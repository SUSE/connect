require File.expand_path('../lib/suse/connect/version', __FILE__)

Gem::Specification.new do |gem|

  gem.name        = 'suse-connect'
  gem.version     = SUSE::Connect::VERSION
  gem.date        = Date.today.to_s
  gem.summary     = 'SUSE Connect utility to register system at scc.suse.com'
  gem.description = 'This tool used by a customer to register his system via customer center'
  gem.authors     = ['SUSE Customer Center Team']
  gem.license     = 'LGPL-2.0'
  gem.email       = 'happy-customer@suse.de'
  gem.homepage    = 'http://github.com/SUSE/connect'
  gem.files       = Dir['{bin,lib,test}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split('\0')

  gem.add_development_dependency 'rspec', '~> 2.14'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock', '~> 1.15'
  gem.add_development_dependency 'aruba'

end
