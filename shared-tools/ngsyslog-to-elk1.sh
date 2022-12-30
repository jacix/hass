#!/usr/local/bin/bash
# enable remote syslog to elk1 via syslog-ng

# stop and disable syslog
service syslogd status && service syslogd stop
grep -q 'syslogd_enable="NO"' /etc/rc.conf || echo 'syslogd_enable="NO"' >> /etc/rc.conf

# if syslog-ng isn't running, install it
if service syslog-ng onestatus; then
	echo "syslog-ng is already running. byeee"
	exit
else
	ASSUME_ALWAYS_YES=yes pkg install syslog-ng && echo 'syslog_ng_enable="YES"' >> /etc/rc.conf
fi

# If there's no file, copy the sample as a starter
if ! test -f /usr/local/etc/syslog-ng.conf; then
	cp -rp /usr/local/etc/syslog-ng.conf.sample /usr/local/etc/syslog-ng.conf
	# I would start syslog-ng here, but it won't have the elk1 config, so the next block will get it
else
	echo "/usr/local/etc/syslog-ng.conf is already present"
fi

# fix /etc/hosts so that "logsource" reports the short name, not "localhost"
if ! grep -q "127.0.0.1.*$(uname -n).*localhost" /etc/hosts; then
	sed -i.$(date +%Y%m%d.%H%M) "s/^127.0.0.1.*localhost.*$/127.0.0.1\t\t$(uname -n) $(uname -n).pa.jacix.net localhost/" /etc/hosts
else
	echo "Looks like /etc/hosts is fine:"
	grep $(uname -n) /etc/hosts
fi

# if syslog-ng isn't configured properly, configure and restart it
if ! grep -q "port(5045)" /usr/local/etc/syslog-ng.conf; then

cat << EOB >> /usr/local/etc/syslog-ng.conf
# 2021-10-27
destination p_logstashhost { tcp("elk1.pa.jacix.net" port(5045) localport(514)); };
log { source(src); filter(f_info);destination(p_logstashhost); };
EOB

else
	echo "elk1 is already in /usr/local/etc/syslog-ng.conf"
fi

service syslog-ng restart
