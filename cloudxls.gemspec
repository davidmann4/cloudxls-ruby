# -*- encoding: utf-8 -*-
$LOAD_PATH.push(File.expand_path "../lib", __FILE__)
require "cloudxls/version"

Gem::Specification.new do |gem|
  gem.name          = "cloudxls"
  gem.authors       = ["Sebastian Burkhard"]
  gem.email         = ["hello@cloudxls.com"]
  gem.description   = %q{Ruby wrapper to read and write Excel through the cloudxls API.}
  gem.summary       = %q{Ruby wrapper to read and write Excel through the cloudxls API.}
  gem.homepage      = "https://cloudxls.com"
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ["lib"]

  gem.version       = Cloudxls::VERSION

  gem.add_dependency('multipart-post', '~> 2.0.0')

  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"
end
