module PropertyGenerator
  require_relative 'config_linter.rb'
  require_relative 'globals_linter.rb'
  require_relative 'services_linter.rb'
  require_relative 'report.rb'
  class Linter

    def initialize(path)
      ignore_list = ['README.md']
      invalid_paths = PropertyGenerator.invalid_paths(path, ignore_list)
      @config_linter = PropertyGenerator::ConfigLinter.new(path+"/config/config.yml")
      @globals_linter = PropertyGenerator::GlobalsLinter.new(path+"/globals/", @config_linter.configs)
      @services_linter = PropertyGenerator::ServicesLinter.new(path+"/services/", @config_linter.configs)
      @report = PropertyGenerator::Report.new(invalid_paths)
    end

    def run_tests
      config_report = @config_linter.run_config_tests
      globals_report = @globals_linter.run_globals_tests
      service_linter = @services_linter.run_services_tests
      @report.add_report(config_report)
      @report.add_report(globals_report)
      @report.add_report(service_linter)
    end

    def fail_check
      if @report.has_a_test_failed || @report.has_a_file_failed_to_load
        return true
      else
        false
      end
    end

    def display_report
      @report.display_report
    end

  end
end
