# Introduction

This Package forms part of the seL4 Developer Kit. It provides a fully
coordinated build of a MaaXBoard Microkit program which leverages BuildRoot
(embedded Linux build facility) and libvmm (virtual machine monitor for the
seL4 microkernel) to provide a virtualised Linux Guest interacting with
physical (pass-through) UART (for TTY).

# Usage

Must be invoked inside the following:
* sel4devkit-maaxboard-microkit-docker-dev-env

Show usage instructions:
```
make
```

Build:
```
make all
```

# Maintenance

Presents detailed technical aspects relevant to understanding and maintaining
this Package.

## Retain Previously Built Output

For consistency and understanding, it is generally desirable to be able to
build from source. However, in this instance, the build process can be
particularly time consuming. As a concession, the build output is prepared in
advance, and retained in the Package. Where this previously built output is
present, it shall block a rebuild. If the previously built output be removed
(`make reset`), then a rebuild may be triggered (`make all`).

The retention of build artefacts is ordinarily avoided, and this is reflected
in the configured set of file types to be ignored. As such, following a
rebuild, to examine and retain the resulting content (including build
artefacts), instruct git as follows:

Examine all files, including any that are ordinarily ignored:
```
git status --ignored
```

Force the addition of files, even if they ordinarily ignored:
```
git add --force <Path Files>
```

## Pass Through

Physical UART is passed through to the virtualised Linux Guest. This is
indicated as Primary in the `program.system`. The inclusion of this device
triggers corresponding drivers to be loaded, which then seek access to further
physical devices. Thus, these additional devices also need to be passed
though. These are indicated as Secondary in the `program.system`.

## Build Root

The Build Root facility is used to generate an embedded Linux build for use as
the Linux guest. There are literally thousands of potential configuration
parameters in building a Linux guest. However, the default configurations
supplied by Build Root are likely perfectly reasonable. Thus, throughout, the
approach taken is to adopt the default configurations, only overriding these
where there is a specific reason to do so.

Effective use of Build Root may be framed through the following:
1. Initial configuration.
2. Retain configuration.
3. Build from retained configuration.
4. Refine retained configuration.

### Initial Configuration

Acquire Build Root:
```
curl "https://buildroot.org/downloads/buildroot-2024.02.4.tar.gz" --output buildroot-2024.02.4.tar.gz
gunzip buildroot-2024.02.4.tar.gz
tar --extract --file buildroot-2024.02.4.tar
```

Create a separate Build Root configuration:
```
mkdir initial_config
make -C ./buildroot-2024.02.4 O="../initial_config" menuconfig
```

Use the interactive "menuconfig" facility to select a minimal initial default
configuration for our MaaXBoard target:
* Target Options::Target Architecture (AArch64 (little endian))
* Toolchain::Toolchain type (External toolchain)
* Kernel::Linux Kernel
* Kernel::Linux Kernel::Kernel configuration (Use the architecture default configuration)
* Filesystem images::cpio the root filesystem (for use as an initial RAM filesystem)
* Filesystem images::cpio the root filesystem::Compression method (gzip)

Save the `.config` at the default location, which shall be within
`./initial_config`.

Build the Linux guest. Note that this typically take a long time:
```
make -C ./buildroot-2024.02.4 O="../initial_config"
```

### Retain Configuration

The initial configuration will explicitly list every reachable configurable
setting, which is likely contains several thousand entries. Further, this
configuration is likely to be very tightly coupled to the specific instance of
Build Root, and its selected Linux Kernel. To mitigate these concerns, it is
recommended to instead retain only the portions of the configuration which
differ from the defaults.

Create an area to retain the configuration:
```
mkdir config
```

Retain compact Linux Kernel configuration for the chosen architecture:
```
make -C ./initial_config/build/linux-6.6.37 ARCH=arm64 savedefconfig
cp ./initial_config/build/linux-6.6.37/defconfig ./config/linux.defconfig
```

