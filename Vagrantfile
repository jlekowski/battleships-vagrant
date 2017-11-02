# -*- mode: ruby -*-
# vi: set ft=ruby :

# run `VAGRANT_DB_COUNT=5 vagrant status` to check
dbCount = ENV['VAGRANT_DB_COUNT'] ? ENV['VAGRANT_DB_COUNT'].to_i : 2

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.define "dev", autostart: false do |dev|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-dev"
      vb.memory = "1536"
    end
    dev.vm.network "private_network", ip: "10.10.10.10"
    dev.vm.host_name = "dev"
    dev.vm.synced_folder "~/dev", "/home/ubuntu/dev"
    dev.vm.provision "shell", inline: "sudo ln -fs ~/dev /var/www", privileged: false
    dev.vm.provision "file", source: "provision/varnish/battleships-api.vcl", destination: "battleships-api.vcl"
    dev.vm.provision "shell", path: "provision/root-web.sh", args: [1]
    dev.vm.provision "shell", path: "provision/user-web.sh", args: [ENV['VAGRANT_NAME'] || '', ENV['VAGRANT_EMAIL'] || '', '/tmp'], privileged: false
    dev.vm.provision "file", source: "provision/nginx/battleships-api", destination: "battleships-api"
    dev.vm.provision "file", source: "provision/battleships-api-acl.sh", destination: "battleships-api-acl.sh"
    dev.vm.provision "shell", path: "provision/battleships-api.sh", args: [0, 1, '/tmp', 1], privileged: false
    dev.vm.provision "shell", path: "provision/battleships-api-acl.sh", args: ['/tmp'], run: "always", privileged: false
  end

  # DB must be created before web is provisioned
  (1..dbCount).each do |i|
    config.vm.define "db#{i}" do |db|
      config.vm.provider "virtualbox" do |vb|
        vb.name = "battleships-vagrant-db#{i}"
        vb.memory = "768"
      end
      db.vm.network "private_network", ip: "10.10.10.1#{i}"
      db.vm.host_name = "db#{i}"
      db.vm.provision "shell", path: "provision/root-db.sh", args: [i, "10.10.10.1#{i}", '10.10.10.10']
      db.vm.provision "shell", path: "provision/user-db.sh", privileged: false
    end
  end

  config.vm.define "web", primary: true do |web|
    config.vm.provider "virtualbox" do |vb|
      vb.name = "battleships-vagrant-web"
      vb.memory = "1536"
    end
    web.vm.network "private_network", ip: "10.10.10.10"
    web.vm.host_name = "web"
    web.vm.synced_folder "~/dev", "/home/ubuntu/dev" #, owner: "ubuntu", group: "ubuntu"
    web.vm.provision "file", source: "provision/varnish/battleships-api.vcl", destination: "battleships-api.vcl"
    web.vm.provision "shell", path: "provision/root-web.sh"
    web.vm.provision "shell", path: "provision/user-web.sh", args: [ENV['VAGRANT_NAME'] || '', ENV['VAGRANT_EMAIL'] || ''], privileged: false
    web.vm.provision "file", source: "provision/nginx/battleships-api", destination: "battleships-api"
    web.vm.provision "file", source: "provision/battleships-api-acl.sh", destination: "battleships-api-acl.sh"
    web.vm.provision "shell", path: "provision/battleships-api.sh", args: [dbCount], privileged: false
    web.vm.provision "file", source: "provision/nginx/battleships-webclient", destination: "battleships-webclient"
    web.vm.provision "shell", path: "provision/battleships-webclient.sh", privileged: false
    web.vm.provision "shell", path: "provision/battleships-apiclient.sh", privileged: false
  end

  config.ssh.forward_agent = true
end
