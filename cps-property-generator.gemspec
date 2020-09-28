Gem::Specification.new do |s|
  s.name        = 'cps-property-generator'
  s.version     = '0.2.11'
  s.date        = '2018-07-12'
  s.summary     = "Centralized Property Service json file generator "
  s.description = "Generates json property files from yaml definitions to be served up by CPS."
  s.authors     = ["Bryan Call"]
  s.email       = 'bcall@rapid7.com'
  s.files       =  Dir.glob("{bin,lib,spec,config}/**/*") + %w(README.md)
  s.homepage    =
      'http://rubygems.org/gems/cps-property-generator'
  s.license       = 'MIT'
  s.executables = %w(cps-property-generator)
  s.bindir = 'bin'

  s.add_dependency 'aws-sdk-s3', '~> 1.0.0.rc2'
  s.add_dependency 'thor'
  s.add_dependency 'activesupport', '~> 4.2.11.1'
  s.add_dependency 'terminal-table'
  s.add_dependency 'thor-scmversion'

  s.add_development_dependency 'rspec'
end
