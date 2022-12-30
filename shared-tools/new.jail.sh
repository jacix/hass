#!/bin/sh
# Install required packages
# 2021-10-14 - no need for binutils or wget
#ASSUME_ALWAYS_YES=yes; pkg install bash vim binutils wget openssh-portable sudo
ASSUME_ALWAYS_YES=yes pkg install bash vim openssh-portable sudo
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
cat <<EOB
Add to /etc/rc.conf:
# 2021-09-15 - jason
firewall_enable="YES"
firewall_type="open"

Your application is listening on one of these:
$(netstat -an | grep LISTEN | egrep -v '.22')

Add to /etc/rc.firewalls around line 198 and customize with the port above
# 2021-09-15 port forwarding
${fwcmd} add fwd 127.0.0.1,8091 tcp from any to any 80 in # zwavejas2mqtt
echo "I just ran jason's rules"

EOB

# enable ssh on boot and start it
#echo -e "echo 'trying to start bash with 1 sec delay'\ntest -x /usr/local/bin/bash && ( sleep 1; /usr/local/bin/bash; )" >> /root/.cshrc
#sh -c "echo -e 'echo trying to start bash with 1 sec delay\ntest -x /usr/local/bin/bash && (sleep 1; /usr/local/bin/bash)' "  >> /root/.cshrc
sed -i.$(date +%Y%m%d.%H%M) 's:^endif:\techo "trying to start bash after 1 sec delay"\n\ttest -x /usr/local/bin/bash \&\& \(sleep 1; /usr/local/bin/bash\)\nendif:' .cshrc
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
