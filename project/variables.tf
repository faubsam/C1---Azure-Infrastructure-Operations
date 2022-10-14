variable "prefix" {
    description = "The prefix to use for resources created with this template"
    default = "az-devops-c1"
}

variable "location" {
    description = "The azure location where the resources will be created"
    default = "East US"
}

variable "counter" {
    description = "The number of virtual machines to create within the scale set"
    default = 2
}

variable "address_prefixes" {
    description = "The address block for the internal subnet"
    default = ["10.0.1.0/24"]
}

variable "packer_image_name" {
    description = "The name of the packer image to use for the virtual machines"
    default = "az-devops-c1-ubuntu-image-18"
}

variable "images_resource_group" {
    description = "The resource group where packer images are stored"
    default = "az-devops-c1-images-rg"
}