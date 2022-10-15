terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "az-devops-c1-rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_virtual_network" "vn" {
  name                = "${var.prefix}-vn"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location
  address_space       = var.address_space
  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_network_security_group" "sg" {
  name                = "${var.prefix}-sg"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  security_rule {
    name                       = "allowInternalNetworkAccess"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "denyAll"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_public_ip" "public-ip" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location
  allocation_method   = "Static"

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-internal"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vn.name

}

resource "azurerm_network_interface" "inet" {
  count = var.vm_count
  name                = "${var.prefix}-inet-${count.index}"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  frontend_ip_configuration {
    name                 = azurerm_public_ip.public-ip.name
    public_ip_address_id = azurerm_public_ip.public-ip.id
  }

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_availability_set" "as" {
  name                = "${var.prefix}-as"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  tags = {
    Project = "Azure Devops C1"
  }
}

data "azurerm_image" "image" {
  name = "az-devops-c1-ubuntu-image-18"
  resource_group_name = var.images_resource_group

}

resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "${var.prefix}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "azdevopsc1admin"
  admin_password      = var.admin_password
  source_image_id     = var.packer_image_name
  network_interface_ids = [
    element(azurerm_network_interface.inet.*.id, count.index)
  ]  
  availability_set_id = azurerm_availability_set.as.id
  disable_password_authentication = false


  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
  
  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_managed_disk" "md" {
  count = var.vm_count
  name                 = "${var.prefix}-managed-disk-${count.index}"
  resource_group_name  = azurerm_resource_group.az-devops-c1-rg.name
  location             = azurerm_resource_group.az-devops-c1-rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "mda" {
  count=var.vm_count
  managed_disk_id    = element(azurerm_managed_disk.md.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.vm.*.id, count.index)
  lun                = "10" 
  caching            = "ReadWrite"
}