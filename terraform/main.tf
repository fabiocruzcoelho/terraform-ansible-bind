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
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYRW/3LEdMsYd7RQPRhkULov5kHFqBw5OedvsSSA0a+sOKSiOIa6U6l6zcPyFsYYx+XnPXHZI42slO3ImBghz4kAU0TAzP2jsv6ejf4gS6QeyV0xqwagFJv2ELnN9RJND75p7lXg5Ag1P/+RMfH+WCgQv4LPVqO7RiEqkfwSPa9F6CzOLza9EuNY/7u+eROEpEem3zNudEXJJ5fNkcwRTHh+V4XLUxDkOEwQVDpF6798EUTly+6Dhzrrxo5gXVnBUXzblYAYPAyWZ0FqBXlC+sPOqyaVEsJTNEmkrYw5cccW7/M7t+PINrjGEmnXd4PG5IUqPcHR3WkZG44QKt6HauMwvTLRPF5Feuov56FZJqQXrrJ8Ku+SHR5Ju9SAq7iRqreIrRJT/f8vjL9AXaX4S7b2GzSTKICegD5UqNaN5vAVo2Ih9FLZIJXpTymd4d+rMeprYutXaKStbejgAxRkjdr+epVL0wLZZ4toleZRmTzl+v4Xp5aLHyO+RzuZKFzxAbH9VvcBsjVSvvYLispDnsz6Uw+zce0eX4BvZIFKR2zxSWGB168TJ8IJXEwB9HkPe4lW0nEYA/3cb9wLDuzse5Ez+HgDkWP98OLj+gIcoHQg/OFbIf5I7E081tEQjYKgd3HYpjgYfDA2pdcOy2QDXMdfj7ORjb99cq8fee9FOplQ== fabio@fabio-note"

  user_data = <<EOF
runcmd:
  - [ yum, -y, update ]
  - [ yum, -y, install, epel-release, htop, vim, bash_completion, python ]
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

# Print the Boxes IP
# Note: you can use `virsh domifaddr <vm_name> <interface>` to get the ip later
output "ip" {
  value = "${libvirt_domain.domain-dns.network_interface.0.addresses.0}"
}
