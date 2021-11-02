

resource "libvirt_volume" "bootstrap-disk-base" {
  name             = "bootstrap-base.qcow2"
  source           = "/terraform-coreos-ignition/fedora-coreos-34.20210904.3.0-qemu.x86_64.qcow2"
  format           = "qcow2"
}
resource "libvirt_volume" "bootstrap-disk" {
  name             = "bootstrap.qcow2"
  base_volume_id   = libvirt_volume.bootstrap-disk-base.id
  size             = 101474836480
}

# Loading ignition configs in QEMU requires at least QEMU v2.6
resource "libvirt_ignition" "bootstrap-ignition" {
  name    = "bootstrap-ignition"
  pool    = "default"
  content = "bootstrap.ign"
}

# Create the virtual machines
resource "libvirt_domain" "bootstrap-machine" {
  count  = 1
  name   = "okd-bootstrap"
  vcpu   = "2"
  # /run tmpfs size seems to be derived from amount of available ram, 4gb ram --> 783 mb size of /run fs
  memory = "16000"

  coreos_ignition = libvirt_ignition.bootstrap-ignition.id

  disk {
    volume_id = libvirt_volume.bootstrap-disk.id
  }

  graphics {
    ## Bug in linux up to 4.14-rc2
    ## https://bugzilla.redhat.com/show_bug.cgi?id=1432684
    ## No Spice/VNC available if more than one machine is generated at a time
    ## Comment the address line, uncomment the none line and the console block below
    #listen_type = "none"
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
    mac = "52:54:00:5E:97:B7"
  }

  ## mounts filesystem local to the kvm host. used to patch in the
  ## qemu-guest-agent as docker container
  #filesystem {
  #  source = "/srv/images/"
  #  target = "qemu_docker_images"
  #  readonly = true
  #}
}


