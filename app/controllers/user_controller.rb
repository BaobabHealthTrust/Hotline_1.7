class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password])
      if user
        location = Location.find(params[:location]) rescue nil     
        location = Location.find_by_name(params[:location]) if location.blank? 
        if location.blank?
          redirect_to '/login' and return
        end
        User.current = user
        session[:user_id] = user.id
        session[:location_id] = location.id
        redirect_to '/'
      end
    else
      reset_session  
    end
  end

end
