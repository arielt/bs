require 'bs/lxc'
require 'bs/lxc/container'
require 'bs/node/local'
require 'pp'

# Desktop computational node
# No monitoring support, single container

module BS
  module Node
    class Desktop < BS::Node::Local

      CONF_FILE = "#{BS::Config::CONF_DIR}/node.yml"

      def print_status(params)
        puts "Node:"
        puts "Host name: \t\t#{@conf[:hostname]}"
        puts "Available memory: \t#{@conf[:mem]} Kb"
        puts "Number of CPUs: \t#{@conf[:cpu]}"
        puts "Disk space: \t\t#{@conf[:hd]} Kb"
        puts "\nSandbox:"
        puts "Available memory: \t#{@conf[:sandboxes][0][:mem]} Kb"
        puts "Number of CPUs: \t#{@conf[:sandboxes][0][:cpu]}"
        puts "Disk space: \t\t#{@conf[:sandboxes][0][:hd]} Kb"
      end

      def set_constraints(sandbox)
        puts "BS: setting constraints".green
        lxc = BS::LXC::Container.new(sandbox[:name])
        lxc.set_knob(:mem,  "#{sandbox[:mem]}K")
        lxc.set_knob(:swap, "#{sandbox[:mem]*2}K")
        lxc.destroy_hd
        lxc.create_hd(sandbox[:hd])
        lxc.enable_network
        lxc.save
        configure(sandbox[:name])
        puts "BS: disabling network".green
        lxc.disable_network
        lxc.save
        puts "BS: done with constraints".green
      end         

      def set_sb_conf
        # resources allocated for sandbox
        @conf[:sandboxes] = []
        @conf[:sandboxes].push({
          :name => 'sb0', 
          :mem  => BS::Config.get['sandbox']['memory'].to_i,
          :cpu =>  @conf[:cpu],
          :hd =>   BS::Config.get['sandbox']['disk_space'].to_i
        })
      end

      # create node, no dispatching
      def create
        @conf[:sandboxes].each do |v|
          create_sandbox(v)
        end
      end

      # destroy node, no dispatching
      def destroy
        @conf[:sandboxes].each do |v|
          destroy_sandbox(v)
        end
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

