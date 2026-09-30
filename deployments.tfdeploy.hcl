############################################################
# Deployments
#  - 같은 Stack 코드(components)를 deployment 별로 다른 입력값으로 배포
#  - deployment = 독립된 State + 독립된 Plan/Apply
#  - 여기서는 deployment 3개 = Azure 구독 3개
############################################################

# HCP Terraform이 Run마다 Azure용 OIDC 토큰(JWT)을 발급
#  sub = organization:<org>:project:<project>:stack:<stack>:deployment:<cloud|data|infra>:operation:<plan|apply>
identity_token "azurerm" {
  audience = ["api://AzureADTokenExchange"]
}

# 환경 정보(Tenant / Client / 구독 ID / SSH 공개키)는 코드에 넣지 않고
# HCP Terraform Variable Set 에서 읽어옴
#  - Stack에는 Workspace 같은 변수 화면이 없으므로 store "varset" 블록으로 가져옴
#  - Variable Set은 Stack이 속한 Project 에 공유되어 있어야 함
#  - Variable Set 키: tenant_id, client_id, ssh_public_key,
#                     subscription_id_cloud, subscription_id_data, subscription_id_infra
store "varset" "azure" {
  id       = "varset-XXXXXXXXXXXXXXXX" # Variable Set ID (Settings → Variable sets → 해당 Set의 URL/ID)
  category = "terraform"
}

locals {
  prefix = "stackdemo"
}

deployment "cloud" {
  inputs = {
    environment = "cloud"
    prefix      = local.prefix
    vnet_cidr   = "10.10.0.0/16"
    vm_size     = "Standard_B1s"

    subscription_id = store.varset.azure.subscription_id_cloud
    tenant_id       = store.varset.azure.tenant_id
    client_id       = store.varset.azure.client_id
    ssh_public_key  = store.varset.azure.ssh_public_key
    identity_token  = identity_token.azurerm.jwt
  }
}

deployment "data" {
  inputs = {
    environment = "data"
    prefix      = local.prefix
    vnet_cidr   = "10.20.0.0/16"
    vm_size     = "Standard_B1s"

    subscription_id = store.varset.azure.subscription_id_data
    tenant_id       = store.varset.azure.tenant_id
    client_id       = store.varset.azure.client_id
    ssh_public_key  = store.varset.azure.ssh_public_key
    identity_token  = identity_token.azurerm.jwt
  }
}

deployment "infra" {
  inputs = {
    environment = "infra"
    prefix      = local.prefix
    vnet_cidr   = "10.30.0.0/16"
    vm_size     = "Standard_B1s"

    subscription_id = store.varset.azure.subscription_id_infra
    tenant_id       = store.varset.azure.tenant_id
    client_id       = store.varset.azure.client_id
    ssh_public_key  = store.varset.azure.ssh_public_key
    identity_token  = identity_token.azurerm.jwt
  }

  # 시연 후 정리: 아래 주석을 풀고 push → Infra 구독의 리소스가 삭제됨
  # destroy = true
}
