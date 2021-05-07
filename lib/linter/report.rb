module PropertyGenerator
  require 'terminal-table'

  class Report
    def initialize(files_failing_load, ignored_tests)
      @files_failing_load = files_failing_load
      @full_report = {}
      @ignored_tests = ignored_tests
    end

    def add_report(report)
      @full_report = @full_report.merge(report)
    end

    def display_report
      unless @files_failing_load.empty?
        puts make_failing_to_load_table
        puts '*****************'
        puts "Check for property values that start with an interpolated value \nIf the first character of the value is a bracket yaml will fail to load \nPlace the value in quotes"
        puts '*****************'
      end
      puts make_skip_table
      puts make_pass_table
      puts make_warn_table
      puts make_fail_table
    end

    def has_a_test_failed
      failed = false
      @full_report.each do |test, status|
        if status[:status] == 'fail'
          failed = true
        end
      end
      failed
    end

    def has_a_file_failed_to_load
      !@files_failing_load.empty?
    end

    def make_failing_to_load_table
      rows = []
      @files_failing_load.each do |failed|
        rows << [failed]
      end
      Terminal::Table.new :headings => ['Files'], :title => 'Files Failing to Load', :rows => rows, :style => { :width => 200 }
    end

    def make_skip_table
      return if @ignored_tests.empty?

      Terminal::Table.new(headings: ['Test'], title: 'Skipped Tests', rows: @ignored_tests.values, style: { width: 200 })
    end

    def make_pass_table
      rows = []
      @full_report.each do |test, status|
        if status[:status] == 'pass'
          rows << [test.gsub('_', ' ')]
        end
      end
      Terminal::Table.new(headings: ['Test'], title: 'Passing Tests', rows: rows, style: { width: 200 })
    end

    def make_warn_table
      rows = []
      @full_report.each do |test, status|
        if status[:status] == 'warn'
          rows << [test.gsub('_', ' '), status[:error].scan(/.{1,90}/).join("\n")]
        end
      end
      Terminal::Table.new(headings: ['Test', 'Error'], title: 'Warning Tests', rows: rows, style: { width: 200 })
    end

    def make_fail_table
      rows = []
      @full_report.each do |test, status|
        if status[:status] == 'fail'
          rows << [test.gsub('_', ' '), status[:error].scan(/.{1,90}/).join("\n")]
        end
      end
      Terminal::Table.new(headings: ['Test', 'Error'], title: 'Failing Tests', rows: rows, style: { width: 200 })
    end
  end
end
