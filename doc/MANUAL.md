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
make get
make all
```

Where executed on the MaaXBoard, the Virtualised Linux Guest will boot to a
prompt. The default password applies, which is: "root".

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
