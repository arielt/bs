module BS
  module Sandbox
    class Policy

      USER = "sandbox"

      def initialize(sb_name)
        @rootfs = "/var/lib/lxc/#{sb_name}/rootfs/"
        @policy = [
          {:type => 'hard', :item => 'nproc',  :value => BS::Config.params['sandbox']['nproc'].to_i},
          {:type => 'hard', :item => 'nofile', :value => BS::Config.params['sandbox']['nofile'].to_i}
        ]
      end

      def conf_array
        output = []
        @policy.each do |v|
          output << "#{USER}\t#{v[:type]}\t#{v[:item]}\t#{v[:value]}"
        end
        output
      end

      # enable resource control inside container
      def enable_rc
        system("sudo cp /opt/bs/files/su #{@rootfs}etc/pam.d/")
        system("echo \"session    required   pam_limits.so\" | sudo tee -a #{@rootfs}etc/pam.d/su > /dev/null")
      end

      # enable resource control inside container
      def disable_rc
        system("sudo cp /opt/bs/files/su #{@rootfs}etc/pam.d/")
      end

      def apply
        enable_rc
        system("sudo cp /opt/bs/files/limits.conf #{@rootfs}etc/security/")
        conf_array.each do |v|
          system("echo \"#{v}\" | sudo tee -a #{@rootfs}etc/security/limits.conf > /dev/null")
        end
      end

    end
  end
end

