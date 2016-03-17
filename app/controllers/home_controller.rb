class HomeController < ApplicationController
  def index
    render :layout => false
  end

  def configuration
    render :layout => false
  end
    

  def concept_sets
    search_string = params[:search_string] || ''
    @names = ConceptName.where("name LIKE '%#{search_string}%'").joins("INNER JOIN concept_set s 
      ON concept_name.concept_id = s.concept_set").limit(10).map(&:name).sort
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
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
