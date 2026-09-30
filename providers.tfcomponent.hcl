############################################################
# Provider 설정
#  - Stack에서는 provider 블록에 "이름"이 붙고, 설정은 config { } 안에 작성
#  - 인증정보(Secret)는 없음: HCP Terraform이 발급한 identity_token(OIDC)으로
#    deployment 마다 다른 구독(subscription_id)에 로그인
############################################################

required_providers {
  azurerm = {
    source  = "hashicorp/azurerm"
    version = "~> 5.0"
  }
}

provider "azurerm" "this" {
  config {
    features {}

    use_cli    = false
    use_oidc   = true
    oidc_token = var.identity_token

    subscription_id = var.subscription_id
    tenant_id       = var.tenant_id
    client_id       = var.client_id

    # 새 구독에서도 빠르게 동작하도록 필요한 RP(Compute, Network 등)만 등록
    resource_provider_registrations = "core"
  }
}
