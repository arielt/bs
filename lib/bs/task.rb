module BS
  module Task
    def self.list(params)
      puts "Task list:"
      puts "-------------------------------------"
      system("ls #{BS::Config.get['task_path']}")
      puts "-------------------------------------"
    end

    def self.add(params)
      system("cd  #{BS::Config.get['task_path']} && git clone #{params[0]}")
    end

    def self.del(params)
      system("rm -rf #{BS::Config.get['task_path']}/#{params[0]}")
    end
  end
end

