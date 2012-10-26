#!/usr/bin/env ruby

require 'rubygems'
require 'subcommand'
require 'puppetsdb'
require 'pp'

include Subcommands

module PuppetSDB
  class CLI
    class << self
      def run
        options = {}
        global_cmd = global_options do |opts|
               opts.banner = "Usage: ", File.basename(__FILE__), " [subcommand [options]]"
               opts.description = "CLI for Puppet ENC on Amazon's SimpleDB"
               opts.separator ""
               opts.separator "Global options are:"
               opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
                 options[:verbose] = v
               end
        end

        list_cmd = command :list do |opts|
               opts.banner = "Usage: list [options]"
               opts.description = "List all nodes in the ENC"
        end
        get_cmd = command :get do |opts|
               opts.banner = "Usage: get [options] nodename"
               opts.description = "Get YAML data for the node"
        end

        set_cmd = command :set do |opts|
               opts.banner = "Usage: set [options] nodename [yaml_file]"
               opts.description = "Set YAML data for the node. If yaml_file is not specified, the yaml data is read from STDIN."
        end
        delete_cmd = command :delete do |opts|
               opts.banner = "Usage: delete [options] nodename [...]"
               opts.description = "Delete the ENC record(s)"
               opts.on("-f", "--force", "Do not prompt for confirmation") do |v|
                 options[:delete_force] = v
               end
        end

        cmd = opt_parse
        puppet_enc = PuppetSDB.new
        case cmd
          when "list"
            strfmt = '%-30s %s'
            puts strfmt.%(['Node','Time Modified'])
            puts strfmt.%(['-'*30,'-'*30])
            puppet_enc.list_items_detailed.each do |node|
              puts strfmt.%([node[0],node[1]['Time Modified']])
            end
          when "get"
            (puts get_cmd.call.help; exit 1) if ARGV.empty?
            yaml = puppet_enc.get_node_yaml(ARGV[0])
            puts yaml unless yaml.empty?
          when "set"
            (puts set_cmd.call.help; exit 1) if ARGV.empty?
            nodename = ARGV.shift
            if ARGV.empty?
              yaml_data = $stdin.read
            else
              yaml_file = ARGV.shift
              yaml_data = File.new(yaml_file).read
            end
            puppet_enc.write_node_data(nodename, yaml_data)
          when "delete"
            (puts delete_cmd.call.help; exit 1) if ARGV.empty?
            unless options[:delete_force]
              print "Are you sure you want to delete this node? (yes/[no]) "
              answer = $stdin.gets.chomp
              accepted_confirms = ['y','yes']
              (puts "Cancelled..."; exit) unless accepted_confirms.include?(answer.downcase)
            end
            ARGV.each { |node| puppet_enc.delete_item(node) }
        end
      end
    end
  end
end
