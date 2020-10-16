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
  using ColouredText
  using Params
  include ObjectX
  
  attr_reader :constraints  

  def initialize(h={}) 
    
    macro = h[:macro]
    h.delete :macro
    super(h)

    @constraints = @h[:constraint_list].map do |constraint|
      object(constraint.to_snake_case.merge(macro: macro))
    end
    
  end
  
  def invoke(h={})    
    "%s/%s: %s" % [@group, @type, h.to_json]
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
  
  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
    @s = "Launch Shortcut: " + @h[:app_name] + "\n" + @h[:name]
    super()
  end
  
  alias to_summary to_s

end

class OpenWebPageActionError < Exception
end

# Category: Applications
#


class OpenWebPageAction < ApplicationAction
  using ColouredText

  def initialize(obj={}, macro=nil)

    $debug = true    
    puts ('obj: ' + obj.inspect).debug if $debug
    
    h = if obj.is_a? Hash then
    
      obj.merge({macro: macro})
      
    elsif obj.is_a? Array
      
      puts ('obj: ' + obj.inspect).debug if $debug
      e, macro = obj
      
      a = e.xpath('item/*')

      h2 = if a.any? then
      
        a.map do |node|
          
          if node.name == 'description' and node.text.to_s =~ /: / then
            node.text.to_s.split(/: +/,2).map(&:strip)
          else
            [node.name.to_sym, node.text.to_s.strip]
          end
          
        end.to_h
        
      else
        txt = e.text('item/description')
        {url: (txt || e.text)}
      end      
      
      h2.merge(macro: macro)

    end

    puts ('h:' + h.inspect).debug if $debug
    
    #h[:url_to_open] = h[:url] if h[:url] and h[:url].length > 1

    options = {
      variable_to_save_response: {:string_value=>"", :name=>"coords", 
      decimal_value: 0.0, isLocal: true, m_boolean_value: false, 
      excludeFromLog: false, int_value: 0, type: 2},
      url_to_open: '',
      http_get: true,
      disable_url_encode: false,
      block_next_action: false
    }
    
    return super(options.merge h) if h[:url_to_open]
    
    if h[:macro].remote_url.nil? and (h[:url].nil? or h[:url].empty?) then
      raise OpenWebPageActionError, 'remote_url not found'
    end
    
    url = if h[:url] and h[:url].length > 1 then
    
      h[:url]      

    elsif h2 and h[:macro].remote_url and h[:identifier]
      
      "%s/%s" % [h[:macro].remote_url.sub(/\/$/,''), h[:identifier]]
      
    elsif (h[:identifier].nil? or h[:identifier].empty?)         
      
      h[:url_to_open] = h[:macro].remote_url.sub(/\/$/,'') + '/' + 
          h[:macro].title.downcase.gsub(/ +/,'-')            
      
    end        
    
    if h2 then
      
      h2.delete :identifier
      h2.delete :url
      
      if h2.any? then
        url += '?' + \
            URI.escape(h2.map {|key,value| "%s=%s" % [key, value]}.join('&'))
      end
      
    end
    
    h[:url_to_open] = url    
    super(options.merge h)

  end
  
  def invoke()
    super(url: @h[:url_to_open])
  end
  
  def to_s(colour: false, indent: 0)
    @s = "HTTP GET\nurl: " + @h[:url_to_open]
    super()
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

  def to_s(colour: false, indent: 0)
    'UploadPhotoAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Camera/Photo
