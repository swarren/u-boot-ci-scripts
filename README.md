This repository contains scripts that invoke U-Boot's build and test processes.
They are intended to be run under a continuous integration system such as
Jenkins.

Separate build and test scripts are provided to enable the two steps to be
performed on different physical systems, or at different times, if desired. For
example, one might have a Jenkins configuration where all builds are performed
on a single high-power master machine, yet testing is delegated to a low-power
slave machine, which has the test hardware attached.

These scripts implement as much as possible themselves, with the hope that any
changes to the process can be isolated to the scripts, rather than a combination
of the scripts and the continuous integration system's configuration.

For an example of the Jenkins job configuration that may be used to launch these
scripts, see https://github.com/swarren/u-boot-ci-jjb.
