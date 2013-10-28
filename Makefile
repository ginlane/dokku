GITRECEIVE_URL ?= https://raw.github.com/ginlane/gitreceive/master/gitreceive
SSHCOMMAND_URL ?= https://raw.github.com/progrium/sshcommand/master/sshcommand
PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
STACK_URL ?= github.com/ginlane/buildstep
PREBUILT_STACK_URL ?= https://s3.amazonaws.com/progrium-dokku/progrium_buildstep_c30652f59a.tgz

all:
	# Type "make install" to install.

install: savesettings dependencies copyfiles plugins

dokkuonly: savesettings copyfiles pluginhook
	# dokku plugins-install

savesettings:
	- mv /home/git/.ssh /home/.git.ssh
	- mv /home/git/ssl /home/.git.ssl
	rm -rf /home/git
	mkdir /home/git
	- mv /home/.git.ssh /home/git/.ssh
	- mv /home/.git.ssl /home/git/ssl

copyfiles:
	cp dokku /usr/local/bin/dokku
	cp receiver /home/git/receiver
	- rm -rf /var/lib/dokku/plugins
	mkdir -p /var/lib/dokku/plugins
	cp -r plugins/* /var/lib/dokku/plugins

plugins: pluginhook docker
	dokku plugins-install

dependencies: gitreceive sshcommand pluginhook docker stack

gitreceive:
	wget -qO /usr/local/bin/gitreceive ${GITRECEIVE_URL}
	chmod +x /usr/local/bin/gitreceive
	test -f /home/git/receiver || gitreceive init

sshcommand:
	wget -qO /usr/local/bin/sshcommand ${SSHCOMMAND_URL}
	chmod +x /usr/local/bin/sshcommand
	sshcommand create dokku /usr/local/bin/dokku

pluginhook:
	wget -qO /tmp/pluginhook_0.1.0_amd64.deb ${PLUGINHOOK_URL}
	dpkg -i /tmp/pluginhook_0.1.0_amd64.deb

docker: aufs
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker git
	usermod -aG docker dokku
	curl https://get.docker.io/gpg | apt-key add -
	echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install -y lxc-docker 
	sleep 2 # give docker a moment i guess
	rm -rf /var/lib/docker/volumes/*
	docker stop `docker ps -a -q`
	docker rmi `docker images -q`
	chmod 0777 /var/lib/docker/volumes
	chmod 0777 /var/run/docker.sock

aufs:
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`

stack:
	# @docker images | grep ginlane/buildstep ||  was prefixing the below command
	docker build -t ginlane/buildstep ${STACK_URL}

count:
	@echo "Core lines:"
	@cat receiver dokku bootstrap.sh | wc -l
	@echo "Plugin lines:"
	@find plugins -type f | xargs cat | wc -l
	@echo "Test lines:"
	@find tests -type f | xargs cat | wc -l
