#!/bin/sh
loop=`sudo losetup --partscan --find --show fs.img`
part=${loop}p1
echo loop = $loop
echo part = $part
sudo mkfs -t ext4 -F -L root $part
mkdir -p ./fs
sudo mount $part ./fs
#cd linux/riscv64-chroot
echo copying files ....
#sudo find . | sudo cpio -pudm ../../fs
#cd ../..
cd fs
sudo tar xf ../linux/buildroot-2021.05-rc2/output/images/rootfs.tar
cd ..
echo copying kernel ....
sudo cp linux/linux/vmlinux fs
sudo chown root fs/vmlinux
sync
sudo umount $part
sudo losetup -d $loop
echo done
exit 0
