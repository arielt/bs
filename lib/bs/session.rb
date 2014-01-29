require 'yaml'
require 'fileutils'

module BS
  class Session

    SESSION_DIR  = '/opt/bs/session/'
    SESSION_FILE = "#{SESSION_DIR}config"
    LOCK_FILE = "/opt/bs/session/.lock"

    @config = nil

    def exists?
      File.exists?(SESSION_FILE)
    end

    def load_config
      if exists?
         @config = YAML::load_file(SESSION_FILE)
      else
        @config = nil
      end
    end

    def save_config
      file = File.open(SESSION_FILE, 'w')
      YAML.dump(@config, file)
      file.close
    end

    def status
      puts 'Session:'
      if exists?
        load_config
        puts "  Task: \t#{@config['task']}"
        if @config['accepted_at']
          puts "  Accepted, deadline is #{@config['deadline']}"
        else
          puts "  Not accepted yet"
        end
      else
        puts '  Not created'
      end
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
      File.read( "/opt/bs/tasks/#{@config['task']}/objective.md")
    end

    # accept session
    # check if times out
    def update()
      unless @config['accepted_at']
	@config['accepted_at'] = Time.now        
	@config['deadline'] = @config['accepted_at'] + BS::Task.params(@config['task'])['time_limit'] * 60
	@config['is_active'] = TRUE
      end

      if @config['deadline'] < Time.now
        @config['is_active'] = FALSE
        @config['forced_finish'] = TRUE
        @config['finished_at'] = Time.now
      end
      save_config
    end

    def lock()
      return false if File.exists?(LOCK_FILE)
      FileUtils.touch(LOCK_FILE)
      return true
    end

    def unlock()
      FileUtils.rm_rf(LOCK_FILE)
    end

    def countdown
      (@config['deadline'] - Time.now).to_i
    end

    def config
      @config
    end

    def initialize
      load_config
    end

  end
end

