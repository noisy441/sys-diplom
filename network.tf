resource "yandex_vpc_network" "main" {
  name        = "main-network"
  description = "Основная VPC сеть для дипломного проекта"
  folder_id   = var.folder_id
}

# Создание интернет-шлюза
resource "yandex_vpc_gateway" "internet_gateway" {
  name = "internet-gateway"
  shared_egress_gateway {}
}

# Создание NAT-шлюза
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
}

# Таблица маршрутизации для публичной подсети
resource "yandex_vpc_route_table" "public_route_table" {
  name       = "public-route-table"
  network_id = yandex_vpc_network.main.id
  folder_id  = var.folder_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id        = yandex_vpc_gateway.internet_gateway.id
  }
}

# Таблица маршрутизации для приватных подсетей
resource "yandex_vpc_route_table" "private_route_table" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id
  folder_id  = var.folder_id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id        = yandex_vpc_gateway.nat_gateway.id
  }
}

# Публичная подсеть для Bastion, Zabbix, Kibana, ALB
resource "yandex_vpc_subnet" "public_subnet_a" {
  name           = "public-subnet-a"
  description    = "Публичная подсеть для Bastion, Zabbix, Kibana, ALB"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  folder_id      = var.folder_id
  v4_cidr_blocks = ["192.168.10.0/24"]
  route_table_id = yandex_vpc_route_table.public_route_table.id
}

# Приватная подсеть для Web-сервера 1, Elasticsearch
resource "yandex_vpc_subnet" "private_subnet_a" {
  name           = "private-subnet-a"
  description    = "Приватная подсеть для Web-сервера 1, Elasticsearch"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  folder_id      = var.folder_id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_route_table.id
}

# Приватная подсеть для Web-сервера 2
resource "yandex_vpc_subnet" "private_subnet_b" {
  name           = "private-subnet-b"
  description    = "Приватная подсеть для Web-сервера 2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  folder_id      = var.folder_id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.private_route_table.id
}
