#!/bin/bash

# Copyright (c) 2016-2019, NVIDIA CORPORATION. All rights reserved.
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

script_dir="$(cd "$(dirname "$0")" && pwd)"

u_boot_board="$1"

artifacts_out_dir="artifacts-out"
rm -rf "${artifacts_out_dir}"
mkdir -p "${artifacts_out_dir}"

artifacts_in_dir="artifacts-in"
build_dir="build/u-boot/${u_boot_board}"
# Don't put this in e.g. ./build/venv/${u_boot_board}; the #! line will become
# so long that the kernel truncates it and can't find the Python interpreter:-(
venv_dir="/tmp/venv-$$"
ubtest_dir="src/uboot-test-hooks"
ubtest_bin_dir="${ubtest_dir}/bin"
ubtest_py_dir="${ubtest_dir}/py"

u_boot_commit=$(cat "${artifacts_in_dir}/artifacts-build-u-boot-commit.txt")
git -C src/u-boot checkout ${u_boot_commit}

rm -rf "${build_dir}"
tar -jxvf "${artifacts_in_dir}/artifacts-build-results.tar.bz2"

export PATH="${script_dir}/tools:$(pwd)/${ubtest_bin_dir}:${PATH}"
export PYTHONPATH="$(pwd)/${ubtest_py_dir}/$(hostname):${PYTHONPATH}"

if [ -f ./src/u-boot/test/py/requirements.txt ]; then
    os_release=$(lsb_release -a 2>/dev/null|grep ^Codename:|awk '{print $2}')
    nopip=
    if [ "${os_release}" == "xenial" ]; then
        nopip=--no-pip
    fi
    rm -rf "${venv_dir}"
    virtualenv -p /usr/bin/python3 ${nopip} "${venv_dir}"
    . "${venv_dir}/bin/activate"
    if [ "${os_release}" == "xenial" ]; then
        python "${script_dir}/get-pip.py" pip==20.3.4
    fi
    pip install -r ./src/u-boot/test/py/requirements.txt
fi

if [ "${u_boot_board}" != sandbox ]; then
  u-boot-test-power-on "${u_boot_board}" na
fi

set +e
./src/u-boot/test/py/test.py --bd "${u_boot_board}" --build-dir "$(pwd)/${build_dir}" -k "not sleep"
ret=$?
rm -rf "${venv_dir}"
set +e

cp "${build_dir}/test-log.html" "${artifacts_out_dir}" || true
cp "${build_dir}/multiplexed_log.css" "${artifacts_out_dir}" || true

if [ "${u_boot_board}" != sandbox ]; then
  u-boot-test-power-off "${u_boot_board}" na
fi

exit ${ret}
