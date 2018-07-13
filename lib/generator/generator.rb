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
      project_path =  File.expand_path(options['project_path'])
      @configs = PropertyGenerator::Config.new(project_path)
      @globals = PropertyGenerator::Globals.new(project_path, @configs)
      @globals = @globals.globals
      @output_path =  "#{File.expand_path(options['output'])}/properties/#{SecureRandom.hex}"
      puts "Properties will be output here #{@output_path}"
      @service_list = PropertyGenerator.read_services(project_path)

    end

    def generate
      output = []
      @service_list.each do | service, path|
        service_instance = PropertyGenerator::Service.new(YAML.load_file(path), @configs, @globals)
        service_instance.service
        service_instance.interpolate

        out = PropertyGenerator.writer(service, service_instance.service, @configs, @output_path)
        (output << out).flatten!
      end
      output
    end

    def upload(out, config)
      upload_account = config['upload_account']
      upload_region = config['upload_region']
      upload_bucket = config['upload_bucket']
      out.each do |file|
        next unless file.include?("#{upload_account}") && file.include?("#{upload_region}")
         file_region = file.split("/")[-2]
         PropertyGenerator.sync(upload_region, upload_account, upload_bucket, file, file_region)
      end
    end

  end
end

