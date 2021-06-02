# This file is for testing ansible provisioning
# locally using vagrant.
# To run it, run `vargrant up` in this foler.

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/focal64"

  # Julia will need some RAM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "ansible" do |ansible|
    ansible.verbose = "v"
    ansible.playbook = "r.yml"
  end
end
