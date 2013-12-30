module BS
  module Task

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

     end
  end
end

