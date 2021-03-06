#!/usr/bin/env bash
# Copyright (c) 2017 hostsctl.sh authors and contributors
# (https://git.io/hostsctl)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#

PREFIX="/usr/local/bin"

root_check() {
  if [ $UID -ne 0 ];then
    echo "error: please run as root."
    exit
  fi
}

msg_info() {
  printf "<i> $1\n"
}

hostsctl_install() {
  local prefix="$1"

  printf "* Installing hostsctl ...\n"

  printf "* " && cp -v bin/hostsctl.sh "${prefix}/hostsctl"
  chmod +x "${prefix}/hostsctl"

  # Install bash-completions
  # TODO: zsh-completions
  # ARCHLINUX
  if [ -f "/etc/arch-release" ];then
    printf "* " && cp -v hostsctl.bash-completion "/usr/share/bash-completion/completions/hostsctl"
  # UBUNTU - definitely a tidier way of doing this, but such things are a little above me
  else [ -f "/etc/os-release" ]
    if grep -q 'ID="Ubuntu"' /etc/os-release;then
        printf "* " && cp -v hostsctl.bash-completion "/usr/share/bash-completion/completions/hostsctl"
    fi
  fi

  printf "\n* congrats! hostsctl.sh installed on your system.\n"
  echo "* to get started, run hostsctl upgrade"
}

hosts_config() {
    # Add default config file
    cp -v etc/hostsctl.conf "/etc/hostsctl"
}

hosts_uninstall() {
  local prefix="$1"

  printf "* Restoring old /etc/hosts file ...\n"
  "${prefix}"/bin/hostsctl restore
  printf "* Uninstalling hostsctl ...\n"
  rm "${prefix}/bin/hostsctl"
  rm -r /etc/hostsctl*

  if [ -f "/etc/arch-release" ];then
    rm "/usr/share/bash-completion/completions/hostsctl.bash-completion"
    else [ -f "/etc/os-release"]
      if grep -q 'NAME="Ubuntu"' os-release;then
          rm "/usr/share/bash-completion/completions/hostsctl.bash-completion"
      fi
  fi
  printf "* hostsctl is no longer installed on your system.\n"
}

usage() {
cat << EOF
Usage: $0 [--prefix] ...

Install.sh will install hostsctl on your system.

Arguments:
  --prefix   set installation prefix (default: ${PREFIX})
  uninstall  uninstall hostsctl.
  init-config installs default config file in /etc/hostsctl
EOF
}

root_check

case $1 in
  --prefix)
    PREFIX="$2";;
  uninstall)
    hosts_uninstall "${PREFIX}";;
  init-config)
    hosts_config;;
  *)
    hostsctl_install "${PREFIX}"
esac
