#!/bin/bash

# Copyright (c) 2016, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

set -e
set -x

u_boot_board="$1"

artifacts_out_dir="artifacts-out/${u_boot_board}"
rm -rf "${artifacts_out_dir}"
mkdir -p "${artifacts_out_dir}"

build_dir="build/u-boot/${u_boot_board}"
mkdir -p "${build_dir}"

arm=0
arm64=0
sandbox=0

if [ "${u_boot_board}" = "sandbox" ]; then
  sandbox=1
else
  set +e
  grep -qP 'CONFIG_TEGRA(20|30|114|124)=' "src/u-boot/configs/${u_boot_board}_defconfig"
  ret=$?
  set -e
  if [ ${ret} -eq 0 ]; then
    arm=1
  else
    arm64=1
  fi
fi

if [ ${arm} -eq 1 ]; then
    export CROSS_COMPILE="${HOME}/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-"
fi
if [ ${arm64} -eq 1 ]; then
    export CROSS_COMPILE="${HOME}/gcc-linaro-7.2.1-2017.11-i686_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
fi

set +e
grep -qP "V_PROMPT" "src/u-boot/include/configs/tegra-common.h"
ret=$?
set -e
if [ ${ret} -eq 0 ]; then
  sed -i -e 's/V_PROMPT/CONFIG_SYS_PROMPT/' "src/u-boot/include/configs/${u_boot_board}.h"
  sed -i -e '/V_PROMPT/d' "src/u-boot/include/configs/tegra-common.h"
fi

export PATH="${HOME}/dtc-1.4.3:${PATH}"

make -C src/u-boot O="`pwd`/${build_dir}" "${u_boot_board}_defconfig"
make -C src/u-boot O="`pwd`/${build_dir}" -j8

git -C src/u-boot rev-parse HEAD > "${artifacts_out_dir}/artifacts-build-u-boot-commit.txt"
tar -jcvf "${artifacts_out_dir}/artifacts-build-results.tar.bz2" "${build_dir}"
