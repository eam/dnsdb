# rest-cli - simple class for building command line interface to REST web 
# services

require 'rubygems'
require 'yaml'
require 'rest_client'
require 'json'
require 'logger'

class RestCli
  VERSION = '0.0.2'
  def initialize(opts=[])
    @opts = opts

    # --verbose will set this to DEBUG, which we should do as early as possible
    @log = Logger.new(STDERR)
    @log.level = @opts.delete("--verbose") ? Logger::DEBUG : Logger::WARN

    # config settings are in three places (from lowest to highest precendence)
    # defaults (none set here, they should be in the child class)
    # ~/.foorc file
    # command line options
    set_defaults
    parse_config
    parse_opts
  end

  def set_defaults
  end

  def run 
    if @help
      exit_with_usage
    end

    before_method = "before_" + @action + "_" + @resource
    if respond_to?(before_method)
      self.send(before_method)
    end

    url = @base_url + "/" + @resource
    if !@id.nil?
       url += "/#{@id}"
    end
     
    @log.debug(http_method.to_s + " " + url)
    req_args = {
      :method => http_method,
      :url => url, 
      :headers => {
        :content_type => :json, 
        :accept => :json 
      }
    }

    # TODO support reading from stdin
    content = ""
    if !@args.empty?
      content = JSON.pretty_generate( @args )
      @log.debug("content: " + content)
    end 

    if [:put, :post].include?(http_method)
      req_args[:payload] = content
    end

    req_success = false
    begin
      if http_method == :get
        resp = RestClient.get url, {:params => @args, :accept => :json}
      else 
        resp = RestClient::Request.execute(req_args)
      end
      req_success = true
    rescue RestClient::ExceptionWithResponse => e
      @log.warn( e.message )
      resp = e.response
    end

    if @raw
      puts resp.body
      return
    end

    unless resp.body.nil? or resp.body.empty?
      begin
        resp_obj = JSON.parse( resp.body )
      rescue
        @log.error("unable to parse response, which was: " + resp.body)
      end
    end

    output_method = "output_" + @action + "_" + @resource
    output = false
    if req_success and respond_to?(output_method)
      output = self.send(output_method, resp_obj)
    end

    if !output && !resp_obj.nil?
      puts JSON.pretty_generate(resp_obj)
    end
  end
    
  def http_method(action=@action)
    method_for = {
      "create" => :post,
      "get"    => :get,
      "update" => :put,
      "delete" => :delete,
    }
    return method_for[action]
  end

  def usage(err_msg="")
    return <<EOF
#{err_msg}
Usage: #{$PROGRAM_NAME} <action> <resource> [<id>] [--option ...] [--key value ...]

Actions: create, get, update, delete

Global Options:
    --help        print this usage message and exit
    --verbose     print debugging information
    --url <url>   the base url to preface all HTTP requests with
    --raw         do not format the output
    
All other key/value options are structured as a JSON object and sent as the body
of the HTTP request.
EOF
  end
  

  private
  def parse_opts
    # parse out all known single option arguments
    @help = @opts.delete("--help")
    @raw = @opts.delete("--raw")

    # get the action
    @action = @opts.shift
    if @action.nil? || !http_method(@action)
      exit_with_usage("missing or invalid action")
    end

    # get the resource
    @resource = @opts.shift
    if @resource.nil? || !@resource.match(/^-/).nil?
      exit_with_usage("missing or invalid resource")
    end

    # get the optional id
    if @opts[0] && @opts[0].match(/^-/).nil?
      @id = @opts.shift
    end

    @log.debug("action: #{@action}; resource: #{@resource}; id: #{@id}")

    # get all key/value options
    if @opts.length % 2 == 1
      exit_with_usage("invalid options")
    end

    @args = {}
    @opts.each_slice(2) do |key, value|
      key = String.new(key) # copy it so we can modify it
      if key.gsub!(/^--?/, "").nil?
        exit_with_usage("invalid option: '" + key + "'")
      end

      if !value.match(/^-/).nil?
        exit_with_usage("missing value for key '" + key + "'")
      end

      @args[key] = value
    end

    # parse out known global options
    if url = @args.delete("url")
      @base_url = url
    end
    @log.debug("base URL: #{@base_url}")
  end

  def parse_config
    conf_basename = File.basename($PROGRAM_NAME, ".rb")
    conf_file = File.expand_path("~/.#{conf_basename}rc")
    @log.debug("parsing config values from config file #{conf_file}")

    if !File.exists?(conf_file)
      return
    end

    conf = YAML::load_file(conf_file)
    unless conf["url"].nil?
      @base_url = conf["url"]
    end

    if conf["verbose"]
      @log.level = Logger::DEBUG
    end
  end

  def exit_with_usage(errmsg="")
    $stderr.puts usage(errmsg)
    exit 1
  end

end
