require 'spec_helper'
require_relative '../../lib/generator/config'

module PropertyGenerator
  describe Config do
    subject(:config) {described_class.new(File.expand_path("./spec/resources"))}

    it 'should return the environments' do
      expect(config.environments).to eq(['my-test-env1', 'my-test-env2'])
    end

    it 'should return the accounts' do
      expect(config.accounts).to eq([123456789012, 987654321098])
    end

    #this is gross
    it 'should return the environment configs' do
      expect(config.environment_configs).to eq({'my-test-env1' => {'region' => 'us-east-1',
                                                                   'account' => 123456789012,
                                                                   'interpolations' => {'region' => 'us-east-1',
                                                                                        'cloud' => 'test-cloud-1',
                                                                                        'domain' => 'my1.com'}
                                                                    },
                                               'my-test-env2' => {'region' => 'eu-central-1',
                                                                  'account' => 987654321098,
                                                                  'interpolations' => {'region' => 'eu-central-1',
                                                                                       'cloud' => 'test-cloud-2',
                                                                                       'domain' => 'my2.com'}
                                                                  }
                                               })
    end


  end
end