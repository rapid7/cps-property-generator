require_relative '../helpers/helpers'

module PropertyGenerator
  require 'yaml'
  require 'pathname'
  class GlobalsLinter
    TESTS = [
      'globals_load_as_hashes',
      'globals_are_defined_for_valid_environemnts'
    ].freeze

    def initialize(path, configs, ignored_tests)
      @configs = configs
      @globals = {}
      @ignored_tests = ignored_tests
      valid_paths = PropertyGenerator.valid_paths(path)
      valid_paths.each do |file_path|
        @globals[file_path] = YAML.load_file(file_path)
      end
    end

    def run_globals_tests
      tests = TESTS - @ignored_tests

      PropertyGenerator.test_runner(self, tests)
    end

    def globals_load_as_hashes
      status = { status: 'pass', error: '' }
      non_hash_globals = []
      @globals.each do |path, loaded|
        if loaded.class != Hash
          non_hash_globals << path
        end
      end
      if non_hash_globals != []
        status[:status] = 'fail'
        status[:error] = "Global files #{non_hash_globals} are not being loaded as hashes."
      end
      status
    end

    def globals_have_no_hashes_as_values
      status = { status: 'pass', error: '' }
      globals_with_hash_props = []
      @globals.each do |path, loaded|
        if loaded.class == Hash
          loaded.each do |key, value|
            if value.class == Hash
              globals_with_hash_props << { path => key }
            end
          end
        end
      end
      if globals_with_hash_props != []
        status[:status] = 'fail'
        status[:error] = "Globals #{globals_with_hash_props} have values that are hashes."
      end
      status
    end

    def globals_are_defined_for_valid_environemnts
      status = { status: 'pass', error: '' }
      ignore_list = ['globals.yml']

      if @configs['accounts'].nil?
        status[:status] = 'warn'
        status[:error] = 'Accounts list in config file is missing.'
        return status
      end

      accounts = @configs['accounts'].map(&:to_s)
      globals_with_invalid_environments = @globals.keys.select do |path|
        p = Pathname.new(path)
        filename = p.basename(File.extname(path)).to_s
        next if ignore_list.include?(p.basename.to_s)

        !(@configs['environments'].include?(filename) || accounts.include?(filename))
      end

      unless globals_with_invalid_environments.empty?
        status[:status] = 'warn'
        status[:error] = "Files #{globals_with_invalid_environments} do not have names matching a declared environment."
      end

      status
    end
  end
end
