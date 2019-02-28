lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mara/version'

Gem::Specification.new do |spec|
  spec.name          = 'mara'
  spec.version       = Mara::VERSION
  spec.authors       = ['Maddie Schipper']
  spec.email         = ['me@maddiesch.com']

  spec.summary       = 'DynamoDB Client Wrapper'
  spec.description   = 'DynamoDB Client Wrapper'
  spec.homepage      = 'https://github.com/maddiesch/mara'
  spec.license       = 'MIT'

  spec.files         = Dir['{app,config,db,lib}/**/*', 'Rakefile', 'README.md']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel',      '>= 5.0.0', '< 6'
  spec.add_dependency 'aws-sdk-dynamodb', '>= 1.8.0', '< 2'

  spec.add_development_dependency 'bundler', '>= 1.17', '< 3'
  spec.add_development_dependency 'pry',     '~> 0.10'
  spec.add_development_dependency 'rake',    '~> 10.0'
  spec.add_development_dependency 'rspec',   '~> 3.8'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
