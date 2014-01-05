require 'yaml'
require 'fileutils'

module BS
  module Session

    SESSION_DIR  = '/opt/bs/session/'
    SESSION_FILE = "#{SESSION_DIR}config"

    # this config is not cached
    @config = nil

    extend self

    def status
      puts 'Session:'
      load_config
      if @config
      else
        puts "  Not created"
      end
    end

    def load_config
      unless File.exists?(SESSION_FILE)
        @config = nil
        return @config
      end
      @config = YAML::load_file(SESSION_FILE)
    end

    def save_config
      file = File.open(SESSION_FILE, 'w')
      YAML.dump(@config, file)
      file.close
    end

    def check
    end

    def create
    end

    def resume
       system("cd webapp && rails s -p 4101")
    end

    def make(params)
      FileUtils.mkdir_p(SESSION_DIR)
      @config = {
        'task'        => params[0],
        'created_at'  => Time.now,
        'accepted_at' => nil,
        'deadline'    => nil,
        'result'      => false,
        'server_pid'  => nil
      }

      save_config
    end

    def clean
      FileUtils.rm_rf(SESSION_DIR)
    end

    def objective
      load_config
      File.read( "/opt/bs/tasks/#{@config['task']}/objective.md")
    end

    def accepted_at
      load_config
      @config["accepted_at"]
    end

  end
end