#
class TakePictureAction < CameraAction

  def initialize(obj=nil)

    
    h = if obj.is_a? Hash then

      macro = obj[:macro]    
      obj.delete :macro
      obj

      
    elsif obj.is_a? Array
      
      e, macro = obj
      
      puts 'e: ' + e.xml.inspect

      a = e.xpath('item/*')
      
      if a.any? then
        
        h2 = a.map {|node| [node.name.to_sym, node.text.to_s.strip]}.to_h
        
        desc = ''
        
        if h2[:description] then

          desc = h2[:description]
          h2.delete :description
          puts 'desc: ' + desc.inspect
          
          if desc.length > 1 then
            
            flash = case desc
            when /Flash On/i
              1
            when /Flash Auto/i
              2
            else
              0
            end
            

          end          
          
        end
        
        {
          use_front_camera: (desc =~ /Front Facing/ ? true : false),
          flash_option: flash
        }.merge(h2)          
        
      
      end
    end
    
    options = {
      new_path: macro.picture_path,
      path: macro.picture_path,
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

  def to_s(colour: false, indent: 0)
    
    flash = case @h[:flash_option]
    when 0
      ''
    when 1
      'Flash On'
    when 2
      'Flash Auto'
    end
    
    @s = 'Take Picture'# + @h.inspect
    a = [@h[:use_front_camera] ? 'Front Facing' : 'Rear Facing']
    a << flash if flash.length > 0
    @s += "\n" + a.join(', ')
    super()
    
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

  def to_s(colour: false, indent: 0)
    
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
    
    @label = 'DO / WHILE '

  end

  def to_s(colour: false, indent: 0)
    
    h = @h.clone    
    h.delete :macro
    @s = 'DO / WHILE '
    operator = @h[:is_or_condition] ? 'OR' : 'AND'
    constraints = @constraints.map \
        {|x| '  ' * indent + x.to_summary(colour: colour)}.join(" %s " % operator)    
    
    out = []
    out << "; %s" % @h[:comment] if @h[:comment]
    s = @s.lines.map {|x| ('  ' * indent) + x}.join
    out << s + constraints
    out.join("\n")
    
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

  def to_s(colour: false, indent: 0)
    
    'End Loop '
    
  end
end

# Conditions/Loops
#
class IfConditionAction < Action

  def initialize(obj=nil)

    options = {
      a: true,
      constraint_list: []
    }  
    puts 'obj: ' + obj.inspect if $debug
    
    if obj.is_a? Hash then
      
      h = obj
      macro = h[:macro]
      h2 = options.merge(filter(options,h).merge(macro: macro))
      super(h2)      
      
    elsif obj.is_a? Array
      
      e, macro = obj
      super()
      puts 'e.xml: ' + e.xml if $debug
      puts 'e.text: ' + e.text.to_s.strip if $debug
      raw_txt = e.text.to_s.strip[/^if [^$]+/i] || e.text('item/description')
      puts 'raw_txt: ' + raw_txt.inspect if $debug
      
      clause = raw_txt[/^If (.*)/i,1]
      puts 'clause: ' + clause.inspect if $debug
      conditions = clause.split(/\s+\b(?:AND|OR)\b\s+/i)
      puts 'conditions: ' + conditions.inspect if $debug
      
      cp = ConstraintsNlp.new      
      
      @constraints = conditions.map do |c|
        puts 'c: ' + c.inspect  if $debug
        r = cp.find_constraint c
        puts 'found constraint ' + r.inspect if $debug
        
        r[0].new(r[1]) if r
        
      end         
      puts '@constraints: ' + @constraints.inspect if $debug
      
      # find any nested actions
      item = e.element('item')
      
      if item then
        
        ap = ActionsNlp.new
        obj2 = action_to_object(ap, item, item, macro)      
        puts 'obj2: ' + obj2.inspect if $debug
        #macro.add obj2
        
      end
      
      h = {
        constraint_list: @constraints.map(&:to_h)
      }
      super(h)        {}
      
    else
      # get the constraints

    end
    

    

    
    @label = 'If '

  end

  def to_s(colour: false, indent: 0)
    
    h = @h.clone    
    #h.delete :macro
    @s = 'If '
    operator = @h[:is_or_condition] ? 'OR' : 'AND'
    constraints = @constraints.map \
        {|x| '  ' * indent + x.to_summary(colour: colour)}.join(" %s " % operator)    
    
    out = []
    out << "; %s" % @h[:comment] if @h[:comment]
    s = @s.lines.map {|x| ('  ' * indent) + x}.join
    out << s + constraints
    out.join("\n")
    
  end 
  
end

class ElseAction < Action
  
  def initialize(obj=[])

    options = {
      constraint_list: []
    }
    
    if obj.is_a? Hash then
      
      h = obj

      super(options.merge h)      
      
    elsif obj.is_a? Array
      
      e, macro = obj
      
      # find any nested actions
      item = e.element('item')
      
      if item then
        
        ap = ActionsNlp.new
        obj2 = action_to_object(ap, item, item, macro)      
        puts 'obj2: ' + obj2.inspect if $debug
        #macro.add obj2
        
      end
      
      super(options)
    end
    
    


  end    
  
  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
    
    h = @h.clone    
    h.delete :macro
    @s = 'Else If '
    operator = @h[:is_or_condition] ? 'OR' : 'AND'
    constraints = @constraints.map \
        {|x| '  ' * indent + x.to_summary(colour: colour)}.join(" %s " % operator)    
    
    out = []
    out << "; %s" % @h[:comment] if @h[:comment]
    s = @s.lines.map {|x| ('  ' * indent) + x}.join
    out << s + constraints
    out.join("\n")
    
  end    
  
  def to_summary(colour: false)
    'foo'
  end
    

end


class EndIfAction < Action
  
  def initialize(obj={})
    
    h = if obj.is_a? Hash then
      obj
    elsif obj.is_a? Rexle::Element    
      {}
    else
      {}
    end
    
  
    options = {
      constraint_list: []
    }

    super()

  end  
  
  def to_s(colour: false, indent: 0)
    'End If'
  end
  
  alias to_summary to_s
  
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
  
  def to_s(colour: false, indent: 0)
    
    state = ['On', 'Off', 'Toggle'][@h[:state]]
    @s = 'Airplane Mode ' + state
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
  
  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    'SetBluetoothAction ' + @h.inspect
  end

  alias to_summary to_s
end

class SetHotspotAction < ConnectivityAction
  
  def initialize(h={})

    # to-do: check when *disable hotspot*, is the 
    #        *enable wifi* option selected?
    
    options = {
      device_name: "", state: 0, turn_wifi_on: true, use_legacy_mechanism: false, mechanism: 0

    }

    super(options.merge h)

  end
  
  def to_s(colour: false, indent: 0)
    
    @s =  "%s HotSpot" % [@h[:state] == 0 ? 'Enable' : 'Disable']
    
    if @h[:state] == 1 then
      @s += "\n" + (@h[:turn_wifi_on] ? 'Enable WiFi' : 'Don\'t Enable Wifi')
    end
    
    super()
    
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    option = ['Start', 'Pause','Reset','Reset and Restart'][@h[:option]]
    name = @h[:stopwatch_name]
    @s = "StopWatch (%s)" % option + "\n" + name #+ ' ' + @h.inspect
    super()
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
    #time = ($env and $env[:time]) ? $env[:time] : Time.now
    time = Time.now
    tformat = @h['12_hour'] ? "%-I:%M%P" : "%H:%M"
    super(txt: time.strftime(tformat))
  end
  
  def to_pc()
    'say current_time()'
  end
  
  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    'PressBackAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Device Actions
#
class SpeakTextAction < DeviceAction

  def initialize(obj=nil)
    
    h = if obj.is_a? Hash then
      obj
    elsif obj.is_a? Array
      e, macro = obj
      txt = e.text('item/description')
      {text: (txt || e.text)}
    end     
  
    options = {
      text_to_say: h[:text] || '',
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
  
  def invoke()
    super(text: @h[:text_to_say])
  end  
  
  def to_s(colour: false, indent: 0)
    @s = "Speak Text (%s)" % @h[:text_to_say]
    super()
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

  def to_s(colour: false, indent: 0)

    ui = @h[:ui_interaction_configuration]
    
    option = -> do
      detail = case ui[:click_option]
      when 0 # 'Current focus'
        'Current focus'
      when 1 # 'Text content'
        ui[:text_content]
      when 2 # 'X, Y location'
        "%s" % ui[:xy_point].values.join(',')
      when 3 # 'Identify in app'
        "id:%s" % ui[:view_id]
      end      
    end
    
    s = case @h[:action]
    when 0 # 'Click'      
      'Click' + " [%s]" % option.call
    when 1 # 'Long Click'
      'Long Click' + " [%s]" % option.call
    when 2 # 'Copy'
      'Copy'
    when 3 # 'Cut'
      'Cut'
    when 4 # 'Paste'
      "Paste [%s]" % (ui[:use_clipboard] ? 'Clipboard text' : ui[:text])
    when 5 # 'Clear selection'
      'Clear selection'
    when 6 # 'Gesture'
      detail = "%d ms: %d,%d -> %d,%d" % [ui[:duration_ms], ui[:start_x], 
          ui[:start_y], ui[:end_x], ui[:end_y]]
      "Gesture [%s]" % detail
    end
    
    'UI Interaction' + "\n  " + s #+ ' ' + @h.inspect
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  def invoke()
    super(state: @h[:state])
  end

  def to_pc()
    ['torch :on', 'torch :off', 'torch :toggle'][@h[:state]]
  end
  
  def to_s(colour: false, indent: 0)
    ['Torch On', 'Torch Off', 'Torch Toggle'][@h[:state]]    
  end  

end

# Category: Device Settings
#
class VibrateAction < DeviceSettingsAction

  def initialize(h={})
    
    pattern = [
      'Blip', 'Short Buzz', 'Long Buzz', 'Rapid', 'Slow', 'Increasing', 
      'Constant', 'Decreasing', 'Final Fantasy', 'Game Over', 'Star Wars',
      'Mini Blip', 'Micro Blip'
    ]    
    
    if h[:pattern] then
      h[:vibrate_pattern] = pattern.map(&:downcase).index h[:pattern]
    end
    
    options = {
      vibrate_pattern: 1
    }

    super(options.merge h)

  end
  
  def to_s(colour: false, indent: 0)
    
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    
    operation = ['Copy', 'Move', 'Delete', 'Create Folder']
    file = ['All Files', 'All Media Files', 'Images', 'Audio', 'Videos', 'Specify File Pattern', 'Folder']
    
    detail = @h[:from_name]
    detail += ' to: ' + @h[:to_name] if @h[:option] == 1
    @s = "%s %s" % [operation[@h[:option]], file[@h[:file_option]]]  \
        + "\n" + detail #+ @h.inspect        
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    'Force Location Update' #+ @h.inspect
  end

  alias to_summary to_s
end

# Category: Location
#
class LocationAction < Action
  
  def initialize(h={})
    super(h)
    @group = 'location'
  end
  
end

# Category: Location
#
class ShareLocationAction < LocationAction

  def initialize(obj=nil)
    
    h = if obj.is_a? Hash then
      obj
    elsif obj.is_a? Array
      e, macro = obj
      {variable: macro.set_var(e.text('item/description').to_s)}

    end      
    
    #super()

    options = {
      email: '',
      variable: {:string_value=>"", :name=>"", 
                 :decimal_value=>0.0, :is_local=>true, :boolean_value=>false, 
                 :exclude_from_log=>false, :int_value=>0, :type=>2},
      sim_id: 0,
      output_channel: 5,
      old_variable_format: true
    }
    #options[:variable].merge! h
    super(options.merge h)

  end

  def to_s(colour: false, indent: 0)
    @s = 'Share Location' + "\n" + @h[:variable][:name] # + @h.inspect
    super()
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    'ClearLogAction ' + @h.inspect
  end

  alias to_summary to_s
end


# MacroDroid Specific
#
class CancelActiveMacroAction < Action
  
  def initialize(h={})
    
    options = {

    }

    super(h)
    
  end  
  
  def to_s(colour: false, indent: 0)
    @s = 'Cancel Macro Actions' + "\n  " + @h[:macro_name] #+ ' ' + @h.inspect
    super()
    
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
  
  def to_s(colour: false, indent: 0)
    
    @s = 'Confirm Next'  + "\n%s: %s" % [@h[:title], @h[:message]]
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
  
  def to_s(colour: false, indent: 0)
    
    'Export macros'
    
  end
  
  alias to_summary to_s
  
end


# MacroDroid Specific
#
class SetVariableAction < Action
  using ColouredText
  
  def initialize(obj=nil)
    
    h = if obj.is_a? Hash then
      obj
    elsif obj.is_a? Array
      e, macro = obj
      node = e.element('item/*')
      #puts ("node.name: %s node.value: %s" % [node.name, node.value]).debug
      r = macro.set_var node.name, node.value.to_s
      puts ('r: ' + r.inspect).debug if $debug
      r
      if r[:type] == 2 then
        { variable: {name: r[:name], type: r[:type]}, new_string_value: r[:string_value]
          }
      end
    end    
    
    options = {
      :user_prompt=>true, 
      :user_prompt_message=>"Please enter a word to see it reversed", 
      :user_prompt_show_cancel=>true, 
      :user_prompt_stop_after_cancel=>true, 
      :user_prompt_title=>"Word reverse",
      :name => 'word',
      :false_label=>"False", :int_expression=>false, :int_random=>false, 
      :int_random_max=>0, :int_random_min=>0, :int_value_decrement=>false, 
      :int_value_increment=>false, :new_boolean_value=>false, 
      :new_double_value=>0.0, :new_int_value=>0, 
      :new_string_value=>"[battery]", :true_label=>"True", 
      :user_prompt=>false, :user_prompt_show_cancel=>true, 
      :user_prompt_stop_after_cancel=>true, 
      :variable=>{
                  :exclude_from_log=>false, :is_local=>true, 
                  :boolean_value=>false, :decimal_value=>0.0, 
                  :int_value=>0, :name=>"foo", :string_value=>"52", :type=>2
      }
    }
    super(options.merge h)
    
  end  
  
  def to_s(colour: false, indent: 0)
    
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
    
    @s = 'Set Variable' + ("\n%s: " % @h[:variable][:name]) + input #+ @h.inspect
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
  
  def to_s(colour: false, indent: 0)
    
    #tm = @h[:text_manipulation][:type]

    #s = case tm[:type].to_sym
    s = case 3 # @h[:text_manipulation][:option].to_i
    when 0 # :SubstringManipulation
      "Substring(%s, %s)" % [@h[:text], tm[:params].join(', ')]
    when 1 # :ReplaceAllManipulation
      "Replace all(%s, %s, %s)" % [@h[:text], *tm[:params]]      
    when 2 # :ExtractTextManipulation
      "Extract text(%s, %s)" % [@h[:text], tm[:params].join(', ')]      
    when 3 # :UpperCaseManipulation
      "Upper case(%s)" % [@h[:text]]
      #'foo'
    when 4 # :LowerCaseManipulation
      "Lower case(%s)" % [@h[:text]]      
    when 5 # :TrimWhitespaceManipulation
      "Trim whitespace(%s)" % [@h[:text]]      
    end

    'Text Manipulation' + "\n  " + s.inspect #+ ' ' + @h.inspect        
    
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
  
  def to_s(colour: false, indent: 0)
    
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    recipient = @h[:email_address]
    @s = 'Send EmailAction' + "\nTo: " + recipient #+ ' ' + @h.inspect
    super()
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
    @s = "Display Notification\n" + \
        "%s: %s" % [@h[:notification_subject], @h[:notification_text]]
    super()
  end

end

# Category: Notifications
#
class ToastAction < NotificationsAction

  def initialize(obj)
    
    h = if obj.is_a? Hash then
      obj
    elsif obj.is_a? Array
      e, macro = obj
      txt = e.text('item/description')
      {msg: (txt || e.text)}
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
    super(msg: @h[:message_text])
  end
  
  def to_pc()
    "popup_message '%s'" % @h[:message_text]
  end
  
  def to_s(colour: false, indent: 0)
    @s = "Popup Message\n%s" % @h[:message_text]
    super()
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
  
  def to_s(colour: false, indent: 0)
    @s = 'Answer Call'
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
    @s = 'Call Reject'
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    val = @h[:brightness_percent] > 100 ? 'Auto' : @h[:brightness_percent].to_s + '%'
    @s = 'Brightness' + "\n  " + val #@h.inspect
    super()
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

  def to_s(colour: false, indent: 0)
    'ForceScreenRotationAction ' + @h.inspect
  end

  alias to_summary to_s
end

# Category: Screen
#
class ScreenOnAction < ScreenAction
  using ColouredText

  def initialize(obj=nil)
    
    debug = false
    
    h = if obj.is_a? Hash then
    
      obj
      
    elsif obj.is_a? Array
=begin      
      puts 'obj: ' + obj.inspect if debug
      e, macro = obj
      puts ('e: ' + e.xml.inspect).debug if debug
      a = e.xpath('item/*')

      txt = e.text.to_s
      puts ('txt: ' + txt.inspect).debug if debug
      state = txt[/Screen (On|Off)/i,1]
      
      {screen_off: state.downcase == 'off'}
=end      
      {}
    end    

    options = {
      pie_lock_screen: false,
      screen_off: true,
      screen_off_no_lock: false,
      screen_on_alternative: false
    }

    super(options.merge h)

  end

  def to_s(colour: false, indent: 0)
    
    state = @h[:screen_off] ? 'Off' : 'On'
    state += ' ' + 'No Lock (root only)' if @h[:screen_off_no_lock]
    #state += ' ' + '(Alternative)' if @h[:screen_on_alternative]
    
    @s = 'Screen ' + state
    super()
    
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

  def to_s(colour: false, indent: 0)
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
  using ColouredText

  def initialize(obj=nil)
    
    
    h = if obj.is_a? Hash then
    
      obj
      
    elsif obj.is_a? Array
      
      puts 'obj: ' + obj.inspect if $debug
      e, macro = obj
      
      a = e.xpath('item/*')

      txt = e.text('item/description')      
      
      h2 = if txt then
      
        raw_duration = (txt || e.text).to_s
        puts 'raw_duration: ' + raw_duration.inspect  if $debug
        duration = raw_duration[/Screen On - ([^$]+)/i]
        {duration: duration}
        
      elsif a.any? then
        a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
      end      
      
      h2.merge(macro: macro)

    end
    
    puts ('h: ' + h.inspect).debug if $debug
    
    if h[:duration] then
            
      h[:seconds_to_stay_awake_for] =  Subunit.hms_to_seconds(h[:duration])
      
    end

    options = {
      enabled: true,
      permanent: true,
      screen_option: 0,
      seconds_to_stay_awake_for: 0
    }

    super(options.merge h)

  end
  
  def to_s(colour: false, indent: 0)
    
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
    
    a = [
      'Silent (Vibrate On)',
      'Normal (Vibrate Off)',
      'Vibrate when ringing On',
      'Vibrate when ringing Off',
      'Vibrate when ringing Toggle'
    ]
    
    status = a[@h[:option_int]]
    @s = 'Vibrate Enable/Disable ' + "\n" + status
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

  def to_s(colour: false, indent: 0)
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

  def to_s(colour: false, indent: 0)
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
  
  def to_s(colour: false, indent: 0)
    volume = @h[:stream_index_array].zip(@h[:stream_volume_array]).to_h[true]
    'Volume Change ' + "Notification = %s%%" % volume    
  end
end
