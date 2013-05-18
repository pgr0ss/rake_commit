require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class PromptLineTest < Test::Unit::TestCase

  def test_message_puts_newline_if_saved_attribute_does_not_exist
    RakeCommit::PromptHistory.any_instance.expects(:previous_input).returns(nil)
    RakeCommit::PromptLine.any_instance.expects(:puts).with("\n")
    assert_equal "pair: ", RakeCommit::PromptLine.new("pair").message
  end

  def test_message_puts_saved_attribute_if_exists
    RakeCommit::PromptHistory.any_instance.expects(:previous_input).returns("John Doe")
    RakeCommit::PromptLine.any_instance.expects(:puts).with("\nprevious pair: John Doe\n")
    assert_equal "pair: ", RakeCommit::PromptLine.new("pair").message
  end

  def test_skips_prompt_if_attribute_is_in_exclusions
    prompt_line = RakeCommit::PromptLine.new("pair", ["pair"])
    assert_equal nil, prompt_line.prompt
  end
end
