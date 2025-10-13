
# delete /boot directory
rootfs_postprocess_function() {
   rm -rf ${IMAGE_ROOTFS}/boot
}

# configure root password
inherit extrausers
EXTRA_USERS_PARAMS = "\
   usermod -p '\$1\$TzpfaNEc\$tjqCamkIJFUytJokydS8w.' root \
"

ROOTFS_POSTPROCESS_COMMAND:append = " rootfs_postprocess_function; "
