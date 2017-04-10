#!/usr/bin/env bash
# Copyright (c) 2017 Levi Sabah <0xl3vi@gmail.com>
# (https://git.io/hostsctl/)
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

. /etc/hostsctl.conf

# by https://github.com/mathiasbynens/dotfiles
if tput setaf 1 &> /dev/null; then
    tput sgr0; # reset colors
    bold=$(tput bold);
    reset=$(tput sgr0);
    # Solarized colors, taken from http://git.io/solarized-colors.
    black=$(tput setaf 0);
    blue=$(tput setaf 33);
    cyan=$(tput setaf 37);
    green=$(tput setaf 64);
    orange=$(tput setaf 166);
    purple=$(tput setaf 125);
    red=$(tput setaf 124);
    violet=$(tput setaf 61);
    white=$(tput setaf 15);
    yellow=$(tput setaf 136);
else
  bold='';
  reset="\e[0m";
  black="\e[1;30m";
  blue="\e[1;34m";
  cyan="\e[1;36m";
  green="\e[1;32m";
  orange="\e[1;33m";
  purple="\e[1;35m";
  red="\e[1;31m";
  violet="\e[1;35m";
  white="\e[1;37m";
  yellow="\e[1;33m";
fi;

PREFIX="/etc"
HOSTS="${PREFIX}/hosts"
REMOTE_HOSTS="${PREFIX}/hostsctl.d/30-remote"
ENABLED_DISABLED_HOSTS="${PREFIX}/hostsctl.d/20-enabled-disabled"
USER_HOSTS="${PREFIX}/hostsctl.d/10-hosts"

hosts_usage() {
cat << END
Usage $0 [option] [host] ...

Hostsctl.sh allows you to block ads, social networks, porn, etc,
by manipulating the /etc/hosts file.

Arguments:
  enable [host]    enable specified host
  disable [host]   disable specified host.
  export           export hosts
  merge            merge hosts to ${PREFIX}/hosts
  list-enabled     list enabled hosts
  list-disabled    list disabled hosts
  update-remote    update remote hosts.

Full documentation at: <http://git.io/hostsctl>
END
}

# msg_check: show message when successfully done
# @param $@: text
msg_check() {
  printf "${green}\u2713${reset} $1\n"
}

# msg_error: show error message
# @param $@: text
msg_error() {
  printf "${red}# error:${reset} $@\n"
}

root_check() {
  if [ $UID -ne 0 ];then
    msg_error "please run as root."
    exit
  fi
}

# mktemp: create a temporary file or directory
mktemp() {
  local filename="/tmp/hostsctl-${RANDOM}"
  touch "$filename"
  echo "${filename}"
}

hosts_export() {
  cat ${PREFIX}/hostsctl.d/*
}

# hosts_merge: this will merge /etc/hostsctl.d/ to /etc/hosts
hosts_merge() {
  root_check

  hosts_export > ${HOSTS}
}

hosts_enable() {
  root_check

  local filename
  local tmpfile=$(mktemp);

  if grep -qw "$1" "${REMOTE_HOSTS}";then
    filename="${REMOTE_HOSTS}"
  elif grep -qw "$1" "${USER_HOSTS}";then
    filename=${USER_HOSTS}
  elif grep -qw "$1" "${ENABLED_DISABLED_HOSTS}";then
    filename=${ENABLED_DISABLED_HOSTS}
  fi

  if [ -z ${filename} ];then
    cp ${ENABLED_DISABLED_HOSTS} ${tmpfile} # Copy current version
    echo "#${ip} $1" >> ${tmpfile}
    mv "${tmpfile}" "${ENABLED_DISABLED_HOSTS}" # Update
  else
    awk -vhost=$1 \
    '{ if ( $0 ~ host && substr($0, 1, 1) != "#" ) printf("#%s\n", $0); else print $0 }' ${filename} \
    > "${tmpfile}"
    mv ${tmpfile} ${filename}
  fi

  hosts_merge
  msg_check "$1: ${green}enabled${reset}"
}

hosts_disable() {
  root_check

  local filename
  local tmpfile=$(mktemp);

  if grep -qw "$1" "${REMOTE_HOSTS}";then
    filename="${REMOTE_HOSTS}"
  elif grep -qw "$1" "${USER_HOSTS}";then
    filename=${USER_HOSTS}
  elif grep -qw "$1" "${ENABLED_DISABLED_HOSTS}";then
    filename=${ENABLED_DISABLED_HOSTS}
  fi

  if [ -z ${filename} ];then
    cp ${ENABLED_DISABLED_HOSTS} ${tmpfile} # Copy current version
    echo "${ip} $1" >> ${tmpfile}
    mv "${tmpfile}" "${ENABLED_DISABLED_HOSTS}" # Update
  else
    awk -vhost=$1 \
    '{ if ( $0 ~ host && substr($0, 1, 1) == "#" ) print substr($0, 2); else print $0 }' ${filename} \
    > "${tmpfile}"
    mv ${tmpfile} ${filename}
  fi

  hosts_merge
  msg_check "$1: ${yellow}disabled${reset}"
}

# hosts_list_enabled: list enabled hosts
hosts_list_enabled() {
  hosts=$(awk '{ if ( substr($0, 1, 3) == "#0." ) printf("%s\n", $2) }' ${HOSTS})
  total=0

  for host in $hosts;do
    printf "${green}\u25CF${reset} ${white}${host}${reset}\n"
    total=$[$total+1]
  done
  msg_check "${white}total: ${yellow}${total}"
}

# hosts_list_disabled: list disabled hosts
hosts_list_disabled() {
  hosts=$(awk '{ if ( substr($0, 1, 3) == "0.0" ) printf("%s\n", $2) }' ${HOSTS})
  total=0;

  for host in $hosts;do
    printf "${red}\u25CF${reset} ${white}${host}${reset}\n"
    total=$[$total+1]
  done
  msg_check "${white}total: ${yellow}${total}"
}

# hosts_update_remote: update the remote hosts
hosts_update_remote() {
  root_check
  local tmpfile=$(mktemp);

  curl -o "${tmpfile}" -L "${remote_hosts}" -s
  msg_check "update: ${purple}$(wc -l ${tmpfile} | cut -d' ' -f1)${reset} entries, ${yellow}$(diff -B ${tmp} ${REMOTE_HOSTS} | wc -l)${reset} new"
  mv ${tmpfile} ${REMOTE_HOSTS}
}

case $1 in
  disable)
    hosts_disable "$2";;
  enable)
    hosts_enable  "$2";;
  merge)
    hosts_merge;;
  export)
    hosts_export;;
  update-remote)
    hosts_update_remote;;
  list-enabled)
    hosts_list_enabled;;
  list-disabled)
    hosts_list_disabled;;
  --help)
    hosts_usage;;
  *)
    hosts_usage;;
esac
