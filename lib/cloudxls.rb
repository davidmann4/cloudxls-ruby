require 'openssl'
require 'json'
require 'net/http'
require 'net/http/post/multipart'


class Cloudxls
  class ApiError < Exception
  end

  @api_key      = ENV.fetch("CLOUDXLS_API_KEY", nil)
  @api_base     = ENV.fetch("CLOUDXLS_API_BASE", "api.cloudxls.com")
  @sandbox_base = "sandbox.cloudxls.com"
  @api_version  = "v2".freeze

  class << self
    attr_accessor :api_key,
                  :api_version,
                  :api_base,
                  :sandbox_base,
                  :port

    def client_options
      {
        api_key: self.api_key,
        api_version: self.api_version,
        api_base: self.api_base,
        port: 443
      }
    end

    # Initializes a Write request
    #
    # @param [Hash] params request parameters as
    # @return [WriteRequest] write request object
    #
    def write(params = nil)
      WriteRequest.new(client_options).add_data(params)
    end

    # Initializes a Read request
    #
    # @param [Hash] params request parameters as
    # @return [WriteRequest] write request object
    #
    def read(params = nil)
      ReadRequest.new(client_options).add_data(params)
    end
  end

  module BaseRequest
    def initialize(client_options = nil)
      @post_data = []

      @finished  = false
      @client_options = client_options || Cloudxls.client_options
    end

    def api_key
      key = client_options[:api_key]
      if key.nil?
        raise "api_key is nil. Configure using CLOUDXLS_API_KEY ENV variable or Cloudxls.api_key = ..."
      end
      key
    end

    # Is Api Key for testing/sandbox only?
    #
    # @return [Boolean] write request object
    #
    def test_key?
      api_key.to_s.downcase.start_with?("test")
    end

    def api_base
      if test_key?
        Cloudxls.sandbox_base
      else
        client_options[:api_base]
      end
    end

    # Internal. Starts the request.
    #
    def start(&block)
      Net::HTTP.start(api_base, client_options[:port], use_ssl: true, &block)
    end

    def path_to(path)
      "/#{client_options[:api_version]}/#{path}"
    end

    # Alias for #each
    #
    def data
      each
    end

    # Writes to IO object
    #
    # @params [IO, #write] io
    # @returns [IO]
    #
    def write_to(io)
      each do |chunk|
        io.write chunk
      end
      io
    ensure
      io.close
    end

    # Write response to file
    #
    # @params [String] path
    # @returns [File]
    #
    def save_as(path)
      write_to File.open(path, 'wb')
    end

    # Starts request and yields response to block
    #
    # @params [String] path
    #
    def each(&block)
      raise "#{self.class.name} already executed" if @finished

      start do |http|
        request = Net::HTTP::Post::Multipart.new(self.path, @post_data)
        request.basic_auth api_key, ""
        request['User-Agent'] = "cloudxls-ruby #{Cloudxls::VERSION}"

        if block_given?
          http.request(request) do |response|
            if Net::HTTPSuccess === response
              response.read_body(&block)
            else
              raise ApiError.new("#{response.code} #{response.class.name.to_s}: #{response.body}")
            end
          end
        else
          http.request(request)
        end
      end
      @finished = true
      self
    end
  end

  class ReadRequest
    include BaseRequest

    # post_data is an array of key,value arrays. Reason:
    # - A key can appear multiple times (for multiple sheets)
    # - Parameters need to be in the right order: template - config - data
    #
    # Example: [["separator", ","], ["csv", "hello,world"]]
    attr_reader :post_data
    attr_reader :client_options
    attr_accessor :file_format

    DATA_PARAMETERS = %w[excel file]

    def add_data(params)
      params.map do |key,value|
        key = key.to_s
        if DATA_PARAMETERS.include?(key)
          value = UploadIO.new(value, "text/csv", "data.csv")
        end
        @post_data << [key, value]
      end
      self
    end

    # Response as string
    #
    # @return [String]
    #
    def response_body
      # TODO: optimize
      str = ""
      each do |chunk|
        str << chunk
      end
      str
    end

    # Set request to JSON
    #
    # @returns [require] returns self
    #
    def as_json
      self.file_format = "json"
      self
    end

    # Set request to CSV
    #
    # @returns [WriteRequest] returns self
    #
    def as_csv
      self.file_format = "csv"
      self
    end

    # Response as Hash (used with json)
    #
    # @return [String]
    #
    def to_h
      JSON.load(response_body)
    end

  protected

    def path
      path_to("read.#{file_format || "json"}")
    end
  end

  class WriteRequest
    include BaseRequest
    # post_data is an array of key,value arrays. Reason:
    # - A key can appear multiple times (for multiple sheets)
    # - Parameters need to be in the right order: template - config - data
    #
    # Example: [["separator", ","], ["csv", "hello,world"]]
    attr_reader :post_data
    attr_reader :client_options

    attr_accessor :file_format

    DATA_PARAMETERS = %w[data data_url csv csv_url json json_url]

    # Add another configuration block, consisting of sheet configuration and data element.
    #
    # @params [Hash] params
    # @returns [WriteRequest] returns self
    #
    def add_data(params = nil)
      data_params = []
      params.each do |key, value|
        key = key.to_s
        if DATA_PARAMETERS.include?(key)
          if value.is_a?(File)
            value = UploadIO.new(value, "text/csv", "data")
          end
          data_params << [key, value]
        else
          @post_data << [key, value]
        end
      end
      @post_data += data_params
      self
    end

    # Set request to XLS
    #
    # @returns [WriteRequest] returns self
    #
    def as_xls
      self.file_format = "xls"
      self
    end

    # Set request to XLSX
    #
    # @returns [WriteRequest] returns self
    #
    def as_xlsx
      self.file_format = "xlsx"
      self
    end

    # Sets request to XLSX
    #
    # @returns [WriteRequest] returns self
    #
    def append_to(target_file)
      io = UploadIO.new(target_file, "application/octet-stream", "target-file")
      @post_data = [["target_file", io]] + @post_data
      self
    end

  protected

    def path
      if file_format
        path_to("write.#{file_format}")
      else
        path_to("write")
      end
    end
  end

end