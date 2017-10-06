#!/usr/bin/env bash

function ensure_wget_installed(){
  if ! which wget ; then
    pacman -S --noconfirm wget
  fi
}
ensure_wget_installed

function ensure_unzip_installed(){
  if ! which unzip ; then
    pacman -S --noconfirm unzip
  fi
}
ensure_unzip_installed

function ensure_git_credential_helper_set(){
  if [[ -z "$(git config --global --get credential.helper)" ]]; then
    git config --global credential.helper wincred
  fi
}
ensure_git_credential_helper_set

function ensure_rbenv_installed(){
  local ruby_version=2.2.4

  if [[ $(which ruby) && $(ruby -v | grep -q $ruby_version) ]]; then
    return 0
  fi

  if [[ ! -e '/usr/local/rbenv' ]]; then
    git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv
  fi

  if [[ ! -e '/usr/local/ruby-install' ]]; then
    git clone https://github.com/ecoarium/windows-ruby-install.git /usr/local/ruby-install
  fi

  if [[ ! -e '/etc/profile.d/rbenv.sh' ]]; then
    # Add rbenv to the path:
    echo '# rbenv setup' > /etc/profile.d/rbenv.sh
    echo 'export PATH="/usr/local/rbenv/libexec:$PATH"' >> /etc/profile.d/rbenv.sh
    echo 'export PATH="/usr/local/ruby-install/bin:$PATH"' >> /etc/profile.d/rbenv.sh
    echo 'export RBENV_ROOT=/usr/local/.rbenv' >> /etc/profile.d/rbenv.sh
    echo 'eval "$(rbenv init - )"' >> /etc/profile.d/rbenv.sh

    chmod +x /etc/profile.d/rbenv.sh
  fi

  if [[ ! $(which rbenv) || ! $(which ruby-install) ]]; then
    source /etc/profile.d/rbenv.sh
  fi

  rbenv install $ruby_version
  rbenv global $ruby_version
  rbenv rehash
}
ensure_rbenv_installed

mkdir -p /usr/local/bin
