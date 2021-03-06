#!/bin/bash

###############################################################################
# Copyright (C) 2012-2018 Phillip Smith
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

### tests the number of rules in iptables to ensure
### there (appears) to be a valid ruleset loaded

# defaults here
MIN_RULES=1
IPVER=4

function usage {
	cat <<_HELP_
Usage: $0 [options]
Options:
	-n X	Expect number X minimum rule count
	-4		Check iptables (IPv4)
	-6		Check ip6tables (IPv6)
_HELP_
}

# make our path sane
PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

# constants for exit status
E_OK=0
E_WARNING=1
E_CRITICAL=2
E_UNKNOWN=3

# are we root?
[[ $EUID -ne 0 ]] && { echo "Got root?"; exit $E_UNKNOWN; }

while getopts "46n:" opt; do
  case $opt in
  n)
	MIN_RULES=$OPTARG
	;;
  4)
	IPVER=4
	;;
  6)
	IPVER=6
	;;
  *)
	usage
	exit $E_UNKNOWN
	;;
  esac
done

# first check if firewalld is running; if so, we'll return OK
if command -v firewall-cmd >/dev/null ; then
  firewalld_state="$(firewall-cmd --state)"
  if [[ "$firewalld_state" == 'running' ]] ; then
    emsg="OK; firewalld is running"
    estat=$E_OK
  else
    emsg="WARNING; firewalld state is '$firewalld_state'"
    estat=$E_WARNING
  fi
  echo $emsg
  exit $estat
fi

# check our rule count
if [[ $IPVER -eq 4 ]] ; then
	# Test iptables v4
	RULES_CNT=$(iptables-save | grep -c -- -A)
	POLICY_ERRS=$(iptables -S | grep -E -- '-P (INPUT|FORWARD) ACCEPT')
else
	# Test iptables v6
	RULES_CNT=$(ip6tables-save | grep -c -- -A)
	POLICY_ERRS=$(ip6tables -S | grep -E -- '-P (INPUT|FORWARD) ACCEPT')
fi

# check our rule count
if [[ $RULES_CNT -lt $MIN_RULES ]] ; then
	emsg="CRITICAL; $RULES_CNT IPv$IPVER rules! (Expected > $MIN_RULES)"
	estat=$E_CRITICAL
elif [[ -n "$POLICY_ERRS" ]] ; then
	emsg="WARNING; INPUT and/or FORWARD policy is ACCEPT"
	estat=$E_WARNING
else
	emsg="OK; $RULES_CNT IPv$IPVER rules. (Expected > $MIN_RULES)"
	estat=$E_OK
fi

echo $emsg
exit $estat
