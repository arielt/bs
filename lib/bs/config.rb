module BS
  module Config

    @config = nil

    CONF_FILE = '.bs/config'

    init_config = {
      'task_path' => '.bs/tasks'
    }

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

    def init
      File.open(CONF_FILE, 'w') {|f| f.write init_config.to_yaml }
    end

    def clean
      system("./bs")
    end

    def make
      system("mkdir -p ./bs")
      init
    end

  end
end
