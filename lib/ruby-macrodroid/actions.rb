# file: ruby-macrodroid/actions.rb

# This file contains the following classes:
#
#  
#  ## Action classes
#  
#  Action LocationAction ShareLocationAction ApplicationAction
#  LaunchActivityAction KillBackgroundAppAction OpenWebPageAction CameraAction
#  UploadPhotoAction TakePictureAction ConnectivityAction SetWifiAction
#  SetBluetoothAction SetBluetoothAction SendIntentAction DateTimeAction
#  SetAlarmClockAction StopWatchAction SayTimeAction DeviceAction
#  AndroidShortcutsAction ClipboardAction PressBackAction SpeakTextAction
#  UIInteractionAction VoiceSearchAction DeviceSettingsAction
#  ExpandCollapseStatusBarAction LaunchHomeScreenAction CameraFlashLightAction
#  VibrateAction SetAutoRotateAction DayDreamAction SetKeyboardAction
#  SetKeyguardAction CarModeAction ChangeKeyboardAction SetWallpaperAction
#  FileAction OpenFileAction LocationAction ForceLocationUpdateAction
#  ShareLocationAction SetLocationUpdateRateAction LoggingAction
#  AddCalendarEntryAction LogAction ClearLogAction MediaAction
#  RecordMicrophoneAction PlaySoundAction MessagingAction SendEmailAction
#  SendSMSAction UDPCommandAction NotificationsAction ClearNotificationsAction
#  MessageDialogAction AllowLEDNotificationLightAction
#  SetNotificationSoundAction SetNotificationSoundAction
#  SetNotificationSoundAction NotificationAction ToastAction PhoneAction
#  AnswerCallAction ClearCallLogAction OpenCallLogAction RejectCallAction
#  MakeCallAction SetRingtoneAction ScreenAction SetBrightnessAction
#  ForceScreenRotationAction ScreenOnAction DimScreenAction KeepAwakeAction
#  SetScreenTimeoutAction VolumeAction SilentModeVibrateOffAction
#  SetVibrateAction VolumeIncrementDecrementAction SpeakerPhoneAction
#  SetVolumeAction
#  


class Action < MacroObject
  using Params
  
  attr_reader :constraints  

  def initialize(h={}) 
    
    macro = h[:macro]
    h.delete :macro
    super(h)
    
    # fetch the constraints                               
    @constraints = @h[:constraint_list].map do |constraint|
      object(constraint.to_snake_case.merge(macro: macro))
    end       
  end
  
  def invoke(s='')    
    "%s/%s: %s" % [@group, @type, s]
  end  
  
  def to_s(colour: false)

    h = @h.clone    
    h.delete :macro
    @s ||= "#<%s %s>" % [self.class, h.inspect]
    operator = @h[:is_or_condition] ? 'OR' : 'AND'
    constraints = @constraints.map \
        {|x| x.to_summary(colour: colour)}.join(" %s " % operator)
    
    @s + constraints
    
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

  def to_s(colour: false)
    'ShareLocationAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Launch ' + @h[:application_name]
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

  def to_s(colour: false)
    'KillBackgroundAppAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Applications
