class ReportController < ApplicationController
	skip_before_filter :verify_authenticity_token

	def index
		@reports = {
			  "patient_analysis" => [
					{ "name" => "Demographics", "icon" => "icons/analysis-256.png",
					  "link" => "/report/report_filter_page?report_type=patient_analysis&query=demographics" },
					{   "name" => "Ages Distribution", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=patient_analysis&query=ages distribution" },
					{   "name" => "Health Issues", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=patient_analysis&query=health issues"},
					{   "name" => "Patient Activity", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=patient_analysis&query=patient activity"},
					{   "name" => "Referral Followup", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=patient_analysis&query=referral followup"},
					{   "name" => "Home", "icon" => "icons/gohome.png",
					    "link" => "/"}
			  ],
			  "call_analysis" => [
					{   "name" => "Call Time of Day", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=call_analysis&query=call time of day"},
					{   "name" => "Call Day Distribution", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=call_analysis&query=call day distribution"},
					{   "name" => "Call Lengths", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=call_analysis&query=call lengths"},
					{   "name" => "New Vs Repeat Callers", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=call_analysis&query=new vs repeat callers"},
					{   "name" => "Follow Up", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=call_analysis&query=follow up"},
					{   "name" => "Home", "icon" => "icons/gohome.png",
					    "link" => "/"}
			  ],
			  "tips" => [
					{   "name" => "Tips Activity", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=tips&query=tips activity"},
					{   "name" => "Current Enrollment Totals", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=tips&query=current enrollment totals"},
					{   "name" => "Individual Current Enrollments", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=tips&query=individual current enrollments"},
					{   "name" => "Home", "icon" => "icons/gohome.png",
					    "link" => "/"}
			  ],
			  "family_planning" => [
					{   "name" => "Info on Family Planning", "icon" => "icons/analysis-256.png",
					    "link" => "/report/report_filter_page?report_type=family_planning&query=info on family planning"},
					{   "name" => "Home", "icon" => "icons/gohome.png",
					    "link" => "/"}
			  ]
		}
	end
	def report_filter_page
		location_tag = LocationTag.find_by_name("District")
		@districts = Location.where("m.location_tag_id = #{location_tag.id}")
			               .joins("INNER JOIN location_tag_map m ON m.location_id = location.location_id")
			               .collect{|l |
			[l.id, l.name]
		}
		@districts = ["",'All'] + @districts.collect {
			  |location_id, location_name|
			location_name
		}
		@report_date_range  = [""]
		@patient_type       = [""]
		@grouping           = [""]
		@outcome            = [""]

		@report_type        = params[:report_type]
		@query              = params[:query].gsub(" ", "_")

		start_date          = Encounter.first.encounter_datetime rescue Date.today
		end_date            = session[:datetime].to_date rescue Date.today

		report_date_ranges  = Report.generate_report_date_range(start_date, end_date)
		@date_range_values  = [["",""]]
		@report_date_range  = report_date_ranges.inject({}){|date_range, report_date_range|
			date_range[report_date_range.first]         = report_date_range.last["datetime"]
			@date_range_values.push([report_date_range.last["range"].first, report_date_range.first])
			date_range
		}

		case @report_type
			when "patient_analysis"
				case @query
					when "demographics"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "health_issues"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@health_task         = ["", "Health Symptoms", "Danger Warning Signs",
						                        "Health Information Requested", "Outcomes"]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "ages_distribution"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "patient_activity"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "referral_followup"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@outcomes = ['']+Report.concept_set('General outcome').flatten.delete_if{|c| c.blank?}.uniq
						#outcomes below minimised for the time being. Can used if above method fails
						outcomes            = ["",'REFERRAL TO HOSPITAL',"REFERRED TO A HEALTH CENTRE",
						                        "REFERRED TO NEAREST VILLAGE CLINIC",
						                        "PATIENT TRIAGED TO NURSE SUPERVISOR",
						                        "GIVEN ADVICE NO REFERRAL NEEDED"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

				end
			when "call_analysis"
				case @query
					when "new_vs_repeat_callers"
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
					when "follow_up"
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
					else
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@staff               = [["",""]] + get_staff_members_list + [["All","All"]]
						@call_type           = ["","Normal", #"Followup","Non-Patient Tips",
						                        #"Emergency",
						                        "Irrelevant","Dropped","Advice given, not registered", #,
						                        #"All Patient Interaction",
						                        #"All Non-Patient",
						                        "All"]
						#@call_status         = ["","Yes","No", "All"]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
				end

			when "tips"
				case @query
					when "tips_activity"
						@phone_type         = [["",""],["Community", "community"],["Personal","personal"],
						                       ["Family","family"],["Neighbour","Neighbour"],["All", "all"]]
					when "current_enrollment_totals"

					when "individual_current_enrollments"
						@phone_type         = [["",""],["Community", "community"],["Personal","personal"],
						                       ["Family","family"],["Neighbour","Neighbour"],["All", "all"]]
				end
				@grouping           += [["",""],["By Week", "week"], ["By Month", "month"]]
				@content_type       = [["",""],["Pregnancy", "pregnancy"],["Child","child"],["All", "all"]]
				@language           = [["",""],["Yao","yao"],["Chichewa","chichewa"],["All", "all"]]
				@delivery           = [["",""],["SMS","sms"],["Voice","voice"],["All", "all"]]
				@network_prefix     = [["",""],["09","airtel"],["08","tnm"],["Other","other"],["All", "all"]]
				@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

			when "family_planning"

				@grouping            += [["By Week", "week"], ["By Month", "month"]]
				@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

		end
	end
	def select
		location_tag = LocationTag.find_by_name("District")
		@districts = Location.where("m.location_tag_id = #{location_tag.id}").joins("INNER JOIN location_tag_map m
     ON m.location_id = location.location_id").collect{|l | [l.id, l.name]}
		@districts = [""] + @districts.collect { |location_id, location_name| location_name}

		@report_date_range  = [""]
		@patient_type       = [""]
		@grouping           = [""]
		@outcome            = [""]

		@report_type        = params[:report_type]
		@query              = params[:query].gsub(" ", "_")

		start_date          = Encounter.first.encounter_datetime rescue Date.today
		end_date            = session[:datetime].to_date rescue Date.today

		report_date_ranges  = Report.generate_report_date_range(start_date, end_date)
		@date_range_values  = [["",""]]
		@report_date_range  = report_date_ranges.inject({}){|date_range, report_date_range|
			date_range[report_date_range.first]         = report_date_range.last["datetime"]
			@date_range_values.push([report_date_range.last["range"].first, report_date_range.first])
			date_range
		}

		case @report_type
			when "patient_analysis"
				case @query
					when "demographics"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "health_issues"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@health_task         = ["", "Health Symptoms", "Danger Warning Signs",
						                        "Health Information Requested", "Outcomes"]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "ages_distribution"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "patient_activity"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

					when "referral_followup"
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@outcomes            = ["","REFERRED TO A HEALTH CENTRE",
						                        "REFERRED TO NEAREST VILLAGE CLINIC",
						                        "PATIENT TRIAGED TO NURSE SUPERVISOR",
						                        "GIVEN ADVICE NO REFERRAL NEEDED"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

				end
			when "call_analysis"
				case @query
					when "new_vs_repeat_callers"
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
					when "follow_up"
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
					else
						@patient_type       += ["Women",
						                        "Men",
						                        "Children (6 - 14)",
						                        "Children (under 5)",
						                        "All"]
						@grouping           += [["By Week", "week"], ["By Month", "month"]]
						@staff               = [["",""]] + get_staff_members_list + [["All","All"]]
						@call_type           = ["","Normal", #"Followup","Non-Patient Tips",
						                        #"Emergency",
						                        "Irrelevant","Dropped","Advice given, not registered", #,
						                        #"All Patient Interaction",
						                        #"All Non-Patient",
						                        "All"]
						#@call_status         = ["","Yes","No", "All"]
						@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]
				end

			when "tips"
				case @query
					when "tips_activity"
						@phone_type         = [["",""],["Community", "community"],["Personal","personal"],
						                       ["Family","family"],["Neighbour","Neighbour"],["All", "all"]]
					when "current_enrollment_totals"

					when "individual_current_enrollments"
						@phone_type         = [["",""],["Community", "community"],["Personal","personal"],
						                       ["Family","family"],["Neighbour","Neighbour"],["All", "all"]]
				end
				@grouping           += [["",""],["By Week", "week"], ["By Month", "month"]]
				@content_type       = [["",""],["Pregnancy", "pregnancy"],["Child","child"],["All", "all"]]
				@language           = [["",""],["Yao","yao"],["Chichewa","chichewa"],["All", "all"]]
				@delivery           = [["",""],["SMS","sms"],["Voice","voice"],["All", "all"]]
				@network_prefix     = [["",""],["09","airtel"],["08","tnm"],["Other","other"],["All", "all"]]
				@destination        = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

			when "family_planning"

				@grouping            += [["By Week", "week"], ["By Month", "month"]]
				@destination         = [["",""],["To CSV Format", "csv"], ["To Screen", "screen"]]

		end

		render :template => "/report/patient_analysis_selection" ,
		       :layout => "application"
	end

	def patient_analysis
		render :layout => false
	end

	def reports
		case  params[:query]
			when 'demographics'
				redirect_to :action       => 'patient_demographics_report',
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]

			when 'health_issues'
				health_task = params[:health_task].downcase.gsub(" ", "_")
				redirect_to :action       => "patient_health_issues_report",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :health_task  => health_task,
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]

			when 'ages_distribution'
				redirect_to :action       => "patient_age_distribution_report",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]

			when 'patient_activity'
				redirect_to :action       => "patient_activity_report",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]

			when 'referral_followup'
				redirect_to :action       => "patient_referral_report",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :outcome      => params[:outcome]

			when 'call_time_of_day'
				redirect_to :action       => "call_time_of_day",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :call_type    => params[:call_type],
				            :call_status  => params[:call_status],
				            :staff_member => params[:staff_member]

			when 'call_day_distribution'
				redirect_to :action       => "call_day_distribution",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :call_type    => params[:call_type],
				            :call_status  => params[:call_status],
				            :staff_member => params[:staff_member]

			when 'call_lengths'
				redirect_to :action       => "call_lengths",
				            :start_date   => params[:start_date],
				            :end_date     => params[:end_date],
				            :grouping     => params[:grouping],
				            :patient_type => params[:patient_type],
				            :report_type  => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :call_type    => params[:call_type],
				            :call_status  => params[:call_status],
				            :staff_member => params[:staff_member]

			when 'tips_activity'
				redirect_to :action        => "tips_activity",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :content_type  => params[:content_type],
				            :language      => params[:language],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :delivery      => params[:delivery],
				            :number_prefix => params[:number_prefix]

			when 'current_enrollment_totals'
				redirect_to :action        => "current_enrollment_totals",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :content_type  => params[:content_type],
				            :language      => params[:language],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :delivery      => params[:delivery],
				            :number_prefix => params[:number_prefix]

			when 'individual_current_enrollments'
				redirect_to :action        => "individual_current_enrollments",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :content_type  => params[:content_type],
				            :language      => params[:language],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict],
				            :phone_type    => params[:phone_type],
				            :delivery      => params[:delivery],
				            :number_prefix => params[:number_prefix]
			when 'family_planning_satisfaction'
				redirect_to :action        => "family_planning_satisfaction",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]
			when 'info_on_family_planning'
				redirect_to :action        => "info_on_family_planning",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]
			when 'new_vs_repeat_callers'
				redirect_to :action        => "new_vs_repeat_callers",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]
			when 'follow_up'
				redirect_to :action        => "follow_up",
				            :start_date    => params[:start_date],
				            :end_date      => params[:end_date],
				            :grouping      => params[:grouping],
				            :report_type   => params[:report_type],
				            :query        => params[:query],
				            :destination  => params[:report_destination],
				            :district     => params[:currentdistrict]
		end
	end

	def patient_demographics_report
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]
		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@query        = params[:query]
		@grouping     = params[:grouping]
		@source       = params[:source] rescue nil
		district = params[:district]

		@report_name  = "Patient Demographics for #{params[:district]} district"
		@report       = Report.patient_demographics(@patient_type, @grouping,
		                                            @start_date, @end_date, district) #rescue []
		@cumulative_total =  @report.inject(0){|total, item| total = total + item[:new_registrations].to_i}
	end

	def patient_age_distribution_report
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]
		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@query        = params[:query]
		@grouping     = params[:grouping]
		@source       = params[:source] rescue nil
		district = params[:district]

		case @patient_type.downcase
			when 'women'
				@special_message = ' -- (Please note that women is any female over 13.)'
			when 'children (under 5)'
				@special_message = ' -- (Plese note that children(under 5) is anyone of 5 years of age and below.)'
			when 'children (6 - 14)'
				@special_message = ' -- (Plese note that children (6 - 14) is anyone between the age of 6 and 14.)'
			when 'men'
				@special_message = ' -- (Please note that Men might is any male above the age of 13.)'
			else
				@special_message = ' -- (Please note that age shows for Women,
				Children (under 5),
				Children (6 - 14),
				& Men)'
		end


		@report_name  = "Patient Age Distribution for #{params[:district]} district"
		@report       = Report.patient_age_distribution(@patient_type, @grouping,
		                                                @start_date, @end_date, district)
	end

	def patient_health_issues_report
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]

		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@health_task  = params[:health_task]

		@query        = params[:query]
		@grouping     = params[:grouping]
		@source       = params[:source] rescue nil
		district     = params[:district]

		@report_name  = "Patient Health Issues (#{@health_task.titleize}) for #{district} district"
		@report       = Report.patient_health_issues(@patient_type, @grouping,
		                                             @health_task, @start_date,
		                                             @end_date, district)
	end

	def patient_activity_report
		@start_date         = params[:start_date]
		@end_date           = params[:end_date]
		@patient_type       = params[:patient_type]
		@report_type        = params[:report_type]
		@query              = params[:query]
		@grouping           = params[:grouping]
		@special_message    = ''
		@source             = params[:source] rescue nil
		district            = params[:district]

		@report_name        = "Patient Activity for #{district} district"
		@report             = Report.patient_activity(@patient_type, @grouping,
		                                     @start_date, @end_date, district)
	end

	def patient_referral_report
		@start_date         = params[:start_date]
		@end_date           = params[:end_date]
		@patient_type       = params[:patient_type]
		@report_type        = params[:report_type]
		@query              = params[:query]
		@grouping           = params[:grouping]
		@outcome            = params[:outcome]
		@special_message    = ''
		@source             = params[:source] rescue nil
		district            = params[:district]

		@report_name        = "Referral Followup (#{@outcome}) for #{district} district"
		@report             = Report.patient_referral_followup(@patient_type, @grouping, @outcome,
		                                              @start_date, @end_date, district)
	end
	def call_time_of_day
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]
		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@query        = params[:query]
		@grouping     = params[:grouping]
		@staff_member = params[:staff_member]
		@call_status  = params[:call_status]
		@call_type    = params[:call_type]
		@special_message = ""
		@source       = params[:source] rescue nil
		district      = params[:district]

		if @staff_member == "All"
			@staff = @staff_member
		else
			@staff = User.find(@staff_member).username
		end

		#raise params.to_yaml
		@report_name  = "Call Time Of Day for #{district} District"
		@report    = Report.call_time_of_day(@patient_type, @grouping, @call_type,
		                                     @call_status, @staff_member,
		                                     @start_date, @end_date, district)

	end
	def call_day_distribution
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]
		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@query        = params[:query]
		@grouping     = params[:grouping]
		@staff_member = params[:staff_member]
		@call_status  = params[:call_status]
		@call_type    = params[:call_type]
		@special_message = ''
		@source       = params[:source] rescue nil
		district      = params[:district]

		if @staff_member == "All"
			@staff = @staff_member
		else
			@staff = User.find(@staff_member).username
		end

		@report_name  = "Call Day Distribution for #{district} District"
		@report    = Report.call_day_distribution(@patient_type, @grouping, @call_type,
		                                          @call_status, @staff_member,
		                                          @start_date, @end_date, district)


	end
	def call_lengths
		@start_date   = params[:start_date]
		@end_date     = params[:end_date]
		@patient_type = params[:patient_type]
		@report_type  = params[:report_type]
		@query        = params[:query]
		@grouping     = params[:grouping]
		@staff_member = params[:staff_member]
		@call_status  = params[:call_status]
		@call_type    = params[:call_type]
		@source       = params[:source] rescue  nil
		district      = params[:district]

		@special_message = "(Please note that the call lengths " +
			  "are in Seconds)"

		if @staff_member == "All"
			@staff = @staff_member
		else
			@staff = User.find(@staff_member).username
		end

		@report_name  = "Call Lengths Report for #{district} District"
		@report    = Report.call_lengths(@patient_type, @grouping, @call_type,
		                                 @call_status, @staff_member,
		                                 @start_date, @end_date, district)

	end
	def new_vs_repeat_callers
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@grouping       = params[:grouping]
		@query          = params[:query]
		@district       = params[:district]
		@report_type    = params[:report_type]

		@report_name  = "New vs Repeat Callers for #{@district} District"
		@report = Report.new_vs_repeat_callers_report(@start_date, @end_date, @grouping, @district)
		#raise @report.to_yaml

	end
	def follow_up
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@grouping       = params[:grouping]
		@query          = params[:query]
		@district       = params[:district]
		@report_type    = params[:report_type]

		@report_name  = "Caller Follow Up Report for #{@district} District "
		@report = Report.follow_up_report(@start_date, @end_date, @grouping, @district) #rescue []


	end
	def family_planning_satisfaction
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@grouping       = params[:grouping]
		@query          = params[:query]
		@district       = params[:district]
		@report_type    = params[:report_type]

		@report_name  = "Family Planning Satisfaction for #{@district}"
		@report = Report.family_planning_satisfaction(@start_date, @end_date, @grouping, @district)

	end
	def info_on_family_planning
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@grouping       = params[:grouping]
		@query          = params[:query]
		@district       = params[:district]
		@report_type    = params[:report_type]

		@report_name  = "Info on Family Planning for #{@district}"
		@report = Report.info_on_family_planning(@start_date, @end_date, @grouping, @district)

	end
	def tips_activity
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@report_type    = params[:report_type]
		@query          = params[:query]
		@grouping       = params[:grouping]
		@content_type   = params[:content_type]
		@language       = params[:language]
		@query          = params[:query]
		@phone_type     = params[:phone_type]
		@delivery       = params[:delivery]
		@number_prefix  = params[:number_prefix]
		@source         = params[:source] rescue nil
		district        = params[:district]

		@special_message = ""

		@report_name  = "Tips Activity for #{district} District"
		@report    = Report.tips_activity(@start_date, @end_date, @grouping,
		                                  @content_type, @language, @phone_type,
		                                  @delivery, @number_prefix, district) rescue []
	end

	def current_enrollment_totals
		@start_date     = params[:start_date]
		@end_date       = params[:end_date]
		@report_type    = params[:report_type]
		@query          = params[:query]
		@grouping       = params[:grouping]
		@content_type   = params[:content_type]
		@language       = params[:language]
		@query          = params[:query]
		@phone_type     = params[:phone_type]
		@delivery       = params[:delivery]
		@number_prefix  = params[:number_prefix]
		@source         = params[:source] rescue nil
		district        = params[:district]

		@special_message = ''

		@report_name  = "Current Enrollment Totals for #{district} District"
		@report    = Report.current_enrollment_totals(@start_date, @end_date, @grouping,
		                                              @content_type, @language, @delivery, @number_prefix, district) rescue []
	end
	def individual_current_enrollments
		@start_date     = Encounter.find(:order => "date_created ASC").date_created.strftime("%Y/%m/%d")
		@end_date       = Encounter.find(:order => "date_created DESC").date_created.strftime("%Y/%m/%d")
		# removed :first before :order in the above two lines
		@report_type    = params[:report_type]
		@query          = params[:query]
		@grouping       = "None"
		@content_type   = "All"
		@language       = "All"
		@phone_type     = "All"
		@delivery       = "All"
		@number_prefix  = "All"
		@source         = params[:source] rescue nil
		district        = params[:district]

		@special_message = ''

		@report_name  = "Individual Current Enrollments for #{district} District"
		@report    = Report.individual_current_enrollments(@start_date, @end_date, @grouping,
		                                                   @content_type, @language, @phone_type,
		                                                   @delivery, @number_prefix, district) rescue []
	end

	def call_history

		@calls = Hash.new(0)

		@calls['Total calls today']         = Report.call_history('today')
		@calls['Total calls yesterday']     = Report.call_history('yesterday')

		@calls['Total calls this week']     = Report.call_history('this_week')
		@calls['Total calls last week']     = Report.call_history('last_week')

		@calls['Total calls this month']    = Report.call_history('this_month')
		@calls['Total calls last month']    = Report.call_history('last_month')

		@calls['Total calls this year']    = Report.call_history('this_year')
		@calls['Total calls last year']    = Report.call_history('last_year')

		render :layout => false
	end

	def detailed_call_history
		reference = params[:reference]

		people = []
		callers = Report.call_history(reference,'detailed')
		(callers || []).each do |caller|
			get_person = PersonName.find(caller.person_id)
			patient = PatientService.get_patient(caller.person_id)
			given_name = patient.first_name
			family_name = patient.last_name

			name = given_name+' '+family_name
			ivr_number = patient.avr_access_number
			phone_number = patient.cell_phone_number
			district = patient.township_division || session[:district]
			hotline_user = User.find(caller.creator).username

			arr = []
			arr.push(caller.person_id)
			arr.push(name)
			arr.push(ivr_number)
			arr.push(phone_number)
			arr.push(district)
			arr.push(hotline_user)
			people.push(arr)
		end
		@callers = people
		render :layout => false
	end
end



