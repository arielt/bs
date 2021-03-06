class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def render_inactive_session
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/session_inactive", :formats=>[:html], :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

end
