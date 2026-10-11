terraform {
  required_version = ">= 1.5.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.200"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# ---------- 自动获取本机公网 IP ----------
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com/"
}

provider "alicloud" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

# ---------- 可用区 ----------
data "alicloud_zones" "default" {
  available_disk_category     = "cloud_essd"
  available_resource_creation = "VSwitch"
}

# ---------- VPC ----------
resource "alicloud_vpc" "main" {
  vpc_name   = "k3s-cilium-vpc"
  cidr_block = var.vpc_cidr
}

# ---------- VSwitch ----------
resource "alicloud_vswitch" "main" {
  vpc_id       = alicloud_vpc.main.id
  cidr_block   = var.vswitch_cidr
  zone_id      = data.alicloud_zones.default.zones.0.id
  vswitch_name = "k3s-cilium-vswitch"
}

# ---------- 安全组 ----------
resource "alicloud_security_group" "main" {
  security_group_name = "k3s-cilium-sg"
  description         = "K3s + Cilium SRE Lab"
  vpc_id              = alicloud_vpc.main.id
}

# SSH 仅放行本机 IP（自动获取）
resource "alicloud_security_group_rule" "ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# K8s API Server（VPC 内网）
resource "alicloud_security_group_rule" "k8s_api" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6443/6443"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = var.vpc_cidr
}

# Cilium VXLAN (UDP 8472)
resource "alicloud_security_group_rule" "cilium_vxlan" {
  type              = "ingress"
  ip_protocol       = "udp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8472/8472"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = var.vpc_cidr
}

# Cilium health check (TCP 4240)
resource "alicloud_security_group_rule" "cilium_health" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "4240/4240"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = var.vpc_cidr
}

# Hubble Relay (TCP 4245)
resource "alicloud_security_group_rule" "hubble_relay" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "4245/4245"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = var.vpc_cidr
}

# NodePort 范围（仅本机 IP）
resource "alicloud_security_group_rule" "nodeport" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "30000/32767"
  priority          = 2
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "${chomp(data.http.my_public_ip.response_body)}/32"
}

# 出站全放行
resource "alicloud_security_group_rule" "egress_all" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  priority          = 1
  security_group_id = alicloud_security_group.main.id
  cidr_ip           = "0.0.0.0/0"
}

# ---------- SSH 密钥对 ----------
resource "alicloud_key_pair" "main" {
  key_pair_name = "k3s-cilium-key"
  public_key    = var.ssh_public_key
}

# ---------- ECS 实例 ----------
resource "alicloud_instance" "k3s_server" {
  availability_zone          = data.alicloud_zones.default.zones.0.id
  security_groups            = [alicloud_security_group.main.id]
  instance_type              = var.instance_type
  system_disk_category       = "cloud_essd"
  system_disk_size           = var.system_disk_size
  image_id                   = var.image_id
  instance_name              = var.instance_name
  vswitch_id                 = alicloud_vswitch.main.id
  internet_max_bandwidth_out = 10
  key_name                   = alicloud_key_pair.main.key_pair_name

  user_data = base64encode(templatefile("${path.module}/cloud-init/setup.yaml", {
    k3s_token = var.k3s_token
    server_ip = "__SERVER_IP__"
  }))

  tags = {
    Project = "k3s-cilium-sre-lab"
  }
}
