require 'yaml'

module BS
  module Config

    @config = nil

    CONF_DIR  = "/opt/bs/config"
    CONF_FILE = "/opt/bs/files/bs.yml"
    TASK_DIR  = "/opt/bs/tasks"
    TMP_DIR   = "/opt/tmp"

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

  end
end

