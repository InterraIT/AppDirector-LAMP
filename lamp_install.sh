#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# INSTALLATION OF LAMP -- START
if [ -f /etc/redhat-release ] ; then
	REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	DIST=`cat /etc/redhat-release |sed s/\ release.*//`
	ARCH=`uname -p`
      	if [ $ARCH == "i686" ] ; then
		echo "$DIST 32 BIT MACHINE - v$REV"
		basearch=i386
	else
		echo "$DIST 64 BIT MACHINE - v$REV"
		basearch=x86_64
		yum --nogpgcheck --noplugins -y clean all
	fi
	# INSTALLATION OF REMI REPOSITORY -- START
	rpm -Uvh http://dl.fedoraproject.org/pub/epel/$release/$basearch/epel-release-$release-$subrelease.noarch.rpm
	check_error "ERROR WHILE DOWNLOADING AND INSTALLING epel REPOSITORY"
	rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-$release.rpm
	check_error "ERROR WHILE DOWNLOADING AND INSTALLING remi REPOSITORY"
	if [ "$DIST" = "Red Hat Enterprise Linux Server" ] ; then
		sed -i "s|\$releasever|6|g" /etc/yum.repos.d/remi.repo
	fi
	# INSTALLATION OF REMI REPOSITORY -- END
	yum --enablerepo=remi install -y httpd mysql-server php php-common php-mysql php-pear php-xsl php-gd php-mbstring php-mcrypt 
	check_error "ERROR WHILE INSTALLING LAMP"
	document_root="/var/www/html"
	php_ini_file="/etc/php.ini"
	mysql_service="/etc/init.d/mysqld start"
fi
# INSTALLING PHPMYADMIN 
cd $document_root
wget http://citylan.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.5.2/phpMyAdmin-3.5.2-all-languages.tar.gz
tar xvfz phpMyAdmin-3.5.2-all-languages.tar.gz
rm -rf phpMyAdmin-2.11.11.3-english.tar.gz
mv phpMyAdmin-3.5.2-all-languages phpmyadmin
# INSTALLATION OF LAMP -- DONE