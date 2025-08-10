# releasehelper-menu
An interactive custom release helper script for [sd-webui-forge-docker](https://github.com/catspeed-cc/sd-webui-forge-docker) and [sd-webui-reforge-docker](https://github.com/catspeed-cc/sd-webui-reforge-docker) (will only work with these without modifications)

- run `git clone https://github.com/catspeed-cc/releasehelper-menu.git /path/to/where/you/want/rh-menu`
- run `echo "export PATH=${PATH}:/path/to/where/you/put/rh-menu" | tee -a ~/.bashrc`
- run `rh-menu` from inide [sd-webui-forge-docker](https://github.com/catspeed-cc/sd-webui-forge-docker) or [sd-webui-reforge-docker](https://github.com/catspeed-cc/sd-webui-reforge-docker) repository

It is now in your PATH / .bashrc

- to update `cd /path/to/where/you/put/rh-menu && git pull origin/master`.
- to use `cd path/to/where/your/sd-forge-or-sd-reforge-docker-installation` and `rh-menu` from inside any subdirectory of the installation

Appears to work more properly - I'm welcome. Your welcome.

no other help

~ mooleshacat

P.S. This small dev release helper menu helped me find a few bugs in the menu's command execution for my dockerized projects. \
P.P.S. The fixes will be in the v1.1.3 compatibility version I am working on to make both dockerized projects compatible.

EOF
