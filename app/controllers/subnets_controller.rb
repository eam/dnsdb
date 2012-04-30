class SubnetsController < ApplicationController
  # GET /subnets
  # GET /subnets.json
  def index
    args = {}

    [:base, :id].each do |key|
      if params[key]
        args[key] = params[key]
      end
    end

    if params[:name]
      (args[:base], args[:mask_bits]) = params[:name].split('/')
    end

    @subnets = Subnet.where(args)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @subnets }
    end
  end

  # GET /subnets/1
  # GET /subnets/1.json
  def show
    @subnet = Subnet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @subnet }
    end
  end

  # GET /subnets/new
  # GET /subnets/new.json
  def new
    @subnet = Subnet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @subnet }
    end
  end

  # POST /subnets
  # POST /subnets.json
  def create
    @subnet = Subnet.new(params[:subnet])

    respond_to do |format|
      if @subnet.save
        format.html { redirect_to @subnet, :notice => 'Subnet was successfully created.' }
        format.json { render :json => @subnet, :status => :created, :location => @subnet }
      else
        format.html { render :action => "new" }
        format.json { render :json => @subnet.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /subnets/1
  # DELETE /subnets/1.json
  def destroy
    @subnet = Subnet.find(params[:id])
    @subnet.destroy

    respond_to do |format|
      format.html { redirect_to subnets_url }
      format.json { head :no_content }
    end
  end
end
