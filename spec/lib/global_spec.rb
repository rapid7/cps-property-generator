require 'spec_helper'
require_relative '../../lib/generator/globals'
require_relative '../../lib/generator/config'

module PropertyGenerator
  describe Globals do
    subject(:config) { PropertyGenerator::Config.new(File.expand_path('./spec/resources')) }

    subject(:global) { described_class.new(File.expand_path('./spec/resources'), config) }

    it 'should read the main global file' do
      expect(global.get_main_global).to eq({
                                             'foo' => 'bar',
                                             'map' => {
                                               'key1' => 'val1',
                                               'key2' => 'val2',
                                               'key4' => '{domain}'
                                             }
                                           })
    end

    it 'should read the account globals' do
      expect(global.get_account_globals).to eq({
                                                 123456789012 => {
                                                   'my_account' => 123456789012
                                                 }
                                               })
    end

    it 'should read the environment globals' do
      expect(global.get_environment_globals).to eq({
                                                     123456789012 => {
                                                       'my-test-env1' => {
                                                         'my_env' => 'my-test-env1',
                                                         'test_encrypted' => {
                                                           '$ssm' => {
                                                             'region' => 'region',
                                                             'encrypted' => 'encrypted_value'
                                                           }
                                                         }
                                                       }
                                                     }
                                                   })
    end

    it 'should condense the globals accurately' do
      expect(global.condense_globals).to eq({
                                              'my-test-env1' => {
                                                'foo' => 'bar',
                                                'map' => {
                                                  'key1' => 'val1',
                                                  'key2' => 'val2',
                                                  'key4' => '{domain}'
                                                },
                                                'my_account' => 123456789012,
                                                'my_env' => 'my-test-env1',
                                                'test_encrypted' => {
                                                  '$ssm' => {
                                                    'region' => 'region',
                                                    'encrypted' => 'encrypted_value'
                                                  }
                                                }
                                              },
                                              'my-test-env2' => {
                                                'foo' => 'bar',
                                                'map' => {
                                                  'key1' => 'val1',
                                                  'key2' => 'val2',
                                                  'key4' => '{domain}'
                                                }
                                              }
                                            })
    end
  end
end
