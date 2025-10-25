#Создание снимков ежедневно в 01:00 и хранение 7 дней
resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily-snapshots"

  schedule_policy {
    expression = "0 1 * * *"
  }

  snapshot_count = 7

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web-1.boot_disk.0.disk_id,
    yandex_compute_instance.web-2.boot_disk.0.disk_id,
    yandex_compute_instance.zabbix.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id
  ]
}