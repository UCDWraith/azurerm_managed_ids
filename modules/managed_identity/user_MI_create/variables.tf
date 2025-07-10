variable "user_mi_name" {
  description = "The name of the User Managed Identity to create."
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set."
  default     = {}
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which to create the target resource. Changing this forces a new resource to be created."
}