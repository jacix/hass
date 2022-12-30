#!/bin/sh

du -sh /var/spool/clientmqueue /var/db/freebsd-update
pkg clean

if test "$1" -a "$1" == "go"; then
	rm /var/db/freebsd-update/files/*
	du -sh /var/db/freebsd-update
fi


