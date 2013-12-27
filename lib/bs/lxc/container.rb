require 'fileutils'

module BS
  module LXC
    class Container


      def initialize(name)
        @name = name
        @conf_file_name = "/var/lib/lxc/#{@name}/config"
        @tmp_file_name = "/opt/bs/tmp/#{@name}_config"
        @conf = File.read(@conf_file_name)
        @lines = @conf.split("\n")
      end

      def set_knob(key, value)
        knob = BS::LXC::KNOBS[key]
        raise "Knob #{key} doesn't exist" unless knob

        if @conf.include?(knob)
          @lines.each do |v|
            if v[0,1] != '#'
              values = v.split("=")
              if values[0] && values[0].include?(knob)
                values[1] = value
                v.replace values.join("=")
              end
            end
          end
        else
          @lines.push("#{knob} = #{value}")
          @conf = @lines.join("\n")
        end
      end

      def save
        File.open(@conf_file_name, "w") do |f|
          f.write(@lines.flatten.join("\n"))
        end
      end

      # attaches / detaches virtual hd to /home/sandbox of the container
      def create_hd(size)
        hd_file = "/var/lib/lxc/#{@name}/sandbox_hd" 
        sandbox = "/var/lib/lxc/#{@name}/rootfs/home/sandbox"
        verification = "#{sandbox}/verification"

        raise "Failed to dump HD" unless system("sudo dd if=/dev/zero of=#{hd_file} bs=#{size}KB count=1 && sudo mkfs.ext3 -F #{hd_file}")
        raise "Failed to create sandbox folder" unless system("sudo mkdir -p #{sandbox}")
        raise "Failed to mount HD" unless system("sudo mount -o loop #{hd_file} #{sandbox}")

        # TODO: support root user
        raise "Failed to change owner for sandbox" unless system("sudo chown #{ENV['SUDO_USER']} #{sandbox}")
        #raise "Failed to change group for sandbox" unless system("sudo chgrp #{SANDBOX_UID} #{sandbox}")

        raise "Failed to create verification folder" unless system("sudo mkdir -p #{verification}")
        raise "Failed to change owner for verification" unless system("sudo chown #{ENV['SUDO_USER']} #{verification}")
        #raise "Failed to change group for verification" unless system("sudo chgrp #{BS_UID} #{verification}")
        raise "Failed to chmod for verification" unless system("sudo chmod 771 #{verification}")
      end

      def destroy_hd
        hd_file = "/var/lib/lxc/#{@name}/sandbox_hd" 
        rv = system("sudo umount #{hd_file}")
        puts "WARNING: wasn't able to unmount HD #{hd_file}".red unless rv
        system("sudo rm #{hd_file}")
      end

      def enable_network
        set_knob :network_type, "veth"
      end

      def disable_network
        set_knob :network_type, "empty"
      end

    end
  end
end
