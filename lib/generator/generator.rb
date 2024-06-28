require_relative 'config'
require_relative 'globals'
require_relative 'service'
require_relative '../helpers/helpers'

module PropertyGenerator
  class Generator
    require 'fileutils'
    require 'securerandom'
    include PropertyGenerator
    # purpose: initialize globals and configs
    # serve as a broker between tasks
    def initialize(options)
      project_path = File.expand_path(options['project_path'])
      @configs = PropertyGenerator::Config.new(project_path)
      @globals = PropertyGenerator::Globals.new(project_path, @configs)
      @globals = @globals.globals
      @accounts = @configs.accounts

      @output_path = "#{File.expand_path(options['output'])}/properties/#{SecureRandom.hex}"
      puts "Properties will be output here #{@output_path}"
      @service_list = PropertyGenerator.read_services(project_path)
    end

    def generate
      output = []
      @service_list.each do |service, path|
        PropertyGenerator.config_enforcer(@configs.environment_configs)
        service_instance = PropertyGenerator::Service.new(YAML.load_file(path, permitted_classes: [Time]), @configs, @globals)
        service_instance.service
        service_instance.interpolate

        out = PropertyGenerator.writer(service, service_instance.service, @configs, @output_path, service_instance.additional_options)
        (output << out).flatten!
      end
      output
    end

    def upload(out, config)
      upload_bucket = config['upload_bucket']
      upload_region = config['upload_region']

      if config['upload_all']
        _upload_files(out.sort) do |file|
          file_region = file.split('/')[-2]
          file_account = file.split('/')[-3]

          PropertyGenerator.sync(upload_region, file_account, upload_bucket, file, file_region)
        end
      else
        upload_account = config['upload_account'].strip
        unless @accounts.map { |a| a.to_s.strip }.include?(upload_account)
          abort("The specified account (#{upload_account}) is not configured, please add it to config/config.yml")
        end

        upload_out = out.select { |file| file.include?(upload_account) && file.include?(upload_region) }
        _upload_files(upload_out) do |file|
          file_region = file.split('/')[-2]
          PropertyGenerator.sync(upload_region, upload_account, upload_bucket, file, file_region)
        end
      end
    end

    def _upload_files(files)
      files.each_slice(20) do |file_slice|
        file_slice.map do |file|
          Thread.new do
            yield file
          end
        end.each(&:join)
      end
    end
  end
end
