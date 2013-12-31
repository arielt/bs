require 'bs/lxc'
require 'bs/lxc/container'
require 'bs/node/local'

# Desktop computational node
# No monitoring support, single container

module BS
  module Node
    class Desktop < BS::Node::Local

      CONF_FILE = "#{BS::Config::CONF_DIR}/node.yml"

      def print_status
        puts "\nSandbox:"
        if File.exists?(CONF_FILE)
          puts "Memory limit: \t\t\t#{@conf[:sandboxes][0][:mem]} Kb"
          puts "Swap limit: \t\t\t#{@conf[:sandboxes][0][:mem]*2} Kb"
          puts "Disk space limit: \t\t#{@conf[:sandboxes][0][:hd]} Kb"
          puts "Max number of processes: \t#{BS::Config.params['sandbox']['nproc']}"
          puts "Max number of open files: \t#{BS::Config.params['sandbox']['nofile']}"
        else
          puts "Not created. You may want to run \'sudo bs make\' to fix that".red
        end
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
          :name => BS::Config::DESKTOP_SB, 
          :mem  => BS::Config.params['sandbox']['memory'].to_i,
          :cpu =>  @conf[:cpu],
          :hd =>   BS::Config.params['sandbox']['disk_space'].to_i
        })
      end

      # create node, no dispatching
      def create
        @conf[:sandboxes].each do |v|
          create_sandbox(v)
        end
        save_conf CONF_FILE
      end

      # destroy node, no dispatching
      def destroy
        @conf[:sandboxes].each do |v|
          destroy_sandbox(v)
        end
        system("rm #{CONF_FILE}")
      end

      def initialize
        init_conf CONF_FILE
        set_node_conf
        set_sb_conf
      end

    end
  end
end

