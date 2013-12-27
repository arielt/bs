module BS
  module Task
    def self.list
      puts "Task list:"
      puts "-------------------------------------"
      system("ls #{BS::Config::TASK_DIR}")
      puts "-------------------------------------"
    end

    def self.add(params)
      system("cd  #{BS::Config::TASK_DIR} && git clone #{params[0]}")
    end

    def self.del(params)
      system("rm -rf #{BS::Config::TASK_DIR}/#{params[0]}")
    end
  end
end

