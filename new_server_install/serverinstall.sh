#!/bin/sh

#vars
sshkey=`cat ~/.ssh/id_dsa.pub`
adminemail=larry.bolt@gmail.com
username=`whoami`
servername=yuna\.codr\.in

# standard config, apps, etc

echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' > /etc/apt/sources.list.d/backports.list

apt-get update
apt-get --yes upgrade
apt-get --yes install sudo vim htop git tmux sendmail curl git-core
apt-get --yes install mosh
apt-get --yes install p7zip
apt-get --yes install build-essential

apt-get --yes install denyhosts
sed -i 's/root\@localhost/larry\.bolt\@gmail\.com/g' /etc/denyhosts.conf

apt-get --yes install fail2ban
sed -i 's/root\@localhost/larry\.bolt\@gmail\.com/g' /etc/fail2ban/jail.conf
/etc/init.d/fail2ban restart

# add main user
adduser $username
usermod -a -G sudo $username
visudo
# change %sudo ALL=(ALL) NOPASSWD: ALL

# ssh keys
mkdir .ssh
echo $sshkeys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

# redis
apt-get install redis-server

# web server setup
mkdir -p /var/web/{logs,nodeapps,phpapps,pyapps,root,tools,vhosts}
cd /var/web
echo 'Hello world!' >> /var/web/root/index.html
addgroup web
chgrp -R web .
chmod -R 775 .
chmod g+s .


# apache
apt-get --yes install apache2

# apache config files
a2enmod vhost_alias
cd /etc/apache2/sites-enabled
sed -i 's/SERVERNAME/$servername/g' ./*



#mysql
apt-get --yes install mysql-server
mysql_secure_installation


#php
apt-get --yes install php5 php-pear php5-mysql php5-suhosin php5-mcrypt php5-curl

#phmyadmin
cd /var/web/tools
wget http://downloads.sourceforge.net/project/phpmyadmin/phpMyAdmin/3.5.7/phpMyAdmin-3.5.7-all-languages.7z
7zr x phpMyAdmin-3.5.7-all-languages.7z
rm phpMyAdmin-3.5.7-all-languages.7z
mv phpMyAdmin-3.5.7-all-languages/ phpMyAdmin
rm .travis.yml .htaccess
cd phpMyAdmin
cp config.sample.inc.php config.inc.php
vim config.inc.php

mysql -uroot -p < phpMyAdmin/examples/create_tables.sql

cd /var/web/root
ln -s ../tools/phpMyAdmin/ ./pma