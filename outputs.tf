#Вывод информации о созданной сетевой инфраструктуре
output "vpc_network_id" {
  value       = yandex_vpc_network.main.id
  description = "ID созданной VPC сети"
}

output "public_subnet_a_id" {
  value       = yandex_vpc_subnet.public_subnet_a.id
  description = "ID публичной подсети A"
}

output "private_subnet_a_id" {
  value       = yandex_vpc_subnet.private_subnet_a.id
  description = "ID приватной подсети A"
}

output "private_subnet_b_id" {
  value       = yandex_vpc_subnet.private_subnet_b.id
  description = "ID приватной подсети B"
}

output "public_subnet_a_cidr" {
  value       = yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0]
  description = "CIDR блок публичной подсети A"
}

output "private_subnet_a_cidr" {
  value       = yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0]
  description = "CIDR блок приватной подсети A"
}

output "private_subnet_b_cidr" {
  value       = yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
  description = "CIDR блок приватной подсети B"
}

#Вывод информации о созданных групповых политиках
output "security_group_ids" {
  value = {
    bastion       = yandex_vpc_security_group.sg_bastion.id
    internal      = yandex_vpc_security_group.sg_internal.id
    web           = yandex_vpc_security_group.sg_web.id
    balancer      = yandex_vpc_security_group.sg_balancer.id
    zabbix        = yandex_vpc_security_group.sg_zabbix.id
    elasticsearch = yandex_vpc_security_group.sg_elasticsearch.id
    kibana        = yandex_vpc_security_group.sg_kibana.id
  }
  description = "ID созданных Security Groups"
}

#Вывод информации о созданных виртуальных машинах
output "instance_public_ips" {
  value = {
    bastion = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
    zabbix  = yandex_compute_instance.zabbix.network_interface[0].nat_ip_address
    kibana  = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
  }
  description = "Публичные IP адреса виртуальных машин"
}

output "instance_private_ips" {
  value = {
    bastion       = yandex_compute_instance.bastion.network_interface[0].ip_address
    web_1         = yandex_compute_instance.web-1.network_interface[0].ip_address
    web_2         = yandex_compute_instance.web-2.network_interface[0].ip_address
    zabbix        = yandex_compute_instance.zabbix.network_interface[0].ip_address
    elasticsearch = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
    kibana        = yandex_compute_instance.kibana.network_interface[0].ip_address
  }
  description = "Приватные IP адреса виртуальных машин"
}

output "elasticsearch_private_ip" {
  value = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
  description = "Приватный IP адрес для настройки kibana"
}

output "ssh_connection_commands" {
  value = {
    bastion = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address}"
    web-1   = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} dudin@${yandex_compute_instance.web-1.network_interface[0].ip_address}"
    web-2   = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} dudin@${yandex_compute_instance.web-2.network_interface[0].ip_address}"
    elasticsearch = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} dudin@${yandex_compute_instance.elasticsearch.network_interface[0].ip_address}"
    kibana = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} dudin@${yandex_compute_instance.kibana.network_interface[0].ip_address}"
    zabbix = "ssh -J dudin@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} dudin@${yandex_compute_instance.zabbix.network_interface[0].ip_address}"
  }
  description = "Команды для SSH подключения через Bastion"
}

#Вывод информации о балансировщике нагрузки
output "alb_public_ip" {
  value       = yandex_alb_load_balancer.web_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
  description = "Публичный IP адрес балансировщика нагрузки"
}

output "alb_details" {
  value = {
    name             = yandex_alb_load_balancer.web_balancer.name
    id               = yandex_alb_load_balancer.web_balancer.id
    security_groups  = yandex_alb_load_balancer.web_balancer.security_group_ids
    endpoint         = "http://${yandex_alb_load_balancer.web_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
    target_group_id  = yandex_alb_target_group.web_target_group.id
    backend_group_id = yandex_alb_backend_group.web_backend_group.id
    router_id        = yandex_alb_http_router.web_router.id
  }
  description = "Детальная информация о ALB"
}

output "target_group_info" {
  value = {
    target_group_id = yandex_alb_target_group.web_target_group.id
    target_count    = length(yandex_alb_target_group.web_target_group.target)
    targets = [
      for target in yandex_alb_target_group.web_target_group.target : {
        subnet_id  = target.subnet_id
        ip_address = target.ip_address
      }
    ]
  }
  description = "Информация о target group"
}

output "backend_group_info" {
  value = {
    backend_group_id = yandex_alb_backend_group.web_backend_group.id
    health_check_path = "/"
  }
  description = "Информация о backend group"
}

output "service_urls" {
  value = {
    alb_http    = "http://${yandex_alb_load_balancer.web_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address}"
    zabbix_http = "http://${yandex_compute_instance.zabbix.network_interface[0].nat_ip_address}"
    kibana_http = "http://${yandex_compute_instance.kibana.network_interface[0].nat_ip_address}:5601"
  }
  description = "URL для доступа к сервисам"
}

output "security_group_alb_details" {
  value = {
    id          = yandex_vpc_security_group.sg_balancer.id
    name        = yandex_vpc_security_group.sg_balancer.name
    description = yandex_vpc_security_group.sg_balancer.description
  }
  description = "Информация о Security Group для ALB"
}
