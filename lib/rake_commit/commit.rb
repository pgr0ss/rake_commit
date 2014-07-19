require 'optparse'
require 'rexml/document'
require 'shellwords'

module RakeCommit
  class Commit
    def git?
      `git rev-parse`
      $?.success?
    end

    def git_svn?
      `git svn info 2> /dev/null`
      $?.success?
    end

    def commit
      options = {
        :collapse_commits => true,
        :incremental => false,
        :prompt_exclusions => []
      }

      if File.exists?(".rake_commit")
        defaults = File.read(".rake_commit")
        options = parse_options(Shellwords.split(defaults), options)
      end
      options = parse_options(ARGV, options)

      if git_svn?
        RakeCommit::GitSvn.new(options[:prompt_exclusions]).commit
      elsif git?
        RakeCommit::Git.new(options[:collapse_commits], options[:rebase_only], options[:incremental], options[:prompt_exclusions], options[:precommit]).commit
      else
        RakeCommit::Svn.new(options[:prompt_exclusions]).commit
      end
    end

    def parse_options(args, options)
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: rake_commit [OPTIONS]"
        opts.on("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.on("-i", "--incremental", "Prompt for a local commit") do
          options[:incremental] = true
        end
        opts.on("-n", "--no-collapse", "Run the build and push without pulling or collapsing commits") do
          options[:collapse_commits] = false
        end
        opts.on("-r", "--rebase-only", "Pull and rebase (without collapsing existing commits), then build and push") do
          options[:collapse_commits] = false
          options[:rebase_only] = true
        end
        opts.on("-w", "--without-prompt PROMPT", "Skips the given prompt (author, feature, message)") do |prompt_exclusion|
          options[:prompt_exclusions] << prompt_exclusion
        end
        opts.on("-p", "--precommit SCRIPT", "command to run before commiting changes") do |command|
          options[:precommit] = command
        end
      end

      parser.parse(args)
      options
    end
  end
end
