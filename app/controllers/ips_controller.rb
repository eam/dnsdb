class IpsController < ApplicationController
  # GET ips
  # GET ips.json
  def index

    args = {}
    if params[:subnet]
      (base, mask_bits) = params[:subnet].split('/')
      subnet = Subnet.find_by_base_and_mask_bits(base, mask_bits)

      if subnet.nil?
        respond_to do |format|
          format.html # index.html.erb
          format.json { render :json => { "error" => "subnet #{params["subnet"]} does not exist" }, :status => :unprocessable_entity }
        end
        return
      end
      
      args["subnet_id"] = subnet.id
    end
  
    [:id, :state, :ip, :subnet_id].each do |key|
      if params[key]
        args[key] = params[key]
      end
    end

    @ips = Ip.where(args)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @ips }
    end
  end

  # GET ips/1
  # GET ips/1.json
  def show
    @ip = Ip.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @ip }
    end
  end

  # PUT ips/1
  # PUT ips/1.json
  # or
  # POST ips
  def update

    unless params[:id].nil?
      @ip = Ip.find(params[:id])

      respond_to do |format|
        if @ip.update_attributes(params[:ip])
          format.html { redirect_to @ip, :notice => 'Ip was successfully updated.' }
          format.json { render :json => @ip }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @ip.errors, :status => :unprocessable_entity }
        end
      end
      return
    end

    begin
      if params[:state] != "in_use" 
        # we can only allocate a random IP from this subnet.
        # otherwise you need to update by specifing the IP id
        raise "You can only change the state to in_use"
      end

      if params[:subnet_id].nil?
        raise "subnet_id is required to allocate an IP"
      end

      @ip = IpsController.allocate(params[:subnet_id])
    rescue Exception => e
      err = { "error" => e.message }
    end

    respond_to do |format|
      unless err
        format.html { redirect_to @ip, :notice => 'Ip was allocated successfully.' }
        format.json { render :json => @ip }
      else
        format.html # index.html.erb
        format.json { render :json => err, :status => :unprocessable_entity }
      end
    end
  end

  # returns a newly allocated ip object from the specified subnet
  def self.allocate(subnet_id)
    ip = Ip.where(
      :state     => "available",
      :subnet_id => subnet_id
    ).first

    if ip.nil?
      raise "no available IPs in this subnet"
    end

    # now that we've found an ip, change it's state and return it
    ip.state = "in_use" 
    ip.save

    return ip
  end
end
