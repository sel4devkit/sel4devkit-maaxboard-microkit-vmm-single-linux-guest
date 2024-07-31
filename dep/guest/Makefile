################################################################################
# Makefile
################################################################################

#===========================================================
# Check
#===========================================================
EXP_INFO := sel4devkit-maaxboard-microkit-docker-dev-env 1 *
CHK_PATH_FILE := /check.mk
ifeq ($(wildcard ${CHK_PATH_FILE}),)
    HALT := TRUE
else
    include ${CHK_PATH_FILE}
endif
ifdef HALT
    $(error Expected Environment Not Found: ${EXP_INFO})
endif

#===========================================================
# Layout
#===========================================================
SRC_PATH := src
TMP_PATH := tmp
OUT_PATH := out

#===========================================================
# Usage
#===========================================================
.PHONY: usage
usage: 
	@echo "usage: make <target> [COMPLETE=TRUE]"
	@echo ""
	@echo "<target> is one off:"
	@echo "all"
	@echo "clean"
	@echo "reset"

#===========================================================
# Target
#===========================================================
.PHONY: all
all: ${OUT_PATH}/Image ${OUT_PATH}/rootfs.cpio.gz

${TMP_PATH}:
	mkdir ${TMP_PATH}

${OUT_PATH}:
	mkdir ${OUT_PATH}

ifdef COMPLETE
# Cache with dependencies.
${OUT_PATH}/Image: ${TMP_PATH}/assemble/images/Image | ${OUT_PATH}
	cp -r $< $@

${OUT_PATH}/rootfs.cpio.gz: ${TMP_PATH}/assemble/images/rootfs.cpio.gz | ${OUT_PATH}
	cp -r $< $@
else
# Cache without dependencies.
${OUT_PATH}/Image ${OUT_PATH}/rootfs.cpio.gz:
	make all COMPLETE=TRUE
endif

${TMP_PATH}/assemble: | ${TMP_PATH}
	mkdir ${TMP_PATH}/assemble

${TMP_PATH}/assemble/.config: ${SRC_PATH}/buildroot.defconfig | ${TMP_PATH}/assemble
	cp ${SRC_PATH}/buildroot.defconfig ${TMP_PATH}/assemble/.config

${TMP_PATH}/assemble/linux.defconfig: ${SRC_PATH}/linux.defconfig | ${TMP_PATH}/assemble
	cp ${SRC_PATH}/linux.defconfig ${TMP_PATH}/assemble/linux.defconfig

${TMP_PATH}/assemble/images/Image ${TMP_PATH}/assemble/images/rootfs.cpio.gz &: ${TMP_PATH}/assemble/.config ${TMP_PATH}/assemble/linux.defconfig | ${TMP_PATH}
	# Acquire.
	curl "https://buildroot.org/downloads/buildroot-2024.02.4.tar.gz" --output ${TMP_PATH}/buildroot-2024.02.4.tar.gz
	gunzip ${TMP_PATH}/buildroot-2024.02.4.tar.gz
	tar --directory ${TMP_PATH} --extract --file ${TMP_PATH}/buildroot-2024.02.4.tar
	# Expand default config.
	make -C ${TMP_PATH}/buildroot-2024.02.4 O="../assemble" olddefconfig
	# Build.
	make -C ${TMP_PATH}/buildroot-2024.02.4 O="../assemble"

.PHONY: clean
clean:
	rm -rf ${TMP_PATH}

.PHONY: reset
reset: clean
	rm -rf ${OUT_PATH}

#===============================================================================
# End of file
#===============================================================================
