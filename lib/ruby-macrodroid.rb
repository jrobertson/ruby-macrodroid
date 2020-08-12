#!/usr/bin/env ruby

# file: ruby-macrodroid.rb

require 'pp'
require 'json'
require 'uuid'
require 'rxfhelper'


module Params

  refine Hash do

    # turns keys from camelCase into snake_case

    def to_snake_case(h=self)

      h.inject({}) do |r, x|

        key, value = x
        puts 'value: ' + value.inspect
        
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

  attr_reader :local_variables, :triggers, :actions, :guid

  def initialize(debug: false)

    @debug = debug
    lv=[], triggers=[], actions=[]
    @local_variables, @triggers, @actions = lv, triggers, actions
          
    @triggers, @actions = [], []
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
      m_constraint_list: []
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

    # fetch the constraints (not yet implemented)
    
    @h = h

    %i(local_variables m_trigger_list m_action_list).each do |x|
      @h[x] = []
    end

    @h

  end

  private

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
      import_json(s) if s[0] == '{'
      
    else
      
      @h = {
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
      
      @macros = []
      
    end
  end
  
  def add(macro)
    @macros << macro
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

  def to_h()

    @h.merge(macro_list:  @macros.map(&:to_h)).to_camel_case

  end



end

class MacroObject

  def initialize(h={})
    
    @h = {constraint_list: [], is_or_condition: false, 
          is_disabled: false}.merge(h)
    @list = []
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
  
  def uuid()
    UUID.new.generate
  end
  
end

class Trigger < MacroObject

  def initialize(h={})    
    super({fakeIcon: 0}.merge(h))
    @list << 'fakeIcon'
  end

end



class WebHookTrigger < Trigger

  def initialize(h={})

    options = {
      identifier: ''
    }

    super(options.merge h)

  end

end

class WifiConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      ssid_list: [""],
      wifi_state: 2
    }

    super(options.merge h)

  end

end

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

class PowerButtonToggleTrigger < Trigger

  def initialize(h={})

    options = {
      num_toggles: 3
    }

    super(options.merge h)

  end

end

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

class CallMissedTrigger < Trigger

  def initialize(h={})

    options = {
      contact_list: [{:m_id=>"-2", :m_lookupKey=>"-2", :m_name=>"[Any Number]"}]
    }

    super(options.merge h)

  end

end

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

class WebHookTrigger < Trigger

  def initialize(h={})

    options = {
      identifier: ''
    }

    super(options.merge h)

  end

end

class WifiConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      ssid_list: [],
      wifi_state: 0
    }

    super(options.merge h)

  end

end

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

class HeadphonesTrigger < Trigger

  def initialize(h={})

    options = {
      headphones_connected: true,
      mic_option: 0
    }

    super(options.merge h)

  end

end

class SignalOnOffTrigger < Trigger

  def initialize(h={})

    options = {
      signal_on: true
    }

    super(options.merge h)

  end

end

class UsbDeviceConnectionTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class WifiSSIDTrigger < Trigger

  def initialize(h={})

    options = {
      wifi_cell_info_list: [{:displayName=>"", :ssid=>""}],
      ssid_list: [],
      _in_range: true
    }

    super(options.merge h)

  end

end

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

class TimerTrigger < Trigger

  def initialize(h={})

    options = {
      alarm_id: uuid(),
      days_of_week: [false, true, false, false, false, false, false],
      minute: 10,
      hour: 7,
      use_alarm: false
    }

    super(options.merge h)

  end

end

class StopwatchTrigger < Trigger

  def initialize(h={})

    options = {
      stopwatch_name: 'timer1',
      seconds: 240
    }

    super(options.merge h)

  end

end

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

class AirplaneModeTrigger < Trigger

  def initialize(h={})

    options = {
      airplane_mode_enabled: true
    }

    super(options.merge h)

  end

end

class AutoSyncChangeTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class DayDreamTrigger < Trigger

  def initialize(h={})

    options = {
      day_dream_enabled: true
    }

    super(options.merge h)

  end

end

class DockTrigger < Trigger

  def initialize(h={})

    options = {
      dock_type: 0
    }

    super(options.merge h)

  end

end

class GPSEnabledTrigger < Trigger

  def initialize(h={})

    options = {
      gps_mode_enabled: true
    }

    super(options.merge h)

  end

end

class MusicPlayingTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class DeviceUnlockedTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class DeviceUnlockedTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class AutoRotateChangeTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class ClipboardChangeTrigger < Trigger

  def initialize(h={})

    options = {
      text: '',
      enable_regex: false
    }

    super(options.merge h)

  end

