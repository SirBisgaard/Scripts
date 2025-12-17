#!/bin/sh
# Script origin: https://forums.truenas.com/t/latest-nvidia-drivers/43594/11
# This script is created for installing Nvidia drivers on TrueNAS scale, when running an older Nvidia GPU that is not supported by the OS. 
# The installers are from 

# Prerequisites
install-dev-tools

# Unlock the OS
systemd-sysext unmerge
zfs set readonly=off "$(zfs list -H -o name /usr)"

# Download and install Nvidia drivers
wget -O nvidia.run https://us.download.nvidia.com/XFree86/Linux-x86_64/580.119.02/NVIDIA-Linux-x86_64-580.119.02.run
mount -o remount,exec /tmp
sh ./nvidia.run --accept-license \
  --no-questions \
  --ui=none \
  --kernel-module-only \
  --no-drm                       

# Install Nvidia Container Tools
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit

# Download and install Cuda drivers
#wget -O cuda.run https://developer.download.nvidia.com/compute/cuda/12.9.0/local_installers/cuda_12.9.0_575.51.03_linux.run
wget -O cuda.run https://developer.download.nvidia.com/compute/cuda/13.1.0/local_installers/cuda_13.1.0_590.44.01_linux.run
mount -o remount,exec /tmp
sh cuda.run --silent \
  --toolkit \
  --no-opengl-libs \
  --no-driver

# This is for updating apps to have the GPU.
# nvidia-smi --query-gpu=pci.bus_id,gpu_uuid --format=csv
# midclt call -j app.update 'APP-NAME' '{"values": {"resources": {"gpus": {"use_all_gpus": false, "nvidia_gpu_selection": {"PCI-BUS-ID": {"use_gpu": true, "uuid": "GPU-UUID"}}}}}}'

# Lock the OS 
zfs set readonly=on "$(zfs list -H -o name /usr)"
systemd-sysext merge
systemctl restart docker

# Clean up
rm nvidia.run
rm cuda.run
