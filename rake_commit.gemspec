require 'rake'

Gem::Specification.new do |s|
  s.name = "rake_commit"
  s.summary = "A gem which helps with checking in code"
  s.description = "See http://github.com/pgr0ss/rake_commit"
  s.version = "0.13.1"
  s.author = "Paul Gross"
  s.email = "pgross@gmail.com"
  s.homepage = "http://github.com/pgr0ss/rake_commit"
  s.rubyforge_project = "rake_commit"
  s.files = FileList["README.rdoc", "Rakefile", "{bin,lib,spec}/**/*.rb"]
  s.bindir = 'bin'
  s.executables = ['rake_commit']
end
