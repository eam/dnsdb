class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from Exception, :with => :render_500

  private
  def render_500(exception)
    @error = exception
    respond_to do |format|
      format.json { render :json => { :error => @error }, :status => :internal_server_error }
    end
  end
end
