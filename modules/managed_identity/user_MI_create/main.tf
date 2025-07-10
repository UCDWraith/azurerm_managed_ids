module "get_resource_group" {
  source = "../../resource_group/rg_use"

  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "example" {
  location            = module.get_resource_group.resource_group_location
  name                = var.user_mi_name
  resource_group_name = var.resource_group_name
  tags                = merge({ "ResourceType" = "user-assigned-managed-identity" }, var.tags)

  lifecycle {
    ignore_changes = [
      tags
    ]
}