end

class BootTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class BootTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

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

class ScreenOnOffTrigger < Trigger

  def initialize(h={})

    options = {
      screen_on: true
    }

    super(options.merge h)

  end

end

class SilentModeTrigger < Trigger

  def initialize(h={})

    options = {
      silent_enabled: true
    }

    super(options.merge h)

  end

end

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

class SunriseSunsetTrigger < Trigger

  def initialize(h={})

    options = {
      option: 0,
      time_adjust_seconds: 0
    }

    super(options.merge h)

  end

end


class ActivityRecognitionTrigger < Trigger

  def initialize(h={})

    options = {
      confidence_level: 50,
      selected_index: 1
    }

    super(options.merge h)

  end

end


class ProximityTrigger < Trigger

  def initialize(h={})

    options = {
      near: true,
      selected_option: 0
    }

    super(options.merge h)

  end

end

class ShakeDeviceTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

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

class OrientationTrigger < Trigger

  def initialize(h={})

    options = {
      check_orientation_alive: true,
      option: 0
    }

    super(options.merge h)

  end

end

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

class ShortcutTrigger < Trigger

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

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

class MediaButtonPressedTrigger < Trigger

  def initialize(h={})

    options = {
      option: 'Single Press',
      cancel_press: false
    }

    super(options.merge h)

  end

end

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

end



class ShareLocationAction < Action

  def initialize(h={})

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

class UDPCommandAction < Action

  def initialize(h={})

    options = {
      destination: '',
      message: '',
      port: 1024
    }

    super(options.merge h)

  end

end

class UDPCommandAction < Action

  def initialize(h={})

    options = {
      destination: '',
      message: '',
      port: 1024
    }

    super(options.merge h)

  end

end

class LaunchActivityAction < Action

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

class KillBackgroundAppAction < Action

  def initialize(h={})

    options = {
      application_name_list: [""],
      package_name_list: [""]
    }

    super(options.merge h)

  end

end

class OpenWebPageAction < Action

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

class UploadPhotoAction < Action

  def initialize(h={})

    options = {
      option: 'Via Intent',
      use_smtp_email: false
    }

    super(options.merge h)

  end

end

class TakePictureAction < Action

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

class SetWifiAction < Action

  def initialize(h={})

    options = {
      ssid: '[Select Wifi]',
      network_id: 0,
      state: 0
    }

    super(options.merge h)

  end

end

class SetBluetoothAction < Action

  def initialize(h={})

    options = {
      device_name: '',
      state: 0
    }

    super(options.merge h)

  end

end

class SetBluetoothAction < Action

  def initialize(h={})

    options = {
      device_name: '',
      state: 1
    }

    super(options.merge h)

  end

end

class SendIntentAction < Action

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

class SetAlarmClockAction < Action

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

class StopWatchAction < Action

  def initialize(h={})

    options = {
      stopwatch_name: 'timer1',
      option: 0
    }

    super(options.merge h)

  end

end

class SayTimeAction < Action

  def initialize(h={})

    options = {
      :'12_hour' => true
    }

    super(options.merge h)

  end

end

class AndroidShortcutsAction < Action

  def initialize(h={})

    options = {
      option: 1
    }

    super(options.merge h)

  end

end

class ClipboardAction < Action

  def initialize(h={})

    options = {
      clipboard_text: ''
    }

    super(options.merge h)

  end

end

class PressBackAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class SpeakTextAction < Action

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

class UIInteractionAction < Action

  def initialize(h={})

    options = {
      ui_interaction_configuration: {:type=>"Copy"},
      action: 2
    }

    super(options.merge h)

  end

end

class VoiceSearchAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class ExpandCollapseStatusBarAction < Action

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class LaunchHomeScreenAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class CameraFlashLightAction < Action

  def initialize(h={})

    options = {
      launch_foreground: false,
      state: 0
    }

    super(options.merge h)

  end

end

class VibrateAction < Action

  def initialize(h={})

    options = {
      vibrate_pattern: 1
    }

    super(options.merge h)

  end

end

class SetAutoRotateAction < Action

  def initialize(h={})

    options = {
      state: 0
    }

    super(options.merge h)

  end

end

class DayDreamAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class SetKeyboardAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class SetKeyguardAction < Action

  def initialize(h={})

    options = {
      keyguard_on: true
    }

    super(options.merge h)

  end

end

