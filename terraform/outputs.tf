output "vpc_id" {
  description = "VPC ID"
  value       = alicloud_vpc.main.id
}

output "vswitch_id" {
  description = "VSwitch ID"
  value       = alicloud_vswitch.main.id
}

output "security_group_id" {
  description = "安全组 ID"
  value       = alicloud_security_group.main.id
}

output "instance_id" {
  description = "ECS 实例 ID"
  value       = alicloud_instance.k3s_server.id
}

output "public_ip" {
  description = "ECS 公网 IP"
  value       = alicloud_instance.k3s_server.public_ip
}

output "private_ip" {
  description = "ECS 私网 IP（Cilium k8sServiceHost 使用）"
  value       = alicloud_instance.k3s_server.private_ip
}

output "local_public_ip" {
  description = "本机公网 IP（用于安全组放行）"
  value       = chomp(data.http.my_public_ip.response_body)
}

output "ssh_command" {
  description = "SSH 登录命令"
  value       = "ssh root@${alicloud_instance.k3s_server.public_ip}"
}
