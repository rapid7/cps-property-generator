module PropertyGenerator
  require 'yaml'
  class ConfigLinter
    attr_accessor :configs

    def initialize(path)
      @configs = check_for_config(path)
    end

    def run_config_tests
      if @configs == {}
        tests = ['config_file_is_present']
      else
        tests = [
          'config_has_correct_keys',
          'environment_configs_match_environments_list',
          'environment_configs_have_valid_region_and_account_values',
          'environment_configs_have_well_formatted_interpolations',
          'config_file_is_present'
        ]
      end

      PropertyGenerator.test_runner(self, tests)
    end

    def check_for_config(path)
      # Tries to load the config file - if is unable to load config.yml it returns an empty hash
      # Empty hash is returned so that the rest of the files are still able to be linted instead of stopping at this point.

      YAML.load_file(path)
    rescue StandardError
      {}
    end

    def config_file_is_present
      status = { status: 'pass', error: '' }
      if @configs == {}
        status[:status] = 'fail'
        status[:error] = 'Config.yml file is missing, it is required.'
      end
      status
    end

    def config_has_correct_keys
      status = { status: 'pass', error: '' }
      config_keys = ['environments', 'accounts', 'environment_configs']
      if @configs.keys != config_keys
        status[:status] = 'fail'
        status[:error] = "Config keys should be 'environments', 'accounts', and 'environment_configs'."
      end
      status
    end

    def environment_configs_match_environments_list
      status = { status: 'pass', error: '' }
      if @configs['environments'] != @configs['environment_configs'].keys
        status[:status] = 'fail'
        status[:error] = 'Environments in environment_configs do not match environments listed in config environments.'
      end
      status
    end

    def environment_configs_have_valid_region_and_account_values
      status = { status: 'pass', error: '' }
      environments_missmatch_values = @configs['environment_configs'].reject do |_, env_config|
        env_config.key?('region') && @configs['accounts'].include?(env_config['account'])
      end.keys

      unless environments_missmatch_values.empty?
        status[:status] = 'fail'
        status[:error] = "Environments: #{environments_missmatch_values} in environment_configs have a region or account value not listed in top level."
      end

      status
    end

    def environment_configs_have_well_formatted_interpolations
      status = { status: 'pass', error: '' }
      environments_with_bad_interpolations = []
      any_mistakes = false
      @configs['environment_configs'].keys.each do |environment|
        if @configs['environment_configs'][environment]['interpolations'].class == Hash
          @configs['environment_configs'][environment]['interpolations'].each do |interpolation, value|
            if value.class != String && value.class != Integer && value.class != Float && value.class != Fixnum
              environments_with_bad_interpolations << { environment => interpolation }
              any_mistakes = true
            end
          end
        else
          environments_with_bad_interpolations << environment
          any_mistakes = true
        end
      end
      if any_mistakes
        status[:status] = 'fail'
        status[:error] = "Incorrectly formatted interpolations in Environments: #{environments_with_bad_interpolations}"
      end
      status
    end
  end
end
