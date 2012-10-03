#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
set -e
if [ -f /etc/redhat-release ] ; then
	/sbin/chkconfig --levels 235 httpd on
	chkconfig mysqld on
	/etc/init.d/httpd start & sleep 20
	/etc/init.d/httpd reload
	/etc/init.d/mysqld restart
	
else
	if [ -f /etc/SuSE-release ] ; then
		chkconfig --add apache2
		/etc/init.d/mysql restart
	fi
	/etc/init.d/apache2 restart
fi