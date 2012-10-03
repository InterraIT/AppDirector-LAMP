#!/bin/bash

export PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export http_proxy=http://proxy.vmware.com:3128

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

# FUNCTION TO VALIDATE IP ADDRESS
function valid_ip()
{
    local  ip=$1
    local  stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# FUNCTION TO VALIDATE THE INTEGER
function valid_int()
{
   local  data=$1
   if [[ $data =~ ^[0-9]{1,9}$ ]]; then
      return 0;
   else
      return 1
   fi
}

# FUNCTION TO VALIDATE NAME STRING
function valid_string()
{
    local  data=$1
    if [[ $data =~ ^[A-Za-z]{1,}[A-Za-z0-9_-]{1,}$ ]]; then
       return 0;
    else
       return 1;
    fi
}

# FUNCTION TO VALIDATE PASSWORD
function valid_password()
{
    local  data=$1
    length=${#data}
    if [ $length -le 5 ]; then
        check_error "PASSWORD MUST BE OF AT LEAST 5 CHARACTERS"
    else
        if [[ $data =~ ^[A-Za-z]{1,}[0-9_@$%^+=]{0,}[A-Za-z0-9]{0,}$ ]]; then
           return 0;
        else
           return 1;
        fi
    fi
}

# PARAMETER VALIDATION
echo "VALIDATING PARAMETERS..."
if [ "x${bind_ip}" = "x" ]; then
	error_exit "LAPM BIND IP NOT SET."
else
   if ! valid_ip ${bind_ip}; then
      error_exit "INVALID PARAMETER BIND IP."
   fi
fi
if [ "x${http_port}" = "x" ]; then
    error_exit "HTTP PORT NOT SET."
else
   if ! valid_int ${http_port}; then
      error_exit "INVALID PARAMETER HTTP_PORT.MUST BE AN INTEGER"
   fi
fi
if [ "x${http_proxy_port}" = "x" ]; then
    error_exit "HTTP_PROXY_PORT NOT SET."
else
   if ! valid_int ${http_proxy_port}; then
      error_exit "INVALID PARAMETER HTTP_PROXY_PORT.MUST BE AN INTEGER"
   fi
fi
if [ "x${db_port}" = "x" ]; then
    error_exit "db_port NOT SET."
else
   if ! valid_int ${db_port}; then
      error_exit "INVALID PARAMETER DB_PORT.MUST BE AN INTEGER"
   fi
fi
if [ "x${db_root_username}" = "x" ]; then
    error_exit "DB_ROOT_USERNAME NOT SET."
else
   if ! valid_string ${db_root_username}; then
      error_exit "INVALID PARAMETER DB_ROOT_USERNAME"
   fi
fi
if [ "x${db_root_password}" = "x" ]; then
    error_exit "DB_ROOT_PASSWORD NOT SET."
else
   if ! valid_string ${db_root_password}; then
      error_exit "INVALID PARAMETER DB_ROOT_PASSWORD"
   fi
fi
echo "PARAMTER VALIDATION -- DONE"

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
	echo $REV | grep -q '6.'
	if [ $? -eq 0 ] ; then
		release=6
		subrelease=7
	else
		release=5
		subrelease=4
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

elif [ -f /etc/SuSE-release ] ; then
	zypper ar -f http://download.opensuse.org/distribution/11.2/repo/oss/ repo-oss
	zypper --non-interactive --no-gpg-checks ref    
	zypper --non-interactive --no-gpg-checks install apache2 mysql mysql-tools php5 php5-mysql php-pear php5-xsl php5-gd php5-mcrypt php5-mbstring apache2-mod_php5
	check_error "ERROR WHILE INSTALLING LAMP"
	document_root="/srv/www/htdocs"
	php_ini_file="/etc/php5/cli/php.ini"
	mysql_service="/etc/init.d/mysql start"
	mkdir -p $document_root
	
elif [ -f /etc/debian_version ] ; then
	apt-get -fy update 
	apt-get -fy install
	apt-get -fy install linux-firmware
	apt-get --fix-missing -fy install apache2 mysql-client mysql-server php5 php5-cli php5-mysql php5-xsl php5-gd php5-mcrypt libapache2-mod-php5 libapache2-mod-auth-mysql php-pear
	check_error "ERROR WHILE INSTALLING LAMP"
	document_root="/var/www"
	php_ini_file="/etc/php5/cli/php.ini"
	mysql_service=""
fi
# INSTALLING PHPMYADMIN 
cd $document_root
wget http://citylan.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.5.2/phpMyAdmin-3.5.2-all-languages.tar.gz
check_error "ERROR WHILE DOWNLOADING PHPMYADMIN INSTALLER"
tar xvfz phpMyAdmin-3.5.2-all-languages.tar.gz
check_error "ERROR WHILE EXTRACTING THE PHPMYADMIN INSTALLER"
rm -rf phpMyAdmin-2.11.11.3-english.tar.gz
mv phpMyAdmin-3.5.2-all-languages phpmyadmin
# INSTALLATION OF LAMP -- DONE