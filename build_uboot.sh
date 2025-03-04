#! /bin/sh

uboot_path="${HOME}/vcs/u-boot"

sysroot=/home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin

export PATH=$sysroot:/usr/bin
export CROSS_COMPILE=arm-cortex_a8-linux-gnueabihf-
export ARCH=arm

cd "$uboot_path"

# Book Erratum: the updated uboot uses this config file, rather than the plainer
# am335x_boneblack_defconfig
# Do not try to use the vboot boneblack one.  You must use EVM
make am335x_evm_defconfig
make

# Thi screates relevant files: MLO, u-boot.img
