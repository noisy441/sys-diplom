# 1. Target Group
resource "yandex_alb_target_group" "web_target_group" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
    ip_address = yandex_compute_instance.web-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_subnet_b.id
    ip_address = yandex_compute_instance.web-2.network_interface.0.ip_address
  }
}

# 2. Backend Group
resource "yandex_alb_backend_group" "web_backend_group" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_target_group.id]

    healthcheck {
      timeout          = "3s"
      interval         = "5s"
      healthcheck_port = 80
      healthy_threshold   = 3
      unhealthy_threshold = 5
      
      http_healthcheck {
        path = "/"
      }
    }

    load_balancing_config {
      panic_threshold = 50
    }
  }
}

# 3. HTTP Router
resource "yandex_alb_http_router" "web_router" {
  name        = "web-router"
  description = "HTTP Router for web servers"
}

# 4. Virtual Host
resource "yandex_alb_virtual_host" "web_virtual_host" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id
  authority      = ["*"]

  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend_group.id
        timeout          = "60s"
      }
    }
  }
}


# 6. Application Load Balancer
resource "yandex_alb_load_balancer" "web_balancer" {
  name               = "web-balancer"
  network_id         = yandex_vpc_network.main.id
  security_group_ids = [yandex_vpc_security_group.sg_balancer.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_subnet_a.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}