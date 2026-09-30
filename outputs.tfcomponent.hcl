############################################################
# Stack 출력 (Stack output은 type 명시 필수)
############################################################

output "resource_group_name" {
  type  = string
  value = component.resource_group.name
}

output "vnet_id" {
  type  = string
  value = component.network.vnet_id
}

output "vm_name" {
  type  = string
  value = component.vm.vm_name
}

output "vm_private_ip" {
  type  = string
  value = component.vm.private_ip
}
