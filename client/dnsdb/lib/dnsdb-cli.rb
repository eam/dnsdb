require 'rubygems'
require 'rest-cli'
require 'json'

class DnsdbCli < RestCli 
  VERSION = "0.0.2"

  def usage(err_msg="") 
    examples = <<EOF

Note that for ips, domains and subnets the id may be the name.

Examples:
  # create a subnet (and the corrisponding ips)
  # note that this sets the gateway, network and broadcast ips as in_use
  $ dnsdb create subnets 192.168.1.0/24

  # allocate an ip from this subnet
  $ dnsdb update ips --subnet 192.168.1.0/24 --state in_use

  # allocate a specific ip
  $ dnsdb update ips 192.168.1.42 --state in_use

  # search for all records named foo.example.com
  $ dnsdb get records --name foo.example.com

  # create a CNAME.  the domain is automatically determined for you
  $ dnsdb create records --type CNAME --name foo.example.com --content foo-5.example.com

  # allocate an A record.  An ip is automatically allocated for you
  $ dnsdb create records --subnet 192.168.1.0/24 --type A --name foo-5.example.com

  # set the record to the data from a json file
  $ dnsdb update records 99 < my_record.js

Version: #{VERSION}
EOF

    return super + examples
  end

  def set_defaults
    @base_url = "http://localhost/"
  end

  def before_get_ips
    if @id && @id.match(/^\d+\.\d+.\d+\.\d+$/)
      @id = fetch_id("ips", { "ip" => @id })
    end
  end

  def before_update_ips
    if @args["subnet"]
      @args["subnet_id"] = fetch_id("subnets", { "name" => @args.delete("subnet") })
    end

    if @id && @id.match(/^\d+\.\d+.\d+.\d+$/)
      @id = fetch_id("ips", { "ip" => @id })
    end
  end

  def before_create_subnets
    if @id
      (@args["base"], @args["mask_bits"]) = @id.split('/')
      @id = nil
    end
  end

  def before_get_subnets
    if @id && @id.match(/^\d+\.\d+.\d+.\d+\/\d+$/)
      @id = fetch_id("subnets", { "name" => @id })
    end
  end

  def before_update_subnets
    if @id && @id.match(/^\d+\.\d+.\d+.\d+\/\d+$/)
      @id = fetch_id("subnets", { "name" => @id })
    end
  end

  def before_delete_subnets
    if @id && @id.match(/^\d+\.\d+.\d+.\d+\/\d+$/)
      @id = fetch_id("subnets", { "name" => @id })
    end
  end

  def before_get_domains
    if @id && !@id.match(/^\d+$/)
      @id = fetch_id("domains", { "name" => @id })
    end
  end

  def before_update_domains
    if @id && !@id.match(/^\d+$/)
      @id = fetch_id("domains", { "name" => @id })
    end
  end

  def before_delete_domains
    if @id && !@id.match(/^\d+$/)
      @id = fetch_id("domains", { "name" => @id })
    end
  end

  # TODO it'd be nice if there was a before_global which would always run
  # that would allow me to always convert --subnet to --subnet_id 
  # and all --domain to --domain_id
  def before_get_records
    if @args["domain"]
      @args["domain_id"] = fetch_id("domains", { "name" => @args.delete("domain") })
    end
  end

  def before_update_records
    if @args["domain"]
      @args["domain_id"] = fetch_id("domains", { "name" => @args.delete("domain") })
    end
  end

  def before_create_records
    if @args["subnet"]
      @args["subnet_id"] = fetch_id("subnets", { "name" => @args.delete("subnet") })
    end

    if @args["domain"]
      @args["domain_id"] = fetch_id("domains", { "name" => @args.delete("domain") })
    end
  end

  def fetch_id(resource_type, params)
    url = @base_url + "/#{resource_type}/"
    resp = RestClient.get url, {:params => params, 
                                :accept => :json}

    begin
      id = JSON.parse(resp.body)[0]["id"]
    rescue
      raise "couldn't find a #{resource_type} from where #{params}"
    end

    @log.debug("got id #{id} for #{resource_type}")
    return id
  end

  def output_get_subnets(subnets)
    return false unless @id.nil?

    subnets.sort_by { |subnet| subnet['id'].to_i }.each do |subnet| 
      puts "#{subnet['id']}\t#{subnet['base']}/#{subnet['mask_bits']}"
    end

    return true
  end

end
