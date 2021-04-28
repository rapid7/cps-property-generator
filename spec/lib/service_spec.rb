require "spec_helper"
require_relative "../../lib/generator/service"
require_relative "../../lib/generator/globals"
require_relative "../../lib/generator/config"
require "pp"
module PropertyGenerator
  describe Service do
    subject(:config) { PropertyGenerator::Config.new(File.expand_path("./spec/resources")) }
    subject(:globals) { PropertyGenerator::Globals.new(File.expand_path("./spec/resources"), config) }
    subject(:service) { described_class.new(YAML.load_file("./spec/resources/services/my-microservice-1.yml"), config, globals.globals) }

    it "Parses and condenses a service\"s defaults and environment definitions" do
      expect(service.service).to eq({
                                      "my-test-env1" => {
                                        "foo" => "bar",
                                        "map" => {
                                          "key1" => "notval1",
                                          "key2" => "val2",
                                          "key3" => "{cloud}-{region}",
                                          "key4" => "{domain}"
                                        },
                                        "my_account" => 123456789012,
                                        "my_env" => "my-test-env1",
                                        "test_encrypted" => {
                                          "$ssm" => {
                                            "region" => "region",
                                            "encrypted" => "encrypted_value"
                                          }
                                        },
                                        "database.host" => "my.database.{domain}",
                                        "database.port" => 3306 },
                                      "my-test-env2" => {
                                        "foo" => "bar",
                                        "map" => {
                                          "key1" => "notval1",
                                          "key2" => "val2",
                                          "key3" => "{cloud}-{region}",
                                          "key4" => "{domain}"
                                        },
                                        "database.host" => "my.database.{domain}",
                                        "database.port" => 3306 } })
    end

    it "Tests interpolations work for a service" do
      expect(service.interpolate).to eq({
                                          "my-test-env1" => {
                                            "foo" => "bar",
                                            "map" => {
                                              "key1" => "notval1",
                                              "key2" => "val2",
                                              "key3" => "test-cloud-1-us-east-1",
                                              "key4" => "my1.com"
                                            },
                                            "my_account" => 123456789012,
                                            "my_env" => "my-test-env1",
                                            "test_encrypted" => { "$ssm" => { "region" => "region", "encrypted" => "encrypted_value" } },
                                            "database.host" => "my.database.my1.com",
                                            "database.port" => 3306 },
                                          "my-test-env2" => {
                                            "foo" => "bar",
                                            "map" => {
                                              "key1" => "notval1",
                                              "key2" => "val2",
                                              "key3" => "test-cloud-2-eu-central-1",
                                              "key4" => "my2.com"
                                            },
                                            "database.host" => "my.database.my2.com",
                                            "database.port" => 3306 } })
    end

  end
end
