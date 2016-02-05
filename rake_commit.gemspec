require 'rake'

Gem::Specification.new do |s|
  s.name = "rake_commit"
  s.summary = "A gem which helps with checking in code"
  s.description = "See http://github.com/pgr0ss/rake_commit"
  s.license = 'MIT'
  s.version = "1.2.0"
  s.author = "Paul Gross"
  s.email = "pgross@gmail.com"
  s.homepage = "http://github.com/pgr0ss/rake_commit"
  s.rubyforge_project = "rake_commit"
  s.files = FileList["README.md", "Rakefile", "{bin,lib,spec}/**/*.rb"]
  s.bindir = 'bin'
  s.executables = ['rake_commit']

  s.add_runtime_dependency 'rake', '>= 0.9.2.2', '< 11'

  s.add_development_dependency 'mocha', '0.9.12'
  s.add_development_dependency 'test-unit'
end
