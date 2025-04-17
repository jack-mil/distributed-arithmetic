#!/usr/bin/bash

# --------------------------------------------- #
# Add the Xilinx directories to Git Bash PATH
# using the Bash for Windows path format
#
# Source this file to make `vivado` command
# available in Bash. This replaces the
# ".settings64-Vivado.sh" that ships with
# the Vivado installer
#
# TODO: Update to also support Linux
# --------------------------------------------- #

prepend_path() {
    # Add first arg to front of PATH, only if not in PATH already
    if [[ -d "${1}" ]] && [[ ! "${PATH}" =~ (^|:)"$1"(:|$) ]]; then
        PATH="${1}${PATH:+":${PATH}"}" # handle's blank PATH (unlikely)
    else
        return 1
    fi
}

export XILINX_VIVADO="/c/Xilinx/Vivado/2024.2"

if [[ -d ${XILINX_VIVADO} ]]; then
    prepend_path "${XILINX_VIVADO}/lib/win64.o"
    prepend_path "${XILINX_VIVADO}/bin"
else
    echo "Vivado installation not found at: ${XILINX_VIVADO}"
    return 1
fi
