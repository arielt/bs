require 'fileutils'
require 'timeout'
require 'bs/helpers'

module BS
  module Task

    DEFAULT_TIME_LIMIT = 30

    # subsystems
    C          = 0
    CPP        = 10
    RUBY       = 20
    JAVASCRIPT = 30

    VERIFICATOR = {
      C           => "c.rb",
      CPP         => "cpp.rb",
      RUBY        => "ruby.rb",
      JAVASCRIPT  => "jvs.rb"
    }

    class << self

      def list
        puts "Task list:"
        puts "-------------------------------------"
        system("ls #{BS::Config::TASK_DIR}")
        puts "-------------------------------------"
      end

      def add(params)
        system("cd  #{BS::Config::TASK_DIR} && git clone #{params[0]}")
      end

      def del(params)
        system("rm -rf #{BS::Config::TASK_DIR}/#{params[0]}")
      end

      def verify(params)
        # TODO: define constants
        sb_name  = 'sb0'
        rootfs   = "/var/lib/lxc/#{sb_name}/rootfs/"
        ver_path = rootfs + "#{BS::Config::VER_DST_DIR}/"

        # TODO: port internal policy
        # Policy.new(sb_name).apply

        FileUtils.rm_rf(ver_path + ".")
        FileUtils.rm_rf("#{BS::Config::LOG_DIR}/execute")
        FileUtils.cp(params[1], "#{ver_path}solution.cpp")
        FileUtils.cp("#{BS::Config::TASK_DIR}/#{params[0]}/verification.cpp", "#{ver_path}verification.cpp")
        FileUtils.cp("#{BS::Config::VER_SRC_DIR}/#{VERIFICATOR[CPP]}", ver_path)

        puts "Verification started...".green
        rv = false
        begin
          Timeout.timeout(DEFAULT_TIME_LIMIT) do
            command = "sudo lxc-execute -n #{sb_name} -o #{BS::Config::LOG_DIR}/execute -l NOTICE #{BS::Config::VER_DST_DIR}/#{VERIFICATOR[CPP]}" 
            rv = system(command)
          end
          system("tail -n 25 #{ver_path}log.txt > #{ver_path}trunc_log.txt")
          message = File.read("#{ver_path}trunc_log.txt")            
        rescue Timeout::Error
          message =  "Oops... It takes too long, we can't verify this"
          system("sudo lxc-stop -n #{sb_name} &")
          sleep(1)
          init_pid = fetch_init_pid(sb_name)
          system("sudo kill -9 #{init_pid}")
          puts "Killed #{init_pid}"
        end

        puts message

        if rv
          puts "Success".green
        else
          puts "Failure".red
        end

       end
    end
  end
end

