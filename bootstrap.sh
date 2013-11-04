#!/usr/bin/env bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive
export DOKKU_REPO=${DOKKU_REPO:-"https://github.com/ginlane/dokku.git"}

if ! which apt-get &>/dev/null
then
	echo "This installation script requres apt-get. For manual installation instructions, consult https://github.com/ginlane/dokku ."
	exit 1
fi

apt-get update
apt-get install -y git make curl software-properties-common

cd ~  
rm -rf dokku
git clone $DOKKU_REPO
cd dokku && test $DOKKU_BRANCH && git checkout origin/$DOKKU_BRANCH || true
make install
dokku plugins-install
make stack

echo
echo "Be sure to upload a public key for your user:"
echo "  cat ~/.ssh/id_rsa.pub | ssh root@$HOSTNAME \"sudo sshcommand acl-add dokku yourusername\""
