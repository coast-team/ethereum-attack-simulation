#!/usr/bin/ruby

module MyConfig
  BOOTNODE_PORT = 30301
  ACCOUNT_ADDRESS_FILE = "/home/lxc/ethereum_files/account_address.txt"
  DATADIR = "/home/lxc/ethereum_files/datadir"
  PASSWORD_FILE = "/home/lxc/password.txt"
  GENESIS_FILE = "/home/lxc/ethereum_files/custom_genesis.json"
  RPC_PORT = 8081
  NODE_PORT = 30308
  RPC_API = "db,eth,net,web3,miner,admin"
  TOTAL_NUMBER = 40
  FULLNODES = []
  GATEWAY  = '10.147.255.254' # Default gateway of Nancy's sites
  # Describing the resources we are working with
  IFNAME = 'if0'
  BOOTNODE = {
    :name => 'bootnode',
    :address => nil
  }

  (1..TOTAL_NUMBER).each do |i|
      fullnode = {
          :name => "fullnode#{i}",
          :address => nil,
          :pid => nil,
          :rpc_port => RPC_PORT,
          :node_port => NODE_PORT,
          :mining => true
      }
      FULLNODES.push(fullnode)
  end

  NODELIST = FULLNODES.clone() # + client_nodes + light_client_nodes
  NODELIST.push(BOOTNODE)

  EXECUTION_TIME = 3600

  ETHSTATS_BACKEND_PATH = "/home/lxc/eth-net-intelligence-api/app.json"
  ETHSTATS_FRONTEND_URL = "vps387426.ovh.net"
end

# Monkey patching

def puts(o)
  super("#{Time.now.strftime('%H:%M:%S')}: #{o}")
end

class String
  def is_integer?
    true if Integer(self) rescue false
  end
end
