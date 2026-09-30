############################################################
# Components
#  - component = 기존 Terraform 모듈 하나 + 사용할 provider
#  - 컴포넌트 간 값 전달(component.X.Y)로 의존성이 자동으로 결정됨
#
#   resource_group ──> network (VNet / Subnet / NSG) ──> vm (Linux VM 1대)
############################################################

component "resource_group" {
  source = "./modules/resource-group"

  inputs = {
    name     = "${var.prefix}-${var.environment}-rg"
    location = var.location
    tags     = local.tags
  }

  providers = {
    azurerm = provider.azurerm.this
  }
}

component "network" {
  source = "./modules/network"

  inputs = {
    prefix              = "${var.prefix}-${var.environment}"
    resource_group_name = component.resource_group.name
    location            = component.resource_group.location
    vnet_cidr           = var.vnet_cidr
    tags                = local.tags
  }

  providers = {
    azurerm = provider.azurerm.this
  }
}

component "vm" {
  source = "./modules/vm"

  inputs = {
    prefix              = "${var.prefix}-${var.environment}"
    resource_group_name = component.resource_group.name
    location            = component.resource_group.location
    subnet_id           = component.network.subnet_id
    vm_size             = var.vm_size
    ssh_public_key      = var.ssh_public_key
    tags                = local.tags
  }

  providers = {
    azurerm = provider.azurerm.this
  }
}

locals {
  tags = {
    environment = var.environment
    managed_by  = "hcp-terraform-stacks"
    demo        = "stacks-multi-subscription"
  }
}
