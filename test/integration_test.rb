require File.expand_path(File.dirname(__FILE__) + "/test_helper")

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

      in_git_repo do
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

      in_git_repo do
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

      in_git_repo do
        Shell.system "yes | ../../../bin/rake_commit"

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 1, log_lines.size
        assert_match /Added Rakefile/, log_lines.first
      end
    end
  end

  def test_collapse_merge_commits
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        Shell.system "git checkout -b br"
        Shell.system "echo 'blah' >> one"
        Shell.system "git add one"
        Shell.system "git commit -m 'commit on branch'"
        Shell.system "git checkout master"
        Shell.system "git merge --no-ff br"

        assert_equal 3, Shell.backtick("git log --pretty=oneline").split("\n").size
        Shell.system "yes | ../../../bin/rake_commit"

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        puts log_lines
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first
        assert_match /Added Rakefile/, log_lines.last
      end
    end
  end

  def test_do_not_collapse_merge_commits
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        Shell.system "git checkout -b br"
        Shell.system "echo 'blah' >> one"
        Shell.system "git add one"
        Shell.system "git commit -m 'commit on branch'"
        Shell.system "git checkout master"
        Shell.system "git merge --no-ff br"

        assert_equal 3, Shell.backtick("git log --pretty=oneline").split("\n").size
        Shell.system "yes | ../../../bin/rake_commit --no-collapse"

        log_lines = Shell.backtick("git log --pretty=oneline").split("\n")
        puts log_lines
        assert_equal 3, log_lines.size
        assert_match /Merge branch 'br'/, log_lines[0]
        assert_match /commit on branch/, log_lines[1]
        assert_match /Added Rakefile/, log_lines[2]
      end
    end
  end

  def create_git_repo
    Shell.system "git init"
    Shell.system "git add Rakefile"
    Shell.system "git commit -m 'Added Rakefile'"
    Shell.system "git checkout -b not_master"
  end

  def in_git_repo(&block)
    Shell.system "git clone file://#{TMP_DIR}/git_repo git_wc"
    Dir.chdir("git_wc") do
      yield
    end
  end
end
