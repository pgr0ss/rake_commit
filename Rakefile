require "rake/testtask"

task :default => :test

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
end

desc "clean"
task :clean do
  rm_f Dir.glob("*.gem")
end

namespace :gem do
  desc "build the gem"
  task :build => :clean do
    sh "gem build rake_commit.gemspec"
  end
end
