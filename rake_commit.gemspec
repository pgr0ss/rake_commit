require 'rake'

Gem::Specification.new do |s|
  s.name = "rake_commit"
  s.summary = "A gem which helps with checking in code"
  s.description = "See http://github.com/pgr0ss/rake_commit"
  s.license = 'MIT'
  s.version = "1.3.0"
  s.author = "Paul Gross"
  s.email = "pgross@gmail.com"
  s.homepage = "http://github.com/pgr0ss/rake_commit"
  s.rubyforge_project = "rake_commit"
  s.files = FileList["README.md", "Rakefile", "{bin,lib,spec}/**/*.rb"]
  s.bindir = 'bin'
  s.executables = ['rake_commit']

  s.add_runtime_dependency 'rake', '>= 12.3.3', '< 13'
  s.add_runtime_dependency 'word_wrap', '~> 1.0'

  s.add_development_dependency 'mocha', '0.9.12'
  s.add_development_dependency 'test-unit', '~> 3.1', '>= 3.1.5'
end
