# releasehelper-menu
custom release helper script for sd-webui-forge-docker and sd-webui-reforge-docker (will only work with these without modifications)

- run `git clone https://github.com/catspeed-cc/releasehelper-menu.git /path/to/where/you/want/rh-menu`
- run `echo "export PATH=${PATH}:/path/to/where/you/put/rh-menu" | tee -a ~/.bashrc`
- run `./rh-menu` from inide sd-webui-forge-docker or sd-webui-reforge-docker repository

It is now in your PATH / .bashrc

- to update `cd /path/to/where/you/put/rh-menu && git pull origin/master`.
- to use `cd path/to/where/your/sd-forge-or-sd-reforge-docker-installation` and `rh-menu` from inside any subdirectory of the installation

no other help

~ mooleshacat

EOF
