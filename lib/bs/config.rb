module BS
  module Config

    @config = nil

    CONF_FILE = '.bs/config'

    @init_config = {
      'task_path' => '.bs/tasks'
    }

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

    def self.init
      File.open(CONF_FILE, 'w') {|f| f.write @init_config.to_yaml }
    end

    def self.clean(params)
      system("rm -rf .bs")
    end

    def self.make(params)
      system("mkdir -p .bs")
      system("mkdir -p .bs/tasks")
      init
    end

  end
end
