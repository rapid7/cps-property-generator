module PropertyGenerator
  require 'json'
  require 'fileutils'
  require 'aws-sdk-s3'
  class << self

    def test_runner(object, test_list)
      results = {}
      test_list.each do |test|
        results[test] = object.send(test)
      end
      results
    end

    def get_list_of_files(path, ignore_list)
      #Returns a list of files in given path
      #Ignores files in a given ignore list
      Dir.glob(path + "/**/*").select{ |e| File.file? e unless ignore_list.include?(e.split('/')[(e.split('/')).length - 1])}
    end

    def valid_paths(path)
      valid_paths = []
      list_of_file_paths = get_list_of_files(path, [])
      list_of_file_paths.each do |file_path|
        begin
          YAML.load_file(file_path)
          valid_paths << file_path
        rescue
          next
        end
      end
      valid_paths
    end

    def invalid_paths(path, ignore_list)
      invalid_paths = []
      list_of_file_paths = get_list_of_files(path, ignore_list)
      list_of_file_paths.each do |file_path|
        begin
          YAML.load_file(file_path)
        rescue
          invalid_paths << file_path
        end
      end
      invalid_paths
    end

    def read_services(path)
      Dir.glob("#{path}/services/*.{yaml,yml}").each_with_object({}) do |file, acc|
        name = File.basename(file)[/(?<service>.*)\.ya?ml$/, :service]
        path = File.absolute_path(file)
        acc[name] = path
      end
    end

    def writer(service_name, finalized, configs, output_path)
      output = []
      envs = configs.environments
      environmental_configs =  configs.environment_configs
      envs.each do | env|
        account = environmental_configs[env]["account"]
        region = environmental_configs[env]["region"]
        json = JSON.pretty_generate({"properties" => finalized[env]})
        FileUtils.mkdir_p("#{output_path}/#{account}/#{region}/") unless Dir.exist?("#{output_path}/#{account}/#{region}/")
        File.write("#{output_path}/#{account}/#{region}/#{service_name}.json", json)
        output << "#{output_path}/#{account}/#{region}/#{service_name}.json"
      end
      output
    end

    def sync(region, account, bucket, file, file_region)
      s3 = Aws::S3::Resource.new(region: region)
      filename = file.split("/").last
      puts "Destination: #{account}/#{file_region}/#{filename}"
      puts "Uploading: #{file}"
      obj = s3.bucket(bucket).object("#{account}/#{file_region}/#{filename}")
      obj.upload_file(file)
    end

  end
end
