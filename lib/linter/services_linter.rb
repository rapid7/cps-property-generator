require_relative '../helpers/helpers'
module PropertyGenerator
  require 'yaml'
  class ServicesLinter

    def initialize(path, configs)
      @configs = configs
      @services = {}
      valid_paths = PropertyGenerator.valid_paths(path)
      valid_paths.each do |file_path|
        @services[file_path] = YAML.load_file(file_path)
      end
    end

    def run_services_tests
      tests = ['services_have_accepted_keys',
               'service_environments_are_not_empty',
               'service_defaults_have_no_hashes_as_values',
               'service_environments_match_config_environments',
               'service_environments_have_no_hashes_as_values',
               'service_encrypted_environments_match_config_environments',
               'service_encrypted_fields_are_correct',
               'service_encrypted_region_field_is_accepted']
      results = PropertyGenerator.test_runner(self, tests)
      results
    end

    def service_environments_are_not_empty
      status = {status: 'pass', error: ''}
      services_empty_environments = []
      @services.each do |path, loaded|
        unless loaded['environments'] == nil
          loaded['environments'].each do |environments, properties|
            if properties == nil
              services_empty_environments << {path => environments}
            end
          end
        end
      end
      if services_empty_environments != []
        status[:status] = 'fail'
        status[:error] = "Service files #{services_empty_environments} have empty environments, these should be omitted."
      end
      status
    end

    def services_have_accepted_keys
      status = {status: 'pass', error: ''}
      accepted_keys = ['default', 'environments', 'encrypted']
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        loaded.keys.each do |service_key|
          unless accepted_keys.include?(service_key)
            services_with_unacceptable_keys << {path => service_key}
          end
        end
      end
      if services_with_unacceptable_keys != []
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have keys other than 'default', 'environments', or 'encrypted'."
      end
      status
    end

    def service_defaults_have_no_hashes_as_values
      status = {status: 'pass', error: ''}
      services_with_hashes_in_defaults = []
      @services.each do |path, loaded|
        unless loaded['default'] == nil
          loaded['default'].each do |defaultkey, defaultvalue|
            if defaultvalue.class == Hash
              services_with_hashes_in_defaults << {path => defaultkey}
            end
          end
        end
      end
      if services_with_hashes_in_defaults != []
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_hashes_in_defaults} have default properties with values as hashes."
      end
      status
    end

    def service_environments_match_config_environments
      status = {status: 'pass', error: ''}
      missmatched_environments = []
      @services.each do |path, loaded|
        if loaded['environments'] != nil
          loaded['environments'].keys.each do |environment|
            if @configs['environments'] != nil
              unless @configs['environments'].include?(environment)
                missmatched_environments << {path => environment}
              end
            else
              status[:status] = 'warn'
              status[:error] = "Environments list in config file is missing."
            end
          end
        end
      end
      if missmatched_environments != []
        status[:status] = 'warn'
        status[:error] = "Service files: #{missmatched_environments} have environments not matching config list."
      end
      status
    end

    def service_environments_have_no_hashes_as_values
      status = {status: 'pass', error: ''}
      services_with_hashes_in_environments = []
      services_with_empty_environments = []
      @services.each do |path, loaded|
        unless loaded['environments'] == nil
          loaded['environments'].each do |environments, properties|
            if properties == nil
              services_with_empty_environments << {path => environments}
            else
              properties.each do |key, value|
                if value.class == Hash
                  services_with_hashes_in_environments << {path => {environments => key}}
                end
              end
            end
          end
        end
      end
      if services_with_hashes_in_environments != []
        status[:status] = 'fail'
        status[:error] = "Service files #{services_with_hashes_in_environments} have environment properties with values as hashes."
      elsif services_with_empty_environments != []
        status[:status] = 'fail'
        status[:error] = "Service files #{services_with_empty_environments} have empty environments, if an environment has no properties remove the environment key."
      end
      status
    end

    def service_encrypted_environments_match_config_environments
      status = {status: 'pass', error: ''}
      missmatched_environments = []
      @services.each do |path, loaded|
        if loaded['encrypted'] != nil
          loaded['encrypted'].keys.each do |environment|
            if @configs['environments'] != nil
              unless @configs['environments'].include?(environment)
                missmatched_environments << {path => environment}
              end
            else
              status[:status] = 'warn'
              status[:error] = "Environments list in config file is missing."
            end
          end
        end
      end
      if missmatched_environments != []
        status[:status] = 'warn'
        status[:error] = "Service files: #{missmatched_environments} have encrypted environments not matching config list."
      end
      status
    end

    def service_encrypted_fields_are_correct
      status = {status: 'pass', error: ''}
      accepted_keys = ['region', 'encrypted']
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        if loaded['encrypted'] != nil
          loaded['encrypted'].each do |environment, property|
            if loaded['encrypted'][environment][property] != nil
              loaded['encrypted'][environment][property].each do |ssm, keys|
                unless loaded['encrypted'][environment][property]['$ssm'][keys].keys == accepted_keys
                  services_with_unacceptable_keys << {path => {environment => property}}
                end
              end
            end
          end
        end
      end
      if services_with_unacceptable_keys != []
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have encrypted properties with keys other than 'region' and 'encrypted'."
      end
      status
    end

    def service_encrypted_region_field_is_accepted
      status = {status: 'pass', error: ''}
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        if loaded['encrypted'] != nil
          loaded['encrypted'].each do |environment, property|
            if loaded['encrypted'][environment][property] != nil
              loaded['encrypted'][environment][property].each do |ssm, keys|
                if @configs['environments'] != nil
                  unless @configs['environments'].include?(loaded['encrypted'][environment][property]['$ssm'][keys]['region'])
                    services_with_unacceptable_keys << {path => {environment => property}}
                  end
                else
                  status[:status] = 'warn'
                  status[:error] = "Environments list in config file is missing."
                end
              end
            end
          end
        end
      end
      if services_with_unacceptable_keys != []
        status[:status] = 'warn'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have encrypted properties a region field not matching a declared environment in the configs."
      end
      status
    end


  end
end
