class EncountersController < ApplicationController

  def create
    @patient = Patient.find(params[:encounter][:patient_id])
  end

  def new
    @selected_value = []
    @select_options = select_options
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    render :action => params[:encounter_type] if params[:encounter_type]
  end

  def select_options
    select_options = {
        'maternal_health_info' => [
            ['', ''],
            ['Healthcare visits', 'HEALTHCARE VISITS'],
            ['Nutrition', 'NUTRITION'],
            ['Body changes', 'BODY CHANGES'],
            ['Discomfort', 'DISCOMFORT'],
            ['Concerns', 'CONCERNS'],
            ['Emotions', 'EMOTIONS'],
            ['Warning signs', 'WARNING SIGNS'],
            ['Routines', 'ROUTINES'],
            ['Beliefs', 'BELIEFS'],
            ['Baby\'s growth', 'BABY\'S GROWTH'],
            ['Milestones', 'MILESTONES'],
            ['Prevention', 'PREVENTION'],
            ['Family planning','FAMILY PLANNING'],
            ['Birth planning - male','BIRTH PLANNING MALE'],
            ['Birth planning - female','BIRTH PLANNING FEMALE'],
            ['Other','OTHER']
        ],
        'maternal_health_symptoms' => [
            ['',''],
            ['Vaginal Bleeding during pregnancy','VAGINAL BLEEDING DURING PREGNANCY'],
            ['Postnatal bleeding','POSTNATAL BLEEDING'],
            ['Fever during pregnancy','FEVER DURING PREGNANCY SYMPTOM'],
            ['Postnatal fever','POSTNATAL FEVER SYMPTOM'],
            ['Headaches','HEADACHES'],
            ['Fits or convulsions','FITS OR CONVULSIONS SYMPTOM'],
            ['Swollen hands or feet','SWOLLEN HANDS OR FEET SYMPTOM'],
            ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SYMPTOM'],
            ['No fetal movements','NO FETAL MOVEMENTS SYMPTOM'],
            ['Water breaks','WATER BREAKS SYMPTOM'],
            ['Postnatal discharge - bad smell','POSTNATAL DISCHARGE BAD SMELL'],
            ['Abdominal pain','ABDOMINAL PAIN'],
            ['Problems with monthly periods','PROBLEMS WITH MONTHLY PERIODS'],
            ['Problems with family planning method','PROBLEMS WITH FAMILY PLANNING METHOD'],
            ['Infertility','INFERTILITY'],
            ['Frequent miscarriages','FREQUENT MISCARRIAGES'],
            ['Vaginal bleeding (not during pregnancy)','VAGINAL BLEEDING NOT DURING PREGNANCY'],
            ['Vaginal itching','VAGINAL ITCHING'],
            ['Vaginal discharge ','VAGINAL DISCHARGE'],
            ['Other','OTHER']
        ],
        #TODO - add the new symptoms above, danger signs below on to concept server
        'danger_signs' => [
            ['',''],
            ['Heavy vaginal bleeding during pregnancy','HEAVY VAGINAL BLEEDING DURING PREGNANCY'],
            ['Excessive postnatal bleeding','EXCESSIVE POSTNATAL BLEEDING'],
            ['Fever during pregnancy','FEVER DURING PREGNANCY SIGN'],
            ['Postanatal fever','POSTNATAL FEVER SIGN'],
            ['Severe headache','SEVERE HEADACHE'],
            ['Fits or convulsions','FITS OR CONVULSIONS SIGN'],
            ['Swollen hands, feet, and face','SWOLLEN HANDS OR FEET SIGN'],
            ['Paleness of the skin and tiredness','PALENESS OF THE SKIN AND TIREDNESS SIGN'],
            ['No fetal movements','NO FETAL MOVEMENTS SIGN'],
            ['Water breaks','WATER BREAKS SIGN'],
            ['Severe abdominal pain','ACUTE ABDOMINAL PAIN']
        ],
        'child_health_info' => [
            ['',''],
            ['Sleeping','SLEEPING'],
            ['Feeding problems','FEEDING PROBLEMS'],
            ['crying','CRYING'],
            ['Bowel movements','BOWEL MOVEMENTS'],
            ['Skin rashes','SKIN RASHES'],
            ['Skin infections','SKIN INFECTIONS'],
            ['Umbilicus infection','UMBILICUS INFECTION'],
            ['Growth milestones','GROWTH MILESTONES'],
            ['Accessing healthcare services','ACCESSING HEALTHCARE SERVICES'],
            #        ['Family planning','Family planning'],
            ['Other','OTHER']
        ],
        'type_of_message_content' => [
            ['',''],
            ['Pregnancy', 'Pregnancy'],
            ['Postnatal', 'Postnatal'],
            ['Child', 'Child'],
            ['WCBA', 'WCBA'],
            #['Family planning', 'Family planning'], #TODO check if the reports will work well after adding this to the list
            ['Observer', 'Observer']
        ],
        'message_type' => [
            ['', ''],
            ['SMS', 'SMS'],
            ['Voice','VOICE']
        ],
        'phone_type' => [
            ['', ''],
            ['Community phone', 'COMMUNITY PHONE'],
            ['Personal phone', 'PERSONAL PHONE'],
            ['Family member phone', 'FAMILY MEMBER PHONE'],
            ['Neighbour\'s phone', 'NEIGHBOUR\'S PHONE'] #TODO check if this will work
        ],
        'language_type' => [
            ['', ''],
            ['Chichewa', 'CHICHEWA'],
            ['Chiyao', 'CHIYAO']
        ],
        'pregnancy_status' => [
            ['', ''],
            ['Pregnant', 'Pregnant'],
            ['NOT pregnant', 'NOT pregnant'],
            ['Delivered', 'Delivered'],
            ['Miscarried', 'Miscarried']
        ],
        'child_danger_signs_greater_zero_outcome' => [
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Given advice', 'GIVEN ADVICE'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS']
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ] #'REGISTERED FOR TIPS AND REMINDERS']
        ],
        'child_symptoms_greater_zero_outcome' => [
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Given advice', 'GIVEN ADVICE'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS']
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ] #'REGISTERED FOR TIPS AND REMINDERS']
        ],
        'general_outcome' => [
            ['Given advice', 'GIVEN ADVICE'],
            ['Referred to nearest village clinic', 'REFERRED TO NEAREST VILLAGE CLINIC'],
            ['Referred to a health centre', 'REFERRED TO A HEALTH CENTRE'],
            ['Hospital', 'HOSPITAL'],
            ['Nurse consultation', 'NURSE CONSULTATION'],
            ['Registered for Tips and reminders','REGISTERED FOR TIPS AND REMINDERS' ], #'REGISTERED FOR TIPS AND REMINDERS'],
            ['Referral to emergency transport','REFERRAL TO EMERGENCY TRANSPORT' ],
            ['Other','OTHER' ]
        ],
        'referral_reasons' => [
            ['',''],
            ['Danger signs observed', 'DANGER SIGNS OBSERVED'],
            ['Physical exam needed', 'PHYSICAL EXAM NEEDED'],
            ['Village clinic not accessible', 'VILLAGE CLINIC NOT ACCESSIBLE'],
            ['Follow-up on previous treatment', 'FOLLOW-UP ON PREVIOUS TREATMENT'],
            ['No health center or Hospital referral', 'NO HEALTH CENTER OR HOSPITAL REFERRAL'],
            ['Other', 'OTHER']
        ],

        'reason_for_not_attending_anc' => [
            ['',''],
            ['Clinic too far','Clinic too far'],
            ['No time to go','No time to go'],
            ['Poor care at clinic','Poor care at clinic'],
            ['Too early in pregnancy','Too early in pregnancy'],
            ['Did not know I should go','Did not know I should go'],
            ['HSA unable to visit client','HSA unable to visit client'],
            ['HSA cannot find client','HSA cannot find client'],
            ['Client died','Client died'],
            ['Client miscarried','Client miscarried'],
            ['Client delivered','Client delivered'],
            ['Client moved','Client moved'],
            ['Other','Other']
        ],

        'reason_for_not_visiting_anc_client' => [
            ['',''],
            ['HSA too busy','HSA too busy'],
            ['HSA Cannot find client','HSA Cannot find client'],
            ['Client moved','Client moved'],
            ['Client miscarried','Client miscarried'],
            ['Client delivered','Client delivered'],
            ['Client died','Client died'],
            ['Other','Other']
        ]
    }
  end
end
