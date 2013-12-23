module Bs
  module Config

    @config = nil

    def self.get
      @config = YAML::load_file('.bs/config') unless @config
      return @config
    end

  end
end
