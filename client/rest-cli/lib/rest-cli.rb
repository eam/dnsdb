# rest-cli - simple class for building command line interface to REST web
# services

require 'rubygems'
require 'yaml'
require 'logger'
require 'json-resource'

class RestCli
  def initialize(opts=[])
    @opts = opts

    # --verbose will set this to DEBUG, which we should do as early as possible
    @log = Logger.new(STDERR)

    if @opts.delete("--verbose")
      @log.level = Logger::DEBUG
      RestClient.log = @log
    else
      @log.level = Logger::WARN
    end

    # config settings are in three places (from lowest to highest precendence)
    # defaults (none set here, they should be in the child class)
    # ~/.foorc file
    # command line options
    set_defaults
    parse_config
    parse_opts
  end

  # this is a stub, see child classes for implementation
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

    json_rsrc = RestClient::Resource::Json.new(@base_url)
    begin
      case @action
      when 'get', 'update'
        resp = json_rsrc.send(@action, @resource, @id, @args)
      when 'delete'
        resp = json_rsrc.send(@action, @resource, @id)
      when 'create'
        resp = json_rsrc.send(@action, @resource, @args)
      else
        raise "failed to dispatch for action #{@action}"
      end
    rescue Errno::ECONNREFUSED => e
      @log.debug e.backtrace
      @log.fatal "Error when connecting to #{@base_url}: #{e.message}"
      exit 1
    end

    resp_obj = json_rsrc.response
    if @raw
      puts resp_obj.body
      return
    end

    req_success = (resp_obj.code < 400)
    if !req_success
      $stderr.puts "#{resp_obj.code} #{RestClient::STATUSES[resp_obj.code]}"
    end

    output_method = "output_" + @action + "_" + @resource
    output = false
    if resp and req_success and respond_to?(output_method)
      output = self.send(output_method, resp)
    end

    if !output && resp && !resp.empty?
      puts JSON.pretty_generate(resp)
    end
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
    if @action.nil? || !%w(create get update delete).include?(@action)
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
