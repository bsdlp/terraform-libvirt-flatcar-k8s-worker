variable "kubeadm_join_args" {
  type = string
}

data "ignition_config" "ignition" {
  users = [
    data.ignition_user.core.rendered,
  ]

  files = [
    data.ignition_file.hostname.rendered,
    data.ignition_file.network.rendered,
    data.ignition_file.kubeadm.rendered,
    data.ignition_file.kubelet.rendered,
    data.ignition_file.kubelet_service.rendered,
    data.ignition_file.kubeadm_conf.rendered,
  ]

  systemd = [
    data.ignition_systemd_unit.kubeadm_service.rendered,
    data.ignition_systemd_unit.kubelet_service.rendered,
  ]
}

data "ignition_file" "network" {
  path = "/etc/systemd/network/00-wired.network"
  content {
    content = templatefile("${path.module}/units/00-wired.network", {
      network_interface = network_interface,
    })
  }
}

data "ignition_file" "hostname" {
  path = "/etc/hostname"
  mode = 420

  content {
    content = var.domain_name
  }
}

data "ignition_user" "core" {
  name = "core"

  ssh_authorized_keys = var.ssh_authorized_keys
}

data "ignition_file" "kubeadm" {
  path = "/opt/bin/kubeadm"
  mode = "0755"
  source {
    source = "https://dl.k8s.io/v1.28.0/bin/linux/amd64/kubeadm"
  }
}

data "ignition_file" "kubelet" {
  path = "/opt/bin/kubelet"
  mode = "0755"
  source {
    source = "https://dl.k8s.io/v1.28.0/bin/linux/amd64/kubelet"
  }
}

data "ignition_file" "kubelet_service" {
  path = "/etc/systemd/system/kubelet.service"
  source {
    source = "https://raw.githubusercontent.com/kubernetes/release/v0.15.1/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service"
  }
}

data "ignition_file" "kubeadm_conf" {
  path = "/etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  source {
    source = "https://raw.githubusercontent.com/kubernetes/release/v0.15.1/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf"
  }
}

data "ignition_systemd_unit" "kubelet_service" {
  name = "kubelet.service"
  dropin {
    name    = "20-kubelet.conf"
    content = file("${path.module}/units/20-kubelet.conf")
  }
}

data "ignition_systemd_unit" "kubeadm_service" {
  name = "kubeadm.service"
  content = templatefile("${path.module}/units/kubeadm.service", {
    kubeadm_join_args = var.kubeadm_join_args,
  })
}
