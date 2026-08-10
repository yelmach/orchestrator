Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  
  config.vm.define "master" do |master|
    master.vm.hostname = "master-node"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "master-node"
    end
    
    master.vm.provision "shell", path: "scripts/master.sh"
  end

  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent1-node"
    agent.vm.network "private_network", ip: "192.168.56.11"
    agent.vm.network "forwarded_port", guest: 30000, host: 3000
    
    agent.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "agent1-node"
    end
    
    agent.vm.provision "shell", path: "scripts/agent.sh"
  end
end