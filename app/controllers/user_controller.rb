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

    redirect_to '/admin'
    
   end

  def search_user
    unless request.get?
      @user = User.find_by_username(params[:user][:username])
      redirect_to :action =>"show", :id => @user.id
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    
    #find_by_person_id(params[:id])
    params[:person_name] = params[:person][:names]
    @user = User.where(user_id: params[:user_id]).first
    #raise @user.inspect

    username = params[:user]['username'] rescue current_user.username


     if username
       @user.username = username
       @user.save
     end

    PersonName.find(:all,:conditions =>["voided = 0 AND person_id = ?",@user.person_id]).each do | person_name |
      person_name.voided = 1
      person_name.voided_by = current_user.person_id
      person_name.date_voided = Time.now()
      person_name.void_reason = 'Edited name'
      person_name.save
    end rescue nil

    person_name = PersonName.new()
    person_name.family_name = params[:person_name]["family_name"]
    person_name.given_name = params[:person_name]["given_name"]
    person_name
    if person_name.save
      flash[:notice] = 'User Successfully Updated.'
      redirect_to :action => 'show', :id => @user.id and return
    end rescue nil

    flash[:notice] = "User Was Not Updated!."
    render :action => 'show'
    redirect
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
    @user = User.find(session[:user_id])
    @user_id = @user.user_id
    #raise params.inspect
    unless request.get?

      if (params[:user][:password] != params[:user][:confirm_password])
            flash[:notice] = 'Password Does Not Match'
            redirect_to :action => 'change_password' and return
      else
            #if @user.update_attributes(params[:user]
              @user.password = params[:user][:password]
              if (@user.save)
                flash[:notice] = "Password Successfully Changed"
                #raise params.inspect
              redirect_to :action => "show",:id => @user_id and return
              else
                flash[:notice] = "Password Change Failed" 
                redirect_to :action => 'change_password' and return 
              end
              
            #else
             #flash[:notice] = "Password change failed"  
            #end    
      end
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

end
