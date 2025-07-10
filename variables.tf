variable "subscription_id" {
  description = "Subscription ID to which the role assignments will be applied"
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "The subscription_id must be a valid GUID."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set."
  default     = {}
}

variable "user_managed_identities" {
  description = "List of user-assigned managed identities with RG and tags"
  type = list(object({
    resource_group_name = string
    user_mi_name        = string
    tags_id_specific    = map(string)
  }))
}