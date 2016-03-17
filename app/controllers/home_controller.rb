class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def index
    render :layout => false
  end

  def configuration
    render :layout => false
  end
    
  def reference_material
    @material = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article'")
    render :layout => false
  end

  def reference_article
    @article = Publify.find_by_sql("SELECT * FROM contents c WHERE c.type = 'Article' AND id = #{params[:article_id]}").first
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

  def view_tags
=begin
    tag_concepts = TagConceptRelationship.all
    @tag_concept_hash = {}
    
    tag_concepts.each do |tag_concept|
      tag_id = tag_concept.tag_id
      concept_id = tag_concept.concept_id
      tag_name = Publify.find(tag_id).name
      concept_name = ConceptName.where("concept_id = '#{concept_id}'").last.name
      @tag_concept_hash[concept_name] = {} if @tag_concept_hash[concept_name].blank?
      @tag_concept_hash[concept_name][tag_id] = tag_name
    end
=end
    @tags = Publify.all
    render :layout => false
  end

  def tag_concepts
    concept_names = []
    tag_concepts = TagConceptRelationship.where(tag_id: params[:tag_id])
    (tag_concepts || []).each  do |t|
      concept_names << [ConceptName.where(concept_id: t.concept_id).last.name, t.created_at.strftime('%d.%b.%Y %H:%M:%S')]
    end
      
    render text: concept_names.to_json and return
  end


  def view_tips
    render :layout => false
  end

  def create_tag_concept_relationships

    ActiveRecord::Base.transaction do
      concept_id = ConceptName.where("name = '#{params[:concept]}'").last.concept_id
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
      concept_id = ConceptName.where("name = '#{params[:concept]}'").last.concept_id
      tag_ids = TagConceptRelationship.where("concept_id = #{concept_id}").map(&:tag_id).join(",")
      tag_ids = '0' if tag_ids.blank?

      article_ids = Publify.find_by_sql("SELECT * FROM articles_tags  WHERE tag_id IN (#{tag_ids})"
          ).map(&:article_id).join(",")
      article_ids = '0' if article_ids.blank?
      articles = Publify.find_by_sql("SELECT * FROM contents WHERE id IN (#{article_ids})")
      
      articles_hash = {}
      articles.each do |article|
        article_id = article.id
        articles_hash[article_id]= {}
        articles_hash[article_id]["title"] = article.title
        articles_hash[article_id]["author"] = article.author
        articles_hash[article_id]["body"] = article.body
      end

      session[:articles_hash] = articles_hash
      first_key = articles_hash.keys.first
      article = articles_hash[first_key]
      hash = {:key => first_key, :data => article}
      render :text => hash.to_json
  end

  def next_article
    key = params[:key]
    next_item_pos = (session[:articles_hash].keys.index(key) + 1)
    disabled = false
    if (next_item_pos > (session[:articles_hash].keys.count - 2))
      disabled = true
    end
    if (next_item_pos > (session[:articles_hash].keys.count - 1))
      disabled = true
      next_item_pos = session[:articles_hash].keys.count - 1
    end

    my_key = session[:articles_hash].keys[next_item_pos]
    article = session[:articles_hash][my_key]
    hash = {:key => my_key, :data => article, :disabled => disabled}
    render :text => hash.to_json
  end

  def previous_article
    key = params[:key].to_s
    prev_item_pos = (session[:articles_hash].keys.index(key) - 1)
    disabled = false

    disabled = true if (prev_item_pos == 0)
    if prev_item_pos < 0
      prev_item_pos = 0
      disabled = true
    end
    my_key = session[:articles_hash].keys[prev_item_pos]
    article = session[:articles_hash][my_key]
    hash = {:key => my_key, :data => article , :disabled => disabled}
    render :text => hash.to_json
  end
  
end
