#!/bin/bash
set -e

prepare() {

# systemctl stop reflector
# reflector --verbose --country China --protocol http --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

esp_partition=/dev/nvme0n1p1
root_partition=/dev/nvme0n1p2

mkfs.ext4 -F ${root_partition}
mkfs.fat -F 32 ${esp_partition}

mount ${root_partition} /mnt
mkdir -p /mnt/boot/efi
mount ${esp_partition} /mnt/boot/efi

pacstrap /mnt base base-devel linux-lts linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

cp install.sh /mnt/root/
arch-chroot /mnt /root/install.sh install
rm -rf  /mnt/root/install.sh

}

install() {

hostname='xundaoxd-pc'
user="xundaoxd"

ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

echo -e 'en_US.UTF-8 UTF-8\nzh_CN.UTF-8 UTF-8' >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
locale-gen

echo $hostname > /etc/hostname

mkinitcpio -P

pacman -S --noconfirm grub efibootmgr
grub-install --efi-directory=/boot/efi --recheck
grub-mkconfig -o /boot/grub/grub.cfg

pacman -S --noconfirm nvidia-lts alsa-utils alsa-firmware pulseaudio pulseaudio-alsa pulseaudio-bluetooth

pacman -S --noconfirm plasma kde-applications fcitx-googlepinyin kcm-fcitx
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable bluetooth

pacman -Syy
pacman -S --noconfirm zsh git neovim python-pynvim firefox openssh wget

useradd -m -s /bin/zsh $user
usermod -aG wheel $user
EDITOR=nvim visudo

echo 'set root password.'
passwd

echo "set $user password."
passwd $user

}

if [[ $# -eq 1 ]]; then
    $1
else
    prepare
fi

