require 'yaml'
require 'fileutils'

module BS
  class Session

    SESSION_DIR  = '/opt/bs/session/'
    SESSION_FILE = "#{SESSION_DIR}config"

    @config = nil

    def is_created
      File.exists?(SESSION_FILE)
    end

    def load_config
      if is_created()
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
      if is_created()
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
      File.read( "/opt/bs/tasks/#{@config['task']}/objective.md")
    end

    def accept
      unless @config['accepted_at']
        @config['accepted_at'] = Time.now
        @config['deadline'] = @config['accepted_at'] + BS::Task.params(@config['task'])['time_limit'] * 60
        save_config
      end
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

