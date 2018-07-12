require 'spec_helper'
require_relative '../../lib/generator/service'
require_relative '../../lib/generator/globals'
require_relative '../../lib/generator/config'
require 'pp'
module PropertyGenerator
  describe Service do
    subject(:config) {PropertyGenerator::Config.new(File.expand_path("./spec/resources"))}
    subject(:globals) {PropertyGenerator::Globals.new(File.expand_path("./spec/resources"), config)}
    subject(:service) {described_class.new(YAML.load_file('./spec/resources/services/my-microservice-1.yml'), config, globals.globals)}

    it 'Parses and condenses a service\'s defaults and environment definitions'  do
      expect(service.service).to eq({"my-test-env1"=> {"foo"=>"bar",
                                                       "my_account"=>123456789012,
                                                       "my_env"=>"my-test-env1",
                                                       "database.host"=>"my.database.{domain}",
                                                       "database.port"=>3306},
                                     "my-test-env2"=> {"foo"=>"bar",
                                                       "database.host"=>"my.database.{domain}",
                                                       "database.port"=>3306}})
    end

    it 'Tests interpolations work for a service' do
      expect(service.interpolate).to eq({"my-test-env1"=> {"foo"=>"bar",
                                                           "my_account"=>123456789012,
                                                           "my_env"=>"my-test-env1",
                                                           "database.host"=>"my.database.my1.com",
                                                           "database.port"=>3306},
                                         "my-test-env2"=> {"foo"=>"bar",
                                                           "database.host"=>"my.database.my2.com",
                                                           "database.port"=>3306}})
    end

  end
end