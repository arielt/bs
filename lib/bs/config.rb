require 'yaml'

module BS
  module Config

    @config = nil

    OPT_DIR   = "/opt/bs"
    CONF_DIR  = "#{OPT_DIR}/config"
    CONF_FILE = "#{CONF_DIR}/bs.yml"
    TASK_DIR  = "#{OPT_DIR}/tasks"
    #TMP_DIR   = "#{OPT_DIR}/tmp"
    LOG_DIR   = "#{OPT_DIR}/log"

    VER_DST_DIR = '/home/sandbox/verification'
    VER_SRC_DIR = "#{OPT_DIR}/lib/bs/lxc/fs/home/sandbox/verification"

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

  end
end

