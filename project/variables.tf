variable "prefix" {
    description = "The prefix to use for resources created with this template"
    default = "az-devops-c1"
}

variable "location" {
    description = "The azure location where the resources will be created"
    default = "East US"
}

variable "vm_count" {
    description = "The number of virtual machines to create within the scale set"
    default = 2
}

variable "address_space" {
    description = "The address block for the virtual network"
    default = ["10.0.0.0/16"]
}

variable "packer_image_name" {
    description = "The id of the packer image to use for the virtual machines"
    default = "/subscriptions/1b33bac2-45ca-42d7-9099-3239addac4ee/resourceGroups/az-devops-c1-images-rg/providers/Microsoft.Compute/images/az-devops-c1-ubuntu-image-18"
}

variable "images_resource_group" {
    description = "The resource group where packer images are stored"
    default = "az-devops-c1-images-rg"
}

variable "admin_password" {
    description = "The initial administrator password for the vm"
    default = "@dm1n123$"
}