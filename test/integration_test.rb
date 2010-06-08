require File.dirname(__FILE__) + "/test_helper"

class IntegrationTest < Test::Unit::TestCase

  TMP_DIR = File.expand_path(File.dirname(__FILE__) + "/tmp")

  def setup
    FileUtils.mkdir TMP_DIR
  end

  def teardown
    FileUtils.rm_r TMP_DIR
  end

  def test_successful_rake_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      Shell.system "git clone file://#{TMP_DIR}/git_repo git_wc"

      Dir.chdir("git_wc") do
        Shell.system "touch new_file"
        Shell.system "yes | ../../../bin/rake_commit"

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first

        assert_equal "", Shell.backtick("git cherry origin")
      end
    end
  end

  def test_unsuccessful_rake_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        Shell.system "echo 'task :default do; raise \"failing test\"; end' >> Rakefile"
        create_git_repo
      end

      Shell.system "git clone file://#{TMP_DIR}/git_repo git_wc"

      Dir.chdir("git_wc") do
        Shell.system "touch new_file"

        begin
          Shell.system "yes | ../../../bin/rake_commit"
          fail
        rescue => e
        end

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first

        unpushed_sha = log_lines.first.gsub(/ .*/, "")

        assert_equal "+ #{unpushed_sha}\n", Shell.backtick("git cherry origin")
      end
    end
  end

  def test_with_nothing_to_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      Shell.system "git clone file://#{TMP_DIR}/git_repo git_wc"

      Dir.chdir("git_wc") do
        Shell.system "yes | ../../../bin/rake_commit"

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 1, log_lines.size
        assert_match /Added Rakefile/, log_lines.first
      end
    end
  end

  def create_git_repo
    Shell.system "git init"
    Shell.system "git add Rakefile"
    Shell.system "git commit -m 'Added Rakefile'"
    Shell.system "git checkout -b not_master"
  end
end
