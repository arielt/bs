module BS
  module Task
    def self.list(params)
      puts "Task list:"
      puts "-------------------------------------"
      system("ls #{BS::Config.get['tasks_path']}")
      puts "-------------------------------------"
    end

    def self.add(params)
      system("cd  #{BS::Config.get['tasks_path']} && git clone #{params[0]}")
    end

    def self.del(params)
      system("rm -rf #{BS::Config.get['tasks_path']}/#{params[0]}")
    end
  end
end

