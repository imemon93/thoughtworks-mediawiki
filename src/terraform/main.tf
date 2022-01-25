provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "thoughtworks-rg" {
  name     = "thoughtworks-test-resources"
  location = "North Europe"
}

# Virtual network
resource "azurerm_virtual_network" "thoughtworks-vnet" {
  name                = "thoughtworks-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.thoughtworks-rg.location
  resource_group_name = azurerm_resource_group.thoughtworks-rg.name
}

# Virtual network subnet
resource "azurerm_subnet" "thoughtworks-subnet1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.thoughtworks-rg.name
  virtual_network_name = azurerm_virtual_network.thoughtworks-vnet.name
  address_prefixes     = ["10.0.1.0/28"]
}

# Network Interface
resource "azurerm_network_interface" "thoughtworks-nic" {
  name                = "thoughtworks-nic"
  location            = azurerm_resource_group.thoughtworks-rg.location
  resource_group_name = azurerm_resource_group.thoughtworks-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.thoughtworks-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "thoughtworks-nsg" {
  name                = "thoughtworks-nsg"
  resource_group_name = azurerm_resource_group.thoughtworks-rg.name
  location            = azurerm_resource_group.thoughtworks-rg.location
}

# Network Security Rules
resource "azurerm_network_security_rule" "rules" {
  for_each = var.rules
  
  name                                       = each.value.rule_name
  direction                                  = "Inbound"
  description                                = each.value.rule_name
  source_port_range                          = "*"
  destination_port_range                     = each.value.port
  source_address_prefix                      = "*"
  protocol                                   = "Tcp"
  access                                     = "Allow"
  priority                                   = each.value.priority
  resource_group_name                        = azurerm_resource_group.thoughtworks-rg.name
  network_security_group_name                = azurerm_network_security_group.thoughtworks-nsg.name
}

# Network Security Group Association with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_subnet" {
  subnet_id                 = azurerm_subnet.thoughtworks-subnet1.id
  network_security_group_id = azurerm_network_security_group.thoughtworks-nsg.id
}

# Private SSH Key
resource "tls_private_key" "thoughtworks-ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.thoughtworks-ssh.private_key_pem 
    sensitive = true
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "thoughtworks-vm" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.thoughtworks-rg.name
  location            = azurerm_resource_group.thoughtworks-rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.thoughtworks-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.thoughtworks-ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "7-RAW-CI"
    version   = "7.6"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u adminuser -i '${self.ipv4_address},' --private-key ${tls_private_key.thoughtworks-ssh.private_key_pem} src/ansible/configure_mediawiki.yml"
  }
}

