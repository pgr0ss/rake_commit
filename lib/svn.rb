require 'fileutils'

class Svn

  def initialize(prompt_exclusions = [])
    @prompt_exclusions = prompt_exclusions
  end

  def commit
    if files_to_check_in?
      message = CommitMessage.new(@prompt_exclusions).joined_message
      add
      delete
      up
      Shell.system "rake"
      output = Shell.backtick "#{commit_command(message)}"
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
    Shell.backtick("svn st --ignore-externals").split("\n").reject {|line| line[0,1] == "X"}.any?
  end

  def status
    Shell.system "svn st"
  end

  def up
    output = Shell.backtick "svn up"
    puts output
    output.split("\n").each do |line|
      raise "SVN conflict detected. Please resolve conflicts before proceeding." if line[0,1] == "C"
    end
  end

  def add
    Shell.backtick("svn st").split("\n").each do |line|
      if new_file?(line) && !svn_conflict_file?(line)
        file = line[7..-1].strip
        Shell.system "svn add #{file.inspect}"
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
    Shell.backtick("svn st").split("\n").each do |line|
      if line[0,1] == "!"
        file = line[7..-1].strip
        Shell.backtick "svn up #{file.inspect} && svn rm #{file.inspect}"
        puts %[removed #{file}]
      end
    end
  end

  def revert_all
    Shell.system "svn revert -R ."
    Shell.backtick("svn st").split("\n").each do |line|
      next unless line[0,1] == '?'
      filename = line[1..-1].strip
      puts "removed #{filename}"
      FileUtils.rm_r filename
    end
  end
end
