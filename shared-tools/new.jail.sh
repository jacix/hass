#!/bin/sh
# Install required packages
# change log:
# 2021-10-14 - no need for binutils or wget
# 2025-02-04 - if rc.firewall isn't already updated, print right ports for this jail. to-do: update rc.firewall automatically; 
#            - update .cshrc only if it doesn't start bash already
#            - install only missing packages 
#            - enable firewall in /etc/rc.conf if it's not already done
##########################################################################
pkg update
#ASSUME_ALWAYS_YES=yes; pkg install bash vim binutils wget openssh-portable sudo
#ASSUME_ALWAYS_YES=yes pkg install bash vim openssh-portable sudo
# install desired packages only if they're missing
for desired_pkg in bash vim openssh-portable sudo; do
	if pkg info ${desired_pkg} > /dev/null; then
		echo "### ${desired_pkg} already installed"
	else
		ASSUME_ALWAYS_YES=yes pkg install ${desired_pkg}
	fi
done
# enable ssh on boot and start it
grep -q 'openssh_enable="YES"' /etc/rc.conf || echo 'openssh_enable="YES"' >> /etc/rc.conf
service openssh start

# create jason user and populate ~jason
if ! grep -q jason /etc/passwd; then
	pw group add jason -g 666
	echo "jason:666:666::::jason::bash:" | adduser -f - -g wheel -w random
	cd /home/jason && tar xvf /shared/tools/bashenv-for-jails.current.tar && chown -R jason:jason /home/jason
fi
# populate ~root
if ! grep -q jason /root/.bashrc; then 
	cd /root && tar xvf /shared/tools/bashenv-for-jails.current.tar
fi

if grep -q "firewall_enable" /etc/rc.conf; then
	echo "### firewall already enabled in /etc/rc.conf"
else
	echo "### updating /etc/rc.rc.conf"
cat <<EOB >> /etc/rc.conf

# $(date +%Y-%m-%d) - jason
firewall_enable="YES"
firewall_type="open"
EOB
fi

if grep -q jason /etc/rc.firewall; then
	echo "### /etc/rc.firewall already has your ports"
else
cat <<EOB
ports:
* flaresolverr: 8191 -> 80
* hass: 8123 -> 443
* plex: 32400 -> 80
* prowlarr: 9696 -> 80 ; 6969 -> 443
* radarr: 7878 -> 80 ; 9898 -> 443
* sonarr: 8989 -> 80
* transmission: 9091 -> 80
* unifi: 8443 -> 443
* zwavejs2mqtt: 8091 -> 80

Your application is listening on one of these:
$(netstat -an | grep LISTEN | egrep -v '.22')

Add to /etc/rc.firewalls around line 198 and customize with the port above
# 2021-09-15 port forwarding
$(case $(uname -n) in 
flaresolverr)
echo "        \${fwcmd} add fwd 127.0.0.1,9181 tcp from any to any 80 in # $(uname -n)";;
hass)
echo "        \${fwcmd} add fwd 127.0.0.1,8123 tcp from any to any 443 in # $(uname -n)";;
plex)
echo "        \${fwcmd} add fwd 127.0.0.1,32400 tcp from any to any 80 in # $(uname -n)";;
pprowlarr) 
echo "        \${fwcmd} add fwd 127.0.0.1,9696 tcp from any to any 80 in # $(uname -n)";
echo "        \${fwcmd} add fwd 127.0.0.1,6969 tcp from any to any 443 in # $(uname -n)";;
radarr) 
echo "        \${fwcmd} add fwd 127.0.0.1,7878 tcp from any to any 80 in # $(uname -n)";
echo "        \${fwcmd} add fwd 127.0.0.1,9898 tcp from any to any 443 in # $(uname -n)";;
sonarr) 
echo "        \${fwcmd} add fwd 127.0.0.1,8989 tcp from any to any 80 in # $(uname -n)";;
transmission) 
echo "        \${fwcmd} add fwd 127.0.0.1,9091 tcp from any to any 80 in # $(uname -n)";;
unifi) 
echo "        \${fwcmd} add fwd 127.0.0.1,8443 tcp from any to any 443 in # $(uname -n)";;
zwavejs2mqtt)
echo "        \${fwcmd} add fwd 127.0.0.1,8091 tcp from any to any 80 in # $(uname -n)";;
*)
echo "### unknown host $(uname -n); update this script with something like:";
echo "        \${fwcmd} add fwd 127.0.0.1,8091 tcp from any to any 80 in # $(uname -n)";;
esac)
echo "I just ran jason's rules"
EOB
fi

#echo -e "echo 'trying to start bash with 1 sec delay'\ntest -x /usr/local/bin/bash && ( sleep 1; /usr/local/bin/bash; )" >> /root/.cshrc
#sh -c "echo -e 'echo trying to start bash with 1 sec delay\ntest -x /usr/local/bin/bash && (sleep 1; /usr/local/bin/bash)' "  >> /root/.cshrc
if ! $(grep -q "trying to" ${HOME}/.cshrc); then
	echo "### Updating .cshrc to start bash"
	sed -i.$(date +%Y%m%d.%H%M) 's:^endif:\techo "trying to start bash after 1 sec delay"\n\ttest -x /usr/local/bin/bash \&\& \(sleep 1; /usr/local/bin/bash\)\nendif:' ${HOME}/.cshrc
else
	echo "### .cshrc already starts bash"
fi
# enable remote syslog to elk1
#DATESTAMP=$(date +%Y%m%d.%H%M)
#if service syslogd status && ! test -f /etc/syslog.d/99-remote.conf; then
#	echo "*.*		@elk1.pa.jacix.net:5045" > /etc/syslog.d/99-remote.conf
#	sed -i.${DATESTAMP} 's/syslogd_flags="-c -ss"/syslogd_flags="-c -s"/' /etc/rc.conf
#	service syslogd restart
#else
#	echo "Either syslog isn't running or 99-remote.conf is already here. Let's see which:"
#	ls -l /etc/syslog.d/99-remote.conf
#	service syslogd status
#fi
