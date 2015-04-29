#!/bin/bash

# Import config file
. /vagrant/setup/config

# Don't ask for anything
export DEBIAN_FRONTEND=noninteractive

# Set MySQL root password
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password password'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password password'


# Install packages
apt-get update

apt-get install -q -f -y --force-yes -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' mysql-server-5.5 php5-mysql libsqlite3-dev apache2 php5 libapache2-mod-php5 php5-dev build-essential php-pear ruby1.9.1-dev php5-mcrypt php5-curl git php5-gd imagemagick unzip php5-xdebug postfix

apt-get -y remove puppet chef chef-zero puppet-common

# Set timezone
echo "Australia/Melbourne" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata


# Setup database
if [ ! -f /var/log/databasesetup ]; then
	echo "DROP DATABASE IF EXISTS test" | mysql -uroot -ppassword
	echo "CREATE USER 'devdb'@'localhost' IDENTIFIED BY 'devdb'" | mysql -uroot -ppassword
	echo "CREATE DATABASE devdb" | mysql -uroot -ppassword
	echo "GRANT ALL ON devdb.* TO 'devdb'@'localhost'" | mysql -uroot -ppassword
	echo "FLUSH PRIVILEGES" | mysql -uroot -ppassword
	touch /var/log/databasesetup
fi

# Setup apache
echo "ServerName localhost" >> /etc/apache2/apache2.conf
a2enmod rewrite

sed -e "s/site-name.local/$SITE_NAME/g" /vagrant/setup/files/host.conf >/etc/apache2/sites-available/host.conf
cp /vagrant/setup/files/xdebug.ini /etc/apache2/mods-available/xdebug.ini

# Create .my.cnf - why doesn't this line work?
cp /vagrant/setup/files/my.cnf ~/.my.cnf

a2ensite host
a2dissite 000-default

# Link repository webroot to server webroot
rm -rf "/var/www/${SITE_NAME}"
ln -fs "${WEBROOT_PATH}" "/var/www/${SITE_NAME}"


# Configure PHP
sed -i '/display_errors = Off/c display_errors = On' /etc/php5/apache2/php.ini
sed -i '/error_reporting = E_ALL & ~E_DEPRECATED/c error_reporting = E_ALL | E_STRICT' /etc/php5/apache2/php.ini
sed -i '/html_errors = Off/c html_errors = On' /etc/php5/apache2/php.ini

# Configure postfix
if [ -f /etc/postfix/main.cf ]; then
	sed -i '/relayhost =/c relayhost = devrelay.in.monkii.com' /etc/postfix/main.cf
fi

# Make sure things are up and running as they should be
service apache2 restart


if [ "$CMS" = "wordpress" ]; then
	cd /tmp
	# Composer
	curl -sS https://getcomposer.org/installer | php
	chmod +x composer.phar
	mv composer.phar /usr/local/bin/composer

	# WP CLI
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	chmod +x wp-cli.phar
	mv wp-cli.phar /usr/local/bin/wp
fi

if [ "$CMS" = "drupal" ]; then
	if ! which drush 2>/dev/null; then
		# Drush
		pear channel-discover pear.drush.org
		pear install drush/drush
		chmod 777 /usr/share/php/drush/lib
	fi
fi

