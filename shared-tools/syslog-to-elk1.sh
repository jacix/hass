#!/usr/local/bin/bash
# enable remote syslog to elk1
echo "Nope - you want syslog=ng: $(dirname $0)/ngsyslog-to-elk1.sh"
exit 1

if service syslogd status && ! test -f /etc/syslog.d/99-remote.conf; then
	echo "*.*		@elk1.pa.jacix.net:5045" > /etc/syslog.d/99-remote.conf
	sed -i.$(date +%Y%d%m.%H%M) 's/syslogd_flags="-c -ss"/syslogd_flags="-c -s"/' /etc/rc.conf
	service syslogd restart
else
	echo "Either syslog isn't running or 99-remote.conf is already here. Let's see which:"
	ls -l /etc/syslog.d/99-remote.conf
	service syslogd status
fi
