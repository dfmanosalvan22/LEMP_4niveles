# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "debian/bookworm64"

  #server base de datos
  config.vm.define "serverdb1felipe" do |serverdb1felipe|
    serverdb1felipe.vm.hostname = "serverdb1felipe"  
    serverdb1felipe.vm.network "private_network", ip: "192.168.40.20", virtualbox__intnet: "REDINTERNA4"
    
    serverdb1felipe.vm.provider "virtualbox" do |vb|
      vb.name = "serverdb1felipe"
      vb.memory = "1024"
      vb.cpus = 1
    end

    serverdb1felipe.vm.provision "shell" do |serverdb1felipe|
      serverdb1felipe.path = "scripts/galera.sh"
      serverdb1felipe.args = ["192.168.40.20", "serverdb1felipe", "bootstrap"]
    end
  end 

  config.vm.define "serverdb2felipe" do |serverdb2felipe|
    serverdb2felipe.vm.hostname = "serverdb2felipe"  
    serverdb2felipe.vm.network "private_network", ip: "192.168.40.21", virtualbox__intnet: "REDINTERNA4"
    
    serverdb2felipe.vm.provider "virtualbox" do |vb|
      vb.name = "serverdb2felipe"
      vb.memory = "1024"
      vb.cpus = 1
    end

    serverdb2felipe.vm.provision "shell" do |serverdb2felipe|
      serverdb2felipe.path = "scripts/galera.sh"
      serverdb2felipe.args = ["192.168.40.21", "serverdb2felipe"]
    end
  end 


  config.vm.define "serverdb3felipe" do |serverdb3felipe|
    serverdb3felipe.vm.hostname = "serverdb3felipe"  
    serverdb3felipe.vm.network "private_network", ip: "192.168.40.22", virtualbox__intnet: "REDINTERNA4"
    
    serverdb3felipe.vm.provider "virtualbox" do |vb|
      vb.name = "serverdb3felipe"
      vb.memory = "1024"
      vb.cpus = 1
    end

    serverdb3felipe.vm.provision "shell" do |serverdb3felipe|
      serverdb3felipe.path = "scripts/galera.sh"
      serverdb3felipe.args = ["192.168.40.22", "serverdb3felipe"]
    end
  end 


  #server haproxy
  config.vm.define "proxybbddfelipe" do |proxybbddfelipe|
    proxybbddfelipe.vm.hostname = "proxybbddfelipe"
    proxybbddfelipe.vm.network "private_network", ip: "192.168.30.10", virtualbox__intnet: "REDINTERNA3"
    proxybbddfelipe.vm.network "private_network", ip: "192.168.40.10", virtualbox__intnet: "REDINTERNA4"

    proxybbddfelipe.vm.provider "virtualbox" do |vb|
      vb.name = "proxybbddfelipe"
      vb.memory = "512"
      vb.cpus = 1
    end

    proxybbddfelipe.vm.provision "shell", path: "scripts/haproxy.sh"
  end

  #server nfs + php-fpm
  config.vm.define "servernfsfelipe" do |servernfsfelipe|
    servernfsfelipe.vm.hostname = "servernfsfelipe"
    servernfsfelipe.vm.network "private_network", ip: "192.168.20.10", virtualbox__intnet: "REDINTERNA2"
    servernfsfelipe.vm.network "private_network", ip: "192.168.30.20", virtualbox__intnet: "REDINTERNA3"

    servernfsfelipe.vm.provider "virtualbox" do |vb|
      vb.name = "servernfsfelipe"
      vb.cpus = 1
    end
    servernfsfelipe.vm.provision "shell", path: "scripts/nfs.sh"
  end

  #Servidor web 1
  config.vm.define "serverweb1felipe" do |serverweb1felipe|
    serverweb1felipe.vm.hostname = "serverweb1felipe"
    serverweb1felipe.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "REDINTERNA1"
    serverweb1felipe.vm.network "private_network", ip: "192.168.20.20", virtualbox__intnet: "REDINTERNA2"

    serverweb1felipe.vm.provider "virtualbox" do |vb|
      vb.name = "serverweb1felipe"
      vb.memory = "512"
      vb.cpus = 1
    end
    serverweb1felipe.vm.provision "shell", path: "scripts/serverweb.sh"
  end

  #Servidor web 2
  config.vm.define "serverweb2felipe" do |serverweb2felipe|
    serverweb2felipe.vm.hostname = "serverweb2felipe"
    serverweb2felipe.vm.network "private_network", ip: "192.168.10.30", virtualbox__intnet: "REDINTERNA1"
    serverweb2felipe.vm.network "private_network", ip: "192.168.20.30", virtualbox__intnet: "REDINTERNA2"

    serverweb2felipe.vm.provider "virtualbox" do |vb|
      vb.name = "serverweb2felipe"
      vb.memory = "512"
      vb.cpus = 1
    end
    serverweb2felipe.vm.provision "shell", path: "scripts/serverweb.sh"
  end

  #Balanceador
  config.vm.define "balanceadorfelipe" do |balanceadorfelipe|
    balanceadorfelipe.vm.hostname = "balanceadorfelipe"
    balanceadorfelipe.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "REDINTERNA1"
    balanceadorfelipe.vm.network "public_network"
    balanceadorfelipe.vm.network "forwarded_port", guest: 80, host: 8080

    balanceadorfelipe.vm.provider "virtualbox" do |vb|
      vb.name = "balanceadorfelipe"
      vb.memory = "512"
      vb.cpus = 1
    end

    balanceadorfelipe.vm.provision "shell", path: "scripts/balanceador.sh"
  end


end
  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Disable the default share of the current code directory. Doing this
  # provides improved isolation between the vagrant box and your host
  # by making sure your Vagrantfile isn't accessible to the vagrant box.
  # If you use this you may want to enable additional shared subfolders as
  # shown above.
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Ansible, Chef, Docker, Puppet and Salt are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   apt-get update
  #   apt-get install -y apache2
  # SHELL
