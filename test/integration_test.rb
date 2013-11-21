require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class IntegrationTest < Test::Unit::TestCase

  TMP_DIR = File.expand_path(File.dirname(__FILE__) + "/tmp")

  def setup
    FileUtils.mkdir TMP_DIR
    if RakeCommit::Shell.backtick("git config --global user.name || true").strip.empty?
      RakeCommit::Shell.system "git config --global user.name tests"
      RakeCommit::Shell.system "git config --global user.email tests@example.com"
    end
  end

  def teardown
    FileUtils.rm_r TMP_DIR
  end

  def test_successful_rake_commit_with_git
    Dir.chdir(TMP_DIR) do
      create_git_repo

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
      create_git_repo
      Dir.chdir("git_repo_wc") do
        RakeCommit::Shell.system "echo 'task :default do; raise \"failing test\"; end' > Rakefile"
        RakeCommit::Shell.system "git commit -a -m 'Changed Rakefile to fail'"
        RakeCommit::Shell.system "git push origin master"
      end

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"

        begin
          RakeCommit::Shell.system "yes | ../../../bin/rake_commit"
          fail
        rescue => e
        end

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 3, log_lines.size
        assert_match /y - y/, log_lines.first

        unpushed_sha = log_lines.first.gsub(/ .*/, "")

        assert_equal "+ #{unpushed_sha}\n", RakeCommit::Shell.backtick("git cherry origin")
      end
    end
  end

  def test_with_nothing_to_commit_with_git
    Dir.chdir(TMP_DIR) do
      create_git_repo

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
      create_git_repo

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
      create_git_repo

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
      create_git_repo

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
      create_git_repo

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        fail_lines = RakeCommit::Shell.backtick("yes | ../../../bin/rake_commit --incremental 2>&1", false).split("\n")
        assert_not_nil fail_lines.grep(/nothing added to commit but untracked files present/)
      end
    end
  end

  def test_without_pair_does_not_prompt_for_pair
    Dir.chdir(TMP_DIR) do
      create_git_repo

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
      create_git_repo

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
      create_git_repo

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
      create_git_repo

      in_git_repo do
        RakeCommit::Shell.system "echo '--without-prompt=feature' > .rake_commit"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_match /\A\w+ y\z/, log_lines.first
      end
    end
  end


  def test_rake_commit_pulls_and_rebases
    Dir.chdir(TMP_DIR) do
      create_git_repo

      FileUtils.mkdir "collaborator_repo"
      in_git_repo("collaborator_repo") do
        RakeCommit::Shell.system "touch foo.bar"
        RakeCommit::Shell.system "git add ."
        RakeCommit::Shell.system "git commit -m 'Added foo.bar'"
      end

      in_git_repo do
        RakeCommit::Shell.system "git checkout master"
      end

      Dir.chdir("collaborator_repo") do
        RakeCommit::Shell.system "git push origin master"
      end

      Dir.chdir("git_wc") do
        RakeCommit::Shell.system "touch bar.baz"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"
        files = RakeCommit::Shell.backtick("git ls-files")
        assert files.include?("foo.bar")
      end
    end
  end

  def test_rake_commit_recovers_from_failed_rebase
    Dir.chdir(TMP_DIR) do
      create_git_repo

      FileUtils.mkdir "collaborator_repo"
      in_git_repo("collaborator_repo") do
        RakeCommit::Shell.system "echo 'guaranteed' >> foo.bar"
        RakeCommit::Shell.system "git add ."
        RakeCommit::Shell.system "git commit -m 'Added foo.bar'"
      end

      in_git_repo do
        RakeCommit::Shell.system "git checkout master"
      end

      Dir.chdir("collaborator_repo") do
        RakeCommit::Shell.system "git push origin master"
      end

      Dir.chdir("git_wc") do
        RakeCommit::Shell.system "echo 'conflict' >> foo.bar"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"
        RakeCommit::Shell.system "echo 'guaranteed conflict' > foo.bar"
        RakeCommit::Shell.system "git add foo.bar"
        RakeCommit::Shell.system "yes | ../../../bin/rake_commit"
      end

      Dir.chdir("git_repo_wc") do
        RakeCommit::Shell.system "git pull"
        file_contents = RakeCommit::Shell.backtick "cat foo.bar"
        assert_equal "guaranteed conflict\n", file_contents
      end
    end
  end

  def test_allows_specifying_precommit_task
    Dir.chdir(TMP_DIR) do
      create_git_repo

      in_git_repo do
        output = RakeCommit::Shell.backtick "yes | ../../../bin/rake_commit --precommit 'echo hi'"
        assert_equal 0, $CHILD_STATUS
        output_lines = output.split("\n")
        assert_equal "hi", output_lines.first
      end
    end
  end

  def test_allows_specifying_precommit_task_in_dotfile
    Dir.chdir(TMP_DIR) do
      create_git_repo

      in_git_repo do
        RakeCommit::Shell.system %%echo '--precommit "echo hi"' > .rake_commit%
        output = RakeCommit::Shell.backtick "yes | ../../../bin/rake_commit"
        assert_equal 0, $CHILD_STATUS
        output_lines = output.split("\n")
        assert_equal "hi", output_lines.first
      end
    end
  end

  def test_escape_shell_characters
    Dir.chdir(TMP_DIR) do
      create_git_repo

      in_git_repo do
        RakeCommit::Shell.system "touch new_file"
        RakeCommit::Shell.system "yes '$1' | ../../../bin/rake_commit"

        log_lines = RakeCommit::Shell.backtick("git log --pretty=oneline").split("\n")
        assert_equal 2, log_lines.size
        assert_match /\$1 - \$1/, log_lines.first

        author_line = RakeCommit::Shell.backtick("git log -1 | grep Author")
        assert_match /Author: \$1/, author_line
      end
    end
  end


  def create_git_repo
    FileUtils.mkdir "git_repo"
    Dir.chdir("git_repo") do
      RakeCommit::Shell.system "git init --bare"
    end

    in_git_repo("git_repo_wc") do
      RakeCommit::Shell.system "git init"
      RakeCommit::Shell.system "echo 'task :default do; end' >> Rakefile"
      RakeCommit::Shell.system "git add Rakefile"
      RakeCommit::Shell.system "git commit -m 'Added Rakefile'"
      RakeCommit::Shell.system "git push origin master"
    end
    sleep 1 # Ensure that the first commit is at least one second older
  end

  def in_git_repo(repo_name="git_wc", &block)
    RakeCommit::Shell.system "git clone file://#{TMP_DIR}/git_repo #{repo_name}"
    Dir.chdir(repo_name) do
      yield
    end
  end
end
