# http://www.andmarios.com/en/2012/06/gitlab-on-an-ubuntu-10-04-server-with-apache/

# git setup
apt-get install -y zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev

sudo adduser \
  --system \
  --shell /bin/sh \
  --gecos 'Git Version Control' \
  --group \
  --disabled-password \
  --home /home/git \
  git

sudo adduser --disabled-login --gecos 'GitLab' gitlab

# Add it to the git group
sudo usermod -a -G git gitlab

# Generate the SSH key
sudo -u gitlab -H ssh-keygen -q -N '' -t rsa -f /home/gitlab/.ssh/id_rsa

cd /home/git
sudo -u git -H git clone -b gl-v320 https://github.com/gitlabhq/gitolite.git /home/git/gitolite

sudo -u git -H mkdir /home/git/bin
sudo -u git -H sh -c 'printf "%b\n%b\n" "PATH=\$PATH:/home/git/bin" "export PATH" >> /home/git/.profile'
sudo -u git -H sh -c 'gitolite/install -ln /home/git/bin'

# Copy the gitlab user's (public) SSH key ...
sudo cp /home/gitlab/.ssh/id_rsa.pub /home/git/gitlab.pub
sudo chmod 0444 /home/git/gitlab.pub

# ... and use it as the admin key for the Gitolite setup
sudo -u git -H sh -c "PATH=/home/git/bin:$PATH; gitolite setup -pk /home/git/gitlab.pub"

# Make sure the Gitolite config dir is owned by git
sudo chmod 750 /home/git/.gitolite/
sudo chown -R git:git /home/git/.gitolite/

# Make sure the repositories dir is owned by git and it stays that way
sudo chmod -R ug+rwXs,o-rwx /home/git/repositories/
sudo chown -R git:git /home/git/repositories/

sudo -u gitlab -H ssh git@localhost

# sql
# CREATE USER 'gitlab'@'localhost' IDENTIFIED BY 'gitlabpassword'
# CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
# GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlabhq_production`.* TO 'gitlab'@'localhost';

cd /home/gitlab/gitlab

# Copy the example GitLab config
sudo -u gitlab -H cp config/gitlab.yml.example config/gitlab.yml

# Make sure to change "localhost" to the fully-qualified domain name of your
# host serving GitLab where necessary
sudo -u gitlab -H vim config/gitlab.yml

# Make sure GitLab can write to the log/ and tmp/ directories
sudo chown -R gitlab log/
sudo chown -R gitlab tmp/
sudo chmod -R u+rwX  log/
sudo chmod -R u+rwX  tmp/

# Make directory for satellites
sudo -u gitlab -H mkdir /home/gitlab/gitlab-satellites

# Copy the example Unicorn config
sudo -u gitlab -H cp config/unicorn.rb.example config/unicorn.rb

sudo -u gitlab cp config/database.yml.mysql config/database.yml
sudo -u gitlab vim config/database.yml

cd /home/gitlab/gitlab

sudo gem install charlock_holmes --version '0.6.9'

# For MySQL (note, the option says "without")
sudo -u gitlab -H bundle install --deployment --without development test postgres

sudo -u gitlab -H git config --global user.name "GitLab"
sudo -u gitlab -H git config --global user.email "gitlab@gitlab.yuna.codr.in"


sudo cp ./lib/hooks/post-receive /home/git/.gitolite/hooks/common/post-receive
sudo chown git:git /home/git/.gitolite/hooks/common/post-receive
sudo -u gitlab -H bundle exec rake gitlab:setup RAILS_ENV=production

