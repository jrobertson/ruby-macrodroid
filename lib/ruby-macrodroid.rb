#!/usr/bin/env ruby

# file: ruby-macrodroid.rb

require 'uuid'
require 'rxfhelper'
require 'chronic_cron'


class TriggersNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    triggers(params)

  end

  def triggers(params) 

    get /^at (\d+:\d+(?:[ap]m)?) on (.*)/i do |time, days|
      [TimerTrigger, {time: time, days: days}]
    end


  end

  alias find_trigger run_route

end

class ActionsNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    actions(params)

  end

  def actions(params) 

    get /^message popup: (.*)/i do |msg|
      [ToastAction, {msg: msg}]
    end


  end

  alias find_action run_route

end

class ConstraintsNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    constraints(params)

  end

  def constraints(params) 

    get /^airplane mode (.*)/i do |state|
      [AirplaneModeConstraint, {enabled: (state =~ /^enabled|on$/) == 0}]
    end

  end

  alias find_constraint run_route

end

module Params

  refine Hash do

    # turns keys from camelCase into snake_case

    def to_snake_case(h=self)

      h.inject({}) do |r, x|

        key, value = x
        #puts 'value: ' + value.inspect
        
        val = if value.is_a?(Hash) then
          to_snake_case(value)
        elsif value.is_a?(Array) and value.first.is_a? Hash
          value.map {|row| to_snake_case(row)}
        else
          value          
        end
        
        r.merge key.to_s.sub(/^m_/,'').gsub(/[A-Z][a-z]/){|x| '_' + 
          x.downcase}.gsub(/[a-z][A-Z]/){|x| x[0] + '_' + x[1].downcase}\
          .downcase.to_sym => val

      end
    end

    # turns keys from snake_case to CamelCase
    def to_camel_case(h=self)
      
      h.inject({}) do |r,x|
                
        key, value = x   
        
        val = if value.is_a?(Hash) then
          to_camel_case(value)
        elsif value.is_a?(Array) and value.first.is_a? Hash
          value.map {|row| to_camel_case(row)}
        else
          value          
        end
        
        r.merge({key.to_s.gsub(/(?<!^m)_[a-z]/){|x| x[-1].upcase} => val})
      end
      
    end


  end

end

class Macro
  using ColouredText
  using Params

  attr_reader :local_variables, :triggers, :actions, :constraints, :guid
  attr_accessor :title

  def initialize(name=nil, debug: false)

    @title, @debug = name, debug
    
    puts 'inside Macro#initialize' if @debug    
          
    @local_variables, @triggers, @actions, @constraints = [], [], [], []
    @h = {}
    
  end
  
  def add(obj)

    if obj.kind_of? Trigger then
      
      puts 'trigger found' if @debug
      @triggers << obj
      
    elsif obj.kind_of? Action
      
      puts 'action found' if @debug
      @actions << obj
      
    elsif obj.kind_of? Constraint
      
      puts 'constraint found' if @debug
      @constraints << obj
      
    end
    
  end

  def to_h()

    h = {
      local_variables: @local_variables,
      m_trigger_list: @triggers.map(&:to_h),
      m_action_list: @actions.map(&:to_h),
      m_constraint_list: @constraints.map(&:to_h),
      m_description: '',
      m_name: @title,
      m_excludeLog: false,
      m_GUID: guid(),
      m_isOrCondition: false,
      m_enabled: false,
      m_descriptionOpen: false,
      m_headingColor: 0
    }
    
    puts 'h: ' + h.inspect if @debug

    @h.merge(h)
  end

  def import_h(h)

    # fetch the local variables
    @local_variables = h['local_variables']
    
    # fetch the triggers
    @triggers = h[:trigger_list].map do |trigger|
      
      object(trigger.to_snake_case)

    end

    @actions = h[:action_list].map do |action|
      object(action.to_snake_case)
    end

    # fetch the constraints                               
    @constraints = h[:constraint_list].map do |constraint|
      object(constraint.to_snake_case)
    end                               
    
    @h = h

    %i(local_variables m_trigger_list m_action_list m_constraint_list)\
      .each {|x| @h[x] = [] }

    @h

  end
  
  def import_xml(node)
    
    if @debug then
      puts 'inside Macro#import_xml'
      puts 'node: ' + node.xml.inspect
    end
    
    @title = node.attributes[:name]

    if node.element('triggers') then
      
      # level 2
      
      # get all the triggers
      @triggers = node.xpath('triggers/*').map do |e|
        
        puts 'e.name: ' + e.name.inspect if @debug
        {timer: TimerTrigger}[e.name.to_sym].new(e.attributes.to_h)
        
      end

      # get all the actions
      @actions = node.xpath('actions/*').map do |e|
        
        if e.name == 'notification' then
          
          case e.attributes[:type].to_sym
          when :popup          
            e.attributes.delete :type
            ToastAction.new e.attributes.to_h
          end
          
        end

      end    
                               
      # get all the constraints
      @constraints = node.xpath('constraints/*').map do |e|
        
        puts 'e.name: ' + e.name.inspect if @debug
        {airplanemode: AirplaneModeConstraint}[e.name.to_sym].new(e.attributes.to_h)

      end                                  
      
    else
      
      # Level 1
      
      tp = TriggersNlp.new      
      
      @triggers = node.xpath('trigger').map do |e|
        
        r = tp.find_trigger e.text
        
        puts 'found trigger ' + r.inspect if @debug
        
        if r then
          r[0].new(r[1])
        end
        
      end
      
      ap = ActionsNlp.new      
      
      @actions = node.xpath('action').map do |e|
        
        r = ap.find_action e.text
        puts 'found action ' + r.inspect if @debug
        
        if r then
          r[0].new(r[1])
        end
        
      end      
                               
      cp = ConstraintsNlp.new      
      
      @constraints = node.xpath('constraint').map do |e|
        
        r = cp.find_constraint e.text
        puts 'found constraint ' + r.inspect if @debug
        
        if r then
          r[0].new(r[1])
        end
        
      end                                   
      
    end
    
    self
    
  end
  
  def match?(triggerx, detail={time: $env[:time]} )
                
    if @triggers.any? {|x| x.type == triggerx and x.match?(detail) } then
      
      if @debug then
        puts 'checking constraints ...' 
        puts '@constraints: ' + @constraints.inspect
      end
      
      if @constraints.all? {|x| x.match?($env.merge(detail)) } then
      
        true
        
      else

        return false
        
      end
      
    end
    
  end
  
  def run()
    @actions.map(&:invoke)
  end  

  private
  
  def guid()
    '-' + rand(1..9).to_s + 18.times.map { rand 9 }.join    
  end

  def object(h={})

    puts ('inside object h:'  + h.inspect).debug if @debug
    klass = Object.const_get h[:class_type]
    klass.new h
  end

