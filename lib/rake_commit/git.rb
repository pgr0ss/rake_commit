require 'shellwords'

module RakeCommit
  class Git

    def initialize(collapse_commits = true, rebase_only = false, incremental = false, prompt_exclusions = [], precommit = nil)
      @collapse_commits = collapse_commits
      @rebase_only = rebase_only
      @incremental = incremental
      @prompt_exclusions = prompt_exclusions
      @precommit = precommit
    end

    def commit
      if @incremental
        incremental_commit
      elsif rebase_in_progress?
        rebase_continue
        RakeCommit::Shell.system("rake")
        push
      else
        if collapse_git_commits?
          return unless collapse_git_commits
        elsif rebase_only?
          add
          incremental_commit unless nothing_to_commit?
          pull_rebase rescue return false
        end
        RakeCommit::Shell.system("rake")
        push
      end
    end

    def rebase_in_progress?
      File.directory?(".git/rebase-merge") || File.directory?(".git/rebase-apply")
    end

    def collapse_git_commits?
      return false unless @collapse_commits
      return true unless merge_commits?
      status
      input = Readline.readline("Do you want to collapse merge commits? (y/n): ").chomp
      input == "y"
    end

    def rebase_only?
      !!@rebase_only
    end

    def rebase_continue
      RakeCommit::Shell.system("git rebase --continue")
    end

    def collapse_git_commits
      RakeCommit::Shell.system(@precommit) unless @precommit.nil?
      add
      temp_commit
      reset_soft
      status
      return if nothing_to_commit?
      incremental_commit
      pull_rebase rescue return false
      return true
    end

    def status
      RakeCommit::Shell.system("git status", false)
    end

    def add
      RakeCommit::Shell.system "git add -A ."
    end

    def incremental_commit
      commit_message = RakeCommit::CommitMessage.new(@prompt_exclusions)
      unless commit_message.author.nil?
        RakeCommit::Shell.system("git config user.name #{Shellwords.shellescape(commit_message.author)}")
      end
      message = [commit_message.feature, commit_message.message].compact.join(" - ")
      RakeCommit::Shell.system("git commit -m #{Shellwords.shellescape(message)}")
    end

    def reset_soft
      raise "Could not determine branch" unless git_branch
      RakeCommit::Shell.system "git reset --soft #{merge_base}"
    end

    def pull_rebase
      RakeCommit::Shell.system "git pull --rebase --stat"
    end

    def push
      RakeCommit::Shell.system "git push origin #{git_branch}"
    end

    def temp_commit
      return if nothing_to_commit?
      RakeCommit::Shell.system "git commit -m 'rake_commit backup commit'"
    end

    def nothing_to_commit?
      status = RakeCommit::Shell.backtick("git status", false)
      status.empty? || status =~ /nothing to commit/m
    end

    def git_branch
      @git_branch ||= begin
        output = RakeCommit::Shell.backtick("git symbolic-ref HEAD")
        output.gsub('refs/heads/', '').strip
      end
    end

    def merge_commits?
      RakeCommit::Shell.backtick("git log #{merge_base}..HEAD") != RakeCommit::Shell.backtick("git log --no-merges #{merge_base}..HEAD")
    end

    def merge_base
      @merge_base ||= RakeCommit::Shell.backtick("git merge-base #{git_branch} origin/#{git_branch}").strip
    end
  end
end
