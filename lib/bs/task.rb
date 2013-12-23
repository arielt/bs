module Bs
  module Task
    def self.list(params)
      puts "Task list:"
      puts "-------------------------------------"
      system("ls #{Bs::Config.get['tasks_path']}")
      puts "-------------------------------------"
    end

    def self.add(params)
      system("cd  #{Bs::Config.get['tasks_path']} && git clone #{params[0]}")
    end

    def self.del(params)
      system("rm -rf #{Bs::Config.get['tasks_path']}/#{params[0]}")
    end
  end
end

