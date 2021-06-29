module PropertyGenerator
  require_relative 'config_linter'
  require_relative 'globals_linter'
  require_relative 'services_linter'
  require_relative 'report'
  class Linter
    attr_accessor :ignored_tests, :services_linter, :globals_linter, :config_linter, :report

    def initialize(path)
      ignore_list = %w[README.md .cpsignore Jenkinsfile]
      invalid_paths = PropertyGenerator.invalid_paths(path, ignore_list)
      begin
        @ignored_tests = YAML.load_file("#{path}/.cpsignore")
      rescue StandardError
        @ignored_tests = {}
      end
      @config_linter = PropertyGenerator::ConfigLinter.new("#{path}/config/config.yml", @ignored_tests['config'] || [])
      @globals_linter = PropertyGenerator::GlobalsLinter.new("#{path}/globals/", @config_linter.configs, @ignored_tests['globals'] || [])
      @services_linter = PropertyGenerator::ServicesLinter.new("#{path}/services/", @config_linter.configs, @ignored_tests['services'] || [])

      unless @ignored_tests['display_skipped_tests'].nil?
        if @ignored_tests['display_skipped_tests']
          @ignored_tests.delete('display_skipped_tests')
        else
          @ignored_tests = []
        end
      end

      @report = PropertyGenerator::Report.new(invalid_paths, @ignored_tests)
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
        true
      else
        false
      end
    end

    def display_report
      @report.display_report
    end
  end
end
