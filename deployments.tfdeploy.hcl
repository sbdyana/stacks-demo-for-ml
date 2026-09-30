############################################################
# Deployments
#  - 같은 Stack 코드(components)를 deployment 별로 다른 입력값으로 배포
#  - deployment = 독립된 State + 독립된 Plan/Apply
#  - 여기서는 deployment 3개 = Azure 구독 3개
############################################################

# 환경 정보(Tenant / Client / 구독 ID / SSH 공개키)는 코드에 넣지 않고
# HCP Terraform Variable Set 에서 읽어옴
#  - Stack에는 Workspace 같은 변수 화면이 없으므로 store "varset" 블록으로 가져옴
#  - Variable Set은 Stack이 속한 Project 에 공유되어 있어야 함
#  - store 값은 ephemeral → provider 인증에만 사용 가능 (리소스 인자에는 못 씀)
#  - Variable Set 키: tenant_id, client_id, client_secret(Sensitive), subscription_id_cloud
#                     (+ subscription_id_data, subscription_id_infra — 해당 deployment 활성화 시)
store "varset" "azure" {
  id       = "varset-oWW5DxDWVgvtLZQe" # Variable Set ID (Settings → Variable sets → 해당 Set의 URL/ID)
  category = "terraform"
}

locals {
  prefix = "stackdemo"

  # VM 리소스 인자에 들어가므로 ephemeral 인 store 값은 사용 불가 → 코드에 직접 기입 
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJjuZH1V/AykUILUxMFjExvIrVo/6gPO4CaaZE6yaS/p stacks-demo"
}

deployment "cloud" {
  inputs = {
    environment = "cloud"
    prefix      = local.prefix
    vnet_cidr   = "10.10.0.0/16"
    vm_size     = "Standard_D2s_v3"

    subscription_id = store.varset.azure.subscription_id_cloud
    tenant_id       = store.varset.azure.tenant_id
    client_id       = store.varset.azure.client_id
    ssh_public_key  = local.ssh_public_key
    client_secret   = store.varset.azure.client_secret
  }
}

# ── Data / Infra 구독: 구독 ID 발급 전까지 비활성화 ─────────────
#  구독이 준비되면 아래 주석을 풀고 Variable Set에
#  subscription_id_data / subscription_id_infra 를 추가
# deployment "data" {
#   inputs = {
#     environment = "data"
#     prefix      = local.prefix
#     vnet_cidr   = "10.20.0.0/16"
#     vm_size     = "Standard_D2s_v3"
#
#     subscription_id = store.varset.azure.subscription_id_data
#     tenant_id       = store.varset.azure.tenant_id
#     client_id       = store.varset.azure.client_id
#     ssh_public_key  = local.ssh_public_key
#     client_secret   = store.varset.azure.client_secret
#   }
# }
#
# deployment "infra" {
#   inputs = {
#     environment = "infra"
#     prefix      = local.prefix
#     vnet_cidr   = "10.30.0.0/16"
#     vm_size     = "Standard_D2s_v3"
#
#     subscription_id = store.varset.azure.subscription_id_infra
#     tenant_id       = store.varset.azure.tenant_id
#     client_id       = store.varset.azure.client_id
#     ssh_public_key  = local.ssh_public_key
#     client_secret   = store.varset.azure.client_secret
#   }
#
#   # 시연 후 정리: 아래 주석을 풀고 push → Infra 구독의 리소스가 삭제됨
#   # destroy = true
# }
