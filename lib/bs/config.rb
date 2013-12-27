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

  end
end

