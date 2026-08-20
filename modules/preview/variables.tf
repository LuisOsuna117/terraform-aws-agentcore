variable "name" {
  type = string
}

variable "template_body" {
  type = string
}

variable "parameters" {
  type    = map(string)
  default = {}
}

variable "capabilities" {
  type    = set(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
