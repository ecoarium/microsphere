#!/bin/bash -eux

echo "==> Cleaning up yum cache of metadata and packages to save space"
yum -y clean all

echo "==> Removing temporary files used to build box"
rm -rf /tmp/*

echo '==> Zeroing out empty area to save space in the final image'
# Zero out the free space to save space in the final image.  Contiguous
# zeroed space compresses down to nothing.
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Block until the empty file has been removed, otherwise, Packer
# will try to kill the box while the disk is still full and that's bad
sync
