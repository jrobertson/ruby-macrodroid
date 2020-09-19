# file: ruby-macrodroid/constraints.rb

# This file contains the following classes:
#
#  
#  ## Constraint classes
#  
#  Constraint TimeOfDayConstraint BatteryLevelConstraint
#  BatterySaverStateConstraint BatteryTemperatureConstraint
#  ExternalPowerConstraint BluetoothConstraint GPSEnabledConstraint
#  LocationModeConstraint SignalOnOffConstraint WifiConstraint
#  CellTowerConstraint IsRoamingConstraint DataOnOffConstraint
#  WifiHotSpotConstraint CalendarConstraint DayOfWeekConstraint
#  TimeOfDayConstraint DayOfMonthConstraint MonthOfYearConstraint
#  SunsetSunriseConstraint AirplaneModeConstraint AutoRotateConstraint
#  DeviceLockedConstraint RoamingOnOffConstraint TimeSinceBootConstraint
#  AutoSyncConstraint NFCStateConstraint IsRootedConstraint VpnConstraint
#  MacroEnabledConstraint ModeConstraint TriggerThatInvokedConstraint
#  LastRunTimeConstraint HeadphonesConnectionConstraint MusicActiveConstraint
#  NotificationPresentConstraint PriorityModeConstraint
#  NotificationVolumeConstraint InCallConstraint PhoneRingingConstraint
#  BrightnessConstraint VolumeConstraint SpeakerPhoneConstraint
#  DarkThemeConstraint ScreenOnOffConstraint VolumeLevelConstraint
#  FaceUpDownConstraint LightLevelConstraint DeviceOrientationConstraint
#  ProximitySensorConstraint
#

class Constraint < MacroObject

  def initialize(h={})    
    super(h)
  end
  
  def match?(detail={}, model=nil)

    detail.select {|k,v| @h.include? k }.all? {|key,value| @h[key] == value}

  end  
  
  #def to_s()
  #  ''
  #end
  
  protected
  
  def toggle_match?(key, val)
    
    if @h[key] == true and val == key.to_s then
      true
    elsif @h[key] == false and val != key.to_s 
      true
    else
      false
    end
    
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
  
  def to_s(colour: false)
    
    operator = if @h[:greater_than] then
      '>'
    elsif @h[:equals]
      '='
    else
      '<'
    end
    
    level = @h[:battery_level]
    
    "Battery %s %s%%" % [operator, level]
  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'BatterySaverStateConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'BatteryTemperatureConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    connection = @h[:external_power] ? 'Connected' : 'Disconnected'
    'Power ' + connection
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
  
  def to_s(colour: false)
    device = @h[:device_name] #== 'Any Device' ? 'Any' : @h[:device_name]
    "Device Connected\n  %s" % device
  end
  
  def to_summary(colour: false)
    device = @h[:device_name] #== 'Any Device' ? 'Any' : @h[:device_name]
    "Device Connected (%s)" % device
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

  def to_s(colour: false)
    'GPSEnabledConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'LocationModeConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SignalOnOffConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    
    state = ['Enabled','Disabled','Connected', 'Not Connected'][@h[:wifi_state]]
    @s =  'Wifi ' + state + ': '
    
    if @h[:ssid_list].length > 1 then
      @s += "[%s]" % @h[:ssid_list].join(', ')
    elsif @h[:ssid_list].length > 0
      @s += @h[:ssid_list].first
    end
      
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CellTowerConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'IsRoamingConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'DataOnOffConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'WifiHotSpotConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CalendarConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'DayOfWeekConstraint ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Date/Time
#
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
  
  def to_s(colour: false)
    a = @h[:start_hour], @h[:start_minute], @h[:end_hour], @h[:start_minute]
    'Time of Day ' + "%02d:%02d - %02d:%02d" % a    
  end
  
  alias to_summary to_s
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

  def to_s(colour: false)
    'DayOfMonthConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'MonthOfYearConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SunsetSunriseConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def match?(detail={}, model=nil)
    
    puts 'inside airplaneModeConstraint#match?' if $debug
    
    if detail.has_key? :enabled then
      
      puts 'detail has the key' if $debug
      super(detail)
      
    elsif model
      
      if $debug then
        puts 'checking the model'
        switch = model.connectivity.airplane_mode.switch
        puts 'switch: ' + switch.inspect
      end
      
      toggle_match?(:enabled, switch)
      
    end
    
  end
  
  def to_pc()
    status = @h[:enabled] ? 'enabled?' : 'disabled?'
    'airplane_mode.' + status
  end
  
  def to_s(colour: false)
    
    status = @h[:enabled] ? 'Enabled' : 'Disabled'
    'Airplane Mode ' + status
    
  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'AutoRotateConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Device ' + (@h[:locked] ? 'Locked' : 'Unlocked')
  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'RoamingOnOffConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'TimeSinceBootConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'AutoSyncConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'NFCStateConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'IsRootedConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'VpnConstraint ' + @h.inspect
  end

  alias to_summary to_s
