#!/usr/bin/env ruby

require 'rubygems'
require 'subcommand'
require 'puppetsdb'

include Subcommands

module PuppetSDB
  class CLI
    class << self
      COL_WIDTH = 40
      def ask_confirm(question)
        print "Are you sure you want to delete this node? (yes/[no]) "
        answer = $stdin.gets.chomp
        accepted_confirms = ['y','yes']
        accepted_confirms.include?(answer.downcase)
      end

      def run
        options = {}
        global_cmd = global_options do |opts|
          opts.banner = "Usage: ", $PROGRAM_NAME, " [subcommand [options]]"
          opts.description = "CLI for Puppet ENC on Amazon's SimpleDB"
          opts.separator ""
          opts.separator "Global options are:"
          opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
            options[:verbose] = v
          end
        end

        list_cmd = command :list do |opts|
          opts.banner = "Usage: list"
          opts.description = "List all nodes in the ENC"
        end
        listdomains_cmd = command :listdomains do |opts|
          opts.banner = "Usage: listdomains"
          opts.description = "List all SimpleDB domains in the AWS account"
        end
        createdomain_cmd = command :createdomain do |opts|
          opts.banner = "Usage: createdomain domain_name"
          opts.description = "Create a SimpleDB domain"
        end
        deletedomain_cmd = command :deletedomain do |opts|
          opts.banner = "Usage: deletedomain [options] domain_name"
          opts.description = "Delete a SimpleDB domain"
          opts.on("-f", "--force", "Do not prompt for confirmation") do |v|
            options[:deletedomain_force] = v
          end
          opts.on("-i", "--items", "Delete the domain and all associated items") do |v|
            options[:deletedomain_items] = v
          end
        end
        get_cmd = command :get do |opts|
          opts.banner = "Usage: get [options] nodename"
          opts.description = "Get YAML data for a node"
        end
        set_cmd = command :set do |opts|
          opts.banner = "Usage: set [options] nodename [yaml_file]"
          opts.description = "Set YAML data for a node. If yaml_file is not specified, the yaml data is read from STDIN."
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
            strfmt = "%-#{COL_WIDTH.to_s}s %s"
            puts strfmt.%(['Node','Time Modified'])
            puts strfmt.%(['-'*COL_WIDTH,'-'*COL_WIDTH])
            puppet_enc.list_items_detailed.each do |node|
              puts strfmt.%([node[0],node[1]['Time Modified']])
            end
          when "listdomains"
            strfmt = "%s"
            puts strfmt.%(['Domain'])
            puts strfmt.%(['-'*COL_WIDTH])
            puppet_enc.list_domains.each { |domain| puts strfmt.%([domain]) }
          when "createdomain"
            domain_name = ARGV.shift
            puppet_enc.create_domain(domain_name)
            puts "Domain create successfully"
          when "deletedomain"
            domain_name = ARGV.shift
            unless options[:deletedomain_force]
              (puts "Cancelled..."; exit 0) unless ask_confirm("Are you sure you want to delete this domain? (yes/[no]) ")
            end
            if options[:deletedomain_items]
              puppet_enc.delete_domain(domain_name, with_items=true)
            else
              puppet_enc.delete_domain(domain_name, with_items=false)
            end
            puts "Domain deleted successfully"
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
              (puts "Cancelled..."; exit 0) unless ask_confirm("Are you sure you want to delete this node? (yes/[no]) ")
            end
            ARGV.each { |node| puppet_enc.delete_item(node) }
        end
        (add_subcommand_help; puts global_cmd.help; exit 1) unless cmd
      end
    end
  end
end
