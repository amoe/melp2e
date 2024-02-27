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

## Ch2: Learning about toolchains

CS will show how to create a toolchain using _crosstool-NG_.

A toolchain is this:
* Compiler
* Linker
* Runtime libraries implementing POSIX

You need it to build the other elements so it's the most fundamental.  It needs
to support some form of assembly, C, and C++.

Clang can be used as a tool to build the kernel but this is still a variation
rather than the main method.  GCC is the main/preferred choice.

The GNU toolchain has the following parts:

* binutils (assembler and linker)
* GCC
* C library (there are multiple options here.)
* GDB debugger

You need to generate a special set of kernel headers (pp21).  Kernel headers are
always backwards compatible so you just need to use a set of kernel headers that
is older than your kernel target.

There are two types of toolchain: a native toolchain and a cross toolchain.
Mostly we will use a cross toolchain in order to do development and compilation
on a fast system and then to transfer it to the limited resource system.  It is
also good to introduce a distinction between the host and the target.  If they
use the same architecture, it might be tempting to native compile on the host.
But this might break in strange ways later.  There are certain arguments for
native compilation but they're mostly outside the scope of MELP.

CPU architectures: Not all CPUs have a hardware FPU.  Hence the existence of
things like fixed-point decoders for Vorbis for use in embedded applications.
The toolchain can be configured to generate calls to software implementations of
floating point math instead.  There is also an ABI/calling convention.  The ABI
is not really a property of the CPU itself but rather is an agreement/contract
between the compiler and the operating system.  However the ABI will be defined
in the terms of the capabilities provided by the CPU -- and actually some
manufacturers do define a detailed ABI especially ARM.

ARM has two diverged ABIs, one for processors with FPUs, and one for processors
without.  EABIHF is preferred, but requires FPU.

The toolchain has a specific name.  This consists of CPU, vendor (optional),
kernel and a userspace component.  These are pretty much opaque strings.  You
can check the toolchain tuple by running `gcc -dumpmachine`.  For instance, I
get `x86_64-linux-gnu` on my Debian system.  The tuple prefixes all the tools in
the PATH, and the `gcc` command is usually a link to the tuple-qualified
version:

    amoe@sprinkhaan $ ls -l /usr/bin/gcc-12                                                                                                                                                                     0.01s 
    lrwxrwxrwx 1 root root 23 Jan  8  2023 /usr/bin/gcc-12 -> x86_64-linux-gnu-gcc-12

C library: Musl may be necessary if you have less than 32M main memory,
otherwise, use glibc.

Sometimes you can get a prebuilt toolchain from a vendor.  This may be worth
doing but it's not a fully reliable option.  crosstool-NG and buildroot/Yocto
all solve this issue, though.

### crosstool-NG

crosstool-ng is not in Debian.  As of the date of these notes 2024-02, the
latest is 1.26.0.  You can install it doing the standard autotools method.  It
installs a single binary, `ct-ng`.  It comes with some samples: `ct-ng
list-samples`.

One sample is quite close to our target board: `arm-cortex_a8-linux-gnueabi`
GNU EABI is vs EABIHF (hard float).  EABIHF is not compatible with CPUs that
don't have an FPU.  EABI passes floating point values in integer registers which
is not as fast.

    amoe@sprinkhaan $ ct-ng show-arm-cortex_a8-linux-gnueabi                                                                                                                                                    0.09s 
    [G...]   arm-cortex_a8-linux-gnueabi
        Languages       : C,C++
        OS              : linux-6.4
        Binutils        : binutils-2.40
        Compiler        : gcc-13.2.0
        C library       : glibc-2.38
        Debug tools     : duma-2_5_21 gdb-13.2 ltrace-0.7.3 strace-6.4
        Companion libs  : expat-2.5.0 gettext-0.21 gmp-6.2.1 isl-0.26 libelf-0.8.13 libiconv-1.16 mpc-1.2.1 mpfr-4.2.1 ncurses-6.4 zlib-1.2.13 zstd-1.5.5

Run `ct-ng arm-cortex_a8-linux-gnueabi` to 'choose' this sample.  This writes a
file in the current directory.  Then, `ct-ng menuconfig` will take you into a
curses-based menu feature.

You need to unselect "render the toolchain read only", and enable hardware FPU.
Enabling hardware FPU switches to EABIHF, so we're deviating from the sample
here.  menuconfig writes all your config into the .config file.  ct-ng also
expects a local directory './src' to store tarballs in.  It downloads tarballs
for all pieces.  It patches them.  Then, all pieces will be built in dependency
order.
