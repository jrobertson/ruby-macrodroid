# file: ruby-macrodroid/triggers.rb

# This file contains the following classes:
#
#  
#  ## Trigger classes
#  
#  Trigger WebHookTrigger WifiConnectionTrigger
#  ApplicationInstalledRemovedTrigger ApplicationLaunchedTrigger
#  BatteryLevelTrigger BatteryTemperatureTrigger PowerButtonToggleTrigger
#  ExternalPowerTrigger CallActiveTrigger IncomingCallTrigger
#  OutgoingCallTrigger CallEndedTrigger CallMissedTrigger IncomingSMSTrigger
#  WebHookTrigger WifiConnectionTrigger BluetoothTrigger HeadphonesTrigger
#  SignalOnOffTrigger UsbDeviceConnectionTrigger WifiSSIDTrigger
#  CalendarTrigger TimerTrigger StopwatchTrigger DayTrigger
#  RegularIntervalTrigger DeviceEventsTrigger AirplaneModeTrigger
#  AutoSyncChangeTrigger DayDreamTrigger DockTrigger FailedLoginTrigger
#  GPSEnabledTrigger MusicPlayingTrigger DeviceUnlockedTrigger
#  AutoRotateChangeTrigger ClipboardChangeTrigger BootTrigger
#  IntentReceivedTrigger NotificationTrigger ScreenOnOffTrigger
#  SilentModeTrigger WeatherTrigger GeofenceTrigger SunriseSunsetTrigger
#  SensorsTrigger ActivityRecognitionTrigger ProximityTrigger
#  ShakeDeviceTrigger FlipDeviceTrigger OrientationTrigger
#  FloatingButtonTrigger ShortcutTrigger VolumeButtonTrigger
#  MediaButtonPressedTrigger SwipeTrigger
#  




class Trigger < MacroObject
  using Params
  
  attr_reader :constraints
  
  def initialize(h={})    
    super({fakeIcon: 0}.merge(h))
    @list << 'fakeIcon'
        
    # fetch the constraints                               
    @constraints = @h[:constraint_list].map do |constraint|
      object(constraint.to_snake_case)
    end       
    
  end
  
  def match?(detail={}, model=nil)

    # only match where the key exists in the trigger object
    detail.select {|k,v| @h.include? k }.all? {|key,value| @h[key] == value}

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

  def to_s(colour: false)
    'WifiConnectionTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ApplicationInstalledRemovedTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ApplicationLaunchedTrigger ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    operator = @h[:decreases_to] ? '<=' : '>='    
    "Battery %s %s%%" % [operator, @h[:battery_level]]
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

  def to_s(colour: false)
    'BatteryTemperatureTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'PowerButtonToggleTrigger ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    
    return 'Power Disconnected' unless @h[:power_connected]
    
    status = 'Power Connectd'
    options = if @h[:power_connected_options].all? then
      'Any'
    else
      
      a = ['Wired (Fast Charge)', 'Wireless', 'Wired (Slow Charge)']
      @h[:power_connected_options].map.with_index {|x,i| x ? i : nil}\
          .compact.map {|i| a[i] }.join(' + ')
      
    end
    
    "%s: %s" % [status, options]

  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'CallActiveTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    caller = @h[:incoming_call_from_list].map {|x| "%s" % x[:name]}.join(', ')
    "Call Incoming [%s]" % caller
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'OutgoingCallTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CallEndedTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CallMissedTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'IncomingSMSTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    
    url = "https://trigger.macrodroid.com/%s/%s" % \
        [@h[:macro].deviceid, @h[:identifier]]
    @s = 'WebHook (Url)' + "\n  " + url
    super()

  end

  alias to_summary to_s
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

  def to_s(colour: false)
    access_point = @h[:ssid_list].first
    'Connected to network ' + access_point
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'BluetoothTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'HeadphonesTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SignalOnOffTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'UsbDeviceConnectionTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'WifiSSIDTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CalendarTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

    @options = {
      alarm_id: uuid(),
      days_of_week: [false, false, false, false, false, false, false],
      minute: 10,
      hour: 7,
      use_alarm: false
    }
            
    #super(options.merge filter(options, h))
    super(@options.merge h)

  end
  
  def match?(detail={time: $env[:time]}, model=nil)
    
   time() == detail[:time]

  end
  
  # sets the environmental conditions for this trigger to fire
  #
  def set_env()
    $env[:time] = time()
  end
  
  def to_pc()    
    "time.is? '%s'" % self.to_s.gsub(',', ' or')
  end
  
  def to_s(colour: false)
    
    dow = @h[:days_of_week]        

    wd = Date::ABBR_DAYNAMES    
    a = (wd[1..-1] << wd.first)
    
    a2 = dow.map.with_index.to_a
    start = a2.find {|x,i| x}.last
    r = a2[start..-1].take_while {|x,i| x == true}
    r2 = a2[start..-1].select {|x,i| x}
    
    days = if r == r2 then
    
      x1, x2 = a2[start].last, a2[r.length-1].last
      
      if (x2 - x1) >= 2 then
        "%s-%s" % [a[x1],a[x2]]
      else
        a.zip(dow).select {|_,b| b}.map(&:first).join(', ')
      end
    else  
      a.zip(dow).select {|_,b| b}.map(&:first).join(', ')
    end
    
    time = Time.parse("%s:%s" % [@h[:hour], @h[:minute]]).strftime("%H:%M")    
    
    "%s %s" % [time, days]
  end
  
  alias to_summary to_s
  
  private
  
  def time()
    
    a = @h[:days_of_week].clone
    a.unshift a.pop

    dow = a.map.with_index {|x, i| x ? i : nil }.compact.join(',')
    s = "%s %s * * %s" % [@h[:minute], @h[:hour], dow]        
    recent_time = ($env && $env[:time]) ? $env[:time] : Time.now
    ChronicCron.new(s, recent_time).to_time
    
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

  def to_s(colour: false)
    'StopwatchTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'DayTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    
    interval = Subunit.new(units={minutes:60, hours:60}, \
                           seconds: @h[:seconds]).strfunit("%c")
    'Regular Interval ' + "\n  Interval: " + interval
    
  end

  alias to_summary to_s
