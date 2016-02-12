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
    roles = UserRole.all.map(&:role)
  end


  def create
    
    person = Person.create(birthdate: Date.today, birthdate_estimated: 1, gender: params[:person]['gender'].first) 
    
    person_name = PersonName.create(given_name: params[:person]['names']['given_name'], 
      family_name: params[:person]['names']['family_name'], person_id: person.id)

    PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)

    User.create(username: params[:user]['username'], password: params[:user]['password'], 
      person_id: person.id, system_id: params[:user]['role'])

    redirect_to '/admin'
   end

  def edit
    @user = User.find(params[:id])
  end

  def manage_user
    render :layout => false
  end

  def manage_clinic
    render :layout => false
  end

end
