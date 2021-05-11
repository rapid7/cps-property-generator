module PropertyGenerator
  require 'yaml'
  class Config
    attr_accessor :configs

    def initialize(project_path)
      @project_path = project_path
    end

    def configs
      @configs ||= read_configs
    end

    def environments
      configs['environments']
    end

    def accounts
      configs['accounts']
    end

    def environment_configs
      configs['environment_configs']
    end

    def read_configs
      file = "#{@project_path}/config/config.yml"
      YAML.load_file(file)
    end
  end
end
