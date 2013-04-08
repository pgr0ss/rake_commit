require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class IntegrationTest < Test::Unit::TestCase

  TMP_DIR = File.expand_path(File.dirname(__FILE__) + "/tmp")

  def setup
    FileUtils.mkdir TMP_DIR
    if RakeCommit::Shell.backtick("git config user.name").strip.empty?
      RakeCommit::Shell.system "git config user.name tests"
      RakeCommit::Shell.system "git config user.email tests@example.com"
    end
  end

  def teardown
    FileUtils.rm_r TMP_DIR
  end

  def test_successful_rake_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first

        assert_equal "", RakeCommit::Shell.backtick("git cherry origin")
      end
    end
  end

  def test_unsuccessful_rake_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; raise \"failing test\"; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"

        begin
          RakeCommit::Shell.system "yes | ../../../bin/rake_commit"
          fail
        rescue => e
        end

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first

        unpushed_sha = log_lines.first.gsub(/ .*/, "")

        assert_equal "+ #{unpushed_sha}\n", RakeCommit::Shell.backtick("git cherry origin")
      end
    end
  end

  def test_with_nothing_to_commit_with_git
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 1, log_lines.size
        assert_match /Added Rakefile/, log_lines.first
      end
    end
  end

  def test_collapse_merge_commits
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "git checkout -b br"
        RakeCommit::Shell.system "echo 'blah' >> one"
        RakeCommit::Shell.system "git add one"
        RakeCommit::Shell.system "git commit -m 'commit on branch'"
        RakeCommit::Shell.system "git checkout master"
        RakeCommit::Shell.system "git merge --no-edit --no-ff br"

        assert_equal 3, RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n").size
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
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
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "git checkout -b br"
        RakeCommit::Shell.system "echo 'blah' >> one"
        RakeCommit::Shell.system "git add one"
        RakeCommit::Shell.system "git commit -m 'commit on branch'"
        RakeCommit::Shell.system "git checkout master"
        RakeCommit::Shell.system "git merge --no-edit --no-ff br"

        assert_equal 3, RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n").size
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit --no-collapse"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 3, log_lines.size
        assert_match /Merge branch 'br'/, log_lines[0]
        assert_match /commit on branch/, log_lines[1]
        assert_match /Added Rakefile/, log_lines[2]
      end
    end
  end

  def test_incremental_commit
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "touch Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "git add new_file"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit --incremental"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /y - y/, log_lines.first
      end
    end
  end

  def test_incremental_commit_does_not_automatically_add_files
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "touch Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        fail_lines = RakeCommit::Shell.backtick("yes | ../../../bin/rake_commit --incremental 2>&1", false).split("\n")
        assert_not_nil fail_lines.grep(/nothing added to commit but untracked files present/)
      end
    end
  end

  def test_without_pair_does_not_prompt_for_pair
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "git config user.name someone"
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit --without-prompt=pair"

        log_lines = RakeCommit::Shell.backtick("git log | grep Author").split("\n")
        assert_match /\AAuthor: someone <.*>\z/, log_lines.first
      end
    end
  end

  def test_without_allows_multiple_flags
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "git config user.name someone"
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit --without-prompt=pair --without-prompt=feature"

        log_lines = RakeCommit::Shell.backtick("git log | grep Author").split("\n")
        assert_match /\AAuthor: someone <.*>\z/, log_lines.first
        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_match /\A\w+ y\z/, log_lines.first
      end
    end
  end

  def test_without_feature_does_not_prompt_for_feature
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit --without-prompt=feature"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_match /\A\w+ y\z/, log_lines.first
      end
    end
  end

  def test_with_config_file_to_not_prompt_for_feature_does_not_prompt
    Dir.chdir(TMP_DIR) do
      FileUtils.mkdir "git_repo"
      Dir.chdir("git_repo") do
        RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
        create_git_repo
      end

      in_git_repo do
        RakeCommit::Shell.system "echo '--without-prompt=feature' > .rake_commit"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_match /\A\w+ y\z/, log_lines.first
      end
    end
  end

  def create_git_repo
    RakeCommit::Shell.system "git init"
    RakeCommit::Shell.system "git add Rakefile"
    RakeCommit::Shell.system "git commit -m 'Added Rakefile'"
    RakeCommit::Shell.system "git checkout -b not_master"
    sleep 1 # Ensure that the first commit is at least one second older
  end

  def in_git_repo(&block)
    RakeCommit::Shell.system "git clone file://#{TMP_DIR}/git_repo git_wc"
    Dir.chdir("git_wc") do
      yield
    end
  end
end
