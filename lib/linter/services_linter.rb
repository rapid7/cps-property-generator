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

    def recursive_find_keys(obj, key)
      if obj.respond_to?(:key?) && obj.key?(key)
        obj[key]
      elsif obj.is_a?(Hash) or obj.is_a?(Array)
        r = nil
        obj.find{ |*a| r = recursive_find_keys(a.last,key) }
        r
      end
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
              next
            end

            s = recursive_find_keys(value, '$ssm')
            k = recursive_find_keys(value, '$kms')
            if s.nil? && k.nil?
              services_with_unacceptable_keys << { path => { environment => property } }
              next
            end

            unless s.nil?
              s.keys.each do |key|
                unless accepted_keys.include?(key)
                  services_with_unacceptable_keys << { path => { environment => property } }
                  next
                end
              end
            end

            unless k.nil?
              if (k.keys & ['region', 'encrypted']).count != 2
                services_with_unacceptable_keys << { path => { environment => property } }
              end
            end
          end
        end
      end
      unless services_with_unacceptable_keys.empty?
        status[:status] = 'fail'
        status[:error] = "Service files: #{services_with_unacceptable_keys} has an encrypted block without " +
          "properties, encrypted properties without $kms or $ssm blocks, or encrypted blocks with either bad " +
          "indentation or incorrect keys."
      end
      status
    end

    def service_encrypted_region_field_is_accepted
      status = { status: 'pass', error: '' }
      services_with_unacceptable_keys = []
      @services.each do |path, loaded|
        next if loaded['encrypted'].nil?

        loaded['encrypted'].each do |environment, properties|
          if loaded['encrypted'][environment].nil?
            status[:status] = 'error'
            status[:error] = 'Encrypted properties are missing from the encrypted environment'
            return status
          end

          encrypted_env = loaded['encrypted'][environment]

          # next if encrypted_env[property].nil?

          encrypted_env.each do |property, encrypted_values|
            if @configs['environments'].nil?
              status[:status] = 'warn'
              status[:error] = 'Environments list in config file is missing.'
              break
            end

            %w[$ssm $kms].each do |encryption_type|
              values = recursive_find_keys(encrypted_values, encryption_type)
              next if values.nil?

              unless @configs['environments'].include?(values['region'])
                services_with_unacceptable_keys << { path => { environment => property } }
              end
            end
          end
        end
      end
      if !services_with_unacceptable_keys.empty? && status[:status] == 'pass'
        status[:status] = 'warn'
        status[:error] = "Service files: #{services_with_unacceptable_keys} have encrypted properties a region field not matching a declared environment in the configs."
      end
      status
    end
  end
end
