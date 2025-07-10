module "user_mi" {
  for_each = {
    for mi in var.user_managed_identities :
    mi.user_mi_name => mi
  }

  source              = "./modules/managed_identity/user_MI_create"
  user_mi_name        = each.value.user_mi_name
  resource_group_name = each.value.resource_group_name
  tags                = merge(var.tags, each.value.tags_id_specific)
}
