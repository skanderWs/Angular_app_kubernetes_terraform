output "master_public_ip" {
  value = azurerm_public_ip.pip["master"].ip_address
}

output "worker_public_ip" {
  value = azurerm_public_ip.pip["worker"].ip_address
}