end

class DeviceEventsTrigger < Trigger
  
  def initialize(h={})
    super(h)
    @group = 'device_events'
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
class AirplaneModeTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      airplane_mode_enabled: true
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'AirplaneModeTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class AutoSyncChangeTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'AutoSyncChangeTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class DayDreamTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      day_dream_enabled: true
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'DayDreamTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class DockTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      dock_type: 0
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'DockTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class FailedLoginTrigger < DeviceEventsTrigger
  
  def initialize(h={})

    options = {
      num_failures: 1
    }

    super(options.merge h)

  end
  
  def to_pc()
    'failed_login?'
  end

  def to_s(colour: false)
    'Failed Login Attempt'
  end
end

# Category: Device Events
#
class GPSEnabledTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      gps_mode_enabled: true
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'GPSEnabledTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class MusicPlayingTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'MusicPlayingTrigger ' + @h.inspect
  end

  alias to_summary to_s
end


# Category: Device Events
#
class NFCTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    'NFC Tag' + "\n  " + @h[:tag_name]
  end
  
  alias to_summary to_s

end


# Category: Device Events
#
class DeviceUnlockedTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    'Screen Unlocked'
  end
  
  alias to_summary to_s

end

# Category: Device Events
#
class AutoRotateChangeTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'AutoRotateChangeTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class ClipboardChangeTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      text: '',
      enable_regex: false
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'ClipboardChangeTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class BootTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'BootTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class IntentReceivedTrigger < DeviceEventsTrigger

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

  def to_s(colour: false)
    'IntentReceivedTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Events
#
class NotificationTrigger < DeviceEventsTrigger

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

  def to_s(colour: false)
    s = (@h[:package_name_list] + @h[:application_name_list]).uniq.join(', ')
    'Notification Received ' + "\n    Any Content (%s)" % s
  end

  alias to_summary to_s
end

# Category: Device Events
#
class ScreenOnOffTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      screen_on: true
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    'Screen ' + (@h[:screen_on] ? 'On' : 'Off')
  end
  
  alias to_summary to_s

end

