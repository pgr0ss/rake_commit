require File.expand_path(File.dirname(__FILE__) + "/test_helper")

class PromptLineTest < Test::Unit::TestCase

  def test_message_puts_newline_if_saved_attribute_does_not_exist
    File.expects(:exists?).with(Dir.tmpdir + "/pair.data").returns(false)
    PromptLine.any_instance.expects(:puts).with("\n")
    assert_equal "pair: ", PromptLine.new("pair").message
  end

  def test_message_puts_saved_attribute_if_exists
    File.expects(:exists?).with(Dir.tmpdir + "/pair.data").returns(true)
    File.expects(:read).with(Dir.tmpdir + "/pair.data").returns("John Doe")
    PromptLine.any_instance.expects(:puts).with("\nprevious pair: John Doe\n")
    assert_equal "pair: ", PromptLine.new("pair").message
  end

  def test_save_will_save_entered_value_to_disk
    File.expects(:open).with(Dir.tmpdir + "/feature.data", "w").yields(file = mock)
    file.expects(:write).with("card 100")
    PromptLine.new("feature").save("card 100")
  end
end
