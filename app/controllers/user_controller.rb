class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password])
      if user
        location_tag_id = LocationTag.find_by_name('Facility location').id
        
        location = Location.where("location.location_id = ? OR location.name = ?", 
          params[:location],params[:location]).joins("location_tag_map m ON m.location_id = location.location_id AND
          location_tag_id = #{location_tag_id}").first rescue nil     

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
