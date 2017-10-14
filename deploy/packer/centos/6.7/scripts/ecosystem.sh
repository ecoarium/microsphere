#!/bin/bash -eux

export git_version='2.8.1'

export rbenv_version='1.0.0'
export rbenv_archive="v${rbenv_version}.zip"

export ruby_install_version='20160330'
export ruby_install_archive="v${ruby_install_version}.zip"

export ruby_version='2.1.4'

function create_sym_links(){
  for binary in "${*}"/* ; do
    ln -s "${binary}" /usr/local/bin/
  done
}

function install_developer_tools(){
  yum -y groupinstall 'Development Tools'

  yum -y install gcc g++ make automake autoconf curl-devel
  yum -y install openssl-devel zlib-devel httpd-devel
  yum -y install apr-devel apr-util-devel sqlite-devel
  yum -y install libffi-devel libyaml-devel readline-devel
  yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel
  yum -y install  gcc perl-ExtUtils-MakeMaker
}

function install_old_ruby(){
  yum -y install ruby
  yum -y install ruby-rdoc ruby-devel
  yum -y install rubygems
}

function install_nokogiri_dependencies(){
  yum -y install libxml2-devel libxslt-devel
}

function install_git(){
  cd /usr/src
  wget "https://www.kernel.org/pub/software/scm/git/git-${git_version}.tar.gz"
  tar xzf "git-${git_version}.tar.gz"

  git_install_dir=/usr/local/git

  cd "git-${git_version}"
  make prefix="${git_install_dir}" all
  make prefix="${git_install_dir}" install

  create_sym_links "${git_install_dir}/bin"
}

function install_rbenv(){
  cd /tmp

  wget "https://github.com/rbenv/rbenv/archive/${rbenv_archive}"
  unzip "${rbenv_archive}"

  mv "rbenv-${rbenv_version}" /usr/local/

  create_sym_links "/usr/local/rbenv-${rbenv_version}/bin"

  cd $OLDPWD
}

function install_ruby_install(){
  cd /tmp
  wget "https://github.com/rbenv/ruby-build/archive/${ruby_install_archive}"
  unzip "${ruby_install_archive}"

  mv "ruby-build-${ruby_install_version}" /usr/local/
  create_sym_links "/usr/local/ruby-build-${ruby_install_version}/bin"

  cd $OLDPWD
}

function install_ruby(){
  install_script="
    export RBENV_ROOT=/usr/local/rbenv
    eval \"\$(rbenv init - )\"
    rbenv install \"${ruby_version}\"
"

  sudo su - "${SSH_USERNAME}" bash -c "$install_script"

  create_sym_links "/home/${SSH_USERNAME}/.rbenv/versions/${ruby_version}/bin"
}

function add_usr_local_bin_to_sudoers_secure_path(){
  sed -i -e 's|^Defaults.*secure_path.*$|Defaults     secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin|' /etc/sudoers
}

function install_nfs(){
  yum -y install nfs-utils nfs-utils-lib
}

add_usr_local_bin_to_sudoers_secure_path
install_developer_tools
install_nokogiri_dependencies
install_git
install_rbenv
install_ruby_install
install_ruby
install_nfs
