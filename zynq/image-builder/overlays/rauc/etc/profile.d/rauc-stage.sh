# /etc/profile.d/rauc-stage.sh
# Release /stage before "rauc install": RAUC refuses to write a slot that is
# mounted when the installation starts, and its handlers run too late.
rauc() {
    if [ "${1:-}" = "install" ]; then
        systemctl stop stage-setup.service || return 1
        if ! command rauc "$@"; then
            # Installation failed: restore the staging area (the setup
            # script never touches a slot that is the next boot target)
            systemctl start stage-setup.service
            return 1
        fi
    else
        command rauc "$@"
    fi
}
