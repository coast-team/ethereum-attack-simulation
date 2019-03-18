#!/usr/bin/ruby
require_relative 'utils'
require 'json'
require 'distem'
require 'optparse'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "This script stops some miners.\n\nUsage: test.rb -i FILE_PATH -n NUMBER"

  opts.on("-i", "--input_file FILE_PATH", String, "The path of the file containing the info of the deployed nodes") do |nodes_file_path|
    options[:nodes_file_path] = nodes_file_path
  end

  opts.on("-n", "--nodes_nb NUMBER", OptionParser::DecimalInteger, "The number of nodes that will continue to mine (Must be less than the total number of nodes)") do |on_nodes_nb|
    options[:on_nodes_nb] = on_nodes_nb
  end

end
optparse.parse!

on_nodes_nb = options[:on_nodes_nb]
puts on_nodes_nb
nodes_filepath = options[:nodes_file_path]
puts nodes_filepath

raise OptionParser::MissingArgument, "The number of nodes that  will continue to mine must be specified.\n\n#{optparse.help()}" if on_nodes_nb.nil?
raise OptionParser::MissingArgument, "The path of the file must be specified.\n\n#{optparse.help()}" if nodes_filepath.nil?
raise OptionParser::InvalidArgument, "This path '#{nodes_filepath}' is not defined (Does it exist and refer to a regular file ?)" unless File.file?(nodes_filepath)

fullnodes = JSON.parse(File.read(nodes_filepath))
total_number = fullnodes.size()

raise OptionParser::InvalidArgument, "The number of nodes that will continue to mine must be less than the total number of nodes.\n\n#{optparse.help()}" if on_nodes_nb >= total_number

Distem.client do |cl|
  fullnodes.sample(total_number - on_nodes_nb).each do |node_to_stop|
    cl.vnode_execute(node_to_stop['name'], %Q[geth --exec "miner.stop()" attach "http://#{node_to_stop['address']}:#{node_to_stop['rpc_port']}"])
    node_to_stop['mining'] = false
  end
end

File.open(nodes_filepath,"w") do |f|
  f.write(fullnodes.to_json)
end
