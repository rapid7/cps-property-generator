module PropertyGenerator
  class Service
    attr_accessor :service
    def initialize(service_data, config, globals)
      @service_data = service_data
      @environments = config.environments
      @globals = globals
      @environment_configs = config.environment_configs
      set_service
    end

    def set_service
      service_data = merge_env_default(@service_data, @environments)
      @service = merge_service_with_globals(@globals, service_data, @environments)
    end

    def service
      @service
    end

    def interpolate
      environments = @environments
      #read in config
      #interate through environment and substitute config for values for that environment
      environments.each do | env|
        #get the map of config for a env
        interpolations = @environment_configs[env]['interpolations']

        #interate through the properties for an environment and gsub the config
        @service[env].each do | property_key, property_value|
          property_value_dup = property_value.dup
          interpolations.each do |matcher_key, matcher_value|
            if property_value.class == String && property_value_dup.include?("{#{matcher_key}}")
              @service[env][property_key] = property_value_dup.gsub!("{#{matcher_key}}", matcher_value)
            end
          end
        end
      end
      service
    end

    def merge_env_default(data, environments)
      #creates a hash of the enviornments merged with the defaults
      # {service => {env1 =>  {properties},
      #             env2 => {properties}
      #           }
      # }
      output = {}
      default = data['default']

      environments.each do |env|
        default_clone = default.dup
        #if nil, use set to environments as nothing to merge env with
        data['environments'] ||= {}
        data['environments'][env] ||= {}
        environment_data = data['environments'][env].dup
        if data['encrypted']
          encrypted = data['encrypted'][env].dup unless data['encrypted'][env].nil?
          environment_data = data['environments'][env].merge(encrypted) unless encrypted.nil?
        end
        if default_clone.nil?
          merged = environment_data
        else
          merged = default_clone.merge(environment_data)
        end
        output[env] = merged
      end
      output
    end

    def merge_service_with_globals(globals_data, service_data, environments)
      #service will now overwrite globals, merging will be done for each environment
      output = {}
      envs = environments
      envs.each do |env|
        globals_clone = globals_data.dup
        if globals_clone[env].nil? || globals_clone[env] == false
          merged = service_data[env]
        else
          merged = globals_clone[env].merge(service_data[env])
        end
        output[env] = merged
      end
      output
    end


  end
end
