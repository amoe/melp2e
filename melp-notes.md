# MELP notes

## Preface

The major components are: the kernel, Yocto, and Buildroot.

A chapter will exist on over-the-air updates and power management.

Simmonds was using Ubuntu 16.04 (Xenial), I believe this was current with Debian
Bullseye.  Apparently some tasks do not respond well to being run in a VM so
it's recommended to run them on a native host.  Distribution compatibility could
become important, therefore.

QEMU and BeagleBone Black are both potential targets.

## Ch1: Starting Out

An SoC is an IC that is essentially a mini computer in a single board.  It
differs from a motherboard in that individual pieces can't be replaced, and it's
generally much smaller.

Regarding the kernel, CS writes:

> Complexity makes it harder to understand. Coupled with the fast moving
> development process and the decentralized structures of open source, you have to
> put some effort into learning how to use it and to keep on re-learning as it
> changes.

Alternative OS in the past has been things like VxWorks, an 'RTOS'.  An RTOS is
not time-sharing, like Linux.  RTOS must explicitly recognize and bind all time
constraints.

When developing for an SoC-based board, you can't use the stock kernel (!) You
will generally need a patched version.

Toolchain, bootloader, kernel, root filesystem: these are the elements of
embedded.  And CS mentions a fifth element:

> That is the collection of programs specific to your embedded application which
> make the device do whatever it is supposed to do, be it weigh groceries,
> display movies, control a robot, or fly a drone.

This is what I am really interested in, but this is specific to the application.

Most architectures have an MMU.  ARM, MIPS, x86 are the most common
architectures.  There is also Linux for devices without MMUs that is called
uClinux.  You need RAM too, but not very much!  16MiB is the minimum that CS
calls for; even this may not be the absolute bare minimum.  You need storage, at
least 8MiB, and you can get this with flash memory.  NOR and NAND flash are
types of non volatile memory.  NOR is faster/better and more expensive, and
might be used for what would traditionally be ROM layers like a base system,
while you might use NAND for larger user data or logs, etc.

An RS-232 serial port is used for debugging.  SoCs can load boot code directly
from interfaces like SD cards or USB.

### BeagleBone Black specs

ARM 1GHz CPU, 512MB RAM, 4GiB onboard flash eMMC, serial port, microSD
connector, USB port, Ethernet port, HDMI port

You can fit "daughter" boards called 'capes'.

You also need this:

> An RS-232 cable that can interface with the 6-pin 3.3V TTL level signals
> provided by the board. The Beagleboard website has links to compatible cables.

I definitely don't have this at present.

The current one is BEAGLEBONE BLK REV C AM3358BZCZ

### QEMU

Qemu can emulate different pieces of hardware.

`qemu-system-arm` is the basic command to emulate an ARM system.

QEMU can connect files on the host system to e.g. the SD card of the emulated
device.

You need to use `tunctl` on the host to create a network interface on the host which
connects to the guest.  CS gives the command for this.
