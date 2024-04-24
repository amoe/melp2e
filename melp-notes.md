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

    amoe@sprinkhaan $ ct-ng show-arm-cortex_a8-linux-gnueabi
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

ct-ng doesn't have great directory hygiene.  By default it stores things in the
current directory as well as `~/x-tools`.  I modified it to set the prefix dir
(`CT_PREFIX_DIR`) thus:

    CT_PREFIX_DIR="/home/amoe/ct-ng/x-tools/${CT_HOST:+HOST-${CT_HOST}/}${CT_TARGET}"

Of course it also stores temporary stuff in a local `build` directory.  You need
a fairly large amount of free space to build the toolchain.

I build 2 toolchains:

* /home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf
* /home/amoe/ct-ng/x-tools/arm-unknown-linux-gnueabi

That means the the Beaglebone compiler lives at:

    /home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-gcc

There are no symlinks defining `gcc` -> the long name, everything has the
toolchain tuple in its name.

If I then run:

    amoe@sprinkhaan $ ~/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-gcc -o hello hello.c


I build my hello world program.  I can't execute this on sprinkhaan: I get

    amoe@sprinkhaan $ ./hello                                                                        0.01s 
    zsh: exec format error: ./hello

Which is what I would expect.

    amoe@sprinkhaan $ file hello                                                                     0.01s 
    hello: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 6.4.0, with debug_info, not stripped

It shows that it's 32 bit which is interesting.  It's interesting that 32 bit is
still a concern.

Using this lil command you can list out the specs in a nice format:

    ~/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/bin/arm-cortex_a8-linux-gnueabihf-c++ -v 2>&1 | sed -n 's|Configured with: ||p' | tr ' ' '\n'

This shows:

    --build=x86_64-build_pc-linux-gnu
    --host=x86_64-build_pc-linux-gnu
    --target=arm-cortex_a8-linux-gnueabihf
    --prefix=/home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf
    --exec_prefix=/home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf
    --with-sysroot=/home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/arm-cortex_a8-linux-gnueabihf/sysroot
    --enable-languages=c,c++
    --with-cpu=cortex-a8
    --with-float=hard
    --with-pkgversion='crosstool-NG
    1.26.0'
    --enable-__cxa_atexit
    --disable-libmudflap
    --disable-libgomp
    --disable-libssp
    --disable-libquadmath
    --disable-libquadmath-support
    --disable-libsanitizer
    --disable-libmpx
    --with-gmp=/home/amoe/ct-ng/build/arm-cortex_a8-linux-gnueabihf/buildtools
    --with-mpfr=/home/amoe/ct-ng/build/arm-cortex_a8-linux-gnueabihf/buildtools
    --with-mpc=/home/amoe/ct-ng/build/arm-cortex_a8-linux-gnueabihf/buildtools
    --with-isl=/home/amoe/ct-ng/build/arm-cortex_a8-linux-gnueabihf/buildtools
    --enable-lto
    --enable-threads=posix
    --enable-target-optspace
    --enable-plugin
    --enable-gold
    --disable-nls
    --disable-multilib
    --with-local-prefix=/home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/arm-cortex_a8-linux-gnueabihf/sysroot
    --enable-long-long

There are two general approaches for handling toolchains in a project:

1.  Built separate distinct toolchains for every target that you want to build
    for.

2.  Ensure you pass sufficient compiler options to a generic toolchain to
    configure it entirely for the target.  (e.g. -mcpu=)


CS refers to 1) as the "Buildroot philosophy", while 2) is the "Yocto
philosophy".  2 sounds better, but you can't make an entirely generic toolchain

Note that "-mcpu" was deprecated in GCC 13.  If a toolchain is built for ARM, it
still can't compile for X86 and vice versa

There is something called a sysroot:

    /home/amoe/ct-ng/x-tools/arm-cortex_a8-linux-gnueabihf/arm-cortex_a8-linux-gnueabihf/sysroot

This seems to contain a root filesystem?  It seems to be some sort of skeleton
of an OS for the target.  Mostly headers, programs and shared data used to
implement the C library.

