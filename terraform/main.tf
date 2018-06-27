# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# We fetch the latest dns release image from their mirrors
resource "libvirt_volume" "dns-qcow2" {
  name   = "dns-qcow2"
  pool   = "Vms"
  source = "/data/isos/Linux/CentOS7-x86_64.qcow2"
  format = "qcow2"
}

# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit" "commoninit" {
  name               = "commoninit.iso"
  local_hostname     = "dns"
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCf06WpN0rSnOuvvvPaOOba23RbKIeL1br42im14jK9/V0txMSHzmbG3S4R6p6GG8fhbXYvjZ6bqgY40WffNDuPIAONJ0Gp0re1+RkFlUz6aPCH0uPnZJtEcsqatuQCRJ0oYHfNCA94mvdIz3k0JdmaVAUZmRf7tuChcFnQqXvp9i0dOBFdXHF8vi3uFef9z3tkQGA5DPW1f1Mc1vzki6g52JBl5UiTfyTAqj7dw8jdFfMORJehG7UwSM+cAzdpWXYDhj3U3py62zba+VchACwhFyxWked53JBzO3gXKgDuDQok4G9/gHIlwtnIVxPPeurdO9WUvzW5xgOsua2wD92h fabio@note"

  user_data = <<EOF
runcmd:
  - [ yum, -y, update ]
  - [ yum, -y, epel-release ]
  - [ yum, -y, install, htop, vim, bash_completion, python, wget, ansible ]
  - [ yum, -y, groupinstall, "Development Tools" ]
  - [ iptables, -F ]
  - [ setenforce, 0 ]

EOF
}

# Create the machine
resource "libvirt_domain" "domain-dns" {
  name   = "DNS"
  memory = "512"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit.commoninit.id}"

  network_interface {
    network_name = "vnet01"
  }

  # IMPORTANT
  # dns can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = "${libvirt_volume.dns-qcow2.id}"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
  }
}

output "ip" {
  value = "${libvirt_domain.domain-dns.network_interface.0.addresses.0}"
}
