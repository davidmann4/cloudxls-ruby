require 'test_helper'

class CloudxlsTest < Minitest::Test
  def test_defaults
    Cloudxls.api_key = "test_foo"
    file = Cloudxls.write(csv: "hello,world").save_as("/tmp/foo.xls")
    hash = Cloudxls.read(excel: File.new(file.path)).to_h
    assert_equal ["hello", "world"], hash.first["rows"][0]
  end
end