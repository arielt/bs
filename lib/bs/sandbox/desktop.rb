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

        extend self

        def perform(params)
          rootfs   = "/var/lib/lxc/#{DESKTOP_SB}/rootfs/"
          ver_path = rootfs + "#{VER_DST_DIR}/"

          task_timeout = BS::Task.params(params[0])['verification_timeout'] 

          BS::Sandbox::Policy.new(DESKTOP_SB).apply

          FileUtils.rm_rf(ver_path + ".")
          FileUtils.rm_rf("#{LOG_DIR}/execute")
          FileUtils.cp(params[1], "#{ver_path}solution.cpp")
          FileUtils.cp("#{TASK_DIR}/#{params[0]}/verification.cpp", "#{ver_path}verification.cpp")
          FileUtils.cp("files/#{VERIFICATOR[CPP]}", ver_path)

          puts "Verification started...".green
          rv = false
          begin
            Timeout.timeout(task_timeout || DEFAULT_TIME_LIMIT) do
              command = "sudo lxc-execute -n #{DESKTOP_SB} -o #{LOG_DIR}/execute -l NOTICE #{VER_DST_DIR}/#{VERIFICATOR[CPP]}" 
              rv = system(command)
            end
            system("tail -n 25 #{ver_path}log.txt > #{ver_path}trunc_log.txt")
            message = File.read("#{ver_path}trunc_log.txt")            
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

