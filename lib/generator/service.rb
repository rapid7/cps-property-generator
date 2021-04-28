module PropertyGenerator

  class Service
    require 'active_support/core_ext/hash'

    attr_accessor :service

    def initialize(service_data, config, globals)
      @service_data = service_data
      @environments = config.environments
      @globals = globals
      @environment_configs = config.environment_configs
      @configmapname = service_data['configname'].nil? ? nil : service_data['configname']
      set_additional_options
      set_service
    end

    def set_service
      service_data = merge_env_default(@service_data, @environments)
      @service = merge_service_with_globals(@globals, service_data, @environments)
    end

    def set_additional_options
      @additional_options = {}
      @additional_options['configname'] = @service_data['configname'].nil? ? nil : @service_data['configname']
      @additional_options['stringdata'] = @service_data['stringdata'].nil? ? nil : @service_data['stringdata']
      @additional_options['configlabels'] = @service_data['configlabels'].nil? ? nil : @service_data['configlabels']
      @additional_options['secretlabels'] = @service_data['secretlabels'].nil? ? nil : @service_data['secretlabels']
    end

    def additional_options
      @additional_options
    end

    def service
      @service
    end

    def configmap_name
      @configmapname
    end

    def interpolate
      environments = @environments
      #read in config
      #interate through environment and substitute config for values for that environment
      environments.each do | env|
        #get the map of config for a env
        interpolations = @environment_configs[env]['interpolations']

        # Recursively interate through the properties for an environment and gsub the config
        # with defined interpolations.
        service_env = Marshal.load(Marshal.dump(@service[env]))
        interpolate_nested_properties(service_env, interpolations)
        @service[env] = service_env
      end
      service
    end

    def interpolate_nested_properties(service_env, interpolations)
      interpolations.each do |matcher_key, matcher_value|
        service_env.each { |k,v|  service_env[k] = v.gsub("{#{matcher_key}}", matcher_value) if v.class == String && v.include?("{#{matcher_key}}")}
        service_env.values.each { |v| interpolate_nested_properties(v, interpolations)  if v.class == Hash }
      end
    end

    def merge_env_default(data, environments)
      #creates a hash of the environments merged with the defaults
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
          environment_data = data['environments'][env].deep_merge(encrypted) unless encrypted.nil?
        end
        if default_clone.nil?
          merged = environment_data
        else
          merged = default_clone.deep_merge(environment_data)
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
          merged = globals_clone[env].deep_merge(service_data[env])
        end
        output[env] = merged
      end
      output
    end

  end

end
