############################################################
# Stack 입력 변수
#  - 값은 deployments.tfdeploy.hcl 의 각 deployment "inputs" 에서 주입
#  - Stack 변수는 반드시 type 을 명시해야 함
############################################################

variable "environment" {
  description = "배포 대상 구독 이름 (cloud / data / infra)"
  type        = string
}

variable "prefix" {
  description = "리소스 이름 prefix"
  type        = string
}

variable "location" {
  type    = string
  default = "koreacentral"
}

variable "vnet_cidr" {
  description = "구독별 VNet 주소 대역"
  type        = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "VM 관리자 SSH 공개키 (공개키라 비밀 아님)"
  type        = string
}

# ── Azure 인증 (OIDC / Workload Identity) ─────────────────
# 구독 ID만 바꿔서 같은 코드를 3개 구독에 배포하는 것이 이 데모의 핵심
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  description = "Federated Credential이 등록된 App Registration(또는 Managed Identity)의 Client ID"
  type        = string
}

# HCP Terraform이 Run마다 발급하는 JWT.
# 데모 1에서 본 ephemeral 과 같은 개념 → State/Plan에 저장되지 않음
variable "identity_token" {
  type      = string
  ephemeral = true
}
