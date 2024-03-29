module PropertyGenerator
  class Globals
    require 'yaml'
    attr_accessor :globals

    def initialize(project_path, config)
      @project_path = project_path
      @environments = config.environments
      @environment_configs = config.environment_configs
      @accounts = config.accounts
    end

    def globals
      @globals ||= condense_globals
    end

    def get_main_global
      top_level = {}
      if File.exist?("#{@project_path}/globals/globals.yml")
        top_level = YAML.load_file("#{@project_path}/globals/globals.yml")
      end
      top_level
    end

    def get_account_globals
      data = {}
      @accounts.each do |account|
        next unless Dir.exist?("#{@project_path}/globals/accounts/#{account}")

        account_default_file = "#{@project_path}/globals/accounts/#{account}/#{account}.yml"
        data[account] = YAML.load_file(account_default_file) if File.exist?(account_default_file)
      end
      data
    end

    def get_environment_globals
      data = {}
      @accounts.each do |account|
        next unless Dir.exist?("#{@project_path}/globals/accounts/#{account}/environments")

        data[account] = {}
        @environments.each do |env|
          next unless File.exist?("#{@project_path}/globals/accounts/#{account}/environments/#{env}.yml")

          data[account][env] = YAML.load_file("#{@project_path}/globals/accounts/#{account}/environments/#{env}.yml")
          unless data[account][env]['encrypted'].nil?
            encrypted = data[account][env]['encrypted'].dup
            not_encrypted = data[account][env].reject { |k, _| k == 'encrypted' }
            data[account][env] = not_encrypted.deep_merge(encrypted)
          end
        end
      end
      data
    end

    # merge environment globals with account globals.
    def condense_globals
      condensed = {}
      # get account and the environmental hash's for said account
      environment_globals = get_environment_globals
      account_globals = get_account_globals
      main_global = get_main_global
      # nothing to do here if everything is empty
      return condensed if environment_globals.empty? && account_globals.empty? && main_global.empty?

      environment_globals.each do |account, env_global|
        # get the env and the values
        env_global.each do |env, hash|
          account_globals[account] ||= {}
          # set the environment globals to be the account global merged with the env globals
          env_global[env] = account_globals[account].deep_merge(hash) unless hash.empty?
          condensed[env] = env_global[env]
        end
      end

      # If there are no environmental globals and there are account globals we have to merge them in
      if condensed.empty? && !account_globals.empty?
        # assemble the account to env mapping
        mapping = {}

        @environment_configs.each do |env, vals|
          account = vals["account"]
          next if account.nil?

          mapping[account] = Array(mapping[account]).push(env)
        end

        account_globals.each do |account, env_account|
          mapping[account].each do |env|
            condensed[env] = env_account
          end
        end
      end

      unless main_global.empty?
        # All environments need the main global definitions
        @environments.each do |env|
          # If a key/value pair for a environment has not been defined set one so we can merge
          condensed[env] ||= {}
          # We need to merge into the globals so any env configs overwrite main global configs.
          # Dup so we dont modify the original object
          main_global_dup = main_global.dup
          condensed[env] = main_global_dup.deep_merge(condensed[env])
        end
      end
      condensed
    end
  end
end