The C library comprises four components: libc, libm, libpthread, librt.

We know what all of these do except for librt.  librt implements shared memory
(`shm_open`) and asynchronous I/O (`aio_open` etc).

Dynamically linking to libc is the default but you can also link statically by
passing `-static` option.  A statically linked "hello world" is 2.8MB, but only
12k if dynamically linked.  Static linking pulls in all the code from `libc.a`
to link the C library.  Checking for `libc.a` under the sysroot shows that it is
21MB in size.

Creating a static library just means using the `ar` tool from the toolchain to
put several `.o` files together.  You can do it yourself fairly easily.

When compiling a dynamic library, you compile using the -`fPIC` switch.  I
created examples of building both library types in the toolchain using
`build_library.sh` in the repository root.

The MELP repository contains a script called `list-libs`, this script invokes
`readelf` from the toolchain in order to get information about a .so file.
Readelf outputs a lot of info.

    amoe@sprinkhaan $ ${TOOLCHAIN}/readelf -a libtest.so | grep NEEDED
    0x00000001 (NEEDED)                     Shared library: [libc.so.6]

This will tell you which libraries the .so file depends on and it also shows the
location ot the runtime linker which is hardcoded into the executable.  The
notorious `LD_LIBRARY_PATH` allows one to override the hardcoded search paths at
runtime (which will presumably be prepended to the hardcoded one).

XXX: What does position-independent code mean?  Due to virtual memory provided
by Linux, each process sees its own address space and can't interfere with the
address space of other programs (protected memory).  Hence non-PIC code may be
"hardcoded" to run at 0x00004000, but that is still "relative" to the virtual
memory space of the process (the actual memory address in global terms may be
something different.)  It kind of makes sense that shared libraries would need
to be compiled as PIC because they get compiled and loaded in a different
command, but I'm still not sure it 100% makes sense.

A version scheme exists consisting of several parts:
* release version
* soname

A release version is a full version e.g. 8.0.2.
A soname is a single integer representing the major version corresponding to a
release version.  e.g. it would be 8 in the case of 8.0.2.
Links exist: libjpeg.so.8 -> libjpeg.so.8.0.2
When programs are built using a library, they request the soname link.  So it's
possible to have multiple major versions of libraries installed on a system
without stuff breaking.

The link `libjpeg.so -> libjpeg.so.8.0.2` is used at build time -- it makes sure
we pick up the default most-current version of the library when building.
The link `libjpeg.so.8 -> libjpeg.so.8.0.2` is used at run time.

Q: How do you set sonames and versions numbers?

CS chooses not to cover CMake which I'm temporarily happy about.

A make variable exists called CROSS_COMPILE.

CS goes over a bit of stuff about configuring busybox but we don't have any
practical demos yet so let's elide this for now.

### Cross compiling open source packages

You set certain variables in the environment to influence the behaviour of the
autotools configure script:

CC, CFLAGS, LDFLAGS (-L for example), LIBS (eg -lm), CPPFLAGS (preprocessor
flags for includes), CPP (preprocessor command name)

Autotools `./configure` also provides a way to override the "host" -- "host"
means the eventual system that will "host" the running program, i.e. in this
case it would be `arm-cortex_a8-linux-gnueabihf`.

You also would want to set the prefix to be `/usr` because if it's linked
against shared libraries, those libraries would be expected to be found there.

So a typical cross compile command for a package that uses autotools would
look as follows:

    CC=arm-cortex_a8-linux-gnueabihf \
      ./configure --host=arm-cortex_a8-linux-gnueabihf --prefix=/usr

CS gives an example of how to cross compile sqlite.

I created a script to implement this.  It's in `build_and_install_sqlite.sh`.
It does seem to work and creates a `sqlite3` file in sysroot under the
toolchain.  It also creates appropriate links for .so files.  Amusingly
libsqlite is still on soname 0 meaning it has never broken API, but it does have
3 in its name, which seems like a hack.

Having installed these under the toolchain, you should then be able to compile
and link.  And indeed it does seem to be possible!  As the stuff is already in
the sysroot you can just use the toolchain's gcc.  The toolchain's gcc already
knows about the locations of the libraries and the header files.

