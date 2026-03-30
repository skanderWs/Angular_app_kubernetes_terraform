terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Groupe de Ressources
resource "azurerm_resource_group" "k8s" {
  name     = "rg-k8s-skander"
  location = "norwayeast"
}

# 2. Réseau
resource "azurerm_virtual_network" "vnet" {
  name                = "k8s-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "k8s-subnet"
  resource_group_name  = azurerm_resource_group.k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 3. Sécurité (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "k8s-nsg"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
  name                       = "Kubelet"
  priority                   = 1004
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "10250"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  }
  security_rule {
  name                       = "Calico"
  priority                   = 1005
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Udp"
  source_port_range          = "*"
  destination_port_range     = "4789"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  }
  security_rule {
    name                       = "K8s-API"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Angular-App-NodePort"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# 4. Définition des machines (Master et Worker)
locals {
  nodes = {
    "master" = { size = "Standard_D2s_v3",  id = 1 }
    "worker" = { size = "Standard_D2s_v3", id = 2 }
  }
}

# IPs Publiques
resource "azurerm_public_ip" "pip" {
  for_each            = local.nodes
  name                = "pip-${each.key}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  allocation_method   = "Static"   
  sku                 = "Standard"
}

# Interfaces Réseau (NIC)
resource "azurerm_network_interface" "nic" {
  for_each            = local.nodes
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

# Liaison NSG -> NIC
resource "azurerm_network_interface_security_group_association" "assoc" {
  for_each                  = local.nodes
  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 5. Les Machines Virtuelles
resource "azurerm_linux_virtual_machine" "vm" {
  for_each            = local.nodes
  name                = "vm-k8s-${each.key}"
  resource_group_name = azurerm_resource_group.k8s.name
  location            = azurerm_resource_group.k8s.location
  size                = each.value.size
  admin_username      = "skander"

  # AJOUT DES TAGS POUR ANSIBLE
  tags = {
    kubernetes_role = each.key  # Sera "master" ou "worker"
  }

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id,
  ]

  admin_ssh_key {
    username   = "skander"
    public_key = file("~/.ssh/id_rsa.pub") 
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
