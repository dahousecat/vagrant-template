Vagrant.configure("2") do |config|

  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  config.vm.box = "ubuntu/monkiitrusty64"
# config.vm.box_url = "https://vagrantcloud.com/ubuntu/trusty64"
  config.vm.box_url = "http://my.monkii.com.au/vagrant/trusty-server-amd-64-monkii-vagrant.box"

  config.vm.provision :shell, path: "setup/bootstrap.sh"
  config.vm.provision :shell, run: "always", :path => "setup/load.sh"
  config.vm.network :private_network, ip: "192.168.56.101"
  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provider :virtualbox do |v|
		v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
		v.customize ["modifyvm", :id, "--memory", 1024]
		#v.customize ["modifyvm", :id, "--name", "precise64"]
	end

	config.vm.synced_folder ".", "/vagrant", nfs: true

end