end


class MacroDroid
  using ColouredText
  using Params  

  attr_reader :macros

  def initialize(obj=nil, debug: false)

    @debug = debug    
    
    if obj then
      
      s, _ = RXFHelper.read(obj)    
      
      if s[0] == '{' then
        import_json(s) 
      elsif  s[0] == '<'
        import_xml(s)
        @h = build_h
      else
        import_xml(text_to_xml(s))
        @h = build_h
      end
      
    else
      
      @h = build_h()
      
      @macros = []
      
    end
  end
  
  def add(macro)
    @macros << macro
  end

  def build_h()
    
    puts 'inside Macro#build_h' if @debug
    {
      cell_tower_groups: [],
      cell_towers_ignore: [],
      drawer_configuration: {
        drawer_items: [],
        background_color: -1,
        header_color: 12692882,
        left_side: false,
        swipe_area_color: -7829368,
        swipe_area_height: 20,
        swipe_area_offset: 40,
        swipe_area_opacity: 80,
        swipe_area_width: 14,
        visible_swipe_area_width: 0
      },
      variables: [],
      user_icons: [],
      geofence_data: {
        geofence_map: {}
      },
      macro_list: []

    }    
  end

  def export_json()

    to_h.to_json

  end

  alias to_json export_json

  def import_json(s)

    @h = JSON.parse(s, symbolize_names: true).to_snake_case
    puts ('@h: ' + @h.pretty_inspect).debug if @debug

    @macros = @h[:macro_list].map do |macro|

      puts ('macro: ' + macro.pretty_inspect).debug if @debug
      m = Macro.new(debug: @debug)
      m.import_h(macro)
      m

    end

    @h[:macro_list] = []
    
  end
  
  def import_xml(raws)
    
    s = RXFHelper.read(raws).first
    puts 's: ' + s.inspect if @debug
    doc = Rexle.new(s)
    puts 'after doc' if @debug
    
    @macros = doc.root.xpath('macro').map do |node|
          
      macro = Macro.new @title, debug: @debug
      macro.import_xml(node)
      macro
      
    end
  end
  
  def text_to_xml(s)
    
    a = s.split(/.*(?=^m:)/); a.shift
    a.map!(&:chomp)

    macros = a.map do |x|

      lines = x.lines
      puts 'lines: ' + lines.inspect if @debug
      
      name = lines.shift[/^m: +(.*)/,1]
      h = {t: [], a: [], c: []}

      lines.each {|line| h[line[0].to_sym] << line[/^\w: +(.*)/,1] }
      triggers = h[:t].map {|text| [:trigger, {}, text]}
      actions = h[:a].map {|text| [:action, {}, text]}
      constraints = h[:c].map {|text| [:constraint, {}, text]}

      [:macro, {name: name},'', *triggers, *actions, *constraints]

    end

    doc = Rexle.new([:macros, {}, '', *macros])
    doc.root.xml pretty: true    
    
  end

  def to_h()

    @h.merge(macro_list:  @macros.map(&:to_h)).to_camel_case

  end



end

class MacroObject
  using ColouredText
  
  attr_reader :type
  attr_accessor :options

  def initialize(h={})
    
    @h = {constraint_list: [], is_or_condition: false, 
          is_disabled: false}.merge(h)
    @list = []
    
    # fetch the class name and convert from camelCase to snake_eyes
    @type = self.class.to_s.sub(/Trigger|Action$/,'')\
        .gsub(/\B[A-Z][a-z]/){|x| '_' + x.downcase}\
        .gsub(/[a-z][A-Z]/){|x| x[0] + '_' + x[1].downcase}\
        .downcase.to_sym
  end

  def to_h()

    h = @h

    h2 = h.inject({}) do |r,x|
      puts 'x: ' + x.inspect if @debug
      key, value = x
      puts 'key: ' + key.inspect if @debug
      new_key = key.to_s.gsub(/\w_\w/){|x| x[0] + x[-1].upcase}
      new_key = new_key.prepend 'm_' unless @list.include? new_key
      new_key = 'm_SIGUID' if new_key == 'm_siguid'
      r.merge(new_key => value)
    end
    
    h2.merge('m_classType' => self.class.to_s)

  end

  protected
  
  def filter(options, h)
    
    (h.keys - options.keys).each {|key| h.delete key }    
    return h
    
  end
  
  def uuid()
    UUID.new.generate
  end
  
end

class Trigger < MacroObject

  def initialize(h={})    
    super({fakeIcon: 0}.merge(h))
    @list << 'fakeIcon'
  end
  
  def match?(detail={})    

    detail.all? {|key,value| @h[key] == value}
    
  end

