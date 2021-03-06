require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class PromptLineTest < Test::Unit::TestCase

  def test_puts_newline_if_saved_attribute_does_not_exist
    File.expects(:exists?).with(Dir.tmpdir + "/author.data").returns(false)
    RakeCommit::PromptLine.any_instance.expects(:puts).with("\n")
    RakeCommit::PromptLine.any_instance.expects(:readline).returns("input")
    RakeCommit::PromptLine.new("author").prompt
  end

  def test_puts_last_saved_attribute_if_exists
    File.expects(:exists?).with(Dir.tmpdir + "/author.data").returns(true)
    File.expects(:read).with(Dir.tmpdir + "/author.data").returns("Jane Doe\nJohn Doe\n")
    RakeCommit::PromptLine.any_instance.stubs(:save_history)
    RakeCommit::PromptLine.any_instance.stubs(:readline).returns("input")
    RakeCommit::PromptLine.any_instance.expects(:puts).with("\n")
    RakeCommit::PromptLine.any_instance.expects(:puts).with("previous author: John Doe")
    RakeCommit::PromptLine.new("author").prompt
  end

  def test_saves_new_input_to_disk
    File.expects(:exists?).with(Dir.tmpdir + "/author.data").returns(true)
    File.expects(:read).with(Dir.tmpdir + "/author.data").returns("Jane Doe\nJohn Doe\n")
    RakeCommit::PromptLine.any_instance.stubs(:readline).returns("Jar Jar Binks\n")
    RakeCommit::PromptLine.any_instance.expects(:append_history).with("Jar Jar Binks")
    RakeCommit::PromptLine.new("author").prompt
  end

  def test_skips_prompt_if_attribute_is_in_exclusions
    prompt_line = RakeCommit::PromptLine.new("author", ["author"])
    assert_equal nil, prompt_line.prompt
  end
end
