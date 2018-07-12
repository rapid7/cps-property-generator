module PropertyGenerator
  require 'yaml'
  class GlobalsLinter

    def initialize(path, configs)
      @configs = configs
      @globals = {}
      valid_paths = PropertyGenerator.valid_paths(path)
      valid_paths.each do |file_path|
          @globals[file_path] = YAML.load_file(file_path)
      end
    end

    def run_globals_tests
      tests = ['globals_load_as_hashes',
               'globals_have_no_hashes_as_values',
               'globals_are_defined_for_valid_environemnts',
               ]
      results = PropertyGenerator.test_runner(self, tests)
      results
    end

    def globals_load_as_hashes
      status = {status: 'pass', error: ''}
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
      status = {status: 'pass', error: ''}
      globals_with_hash_props = []
      @globals.each do |path, loaded|
        if loaded.class == Hash
          loaded.each do |key, value|
            if value.class == Hash
              globals_with_hash_props << {path => key}
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
      status = {status: 'pass', error: ''}
      ignore_list = ['globals.yml']
      globals_with_invalid_environments = []
      accounts = []
      if @configs['accounts'] != nil
        @configs['accounts'].each do |account|
          accounts << account.to_s
        end
        @globals.each do |path, loaded|
          unless @configs['environments'].include?((path.split('/')[(path.split('/')).length - 1]).split('.')[0]) || accounts.include?((path.split('/')[(path.split('/')).length - 1]).split('.')[0])
            globals_with_invalid_environments << path unless ignore_list.include?(path.split('/')[(path.split('/')).length - 1])
          end
        end
        if globals_with_invalid_environments != []
          status[:status] = 'warn'
          status[:error] = "Files #{globals_with_invalid_environments} do not have names matching a declared environment."
        end
      else
        status[:status] = 'warn'
        status[:error] = "Accounts list in config file is missing."
      end
      status
    end


  end
end
