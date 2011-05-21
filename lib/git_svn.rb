class GitSvn
  def initialize(prompt_exclusions = [])
    @prompt_exclusions = prompt_exclusions
  end

  def commit
    git = Git.new
    git.add
    git.status
    git_svn_commit_with_message
    rebase
    Shell.system "rake"
    dcommit
  end

  def git_svn_commit_with_message
    message = CommitMessage.new(@prompt_exclusions).joined_message
    Shell.system "git commit -m #{message.inspect}"
  end

  def rebase
    Shell.system "git svn rebase"
  end

  def dcommit
    Shell.system "git svn dcommit"
  end
end
