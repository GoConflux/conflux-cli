#!/bin/sh
{
    CONFLUX_CLI_URL="http://confluxapp.s3-website-us-west-1.amazonaws.com/toolbelt/conflux-cli.tgz"

    echo "This script requires superuser access to install software."
    echo "You will be prompted for your password by sudo."

    # clear any previous sudo permission
    sudo -k

    # run inside sudo
    sudo sh <<SCRIPT

  # download and extract the client tarball
  rm -rf /usr/local/conflux
  mkdir -p /usr/local/conflux
  cd /usr/local/conflux

  if [ -z "$(which wget)" ]; then
    curl -s $CONFLUX_CLI_URL | tar xz
  else
    wget -qO- $CONFLUX_CLI_URL | tar xz
  fi

  mv conflux-cli/* .
  rm -rf conflux-cli/
  cp bin/conflux /usr/local/bin/conflux

SCRIPT

    echo "Successfully installed Conflux CLI."
    echo "Type 'conflux help' for a list of available commands."
}