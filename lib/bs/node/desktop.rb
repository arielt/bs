require 'bs/lxc'
require 'bs/node/local'

# Desktop computational node
# No monitoring support, single container

module BS
  module Node
    class Desktop < BS::Node::Local

      CONF_FILE = "#{BS::Config::CONF_DIR}/node.yml"

      def status(params)
        puts "Host name: \t\t#{@conf[:hostname]}"
        puts "Available memory: \t#{@conf[:mem]}"
        puts "Number of CPUs: \t#{@conf[:cpu]}"
      end

      def set_sb_conf
        # resources allocated for sandbox
        @conf[:mem_sb] = BS::Config.get['sandbox']['memory']
        @conf[:hd_sb]  = BS::Config.get['sandbox']['disk_space']
        @conf[:cpu_sb] = @conf[:cpu]

        @conf[:sandboxes] = []
        @conf[:sandboxes].push({name: "sb0", type: "first"})
      end

      def initialize
        init_conf CONF_FILE
        set_node_conf
        set_sb_conf
        save_conf CONF_FILE
      end

    end
  end
end

