require 'fileutils'
require 'timeout'
require 'bs/helpers'
require 'bs/sandbox/core'
require 'bs/sandbox/policy'

include BS::Config
include BS::Sandbox::Core

module BS
  module Sandbox
    module Desktop

      # verification status
      STATUS_OK       = 0
      STATUS_NOK      = 1


      SYSTEM_STATUS = {
        true  => STATUS_OK,
        false => STATUS_NOK 
      }

      ROOTFS = "/var/lib/lxc/#{DESKTOP_SB}/rootfs/"
      VER_PATH = ROOTFS + "#{VER_DST_DIR}/"

      extend self

      def perform(task_name, solution_file)
        task_timeout = BS::Task.params(task_name)['verification_timeout'] 

        BS::Sandbox::Policy.new(DESKTOP_SB).apply

        FileUtils.rm_rf(VER_PATH + ".")
        FileUtils.rm_rf("#{LOG_DIR}/execute")
        FileUtils.cp(solution_file, "#{VER_PATH}solution.cpp")
        FileUtils.cp("#{TASK_DIR}/#{task_name}/verification.cpp", "#{VER_PATH}verification.cpp")
        FileUtils.cp("/opt/bs/files/#{VERIFICATOR[CPP]}", VER_PATH)

        puts "Verification started...".green
        rv = false
        begin
          Timeout.timeout(task_timeout || DEFAULT_TIME_LIMIT) do
            command = "sudo lxc-execute -n #{DESKTOP_SB} -o #{LOG_DIR}/execute -l NOTICE #{VER_DST_DIR}/#{VERIFICATOR[CPP]}" 
            rv = system(command)
          end
          system("tail -n 25 #{VER_PATH}log.txt > #{VER_PATH}trunc_log.txt")
          message = File.read("#{VER_PATH}trunc_log.txt")            
        rescue Timeout::Error
          message =  "Oops... It takes too long, we can't verify this"
          system("sudo lxc-stop -n #{DESKTOP_SB} &")
          sleep(1)
          init_pid = fetch_init_pid("#{LOG_DIR}/execute", DESKTOP_SB)
          system("sudo kill -9 #{init_pid} 2> /dev/null")
        end

        puts message

        if rv
          puts "Success".green
        else
          puts "Failure".red
        end

        # under the session lock
        session = BS::Session.new
        session.config['verified_digest']   = session.config['request_digest']
        session.config['verified_status']   = SYSTEM_STATUS[rv]
        session.config['verified_message']  = message
        session.save_config

        session.unlock()
      end


    end
  end
end

