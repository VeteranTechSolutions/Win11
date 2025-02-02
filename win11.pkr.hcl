packer {
  required_plugins {
    proxmox = {
      version = "1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
    windows-update = {
      version = "0.16.7"
      source  = "github.com/rgl/windows-update"
    }
  }
}

variable "disk_size" {
  type    = string
  default = "61440"
}

variable "iso_url" {
  type    = string
  default = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/22631.2428.231001-0608.23H2_NI_RELEASE_SVC_REFRESH_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:c8dbc96b61d04c8b01faf6ce0794fdf33965c7b350eaa3eb1e6697019902945c"
}

variable "proxmox_node" {
  type    = string
  default = env("PROXMOX_NODE")
}

variable "vagrant_box" {
  type = string
}

source "proxmox-iso" "windows-11-23h2-amd64" {
  template_name            = "template-windows-11-23h2"
  template_description     = "See https://github.com/rgl/windows-vagrant"
  tags                     = "windows-11-23h2;template"
  insecure_skip_tls_verify = true
  node                     = var.proxmox_node
  machine                  = "q35"
  cpu_type                 = "host"
  cores                    = 2
  memory                   = 4096
  vga {
    type   = "qxl"
    memory = 32
  }
  network_adapters {
    model  = "virtio"
    bridge = "vmbr0"
  }
  scsi_controller = "virtio-scsi-single"
  disks {
    type         = "scsi"
    io_thread    = true
    ssd          = true
    discard      = true
    disk_size    = "${var.disk_size}M"
    storage_pool = "local-zfs"
  }
  iso_storage_pool = "local"
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  unmount_iso      = true
  additional_iso_files {
    device           = "ide0"
    unmount          = true
    iso_storage_pool = "local"
    cd_label         = "PROVISION"
    cd_files = [
      "drivers/NetKVM/w11/amd64/*.cat",
      "drivers/NetKVM/w11/amd64/*.inf",
      "drivers/NetKVM/w11/amd64/*.sys",
      "drivers/qxldod/w11/amd64/*.cat",
      "drivers/qxldod/w11/amd64/*.inf",
      "drivers/qxldod/w11/amd64/*.sys",
      "drivers/vioscsi/w11/amd64/*.cat",
      "drivers/vioscsi/w11/amd64/*.inf",
      "drivers/vioscsi/w11/amd64/*.sys",
      "drivers/vioserial/w11/amd64/*.cat",
      "drivers/vioserial/w11/amd64/*.inf",
      "drivers/vioserial/w11/amd64/*.sys",
      "drivers/viostor/w11/amd64/*.cat",
      "drivers/viostor/w11/amd64/*.inf",
      "drivers/viostor/w11/amd64/*.sys",
      "drivers/spice-guest-tools.exe",
      "drivers/virtio-win-guest-tools.exe",
      "provision-autounattend.ps1",
      "provision-guest-tools-qemu-kvm.ps1",
      "provision-openssh.ps1",
      "provision-psremoting.ps1",
      "provision-pwsh.ps1",
      "provision-winrm.ps1",
      "tmp/windows-11-23h2/autounattend.xml",
    ]
  }
  os             = "win11"
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  http_directory = "."
  boot_wait      = "30s"
}

build {
  sources = [
    "source.proxmox-iso.windows-11-23h2-amd64"
  ]

  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-updates.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "disable-windows-defender.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "remove-one-drive.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "remove-apps.ps1"
  }

  provisioner "windows-restart" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision.ps1"
  }

  provisioner "windows-update" {
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "enable-remote-desktop.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "provision-cloudbase-init.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "eject-media.ps1"
  }

  provisioner "powershell" {
    use_pwsh = true
    script   = "optimize.ps1"
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
