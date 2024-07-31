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
DEP_PATH := dep
SRC_PATH := src
TMP_PATH := tmp
OUT_PATH := out

DEP_DTS_PATH := ${DEP_PATH}/dts
DEP_GST_PATH := ${DEP_PATH}/guest
DEP_LVM_PATH := ${DEP_PATH}/libvmm
DEP_MKT_PATH := ${DEP_PATH}/microkit

#===========================================================
# Usage
#===========================================================
.PHONY: usage
usage: 
	@echo "usage: make <target>"
	@echo ""
	@echo "<target> is one off:"
	@echo "all"
	@echo "clean"

#===========================================================
# Target
#===========================================================
CPU := cortex-a53
TCH := aarch64-linux-gnu
CC := ${TCH}-gcc
LD := ${TCH}-ld
AS := ${TCH}-as

MKT_BOARD := maaxboard
MKT_CONFIG := debug

MKT_SDK_PATH := ${DEP_MKT_PATH}/out/microkit-sdk-1.2.6
MKT_PATH_FILE := ${MKT_SDK_PATH}/bin/microkit
MKT_RTM_PATH_FILE := ${MKT_SDK_PATH}/board/${MKT_BOARD}/${MKT_CONFIG}

LIBVMM_BOARD := BOARD_${MKT_BOARD}

LIBVMM_AARCH64_OBJ_PATH_FILE := \
    ${TMP_PATH}/fault.o \
    ${TMP_PATH}/imx_sip.o \
    ${TMP_PATH}/linux.o \
    ${TMP_PATH}/psci.o \
    ${TMP_PATH}/smc.o \
    ${TMP_PATH}/tcb.o \
    ${TMP_PATH}/vcpu.o \
    ${TMP_PATH}/vgic.o \
    ${TMP_PATH}/vgic_v3.o \
    ${TMP_PATH}/virq.o \

LIBVMM_COMMON_OBJ_PATH_FILE := \
    ${TMP_PATH}/util.o \
    ${TMP_PATH}/printf.o \
    ${TMP_PATH}/guest.o \

CC_OPS := \
    -c \
    -mcpu=${CPU} \
    -ffreestanding \
    -nostdlib \
    -mstrict-align \
    -g3 \
    -O3 \
    -Wall \
    -Wno-unused-function \
    -Werror \
    -I ${DEP_LVM_PATH}/out/libvmm/include \
    -I ${DEP_LVM_PATH}/out/libvmm/dep/sddf/include \
    -I ${MKT_RTM_PATH_FILE}/include \
    -D ${LIBVMM_BOARD} \

LD_OPS := \
    -L $(MKT_RTM_PATH_FILE)/lib \
    -lmicrokit \
    -Tmicrokit.ld \

#-------------------------------
# Target
#-------------------------------

.PHONY: all
all: ${OUT_PATH}/program.img

${DEP_DTS_PATH}/out/maaxboard.dts:
	make -C ${DEP_DTS_PATH} all

${DEP_GST_PATH}/out/Image ${DEP_GST_PATH}/out/rootfs.cpio.gz &:
	make -C ${DEP_GST_PATH} all

${DEP_LVM_PATH}/out/libvmm:
	make -C ${DEP_LVM_PATH} all

${DEP_MKT_PATH}/out/microkit-sdk-1.2.6:
	make -C ${DEP_MKT_PATH} all

${TMP_PATH}:
	mkdir ${TMP_PATH}

${OUT_PATH}:
	mkdir ${OUT_PATH}

${OUT_PATH}/program.img: ${DEP_MKT_PATH}/out/microkit-sdk-1.2.6 ${SRC_PATH}/program.system ${TMP_PATH}/client_vmm_1.elf | ${OUT_PATH}
	${MKT_PATH_FILE} ${SRC_PATH}/program.system --search-path ${TMP_PATH} --board ${MKT_BOARD} --config ${MKT_CONFIG} --output ${OUT_PATH}/program.img --report ${OUT_PATH}/report.txt

${TMP_PATH}/client_vmm_1.elf: ${TMP_PATH}/client_vmm.o ${TMP_PATH}/client_image_1.o ${LIBVMM_AARCH64_OBJ_PATH_FILE} ${LIBVMM_COMMON_OBJ_PATH_FILE} | ${TMP_PATH}
	${LD} $^ ${LD_OPS} -o $@

${TMP_PATH}/client_vmm.o: ${SRC_PATH}/client_vmm.c ${DEP_LVM_PATH}/out/libvmm | ${TMP_PATH}
	${CC} ${CC_OPS} $< -o $@

${TMP_PATH}/client_image_1.o: ${DEP_LVM_PATH}/out/libvmm/tools/package_guest_images.S ${DEP_GST_PATH}/out/Image ${DEP_GST_PATH}/out/rootfs.cpio.gz ${TMP_PATH}/maaxboard.dtb ${DEP_LVM_PATH}/out/libvmm | ${TMP_PATH}
	${CC} \
	-c \
	-g3 \
	-x assembler-with-cpp \
	-DGUEST_KERNEL_IMAGE_PATH=\"${DEP_GST_PATH}/out/Image\" \
	-DGUEST_DTB_IMAGE_PATH=\"${TMP_PATH}/maaxboard.dtb\" \
	-DGUEST_INITRD_IMAGE_PATH=\"${DEP_GST_PATH}/out/rootfs.cpio.gz\" \
	"${DEP_LVM_PATH}/out/libvmm/tools/package_guest_images.S" \
	-o $@

${TMP_PATH}/maaxboard.dtb: ${DEP_DTS_PATH}/out/maaxboard.dts ${SRC_PATH}/maaxboard-overlay.dts | ${TMP_PATH}
	cat $^ > ${TMP_PATH}/guest.dts
	dtc -q -I dts -O dtb ${TMP_PATH}/guest.dts -o $@

${TMP_PATH}/%.o: ${DEP_LVM_PATH}/out/libvmm/src/%.c | ${TMP_PATH}
	${CC} ${CC_OPS} $< -o $@

${TMP_PATH}/%.o: ${DEP_LVM_PATH}/out/libvmm/src/util/%.c | ${TMP_PATH}
	${CC} ${CC_OPS} $< -o $@

${TMP_PATH}/%.o: ${DEP_LVM_PATH}/out/libvmm/src/arch/aarch64/%.c | ${TMP_PATH}
	${CC} ${CC_OPS} $< -o $@

${TMP_PATH}/%.o: ${DEP_LVM_PATH}/out/libvmm/src/arch/aarch64/vgic/%.c | ${TMP_PATH}
	${CC} ${CC_OPS} $< -o $@

.PHONY: clean
clean:
	make -C ${DEP_DTS_PATH} clean
	make -C ${DEP_GST_PATH} clean
	make -C ${DEP_LVM_PATH} clean
	make -C ${DEP_MKT_PATH} clean
	rm -rf ${TMP_PATH}
	rm -rf ${OUT_PATH}

#===============================================================================
# End of file
#===============================================================================
