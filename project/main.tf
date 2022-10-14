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

resource "azurerm_virtual_network" "az-devops-c1-vn" {
  name                = "${var.prefix}-vn"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location
  address_space       = ["10.0.0.0/24"]
  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_network_security_group" "az-devops-c1-sg" {
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
    source_address_prefix      = var.address_prefixes
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

resource "azurerm_public_ip" "az-devops-c1-public-ip" {
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
  address_prefixes     = var.address_prefixes
  virtual_network_name = azurerm_virtual_network.az-devops-c1-vn.name

}

resource "azurerm_network_interface" "az-devops-c1-inet" {
  name                = "${var.prefix}-inet"
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

resource "azurerm_lb" "az-devops-c1-lb" {
  name                = "${var.prefix}-lb"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  frontend_ip_configuration {
    name                 = azurerm_public_ip.az-devops-c1-public-ip.name
    public_ip_address_id = azurerm_public_ip.az-devops-c1-public-ip.id
  }

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_availability_set" "az-devops-c1-as" {
  name                = "${var.prefix}-as"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location

  tags = {
    Project = "Azure Devops C1"
  }
}

data "azurerm_image" "image" {
  name                = var.packer_image_name
  resource_group_name = var.images_resource_group

}

resource "azurerm_virtual_machine" "az-devops-c1-vm" {
  count               = var.counter
  name                = "${var.prefix}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.az-devops-c1-rg.name
  location            = azurerm_resource_group.az-devops-c1-rg.location
  vm_size                = "Standard_DS1_v2"
  network_interface_ids = [
    azurerm_network_interface.az-devops-c1-inet.id,
  ]

  
  source_image_id = data.azurerm_image.image.id
  

  storage_os_disk {
    name = "os_disk-${count.index}"
    create_option = "Attach"
    
  }
  
  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_managed_disk" "az-devops-c1-md" {
  name                 = "${var.prefix}-md"
  resource_group_name  = azurerm_resource_group.az-devops-c1-rg.name
  location             = azurerm_resource_group.az-devops-c1-rg.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    Project = "Azure Devops C1"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "az-devops-c1-mda" {
  count=var.counter
  managed_disk_id    = azurerm_managed_disk.az-devops-c1-md.id
  virtual_machine_id = azurerm_virtual_machine.az-devops-c1-vm-[count.index]
  lun                = "10"
  caching            = "ReadWrite"
}