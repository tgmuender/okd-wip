terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.6.10"
    }
    ignition = {
      source = "terraform-providers/ignition"
    }
  }
}

provider "libvirt" {
    uri = "qemu+ssh://user@yourLibVirtHost/system?keyfile=/pathToYourKeyFile"
    
}
