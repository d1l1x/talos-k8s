#!/bin/bash
set -x
set -euo pipefail

# renovate: datasource=github-releases depName=siderolabs/talos
talos_version="1.13.9"

# renovate: datasource=docker depName=ghcr.io/siderolabs/qemu-guest-agent
talos_qemu_guest_agent_extension_tag="11.0.2"

# renovate: datasource=docker depName=ghcr.io/siderolabs/drbd
talos_drbd_extension_tag="9.3.3-v1.13.8@sha256:e0044c09bd0cdefea2cb089baf08b7d165e10fea081b8da37ed7d673cc142524"

# renovate: datasource=docker depName=ghcr.io/siderolabs/spin
talos_spin_extension_tag="0.25.1"

# Required by democratic-csi (and any other iSCSI CSI driver): provides
# iscsid/iscsiadm and creates /etc/iscsi on the host. Without this the
# node DaemonSet fails its hostPath mount (HostPathType: Directory).
# NB placeholder tag — run update-talos-extensions to resolve the real one.
# renovate: datasource=docker depName=ghcr.io/siderolabs/iscsi-tools
talos_iscsi_tools_extension_tag="v0.2.0"

# Provides fstrim, used by iSCSI/CSI volume maintenance.
# NB placeholder tag — run update-talos-extensions to resolve the real one.
# renovate: datasource=docker depName=ghcr.io/siderolabs/util-linux-tools
talos_util_linux_tools_extension_tag="2.42.2"

function step {
  echo "### $* ###"
}

function update-talos-extension {
  local variable_name="$1"
  local image_name="$2"
  local images="$3"
  local image="$(grep -F "$image_name:" <<<"$images")"
  local tag="${image#*:}"
  echo "updating the talos extension to $image..."
  variable_name="$variable_name" tag="$tag" perl -i -pe '
    BEGIN {
      $var = $ENV{variable_name};
      $val = $ENV{tag};
    }
    s/^(\Q$var\E=).*/$1"$val"/;
  ' do
}

function update-talos-extensions {
  step "updating the talos extensions"
  local images="$(crane export "ghcr.io/siderolabs/extensions:v$talos_version" | tar x -O image-digests)"
  update-talos-extension talos_qemu_guest_agent_extension_tag ghcr.io/siderolabs/qemu-guest-agent "$images"
  # update-talos-extension talos_drbd_extension_tag ghcr.io/siderolabs/drbd "$images"
  update-talos-extension talos_iscsi_tools_extension_tag ghcr.io/siderolabs/iscsi-tools "$images"
  update-talos-extension talos_util_linux_tools_extension_tag ghcr.io/siderolabs/util-linux-tools "$images"
#   update-talos-extension talos_spin_extension_tag ghcr.io/siderolabs/spin "$images"
}

function build_talos_image {
  local talos_version_tag="v$talos_version"
  rm -rf images/talos
  mkdir -p images/talos
  cat >"images/talos/talos-$talos_version.yml" <<EOF
arch: amd64
platform: nocloud
secureboot: false
version: $talos_version_tag
customization:
  extraKernelArgs:
    - net.ifnames=0
input:
  kernel:
    path: /usr/install/amd64/vmlinuz
  initramfs:
    path: /usr/install/amd64/initramfs.xz
  baseInstaller:
    imageRef: ghcr.io/siderolabs/installer:$talos_version_tag
  systemExtensions:
    - imageRef: ghcr.io/siderolabs/qemu-guest-agent:$talos_qemu_guest_agent_extension_tag
    - imageRef: ghcr.io/siderolabs/iscsi-tools:$talos_iscsi_tools_extension_tag
    - imageRef: ghcr.io/siderolabs/util-linux-tools:$talos_util_linux_tools_extension_tag
output:
  kind: image
  imageOptions:
    diskSize: $((2*1024*1024*1024))
    diskFormat: raw
  outFormat: raw
EOF
  docker run --rm -i \
    -v $PWD/tmp/talos:/secureboot:ro \
    -v $PWD/tmp/talos:/out \
    -v /dev:/dev \
    --privileged \
    "ghcr.io/siderolabs/imager:$talos_version_tag" \
    - < "images/talos/talos-$talos_version.yml"
  local img_path="images/talos/talos-$talos_version.qcow2"
  qemu-img convert -O qcow2 tmp/talos/nocloud-amd64.raw $img_path
  qemu-img info $img_path
}
    # - imageRef: ghcr.io/siderolabs/spin:$talos_spin_extension_tag

# function export-kubernetes-ingress-ca-crt {
#   kubectl get -n cert-manager secret/ingress-tls -o jsonpath='{.data.tls\.crt}' \
#     | base64 -d \
#     > kubernetes-ingress-ca-crt.pem
# }

update-talos-extensions
build_talos_image