resource "local_file" "inventory_fqdn" {
  depends_on = [
    yandex_compute_instance.bastion,
    yandex_compute_instance.web-1,
    yandex_compute_instance.web-2, 
    yandex_compute_instance.zabbix,
    yandex_compute_instance.elasticsearch,
    yandex_compute_instance.kibana
  ]
  
  content = templatefile("${path.module}/templates/inventory.tpl", {
    bastion_ip        = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
    web1_ip           = yandex_compute_instance.web-1.network_interface[0].ip_address
    web2_ip           = yandex_compute_instance.web-2.network_interface[0].ip_address
    zabbix_ip         = yandex_compute_instance.zabbix.network_interface[0].ip_address
    elasticsearch_ip  = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
    kibana_ip         = yandex_compute_instance.kibana.network_interface[0].ip_address
    
    bastion_fqdn      = yandex_compute_instance.bastion.fqdn
    web1_fqdn         = yandex_compute_instance.web-1.fqdn
    web2_fqdn         = yandex_compute_instance.web-2.fqdn
    zabbix_fqdn       = yandex_compute_instance.zabbix.fqdn
    elasticsearch_fqdn = yandex_compute_instance.elasticsearch.fqdn
    kibana_fqdn       = yandex_compute_instance.kibana.fqdn
  })
  
  filename = "./ansible/hosts.ini"
}