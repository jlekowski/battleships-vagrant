# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.network "private_network", ip: "10.10.10.10"

  config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
  end

  config.ssh.forward_agent = true

  config.vm.provision "file", source: "provision/varnish/battleships-api.vcl", destination: "battleships-api.vcl"
  config.vm.provision "shell", path: "provision/root.sh"
  config.vm.provision "shell", path: "provision/user.sh", args: [ENV['VAGRANT_NAME'] || '', ENV['VAGRANT_EMAIL'] || ''], privileged: false
  config.vm.provision "file", source: "provision/nginx/battleships-api", destination: "battleships-api"
  config.vm.provision "shell", path: "provision/battleships-api.sh", privileged: false
  config.vm.provision "file", source: "provision/nginx/battleships-webclient", destination: "battleships-webclient"
  config.vm.provision "shell", path: "provision/battleships-webclient.sh", privileged: false
  config.vm.provision "shell", path: "provision/battleships-apiclient.sh", privileged: false
end
