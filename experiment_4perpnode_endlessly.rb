#!/usr/bin/ruby
require_relative 'utils'
require 'json'
require 'distem'
require "optparse"

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "This script starts 40 ethereum miners.\n\nUsage: test.rb -i FILE_PATH -n NUMBER"

  opts.on("-i", "--input_file FILE_PATH", String, "The path of the file that will contain the info of the deployed nodes") do |nodes_file_path|
    options[:nodes_file_path] = nodes_file_path
  end

  options[:ethstats] = false
  opts.on("-s", "--ethstats", OptionParser::DecimalInteger, "It activates the ethereum network monitoring service") do |ethstats|
    options[:ethstats] = true
  end

end
optparse.parse!

ethstats = options[:ethstats]
nodes_filepath = options[:nodes_file_path]

raise OptionParser::MissingArgument, "The path of the file must be specified.\n\n#{optparse.help()}" if nodes_filepath.nil?

Distem.client do |cl|
  MyConfig::NODELIST.each_with_index do |node, index|
    # Adding the connection to Internet for the nodes
    node[:address] = cl.viface_info(node[:name],MyConfig::IFNAME)['address'].split('/')[0]
    cl.vnode_execute(node[:name], "rm /etc/resolv.conf && cp /home/lxc/resolv.conf /etc/")
    cl.vnode_execute(node[:name], "ifconfig #{MyConfig::IFNAME} #{node[:address]} netmask 255.252.0.0")
    cl.vnode_execute(node[:name], "route add default gw #{MyConfig::GATEWAY} dev #{MyConfig::IFNAME}")
    puts "Connection to www allowed for #{node[:name]}"
  end

  # Start the bootnode
  puts "Starting bootstrap node service at #{MyConfig::BOOTNODE[:address]}"
  ret = cl.vnode_execute(MyConfig::BOOTNODE[:name], "systemctl start bootstrap_node.service")
  puts "Bootstrap node service : #{ret}"

  bootkey_file = cl.vnode_execute(MyConfig::BOOTNODE[:name], %Q[ps -eo command | grep "^bootnode" | head -n 1 | cut -d'=' -f2])
  raise 'Bootnode command should be started ... Something wrong happened' if bootkey_file.first.nil?
  enode_addr = cl.vnode_execute(MyConfig::BOOTNODE[:name], "bootnode -nodekey=#{bootkey_file.first} -writeaddress")
  raise 'Bootnode address should be retrievable ... Something wrong happened' if enode_addr.first.nil?
  enode = "enode://#{enode_addr.first}@#{MyConfig::BOOTNODE[:address]}:#{MyConfig::BOOTNODE_PORT}"
  puts "Bootstrap enode : #{enode}"

  # Start the full ethereum nodes
  MyConfig::FULLNODES.each do |fullnode|
    puts "#{fullnode[:name]} at #{fullnode[:address]}"
    # Check if this node has an account
    # When creating a new account, we write the account address to a file.
    # So here we check if the file exists
    ret = cl.vnode_execute(fullnode[:name], "[ -f #{MyConfig::ACCOUNT_ADDRESS_FILE} ]; echo $?")
    if ret != 0 then
      # No account -> creation
      puts "No account yet for #{fullnode[:name]}. Creation ..."
      new_account_command = %Q[geth --datadir #{MyConfig::DATADIR} --password #{MyConfig::PASSWORD_FILE} account new | grep -Eo "\\{\\w+\\}" | sed 's/{//;s/}//;' | tee #{MyConfig::ACCOUNT_ADDRESS_FILE}]
      # Write the command used to create a new account to /tmp/new_account_command.txt
      # cl.vnode_execute(fullnode[:name], "echo new_account_command > /tmp/new_account_command.txt")
      cl.vnode_execute(fullnode[:name], new_account_command)
    end
    account_address = cl.vnode_execute(fullnode[:name], "cat #{MyConfig::ACCOUNT_ADDRESS_FILE}")
    account_address = account_address.first
    # Generating the first block using the custom_genesis.json file
    ret = cl.vnode_execute(fullnode[:name], %Q[geth --datadir #{MyConfig::DATADIR} init #{MyConfig::GENESIS_FILE}])
    puts "Generate the genesis file for #{fullnode[:name]} : #{ret}"
    # Use of nohup to avoid vnode_execute hanging or geth being killed when vnode_execute returns (because of the ssh connection ?)
    # And displays to stdout the pid of this backgrounded process
    geth_command = %Q[nohup geth --rpc --rpcaddr #{fullnode[:address]} --rpcport #{fullnode[:rpc_port]} --datadir #{MyConfig::DATADIR} --identity #{fullnode[:name]} --port #{fullnode[:node_port]} --rpcapi #{MyConfig::RPC_API} --bootnodes #{enode} --unlock #{account_address} --password #{MyConfig::PASSWORD_FILE} --etherbase #{account_address} > /tmp/geth.out 2> /tmp/geth.err < /dev/null & echo -n $!]
    # Write the command used to execute a ethereum fullnode to /tmp/geth_command.txt
    # cl.vnode_execute(fullnode[:name], "echo #{geth_command} > /tmp/geth_command.txt")
    pid = cl.vnode_execute(fullnode[:name], geth_command)
    raise "pid should be an non-empty array. Output : #{pid}" if !pid.respond_to?('first') || pid.first.nil?
    fullnode[:pid] = pid.first
    puts "Geth running, pid : #{fullnode[:pid]}"
    # Launch of the ethstats service
    if ethstats
      cl.vnode_execute(fullnode[:name], "sed -i 's/rpc_ip_addr/#{fullnode[:address]}/' #{MyConfig::ETHSTATS_BACKEND_PATH}")
      cl.vnode_execute(fullnode[:name], "sed -i 's/ethstats_ip_addr/#{MyConfig::ETHSTATS_FRONTEND_URL}/' #{MyConfig::ETHSTATS_BACKEND_PATH}")
      cl.vnode_execute(fullnode[:name], "sed -i 's/fullnode#?/#{fullnode[:name]}/' #{MyConfig::ETHSTATS_BACKEND_PATH}")
      cl.vnode_execute(fullnode[:name], "systemctl start eth_net_intelligence_api.service")
    end
  end

  puts "#{MyConfig::FULLNODES.size} ethereum nodes are running endlessly"
  puts "Starting the mining on all the fullnodes."
  MyConfig::FULLNODES.each do |fullnode|
    cl.vnode_execute(fullnode[:name], %Q[geth --exec "miner.start(1)" attach "http://#{fullnode[:address]}:#{fullnode[:rpc_port]}"])
  end
  puts "All the ethereum nodes are mining."
end

File.open(nodes_filepath,"w") do |f|
  f.write(MyConfig::FULLNODES.to_json)
end