#
class LaunchShortcutAction < ApplicationAction

  def initialize(h={})
    
    options = {
      :app_name=>"Amazon Alexa", :intent_encoded=>"", :name=>"Ask Alexa"
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    @s = "Launch Shortcut: " + @h[:app_name] + "\n  " + @h[:name]
    super()
  end
  
  alias to_summary to_s

end

# Category: Applications
#
class OpenWebPageAction < ApplicationAction

  def initialize(h={})
    
    h[:url_to_open] = h[:url] if h[:url]

    options = {
      variable_to_save_response: {:m_stringValue=>"", :m_name=>"", :m_decimalValue=>0.0, :isLocal=>true, :m_booleanValue=>false, :excludeFromLog=>false, :m_intValue=>0, :m_type=>2},
      url_to_open: '',
      http_get: true,
      disable_url_encode: false,
      block_next_action: false
    }

    super(options.merge filter(options,h))

  end
  
  def to_s(colour: false)
    "HTTP GET\n  url: " + @h[:url_to_open]
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

  def to_s(colour: false)
    'UploadPhotoAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_pc()
    camera = @h[:use_front_camera] ? :front : :back
    'take_photo :' + camera.to_s
  end

  def to_s(colour: false)
    'Take Picture'
  end  

end


# Conditions/Loops
#
class IfConfirmedThenAction < Action
  
  def initialize(h={})
    
    options = {
      a: true,
      constraint_list: ''
    }
    
    macro = h[:macro]
    h2 = options.merge(filter(options,h).merge(macro: macro))

    super(h2)
    
    @label = 'If Confirmed Then '

  end

  def to_s(colour: false)
    
    @s = "If Confirmed Then " #+ @constraints.map(&:to_s).join(" %s " % operator)
    super(colour: colour)
    
  end
end

# Conditions/Loops
#
class LoopAction < Action
  
  def initialize(h={})
    
    options = {

    }
    
    h2 = options.merge(h)

    super(h2)
    
    @label = 'WHILE / DO '

  end

  def to_s(colour: false)
    
    @s = 'WHILE / DO '
    super()
    
  end
end

# Conditions/Loops
#
class EndLoopAction < Action
  
  def initialize(h={})
    
    options = {

    }
    
    h2 = options.merge(h)

    super(h2)
    
    @label = 'End Loop '

  end

  def to_s(colour: false)
    
    'End Loop '
    
  end
end

# Conditions/Loops
#
class IfConditionAction < Action
  
  def initialize(obj=nil)
    
    h = if obj.is_a? Hash then
      obj
    else
      # get the constraints

    end
    
    options = {
      a: true,
      constraint_list: ''
    }
    
    macro = h[:macro]
    h2 = options.merge(filter(options,h).merge(macro: macro))

    super(h2)
    
    @label = 'If '

  end

  def to_s(colour: false)
    
    @s = "If " #+ @constraints.map(&:to_s).join(" %s " % operator)
    super(colour: colour)
    
  end
end

class ElseAction < Action
  
  def initialize(h={})

    options = {
      constraint_list: ''
    }

    super(options.merge h)
    

  end  
  
  def to_s(colour: false)
    'Else'
  end
  
end

class ElseIfConditionAction < Action
  
  def initialize(h={})

    options = {
      constraint_list: ''
    }

    super(options.merge h)
    @label = 'Else If '

  end  
  
  def to_s(colour: false)
    @s = 'Else If '
    super()
  end
    

end


class EndIfAction < Action
  
  def initialize(h={})

    options = {
      constraint_list: ''
    }

    super(options.merge h)

  end  
  
  def to_s(colour: false)
    'End If'
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
class SetAirplaneModeAction < ConnectivityAction

  def initialize(h={})

    options = {
      device_name: '',
      state: 1
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    
    state = ['On', 'Off', 'Toggle'][@h[:state]]
    @s = 'Airplane Mode ' + state + "\n"
    super(colour: colour)
    
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
  
  def to_s(colour: false)
    action = @h[:state] == 0 ? 'Enable' : 'Disable'
    action + ' Wifi'
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

  def to_s(colour: false)
    'SetBluetoothAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetBluetoothAction ' + @h.inspect
  end

  alias to_summary to_s
end

class SetHotspotAction < ConnectivityAction
  
  def initialize(h={})

    options = {
      device_name: "", state: 0, turn_wifi_on: true, use_legacy_mechanism: false, mechanism: 0

    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    action = @h[:turn_wifi_on] ? 'Enable' : 'Disable'
    action + ' HotSpot'
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

  def to_s(colour: false)
    'Send Intent ' + "\n  " + @h[:action]
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetAlarmClockAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'StopWatchAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def invoke()
    time = ($env and $env[:time]) ? $env[:time] : Time.now
    tformat = @h['12_hour'] ? "%-I:%M%P" : "%H:%M"
    super(time.strftime(tformat))
  end
  
  def to_pc()
    'say current_time()'
  end
  
  def to_s(colour: false)
    'Say Current Time'
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

  def to_s(colour: false)
    'AndroidShortcutsAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'Fill Clipboard' + "\n  " + @h[:clipboard_text] #+ @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Actions
#
class PressBackAction < DeviceAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'PressBackAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    "Speak Text (%s)" % @h[:text_to_say]
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

  def to_s(colour: false)
    'UIInteractionAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Actions
#
class VoiceSearchAction < DeviceAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'VoiceSearchAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ExpandCollapseStatusBarAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Settings
#
class LaunchHomeScreenAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'LaunchHomeScreenAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Settings
#
class CameraFlashLightAction < DeviceSettingsAction

  # options
  #  0  Toch On
  #  1  Torch Off
  #  2  Torch Toggle
  #
  def initialize(h={})

    options = {
      launch_foreground: false,
      state: 0
    }

    super(options.merge h)

  end

  def to_pc()
    ['torch :on', 'torch :off', 'torch :toggle'][@h[:state]]
  end
  
  def to_s(colour: false)
    ['Torch On', 'Torch Off', 'Torch Toggle'][@h[:state]]    
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
  
  def to_s(colour: false)
    
    pattern = [
      'Blip', 'Short Buzz', 'Long Buzz', 'Rapid', 'Slow', 'Increasing', 
      'Constant', 'Decreasing', 'Final Fantasy', 'Game Over', 'Star Wars',
      'Mini Blip', 'Micro Blip'
    ]
    
    'Vibrate ' + "(%s)" % pattern[@h[:vibrate_pattern].to_i]
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

  def to_s(colour: false)
    'SetAutoRotateAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Settings
#
class DayDreamAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'DayDreamAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Settings
#
class SetKeyboardAction < DeviceSettingsAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'SetKeyboardAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetKeyguardAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'CarModeAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ChangeKeyboardAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetWallpaperAction ' + @h.inspect
  end

  alias to_summary to_s
end

class FileAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'file'
  end
  
end



# Category: Files
#
class FileOperationV21Action < FileAction

  def initialize(h={})

    options = {
      :app_name=>"", :class_name=>"", :package_name=>"", :file_path=>"", 
      :file_extensions=>["jpg", "jpeg", "png", "raw", "bmp", "tif", "tiff", 
                         "gif"], :file_option=>2, :from_name=>"Sent", 
      :from_uri_string=>"", :option=>2
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    
    operation = ['Copy', 'Move', 'Delete', 'Create Folder']
    file = ['All Files', 'All Media Files', 'Images', 'Audio', 'Videos', 'Specify File Pattern', 'Folder']
    
    detail = @h[:from_name]
    detail += ' to: ' + @h[:to_name] if @h[:option] == 1
    @s = "%s %s" % [operation[@h[:option]], file[@h[:file_option]]]  \
        + "\n  " + detail #+ @h.inspect        
    super()
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'OpenFileAction ' + @h.inspect
  end

  alias to_summary to_s
end


# Category: Files
#
class WriteToFileAction < FileAction

  def initialize(h={})

    options = {
      app_name: '',
      class_name: '',
      package_name: '',
      file_path: ''
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'Write To File' + "\n  " + @h[:filename] #+ @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ForceLocationUpdateAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ShareLocationAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetLocationUpdateRateAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'AddCalendarEntryAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'LogAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ClearLogAction ' + @h.inspect
  end

  alias to_summary to_s
end

# MacroDroid Specific
#
class ConfirmNextAction < Action
  
  def initialize(h={})
    
    options = {
      :message=>"Do you want to fill the clipboard? ", :title=>"Fill clipboard? ", :negative_text=>"NO", :positive_text=>"YES", :class_type=>"ConfirmNextAction"

    }

    super(h)
    
  end  
  
  def to_s(colour: false)
    
    @s = 'Confirm Next'  + "\n  %s: %s" % [@h[:title], @h[:message]]
    super()
    
  end
  
  alias to_summary to_s
  
end

# MacroDroid Specific
#
class ExportMacrosAction < Action
  
  def initialize(h={})
    
    options = {
      file_path: "", path_uri: ""
    }
    super(h)
    
  end  
  
  def to_s(colour: false)
    
    'Export macros'
    
  end
  
  alias to_summary to_s
  
end


# MacroDroid Specific
#
class SetVariableAction < Action
  
  def initialize(h={})
    
    options = {
      :user_prompt=>true, 
      :user_prompt_message=>"Please enter a word to see it reversed", 
      :user_prompt_show_cancel=>true, 
      :user_prompt_stop_after_cancel=>true, 
      :user_prompt_title=>"Word reverse",
      :name => 'word'
    }
    super(h)
    
  end  
  
  def to_s(colour: false)
    
    input = if @h[:user_prompt] then
      '[User Prompt]'
    elsif @h[:expression]
      @h[:expression]
    elsif @h[:int_value_increment]
      '(+1)'      
    elsif @h[:int_value_decrement]
      '(-1)'
    elsif @h[:int_random]
      "Random %d -> %d" % [@h[:int_random_min], @h[:int_random_max]]
    else

=begin      
        sym = case @h[:variable][:type]
        when 0 # boolean
          :new_boolean_value
        when 1 # integer
          :new_int_value
        when 2 # string
          :new_string_value
        when 3 # decimal
          :new_double_value
        end
        
        @h[sym].to_s
=end        
        a = %i(new_boolean_value new_int_value new_string_value new_double_value)
        @h[a[@h[:variable][:type]]].to_s

    end
    
    @s = 'Set Variable' + ("\n  %s: " % @h[:variable][:name]) + input #+ @h.inspect
    super()
    
  end
  
  alias to_summary to_s
  
end



# MacroDroid Specific
#
class TextManipulationAction < Action
  
  def initialize(h={})
    
    options = {

    }
    super(h)
    
  end  
  
  def to_s(colour: false)
    
    tm = @h[:text_manipulation]
    
    s = case tm[:type].to_sym
    when :SubstringManipulation
      "Substring(%s, %s)" % [@h[:text], tm[:params].join(', ')]
    end

    
    'Text Manipulation' + "\n  " + s #+ ' ' + @h.inspect
    
    
  end
  
  alias to_summary to_s
  
end

class PauseAction < Action
  
  def initialize(h={})
    
    options = {
      delay_in_milli_seconds: 0, delay_in_seconds: 1, use_alarm: false
    }
    super(h)
    
  end  
  
  def to_s(colour: false)
    
    su = Subunit.new(units={minutes:60, hours:60}, 
                     seconds: @h[:delay_in_seconds])

    ms = @h[:delay_in_milli_seconds]
    
    duration = if su.to_h.has_key?(:minutes) or (ms < 1) then
      su.strfunit("%X")
    else
      "%s %s ms" % [su.strfunit("%X"), ms]
    end
    
    "Wait " + duration
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

  def to_s(colour: false)
    'RecordMicrophoneAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Play: ' + @h[:file_path]
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

  def to_s(colour: false)
    'SendEmailAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SendSMSAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'UDPCommandAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ClearNotificationsAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    'Display Dialog' + "\n  Battery at: [battery]"
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

  def to_s(colour: false)
    'AllowLEDNotificationLightAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetNotificationSoundAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetNotificationSoundAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetNotificationSoundAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Notifications
#
class NotificationAction < NotificationsAction

  def initialize(h={})
    
    h[:notification_subject] = h[:subject] if h[:subject] 
    h[:notification_text] = h[:text] if h[:text]

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

    super(options.merge filter(options, h))

  end
  
  def to_s(colour: false)
    "Display Notification\n  " + \
        "%s: %s" % [@h[:notification_subject], @h[:notification_text]]
  end

end

# Category: Notifications
#
class ToastAction < NotificationsAction

  def initialize(obj)
    
    h = if obj.is_a? Hash then
      obj
    else
      {msg: obj}
    end

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
  
  def to_pc()
    "popup_message '%s'" % @h[:message_text]
  end
  
  def to_s(colour: false)
    @s = "Popup Message\n  %s" % @h[:message_text]
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
  
  def to_s(colour: false)
    @s = 'Answer Call' + "\n  "
    super()
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

  def to_s(colour: false)
    'ClearCallLogAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Phone
#
class OpenCallLogAction < PhoneAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'OpenCallLogAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Phone
#
class RejectCallAction < PhoneAction

  def initialize(h={})

    options = {
    }

    super(options.merge h)

  end
  
  def to_s(colour: false)
    @s = 'Call Reject' + "\n  "
    super()
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

  def to_s(colour: false)
    'MakeCallAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetRingtoneAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SetBrightnessAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'ForceScreenRotationAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    
    state = @h[:screen_off] ? 'Off' : 'On'
    state += ' ' + 'No Lock (root only)' if @h[:screen_off_no_lock]
    #state += ' ' + '(Alternative)' if @h[:screen_on_alternative]
    
    'Screen ' + state
    
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'DimScreenAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Screen
#
# options:
#   keep awake, screen on => enabled: true
#   disable keep awake    => enabled: false
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
  
  def to_s(colour: false)
    
    screen = @h[:screen_option] == 0 ? 'Screen On' : 'Screen Off'
    
    if @h[:enabled] then
    
      whenx = if @h[:seconds_to_stay_awake_for] == 0 then
    
      'Until Disabled'
      
      else
        scnds = @h[:seconds_to_stay_awake_for]
        Subunit.new(units={minutes:60, hours:60}, seconds: scnds).strfunit("%x")
      end
      
      "Keep Device Awake\n  " + screen + ' - ' + whenx
      
    else
      'Disable Keep Awake'
    end
    
    
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

  def to_s(colour: false)
    'SetScreenTimeoutAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SilentModeVibrateOffAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    
    a = [
      'Silent (Vibrate On)',
      'Normal (Vibrate Off)',
      'Vibrate when ringing On',
      'Vibrate when ringing Off',
      'Vibrate when ringing Toggle'
    ]
    
    status = a[@h[:option_int]]
    @s = 'Vibrate Enable/Disable ' + "\n    " + status + "\n  "
    super()
    
  end

  def to_summary(colour: false)
    
    @s = 'Vibrate Enable/Disable'
    
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

  def to_s(colour: false)
    'VolumeIncrementDecrementAction ' + @h.inspect
  end

  alias to_summary to_s
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

  def to_s(colour: false)
    'SpeakerPhoneAction ' + @h.inspect
  end

  alias to_summary to_s
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
  
  def to_s(colour: false)
    volume = @h[:stream_index_array].zip(@h[:stream_volume_array]).to_h[true]
    'Volume Change ' + "Notification = %s%%" % volume    
  end
end
