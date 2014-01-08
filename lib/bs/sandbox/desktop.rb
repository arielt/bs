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

        ROOTFS = "/var/lib/lxc/#{DESKTOP_SB}/rootfs/"
        VER_PATH = ROOTFS + "#{VER_DST_DIR}/"
        LOCK_FILE = "/var/lib/lxc/#{DESKTOP_SB}/.lock"

        extend self

        def lock()
          return false if File.exists?(LOCK_FILE)
          FileUtils.touch(LOCK_FILE)
          return true
        end

        def unlock()
          FileUtils.rm_rf(LOCK_FILE)
        end

        def perform(params)
          task_timeout = BS::Task.params(params[0])['verification_timeout'] 

          BS::Sandbox::Policy.new(DESKTOP_SB).apply

          FileUtils.rm_rf(VER_PATH + ".")
          FileUtils.rm_rf("#{LOG_DIR}/execute")
          FileUtils.cp(params[1], "#{VER_PATH}solution.cpp")
          FileUtils.cp("#{TASK_DIR}/#{params[0]}/verification.cpp", "#{VER_PATH}verification.cpp")
          FileUtils.cp("files/#{VERIFICATOR[CPP]}", VER_PATH)

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
        end


    end
  end
end

