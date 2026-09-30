# 03-stacks — HCP Terraform Stacks로 Azure 구독 3개에 한 번에 배포

같은 코드(components)를 **deployment 3개(Cloud / Data / Infra) = Azure 구독 3개**에 배포합니다.
구독마다 Workspace를 따로 만들 필요 없이 Stack 하나로 관리하는 것이 핵심입니다.

## 아키텍처 (구독당 동일 · 생성 2~3분)

```
Stack: azure-multi-sub
 ├─ deployment "cloud" ─▶ Cloud 구독 ┐
 ├─ deployment "data"  ─▶ Data 구독  ├─ 각 구독에 동일하게:
 └─ deployment "infra" ─▶ Infra 구독 ┘
                                 component "resource_group" : Resource Group
                                   └─▶ component "network"  : VNet + Subnet + NSG (무료, SSH는 VNet 내부만 허용)
                                         └─▶ component "vm" : Ubuntu 24.04 VM 1대 (Standard_B1s, Public IP 없음)
```

| 구독 | VNet | VM |
|---|---|---|
| Cloud | 10.10.0.0/16 | Standard_B1s |
| Data | 10.20.0.0/16 | Standard_B1s |
| Infra | 10.30.0.0/16 | Standard_B1s |

> 비용: B1s 1대 시간당 약 $0.01 + OS 디스크(Standard HDD) → 시연 후 바로 삭제하면 몇백 원 수준

## 파일 구성

| 파일 | 역할 |
|---|---|
| `variables.tfcomponent.hcl` | Stack 입력 변수 (`identity_token`은 `ephemeral = true`) |
| `providers.tfcomponent.hcl` | `required_providers` + `provider "azurerm" "this" { config { ... } }` (OIDC 인증) |
| `components.tfcomponent.hcl` | component 3개 = 기존 모듈 재사용, `component.X.Y`로 의존성 연결 |
| `outputs.tfcomponent.hcl` | deployment별 VM 이름 / Private IP 등 |
| `deployments.tfdeploy.hcl` | `identity_token` + deployment 3개 (구독 ID만 다름) |
| `.terraform.lock.hcl` | **Stacks는 lock 파일 필수** (azurerm 5.7.0 / linux_amd64 포함) |
| `modules/` | 일반 Terraform 모듈 (Stack이 아니어도 그대로 재사용 가능) |

## 0. 준비 — Azure OIDC (Secret 없이 인증)

App Registration 1개에 **3개 구독 Contributor 권한** + **deployment × (plan/apply) = 6개 Federated Credential**을 등록합니다.

```bash
ORG=<hcp-org>; PROJECT=<hcp-project>; STACK=azure-multi-sub
SUBS=(<Cloud-구독ID> <Data-구독ID> <Infra-구독ID>)

APP_ID=$(az ad app create --display-name hcp-stacks-demo --query appId -o tsv)
az ad sp create --id $APP_ID
for s in "${SUBS[@]}"; do
  az role assignment create --assignee $APP_ID --role Contributor --scope /subscriptions/$s
done

for d in cloud data infra; do for op in plan apply; do
  az ad app federated-credential create --id $APP_ID --parameters "{
    \"name\": \"stacks-$d-$op\",
    \"issuer\": \"https://app.terraform.io\",
    \"subject\": \"organization:$ORG:project:$PROJECT:stack:$STACK:deployment:$d:operation:$op\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
done; done

echo "client_id=$APP_ID  tenant_id=$(az account show --query tenantId -o tsv)"
```

## 0-1. 준비 — HCP Variable Set

Stack에는 Workspace 같은 변수 화면이 없으므로, 환경 정보는 **Variable Set**에 넣고 `deployments.tfdeploy.hcl`의 `store "varset"` 블록으로 읽어옵니다.

1. HCP Terraform → Settings → **Variable sets → Create** (예: `stacks-demo-azure`)
2. 적용 범위: Stack이 속한 **Project에 공유**
3. **Terraform variable**로 아래 6개 등록

| Key | Value |
|---|---|
| `tenant_id` | Tenant ID |
| `client_id` | 위에서 만든 App Registration Client ID |
| `ssh_public_key` | `cat ~/.ssh/id_ed25519.pub` 결과 |
| `subscription_id_cloud` | Cloud 구독 ID |
| `subscription_id_data` | Data 구독 ID |
| `subscription_id_infra` | Infra 구독 ID |

4. Variable Set ID(`varset-...`)를 `deployments.tfdeploy.hcl`의 `store "varset" "azure"` → `id`에 입력

> 구독에 따라 `koreacentral`에서 B1s 용량이 없다는 오류(SkuNotAvailable)가 나면 해당 deployment의 `vm_size`를 `Standard_B2ats_v2` 등으로 바꿉니다.

## 1. Stack 생성 & 배포

1. 이 폴더를 VCS(GitHub/GitLab)에 push
2. HCP Terraform → Project → **New → Stack** → VCS 연결, 이름 `azure-multi-sub`, Working Directory `03-stacks`
3. Stack이 설정을 읽어 **deployment 3개(cloud/data/infra)** 에 대해 각각 Plan 생성
4. 각 deployment의 Plan을 Approve → Apply (component 의존성 순서: resource_group → network → vm)
5. 각 deployment의 Outputs(`vm_name`, `vm_private_ip`) 확인 → Azure Portal에서 구독 3개에 VM이 하나씩 생성된 것 확인

## 2. (시연 포인트) 변경 한 번 → 3개 구독 동시 반영

예) `components.tfcomponent.hcl`의 `local.tags`에 `owner = "platform-team"` 추가 후 push
→ 새 Configuration 버전 하나로 **cloud/data/infra 3개 Plan이 동시에** 생성됨 → 구독별로 순서대로 승인

## 3. 정리

Stack은 deployment 블록을 지우는 것만으로는 삭제되지 않습니다.
각 deployment에 `destroy = true`를 넣고 push → Plan/Apply(destroy) → 완료 후 deployment 블록 제거.

## 참고

- 로컬 검증: `terraform stacks validate` (Terraform 1.13+ 의 stacks 플러그인 필요)
- provider 버전 변경 시: `terraform stacks providers-lock -platform=linux_amd64 -platform=darwin_arm64`
