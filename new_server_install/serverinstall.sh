#!/bin/sh

#vars
sshkey=`cat ~/.ssh/id_dsa.pub`
adminemail=larry.bolt@gmail.com
username=`whoami`

# standard config, apps, etc

echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' > /etc/apt/sources.list.d/backports.list

apt-get update
apt-get --yes upgrade
apt-get --yes install sudo vim htop git tmux
apt-get --yes install mosh

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


# web server setup
mkdir -p /var/web/{logs,nodeapps,phpapps,pyapps,root,tools,vhosts}

# apache
apt-get --yes install apache2

#mysql
apt-get --yes install mysql-server