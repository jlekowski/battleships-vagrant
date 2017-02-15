# -*- mode: ruby -*-
# vi: set ft=ruby :

$aclScript = <<SCRIPT
  mkdir /tmp/var
  sudo setfacl -R -m u:"www-data":rwX -m u:`whoami`:rwX /tmp/var
  sudo setfacl -dR -m u:"www-data":rwX -m u:`whoami`:rwX /tmp/var
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.define "dev", autostart: false do |dev|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-dev"
      vb.memory = "2048"
    end
    dev.vm.network "private_network", ip: "10.10.10.10"
    dev.vm.host_name = "dev"
    dev.vm.synced_folder "~/dev", "/home/ubuntu/dev"
    dev.vm.provision "shell", inline: "sudo ln -fs ~/dev /var/www", privileged: false
    dev.vm.provision "file", source: "provision/varnish/battleships-api.vcl", destination: "battleships-api.vcl"
    dev.vm.provision "shell", path: "provision/root.sh", args: [1]
    dev.vm.provision "shell", path: "provision/user.sh", args: [ENV['VAGRANT_NAME'] || '', ENV['VAGRANT_EMAIL'] || '', '/tmp'], privileged: false
    dev.vm.provision "file", source: "provision/nginx/battleships-api", destination: "battleships-api"
    dev.vm.provision "shell", path: "provision/battleships-api.sh", args: [1, '/tmp', 1], privileged: false
    dev.vm.provision "shell", inline: $aclScript, run: "always", privileged: false
  end

  config.vm.define "web", primary: true do |web|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-web"
      vb.memory = "2048"
    end
    web.vm.network "private_network", ip: "10.10.10.10"
    web.vm.host_name = "web"
    web.vm.provision "file", source: "provision/varnish/battleships-api.vcl", destination: "battleships-api.vcl"
    web.vm.provision "shell", path: "provision/root.sh"
    web.vm.provision "shell", path: "provision/user.sh", args: [ENV['VAGRANT_NAME'] || '', ENV['VAGRANT_EMAIL'] || ''], privileged: false
    web.vm.provision "file", source: "provision/nginx/battleships-api", destination: "battleships-api"
    web.vm.provision "shell", path: "provision/battleships-api.sh", privileged: false
    web.vm.provision "file", source: "provision/nginx/battleships-webclient", destination: "battleships-webclient"
    web.vm.provision "shell", path: "provision/battleships-webclient.sh", privileged: false
    web.vm.provision "shell", path: "provision/battleships-apiclient.sh", privileged: false
  end

  config.vm.define "db-master", autostart: false do |db|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-db-master"
      vb.memory = "1024"
    end
    db.vm.network "private_network", ip: "10.10.10.11"
    db.vm.host_name = "db-master"
    db.vm.provision "shell", path: "provision/root-db-master.sh", args: ['10.10.10.11']
    db.vm.provision "shell", path: "provision/user-db.sh", privileged: false
  end

  config.vm.define "db-slave", autostart: false do |db|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-db-slave"
      vb.memory = "768"
    end
    db.vm.network "private_network", ip: "10.10.10.12"
    db.vm.host_name = "db-slave"
    db.vm.provision "shell", path: "provision/root-db-slave.sh", args: ['10.10.10.12']
    db.vm.provision "shell", path: "provision/user-db.sh", privileged: false
  end

#  config.vm.define "db-slave2", autostart: false do |db|
#    config.vm.provider "virtualbox" do |vb|
#      vb.name = "battleships-vagrant-db-slave2"
#      vb.memory = "768"
#    end
#   db.vm.network "private_network", ip: "10.10.10.13"
#    db.vm.host_name = "db-slave2"
#    db.vm.provision "shell", path: "provision/root-db-slave.sh", args: ['10.10.10.13']
#    db.vm.provision "shell", path: "provision/user-db.sh", privileged: false
#  end

  config.ssh.forward_agent = true
end
