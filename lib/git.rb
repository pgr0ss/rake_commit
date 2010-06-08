class Git
  def commit
    collapse_git_commits if collapse_git_commits?

    Shell.system("rake")

    if ok_to_check_in?
      push
    end
  end

  def collapse_git_commits?
    return true unless merge_commits?
    status
    input = Readline.readline("Do you want to collapse merge commits? (y/n): ").chomp
    input == "y"
  end

  def collapse_git_commits
    add
    temp_commit
    reset_soft
    status
    return if nothing_to_commit?
    commit_message = CommitMessage.new
    Shell.system("git config user.name #{commit_message.pair.inspect}")
    message = "#{commit_message.feature} - #{commit_message.message}"
    Shell.system("git commit -m #{message.inspect}")
    pull_rebase
  end

  def status
    Shell.system "git status"
  end

  def add
    Shell.system "git add -A ."
  end

  def reset_soft
    raise "Could not determine branch" unless git_branch
    Shell.system "git reset --soft #{merge_base}"
  end

  def pull_rebase
    Shell.system "git pull --rebase"
  end

  def push
    Shell.system "git push origin #{git_branch}"
  end

  def temp_commit
    return if nothing_to_commit?
    Shell.system "git commit -m 'rake_commit backup commit'"
  end

  def nothing_to_commit?
    Shell.backtick("git status") =~ /nothing to commit/m
  end

  def git_branch
    @git_branch ||= begin
      output = Shell.backtick("git symbolic-ref HEAD")
      output.gsub('refs/heads/', '').strip
    end
  end

  def merge_commits?
    Shell.backtick("git log #{merge_base}..HEAD") != Shell.backtick("git log --no-merges #{merge_base}..HEAD")
  end

  def merge_base
    @merge_base ||= Shell.backtick("git merge-base #{git_branch} origin/#{git_branch}").strip
  end
end
