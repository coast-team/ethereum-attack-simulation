#!/usr/bin/ruby
require_relative 'utils'
require 'json'
require 'distem'
require "optparse"

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "This script restart the miners that are currently stopped.\n\nUsage: test.rb -i FILE_PATH"

  opts.on("-i", "--input_file FILE_PATH", String, "The path of the file containing the info of the deployed nodes") do |nodes_file_path|
    options[:nodes_file_path] = nodes_file_path
  end

end
optparse.parse!

nodes_filepath = options[:nodes_file_path]

raise OptionParser::MissingArgument, "The path of the file must be specified.\n\n#{optparse.help()}" if nodes_filepath.nil?
raise OptionParser::InvalidArgument, "This path '#{nodes_filepath}' is not defined (Does it exist and refer to a regular file ?)" unless File.file?(nodes_filepath)

fullnodes = JSON.parse(File.read(nodes_filepath))

Distem.client do |cl|

  fullnodes.each do |node|
    if !node[:mining]
      cl.vnode_execute(node['name'], %Q[geth --exec "miner.start()" attach "http://#{node['address']}:#{node['rpc_port']}"])
      node['mining'] = true
    end
  end
end

File.open(nodes_filepath,"w") do |f|
  f.write(fullnodes.to_json)
end
