#!/bin/bash

apt install -y git make podman libfuse3-dev runc

mkdir ~/.config/containers/

me="$(whoami)"

echo "[storage]
  driver = \"overlay\"
  runroot = \"/run/user/1000\"
  graphroot = \"/home/$me/.local/share/containers/storage\"
  [storage.options]
    mount_program = \"/usr/bin/fuse-overlayfs\"" >> storage.conf 

rm -rf /home/virty/.local/share/containers/storage
