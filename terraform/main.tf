# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "centos-qcow2" {
  name   = "centos-qcow2"
  pool   = "Vms"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-1805.qcow2"
  format = "qcow2"
}

# Create a network for our VMs
resource "libvirt_network" "vm_network" {
  name      = "vm_network"
  addresses = ["10.0.1.0/24"]
}

# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit" "commoninit" {
  name               = "commoninit.iso"
  pool               = "Vms"
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDYRW/3LEdMsYd7RQPRhkULov5kHFqBw5OedvsSSA0a+sOKSiOIa6U6l6zcPyFsYYx+XnPXHZI42slO3ImBghz4kAU0TAzP2jsv6ejf4gS6QeyV0xqwagFJv2ELnN9RJND75p7lXg5Ag1P/+RMfH+WCgQv4LPVqO7RiEqkfwSPa9F6CzOLza9EuNY/7u+eROEpEem3zNudEXJJ5fNkcwRTHh+V4XLUxDkOEwQVDpF6798EUTly+6Dhzrrxo5gXVnBUXzblYAYPAyWZ0FqBXlC+sPOqyaVEsJTNEmkrYw5cccW7/M7t+PINrjGEmnXd4PG5IUqPcHR3WkZG44QKt6HauMwvTLRPF5Feuov56FZJqQXrrJ8Ku+SHR5Ju9SAq7iRqreIrRJT/f8vjL9AXaX4S7b2GzSTKICegD5UqNaN5vAVo2Ih9FLZIJXpTymd4d+rMeprYutXaKStbejgAxRkjdr+epVL0wLZZ4toleZRmTzl+v4Xp5aLHyO+RzuZKFzxAbH9VvcBsjVSvvYLispDnsz6Uw+zce0eX4BvZIFKR2zxSWGB168TJ8IJXEwB9HkPe4lW0nEYA/3cb9wLDuzse5Ez+HgDkWP98OLj+gIcoHQg/OFbIf5I7E081tEQjYKgd3HYpjgYfDA2pdcOy2QDXMdfj7ORjb99cq8fee9FOplQ== fabio@fabio-note"
}

# Create the machine
resource "libvirt_domain" "estudosdevops-lab" {
  name   = "BIND-DNS"
  memory = "512"
  vcpu   = 1

  cloudinit = "${libvirt_cloudinit.commoninit.id}"

  network_interface {
    hostname     = "master"
    network_name = "vm_network"
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
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
    volume_id = "${libvirt_volume.centos-qcow2.id}"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}

# Print the Boxes IP
# Note: you can use `virsh domifaddr <vm_name> <interface>` to get the ip later
output "ip" {
  value = "${libvirt_domain.estudosdevops-lab.network_interface.0.addresses.0}"
}
