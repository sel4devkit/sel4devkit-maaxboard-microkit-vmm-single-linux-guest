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
all: ${OUT_PATH}/maaxboard.dts

${TMP_PATH}:
	mkdir ${TMP_PATH}

${OUT_PATH}:
	mkdir ${OUT_PATH}

ifdef COMPLETE
# Cache with dependencies.
${OUT_PATH}/maaxboard.dts: ${TMP_PATH}/maaxboard.dts | ${OUT_PATH}
	cp -r $< $@
else
# Cache without dependencies.
${OUT_PATH}/maaxboard.dts:
	make all COMPLETE=TRUE
endif

${TMP_PATH}/maaxboard.dts: | ${TMP_PATH}
	# Acquire.
	git -C ${TMP_PATH} clone --branch "maaxboard_lf-6.1.22-2.0.0" "git@github.com:Avnet/linux-imx.git" linux-imx
	# Extract.
	cpp -nostdinc -I ${TMP_PATH}/linux-imx/include -undef -x assembler-with-cpp ${TMP_PATH}/linux-imx/arch/arm64/boot/dts/freescale/maaxboard.dts -o ${TMP_PATH}/maaxboard.dts

.PHONY: clean
clean:
	rm -rf ${TMP_PATH}

.PHONY: reset
reset: clean
	rm -rf ${OUT_PATH}

################################################################################
# End of file
################################################################################
