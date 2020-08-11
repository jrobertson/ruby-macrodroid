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



class WifiConnectionTrigger < Trigger

  def initialize(h={})    
    super({}.merge(h))
  end

end

class WebHookTrigger < Trigger

  def initialize(h={})    
    super({identifier: ''}.merge(h))
    @list << 'identifier'
  end

  def identifier()
    @h[:identifier]
  end

  def identifier=(val)
    @h[:identifier] = val
  end

end

class WifiConnectionTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ApplicationInstalledRemovedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ApplicationLaunchedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class BatteryLevelTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class BatteryTemperatureTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class PowerButtonToggleTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ExternalPowerTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class CallActiveTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class IncomingCallTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class OutgoingCallTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class CallEndedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class CallMissedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class IncomingSMSTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class BluetoothTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class HeadphonesTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class SignalOnOffTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class UsbDeviceConnectionTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class WifiSSIDTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class CalendarTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end
  
  

  
class TimerTrigger < Trigger

  def initialize(h={})    
    
    options = {
      alarm_id: uuid(),
      days_of_week: [false, true, false, false, false, false, false], 
      hour: 0,  
      minute: 0,
      use_alarm: false
    }
      
    super(options.merge h)
    
    
  end

end

class StopwatchTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class DayTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class RegularIntervalTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class AirplaneModeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class AutoSyncChangeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class DayDreamTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class DockTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class GPSEnabledTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class MusicPlayingTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class DeviceUnlockedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class AutoRotateChangeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ClipboardChangeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class BootTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class IntentReceivedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class NotificationTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ScreenOnOffTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class SilentModeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class WeatherTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class GeofenceTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class SunriseSunsetTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ActivityRecognitionTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ProximityTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ShakeDeviceTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class FlipDeviceTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class OrientationTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class FloatingButtonTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class ShortcutTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class VolumeButtonTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class MediaButtonPressedTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end

class SwipeTrigger < Trigger

  def initialize(h={})    
    super({}.merge h)
  end

end


class Action < MacroObject

  def initialize(h={})    
    super(h)
  end

end



class ShareLocationAction < Action

  def initialize(h={})    
    super({sim_id: 0, output_channel: 5, old_variable_format: true}.merge(h))
  end

end

class UDPCommandAction < Action

  def initialize(h={})    
    super({destination: '', message: '', port: 0}.merge h)
  end

end

class LaunchActivityAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class KillBackgroundAppAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class OpenWebPageAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class UploadPhotoAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class TakePictureAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetWifiAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetBluetoothAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SendIntentAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetAlarmClockAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class StopWatchAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SayTimeAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class AndroidShortcutsAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ClipboardAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class PressBackAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SpeakTextAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class UIInteractionAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class VoiceSearchAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ExpandCollapseStatusBarAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class LaunchHomeScreenAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class CameraFlashLightAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class VibrateAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetAutoRotateAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class DayDreamAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetKeyboardAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetKeyguardAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class CarModeAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ChangeKeyboardAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetWallpaperAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class OpenFileAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ForceLocationUpdateAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetLocationUpdateRateAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class AddCalendarEntryAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class LogAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ClearLogAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class RecordMicrophoneAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class PlaySoundAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SendEmailAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SendSMSAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ClearNotificationsAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class MessageDialogAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class AllowLEDNotificationLightAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetNotificationSoundAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class NotificationAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ToastAction < Action

  def initialize(h={})    
    
    options = {
      message_text: 'Popup message for you!',
      image_resource_name: 'launcher_no_border',
      image_package_name: 'com.arlosoft.macrodroid',
      image_name: 'launcher_no_border',
      duration: 0,
      display_icon: true,
      background_color: -12434878,
      position: 0,
    }
    
    super(options.merge h)
  end

end

class AnswerCallAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ClearCallLogAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class OpenCallLogAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class RejectCallAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class MakeCallAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetRingtoneAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetBrightnessAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ForceScreenRotationAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class ScreenOnAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class DimScreenAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class KeepAwakeAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetScreenTimeoutAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SilentModeVibrateOffAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetVibrateAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class VolumeIncrementDecrementAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SpeakerPhoneAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class SetVolumeAction < Action

  def initialize(h={})    
    super({}.merge h)
  end

end

class Constraint < MacroObject

  def initialize(h={})    
    super(h)
  end

end
