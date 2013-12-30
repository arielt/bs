module BS
  module Sandbox
    module Core

      # queue should be defined in descendant modules

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

    end
  end
end
