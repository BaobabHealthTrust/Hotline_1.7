class HomeController < ApplicationController
  def index
    render :layout => false
  end
  
  def start_call
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
end
