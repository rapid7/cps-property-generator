module PropertyGenerator
  require 'terminal-table'

  class Report
    def initialize(files_failing_load)
      @files_failing_load = files_failing_load
      @full_report = {}
    end

    def add_report(report)
      @full_report = @full_report.merge(report)
    end

    def display_report
      if @files_failing_load != []
        make_failing_to_load_table
      end
      make_pass_table
      make_warn_table
      make_fail_table
    end

    def has_a_test_failed
      @full_report.each do |test, status|
        if status[:status] == 'fail' || @files_failing_load != []
          return true
        else
          return false
        end
      end
    end

    def make_failing_to_load_table
      rows = []
      @files_failing_load.each do |failed|
        rows << [failed]
      end
      table = Terminal::Table.new :headings => ['Files'], :title => 'Files Failing to Load', :rows => rows, :style => {:width => 200}
      puts table
    end

    def make_pass_table
      rows = []
      @full_report.each do |test,status|
        if status[:status] == 'pass'
          rows << [test.gsub('_', ' ')]
        end
      end
      table = Terminal::Table.new :headings => ['Test'], :title => 'Passing Tests', :rows => rows, :style => {:width => 200}
      puts table
    end

    def make_warn_table
      rows = []
      @full_report.each do |test,status|
        if status[:status] == 'warn'
          rows << [test.gsub('_', ' '), status[:error].scan(/.{1,90}/).join("\n")]
        end
      end
      table = Terminal::Table.new :headings => ['Test', 'Error'], :title => 'Warning Tests', :rows => rows, :style => {:width => 200}
      puts table
    end

    def make_fail_table
      rows = []
      @full_report.each do |test,status|
        if status[:status] == 'fail'
          rows << [test.gsub('_', ' '), status[:error].scan(/.{1,90}/).join("\n")]
        end
      end
      table = Terminal::Table.new :headings => ['Test', 'Error'], :title => 'Failing Tests', :rows => rows, :style => {:width => 200}
      puts table
    end

  end
end
