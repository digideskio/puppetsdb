require 'base64'
require 'rubygems'
require 'aws'
require 'yaml'

module PuppetSDB
  class PuppetSDB
    attr_accessor :simpledb, :domain
     
    def initialize(domain=nil)
      cfg_file_paths = ['/etc/puppetsdb/config.yml']
      if ENV['HOME']
        cfg_file_paths << '~/.puppetsdb/config.yml'
      else
        cfg_file_paths << '~puppet/.puppetsdb/config.yml'
      end
      conf = {}
      cfg_file_paths.each do |file|
        file = File.expand_path(file)
        next unless File.exists?(file)
        conf.merge!(YAML.load(File.read(file)))
      end

      AWS.config(conf['aws'])
      domain ||= conf['puppetsdb']['domain']
      @simpledb = AWS::SimpleDB.new
      @domain = domain
    end

    def list_domains
      @simpledb.domains.collect(&:name)
    end

    def create_domain(domain_name)
      @simpledb.domains.create(domain_name)
    end

    def delete_domain(domain_name, with_items=false)
      if with_items
        @simpledb.domains[domain_name].delete!
      else
        @simpledb.domains[domain_name].delete
      end
    end

    def list_items
      @simpledb.domains[@domain].items.collect(&:name)
    end

    def list_items_detailed
      attrs = ['Time Modified']
      results = []
      @simpledb.domains[@domain].items.select(*attrs).each do |item_data|
        results << [item_data.name, item_data.attributes]
      end
      results
    end

    def list_item_attrs(item)
      @simpledb.domains[@domain].items[item].attributes.collect(&:name)
    end

    def delete_item(item)
      @simpledb.domains[@domain].items[item].delete
    end

    def get_item_attrs(item)
      @simpledb.domains[@domain].items[item].data.attributes
    end

    def get_node_yaml(item)
      attrs = get_item_attrs(item)
      if attrs.empty?
        ""
      else
        decode_base64(attrs['Node Data'][0])
      end
    end

    def update_item(item, attrs)
      @simpledb.domains[@domain].items[item].attributes.put(
        :replace => attrs)
    end

    def encode_yaml(yaml)
      Base64.encode64(yaml)
    end

    def decode_base64(base64)
      Base64.decode64(base64)
    end

    def get_timestamp_utc
      Time.now.utc
    end

    def construct_attrs(yaml)
      attrs = {'Time Modified' => get_timestamp_utc,
               'Node Data' => encode_yaml(yaml)}
    end

    def validate_yaml(yaml)
      begin
        YAML.load(yaml)
      rescue
        puts "Validation of YAML failed"
        raise
      end
    end

    def write_node_data(nodename, yaml)
      validate_yaml(yaml)
      update_item(nodename, construct_attrs(yaml))
    end
  end
end
