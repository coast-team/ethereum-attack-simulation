#!/usr/bin/ruby
require_relative 'utils'
# Import the Distem module
require 'distem'
# The path to the compressed filesystem image
# We can point to local file since our homedir is available from NFS
FSIMG="file:///home/jeisenbarth/public/distem/jessie-ethereum-lxc.tar.gz"
# The first argument of the script is the address (in CIDR format, e.g. 10.144.0.0./22)
# of the virtual network to set-up in our platform
# This ruby hash table describes our virtual network
vnet = {
  'name' => 'testnet',
  'address' => ARGV[0]
}
nodelist = []
cpu_limit = 1
# Read SSH keys
private_key = IO.readlines('/home/jeisenbarth/.ssh/id_rsa').join
public_key = IO.readlines('/home/jeisenbarth/.ssh/id_rsa.pub').join
sshkeys = {
  'private' => private_key,
  'public' => public_key
}
# Connect to the Distem server (on http://localhost:4567 by default)
Distem.client do |cl|
  # Put the physical machines that have been assigned to you
  # You can get that by executing: cat $OAR_NODE_FILE | uniq
  pnodes_list = cl.pnodes_info.map{ |p| p[0]}

  puts 'Creating virtual network'
  #Start by creating the virtual network
  cl.vnetwork_create(vnet['name'], vnet['address'])
  #Creating one virtual node for bootnode and 4 vnodes per pnode for fullnode
  puts 'Creating vnode for bootnode'
  bootnode_name = 'bootnode'
  cl.vnode_create(bootnode_name, { 'host' => pnodes_list[0] }, sshkeys) # first pnode !
  cl.vfilesystem_create(bootnode_name, { 'image' => FSIMG })
  cl.vcpu_create(bootnode_name, cpu_limit, 'ratio', 1)
  cl.viface_create(bootnode_name, 'if0', { 'vnetwork' => vnet['name'], 'default' => 'true' })
  nodelist << bootnode_name
  puts 'Creating vnodes for fullnodes'
  count = 1
  # Iterate on every physical nodes left. The bootstrap node uses one
  pnodes_list[1..-1].each do |pnode|
    # Create 4 virtual nodes per physical machine (one per core)
    4.times do
      nodename = "fullnode#{count}"
      puts "Creating node named #{nodename} -- #{pnode}"
      # Create the first virtual node and set it to be hosted on 'pnode'
      cl.vnode_create(nodename, { 'host' => pnode }, sshkeys)
      # Specify the path to the compressed filesystem image
      # of this virtual node
      cl.vfilesystem_create(nodename, { 'image' => FSIMG })
      # Create a virtual CPU with 1 core on this virtual node
      # specifying that its frequency should be 'cpu_limit'
      cl.vcpu_create(nodename, cpu_limit, 'ratio', 1)
      # Create a virtual network interface and connect it to vnet
      cl.viface_create(nodename, 'if0', { 'vnetwork' => vnet['name'], 'default' => 'true' })
      nodelist << nodename
      count += 1
    end
  end

  puts 'Starting virtual nodes'
  # Starting the virtual nodes using the asynchronous method
  cl.vnodes_start!(nodelist)

  # Print a status message about how many nodes remain to be started
  vnodes_state = nodelist.collect {|x| cl.vnode_info(x)["status"]}
  nb_running = vnodes_state.count("RUNNING")
  old_nb = -1
  while nb_running != vnodes_state.size do
    if old_nb < nb_running
      puts "Remaining to be run : #{vnodes_state.size-nb_running} left"
    end
    vnodes_state = nodelist.map {|x| cl.vnode_info(x)["status"]}
    old_nb = nb_running
    nb_running = vnodes_state.count("RUNNING")
    sleep 1
  end
  puts "Plateform deployment finished. Ready to run the experiment script"
end
