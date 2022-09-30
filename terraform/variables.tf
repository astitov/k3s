variable "my_ami" {
  type  = string
  default = "ami-07eeacb3005b9beae"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "pub_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "priv_cidr" {
  type    = string
  default = "10.0.20.0/24"
}
