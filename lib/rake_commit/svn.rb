require 'fileutils'

module RakeCommit
  class Svn

    def initialize(prompt_exclusions = [], precommit = nil)
      @prompt_exclusions = prompt_exclusions
      @precommit = precommit
    end

    def commit
      if files_to_check_in?
        message = RakeCommit::CommitMessage.new(@prompt_exclusions).joined_message_with_author
        RakeCommit::Shell.system(@precommit) unless @precommit.nil?
        add
        delete
        up
        RakeCommit::Shell.system "rake"
        output = RakeCommit::Shell.backtick "#{commit_command(message)}"
        puts output
        revision = output.match(/Committed revision (\d+)\./)[1]
      else
        puts "Nothing to commit"
      end
    end

    def commit_command(message)
      "svn ci -m #{message.inspect}"
    end

    def files_to_check_in?
      RakeCommit::Shell.backtick("svn st --ignore-externals").split("\n").reject {|line| line[0,1] == "X"}.any?
    end

    def status
      RakeCommit::Shell.system "svn st"
    end

    def up
      output = RakeCommit::Shell.backtick "svn up"
      puts output
      output.split("\n").each do |line|
        raise "SVN conflict detected. Please resolve conflicts before proceeding." if line[0,1] == "C"
      end
    end

    def add
      RakeCommit::Shell.backtick("svn st").split("\n").each do |line|
        if new_file?(line) && !svn_conflict_file?(line)
          file = line[7..-1].strip
          RakeCommit::Shell.system "svn add #{file.inspect}"
        end
      end
    end

    def new_file?(line)
      line[0,1] == "?"
    end

    def svn_conflict_file?(line)
      line =~ /\.r\d+$/ || line =~ /\.mine$/
    end

    def delete
      RakeCommit::Shell.backtick("svn st").split("\n").each do |line|
        if line[0,1] == "!"
          file = line[7..-1].strip
          RakeCommit::Shell.backtick "svn up #{file.inspect} && svn rm #{file.inspect}"
          puts %[removed #{file}]
        end
      end
    end

    def revert_all
      RakeCommit::Shell.system "svn revert -R ."
      RakeCommit::Shell.backtick("svn st").split("\n").each do |line|
        next unless line[0,1] == '?'
        filename = line[1..-1].strip
        puts "removed #{filename}"
        FileUtils.rm_r filename
      end
    end
  end
end
