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

artifacts_in_dir="artifacts-in"
build_dir="build/u-boot"
ubtest_dir="src/uboot-test-hooks"
ubtest_bin_dir="${ubtest_dir}/bin"
ubtest_py_dir="${ubtest_dir}/py"

tar -xvf "${artifacts_in_dir}/artifacts-build-results.tar"
tar -xvf "${artifacts_in_dir}/artifacts-build-test-py.tar"

set +e
PATH="`pwd`/${ubtest_bin_dir}:${PATH}" \
  PYTHONPATH="`pwd`/${ubtest_py_dir}/`hostname`:${PYTHONPATH}" \
  ./src/u-boot/test/py/test.py --bd "${u_boot_board}" --build-dir "`pwd`/${build_dir}"
ret=$?
set +e

cp "${build_dir}/test-log.html" "${artifacts_out_dir}" || true
cp "${build_dir}/multiplexed_log.css" "${artifacts_out_dir}" || true

exit ${ret}
