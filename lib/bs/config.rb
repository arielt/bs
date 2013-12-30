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

    DEFAULT_TIME_LIMIT = 30

    # subsystems
    C          = 0
    CPP        = 10
    RUBY       = 20
    JAVASCRIPT = 30

    VERIFICATOR = {
      C           => "c.rb",
      CPP         => "cpp.rb",
      RUBY        => "ruby.rb",
      JAVASCRIPT  => "jvs.rb"
    }

    def self.get
      @config = YAML::load_file(CONF_FILE) unless @config
      return @config
    end

  end
end