### pkg-config

pkg-config files are also installed under /usr/lib/pkgconfig under the sysroot.

Using the environment variable `PKG_CONFIG_LIBDIR` you can force the pkg-config
tool to read from the database under the sysroot:

PKG_CONFIG_LIBDIR=$(getsysroot)/usr/lib/pkgconfig pkg-config sqlite3 --libs
--cflags

Whenever someone uses a non-autotools environment it probably necessitates a
giant mess of hacks to fix the lack of support for cross compiling that
inevitably results.  This is unsustainable for packages with lots of
dependencies.


## Ch2: Bootloaders

The bootloader: *passes control from itself to the kernel using a device tree*.
We will use U-Boot as an example.  How does it differ from grub?  There is also
one called Barebox.

The bootloader has two jobs: load the kernel, provide a device tree, and provide
a kernel command line string.

*Reset vector*: A specific location in non-volatile memory stores a pointer to
the start instruction after system reset.  The CPU will jump to the value stored
at the reset vector to start executing.

A DRAM memory controller ensures the RAM's capacitors get refreshed.


### Boot sequence 

The modern way of booting involves multiple steps.  This is because the DRAM
memory controller needs to be bootstrapped.  Modern bootloaders are too large to
fit into the small amount of SRAM provided on 

* Code hardcoded into ROM loads something called an SPL (secondary program
  loader) into SRAM.  (DRAM can't be used yet.)
* SPL sets up the memory controller to enable DRAM use.  SPL can read file
  systems and pre-programmed file names.  The SPL loads the *tertiary program
  loader* into DRAM.
* The TPL loads into DRAM the kernel image, plus initramfs and a device tree.

There seems to be 128kb of SRAM on the Sitara AM3358 which is indeed a small
amount.


### UEFI boot

* Load UEFI firmware.
* UEFI firmware initializes DRAM controller.  Loads "real" bootloader (TPL) from
  UEFI system partition which must be FAT32 or FAT16.  This loader is found at a
  hardcoded location.
* TPL loads kernel, initramfs, device tree.


There is more info available here:
https://android.googlesource.com/kernel/msm/+/android-msm-hammerhead-3.4-kk-r1/Documentation/arm/Booting

### Device trees

There was something called "A tags" which is described above as "kernel tagged
list".  But device trees are the successor to A tags, because they don't require
information to be hardcoded into the kernel source.

Device trees are specified in .dts files.

Is there a validator for .dts files?  Not sure.

The device tree is actually a graph, because nodes can have labels.

The DTS file for Beaglebone Black is located at
arch/arm/boot/dts/am335x-boneblack.dts in the kernel source tree.

I have captured the memory below

```
/ {
    #address-cells = <2>;
    #size-cells = <2>;
    memory@80000000 {
        device_type = "memory";
        reg = <0x00000000 0x80000000 0 0x80000000>;
    };
};
```

Here we have memory along with a reg property.
The reg property defines two pairs.

DTS files frequently use #include directives to capture base behaviour and
implement types of inheritance to reduce duplication.

OpenFirmware specifies the use of `/include/`, but the kernel source uses
`#include`.

The kernel's Kbuild build system runs the C preprocessor over the DTS files
allowing use of CPP directives.

You use the `&` notation to bind to previously defined nodes and modify/override
them.

```
&mmc1 {
    status = "okay";
}
```

Here we override the `status` property and set it to `okay` which will cause it
to be initialized with a device driver.  

On the Beaglebone Black, we connect the MMC controller to a different voltage
regulator:

```
&mmc1 {
    vmmc-supply = <&vmmcsd_fixed>;
}
```

Here we refer to a previously defined node `vmmcsd_fixed` via the label/phandle.

The device tree compiler is named `dtc` and creates an output file `.dtb`, a
_device tree blob_.  Dtc lives in the linux source.  It's package on Debian as
`device-tree-compiler`.  It installs /usr/bin/dtc.

Most stuff is built using Kbuild, though.
