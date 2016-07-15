require 'test_helper'

class CloudxlsTest < Minitest::Test
  def test_defaults
    file = Cloudxls.write("hello,world").save_as("/tmp/foo.xls")
    hsh = Cloudxls.read(File.new(file.path)).to_h
    assert_equal("hello", "world"), hsh.first["rows"][0]
    puts json
  end
end