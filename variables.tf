variable "cloud_id" {
  type    = string
  default = "b1gt4ptl2kqr88n6tel7"
}

variable "folder_id" {
  type    = string
  default = "b1gnhl2isavkofciik7f"
}

variable "your_public_ip" {
  type        = string
  description = "Мой публичный IP адрес для доступа к Bastion"
  default     = "188.232.0.87/32" # Заменять на реальный IP
}

variable "ssh_public_key_path" {
  type        = string
  description = "Путь к файлу с публичным SSH ключом"
  default     = "~/.ssh/id_ed25519.pub"
}