end


# Category: Applications
#
class WebHookTrigger < Trigger

  def initialize(h={})

    options = {
      identifier: ''
    }

    super(options.merge h)

  end

end

# Category: Applications
#
# Also known as Wifi State Change
#
# wifi_state options:
#   0 - Wifi Enabled
#   1 - Wifi Disabled
#   2 - Connected to network
#     ssid_list options:
#       ["Any Network"] 
#       ["some Wifi SSID"] - 1 or more SSID can be supplied
#   3 - Disconnected from network
#     ssid_list options:
#       ["Any Network"] 
#       ["some Wifi SSID"] - 1 or more SSID can be supplied

class WifiConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      ssid_list: [""],
      wifi_state: 2
    }

    super(options.merge h)

  end

end

# Category: Applications
#
class ApplicationInstalledRemovedTrigger < Trigger

  def initialize(h={})

    options = {
      application_name_list: [],
      package_name_list: [],
      installed: true,
      application_option: 0,
      updated: false
    }

    super(options.merge h)

  end

end

# Category: Applications
#
class ApplicationLaunchedTrigger < Trigger

  def initialize(h={})

    options = {
      application_name_list: ["Chrome"],
      package_name_list: ["com.android.chrome"],
      launched: true
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class BatteryLevelTrigger < Trigger

  def initialize(h={})

    options = {
      battery_level: 50,
      decreases_to: true,
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class BatteryTemperatureTrigger < Trigger

  def initialize(h={})

    options = {
      decreases_to: true,
      option: 0,
      temperature: 30
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class PowerButtonToggleTrigger < Trigger

  def initialize(h={})

    options = {
      num_toggles: 3
    }

    super(options.merge h)

  end

end


# Category: Battery/Power
#
class ExternalPowerTrigger < Trigger

  def initialize(h={})

    options = {
      power_connected_options: [true, true, true],
      has_set_usb_option: true,
      power_connected: true,
      has_set_new_power_connected_options: true
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class CallActiveTrigger < Trigger

  def initialize(h={})

    options = {
      contact_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}],
      secondary_class_type: 'CallActiveTrigger',
      signal_on: true
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class IncomingCallTrigger < Trigger

  def initialize(h={})

    options = {
      incoming_call_from_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}],
      group_id_list: [],
      group_name_list: [],
      option: 0,
      phone_number_exclude: false
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class OutgoingCallTrigger < Trigger

  def initialize(h={})

    options = {
      outgoing_call_to_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}],
      group_id_list: [],
      group_name_list: [],
      option: 0,
      phone_number_exclude: false
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class CallEndedTrigger < Trigger

  def initialize(h={})

    options = {
      contact_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}],
      group_id_list: [],
      group_name_list: [],
      option: 0,
      phone_number_exclude: false
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class CallMissedTrigger < Trigger

  def initialize(h={})

    options = {
      contact_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}]
    }

    super(options.merge h)

  end

end