end


# Category: MacroDroid Specific
#
class MacroDroidVariableConstraint < Constraint

  def initialize(h={})

    options = {
      
      :enable_regex=>false, 
      :boolean_value=>false, 
      :double_value=>0.0, 
      :int_compare_variable=>false, 
      :int_greater_than=>false, 
      :int_less_than=>false, 
      :int_not_equal=>false, 
      :int_value=>1, 
      :string_comparison_type=>0,
      :string_equal=>true, 
      :variable=>{
                  :exclude_from_log=>false, 
                  :is_local=>true, 
                  :boolean_value=>false, 
                  :decimal_value=>0.0, 
                  :int_value=>2, 
                  :name=>"torch", 
                  :string_value=>"", 
                  :type=>1
                 }      

    }

    super(options.merge h)

  end

  def to_s(colour: false)
    
      a = [:int_greater_than, :int_less_than, :int_not_equal, 
                :string_equal].zip(['>','<','!=', '='])
      operator = a.find {|label,_| @h[label]}.last
    
    @s = "%s %s %s" % [@h[:variable][:name], operator, @h[:int_value]]
    super()
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'MacroEnabledConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ModeConstraint ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: MacroDroid Specific
#
class TriggerThatInvokedConstraint < Constraint
  using ColouredText
  
  def initialize(h={})

    puts ('h: ' + h.inspect).green
    @trigger = h[:macro].triggers.find {|x| x.siguid == h[:si_guid_that_invoked] }
    
    options = {
      not: false,
      si_guid_that_invoked: -4951291100076165433,
      trigger_name: 'Shake Device'
    }

    #super(options.merge filter(options,h))
    super(options.merge h)

  end
  
  def to_s(colour: false)
    'Trigger Fired: ' + @trigger.to_s(colour: colour)
  end
  
  def to_summary(colour: false)
    #puts '@trigger' + @trigger.inspect
    if @trigger then
      'Trigger Fired: ' + @trigger.to_summary(colour: colour)
    else
      'Trigger Fired: Trigger not found; guid: ' + @h[:si_guid_that_invoked].inspect
    end
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

  def to_s(colour: false)
    
    macro = if @h[:check_this_macro] then
      '[This Macro]'
    end
    
    invoked = @h[:invoked] ? ' Invoked' : 'Not Invoked'
    
    duration = Subunit.seconds(@h[:time_period_seconds]).strfunit("%x")
    "Macro(s) %s\n  %s: %s for %s" % [invoked, macro, invoked, duration]
    
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    connection = @h[:connected] ? 'Connected' : 'Disconnected'
    'Headphones ' + connection
  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'MusicActiveConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'NotificationPresentConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'PriorityModeConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'NotificationVolumeConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'InCallConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    @s = @h[:ringing] ? 'Phone Ringing' : 'Not Ringing'
    super(colour: colour)
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

  def to_s(colour: false)
    'BrightnessConstraint ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Screen and Speaker
#
class VolumeConstraint < Constraint

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge filter(options, h))

  end
  
  def to_s(colour: false)
    a = ['Volume On', 'Vibrate Only' 'Silent', 'Vibrate or Silent']
    
    "Ringer Volume\n  " + a[@h[:option]]
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

  def to_s(colour: false)
    'SpeakerPhoneConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'DarkThemeConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Screen ' + (@h[:screen_on] ? 'On' : 'Off')
  end
  
  alias to_summary to_s

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

  def to_s(colour: false)
    'VolumeLevelConstraint ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'FaceUpDownConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    
    operator = @h[:light_level] == -1 ? 'Less than' : 'Greater than'    
    condition = operator + ' ' + @h[:light_level_float].to_s + 'lx'
    'Light Sensor ' + condition
    
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

  def to_s(colour: false)
    'DeviceOrientationConstraint ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Proximity Sensor: ' + (@h[:near] ? 'Near' : 'Far')
  end

end
