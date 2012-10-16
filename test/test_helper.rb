unless defined?(TEST_HELPER_LOADED)
  TEST_HELPER_LOADED = true

  require "rubygems"
  require "rake"
  Dir.glob(File.dirname(__FILE__) + "/../lib/tasks/**/*.rake").each { |rakefile| load rakefile }
  require File.dirname(__FILE__) + "/../lib/rake_commit"

  require "test/unit"
  require "mocha"

  Test::Unit::TestCase.class_eval do
    def capture_stdout(&block)
      old_stdout, $stdout = $stdout, StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end
  end
end
