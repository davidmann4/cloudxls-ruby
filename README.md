# Installation

    gem install cloudxls

Or in your Gemfile

    gem 'cloudxls', '~> 2.0.0-beta'

# Examples

## Set-up API-Keys

Register on https://www.cloudxls.com to get an API key.

Either set the ENV variable `CLOUDXLS_API_KEY` or manually using `Cloudxls.api_key#=`

```ruby
Cloudxls.api_key = "YOUR-API-KEY"
```

### Sandbox

If you use a sandbox API key (starting with 'test_') the client sends requests
to the sandbox test API.

## Read-API

Send an xls or xlsx file using the `Cloudxls#read` method. `#to_h` will start the request and parse the json into a ruby hash.

```ruby
data = Cloudxls.read(File.new("/path/to/my-excel.xls")).to_h
```

Output

```json
[
  {
    "name" : "Sheet1",
    "rows" : [
      ["hello", "world"],
      ["lorem", "ipsum"]
    ]
  }
]
```

Save json to a file

```ruby
Cloudxls.read(File.new("/path/to/my-excel.xls")).save_as("output.json")
```

Or access the response_stream directly

```ruby
io = File.new("output.json", "w")
Cloudxls.read(File.new("/path/to/my-excel.xls")).each do |chunk|
  io.write chunk
end
io.close
```

## Write-API

Write a xls file with a single sheet.

```ruby
csv_string = "hello,world\nfoo,bar"

Cloudxls.write(csv_string)
  .save_as("/tmp/hello-world.xls")
```

With options:

```ruby
req = Cloudxls.write(csv_string, {
  offset: "B2",
  sheet_name: "Data"
})
req.save_as("/tmp/hello-world.xls")
```

Multiple sheets:

```ruby
Cloudxls.write(csv_string)
  .add_data("more,data")
  .add_data("more,data", sheet_name: "foobar")
  .save_as("/tmp/hello-world.xls")
```

Append data to a target file (xls or xlsx)

```ruby
Cloudxls.write(csv_string)
  .add_data("more,data")
  .add_data("more,data", sheet_name: "foobar")
  .add_target(File.new("/path/to/my-file.xls"))
  .save_as("/tmp/hello-world.xls")
```

## Useage in Rails

The most efficient way is to directly stream the cloudxls response to the client.
Assign the result of a `#write` or `#read` call to the `response_body`.

```ruby
def index
  headers["Content-Type"] = "application/vnd.ms-excel"
  headers["Content-disposition"] = "attachment; filename=users.xls"

  self.response_body = Cloudxls.write(User.all.to_csv)
end
```
