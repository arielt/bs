module BS
  module Session

    SESSION_DIR  = '/opt/bs/session/'
    SESSION_FILE = "#{SESSION_DIR}config"

    extend self

    def status
      puts 'Session:'
      state = load_state
      if state
      else
        puts "  Not created"
      end
    end

    def load_state
      return nil unless File.exists?(SESSION_FILE)
      YAML::load_file(SESSION_FILE)
    end

    def check
    end

    def create
    end

    def launch
    end

    def make
      check
      create
      launch
    end

    def clean
      FileUtils.rm_rf(SESSION_DIR)
    end

  end
end
