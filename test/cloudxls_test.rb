require 'test_helper'

class CloudxlsTest < Minitest::Test
  def test_defaults
    Cloudxls.api_key = "test_foo"
    assert_equal "test_foo", Cloudxls.api_key
    file = Cloudxls.write("hello,world").save_as("/tmp/foo.xls")

    hsh = Cloudxls.read(File.new(file.path)).to_h
    assert_equal ["hello", "world"], hsh.first["rows"][0]
  end
end