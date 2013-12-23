require 'bs/helpers'
require 'bs/lxc'

module BS
  module Node
    class Local

        include Node

        attr_accessor :conf
        attr_accessor :unused_memory
        attr_accessor :unused_hd

        # create basic configuration if there is no existing one
        def create_conf
            @conf[:hostname] = Socket.gethostname

            # memory in Kb
            m = MemInfo.new
            @conf[:mem] = m.memtotal

            @conf[:cpu] = Sys::CPU.processors.count

            # Disk space in Kb
            stat = Sys::Filesystem.stat("/")
            @conf[:hd] =  stat.block_size * stat.blocks_available / 1024

            # resources allocated for sandboxes' sake
            @conf[:mem_sb]  = (@conf[:mem] * 0.8).round
            @conf[:hd_sb]   = (@conf[:hd] * 0.8).round
            @conf[:cpu_sb]  = @conf[:cpu]

            @conf[:sandboxes] = []
            @conf[:sandboxes].push({name: "sb0", type: "first"})

            save
        end

        # save configuration
        def save
            file = File.open(CONF_FILE, 'w')
            YAML.dump(@conf, file)
            file.close
        end

        def remove_container(container)
            LXC.use_sudo = true
            container.sb_destroy_hd
            container.destroy(true)
            LXC.use_sudo = false
        end

        def set_constraints(sandbox)
            types = Node::TYPES[sandbox[:type].to_sym] 
            lxc = LXC.container(sandbox[:name])
            lxc.sb_mem_limit = types[:mem]
            lxc.sb_mem_swap_limit = types[:swap]
            lxc.sb_cpu_share = types[:cpu_share]
            lxc.sb_destroy_hd
            lxc.sb_create_hd(types[:hd])
            lxc.enable_network
            configure(sandbox[:name])
            lxc.disable_network
        end

        def enable_network(name)
            LXC.container(name).enable_network
        end

        def disable_network(name)
            LXC.container(name).disable_network
        end

        # check there is no unused resources in current configuration
        def is_sane?
            # sum same parameter of each sand box.
            # if no sum hits the maximum - node is insane
            mem_sum = 0
            hd_sum = 0
            unless @conf[:sandboxes].nil?
                @conf[:sandboxes].each do |v|
                    mem_sum += Node::TYPES[v[:type].to_sym][:mem]
                    hd_sum += Node::TYPES[v[:type].to_sym][:hd]
                end
            end

            @unused_memory = @conf[:mem_sb] - mem_sum
            @unused_hd = @conf[:hd_sb] - hd_sum

            if @unused_memory != 0 && @unused_hd != 0
                puts "This node is insane"
                puts "Unused memory: #{@unused_memory}K"
                puts "Unused HD: #{@unused_hd}K"
                return false
            end
            puts "This node is sane"
            true
        end

        # perform internal configuration with puppet
        def configure(sb_name)
            puts "Configure!!!!"
            rootfs = "/var/lib/lxc/#{sb_name}/rootfs"
            system("sudo /usr/sbin/chroot #{rootfs} /bin/bash -c \"apt-get update\"")
            system("sudo /usr/sbin/chroot #{rootfs} apt-get -q -y install puppet lxc make build-essential libboost-test-dev")
            system("sudo cp /opt/bs/conf/lxc-insider.pp #{rootfs}/etc/puppet/manifests/lxc-insider.pp")
            system("sudo lxc-execute -n #{sb_name} puppet apply /etc/puppet/manifests/lxc-insider.pp")
        end

        # stop monit services and monit itself
        def stop_monit
            system("sudo monit stop all")
            sleep(10)
            system("sudo service monit stop")
            sleep(10)
        end

        def start_monit            
            system("sudo service monit start")
            sleep(10)
            system("sudo monit start all")
            sleep(60)
        end

        def create_sandbox(v)
            name = v[:name]
            type = v[:type]
            template = File.read("puppet/modules/bs/templates/monit-resque.erb")
  
            if name == "sb0"
                system("sudo /usr/bin/lxc-create -n #{name} -t ubuntu -- -r oneiric")
                set_constraints(v)
            else
                system("sudo lxc-clone -o sb0 -n #{name}")
            end

            set_constraints(v)

            # update monit configuration file
            file = File.open("/opt/bs/tmp/resque_worker_#{name}","w")
            file << ERB.new(template).result(binding)
            file.close
            system("sudo cp /opt/bs/tmp/resque_worker_#{name} /etc/monit/conf.d/resque_worker_#{name}")
            FileUtils.rm("/opt/bs/tmp/resque_worker_#{name}")
        end

        # 
        # builds all container
        # mounts disks
        #
        def create
            @conf[:sandboxes].each do |v|
                create_sandbox(v)
            end
            start_monit
        end

        def destroy
            stop_monit
            LXC.containers.each do |v|
                remove_container(v)
            end
            system("sudo rm -f /etc/monit/conf.d/*")
            system("sudo rm -f /opt/bs/log/*")
        end

        # check if configuration corresponds to runtime
        def is_sound?
            @conf[:sandboxes].each do |v|
                name = v[:name]
                lxc = LXC.container(name)
                return false unless lxc.exists?
            end
            return true
        end

        def initialize
            if File.exists?(CONF_FILE)
                @conf = YAML.load(File.read(CONF_FILE))
                @conf.recursively_symbolize_keys!
            else
                @conf = {}
                create_conf
            end
        end
    end
  end
end
