# Variables
variable "master-node-count" {
  default = 3
}

variable "mac-addresses" {
  type = list(string)
  default = [
    "52:54:00:5E:97:A0",
    "52:54:00:5E:97:A1",
    "52:54:00:5E:97:A2"
  ]
}

# Base Disk
resource "libvirt_volume" "node-disk-base" {
  name             = "node-base.qcow2"
  source           = "/fedora-coreos-34.20210904.3.0-qemu.x86_64.qcow2"
  format           = "qcow2"
}

# Node Disk
resource "libvirt_volume" "node-disk" {
  name             = "master${count.index}.qcow2"
  base_volume_id   = libvirt_volume.node-disk-base.id
  size             = 51474836480
  count            = var.master-node-count
}

# Master Ignition
resource "libvirt_ignition" "master-ignition" {
  name    = "master-ignition"
  pool    = "default"
  content = "master.ign"
}

# Create the virtual machines
resource "libvirt_domain" "master-machine" {
  count  = var.master-node-count
  name   = "okd-master${count.index}"
  vcpu   = "2"
  # /run tmpfs size seems to be derived from amount of available ram, 4gb ram --> 783 mb size of /run fs
  memory = "8000"

  coreos_ignition = libvirt_ignition.master-ignition.id

  disk {
    volume_id = element(libvirt_volume.node-disk.*.id, count.index)
  }

  graphics {
    listen_type = "address"
  }

  ## Makes the tty0 available via `virsh console`
  console {
    type = "pty"
    target_port = "0"
  }

  network_interface {
    macvtap = "dmz20"
    # Requires qemu-agent container if network is not native to libvirt
    //wait_for_lease = true
    mac = var.mac-addresses[count.index]
  }
}


