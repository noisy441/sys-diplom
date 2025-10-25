# Security Group для Bastion - SSH доступ только с вашего IP
resource "yandex_vpc_security_group" "sg_bastion" {
  name        = "sg-bastion"
  description = "Security Group для Bastion хоста"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH доступ только с вашего IP"
    port           = 22
    v4_cidr_blocks = [var.your_public_ip]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для внутренней коммуникации
resource "yandex_vpc_security_group" "sg_internal" {
  name        = "sg-internal"
  description = "Security Group для внутренней коммуникации между сервисами"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "ANY"
    description    = "Разрешить всю коммуникацию внутри VPC"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик внутри VPC"
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }
}

# Security Group для Web-серверов
resource "yandex_vpc_security_group" "sg_web" {
  name        = "sg-web"
  description = "Security Group для Web-серверов"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "HTTP доступ от балансировщика"
    port              = 80
    security_group_id = yandex_vpc_security_group.sg_balancer.id
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP доступ для мониторинга от Zabbix"
    port              = 80
    security_group_id = yandex_vpc_security_group.sg_zabbix.id
  }

  ingress {
    protocol       = "TCP"
    description    = "Внутренняя коммуникация по HTTP"
    port           = 80
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для балансировщика (ALB)
resource "yandex_vpc_security_group" "sg_balancer" {
  name        = "sg-balancer"
  description = "Security Group для Application Load Balancer"
  network_id  = yandex_vpc_network.main.id

  ingress {
    description       = "healthchecks"
    protocol          = "TCP"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080  
  }

    ingress {
    protocol       = "TCP"
    description    = "Разрешить health check от ALB"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80   # порт, который использует health check
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик к веб-серверам"
    v4_cidr_blocks = [
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }
}

# Security Group для Zabbix
resource "yandex_vpc_security_group" "sg_zabbix" {
  name        = "sg-zabbix"
  description = "Security Group для сервера Zabbix"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Zabbix UI HTTP из интернета"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix UI HTTPS из интернета"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix агенты из интернета"
    port           = 10051
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix UI от внутренних сервисов"
    port           = 80
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix UI HTTPS от внутренних сервисов"
    port           = 443
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol       = "TCP"
    description    = "Zabbix агенты от внутренних сервисов"
    port           = 10051
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

   ingress {
    protocol       = "TCP"
    description    = "Zabbix агенты от внутренних сервисов"
    port           = 10050
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }
 
# Настройка доступо по SSH c определенного IP
  ingress {
    protocol       = "TCP"
    description    = "SSH доступ только с вашего IP"
    port           = 22
    v4_cidr_blocks = [var.your_public_ip]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Elasticsearch
resource "yandex_vpc_security_group" "sg_elasticsearch" {
  name        = "sg-elasticsearch"
  description = "Security Group для Elasticsearch"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "Elasticsearch API от Kibana"
    port              = 9200
    security_group_id = yandex_vpc_security_group.sg_kibana.id
  }

  # доступ от веб-серверов для Filebeat
  ingress {
    protocol          = "TCP"
    description       = "Elasticsearch API от веб-серверов для Filebeat"
    port              = 9200
    security_group_id = yandex_vpc_security_group.sg_web.id
  }

  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch API для внутренней коммуникации"
    port           = 9200
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol       = "TCP"
    description    = "Elasticsearch transport для внутренней коммуникации"
    port           = 9300
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для Kibana
resource "yandex_vpc_security_group" "sg_kibana" {
  name        = "sg-kibana"
  description = "Security Group для Kibana"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Kibana UI из интернета"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Kibana UI для внутренней коммуникации"
    port           = 5601
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH доступ только с вашего IP"
    port           = 22
    v4_cidr_blocks = [var.your_public_ip]
  }

  egress {
    protocol       = "ANY"
    description    = "Разрешить весь исходящий трафик"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}