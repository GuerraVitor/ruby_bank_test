class ApplicationController < ActionController::Base
 
  helper_method :current_user, :logged_in? # Makes these methods available in views too

  private

  def require_login
    unless logged_in?
      flash[:alert] = "You must be logged in to access this page."
      redirect_to login_path
    end
  end
  
  allow_browser versions: :modern
end
