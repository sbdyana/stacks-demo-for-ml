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

# ── Azure 인증 (Service Principal + Client Secret) ────────
# 구독 ID만 바꿔서 같은 코드를 3개 구독에 배포하는 것이 이 데모의 핵심
variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_id" {
  description = "App Registration(Service Principal)의 Application(client) ID"
  type        = string
}

# App Registration → Certificates & secrets 의 "Value" (Secret ID 아님)
# 데모 1에서 본 ephemeral 과 같은 개념 → State/Plan에 저장되지 않음
variable "client_secret" {
  type      = string
  ephemeral = true
}