# Category: Call/SMS
#
class IncomingSMSTrigger < Trigger

  def initialize(h={})

    options = {
      sms_from_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}],
      group_id_list: [],
      group_name_list: [],
      sms_content: '',
      option: 0,
      excludes: false,
      exact_match: false,
      enable_regex: false,
      sms_number_exclude: false
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class WebHookTrigger < Trigger

  def initialize(h={})

    options = {
      identifier: ''
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class WifiConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      ssid_list: [],
      wifi_state: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class BluetoothTrigger < Trigger

  def initialize(h={})

    options = {
      device_name: 'Any Device',
      bt_state: 0,
      any_device: false
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class HeadphonesTrigger < Trigger

  def initialize(h={})

    options = {
      headphones_connected: true,
      mic_option: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class SignalOnOffTrigger < Trigger

  def initialize(h={})

    options = {
      signal_on: true
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class UsbDeviceConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
# Also known as Wifi SSID Transition
#
# options:
#   in_range: true | false
#   wifi_cell_info: {display_name: "some Wifi SSID", 
#                    ssid: "some Wifi SSID"} - 1 or more allowed
#
class WifiSSIDTrigger < Trigger

  def initialize(h={})

    options = {
      wifi_cell_info_list: [{:display_name=>"", :ssid=>""}],
      ssid_list: [],
      in_range: true
    }

    super(options.merge h)

  end
  
  def to_h()
    
    h = super()
    val = h[:m_inRange]
    
    h[:m_InRange] = val
    h.delete :m_inRange
    
    return h
    
  end

end

# Category: Date/Time
#
class CalendarTrigger < Trigger

  def initialize(h={})

    options = {
      title_text: '',
      detail_text: '',
      calendar_name: 'Contacts',
      calendar_id: '3',
      availability: 0,
      check_in_advance: false,
      advance_time_seconds: 0,
      event_start: true,
      ignore_all_day: false,
      negative_advance_check: false,
      enable_regex: false
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class TimerTrigger < Trigger
  using ColouredText
  

  def initialize(h={})

    puts 'TimerTrigger h: ' + h.inspect if $debug
    
    if h[:days] then
      
      days = [false] * 7
      
      h[:days].split(/, */).each do |x|

        r = Date::DAYNAMES.grep /#{x}/i
        i = Date::DAYNAMES.index(r.first)
        days[i-1] = true

      end      
      
      h[:days_of_week] = days
      
    end
    
    if h[:time] then
      
      t = Time.parse(h[:time])
      h[:hour], h[:minute] = t.hour, t.min
      
    end
    
    #puts ('h: ' + h.inspect).debug

    options = {
      alarm_id: uuid(),
      days_of_week: [false, false, false, false, false, false, false],
      minute: 10,
      hour: 7,
      use_alarm: false
    }
            
    super(options.merge filter(options,h))

  end
  
  def match?(detail={time: $env[:time]})

    a = @h[:days_of_week]
    a.unshift a.pop

    dow = a.map.with_index {|x, i| x ? i : nil }.compact.join(',')

    s = "%s %s * * %s" % [@h[:minute], @h[:hour], dow]
    
    if $debug then
      puts 's: ' + s.inspect 
      puts 'detail: ' + detail.inspect
      puts '@h: ' + @h.inspect
    end
    
    ChronicCron.new(s, detail[:time]).to_time == detail[:time]

  end

end

# Category: Date/Time
#
class StopwatchTrigger < Trigger

  def initialize(h={})

    options = {
      stopwatch_name: 'timer1',
      seconds: 240
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
# Also known as Day of Week/Month
#
# month_of_year equal to 0 means it occurs every month
# day_of_week starts with a Monday (value is 0)
# 
class DayTrigger < Trigger

  def initialize(h={})

    options = {
      alarm_id: uuid(),
      hour: 9,
      minute: 0,
      month_of_year: 0,
      option: 0,
      day_of_week: 2,
      day_of_month: 0,
      use_alarm: false
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
# Regular Interval
#
class RegularIntervalTrigger < Trigger

  def initialize(h={})

    options = {
      ignore_reference_start_time: false,
      minutes: 0,
      seconds: 7200,
      start_hour: 9,
      start_minute: 10,
      use_alarm: false
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
# Airplane Mode Changed
#
# options: 
#   Airplane Mode Enabled
#   Airplane Mode Disabled
#
# shorthand example:
#   airplanemode: enabled
#
class AirplaneModeTrigger < Trigger

  def initialize(h={})

    options = {
      airplane_mode_enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class AutoSyncChangeTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class DayDreamTrigger < Trigger

  def initialize(h={})

    options = {
      day_dream_enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class DockTrigger < Trigger

  def initialize(h={})

    options = {
      dock_type: 0
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class GPSEnabledTrigger < Trigger

  def initialize(h={})

    options = {
      gps_mode_enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class MusicPlayingTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end


# Category: Device Events
#
class DeviceUnlockedTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class AutoRotateChangeTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class ClipboardChangeTrigger < Trigger

  def initialize(h={})

    options = {
      text: '',
      enable_regex: false
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class BootTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class IntentReceivedTrigger < Trigger

  def initialize(h={})

    options = {
      action: '',
      extra_params: [],
      extra_value_patterns: [],
      extra_variables: [],
      enable_regex: false
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class NotificationTrigger < Trigger

  def initialize(h={})

    options = {
      text_content: '',
      package_name_list: ["Any Application"],
      application_name_list: ["Any Application"],
      exclude_apps: false,
      ignore_ongoing: true,
      option: 0,
      exact_match: false,
      excludes: false,
      sound_option: 0,
      supress_multiples: true,
      enable_regex: false
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class ScreenOnOffTrigger < Trigger

  def initialize(h={})

    options = {
      screen_on: true
    }

    super(options.merge h)

  end

end

# Category: Device Events
#
class SilentModeTrigger < Trigger

  def initialize(h={})

    options = {
      silent_enabled: true
    }

    super(options.merge h)

  end

end

# Category: Location
#
class WeatherTrigger < Trigger

  def initialize(h={})

    options = {
      humidity_above: true,
      humidity_value: 50,
      option: 4,
      temp_below: true,
      temp_celcius: true,
      temperature: 0,
      weather_condition: 0,
      wind_speed_above: true,
      wind_speed_value: 0,
      wind_speed_value_mph: 0
    }

    super(options.merge h)

  end

end

# Category: Location
#
class GeofenceTrigger < Trigger

  def initialize(h={})

    options = {
      update_rate_text: '5 Minutes',
      geofence_id: '',
      geofence_update_rate_minutes: 5,
      trigger_from_unknown: false,
      enter_area: true
    }

    super(options.merge h)

  end

end

# Category: Location
#
class SunriseSunsetTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0,
      time_adjust_seconds: 0
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class ActivityRecognitionTrigger < Trigger

  def initialize(h={})

    options = {
      confidence_level: 50,
      selected_index: 1
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class ProximityTrigger < Trigger

  def initialize(h={})

    options = {
      near: true,
      selected_option: 0
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class ShakeDeviceTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class FlipDeviceTrigger < Trigger

  def initialize(h={})

    options = {
      any_start: false,
      face_down: true,
      work_with_screen_off: false
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class OrientationTrigger < Trigger

  def initialize(h={})

    options = {
      check_orientation_alive: true,
      option: 0
    }

    super(options.merge h)

  end

end

# Category: User Input
#
class FloatingButtonTrigger < Trigger

  def initialize(h={})

    options = {
      image_resource_id: 0,
      icon_bg_color: -9079435,
      alpha: 100,
      padding: 20,
      force_location: false,
      show_on_lock_screen: false,
      size: 0,
      transparent_background: false,
      x_location: 0,
      y_location: 0
    }

    super(options.merge h)

  end

end

# Category: User Input
#
class ShortcutTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: User Input
#
class VolumeButtonTrigger < Trigger

  def initialize(h={})

    options = {
      dont_change_volume: true,
      monitor_option: 1,
      not_configured: false,
      option: 0
    }

    super(options.merge h)

  end

end

# Category: User Input
#
class MediaButtonPressedTrigger < Trigger

  def initialize(h={})

    options = {
      option: 'Single Press',
      cancel_press: false
    }

    super(options.merge h)

  end

end

# Category: User Input
#
class SwipeTrigger < Trigger

  def initialize(h={})

    options = {
      swipe_start_area: 0,
      swipe_motion: 0,
      cleared: true
    }

    super(options.merge h)

  end

end


class Action < MacroObject

  def initialize(h={})    
    super(h)
  end
  
  def invoke(s='')    
    "%s/%s: %s" % [@group, @type, s]
  end  

end


class LocationAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'location'
  end
  
end

# Category: Location
#
class ShareLocationAction < LocationAction

  def initialize(h={})
    
    super()

    options = {
      email: '',
      variable: {:m_stringValue=>"", :m_name=>"", 
                 :m_decimalValue=>0.0, :isLocal=>true, :m_booleanValue=>false, 
                 :excludeFromLog=>false, :m_intValue=>0, :m_type=>2},
      sim_id: 0,
      output_channel: 5,
      old_variable_format: true
    }

    super(options.merge h)

  end

end


class ApplicationAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'application'
  end
  
end

# Category: Applications
#
class LaunchActivityAction < ApplicationAction

  def initialize(h={})

    options = {
      application_name: 'Chrome',
      package_to_launch: 'com.android.chrome',
      exclude_from_recents: false,
      start_new: false
    }

    super(options.merge h)

  end

end

# Category: Applications
#
class KillBackgroundAppAction < ApplicationAction

  def initialize(h={})

    options = {
      application_name_list: [""],
      package_name_list: [""]
    }

    super(options.merge h)

  end

end

# Category: Applications
#
class OpenWebPageAction < ApplicationAction

  def initialize(h={})

    options = {
      variable_to_save_response: {:m_stringValue=>"", :m_name=>"", :m_decimalValue=>0.0, :isLocal=>true, :m_booleanValue=>false, :excludeFromLog=>false, :m_intValue=>0, :m_type=>2},
      url_to_open: '',
      http_get: true,
      disable_url_encode: false,
      block_next_action: false
    }

    super(options.merge h)

  end

end


class CameraAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'camera'
  end
  
end

# Category: Camera/Photo
#
class UploadPhotoAction < CameraAction

  def initialize(h={})

    options = {
      option: 'Via Intent',
      use_smtp_email: false
    }

    super(options.merge h)

  end

end

# Category: Camera/Photo
#
class TakePictureAction < CameraAction

  def initialize(h={})

    options = {
      new_path: '/storage/sdcard1/DCIM/Camera',
      path: '/storage/sdcard1/DCIM/Camera',
      show_icon: true,
      use_front_camera: true,
      flash_option: 0
    }

    super(options.merge h)

  end

end


class ConnectivityAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'connectivity'
  end
  
end

# Category: Connectivity
#
class SetWifiAction < ConnectivityAction

  def initialize(h={})

    options = {
      ssid: '[Select Wifi]',
      network_id: 0,
      state: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class SetBluetoothAction < ConnectivityAction

  def initialize(h={})

    options = {
      device_name: '',
      state: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class SetBluetoothAction < ConnectivityAction

  def initialize(h={})

    options = {
      device_name: '',
      state: 1
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class SendIntentAction < ConnectivityAction

  def initialize(h={})

    options = {
      action: '',
      class_name: '',
      data: '',
      extra1_name: '',
      extra1_value: '',
      extra2_name: '',
      extra2_value: '',
      extra3_name: '',
      extra3_value: '',
      extra4_name: '',
      extra4_value: '',
      package_name: '',
      target: 'Activity'
    }

    super(options.merge h)

  end

end


class DateTimeAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'datetime'
  end
  
end

# Category: Date/Time
#
class SetAlarmClockAction < DateTimeAction

  def initialize(h={})

    options = {
      days_of_week: [false, false, false, false, false, false, false],
      label: 'wakeup mum',
      delay_in_minutes: 1,
      hour: 8,
      delay_in_hours: 0,
      minute: 15,
      one_off: true,
      option: 0,
      relative: true,
      day_option: 0
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class StopWatchAction < DateTimeAction

  def initialize(h={})

    options = {
      stopwatch_name: 'timer1',
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class SayTimeAction < DateTimeAction

  def initialize(h={})

    options = {
      :'12_hour' => true
    }

    super(options.merge h)

  end

end


class DeviceAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'device'
  end
  
end

# Category: Device Actions
#
class AndroidShortcutsAction < DeviceAction

  def initialize(h={})

    options = {
      option: 1
    }

    super(options.merge h)

  end

end

# Category: Device Actions
#
class ClipboardAction < DeviceAction

  def initialize(h={})

    options = {
      clipboard_text: ''
    }

    super(options.merge h)

  end

end

# Category: Device Actions
#
class PressBackAction < DeviceAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Actions
#
class SpeakTextAction < DeviceAction

  def initialize(h={})

    options = {
      text_to_say: '',
      queue: false,
      read_numbers_individually: false,
      specify_audio_stream: false,
      speed: 0.99,
      pitch: 0.99,
      wait_to_finish: false,
      audio_stream: 0
    }

    super(options.merge h)

  end

end

# Category: Device Actions
#
class UIInteractionAction < DeviceAction

  def initialize(h={})

    options = {
      ui_interaction_configuration: {:type=>"Copy"},
      action: 2
    }

    super(options.merge h)

  end

end

# Category: Device Actions
#
class VoiceSearchAction < DeviceAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end


class DeviceSettingsAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'devicesettings'
  end
  
end

# Category: Device Settings
#
class ExpandCollapseStatusBarAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class LaunchHomeScreenAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class CameraFlashLightAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      launch_foreground: false,
      state: 0
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class VibrateAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      vibrate_pattern: 1
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class SetAutoRotateAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      state: 0
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class DayDreamAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class SetKeyboardAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class SetKeyguardAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      keyguard_on: true
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class CarModeAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class ChangeKeyboardAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      keyboard_id: 'com.android.inputmethod.latin/.LatinIME',
      keyboard_name: 'Android Keyboard (AOSP)'
    }

    super(options.merge h)

  end

end

# Category: Device Settings
#
class SetWallpaperAction < DeviceSettingsAction

  def initialize(h={})

    options = {
      image_name: '6051449505275476553',
      s_screen_options: ["Home Screen", "Lock Screen", "Home + Lock Screen"],
      s_options: ["Image", "Live Wallpaper (Preview Screen)"],
      wallpaper_uri_string: 'content://media/external/images/media/928',
      screen_option: 0,
      option: 0
    }

    super(options.merge h)

  end

end

class FileAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'file'
  end
  
end

# Category: Files
#
class OpenFileAction < FileAction

  def initialize(h={})

    options = {
      app_name: '',
      class_name: '',
      package_name: '',
      file_path: ''
    }

    super(options.merge h)

  end

end


class LocationAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'location'
  end
  
end

# Category: Location
#
class ForceLocationUpdateAction < LocationAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Location
#
class ShareLocationAction < LocationAction

  def initialize(h={})

    options = {
      email: '',
      variable: {:m_stringValue=>"", :m_name=>"", :m_decimalValue=>0.0, :isLocal=>true, :m_booleanValue=>false, :excludeFromLog=>false, :m_intValue=>0, :m_type=>2},
      sim_id: 0,
      output_channel: 5,
      old_variable_format: true
    }

    super(options.merge h)

  end

end

# Category: Location
#
class SetLocationUpdateRateAction < LocationAction

  def initialize(h={})

    options = {
      update_rate: 0,
      update_rate_seconds: 600
    }

    super(options.merge h)

  end

end

class LoggingAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'logging'
  end
  
end

# Category: Logging
#
class AddCalendarEntryAction < LoggingAction

  def initialize(h={})

    options = {
      title: '',
      duration_value: '0',
      calendar_id: '3',
      detail: '',
      availability: 0,
      fixed_days: 16,
      fixed_hour: 0,
      fixed_minute: 0,
      fixed_months: 8,
      fixed_time: true,
      relative_days: 0,
      relative_hours: 0,
      relative_minutes: 0,
      all_day_event: true
    }

    super(options.merge h)

  end

end

# Category: Logging
#
class LogAction < LoggingAction

  def initialize(h={})

    options = {
      log_text: '',
      log_date_and_time: true
    }

    super(options.merge h)

  end

end

# Category: Logging
#
class ClearLogAction < LoggingAction

  def initialize(h={})

    options = {
      user_log: true
    }

    super(options.merge h)

  end

end

class MediaAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'media'
  end
  
end

# Category: Media
#
class RecordMicrophoneAction < MediaAction

  def initialize(h={})

    options = {
      path: '/storage/emulated/0/MacroDroid/Recordings',
      record_time_string: 'Cancel Recording',
      recording_format: 0,
      seconds_to_record_for: -2
    }

    super(options.merge h)

  end

end

# Category: Media
#
class PlaySoundAction < MediaAction

  def initialize(h={})

    options = {
      selected_index: 0,
      file_path: ''
    }

    super(options.merge h)

  end

end


class MessagingAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'messaging'
  end
  
end

# Category: Messaging
#
class SendEmailAction < MessagingAction

  def initialize(h={})

    options = {
      subject: '',
      body: '',
      email_address: '',
      from_email_address: '',
      attach_user_log: false,
      attach_log: false,
      send_option: 0
    }

    super(options.merge h)

  end

end

# Category: Messaging
#
class SendSMSAction < MessagingAction

  def initialize(h={})

    options = {
      number: '',
      contact: {:m_id=>"Hardwired_Number", :m_lookupKey=>"Hardwired_Number", :m_name=>"[Select Number]"},
      message_content: '',
      add_to_message_log: false,
      pre_populate: false,
      sim_id: 0
    }

    super(options.merge h)

  end

end

# Category: Messaging
#
class UDPCommandAction < MessagingAction

  def initialize(h={})

    options = {
      destination: '',
      message: '',
      port: 1024
    }

    super(options.merge h)

  end

end


class NotificationsAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'notifications'
  end
  
end

# Category: Notifications
#
class ClearNotificationsAction < NotificationsAction

  def initialize(h={})

    options = {
      package_name_list: [],
      match_text: '',
      application_name_list: [],
      clear_persistent: false,
      excludes: false,
      match_option: 0,
      age_in_seconds: 0,
      option: 0,
      enable_regex: false
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class MessageDialogAction < NotificationsAction

  def initialize(h={})

    options = {
      secondary_class_type: 'MessageDialogAction',
      ringtone_name: 'Default',
      notification_text: '',
      notification_subject: '',
      macro_guid_to_run: -0,
      notification_channel_type: 0,
      image_resource_id: 0,
      overwrite_existing: false,
      priority: 0,
      ringtone_index: 0,
      icon_bg_color: -1762269,
      run_macro_when_pressed: false
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class AllowLEDNotificationLightAction < NotificationsAction

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class SetNotificationSoundAction < NotificationsAction

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/27'
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class SetNotificationSoundAction < NotificationsAction

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/51'
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class SetNotificationSoundAction < NotificationsAction

  def initialize(h={})

    options = {
      ringtone_name: 'None'
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class NotificationAction < NotificationsAction

  def initialize(h={})

    options = {
      ringtone_name: 'Default',
      notification_text: '',
      notification_subject: '',
      macro_guid_to_run: 0,
      notification_channel_type: 0,
      image_resource_id: 0,
      overwrite_existing: false,
      priority: 0,
      ringtone_index: 0,
      icon_bg_color: -1762269,
      run_macro_when_pressed: false
    }

    super(options.merge h)

  end

end

# Category: Notifications
#
class ToastAction < NotificationsAction

  def initialize(h={})

    if h[:msg] then
      h[:message_text] = h[:msg]
      h.delete :msg
    end
    
    options = {
      message_text: '',
      image_resource_name: 'launcher_no_border',
      image_package_name: 'com.arlosoft.macrodroid',
      image_name: 'launcher_no_border',
      duration: 0,
      display_icon: true,
      background_color: -12434878,
      position: 0
    }

    super(options.merge h)

  end
  
  def invoke()
    super(@h[:message_text])
  end

end


class PhoneAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'phone'
  end
  
end

# Category: Phone
#
class AnswerCallAction < PhoneAction

  def initialize(h={})

    options = {
      selected_index: 0
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class ClearCallLogAction < PhoneAction

  def initialize(h={})

    options = {
      non_contact: false,
      specific_contact: false,
      type: 0
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class OpenCallLogAction < PhoneAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class RejectCallAction < PhoneAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class MakeCallAction < PhoneAction

  def initialize(h={})

    options = {
      contact: {:m_id=>"Hardwired_Number", :m_lookupKey=>"Hardwired_Number", :m_name=>"[Select Number]"},
      number: ''
    }

    super(options.merge h)

  end

end


# Category: Phone
#
class SetRingtoneAction < PhoneAction

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/174'
    }

    super(options.merge h)

  end

end

class ScreenAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'screen'
  end
  
end

# Category: Screen
#
class SetBrightnessAction < ScreenAction

  def initialize(h={})

    options = {
      brightness_percent: 81,
      force_pie_mode: false,
      brightness: 0
    }

    super(options.merge h)

  end

end

# Category: Screen
#
class ForceScreenRotationAction < ScreenAction

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Screen
#
class ScreenOnAction < ScreenAction

  def initialize(h={})

    options = {
      pie_lock_screen: false,
      screen_off: true,
      screen_off_no_lock: false,
      screen_on_alternative: false
    }

    super(options.merge h)

  end

end

# Category: Screen
#
class DimScreenAction < ScreenAction

  def initialize(h={})

    options = {
      percent: 50,
      dim_screen_on: true
    }

    super(options.merge h)

  end

end

# Category: Screen
#
class KeepAwakeAction < ScreenAction

  def initialize(h={})

    options = {
      enabled: true,
      permanent: true,
      screen_option: 0,
      seconds_to_stay_awake_for: 0
    }

    super(options.merge h)

  end

end

# Category: Screen
#
class SetScreenTimeoutAction < ScreenAction

  def initialize(h={})

    options = {
      timeout_delay_string: '1 Minute',
      timeout_delay: 60,
      custom_value_delay: 0
    }

    super(options.merge h)

  end

end


class VolumeAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'volume'
  end
  
end

# Category: Volume
#
class SilentModeVibrateOffAction < VolumeAction

  def initialize(h={})

    options = {
      option: 1
    }

    super(options.merge h)

  end

end

# Category: Volume
#
class SetVibrateAction < VolumeAction

  def initialize(h={})

    options = {
      option: 'Silent (Vibrate On)',
      option_int: -1
    }

    super(options.merge h)

  end

end

# Category: Volume
#
class VolumeIncrementDecrementAction < VolumeAction

  def initialize(h={})

    options = {
      volume_up: true
    }

    super(options.merge h)

  end

end

# Category: Volume
#
class SpeakerPhoneAction < VolumeAction

  def initialize(h={})

    options = {
      secondary_class_type: 'SpeakerPhoneAction',
      state: 0
    }

    super(options.merge h)

  end

end

# Category: Volume
#
class SetVolumeAction < VolumeAction

  def initialize(h={})

    options = {
      variables: [nil, nil, nil, nil, nil, nil, nil],
      stream_index_array: [false, false, false, false, false, false, true],
      stream_volume_array: [0, 0, 0, 0, 0, 0, 66],
      force_vibrate_off: false,
      volume: -1
    }

    super(options.merge h)

  end

end

class Constraint < MacroObject

  def initialize(h={})    
    super(h)
  end

end

class TimeOfDayConstraint < Constraint

  def initialize(h={})

    options = {
      end_hour: 8,
      end_minute: 0,
      start_hour: 22,
      start_minute: 0
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class BatteryLevelConstraint < Constraint

  def initialize(h={})

    options = {
      battery_level: 23,
      equals: false,
      greater_than: false
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class BatterySaverStateConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class BatteryTemperatureConstraint < Constraint

  def initialize(h={})

    options = {
      equals: false,
      greater_than: false,
      temperature: 30
    }

    super(options.merge h)

  end

end

# Category: Battery/Power
#
class ExternalPowerConstraint < Constraint

  def initialize(h={})

    options = {
      external_power: true,
      power_connected_options: [false, true, false]
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class BluetoothConstraint < Constraint

  def initialize(h={})

    options = {
      any_device: false,
      bt_state: 0,
      device_name: 'Any Device'
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class GPSEnabledConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class LocationModeConstraint < Constraint

  def initialize(h={})

    options = {
      options: [false, false, false, true]
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class SignalOnOffConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class WifiConstraint < Constraint

  def initialize(h={})

    options = {
      ssid_list: [],
      wifi_state: 0
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class CellTowerConstraint < Constraint

  def initialize(h={})

    options = {
      cell_group_name: 'test group',
      cell_ids: ["524,14,41070731"],
      in_range: true
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class IsRoamingConstraint < Constraint

  def initialize(h={})

    options = {
      is_roaming: true
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class DataOnOffConstraint < Constraint

  def initialize(h={})

    options = {
      data_on: true
    }

    super(options.merge h)

  end

end

# Category: Connectivity
#
class WifiHotSpotConstraint < Constraint

  def initialize(h={})

    options = {
      check_connections: false,
      comparison_value: 0,
      connected_count: 0,
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class CalendarConstraint < Constraint

  def initialize(h={})

    options = {
      enable_regex: false,
      availability: 0,
      calendar_id: '1',
      calendar_name: 'PC Sync',
      detail_text: '',
      entry_set: true,
      ignore_all_day: false,
      title_text: ''
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class DayOfWeekConstraint < Constraint

  def initialize(h={})

    options = {
      days_of_week: [false, false, true, false, false, false, false]
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class TimeOfDayConstraint < Constraint

  def initialize(h={})

    options = {
      end_hour: 1,
      end_minute: 1,
      start_hour: 21,
      start_minute: 58
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class DayOfMonthConstraint < Constraint

  def initialize(h={})

    options = {
      day_names: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"],
      days_of_month: [false, false, false, false, false, false, false, true, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false]
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class MonthOfYearConstraint < Constraint

  def initialize(h={})

    options = {
      months: [false, false, false, false, false, false, false, true, false, false, false, false]
    }

    super(options.merge h)

  end

end

# Category: Date/Time
#
class SunsetSunriseConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class AirplaneModeConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class AutoRotateConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class DeviceLockedConstraint < Constraint

  def initialize(h={})

    options = {
      locked: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class RoamingOnOffConstraint < Constraint

  def initialize(h={})

    options = {
      roaming_on: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class TimeSinceBootConstraint < Constraint

  def initialize(h={})

    options = {
      less_than: true,
      time_period_seconds: 10921
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class AutoSyncConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: false
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class NFCStateConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class IsRootedConstraint < Constraint

  def initialize(h={})

    options = {
      rooted: true
    }

    super(options.merge h)

  end

end

# Category: Device State
#
class VpnConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: MacroDroid Specific
#
class MacroEnabledConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true,
      macro_ids: [-8016812002629322290],
      macro_names: ["Intruder photo "]
    }

    super(options.merge h)

  end

end

# Category: MacroDroid Specific
#
class ModeConstraint < Constraint

  def initialize(h={})

    options = {
      mode: 'Away',
      mode_selected: true
    }

    super(options.merge h)

  end

end

# Category: MacroDroid Specific
#
class TriggerThatInvokedConstraint < Constraint

  def initialize(h={})

    options = {
      not: false,
      si_guid_that_invoked: -4951291100076165433,
      trigger_name: 'Shake Device'
    }

    super(options.merge h)

  end

end

# Category: MacroDroid Specific
#
class LastRunTimeConstraint < Constraint

  def initialize(h={})

    options = {
      check_this_macro: false,
      invoked: true,
      macro_ids: [-6922688338672048267],
      macro_names: ["Opendoor"],
      time_period_seconds: 7260
    }

    super(options.merge h)

  end

end

# Category: Media
#
class HeadphonesConnectionConstraint < Constraint

  def initialize(h={})

    options = {
      connected: true
    }

    super(options.merge h)

  end

end

# Category: Media
#
class MusicActiveConstraint < Constraint

  def initialize(h={})

    options = {
      music_active: true
    }

    super(options.merge h)

  end

end

# Category: Notification
#
class NotificationPresentConstraint < Constraint

  def initialize(h={})

    options = {
      enable_regex: false,
      application_name_list: ["All applications"],
      exact_match: false,
      excludes: false,
      excludes_apps: -1,
      option: 0,
      package_name_list: ["allApplications"],
      text_content: ''
    }

    super(options.merge h)

  end

end

# Category: Notification
#
class PriorityModeConstraint < Constraint

  def initialize(h={})

    options = {
      in_mode: true,
      selected_index: 0
    }

    super(options.merge h)

  end

end

# Category: Notification
#
class NotificationVolumeConstraint < Constraint

  def initialize(h={})

    options = {
      option: 1
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class InCallConstraint < Constraint

  def initialize(h={})

    options = {
      in_call: true
    }

    super(options.merge h)

  end

end

# Category: Phone
#
class PhoneRingingConstraint < Constraint

  def initialize(h={})

    options = {
      ringing: true
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class BrightnessConstraint < Constraint

  def initialize(h={})

    options = {
      brightness: 35,
      equals: false,
      force_pie_mode: false,
      greater_than: false,
      is_auto_brightness: false
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class VolumeConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class SpeakerPhoneConstraint < Constraint

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class DarkThemeConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class ScreenOnOffConstraint < Constraint

  def initialize(h={})

    options = {
      a: true,
      screen_on: true
    }

    super(options.merge h)

  end

end

# Category: Screen and Speaker
#
class VolumeLevelConstraint < Constraint

  def initialize(h={})

    options = {
      comparison: 0,
      stream_index_array: [false, true, false, false, false, false, false],
      volume: 42
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class FaceUpDownConstraint < Constraint

  def initialize(h={})

    options = {
      option: -1,
      selected_options: [true, false, true, false, false, false]
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class LightLevelConstraint < Constraint

  def initialize(h={})

    options = {
      light_level: -1,
      light_level_float: 5000.0,
      option: 1
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class DeviceOrientationConstraint < Constraint

  def initialize(h={})

    options = {
      portrait: true
    }

    super(options.merge h)

  end

end

# Category: Sensors
#
class ProximitySensorConstraint < Constraint

  def initialize(h={})

    options = {
      near: true
    }

    super(options.merge h)

  end

end
