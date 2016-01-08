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

artifacts_out_dir="artifacts-out"
rm -rf "${artifacts_out_dir}"
mkdir -p "${artifacts_out_dir}"

build_dir="build/u-boot"
mkdir -p "${build_dir}"

arm=0
arm64=0

if [ "${u_boot_board}" != "sandbox" ]; then
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
    export CROSS_COMPILE=arm-none-eabi-
fi
if [ ${arm64} -eq 1 ]; then
    export CROSS_COMPILE=aarch64-linux-gnu-
fi

sed -i -e 's/V_PROMPT/CONFIG_SYS_PROMPT/' "src/u-boot/include/configs/${u_boot_board}.h"
sed -i -e '/V_PROMPT/d' "src/u-boot/include/configs/tegra-common.h"

make -C src/u-boot O="`pwd`/${build_dir}" "${u_boot_board}_defconfig"
make -C src/u-boot O="`pwd`/${build_dir}" -j8

artifact_files=()
artifact_files+=("${build_dir}/u-boot")
artifact_files+=("${build_dir}/.config")
artifact_files+=("${build_dir}/include/autoconf.mk")
if [ ${arm} -eq 1 ]; then
  artifact_files+=("${build_dir}/spl/u-boot-spl")
  artifact_files+=("${build_dir}/u-boot-nodtb-tegra.bin")
  artifact_files+=("${build_dir}/u-boot.dtb")
  artifact_files+=("${build_dir}/u-boot-dtb-tegra.bin")
fi
if [ ${arm64} -eq 1 ]; then
  artifact_files+=("${build_dir}/u-boot.bin")
  artifact_files+=("${build_dir}/u-boot.dtb")
  artifact_files+=("${build_dir}/u-boot-dtb.bin")
fi
tar -cvf "${artifacts_out_dir}/artifacts-build-results.tar" "${artifact_files[@]}"

if [ -d "src/u-boot/test/py" ]; then
  tar -cvf "${artifacts_out_dir}/artifacts-build-test-py.tar" "src/u-boot/test/py"
else
  echo WARNING: Using substitute u-boot/test/py archive
  cp "`dirname $0`/artifacts-build-test-py.tar" "${artifacts_out_dir}/artifacts-build-test-py.tar"
fi
