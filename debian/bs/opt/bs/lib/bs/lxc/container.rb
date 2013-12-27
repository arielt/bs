module LXC
  class Container
    attr_accessor :name
    attr_reader   :state
    attr_reader   :pid
    attr_accessor :conf

    # Initialize a new LXC::Container instance
    # @param [String] name container name
    # @return [LXC::Container] container instance
    def initialize(name)
      @name = name
      puts "tear"
        @conf_file_name = "/var/lib/lxc/#{@name}/config"
        @tmp_file_name = "#{BS::Config::CONF_DIR}/tmp/#{@name}_config"
        puts @conf_file_name
        puts @conf
        @conf = Configuration.load_file(@conf_file_name)
    end

    # Get container attributes hash
    # @return [Hash]
    def to_hash
      status
      {'name' => name, 'state' => state, 'pid' => pid}
    end

    # Get current status of container
    # @return [Hash] hash with :state and :pid attributes
    def status
      str    = LXC.run('info', '-n', name)
      @state = str.scan(/^state:\s+([\w]+)$/).flatten.first
      @pid   = str.scan(/^pid:\s+(-?[\d]+)$/).flatten.first
      {:state => @state, :pid => @pid}
    end

    # Check if container exists
    # @return [Boolean]
    def exists?
      LXC.run('ls').split("\n").uniq.include?(name)
    end

    # Check if container is running
    # @return [Boolean]
    def running?
      status[:state] == 'RUNNING'
    end

    # Check if container is frozen
    # @return [Boolean]
    def frozen?
      status[:state] == 'FROZEN'
    end

    # Start container
    # @return [Hash] container status hash
    def start
      LXC.run('start', '-d', '-n', name)
      status
    end

    # Stop container
    # @return [Hash] container status hash
    def stop
      LXC.run('stop', '-n', name)
      status
    end

    # Restart container
    # @return [Hash] container status hash
    def restart
      stop
      start
    end

    # Freeze container
    # @return [Hash] container status hash
    def freeze
      LXC.run('freeze', '-n', name)
      status
    end

    # Unfreeze container
    # @return [Hash] container status hash
    def unfreeze
      LXC.run('unfreeze', '-n', name)
      status
    end

    # Wait for container to change status
    # @param [String] state state name
    def wait(state)
      if !LXC::Shell.valid_state?(state)
        raise ArgumentError, "Invalid container state: #{state}"
      end
      LXC.run('wait', '-n', name, '-s', state)
    end

    # Get container memory usage in bytes
    # @return [Integer]
    def memory_usage
      LXC.run('cgroup', '-n', name, 'memory.usage_in_bytes').strip.to_i
    end

    # Get container memory limit in bytes
    # @return [Integer]
    def memory_limit
      LXC.run('cgroup', '-n', name, 'memory.limit_in_bytes').strip.to_i
    end

    # Get container processes
    # @return [Array] list of all processes
    def processes
      raise ContainerError, "Container is not running" if !running?
      str = LXC.run('ps', '-n', name, '--', '-eo pid,user,%cpu,%mem,args').strip
      lines = str.split("\n") ; lines.delete_at(0)
      lines.map { |l| parse_process_line(l) }
    end

    # Create a new container
    # @param [String] path path to container config file or [Hash] options
    # @return [Boolean]
    def create(path)
      raise ContainerError, "Container already exists." if exists?
      if path.is_a?(Hash)
        args = "-n #{name}"

        if !!path[:config_file]
          unless File.exists?(path[:config_file])
            raise ArgumentError, "File #{path[:config_file]} does not exist."
          end
          args += " -f #{path[:config_file]}"
        end

        if !!path[:template]
          template_path = "/usr/lib/lxc/templates/lxc-#{path[:template]}"
          unless File.exists?(template_path)
            raise ArgumentError, "Template #{path[:template]} does not exist."
          end
          args += " -t #{path[:template]}"
        end

        args += " -B #{path[:backingstore]}" if !!path[:backingstore]
        args += " -- #{path[:template_options].join(' ')}".strip if !!path[:template_options]

        LXC.run('create', args)
        exists?
      else
        raise ArgumentError, "File #{path} does not exist." unless File.exists?(path)
        LXC.run('create', '-n', name, '-f', path)
        exists?
      end
    end

    # Clone to a new container from self
    # @param [String] target name of new container
    # @return [LXC::Container] new container instance
    def clone_to(target)
      raise ContainerError, "Container does not exist." unless exists?
      if self.class.new(target).exists?
        raise ContainerError, "New container already exists."
      end

      LXC.run('clone', '-o', name, '-n', target)
      self.class.new target
    end

    # Create a new container from an existing container
    # @param [String] source name of existing container
    # @return [Boolean]
    def clone_from(source)
      raise ContainerError, "Container already exists." if exists?
      unless self.class.new(source).exists?
        raise ContainerError, "Source container does not exist."
      end

      LXC.run('clone', '-o', source, '-n', name)
      exists?
    end

    # Destroy the container 
    # @param [Boolean] force force destruction
    # @return [Boolean] true if container was destroyed
    #
    # If container is running and `force` parameter is true
    # it will be stopped first. Otherwise it will raise exception.
    #
    def destroy(force=false)
      raise ContainerError, "Container does not exist." unless exists?
      if running?
        if force
          # This will force stop and destroy container automatically
          LXC.run('destroy', '-n', '-f', name)
        else
          raise ContainerError, "Container is running. Stop it first or use force=true"
        end
      else
        LXC.run('destroy', '-n', name)
      end  
      !exists?
    end

    # save configuration in root owned folder
    def save_configuration
      FileUtils.mkdir_p("/tmp/#{@name}")
      @conf.save_to_file(@tmp_file_name)
      system("sudo cp #{@tmp_file_name} #{@conf_file_name}")
    end

    # get memory limit
    def sb_mem_limit()
      @conf["lxc.cgroup.memory.limit_in_bytes"].split("K")[0].to_i
    end

    # sets memory limit in kylobites
    def sb_mem_limit=(memlimit)
      @conf["lxc.cgroup.memory.limit_in_bytes"] = memlimit.to_s + "K"
      save_configuration
    end

    # get / set CPU priority. the default is 1024
    def sb_cpu_share()
      @conf["lxc.cgroup.cpu.shares"].nil? ? 1024 :  @conf["lxc.cgroup.cpu.shares"].to_i
    end 

    def sb_cpu_share=(value)
      @conf["lxc.cgroup.cpu.shares"] = value
      save_configuration
    end

    # get / set memory swap limit
    def sb_mem_swap_limit()
      return @conf["lxc.cgroup.memory.memsw.limit_in_bytes"].split("K")[0].to_i if @conf["lxc.cgroup.memory.memsw.limit_in_bytes"]
      return nil
    end

    def sb_mem_swap_limit=(swap_limit)
      @conf["lxc.cgroup.memory.memsw.limit_in_bytes"] = swap_limit.to_s + "K"
      save_configuration
    end

    # attaches / detaches virtual hd to /home/sandbox of the container
    def sb_create_hd(size)
      hd_file = "/var/lib/lxc/#{@name}/sandbox_hd" 
      sandbox = "/var/lib/lxc/#{@name}/rootfs/home/sandbox"
      verification = "#{sandbox}/verification"

      puts "Creating HD..."
      raise "Failed to dump HD" unless system("sudo dd if=/dev/zero of=#{hd_file} bs=#{size}KB count=1 && sudo mkfs.ext3 -F #{hd_file}")
      raise "Failed to create sandbox folder" unless system("sudo mkdir -p #{sandbox}")
      raise "Failed to mount HD" unless system("sudo mount -o loop #{hd_file} #{sandbox}")

      #raise "Failed to change owner for sandbox" unless system("sudo chown #{SANDBOX_UID} #{sandbox}")
      #raise "Failed to change group for sandbox" unless system("sudo chgrp #{SANDBOX_UID} #{sandbox}")

      raise "Failed to create verification folder" unless system("sudo mkdir -p #{verification}")
      #raise "Failed to change owner for verification" unless system("sudo chown #{SANDBOX_UID} #{verification}")
      #raise "Failed to change group for verification" unless system("sudo chgrp #{BS_UID} #{verification}")
      raise "Failed to chmod for verification" unless system("sudo chmod 771 #{verification}")
    end

    def sb_destroy_hd
      hd_file = "/var/lib/lxc/#{name}/sandbox_hd" 
      rv = system("sudo umount #{hd_file}")
      puts "WARNING: wasn't able to unmount HD #{hd_file}" unless rv
      system("sudo rm #{hd_file}")
    end

    def enable_network
        @conf["lxc.network.type"] = "veth"
        save_configuration
    end

    def disable_network
        @conf["lxc.network.type"] = "empty"
        save_configuration
    end

    private

    def parse_process_line(line)
      chunks = line.split(' ')
      chunks.delete_at(0)

      pid     = chunks.shift
      user    = chunks.shift
      cpu     = chunks.shift
      mem     = chunks.shift
      command = chunks.shift
      args    = chunks.join(' ')

      {
        'pid'     => pid,
        'user'    => user,
        'cpu'     => cpu,
        'memory'  => mem,
        'command' => command,
        'args'    => args
      }
    end
  end
end
