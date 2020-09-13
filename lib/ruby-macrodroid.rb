#!/usr/bin/env ruby

# file: ruby-macrodroid.rb

# This file contains the following classes:
#
#  ## Nlp classes
#  
#  TriggersNlp ActionsNlp ConstraintsNlp
#  
#  
#  ## Macro class
#  
#  Macro
#  
#  
#  ## Error class
#  
#  MacroDroidError
#  
#  
#  ## Droid class
#  
#  MacroDroid
#  
#  
#  ## Map class
#  
#  GeofenceMap
#  
#  
#  ## Object class
#  
#  MacroObject
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



require 'yaml'
require 'rowx'
require 'uuid'
require 'glw'
require 'geozone'
require 'geocoder'
require 'subunit'
require 'rxfhelper'
require 'chronic_cron'


MODEL =<<EOF
device
  connectivity
    airplane_mode is disabled
EOF

class TriggersNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    triggers(params)

  end

  def triggers(params) 
    
    # e.g. at 7:30pm daily
    get /^(?:at )?(\d+:\d+(?:[ap]m)?) daily/i do |time, days|
      [TimerTrigger, {time: time, 
                      days: %w(Mon Tue Wed Thu Fri Sat Sun).join(', ')}]
    end       

    get /^(?:at )?(\d+:\d+(?:[ap]m)?) (?:on )?(.*)/i do |time, days|
      [TimerTrigger, {time: time, days: days}]
    end

    # time.is? 'at 18:30pm on Mon or Tue'
    get /^time.is\? ['"](?:at )?(\d+:\d+(?:[ap]m)?) (?:on )?(.*)['"]/i do |time, days|      
      [TimerTrigger, {time: time, days: days.gsub(' or ',', ')}]
    end     
    
    get /^shake[ _]device\??$/i do 
      [ShakeDeviceTrigger, {}]
    end
    
    get /^Flip Device (.*)$/i do |motion|
       facedown = motion =~ /Face Up (?:->|to) Face Down/i
      [FlipDeviceTrigger, {face_down: facedown }]
    end
    
    get /^flip_device_down\?$/i do
      [FlipDeviceTrigger, {face_down: true }]
    end

    get /^flip_device_up\?$/i do
      [FlipDeviceTrigger, {face_down: false }]
    end        
    
    get /^Failed Login Attempt$/i do
      [FailedLoginTrigger, {}]
    end
    
    get /^failed_login?$/i do
      [FailedLoginTrigger, {}]
    end         

    get /^Geofence (Entry|Exit) \(([^\)]+)/i do |direction, name|
      enter_area = direction.downcase.to_sym == :entry
      [GeofenceTrigger, {name: name, enter_area: enter_area}]
    end     
    
    get /^location (entered|exited) \(([^\)]+)/i do |direction, name|
      enter_area = direction.downcase.to_sym == :entered
      [GeofenceTrigger, {name: name, enter_area: enter_area}]
    end
    
    # eg. Proximity Sensor (Near)
    #
    get /^Proximity Sensor \(([^\)]+)\)/i do |distance|
      
      [ProximityTrigger, {distance: distance}]
    end    

    
    
  end

  alias find_trigger run_route

  def to_s(colour: false)
    'TriggersNlp ' + @h.inspect
  end

  alias to_summary to_s
end

class ActionsNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    actions(params)

  end

  def actions(params) 

    # e.g. message popup: hello world!
    get /^message popup: (.*)/i do |msg|
      [ToastAction, {msg: msg}]
    end

    # e.g. Popup Message 'hello world!'
    get /^Popup[ _]Message ['"]([^'"]+)/i do |msg|
      [ToastAction, {msg: msg}]
    end
    
    # e.g. say current time
    get /^say current[ _]time/i do
      [SayTimeAction, {}]
    end    
    
    get /^Torch :?(.*)/i do |onoffstate|
      state = onoffstate.downcase == 'on' ? 0 : 1
      [CameraFlashLightAction, {state: state}]
    end    
    
    get /^Take Picture/i do
      [TakePictureAction, {}]
    end
    
    get /^take_picture/i do
      [TakePictureAction, {}]
    end           
        
    # e.g. Display Notification: Hi there: This is the body of the message
    get /^Display Notification: ([^:]+): [^$]+$/i do |subject, text|
      [NotificationAction, {subject: subject, text: text}]
    end           
    
    
    # e.g. Enable Wifi
    get /^(Enable|Disable) Wifi$/i do |raw_state|
      
      state = raw_state.downcase.to_sym == :enable ? 0 : 1
      [SetWifiAction, {state: state}]
      
    end    
    
    # e.g. Play: Altair
    get /^Play: (.*)$/i do |name|

      [PlaySoundAction, {file_path: name}]
      
    end     
    
    # e.g. Launch Settings
    get /^Launch (.*)$/i do |application|

      h = {
        application_name: application,
        package_to_launch: 'com.android.' + application.downcase
      }
      [LaunchActivityAction, h]
      
    end
    
    # e.g. HTTP GET http://someurl.com/something
    get /^HTTP GET ([^$]+)$/i do |url|

      [OpenWebPageAction, url_to_open: url]
      
    end
    
    # e.g. webhook entered_kitchen
    #
    get /webhook|HTTP GET/i do
      [OpenWebPageAction, {}]
    end
    
    #a: Keep Device Awake Screen On Until Disabled
    #
    get /Keep Device Awake Screen On Until Disabled/i do
      [KeepAwakeAction, {enabled: true, permanent: true, screen_option: 0}]
    end
    
    
    #a: Keep Device Awake Screen On 1h 1m 1s
    #
    get /Keep Device Awake Screen On ([^$]+)/i do |duration|
      
      a = duration.split.map(&:to_i)
      secs = Subunit.new(units={minutes:60, hours:60, seconds: 60}, a).to_i
      
      h = {
        permanent: true, screen_option: 0, seconds_to_stay_awake_for: secs
      }
      [KeepAwakeAction, h]
    end
    
    #a: Disable Keep Awake
    #
    get /Disable Keep Awake/i do
      [KeepAwakeAction, {enabled: false, screen_option: 0}]
    end    


  end

  alias find_action run_route

  def to_s(colour: false)
    'ActionsNlp ' + @h.inspect
  end

  alias to_summary to_s
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
  attr_accessor :title, :description

  def initialize(name=nil, geofences: geofences, debug: false)

    @title, @geofences, @debug = name, geofences, debug
    
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
      m_name: title(),
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

    if @debug then
      puts 'inside import_h'
      puts 'h:' + h.inspect
    end
    
    @title = h[:name]
    @description = h[:description]
    
    # fetch the local variables
    @local_variables = h['local_variables']
    
    # fetch the triggers
    @triggers = h[:trigger_list].map do |trigger|
      puts 'trigger: ' + trigger.inspect
      #exit      
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
    
    if node.element('triggers') then
            
      # level 2
      
      @title = node.attributes[:name]
      @description = node.attributes[:description]
      
      
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
      
      puts 'import_xml: inside level 1' if @debug
      
      @title = node.text('macro') || node.attributes[:name]
      
      #@description = node.attributes[:description]      
      
      tp = TriggersNlp.new      
      
      @triggers = node.xpath('trigger').map do |e|
        
        r = tp.find_trigger e.text
        
        puts 'found trigger ' + r.inspect if @debug
        
        if r then
          if r[0] == GeofenceTrigger then
            GeofenceTrigger.new(r[1], geofences: @geofences)
          else
            r[0].new(r[1])
          end
        end
        
      end
      
      ap = ActionsNlp.new      
      
      @actions = node.xpath('action').map do |e|
        
        puts 'action e: ' + e.xml.inspect if @debug
        r = ap.find_action e.text
        puts 'found action ' + r.inspect if @debug
        
        if r then
          
          a = e.xpath('item/*')
          
          h = if a.any? then
            a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
          else
            {}
          end
          
          r[0].new(r[1].merge(h))
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
  
  def match?(triggerx, detail={time: $env[:time]}, model=nil )
                
    if @triggers.any? {|x| x.type == triggerx and x.match?(detail, model) } then
      
      if @debug then
        puts 'checking constraints ...' 
        puts '@constraints: ' + @constraints.inspect
      end
      
      if @constraints.all? {|x| x.match?($env.merge(detail), model) } then
      
        true
        
      else

        return false
        
      end
      
    end
    
  end
  
  # invokes the actions
  #
  def run()
    @actions.map(&:invoke)
  end
  
  # prepares the environment in order for triggers to test fire successfully
  # Used for testing
  #
  def set_env()
    @triggers.each(&:set_env)
  end

  def to_pc()
    
    heading = '# ' + @title
    heading += '\n# ' + @description if @description
    condition = @triggers.first.to_pc
    actions = @actions.map(&:to_pc).join("\n")
    
<<EOF
#{heading}

if #{condition} then
  #{actions}
end
EOF
  end
    
  def to_s(colour: false)
    
    indent = 0
    actions = @actions.map do |x|

      s = x.to_s(colour: colour)
      if s.lines.length > 1 then
        lines = s.lines
        s = lines[0] + lines[1..-1].map {|x| x.prepend ('  ' * indent) }.join
      end
      
      r = if indent <= 0 then
      
        if colour then
          "a".bg_blue.gray.bold + ": %s" % s
        else
          "a: %s" % s
        end
        
      elsif indent > 0 
      
        if s =~ /^Else/ then
          ('  ' * (indent-1)) + "%s" % s
        elsif s =~ /^End/
          indent -= 1
          ('  ' * indent) + "%s" % s
        else
          ('  ' * indent) + "%s" % s
        end        
        
      end
      
      if s =~ /^If/i then
        
        if indent < 1 then
          
          r = if colour then
            "a".bg_blue.gray.bold + ":\n  %s" % s
          else
            "a:\n  %s" % s
          end
          
          indent += 1
        else
          r = ('  ' * indent) + "%s" % s
        end

        indent += 1
      end
      
      r
      
    end.join("\n")
    
    a = [
      (colour ? "m".bg_cyan.gray.bold : 'm') + ': ' + @title,
      @triggers.map {|x| (colour ? "t".bg_red.gray.bold : 't') \
                     + ": %s" % x}.join("\n"),
      actions
    ]
    
    if @constraints.any? then
      a << @constraints.map do |x|
        (colour ? "c".bg_green.gray.bold : 'c') + ": %s" % x
      end.join("\n") 
    end
    
    if @description and @description.length >= 1 then
      a.insert(1, (colour ? "d".bg_gray.gray.bold : 'd') + ': ' \
               + @description.gsub(/\n/,"\n  "))
    end
    
    a.join("\n") + "\n"
    
  end
  
  def to_summary(colour: false)
    
    if colour then
      
      a = [
        'm'.bg_cyan.gray.bold + ': ' + @title,
        't'.bg_red.gray.bold + ': ' + @triggers.map \
      {|x| x.to_summary(colour: false)}.join(", "),
        'a'.bg_blue.gray.bold + ': ' + @actions.map \
      {|x| x.to_summary(colour: false)}.join(", ")
      ]
      
      if @constraints.any? then
        a <<  'c'.bg_green.gray.bold + ': ' + @constraints.map \
            {|x| x.to_summary(colour: false)}.join(", ") 
      end      
      
    else
      
      a = [
        'm: ' + @title,
        't: ' + @triggers.map {|x| x.to_summary(colour: false)}.join(", "),
        'a: ' + @actions.map {|x| x.to_summary(colour: false)}.join(", ")
      ]
      
      if @constraints.any? then
        a <<  'c: ' + @constraints.map \
            {|x| x.to_summary(colour: false)}.join(", ") 
      end
    end
    
    
    
    a.join("\n") + "\n"
    
  end

  private
  
  def guid()
    '-' + rand(1..9).to_s + 18.times.map { rand 9 }.join    
  end

  def object(h={})

    puts ('inside object h:'  + h.inspect).debug if @debug  
    klass = Object.const_get h[:class_type]
    puts klass.inspect.highlight if $debug
    
    if klass == GeofenceTrigger then
      puts 'GeofenceTrigger found'.highlight if $debug
      GeofenceTrigger.new(h, geofences: @geofences)
    else
      puts 'before klass'
      h2 = h.merge( macro: self)
      puts 'h2: ' + h2.inspect      
      r = klass.new h2 

      r
      
    end
    
  end

end


class MacroDroidError < Exception
end

class MacroDroid
  using ColouredText
  using Params  

  attr_reader :macros, :geofences, :yaml

  def initialize(obj=nil, debug: false)

    @debug = debug    
    
    @geofences = {}
    
    if obj then
      
      raw_s, _ = RXFHelper.read(obj)    
      
      s = raw_s.strip
      
      if s[0] == '{' then
        
        import_json(s) 
        
      elsif  s[0] == '<'
        
        import_xml(s)
        @h = build_h
        
      else

        puts 's: ' + s.inspect if @debug
        
        if s =~ /m(?:acro)?:\s/ then
          
          puts 'before RowX.new' if @debug

          s2 = s.gsub(/^g:/,'geofence:').gsub(/^m:/,'macro:')\
              .gsub(/^t:/,'trigger:').gsub(/^a:/,'action:')\
              .gsub(/^c:/,'constraint:').gsub(/^#.*/,'')
          
          raw_macros, raw_geofences = s2.split(/(?=^macro:)/,2).reverse
          
          if raw_geofences then
            
            geoxml = RowX.new(raw_geofences).to_xml
            
            geodoc = Rexle.new(geoxml)  
            geofences = geodoc.root.xpath('item/geofence')        
            @geofences = fetch_geofences(geofences) if geofences.any?          
            
          end
          
          xml = RowX.new(raw_macros).to_xml
          import_rowxml(xml)
          
        elsif s =~ /^# / 
          xml = pc_to_xml(s)
          import_xml(xml)
        else
          raise MacroDroidError, 'invalid input'
        end
        
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


  def to_h()

    h = {
      geofence_data: {
        geofence_map: @geofences.map {|key, value| [key, value.to_h] }.to_h
      },
      macro_list:  @macros.map(&:to_h)
    }
    @h.merge(h).to_camel_case

  end
  
  # returns pseudocode
  #
  def to_pc()
    @macros.map(&:to_pc).join("\n\n")
  end

  def to_s(colour: false)
    
    lines = []
    
    if @geofences.any? then
      lines << @geofences.map {|_, value| (colour ? "g".green.bold : 'g') \
                               + ': ' + value.to_s}.join("\n\n") + "\n"
    end
    
    lines << @macros.map {|x| x.to_s(colour: colour)}.join("\n")
    lines.join("\n")
    
  end
  
  def to_summary(colour: false)
    @macros.map {|x| x.to_summary(colour: colour)}.join("\n")
  end  
  
  private
  
  def fetch_geofences(nodes)
    
    nodes.map do |e|

      name = e.text.to_s.strip
      item = e.element('item')
      coordinates = item.text('coordinates')
      location = item.text('location')
      
      if not coordinates and location then
        results = Geocoder.search(location)
        coordinates = results[0].coordinates.join(', ') if results.any?
      end
      
      if coordinates then
        latitude, longitude = coordinates.split(/, */,2)
        radius = item.text('radius')
      end
      
      id = UUID.new.generate

      h = {
        name: name, 
        location: location,
        longitude: longitude, 
        latitude: latitude, 
        radius: radius, 
        id: id
      }
      
      [id.to_sym, GeofenceMap.new(h)]
      
    end.to_h

  end
  
  def import_json(s)

    h = JSON.parse(s, symbolize_names: true)
    puts 'json_to_yaml: ' + h.to_yaml if @debug
    @yaml = h.to_yaml # helpful for debugging and testing
    
    @h = h.to_snake_case
    puts ('@h: ' + @h.inspect).debug if @debug
    
    
    # fetch the geofence data
    if @h[:geofence_data] then
      
      @geofences = @h[:geofence_data][:geofence_map].map do |id, properties|
        [id, GeofenceMap.new(properties)]
      end.to_h
      
    end
    
    @macros = @h[:macro_list].map do |macro|

      puts ('macro: ' + macro.inspect).debug if @debug
#       puts '@geofences: ' + @geofences.inspect if @debug
      
      m = Macro.new(geofences: @geofences.map(&:last), debug: @debug )
      m.import_h(macro)
      m

    end

    @h[:macro_list] = []
    
  end
  
  def import_rowxml(raws)
   
    s = RXFHelper.read(raws).first
    puts 's: ' + s.inspect if @debug
    doc = Rexle.new(s)
    puts 'after doc' if @debug    
    puts 'import_rowxml: @geofences: ' + @geofences.inspect if @debug
    geofences = @geofences
    
    @macros = doc.root.xpath('item').map do |node|
      puts ('geofences: ' + geofences.inspect).highlight if @debug
      Macro.new(geofences: geofences.map(&:last), debug: @debug).import_xml(node)
      
    end

  end  
  
  def import_xml(raws)
    
    if @debug then
      puts 'inside import_xml' 
      
      puts 'raws: ' + raws.inspect 
    end
    s = RXFHelper.read(raws).first
    puts 's: ' + s.inspect if @debug
    doc = Rexle.new(s)
    
    if @debug then
      puts 'doc: ' + doc.root.xml
    end
       
    @macros = doc.root.xpath('macro').map do |node|
          
      Macro.new(geofences: @geofences.map(&:last), debug: @debug).import_xml(node)
      
    end
  end
  
  def pc_to_xml(s)
    
    macros = s.strip.split(/(?=#)/).map do |raw_macro|

      a = raw_macro.lines
      name = a.shift[/(?<=# ).*/]
      description = a.shift[/(?<=# ).*/] if a[0][/^# /]
      body = a.join.strip

      a2 = body.lines
      # get the trigger
      trigger = [:trigger, {}, a2[0][/^if (.*) then/,1]]
      action = [:action, {}, a2[1].strip]
      [:macro, {name: name, description: description}, trigger, action, []]

    end

    doc = Rexle.new([:macros, {}, '', *macros])
    doc.root.xml pretty: true    
    
  end  

end

class GeofenceMap
  
  attr_accessor :name, :longitude, :latitude, :radius, :id
  
  def initialize(id: '', longitude: '', latitude: '', name: '', radius: '', 
                 location: nil)
    
    @id, @latitude, @longitude, @name, @radius, @location = id, latitude, \
        longitude, name, radius, location    
    
  end
  
  def to_h()
    
    {
      id: @id, 
      longitude: @longitude, 
      latitude: @latitude, 
      name: @name, 
      radius: @radius
    }
      
  end
  
  def to_s(colour: false)
    
    lines = []
    coordinates = "%s, %s" % [@latitude, @longitude]
    lines << "%s" % @name
    lines << "  location: %s" % @location if @location
    lines << "  coordinates: %s" % coordinates
    lines << "  radius: %s" % @radius
    lines.join("\n")
    
  end
  
end

class MacroObject
  using ColouredText
  
  attr_reader :type, :siguid
  attr_accessor :options

  def initialize(h={})
    
    $env ||= {}
    
    @attributes = %i(constraint_list is_or_condition is_disabled siguid)
    @h = {constraint_list: [], is_or_condition: false, 
          is_disabled: false, siguid: nil}.merge(h)
    @list = []
    
    # fetch the class name and convert from camelCase to snake_eyes
    @type = self.class.to_s.sub(/Trigger|Action$/,'')\
        .gsub(/\B[A-Z][a-z]/){|x| '_' + x.downcase}\
        .gsub(/[a-z][A-Z]/){|x| x[0] + '_' + x[1].downcase}\
        .downcase.to_sym
    @constraints = []
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
  
  def siguid()
    @h[:siguid]
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
  
  alias to_summary to_s

  protected
  
  def filter(options, h)
    
    (h.keys - (options.keys + @attributes.to_a)).each {|key| h.delete key }    
    return h
    
  end
  
  def uuid()
    UUID.new.generate
  end
  
  def object(h={})

    puts ('inside object h:'  + h.inspect).debug if @debug
    klass = Object.const_get h[:class_type]
    puts klass.inspect.highlight if $debug
    
    klass.new h
    
  end    
  
end

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
class WebHookTrigger < Trigger

  def initialize(h={})

    options = {
      identifier: ''
    }

    super(options.merge h)

  end

  def to_s(colour: false)
    'WebHookTrigger ' + @h.inspect
  end

  alias to_summary to_s
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
    'IncomingCallTrigger ' + @h.inspect
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
    'WebHookTrigger ' + @h.inspect
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
    'WifiConnectionTrigger ' + @h.inspect
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
    'RegularIntervalTrigger ' + @h.inspect
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
    'NotificationTrigger ' + @h.inspect
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

    super(options.merge filter(options,h))

  end
  
  def to_s(colour: false)
    
    distance = if @h[:near] then
      'Near'
    else
      'Far'
    end
    
    "Proximity Sensor (%s)" % distance
  end

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
    'FloatingButtonTrigger ' + @h.inspect
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

class IfConditionAction < Action
  
  def initialize(h={})
    
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

class ElseIfConditionAction < IfConditionAction
  
  def initialize(h={})

    options = {
      constraint_list: ''
    }

    super(options.merge h)
    @label = 'ElseIf '

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
    'SendIntentAction ' + @h.inspect
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
    'ClipboardAction ' + @h.inspect
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
    'Display Notification: ' + "%s: %s" % [@h[:notification_subject], @h[:notification_text]]
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
  
  def to_pc()
    "popup_message '%s'" % @h[:message_text]
  end
  
  def to_s(colour: false)
    "Popup Message '%s'" % @h[:message_text]
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
    'ScreenOnAction ' + @h.inspect
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
      
      'Keep Device Awake ' + screen + ' ' + whenx
      
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
    "Device Connected (%s)" % device
  end
  
  alias to_summary to_s

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
    'WifiConstraint ' + @h.inspect
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
    'LastRunTimeConstraint ' + @h.inspect
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


# ----------------------------------------------------------------------------


class DroidSim

  class Service
    def initialize(callback)
      @callback = callback
    end
  end

  class Application < Service

    def closed()
    end
    def launched()
    end
  end

  class Battery < Service

    def level()
    end

    def temperature()
    end

  end
  class Bluetooth < Service

    def enable()
      @callback.on_bluetooth_enabled()
    end

    #def enabled
    #  @callback.on_bluetooth_enabled()
    #end

    def enabled?
    end

    def disabled
    end

    def disabled?
    end
  end

  class Calendar < Service
    def event(starts, ends)
    end
  end

  class DayTime < Service

    def initialie(s)
    end
  end

  class Headphones < Service
    def inserted
    end

    def removed
    end
  end

  class Webhook < Service

    def url()
      @url
    end

    def url=(s)
      @url = s
    end
  end

  class Wifi < Service
    def enabled
    end

    def disabled
    end

    def ssid_in_range()
    end

    def ssid_out_of_range()
    end
  end

  class Power < Service
    def connected()
    end

    def disconnected()
    end

    def button_toggle()
    end
  end

  class Popup < Service
    def message(s)
      puts s
    end
  end


  attr_reader :bluetooth, :popup

  def initialize()

    @bluetooth = Bluetooth.new self
    @popup = Popup.new self

  end

  def on_bluetooth_enabled()
  
  end


end
