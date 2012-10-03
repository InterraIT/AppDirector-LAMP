#!/bin/bash

# FUNTION TO CHECK ERROR
function check_error()
{
   if [ ! "$?" = "0" ]; then
      error_exit "$1";
   fi
}

# FUNCTION TO DISPLAY ERROR AND EXIT
function error_exit()
{
   echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
   exit 1
}

# CONFIGURATION OF LAMP -- START
phpmyadmin_conf=
if [ -f /etc/redhat-release ] ; then
	# CONFIGURE APACHE TO LISTEN ON PARTICULAR PORT
	sed -ie "s/^Listen .*/Listen $http_port\nListen $http_proxy_port/g" /etc/httpd/conf/httpd.conf
	# CONFIGURE MYSQL TO HANDLE BIG PACKETS
	sed -ie "s/\[mysqld\]/\[mysqld\]\n\max_allowed_packet=1024M/g" /etc/my.cnf
	# CONFIGURE MYSQL TO LISTEN ON PARTICULAR PORT
	sed -ie "s/\[mysqld\]/\[mysqld\]\n\port=$db_port/g" /etc/my.cnf
	# CONFIGURE MYSQL TO LISTEN ON PARTICULAR IP
	sed -i 's/bind-address.*/bind-address            = $bind_ip/' /etc/my.cnf
	phpmyadmin_conf="/etc/httpd/conf.d/phpmyadmin.conf"
elif [ -f /etc/debian_version ] ; then
	# CONFIGURE APACHE TO LISTEN ON PARTICULAR PORT
	sed -ie "s/^NameVirtualHost .*/NameVirtualHost \*\:$http_port/g" /etc/apache2/ports.conf 
	sed -ie "s/Listen .*/Listen $http_port/g" /etc/apache2/ports.conf
	sed -ie "s/^Listen .*/Listen $bind_ip\:$http_port\nListen $bind_ip\:$http_proxy_port/g" /etc/apache2/ports.conf
	sed -ie "s/\<VirtualHost .*/VirtualHost \*\:$http_port\>/g" /etc/apache2/sites-enabled/000-default
	sed -ie "s/\<VirtualHost .*/VirtualHost \*\:$http_port\>/g" /etc/apache2/sites-available/default-ssl
	# CONFIGURE MYSQL TO HANDLE BIG PACKETS
	sed -ie "s/\[mysqld\]/\[mysqld\]\n\max_allowed_packet=1024M/g" /etc/mysql/my.cnf
	# CONFIGURE MYSQL TO LISTEN ON PARTICULAR PORT
	sed -ie "s/port.*/port            = $db_port/g" /etc/mysql/my.cnf
	# CONFIGURE MYSQL TO LISTEN ON PARTICULAR IP
	sed -i 's/bind-address.*/bind-address            = $bind_ip/' /etc/mysql/my.cnf
	phpmyadmin_conf="/etc/apache2/conf.d/phpmyadmin.conf"
elif [ -f /etc/SuSE-release ] ; then
	echo "Welcome to openSUSE 11.0. Apache2 works" > /srv/www/htdocs/index.html
	# CONFIGURE APACHE TO LISTEN ON PARTICULAR PORT
	sed -ie "s/^Listen .*/Listen $http_port\nListen $http_proxy_port/g" /etc/apache2/listen.conf
	# CONFIGURE MYSQL TO LISTEN ON PARTICULAR PORT
	sed -ie "s/port.*/port            = $db_port/g" /etc/my.cnf
	# CONFIGURE MYSQL TO HANDLE BIG PACKETS
	sed -ie "s/max_allowed_packet.*/max_allowed_packet = 1024M/g" /etc/my.cnf
	phpmyadmin_conf="/etc/apache2/conf.d/phpmyadmin.conf"
fi

# ASSIGN A PASSWORD FOR MYSQL ADMIN ROOT USER
$mysql_service &
sleep 60
mysqladmin -u $db_root_username password $db_root_password
check_error "ERROR:CANNOT ASSIGN NEW PASSWORD TO MYSQL DATABASE"
# CONFIGURE PHP 
sed -i 's/.*upload_max_filesize.*/upload_max_filesize = 50M/g' $php_ini_file
sed -i 's/.*memory_limit.*/memory_limit = 128M/g' $php_ini_file
sed -i 's/.*max_execution_time.*/max_execution_time = 120/g' $php_ini_file
sed -i 's/.*post_max_size.*/post_max_size = 50M/g' $php_ini_file

# CONFIGURE PHPMYADMIN
cp $document_root/phpmyadmin/config.sample.inc.php $document_root/phpmyadmin/config.inc.php
check_error "ERROR WHILE COPYING PHP CONFIGURATION FILE"
sed -i "s|.*blowfish_secret.*|\$cfg['blowfish_secret'] = 'a8b7c6def231';|" $document_root/phpmyadmin/config.inc.php
sed -ie "s/\$cfg\['Servers'\]\[\$i\]\['host'\].*/$& \n\$cfg\['Servers'\]\[\$i\]\['port'\] = '$db_port';/g" $document_root/phpmyadmin/config.inc.php
echo "Alias /phpMyAdmin /usr/share/phpmyadmin" >> $phpmyadmin_conf

echo "<?php phpinfo(); ?>" > $document_root/phpinfo.php
# CONFIGURATION OF LAMP -- DONE