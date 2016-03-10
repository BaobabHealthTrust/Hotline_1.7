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
    person = Person.create(birthdate: Date.today, birthdate_estimated: 1, gender: params[:person]['gender']) 
    
    person_name = PersonName.create(given_name: params[:person]['names']['given_name'], 
      family_name: params[:person]['names']['family_name'], person_id: person.id)

    PersonNameCode.create(given_name_code: person_name.given_name.soundex, 
      family_name_code: person_name.family_name.soundex, person_name_id: person_name.id)

    User.create(username: params[:user]['username'], password: params[:user]['password'], 
      person_id: person.id, system_id: params[:user]['role'])

    redirect_to '/manage_user'
    
   end

  def search_user
    unless request.get?
      @user = User.find_by_username(params[:user][:username])
      redirect_to "/user/edit/#{@user.id}"
    end
  end

  def edit
    @user = User.find(params[:user_id])
  end

  def update
    params[:person_name] = params[:person][:names]
    @user = User.where(user_id: params[:user_id]).first
    @user.person.update_attributes(gender: params[:person]['gender'].first)
     
    unless params[:user]['username'].blank?
      @user.update_attributes(username: params[:user]['username'])
    end unless params[:user].blank?

    unless params[:user]['role'].blank?
      @user.update_attributes(system_id: params[:user]['role'].downcase)
      (@user.user_roles || []).each { |r| r.destroy }
      UserRole.create(user_id: @user.id, role: params[:user]['role'].titleize)
    end unless params[:user].blank?

    PersonName.where(person_id: @user.person_id).each do | person_name |
      person_name.update_attributes(void_reason: 'Edited name', voided: true)
    end 

    new_name = PersonName.create(given_name: params[:person]['names']['given_name'],
      family_name: params[:person]['names']['family_name'])
    
    PersonNameCode.create(given_name_code: new_name.given_name.soundex,
      family_name_code: new_name.family_name.soundex, person_name_id: new_name.id)
    

    redirect_to '/manage_user'
  end
 
  def manage_user
    render :layout => false
  end

  def select_user
    render :layout => true
  end

  def manage_clinic
    render :layout => false
  end

  def change_password
    unless request.get?
      @user = User.find_by_username(params[:user]['username'])
      @user.update_attributes(password: params[:user]['password'])
      redirect_to '/manage_user' and return
    end
  end

  def show
    unless params[:id].blank?
      @user = User.find(params[:id])
      @person = Person.where(person_id: @user.user_id)
      @person_name = PersonName.find(@user.user_id)
      #raise @person.first.gender.inspect
      #redirect_to "/manage_user"

    else
      @user = User.find(:first, :order => 'date_created DESC')
    end

      #SSrender :layout => 'menu'
  end

  def username
    @names = User.where("username LIKE(?)", "%#{params[:search_string]}%").limit(30).collect do |rec| 
      rec.username
    end
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>" and return
  end

  def hsa_list
    render :layout => false
  end

end
