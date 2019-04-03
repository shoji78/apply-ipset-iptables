#!/bin/bash -eu

setup_ipset_persistent() {
  cat << EOT > /usr/share/netfilter-persistent/plugins.d/10-ipset
#!/bin/sh

# This file is part of netfilter-persistent
# (was iptables-persistent)
# Copyright (C) 2009, Simon Richter <sjr@debian.org>
# Copyright (C) 2010, 2014 Jonathan Wiltshire <jmw@debian.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3
# of the License, or (at your option) any later version.

set -e

rc=0

load_rules()
{
        #load IPSet rules
        if [ ! -f /etc/iptables/rules.ipset ]; then
                echo "Warning: skipping IPSet (no rules to load)"
        else
                ipset restore -! < /etc/iptables/rules.ipset 2> /dev/null
                if [ \$? -ne 0 ]; then
                        rc=1
                fi
        fi
}

save_rules()
{
        #save IPSet rules
        #need at least ip_set loaded:
        /sbin/modprobe -q ip_set
        if [ -x /sbin/ipset ]; then
                touch /etc/iptables/rules.ipset
                chmod 0640 /etc/iptables/rules.ipset
                ipset save | grep -iv "f2b" > /etc/iptables/rules.ipset
                if [ \$? -ne 0 ]; then
                        rc=1
                fi
        fi
}

flush_rules()
{
        if [ -x /sbin/ipset ]; then
                ipset flush
        fi
}

case "\$1" in
start|restart|reload|force-reload)
        load_rules
        ;;
save)
        save_rules
        ;;
stop)
        # Why? because if stop is used, the firewall gets flushed for a variable
        # amount of time during package upgrades, leaving the machine vulnerable
        # It's also not always desirable to flush during purge
        echo "Automatic flushing disabled, use \\"flush\\" instead of \\"stop\\""
        ;;
flush)
        flush_rules
        ;;
*)
    echo "Usage: \$0 {start|restart|reload|force-reload|save|flush}" >&2
    exit 1
    ;;
esac

exit \$rc
EOT
  chmod 755 /usr/share/netfilter-persistent/plugins.d/10-ipset
  touch /etc/iptables/rules.ipset
}


setup_main_script() {
  local INSTALLER_DIR=$(cd $(dirname $0); pwd)
  local SCRIPT_NAME="apply-ipset-iptables.py"
  local DIR="/opt/apply-ipset-iptables"

  pip3 install python-iptables

  mkdir -p $DIR
  if [[ -e "$INSTALLER_DIR/$SCRIPT_NAME" ]]; then
    cp "$INSTALLER_DIR/$SCRIPT_NAME" "$DIR/$SCRIPT_NAME"
  else
    curl -o $DIR/$SCRIPT_NAME https://github.com/shoji78/apply-ipset-iptables/raw/master/apply-ipset-iptables.py
  fi
  chmod 755 $DIR/$SCRIPT_NAME
}


export DEBIAN_FRONTEND=noninteractive
apt install -y \
  iptables-persistent \
  ipset \
  python3-pip

setup_ipset_persistent

setup_main_script

