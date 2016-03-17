class HomeController < ApplicationController
  def index
    render :layout => false
  end
  
  def start_call
    if request.post?
      district = params[:district]
      call_mode = params[:call_mode]
      if call_mode == "New"
        # record patient details
        redirect_to :controller => :patient,
                    :action => :search_by_name,:action_type => 'new_client' and return
      else
        # lookup caller (filtered by district)
        redirect_to "/start_call" and return
      end
      #raise params.inspect
    end
    render :layout => false
  end

  def house_cleaning
    render :layout => false
  end

  def admin
  	render :layout => false
  end

  def report
    render :layout => false
  end

  def list
    @people = Person.joins(" INNER JOIN patient ON person.person_id = patient.patient_id ").select("person.*").where(voided: 0)

      #raise @people.inspect

    #@people = Person.where("a.person_attribute_type_id = ?",
     # person_attribute_type.id).joins("INNER JOIN person_attribute a USING(person_id)")
    render :layout => false
  end 

  def health_facilities
    search_string = params[:search_string] || ''
    @names = Location.where("name LIKE '%#{search_string}%'").limit(10).map(&:name).sort
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def quick_summary
    @stats = Hash.new(0)
    @stats['Total clients registered'] = Patient.count
    @stats['Total clients registered (Women)'] = Patient.where("p.gender = 'F' OR p.gender = 'Female'").joins("INNER JOIN person p ON p.person_id=patient.patient_id").count
    @stats['Total clients registered (Men)'] = Patient.where("p.gender = 'M' OR p.gender = 'Male'").joins("INNER JOIN person p ON p.person_id=patient.patient_id").count

    render :layout => false
  end

end
