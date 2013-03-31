# Script que instala Gamersmafia en un sistema Ubuntu.
#
# El script es bastante agresivo a la hora de instalar paquetes por lo que es
# aconsejable usarlo en una máquina virtual o en una instalación que no tenga
# nada más.
#
# Es seguro ejecutar este script más de una vez ya que no se borran base de
# datos o repositorios existentes.
#
# Para más información:
#
#   https://github.com/slnc/gamersmafia

set -u
set -e

APACHE2_MODULES="expires headers rewrite"
GM_CURRENT="/srv/www/gamersmafia/current"
GM_APACHE_CONFIG="${GM_CURRENT}/config/apache.morpheus.conf"
GIT_REPOSITORY="git://github.com/gamersmafia/gamersmafia.git"
MATCHIT_URL="http://www.vim.org/scripts/download_script.php?src_id=8196"
CTRLP_URL="https://github.com/kien/ctrlp.vim/archive/master.zip"
PACKAGES_TO_INSTALL="
apache2
apache2-mpm-prefork
apache2-threaded-dev
apache2.2-bin
apache2.2-common
build-essential
exuberant-ctags
git
libapr1-dev
libaprutil1-dev
libcurl4-openssl-dev
libgraphicsmagick++1-dev
libgraphicsmagick1-dev
libmagick++-dev
libopenssl-ruby
libpq-dev
libtidy-0.99-0
libxml2-dev libxml2 libxslt1-dev
nodejs
openjdk-7-jre
openssh-server
postgresql
postgresql-client
rpl
redis-server
ruby1.9.1-full
tmux
vim-nox
zip
"

Bootstrap() {
  InstallSystemPackages
  CloneRepo
  SetupPostgreSql
  SetupApache2
  SetupGamersmafiaApp
  DownloadMiscConfigFiles
  PrintFinalNotes
}

DownloadMiscConfigFiles() {
  BOOTSTRAP_GITHUB_URL=https://raw.github.com/gamersmafia/gamersmafia/master/script/bootstrap
  mkdir -p ~/.vim/sessions
  wget -O ~/.vimrc ${BOOTSTRAP_GITHUB_URL}/.vimrc
  wget -O ~/.gitconfig ${BOOTSTRAP_GITHUB_URL}/.gitconfig
  wget -O ~/.bashrc_gm ${BOOTSTRAP_GITHUB_URL}/.bashrc
  wget -O ~/.vim/matchit.zip ${MATCHIT_URL} && cd ~/.vim && unzip matchit.zip && cd
  wget -O ~/.vim/ctrlp.zip ${CTRLP_URL} && cd ~/.vim && unzip ctrlp.zip && cd
  wget -O ~/.tmux.conf ${BOOTSTRAP_GITHUB_URL}/.tmux.conf
  echo -e "\nsource ~/.bashrc_gm" >> ~/.bashrc
}

CloneRepo() {
  if [ ! -d ${GM_CURRENT} ]; then
    sudo mkdir -p ${GM_CURRENT}
    sudo chown -R ${USER} ${GM_CURRENT}
    git clone ${GIT_REPOSITORY} ${GM_CURRENT}
  fi
}

InstallSystemPackages() {
  sudo apt-get update -qq -y
  sudo apt-get install -qq -y `echo ${PACKAGES_TO_INSTALL} | tr '\n' ' '`
  sudo gem update rubygems-update=1.3.5
  sudo REALLY_GEM_UPDATE_SYSTEM=1 gem update --system
  if ! gem list --local | grep -q passenger
  then
    sudo gem install passenger --no-rdoc --no-ri
  fi
  sudo gem install bundler --no-rdoc --no-ri
}

SetupPostgreSql() {
  sudo rpl " peer" " trust" /etc/postgresql/9.1/main/pg_hba.conf
  sudo rpl "127.0.0.1/32            md5" "127.0.0.1/32            trust" /etc/postgresql/9.1/main/pg_hba.conf
  export PGUSER=postgres
  if ! grep -q PGUSER ~/.bashrc
  then
    echo "export PGUSER=postgres" >> ~/.bashrc
  fi
  sudo /etc/init.d/postgresql restart

  if ! `psql --list | grep -q gamersmafia`
  then
    for db in gamersmafia gamersmafia_test
    do
      createdb ${db}
    done
  fi
}

SQL_USERS_TABLE_EXISTS="select * from pg_tables where schemaname='public' and tablename='users';"

SetupGamersmafiaApp() {
  old_pwd=`pwd`
  cd ${GM_CURRENT}
  sudo bundle install
  if ! psql -c "${SQL_USERS_TABLE_EXISTS}" gamersmafia | grep -q users
  then
    psql -f db/create.sql gamersmafia
    rake db:fixtures:load
    ./script/sync_testenv.sh
    cp ${GM_CURRENT}/config/app.yml ${GM_CURRENT}/config/app_production.yml
    rpl ".com" ".dev" ${GM_CURRENT}/config/app_production.yml
  fi
  cd ${old_pwd}
  sudo apache2ctl restart
}

SetupApache2() {
  for module in ${APACHE2_MODULES}
  do
    module_dst="/etc/apache2/mods-enabled/${module}.load"
    if [ ! -f ${module_dst} ]; then
      sudo ln -s /etc/apache2/mods-available/${module}.load ${module_dst}
    fi
  done

  apache2_config_dst="/etc/apache2/sites-enabled/gamersmafia.conf"
  if [ ! -f ${apache2_config_dst} ]; then
    sudo ln -s ${GM_APACHE_CONFIG} ${apache2_config_dst}
  fi

  if ! grep -q passenger /etc/apache2/apache2.conf
  then
    sudo passenger-install-apache2-module -a
    passenger_snippet=`sudo passenger-install-apache2-module -a --snippet`
    passenger_config="/tmp/apache2-passenger.conf"
    rm -f ${passenger_config}
    echo "${passenger_snippet}" > /tmp/apache2-passenger.conf
    sudo sh -c "cat ${passenger_config} >> /etc/apache2/apache2.conf"
  fi
}

GetEth0Ip() {
  /sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
}


PrintFinalNotes() {
  ip=`GetEth0Ip`
  msg=`cat <<END

INSTALACIÓN COMPLETADA
GM debería estar ejecutándose en el puerto 80. Para acceder a ella edita el
archivo hosts de tu sistema principal y añade la siguiente línea:

  ${ip} gamersmafia.dev bazar.gamersmafia.dev arena.gamersmafia.dev


E intenta acceder desde tu navegador escribiendo:

  http://gamersmafia.dev/

Ya hay un usuario registrado con todos los poderes.
Login: "unnamed", password: "unnamedhacker"

Recuerda que si tienes un cliente ssh puedes conectarte al servidor por ssh.

END`
echo -e "$msg\n"
}

Bootstrap
