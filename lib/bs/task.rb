module BS
  module Task

    extend self

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

    def params(task_name)
      @config = YAML::load_file("#{BS::Config::TASK_DIR}/#{task_name}/task.yml")
      return @config
    end

  end
end

