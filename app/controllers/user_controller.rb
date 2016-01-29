class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password],params[:user_type])
      if user
        User.current = user
        session[:user_id] = user.id
        redirect_to '/'
      end
    end
  end

end
