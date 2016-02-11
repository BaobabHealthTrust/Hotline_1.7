class HomeController < ApplicationController
  def index
    render :layout => false
  end
  
  def start_call
    if request.post?
      raise params.inspect
    end
    render :layout => false
  end

  def house_cleaning
    render :layout => false
  end

end
