require 'test_helper'

class CloudxlsTest < Minitest::Test
  def test_defaults
    Cloudxls.api_key = "test_foo"
    file = Cloudxls.write(csv: "hello,world").save_as("/tmp/foo.xls")
    hash = Cloudxls.read(excel: File.new(file.path)).to_h
    assert_equal ["hello", "world"], hash.first["rows"][0]
  end

  def test_defaults
    Cloudxls.api_key = "test_foo"
    file = Cloudxls.write(csv: File.new("test/test.csv")).save_as("/tmp/foo.xls")
    hash = Cloudxls.read(excel: File.new(file.path)).to_h
    assert_equal ["hello", "world"], hash.first["rows"][0]
  end

  def test_accessors
    Cloudxls.api_key = "test_foo"
    assert_equal "test_foo", Cloudxls.api_key

    Cloudxls.api_base = "sandbox.cloudxls.com"
    assert_equal "sandbox.cloudxls.com", Cloudxls.api_base
  end

  def test_test_api_keys
    Cloudxls::WriteRequest.new(api_key: "test_foobar")
  end
end