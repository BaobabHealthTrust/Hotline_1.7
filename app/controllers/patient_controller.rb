class PatientController < ApplicationController
  def dashboard
    
    @tab_name = params[:tab_name] 
    @tab_name = 'current_call' if @tab_name.blank?
    render :layout => false
  end
end
