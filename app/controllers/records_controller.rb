class RecordsController < ApplicationController
  # GET /records
  # GET /records.json
  def index
    args = {}
    [:type, :name, :content, :domain_id].each do |key|
      if params[key]
        args[key] = params[key]
      end
    end

    @records = Record.where(args)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @records }
    end
  end

  # GET /records/1
  # GET /records/1.json
  def show
    @record = Record.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @record }
    end
  end

  # GET /records/new
  # GET /records/new.json
  def new
    @record = Record.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @record }
    end
  end

  # GET /records/1/edit
  def edit
    @record = Record.find(params[:id])
  end

  # POST /records
  # POST /records.json
  def create
    if !params[:subnet_id].nil? && params[:record][:content].nil?
      # TODO catch what this throws
      ip = IpsController.allocate(params[:subnet_id])
      params[:record][:content] = ip.ip 
    end
    
    @record = Record.new(params[:record])

    respond_to do |format|
      if @record.save
        format.html { redirect_to @record, :notice => 'Record was successfully created.' }
        format.json { render :json => @record, :status => :created, :location => @record }
      else
        format.html { render :action => "new" }
        format.json { render :json => @record.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /records/1
  # PUT /records/1.json
  def update
    @record = Record.find(params[:id])
 
   # TODO don't allow update of PTR records (maybe that should go in the model?)

    respond_to do |format|
      if @record.update_attributes(params[:record])
        format.html { redirect_to @record, :notice => 'Record was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @record.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /records/1
  # DELETE /records/1.json
  def destroy
    @record = Record.find(params[:id])
    @record.destroy
 
   # TODO don't allow delete of PTR records (maybe that should go in the model?)

    respond_to do |format|
      format.html { redirect_to records_url }
      format.json { head :no_content }
    end
  end
end