class CarModeAction < Action

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class ChangeKeyboardAction < Action

  def initialize(h={})

    options = {
      keyboard_id: 'com.android.inputmethod.latin/.LatinIME',
      keyboard_name: 'Android Keyboard (AOSP)'
    }

    super(options.merge h)

  end

end

class SetWallpaperAction < Action

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

class OpenFileAction < Action

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

class ForceLocationUpdateAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class ShareLocationAction < Action

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

class SetLocationUpdateRateAction < Action

  def initialize(h={})

    options = {
      update_rate: 0,
      update_rate_seconds: 600
    }

    super(options.merge h)

  end

end

class AddCalendarEntryAction < Action

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

class LogAction < Action

  def initialize(h={})

    options = {
      log_text: '',
      log_date_and_time: true
    }

    super(options.merge h)

  end

end

class ClearLogAction < Action

  def initialize(h={})

    options = {
      user_log: true
    }

    super(options.merge h)

  end

end

class RecordMicrophoneAction < Action

  def initialize(h={})

    options = {
      path: '',
      record_time_string: 'Until Cancelled',
      recording_format: 0,
      seconds_to_record_for: -1
    }

    super(options.merge h)

  end

end

class RecordMicrophoneAction < Action

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

class PlaySoundAction < Action

  def initialize(h={})

    options = {
      selected_index: 0,
      file_path: ''
    }

    super(options.merge h)

  end

end


class SendEmailAction < Action

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

class SendSMSAction < Action

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

class UDPCommandAction < Action

  def initialize(h={})

    options = {
      destination: '',
      message: '',
      port: 1024
    }

    super(options.merge h)

  end

end

class ClearNotificationsAction < Action

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

class MessageDialogAction < Action

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

class AllowLEDNotificationLightAction < Action

  def initialize(h={})

    options = {
      enabled: true
    }

    super(options.merge h)

  end

end

class SetNotificationSoundAction < Action

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/27'
    }

    super(options.merge h)

  end

end

class SetNotificationSoundAction < Action

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/51'
    }

    super(options.merge h)

  end

end

class SetNotificationSoundAction < Action

  def initialize(h={})

    options = {
      ringtone_name: 'None'
    }

    super(options.merge h)

  end

end

class NotificationAction < Action

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

class ToastAction < Action

  def initialize(h={})

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

end

class AnswerCallAction < Action

  def initialize(h={})

    options = {
      selected_index: 0
    }

    super(options.merge h)

  end

end

class ClearCallLogAction < Action

  def initialize(h={})

    options = {
      non_contact: false,
      specific_contact: false,
      type: 0
    }

    super(options.merge h)

  end

end

class OpenCallLogAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class RejectCallAction < Action

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

end

class MakeCallAction < Action

  def initialize(h={})

    options = {
      contact: {:m_id=>"Hardwired_Number", :m_lookupKey=>"Hardwired_Number", :m_name=>"[Select Number]"},
      number: ''
    }

    super(options.merge h)

  end

end

class SetRingtoneAction < Action

  def initialize(h={})

    options = {
      ringtone_uri: 'content://media/internal/audio/media/174'
    }

    super(options.merge h)

  end

end

class SetBrightnessAction < Action

  def initialize(h={})

    options = {
      brightness_percent: 81,
      force_pie_mode: false,
      brightness: 0
    }

    super(options.merge h)

  end

end

class ForceScreenRotationAction < Action

  def initialize(h={})

    options = {
      option: 0
    }

    super(options.merge h)

  end

end

class ScreenOnAction < Action

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

class DimScreenAction < Action

  def initialize(h={})

    options = {
      percent: 50,
      dim_screen_on: true
    }

    super(options.merge h)

  end

end

class KeepAwakeAction < Action

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

class SetScreenTimeoutAction < Action

  def initialize(h={})

    options = {
      timeout_delay_string: '1 Minute',
      timeout_delay: 60,
      custom_value_delay: 0
    }

    super(options.merge h)

  end

end



class SilentModeVibrateOffAction < Action

  def initialize(h={})

    options = {
      option: 1
    }

    super(options.merge h)

  end

end

class SetVibrateAction < Action

  def initialize(h={})

    options = {
      option: 'Silent (Vibrate On)',
      option_int: -1
    }

    super(options.merge h)

  end

end

class VolumeIncrementDecrementAction < Action

  def initialize(h={})

    options = {
      volume_up: true
    }

    super(options.merge h)

  end

end

class SpeakerPhoneAction < Action

  def initialize(h={})

    options = {
      secondary_class_type: 'SpeakerPhoneAction',
      state: 0
    }

    super(options.merge h)

  end

end



class SetVolumeAction < Action

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
