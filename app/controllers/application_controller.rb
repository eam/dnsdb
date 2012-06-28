class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from Exception, :with => :render_500

  private
  def render_500(exception)
    # this only handles error in json.  the default handler can do non-json
    if !self.request.format.json?
      raise exception
    end

    respond_to do |format|
      format.json { render :json => { :error => exception.message }, :status => :internal_server_error }
    end
  end
end