Modify the Build Root configuration to cite the separate Linux Kernel
configuration:
```
make -C ./buildroot-2024.02.4 O="../initial_config" menuconfig
```

Use the interactive "menuconfig" facility to select a custom Linux Kernel
configuration:
* Kernel::Linux Kernel::Kernel configuration (Using a custom (def)config file)
* Kernel::Linux Kernel::Configuration file path (../config/linux.defconfig)

Save the `.config` at the default location, which shall be within
`./initial_config`.

Note that for Build Root, all paths are relative to the location of its
outermost Makefile. Since the Build Root Makefile resides at
`./buildroot-2024.02.4/Makefile` our relative configuration is at
`../config/linux.defconfig`.

Retain compact Build Root configuration:
```
make -C ./buildroot-2024.02.4 O="../initial_config" savedefconfig
cp ./initial_config/defconfig ./config/buildroot.defconfig 
```

At this stage, the entirety of the required configuration has been retained in
path `config`.

### Build from Retained Configuration

Where the required configuration is present in `./config` a complete build
from the retained configuration may be performed as follows:
```
curl "https://buildroot.org/downloads/buildroot-2024.02.4.tar.gz" --output buildroot-2024.02.4.tar.gz
gunzip buildroot-2024.02.4.tar.gz
tar --extract --file buildroot-2024.02.4.tar
mkdir assemble
cp ./config/buildroot.defconfig ./assemble/.config
cp ./config/linux.defconfig ./assemble/linux.defconfig
make -C ./buildroot-2024.02.4 O="../assemble" olddefconfig
make -C ./buildroot-2024.02.4 O="../assemble"
```

The built Linux Kernel image is at `./assemble/images/Image` while the built
initrd (initial RAM disk) is as `./assemble/images/rootfs.cpio.gz`.

### Refine Retained Configuration

While the default configuration is likely perfectly reasonable, it can
advantageous to make refinements. In particular, the default configuration
likely includes many components not needed for any given guest.

Following a build from the retained configuration, the complete expanded
configurations are available as follows:
* Build Root: `./assemble/.config`
* Linux Kernel: `./assemble/build/linux-6.6.37/.config`

These may be manually edited, presented in their compact presentation, and
used to update the retained configuration.

Update process for Build Root:
```
make -C ./buildroot-2024.02.4 O="../assemble" savedefconfig
cp ./assemble/defconfig ./config/buildroot.defconfig 
```

Update process for Linux Kernel:
```
make -C ./assemble/build/linux-6.6.37 ARCH=arm64 savedefconfig
cp ./assemble/build/linux-6.6.37/defconfig ./config/linux.defconfig
```

### MaaXBoard Refined Configuration

For our MaaXBoard target, we choose to remove support for all other
architectures, and remove support for all module drivers, to minimise both
size and build time.

For repeatability, this was achieved by modifying the Linux Kernel
configuration as follows:
```
sed -i 's/=m/=n/g' .config
sed -i -e "s/\(CONFIG_ARCH_ACTIONS\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_ALPINE\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_APPLE\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BCM2835\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BCMBCA\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BCM_IPROC\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BCM\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BERLIN\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_BRCMSTB\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_EXYNOS\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_HISI\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_INTEL_SOCFPGA\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_K3\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_KEEMBAY\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_LAYERSCAPE\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_LG1K\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_MA35\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_MEDIATEK\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_MESON\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_MVEBU\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_NPCM\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_QCOM\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_REALTEK\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_RENESAS\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_ROCKCHIP\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_S32\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_SEATTLE\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_SPARX5\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_SPRD\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_STM32\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_SUNXI\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_SYNQUACER\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_TEGRA\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_TESLA_FSD\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_THUNDER2\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_THUNDER\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_UNIPHIER\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_VEXPRESS\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_VISCONTI\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_XGENE\)=y/\1=n/g" .config
sed -i -e "s/\(CONFIG_ARCH_ZYNQMP\)=y/\1=n/g" .config
```
