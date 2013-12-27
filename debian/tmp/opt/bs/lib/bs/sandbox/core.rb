module Sandbox
    module Core

    # queue should be defined in descendant modules

    SYSTEM_STATUS = {
        true  => STATUS_OK,
        false => STATUS_NOK 
    }

    DEFAULT_TIME_LIMIT = 30

    extend self

    #
    # write the content of the file
    #
    def rewrite_file(file_name, content)
       file = File.open(file_name, 'w')
       file << content
       file.close
    end  

    # get pid from the log file
    def fetch_init_pid(sb_name)
        file = File.read("/var/log/lxc/#{sb_name}.execute")
        file.each_line do |line|
            return line.split("started with pid ").last.split("'")[1].to_i if line.include?("started with pid")
        end
        raise "No pid found for #{file}"
    end

    #
    # search for parent ppid and return sandbox name
    #
    def get_sb_name_by_ppid(ppid)
        Dir.glob("/opt/bs/run/*").each do |file|
            file_text = File.read(file) 
            if file_text.to_i == ppid
                basename = Pathname.new(file).basename.to_s
                by_dot_split = basename.split(".")
                by_resque_worker = by_dot_split[0].split("resque_worker_") 
                return by_resque_worker[1]
            end
        end
        nil
    end

    # resque job parameters are hash
    def perform(params)

        sb_name  = get_sb_name_by_ppid(Process.ppid)
        raise "No sandbox found for this worker" if sb_name.nil?

        rootfs   = "/var/lib/lxc/#{sb_name}/rootfs/"
        ver_path = rootfs + "#{VER_DST_DIR}/"

        user_test = UserTest.find(params["user_test_id"])
        solution = params["solution"]
        session_id = params["session_id"]

        Policy.new(sb_name).apply

        case user_test["language"]
        when CPP
 
            # TODO: save verification and object if it wasn't changed          
            FileUtils.rm_rf(ver_path + ".")

            # copy work files to /home/ubuntu/session_id
            rewrite_file(ver_path + "solution.cpp", solution)

            rewrite_file(ver_path + "verification.cpp", user_test["verification"])

            FileUtils.cp("#{VER_SRC_DIR}/#{VERIFICATOR[CPP]}", ver_path)

            rv = FALSE
            begin
                Timeout.timeout(DEFAULT_TIME_LIMIT) do
                    command = "sudo lxc-execute -n #{sb_name} -o /var/log/lxc/#{sb_name}.execute -l NOTICE #{VER_DST_DIR}/#{VERIFICATOR[CPP]}" 
                    rv = system(command)
                end
                system("tail -n 50 #{ver_path}log.txt > #{ver_path}trunc_log.txt")
                message = File.read("#{ver_path}trunc_log.txt")            
            rescue Timeout::Error
                system("tail -n 50 #{ver_path}log.txt > #{ver_path}trunc_log.txt")
                message = File.read("#{ver_path}trunc_log.txt")            
                message +=  "[--bs--]\nOops... We've been waiting for too long"
                system("sudo lxc-stop -n #{sb_name} &")
                sleep(1)
                init_pid = fetch_init_pid(sb_name)
                system("sudo kill -9 #{init_pid}")
                puts "Killed #{init_pid}"
            end

            active_session = ActiveSession.find(session_id)
            active_session.update_attributes(
              verified_digest:    params["digest"],
              verified_status:    SYSTEM_STATUS[rv],
              verified_message:   message,
              verified_solution:  solution 
            )
            active_session.save!
            active_session.unlock()
            return rv
        when RUBY
        when JAVASCRIPT
        else
            raise "Unknown language"
        end
    end
end
end

