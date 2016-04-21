class Report < ActiveRecord::Base

def self.patient_activity(start_date, end_date, district)
  district_id = District.find_by_name(district).id
  patients_data = []
  date_ranges   = Report.generate_grouping_date_ranges(grouping, start_date, end_date)[:date_ranges]

    date_ranges.map do |date_range|
      
      query   = self.patient_demographics_query_builder(date_range, district_id)
      results = Patient.find_by_sql(query)
      total_calls_for_period = self.call_count_for_period(date_range, patient_type, district_id)
      #data_for_patients = {:patient_data => {}, :statistical_data => {}}
      patient_statistics = {:start_date => date_range.first, 
                            :end_date => date_range.last, :total => 0,
                            :total_calls_for_period => total_calls_for_period.count,
                            :symptoms => 0, :symptoms_pct => 0,
                            :danger => 0, :danger_pct => 0,
                            :info => 0, :info_pct => 0
      }

          new_patients_data = self.all_patients_demographics(results, date_range, district_id)
          total_patients = 0
          new_patients_data[:patient_type].each do |status|
            total_patients += status.last
          end
          patient_statistics[:total] = total_patients

         activity_type.each do |type|
          activity = 'health symptoms' if type == 'symptoms'
          activity = 'danger warning signs' if type == 'danger'
          activity = 'health information requested' if type == 'info'
            essential_params  = self.prepopulate_concept_ids_and_extra_parameters(patient_type, activity)
            data_query = self.patient_activity_query_builder(patient_type, activity, date_range, essential_params, district_id)
            activity_data = Patient.find_by_sql(data_query)
            if type == 'symptoms'
              patient_statistics[:symptoms] = activity_data.first.number_of_patients.to_i
              patient_statistics[:symptoms_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1)  if patient_statistics[:total].to_f != 0
            elsif type == 'danger'
              patient_statistics[:danger] = activity_data.first.number_of_patients.to_i
              patient_statistics[:danger_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            elsif type == 'info'
              patient_statistics[:info] = activity_data.first.number_of_patients.to_i
              patient_statistics[:info_pct] = (activity_data.first.number_of_patients.to_f / patient_statistics[:total].to_f * 100).round(1) if patient_statistics[:total].to_f != 0
            end
         end

      end # end case
      patients_data << patient_statistics
    end
    patients_data
  end
end
