require_relative '../helpers/helpers'
module PropertyGenerator
  require 'yaml'
  class ServicesLinter
    TESTS = [
      'services_have_accepted_keys',
      'service_environments_are_not_empty',
      'service_environments_match_config_environments',
      'service_encrypted_environments_match_config_environments',
      'service_encrypted_fields_are_correct',
      'service_encrypted_region_field_is_accepted'
    ].freeze

    def initialize(path, configs, ignored_tests)
      @configs = configs
      @services = {}
      @ignored_tests = ignored_tests
      valid_paths = PropertyGenerator.valid_paths(path)
      valid_paths.each do |file_path|
        @services[file_path] = YAML.load_file(file_path)
      end
    end

    def run_services_tests
      tests = TESTS - @ignored_tests

      PropertyGenerator.test_runner(self, tests)
    end

    def service_environments_are_not_empty
      status = { status: 'pass', error: '' }
      services_empty_environments = []
      @services.each do |path, loaded|
        unless loaded['environments'].nil?
          loaded['environments'].each do |environments, properties|
            if properties.nil?
              services_empty_environments << { path => environments }
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
      status = { status: 'pass', error: '' }
      accepted_keys = ['default', 'environments', 'encrypted', 'configname', 'stringdata', 'configlabels', 'secretlabels', 'label']
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        loaded.keys.each do |service_key|
          unless accepted_keys.include?(service_key)
            services_with_unacceptable_keys << { path => service_key }
          end
        end
      end
      if services_with_unacceptable_keys != []
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have keys other than 'default', 'environments', 'encrypted', 'configname', 'stringdata', 'configlabels', 'secretlabels' or 'label'"
      end
      status
    end

    def service_environments_match_config_environments
      status = { status: 'pass', error: '' }
      missmatched_environments = []
      @services.each do |path, loaded|
        next if loaded['environments'].nil?

        loaded['environments'].keys.each do |environment|
          if @configs['environments'].nil?
            status[:status] = 'warn'
            status[:error] = 'Environments list in config file is missing.'
          else
            unless @configs['environments'].include?(environment)
              missmatched_environments << { path => environment }
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

    def service_encrypted_environments_match_config_environments
      status = { status: 'pass', error: '' }
      missmatched_environments = []
      @services.each do |path, loaded|
        next if loaded['encrypted'].nil?

        loaded['encrypted'].keys.each do |environment|
          if @configs['environments'].nil?
            status[:status] = 'warn'
            status[:error] = 'Environments list in config file is missing.'
          else
            unless @configs['environments'].include?(environment)
              missmatched_environments << { path => environment }
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
      status = { status: 'pass', error: '' }
      accepted_keys = ['region', 'encrypted', 'service', 'label']
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        next if loaded['encrypted'].nil?

        loaded['encrypted'].each do |environment, properties|
          properties.each do |property, value|
            if value.nil?
              services_with_unacceptable_keys << { path => { environment => property } }
            elsif value['$ssm'].nil?
              services_with_unacceptable_keys << { path => { environment => property } }
            else
              unless value['$ssm'].nil?
                value['$ssm'].keys.each do |key|
                  unless accepted_keys.include?(key)
                    services_with_unacceptable_keys << { path => { environment => property } }
                  end
                end
              end
            end
          end
        end
      end
      if services_with_unacceptable_keys != []
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have encrypted properties with bad indentation or keys other than 'region', 'encrypted' or 'label'."
      end
      status
    end

    def service_encrypted_region_field_is_accepted
      status = { status: 'pass', error: '' }
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        next if loaded['encrypted'].nil?

        loaded['encrypted'].each do |environment, property|
          next if loaded['encrypted'][environment][property].nil?

          loaded['encrypted'][environment][property].each do |ssm, keys|
            if @configs['environments'].nil?
              status[:status] = 'warn'
              status[:error] = 'Environments list in config file is missing.'
            else
              unless @configs['environments'].include?(loaded['encrypted'][environment][property]['$ssm'][keys]['region'])
                services_with_unacceptable_keys << { path => { environment => property } }
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
