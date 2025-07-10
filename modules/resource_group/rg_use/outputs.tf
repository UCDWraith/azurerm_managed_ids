output "resource_group_name" {
  value = data.azurerm_resource_group.example.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.example.location
}

output "resource_group_id" {
  value = data.azurerm_resource_group.example.id
}