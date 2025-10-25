# SSH ключ для доступа ко всем ВМ
resource "yandex_vpc_security_group" "sg_ssh_internal" {
  name        = "sg-ssh-internal"
  description = "Security Group для SSH доступа между сервисами"
  network_id  = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "SSH доступ из внутренней сети"
    port           = 22
    v4_cidr_blocks = [
      yandex_vpc_subnet.public_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_a.v4_cidr_blocks[0],
      yandex_vpc_subnet.private_subnet_b.v4_cidr_blocks[0]
    ]
  }
}

# Данные об образе Ubuntu
data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2204-lts"
}

# Bastion хост
resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  }  

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.public_subnet_a.id
    nat             = true
    security_group_ids = [
      yandex_vpc_security_group.sg_bastion.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }

  metadata = {
    user-data = "${file("./cloud-init.yml")}"
    hostname  = "bastion"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Web-сервер 1
resource "yandex_compute_instance" "web-1" {
  name        = "web-1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  }    

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.private_subnet_a.id
    nat             = false
    ip_address      = "192.168.20.25"
    security_group_ids = [
      yandex_vpc_security_group.sg_web.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }

  metadata = {
    user-data = "${file("./cloud-init.yml")}"

  }

  scheduling_policy {
    preemptible = true
  }
}

# Web-сервер 2
resource "yandex_compute_instance" "web-2" {
  name        = "web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  } 

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.private_subnet_b.id
    nat             = false
    ip_address      = "192.168.30.25"
    security_group_ids = [
      yandex_vpc_security_group.sg_web.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }

  metadata = {
    user-data = "${file("./cloud-init.yml")}"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Zabbix сервер
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  } 

  resources {
    cores  = 4
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 30
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.public_subnet_a.id
    nat             = true
    security_group_ids = [
      yandex_vpc_security_group.sg_zabbix.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }

  metadata = {
    user-data = "${file("./cloud-init.yml")}"
    hostname  = "zabbix"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Elasticsearch сервер
resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  } 

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 100
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.private_subnet_a.id
    nat             = false
    security_group_ids = [
      yandex_vpc_security_group.sg_elasticsearch.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }

  metadata = {
    user-data = "${file("./cloud-init.yml")}"    
    hostname  = "elasticsearch"
  }

  scheduling_policy {
    preemptible = true
  }
}

# Kibana сервер
resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels = {
    project     = "diplom"
    environment = "production"
    owner       = "dudin"
  } 

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id       = yandex_vpc_subnet.public_subnet_a.id
    nat             = true
    security_group_ids = [
      yandex_vpc_security_group.sg_kibana.id,
      yandex_vpc_security_group.sg_ssh_internal.id,
      yandex_vpc_security_group.sg_internal.id
    ]
  }
  
  metadata = {
    user-data = "${file("./cloud-init.yml")}"
    hostname  = "kibana"
  }

  scheduling_policy {
    preemptible = true
  }
}