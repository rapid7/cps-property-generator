Gem::Specification.new do |s|
  s.name = "cps-property-generator"
  s.version = "0.4.3"
  s.summary = "Centralized Property Service json file generator"
  s.description = "Generates json property files from yaml definitions to be served up by CPS."
  s.authors = ["Bryan Call"]
  s.email = "bcall@rapid7.com"
  s.files = Dir.glob("{bin,lib,spec,config}/**/*") + %w[README.md]
  s.homepage = "https://rubygems.org/gems/cps-property-generator"
  s.license = "MIT"
  s.executables = %w[cps-property-generator]
  s.bindir = "bin"
  s.required_ruby_version = ">= 3.0"

  s.add_dependency "activesupport"
  s.add_dependency "aws-sdk-s3"
  s.add_dependency "terminal-table"
  s.add_dependency "thor"
  s.add_dependency "thor-scmversion"
  s.add_dependency "webrick"
  s.add_dependency "rexml"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rubocop"
end
