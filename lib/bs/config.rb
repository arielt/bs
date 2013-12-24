module BS
  module Config

    @config = nil

    CONF_DIR  = '.bs'
    CONF_FILE = '.bs/config'
    TASK_DIR  = '.bs/tasks'

    @init_config = {
      'task_path' => '.bs/tasks'
    }

   def self.check()
     unless Dir.exists? CONF_DIR
       puts "A Binary Score environment is required to run this command.
Run `bs make` to set one up."
       exit(1)
     end
   end

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

    def self.init
      File.open(CONF_FILE, 'w') {|f| f.write @init_config.to_yaml }
    end

    def self.clean(params)
      system("rm -rf #{CONF_DIR}")
    end

    def self.make(params)
      system("mkdir -p #{CONF_DIR}")
      system("mkdir -p #{TASK_DIR}")
      init
    end

  end
end
