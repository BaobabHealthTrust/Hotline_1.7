class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def index

    start_datetime  = Date.today.strftime('%Y-%m-%d %H:%M:%S')
    end_datetime    = Date.today.strftime('%Y-%m-%d 59:59:59')
    @calls_today    = Observation.find_by_sql("SELECT * FROM
                                              ( SELECT person_id, comments
                                                FROM obs
                                                WHERE date_created >= '#{start_datetime}'
                                                AND date_created <= '#{end_datetime}'
                                                GROUP BY person_id, comments
                                              )
                                              AS calls ").count

    render :layout => false

    if !session[:tag_encounters].blank?
      Encounter.feed_tags(session[:tagged_encounters_patient_id])
      session.delete(:tag_encounters)
      session.delete(:tagged_encounters_patient_id)
    end

    session.delete(:end_call) if session[:end_call].present?
    session.delete(:no_guardian) if session[:no_guardian].present?

    session[:automatic_flow] = true
  end

  def configuration
    render :layout => false
  end
    
  def reference_material
    @material = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article'")
    #render :layout => false
  end

  def reference_article
    @article = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article' AND id = #{params[:article_id]}").first
    #render :layout => false
  end

  def concept_sets
    search_string = params[:search_string] || ''
    @names = ConceptName.where("name LIKE '%#{search_string}%'").select(" distinct name ").limit(20).map(&:name).sort
    render :text => "<li>" + @names.map{|n| n } .join("</li><li>") + "</li>"
  end

  def start_call
    if request.post?
      session[:district] = params[:district]
      call_mode = params[:call_mode]
      if call_mode == "New"
        # record patient details
        redirect_to :controller => :patient,
                    :action => :search_by_name,
                    :action_type => 'new_client'  and return
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
    #----- Consider putting this in an array to get patients using the get_patient method from Patient Service library. ------------------
    patient_ids = Encounter.find_by_sql("
              SELECT patient_id FROM encounter e INNER JOIN obs o ON e.encounter_id = o.encounter_id
              WHERE e.voided = 0  AND COALESCE(o.comments, '') = '' limit 1000
      ").map(&:patient_id) + [-1] #should always exist

    @people = Patient.joins(:person => [:person_names, :person_addresses]).select('patient.*, person.*, person_name.*, person_address.*').where(
        "patient.patient_id IN (#{patient_ids.join(', ')})"
    )
    render :layout => false
  end 

  def health_facilities
    search_string = params[:search_string] || ''
    
    #if params[:tag].present?
      location_tags   = LocationTag.where(" name IN ('Health Centre', 'District Hospital', 'Clinic',
     'Rural/Community Hospital', 'Dispensary', 'Central Hospital', 'Maternity', 'Other Hospital', 'Health Post')").collect{|l| l.id}
      names  = Location.where("m.location_tag_id IN (#{location_tags.join(', ')}) AND name LIKE '%#{search_string}%' ").joins("INNER JOIN location_tag_map m
                          ON m.location_id = location.location_id").select(' distinct name ').limit(30).map(&:name).sort
    #end

    render :text => "<li>" + names.map{|n| n } .join("</li><li>") + "</li>" + "<li>" 'Other' "</li>" + "<li>" 'Unknown' "</li>"
  end

  def quick_summary
    @stats = Hash.new(0)
    @stats['Total clients registered'] = Patient.count
    @stats['Total clients registered (Women)'] = Patient.joins(person: :patient).where('person.gender = "F"  
                            AND (YEAR(person.date_created)-YEAR(person.birthdate)) > 14').count
    @stats['Total clients registered (Men)'] = Patient.joins(person: :patient).where('person.gender = "M" 
                            AND (YEAR(person.date_created)-YEAR(person.birthdate)) > 14').count
    @stats['Total clients registered (Aged 6 to 14)'] = Patient.joins(person: :patient).where('(YEAR(person.date_created)-YEAR(person.birthdate)) >= 6 AND (YEAR(person.date_created)-YEAR(person.birthdate)) <= 14').count
    @stats['Total clients registered (Children under 5)'] = Patient.joins(person: :patient).where('(YEAR(person.date_created)-YEAR(person.birthdate)) <= 5').count
    
    render :layout => false
  end

  def view_tags
    relationships = TagConceptRelationship.all
    if params[:by_concepts].blank?
      @tags = Publify.find_by_sql(" SELECT * FROM tags WHERE id IN (#{relationships.map(&:tag_id).join(', ')})") rescue []
    else
      @concepts = ConceptName.find_by_sql(" SELECT * FROM concept_name WHERE concept_id
                                              IN (#{relationships.map(&:concept_id).join(', ')})") rescue []
    end

  end

  def tag_concepts
    concept_names = []
    tag_concepts = TagConceptRelationship.where(tag_id: params[:tag_id])
    (tag_concepts || []).each  do |t|
      concept_names << [ConceptName.where(concept_id: t.concept_id).last.name, t.created_at.strftime('%d.%b.%Y %H:%M:%S')] rescue next
    end
      
    render text: concept_names.to_json and return
  end

  def concept_tags
    tag_names = []
    tag_concepts = TagConceptRelationship.where(concept_id: params[:concept_id])
    (tag_concepts || []).each  do |t|
      tag_names << [Publify.where(id: t.tag_id).last.name, t.created_at.strftime('%d.%b.%Y %H:%M:%S')] rescue next
    end

    render text: tag_names.to_json and return
  end

  def view_tips
    render :layout => false
  end

  def create_tag_concept_relationships

    ActiveRecord::Base.transaction do
      concept_id = ConceptName.where("name = \"#{params[:concept]}\" ").last.concept_id
      params[:tags].each do |tag|
        tag_id = Publify.where("name = '#{tag}'").last.id
        tag_concept_relationship = TagConceptRelationship.new
        tag_concept_relationship.concept_id = concept_id
        tag_concept_relationship.tag_id = tag_id
        tag_concept_relationship.save
      end
    end
    
    redirect_to("/configurations") and return
  end

  def retrieve_articles
    c = params[:concept].split('|').join("\", \"") rescue "----------"
    concept_ids = ConceptName.where("name IN (\"#{c}\")").map(&:concept_id).join(" , ") rescue -1
    tag_ids = TagConceptRelationship.where("concept_id IN (#{concept_ids})").map(&:tag_id).join(",") rescue "0"
    tag_ids = '0' if tag_ids.blank?

      article_ids = Publify.find_by_sql("SELECT * FROM articles_tags  WHERE tag_id IN (#{tag_ids})"
          ).map(&:article_id).join(",")
      article_ids = '0' if article_ids.blank?
      articles = Publify.find_by_sql("SELECT * FROM contents WHERE id IN (#{article_ids})")
      
      articles_hash = {}
      article_override = nil
      article_key = nil
      articles.each do |article|
        article_id = article.id
        articles_hash[article_id]= {}
        articles_hash[article_id]["title"] = article.title.force_encoding("utf-8")
        if params[:title] && params[:title] ==  articles_hash[article_id]["title"]
          article_override = articles_hash[article_id]
          article_key = article_id
        end

        articles_hash[article_id]["author"] = article.author
        articles_hash[article_id]["body"] = article.body.force_encoding("utf-8")
      end

      titles = [];
      articles_hash.each do |key, article|
        titles << article['title']
      end

      session[:articles_hash] = articles_hash
      first_key = articles_hash.keys.first
      article = article_override.blank? ? articles_hash[first_key] : article_override
      hash = {:key => (article_key || first_key), :data => article, :all_keys => titles.join('|') }
      render :text => hash.to_json
  end

  def check_articles

    c = params[:concept].split('|').join("\", \"") rescue "----------"
    concept_ids = ConceptName.where("name IN (\"#{c}\")").map(&:concept_id).join(" , ") rescue -1
    tag_ids = TagConceptRelationship.where("concept_id IN (#{concept_ids})").map(&:tag_id).join(",") rescue "0"
    tag_ids = '0' if tag_ids.blank?

    article_ids = Publify.find_by_sql("SELECT * FROM articles_tags  WHERE tag_id IN (#{tag_ids})"
    ).map(&:article_id).join(",")
    article_ids = '0' if article_ids.blank?
    articles = Publify.find_by_sql("SELECT * FROM contents WHERE id IN (#{article_ids})")

    render :text => "true" and return if articles.length > 0
    render :text => "false"
  end

  def next_article
    key = !params[:key].blank? ? params[:key].to_i : -2
    next_item_pos = (session[:articles_hash].keys.index(key) + 1)
    disabled = false
    if (next_item_pos > (session[:articles_hash].keys.count - 2))
      disabled = true
    end
    if (next_item_pos > (session[:articles_hash].keys.count - 1))
      disabled = true
      next_item_pos = session[:articles_hash].keys.count - 1
    end

    titles = [];
    session[:articles_hash].each do |key, article|
      titles << article['title']
    end

    my_key = session[:articles_hash].keys[next_item_pos]
    article = session[:articles_hash][my_key]
    hash = {:key => my_key, :data => article, :disabled => disabled, :all_keys => titles.join('|')  }
    render :text => hash.to_json
  end

  def previous_article
    key = !params[:key].blank? ? params[:key].to_i : -2
    prev_item_pos = (session[:articles_hash].keys.index(key) - 1)
    disabled = false

    disabled = true if (prev_item_pos == 0)
    if prev_item_pos < 0
      prev_item_pos = 0
      disabled = true
    end

    titles = [];
    session[:articles_hash].each do |key, article|
      titles << article['title']
    end

    my_key = session[:articles_hash].keys[prev_item_pos]
    article = session[:articles_hash][my_key]
    hash = {:key => my_key, :data => article , :disabled => disabled, :all_keys => titles.join('|') }
    render :text => hash.to_json
  end
  
  def set_session
    session[params[:field]] = params[:value]
    render :text => session[params[:field]]
  end

end
