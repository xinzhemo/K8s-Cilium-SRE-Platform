variable "region" {
  description = "阿里云地域"
  type        = string
  default     = "cn-hangzhou"
}

variable "access_key" {
  description = "阿里云 AccessKey ID"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "阿里云 AccessKey Secret"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vswitch_cidr" {
  description = "VSwitch 网段"
  type        = string
  default     = "172.16.1.0/24"
}

variable "instance_type" {
  description = "ECS 实例规格（经济型 e，2C8G）"
  type        = string
  default     = "ecs.e-c1m4.large"
}

variable "system_disk_size" {
  description = "系统盘大小（GB）"
  type        = number
  default     = 60
}

variable "image_id" {
  description = "系统镜像 ID（Ubuntu 22.04）"
  type        = string
  default     = "ubuntu_22_04_x64_20G_alibase_20240628.vhd"
}

variable "instance_name" {
  description = "ECS 实例名称"
  type        = string
  default     = "k3s-cilium-node"
}

variable "ssh_public_key" {
  description = "SSH 公钥内容"
  type        = string
}

variable "k3s_token" {
  description = "K3s 集群 Token"
  type        = string
  default     = "k3s-cilium-sre-lab-token"
}
