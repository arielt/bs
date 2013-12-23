#
# requirements: 
# init with one existing policies
#   - default
#
# default policy should be comprehensive
# thresholds should be defined - hardcoded
# default policy defines minimal threshold as well
#
module Sandbox
    class Policy

        USER = "sandbox"

        def initialize(sb_name, type = :default)

            @rootfs = "/var/lib/lxc/#{sb_name}/rootfs/"
            default_policy = YAML.load_file("lib/lxc/fs/etc/security/default_policy.yml")          

            case(type)

            when :default
                @policy = default_policy
            # for other types, the policy should be merged with default
            else
                raise "Unknown policy type"

            end

        end

        def conf_array
            output = []
            @policy.each do |k,v|
                v.each do |entry|
                    str = "#{USER}\t#{entry["type"]}\t#{k}\t#{entry["value"]}"
                    output << str
                end
            end
            output
        end

        # resource control inside container
        def enable_rc
            system("sudo cp lib/lxc/fs/etc/pam.d/su #{@rootfs}etc/pam.d/")
            system("echo \"session    required   pam_limits.so\" | sudo tee -a #{@rootfs}etc/pam.d/su > /dev/null")
        end

        def disable_rc
            system("sudo cp lib/lxc/fs/etc/pam.d/su #{@rootfs}etc/pam.d/")
        end

        def apply
            enable_rc
            system("sudo cp lib/lxc/fs/etc/security/limits.conf #{@rootfs}etc/security/")
            conf_array.each do |v|
                system("echo \"#{v}\" | sudo tee -a #{@rootfs}etc/security/limits.conf > /dev/null")
            end
        end

    end
end

