module ApplicationHelper

  def get_global_property_value(property)
		settings[property] rescue nil
	end
  
  def month_name_options(selected_months = [])
    i=0
    options_array = [[]] +Date::ABBR_MONTHNAMES[1..-1].collect{|month|[month,i+=1]} + [["Unknown","Unknown"]]
    options_for_select(options_array, selected_months)
  end

  def age_limit
    Time.now.year - 1890
  end

  def session_date
    session[:datetime]
  end

  def fancy_or_high_contrast_touch
    fancy = GlobalProperty.find_by_property("interface").property_value == "fancy" rescue false
    fancy ? "touch-fancy.css" : "touch-basic.css"
  end

  def concept_set(concept_name)
    concept = ConceptName.where(name: concept_name).first.concept
    [''] + (concept.concept_sets || []).collect do |set|
      name = ConceptName.find_by_concept_id(set.concept_set).name rescue nil
      next if name.blank?
      [name]
    end
  end
end