# Category: Device Events
#
class SilentModeTrigger < DeviceEventsTrigger

  def initialize(h={})

    options = {
      silent_enabled: true
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'SilentModeTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'WeatherTrigger ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Location
#
class GeofenceTrigger < Trigger

  def initialize( h={}, geofences: {})

    if h[:name] then
      puts ('geofences2: ' + geofences.inspect) if $debug
      found = geofences.find {|x| x.name.downcase == h[:name].downcase}
      h[:geofence_id] = found.id if found
      
    end
    
    options = {
      update_rate_text: '5 Minutes',
      geofence_id: '',
      geofence_update_rate_minutes: 5,
      trigger_from_unknown: false,
      enter_area: true
    }

    super(options.merge filter(options, h))
    @geofences = geofences

  end
  
  def to_s(colour: false)
    
    if $debug then
      puts ' @geofences: ' + @geofences.inspect
      puts '@h: ' + @h.inspect
      puts '@h[:geofence_id]: ' + @h[:geofence_id].inspect
    end
    
    direction = @h[:enter_area] ? 'Entry' : 'Exit'
    
    found = @geofences.find {|x| x.id == @h[:geofence_id]}
    puts 'found: ' + found.inspect    if @debug 
    label = found ? found.name : 'error: name not found'

    "Geofence %s (%s)" % [direction, label]
    
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

  def to_s(colour: false)
    'SunriseSunsetTrigger ' + @h.inspect
  end

  alias to_summary to_s
end


# Category: MacroDroid Specific
#
class EmptyTrigger < Trigger

  def initialize(h={})

    options = {

    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'EmptyTrigger'
  end

  alias to_summary to_s
end


class SensorsTrigger < Trigger
  
  def initialize(h={})
    super(h)
    @group = 'sensors'
  end
  
end

# Category: Sensors
#
class ActivityRecognitionTrigger < SensorsTrigger

  def initialize(h={})

    options = {
      confidence_level: 50,
      selected_index: 1
    }

    super(options.merge h)
    
    @activity = ['In Vehicle', 'On Bicycle', 'Running', 'Walking', 'Still']    

  end
  
  def to_s(colour: false)
    activity = @activity[@h[:selected_index]]
    'Activity - ' + activity
  end
  
  def to_summary(colour: false)
    
    activity = @activity[@h[:selected_index]]
    s = if activity.length > 10 then
      activity[0..7] + '..'
    else
      activity
    end
    
    'Activity - ' + s
    
  end

end

# Category: Sensors
#
class ProximityTrigger < SensorsTrigger

  def initialize(h={})

    if h[:distance] then
      
      case h[:distance].to_sym
      when :near
        options[:near] = true
      end
    end
    
    options = {
      near: true,
      selected_option: 0
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    
    distance = if @h[:near] then
      'Near'
    else
      'Far'
    end
    
    "Proximity Sensor (%s)" % distance
  end
  
  alias to_summary to_s

end

# Category: Sensors
#
class ShakeDeviceTrigger < SensorsTrigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end
  
  def to_pc()
    'shake_device?'
  end
  
  def to_s(colour: false)
    'Shake Device'
  end

end

# Category: Sensors
#
# options:
#   Face Up -> Face Down
#   Face Down -> Face Up
#   Any -> Face Down
#
class FlipDeviceTrigger < SensorsTrigger

  def initialize(h={})

    options = {
      any_start: false,
      face_down: true,
      work_with_screen_off: false
    }

    super(options.merge h)

  end  
  
  def to_pc()
    @h[:face_down] ? 'flip_device_down?' : 'flip_device_up?'
  end
  
  def to_s(colour: false)
    
    action = @h[:face_down] ? 'Face Up -> Face Down' : 'Face Down -> Face Up'
    'Flip Device ' + action
  end  

end

# Category: Sensors
#
class OrientationTrigger < SensorsTrigger

  def initialize(h={})

    options = {
      check_orientation_alive: true,
      option: 0
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'OrientationTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'Floating Button'
  end

  alias to_summary to_s
end

# Category: User Input
#
class ShortcutTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'ShortcutTrigger ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    
    a = [
      'Volume Up', 
      'Volume Down',
      'Volume Up - Long Press', 
      'Volume Down - Long Press'
    ]
    
    lines = [a[@h[:option]]]
    lines << '  ' + (@h[:dont_change_volume] ? 'Retain Previous Volume' : 'Update Volume')
    @s = lines.join("\n")
  end
  
  def to_summary(colour: false)
    a = [
      'Volume Up', 
      'Volume Down',
      'Volume Up - Long Press', 
      'Volume Down - Long Press'
    ]
    
    lines = [a[@h[:option]]]
    lines << (@h[:dont_change_volume] ? 'Retain Previous Volume' : 'Update Volume')
    @s = lines.join(": ")    
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

  def to_s(colour: false)
    'MediaButtonPressedTrigger ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SwipeTrigger ' + @h.inspect
  end

  alias to_summary to_s
end
