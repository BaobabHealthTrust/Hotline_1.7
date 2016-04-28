Rails.application.routes.draw do

  get 'report/patient_analysis'

  ######################### home start ############################################
  get 'home/index'
  get 'start_call' => 'home#start_call'
  post 'start_call' => 'home#start_call'
  get 'house_keeping' => 'home#house_cleaning'
  get 'admin' => 'home#admin'
  get 'home/health_facilities'
  get 'report' => 'home#report'
  get 'patient_demographic_report' => 'home#patient_demographic_report'
  get '/quick_summary' => 'home#quick_summary'
  get '/list' => 'home#list'
  get 'configurations' => 'home#configuration'
  get '/tags_concept_relationship' => 'home#tags_concept_relationship'
  get 'home/concept_sets'
  get 'view_tags' => 'home#view_tags'
  get 'view_tips' => 'home#view_tips'
  post 'home/create_tag_concept_relationships'

  get 'home/reference_article/:article_id' => 'home#reference_article'
  get 'home/reference_material'
  get 'home/retrieve_articles'
  post 'home/retrieve_articles'
  post 'home/next_article'
  post 'home/previous_article'
  get 'tag_concepts/:tag_id' => 'home#tag_concepts'
  ######################### home end ############################################
  
  ######################### user start ############################################
  get '/login' => 'user#login'
  post '/login' => 'user#login'
  get '/logout' => 'user#login'
  get 'manage_user' => 'user#manage_user'
  get 'manage_clinic' => 'user#manage_clinic'
  get 'user/new'
  post '/user/create'
  get 'user/change_password'
  post '/user/change_password'
  get 'user/show'
  post 'user/show'
  get 'user/update'
  post '/user/update'
  get 'user/select_user'
  post '/user/select_user'
  get 'user/search_user'
  post '/user/search_user'
  get 'user/edit/:user_id' => 'user#edit'
  post '/user/edit'
  get 'user/username'
  get 'user/list'
  get 'user_dashboard/:user_id' => 'user#dashboard'
  post '/edit_selected_user' => 'user#edit_selected_user' 
  ######################### user end ############################################

  ######################### patient start ############################################
  get 'patient/dashboard/:patient_id/:tab_name' => 'patient#dashboard'
  get 'patient/edit/:patient_id' => 'patient#edit'
  post 'patient/new'

  get 'patient/test'
  get 'patient/dietary_assessment'

  post 'patient/search_result'

  get 'patient/new_with_demo/:patient_id' => 'patient#new_with_demo'
  post 'patient/new_with_demo/:patient_id' => 'patient#new_with_demo'

  get 'patient/add_patient_attributes'
  post 'patient/add_patient_attributes'

  get 'patient/search_by_name'
  post 'patient/create'
  get '/patient/given_names'
  get '/patient/family_names'
  get '/patient/given_name_plus_family_name'
  get 'patient/find_by_phone'
  get 'patient/find_by_identifier'
  post 'patient/attributes_search_results'
  get 'patient/districts'
  get 'patient/ta'
  get 'patient/village'
  get 'patient/district'
  post 'encounters/pre_process'
  get 'encounters/nutrition_summary'
  get 'patient_obs/:encounter_id' => 'patient#observations'
  get 'patient/number_of_booked_patients'
  get 'void_encounter/:encounter_id/:tab_name' => 'patient#void_encounter' 

  get 'patient/reference_article/:article_id/:patient_id' => 'patient#reference_article'
  get 'patient/reference_material/:patient_id' => 'patient#reference_material'
  ######################### patient end ############################################
  

  ######################### people start ############################################
  get 'demographics/:patient_id' => 'people#demographics'
  get 'demographic_modify/:field/:patient_id' => 'people#demographic_modify'
  post '/demographic_modify' => 'people#demographic_modify'
  get 'people/new'
  post 'patient/:create' => 'people#create'
  get '/patient/:given_names' => 'people#given_names'
  get '/patient/:family_names' => 'people#family_names'
  get '/patient/:given_name_plus_family_name' => 'people#given_name_plus_family_name'

  get '/people/guardian_check'
  post '/people/guardian_check'

  get 'people/villages'
  post 'people/villages'

  get 'people/regions'
  post 'people/regions'
  #########################hsa start #################################
  post '/people/create_hsa'
  get 'people/search_hsa'
  post '/people/search_hsa'
  get 'people/select_hsa'
  post '/people/select_hsa'
  get 'people/edit_hsa/:person_id' => 'people#edit_hsa'
  post 'people/update_hsa' 
  post '/people/update'
  get 'people/update_hsa'
  post '/people/update_hsa'
  get '/people/given_names'
  get 'people/family_names'
  get '/people/given_name_plus_family_name'
  get 'people/show'
  post 'people/show'
  get '/hsa_list' => 'people#hsa_list'
  get 'hsa_dashboard/:person_id' => 'people#hsa_dashboard'
  post '/edit_selected_hsa' => 'people#edit_selected_hsa'
  ######################### hsa end ##################################
  ######################### people end ############################################

  ######################### encounters start ########################################
  get '/encounters/new/:encounter_type' => 'encounters#new'
  post '/encounters/new/:encounter_type' => 'encounters#new'

  get '/encounters/create'
  post '/encounters/create'
  ######################### encounters end ##########################################


  ######################## Report start ############################################

  get '/reports_index' => 'report#index'
  get '/report/select'
  get '/report/reports'
  post '/report/reports'
  get '/clinic' => 'home#index'
  get '/report/patient_demographics_report'

  ######################## Reports end  ############################################

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  root 'home#index'
end
