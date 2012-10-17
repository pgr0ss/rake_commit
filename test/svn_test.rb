require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class SvnTest < Test::Unit::TestCase

  def test_st_displays_svn_status
    RakeCommit::Shell.expects("system").with("svn st")
    RakeCommit::Svn.new.status
  end

  def test_up_displays_output_from_svn
    RakeCommit::Shell.stubs("backtick").with("svn up").returns("output from svn up")
    output = capture_stdout do
      RakeCommit::Svn.new.up
    end
    assert_equal "output from svn up\n", output
  end

  def test_up_raises_if_there_are_conflicts
    RakeCommit::Shell.stubs("backtick").with("svn up").returns("C      a_conflicted_file\n")
    begin
      capture_stdout do
        RakeCommit::Svn.new.up
      end
    rescue => exception
    end
    assert_not_nil exception
    assert_equal "SVN conflict detected. Please resolve conflicts before proceeding.", exception.message
  end

  def test_add_adds_new_files_and_displays_message
    RakeCommit::Shell.stubs("backtick").with("svn st").returns("?      new_file\nM      modified_file\n?      new_file2\n")
    RakeCommit::Shell.expects("system").with("svn add \"new_file\"")
    RakeCommit::Shell.expects("system").with("svn add \"new_file2\"")
    RakeCommit::Svn.new.add
  end

  def test_add_adds_files_with_special_characters_in_them
    RakeCommit::Shell.stubs("backtick").with("svn st").returns("?       leading_space\n?      x\"x\n?      y?y\n?      z'z\n")
    RakeCommit::Shell.expects("system").with(%Q(svn add "leading_space"))
    RakeCommit::Shell.expects("system").with(%Q(svn add "x\\\"x"))
    RakeCommit::Shell.expects("system").with(%Q(svn add "y?y"))
    RakeCommit::Shell.expects("system").with(%Q(svn add "z'z"))
    RakeCommit::Svn.new.add
  end

  def test_add_does_not_add_svn_conflict_files
    RakeCommit::Shell.expects("system").never
    RakeCommit::Shell.stubs("backtick").with("svn st").returns("?      new_file.r342\n?      new_file.mine")
    RakeCommit::Svn.new.add
  end

  def test_delete_removes_deleted_files_and_displays_message
    RakeCommit::Shell.stubs("backtick").with("svn st").returns("!      removed_file\n?      new_file\n!      removed_file2\n")
    RakeCommit::Shell.expects("backtick").with("svn up \"removed_file\" && svn rm \"removed_file\"")
    RakeCommit::Shell.expects("backtick").with("svn up \"removed_file2\" && svn rm \"removed_file2\"")
    output = capture_stdout do
      RakeCommit::Svn.new.delete
    end
    assert_equal "removed removed_file\nremoved removed_file2\n", output
  end

  def test_revert_all_calls_svn_revert_and_then_removes_all_new_files_and_directories
    RakeCommit::Shell.expects("system").with('svn revert -R .')
    RakeCommit::Shell.expects("backtick").with("svn st").returns("?    some_file.rb\n?    a directory")
    FileUtils.expects(:rm_r).with("some_file.rb")
    FileUtils.expects(:rm_r).with("a directory")
    capture_stdout do
      RakeCommit::Svn.new.revert_all
    end
  end
end
