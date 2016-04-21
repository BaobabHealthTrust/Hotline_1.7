class ReportController < ApplicationController
  def patient_analysis
  	render :layout => false
  end

  def reports
  	case params[:query]
  	when 'patient_activity'
  		redirect_to :action  => 'patient_activity_report',
  		:start_date => params[:start_date],
  		:end_date => params[:end_date],
  		district => params[:currentdistrict],
  		query => params[:query]
  	end
  end

  def patient_activity_report
    @start_date   = params[:start_date]
    @end_date     = params[:end_date]
    @query        = params[:query]
    @source       = params[:source] rescue nil

    @report_name  = "Patient Activity for #{params[:district]} district"
    @report    = Report.patient_activity(@start_date, @end_date, district)

      report_header = ["", "Count","Health Symptoms Count", "Health Symptoms %age",
                           "Danger Signs Count", "Danger Signs %age",
                           "Info Request Count", "Info Request %age"]
      if @source == nil
        redirect_to "/clinic"
      else
        render :text => "Done"
      end
      
    else
      render :layout => false
    end
  end



