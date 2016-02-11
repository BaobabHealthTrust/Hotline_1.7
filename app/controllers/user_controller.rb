class UserController < ApplicationController
  def login
    if request.post?
      user = User.authenticate(params[:username],params[:password])
      if user
        location_tag_id = LocationTag.find_by_name('Facility location').id
        
        location = Location.where("location.location_id = ? OR location.name = ?", 
          params[:location], params[:location]).joins("INNER JOIN location_tag_map m ON m.location_id = location.location_id AND
          location_tag_id = #{location_tag_id}").first rescue nil     

        if location.blank?
          flash[:error] = "Invalid Workstation Location" 
          redirect_to '/login' and return
        end
        User.current = user
        session[:user_id] = user.id
        session[:location_id] = location.id
        redirect_to '/'
      end
    else
      flash[:error] = "Invalid username or password"
      reset_session  
    end
  end

  def new
    @user = User.new
    roles = Role.all.map(&:role)
  end


  def create
    existing_user = User.find(:first, :conditions => {:username => params[:user][:username]}) rescue nil

    if existing_user
      flash[:notice] = 'username already exists'
      redirect_to :action => 'new'
      return
    end
    if (params[:user][:password] != params[:user_confirm][:password])
      flash[:notice] = 'Password Do Not Match'
      redirect_to :action => 'new'
      return

      @user_first_name = params[:person_name][:given_name]
      @user_last_name = params[:person_name][:family_name]
      @user_role = params[:user_role][:user_id]
      @user_name = params[:user][:username]
    end

    person = Person.create()
    person.names.create(params[:person_name])
    params[:user][:user_id] = person.id
    @user = User.new(params[:user])
    @user.id = person.id
    if @user.save

      user_role = UserRole.new
      user_role.role = Role.find_by_role(params[:user_role][:role_id])
      user_role.user_id = @user.user_id
      user_role.save

    @user.update_attributes(params[:user])
    flash[:notice] = 'User was Created Successfully.'
    redirect_to :action => 'show'

  else
    flash[:notice] = 'User was not Created.'
    render :action => new
  end
end






















end
