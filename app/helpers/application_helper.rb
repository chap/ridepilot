module ApplicationHelper  
  def current_provider
    current_user.try(:current_provider)
  end

  def current_provider_id
    current_provider.try(:id)
  end

  def show_dispatch?
    current_user && current_provider && current_provider.dispatch?
  end
  
  def show_scheduling?
    current_user && current_provider.scheduling?
  end

  def is_admin_or_system_admin?
    current_user.present? && (current_user.admin? || current_user.super_admin?)
  end
  
  def new_device_pool_members_options(members)
    options_for_select [["",""]] + members.map { |d| [d.name, d.id] }
  end
  
  def display_trip_result(trip_result)
    trip_result.try(:name) || "Pending"
  end

  def format_full_datetime(time)
    time.strftime "%l:%M%P %a %d-%b-%Y" if time
  end

  def format_simple_full_datetime(time)
    time.strftime "%B %d, %Y %I:%M %p" if time
  end
  
  def format_time_for_listing(time)
    time.strftime('%l:%M%P') if time
  end

  def format_time_for_listing_day(time)
    time.strftime('%d-%b-%Y %a') if time
  end

  def format_time_as_title_for_listing_day(time)
    time.strftime('%b %d, %Y') if time
  end

  def format_date(time, format = 'us')
    time.strftime('%m/%d/%Y') if time
  end
  
  def format_date_for_daily_manifest(date)
    date.strftime('%A, %v') if date
  end
  
  def delete_trippable_link(trippable)
    if can? :destroy, trippable
      link_to trippable.trips.present? ? translate_helper("merge") : translate_helper("delete"), trippable, :class => 'delete'
    end
  end
  
  def can_delete?(trippable)
    trippable.trips.blank? && can?( :destroy, trippable )
  end
  
  def format_newlines(text)
    return text.gsub("\n", "<br/>")
  end

  def bodytag_class
    a = controller.controller_name.underscore
    b = controller.action_name.underscore
    "#{a} #{b}".gsub(/_/, '-')
  end

  def collect_weekdays(schedule)
    weekdays = []
    if schedule.monday
      weekdays.push :monday
    end
    if schedule.tuesday
      weekdays.push :tuesday
    end
    if schedule.wednesday
      weekdays.push :wednesday
    end
    if schedule.thursday
      weekdays.push :thursday
    end
    if schedule.friday
      weekdays.push :friday
    end
    if schedule.saturday
      weekdays.push :saturday
    end
    if schedule.sunday
      weekdays.push :sunday
    end
    return weekdays
  end

  def weekday_abbrev(weekday)
    weekday_abbrevs = {
      :monday => 'M',
      :tuesday => 'T',
      :wednesday => 'W',
      :thursday => 'R',
      :friday => 'F',
      :saturday => 'S',
      :sunday => 'U'
    }

    return weekday_abbrevs[weekday]
  end

  def is_add_user_allowed?(user)
    user.present? && ( user.admin? || user.super_admin?)
  end

  def add_tooltip(key)
    if TranslationEngine.translation_exists?(key)
      html = '<i class="fa fa-question-circle fa-2x pull-right label-help" style="margin-top:-4px;" title data-content="'
      html << TranslationEngine.translate_text(key.to_sym)
      html << '" aria-label="'
      html << TranslationEngine.translate_text(key.to_sym)
      html << '" tabindex="0"></i>'
      return html.html_safe
    end
  end

  def reimbursement_cost_for_trips(provider, trips)
    number_to_currency ReimbursementRateCalculator.new(provider).total_reimbursement_due_for_trips(trips)
  end


  def can_access_admin_tab(a_user)
    a_user && a_user.super_admin?
  end

  def can_access_provider_settings_tab(a_user, a_provider)
    a_user && a_user.admin? && can?(:read, a_provider)
  end

  def display_linked_trip_info(trip)
    linking_to_text = translate_helper(:linking_to)
    if trip.is_return?
      trip.outbound_trip ? "<a href='#{trip_path(trip.outbound_trip)}'>#{linking_to_text}: #{trip.outbound_trip.id}</a>" : ""
    else
      trip.return_trip ? "<a href='#{trip_path(trip.return_trip)}'>#{linking_to_text}: #{trip.return_trip.id}</a>" : ""
    end
  end

  def format_phone_number(phone_number)
    return "" if phone_number.blank?

    us_phony = Phony['1'] # US phone validation

    norm_number = us_phony.normalize(phone_number.to_s)

    number_to_phone norm_number, area_code: true
  end

  def show_provider_setting_alert(provider, section)
    return unless provider && !section.blank?

    has_alert = case section
    when 'general'
      provider.operating_hours.empty?
    when 'users'
      provider.roles.empty?
    when 'drivers'
      provider.drivers.empty?
    when 'vehicles'
      provider.vehicles.empty? 
    when 'addresses'
      ProviderCommonAddress.where(provider: provider).empty?
    when 'customers'
      Customer.for_provider(provider.try(:id)).empty?
    end

    if has_alert
      "<div class='pull-right'><i style='color: red;' class='fa fa-exclamation-triangle'></i></div>".html_safe
    end
  end

  def get_vehicle_warnings(vehicle, run_date = nil)
    return {} unless vehicle

    class_name = ''
    warning_msg = ''

    if run_date && vehicle.active_for_date?(run_date)
      class_name = "overdue-danger"
      warning_msg = "Inactive on the run day (#{format_date run_date})."
    end
    
    tips = []

    if vehicle.vehicle_compliances.legal.overdue.any?
      tips << "legal requirement"
      class_name = 'overdue-danger'
    end

    if vehicle.vehicle_maintenance_compliances.has_overdue?
      tips << "maintenance compliance"
      class_name = 'overdue-warning' if class_name.blank?
    end

    if vehicle.vehicle_compliances.non_legal.overdue.any?
      tips << "compliance event"
      class_name = 'overdue-warning' if class_name.blank?
    end

    if vehicle.expired?
      tips << "warranty"
      class_name = 'overdue-warning' if class_name.blank?
    end

    overdue_msg = "Overdue: " + tips.join(', ') if tips.any?
    
    {
      class_name: class_name,
      tips: warning_msg ? warning_msg + " " + overdue_msg.to_s : overdue_msg.to_s
    }
  end 

  def get_driver_warnings(driver, run_date = nil)
    return {} unless driver

    class_name = ''
    warning_msg = ''

    if run_date && driver.active_for_date?(run_date)
      class_name = "overdue-danger"
      warning_msg = "Inactive on the run day (#{format_date run_date})."
    end

    tips = []
    
    if driver.driver_compliances.legal.overdue.any?
      tips << "legal requirement"
      class_name = 'overdue-danger'
    end

    if driver.driver_compliances.non_legal.overdue.any?
      tips << "compliance event"
      class_name = 'overdue-warning' if class_name.blank?
    end

    overdue_msg = "Overdue: " + tips.join(', ') if tips.any?
    
    {
      class_name: class_name,
      tips: warning_msg ? warning_msg + " " + overdue_msg.to_s : overdue_msg.to_s
    }
  end 

end
