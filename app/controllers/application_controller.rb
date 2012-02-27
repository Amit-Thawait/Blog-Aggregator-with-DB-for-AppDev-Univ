class ApplicationController < ActionController::Base
  protect_from_forgery  
  
  
  def set_layout
     params[:action] == "read_blogs" ? 'application' : 'blogs'
  end
end
