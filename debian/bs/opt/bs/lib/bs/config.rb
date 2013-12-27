require 'yaml'

module BS
  module Config

    @config = nil

    CONF_DIR  = "/opt/bs"
    CONF_FILE = "#{CONF_DIR}/files/bs.yml"
    TASK_DIR  = "#{CONF_DIR}/tasks"
    TMP_DIR   = "#{CONF_DIR}/tmp"

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
      system("mkdir -p #{TMP_DIR}")
      init
    end

  end
end
