#!/usr/bin/env ruby

# file: actionsnlp.rb


class ActionsNlp
  include AppRoutes

  def initialize(macro=nil)

    super()

    params = {macro: macro}
    actions(params)

  end

  def actions(params)
    
    # -- Conditions/Loops ---------------------------------------------
    #
    
    get /else if (.*)/i do
      [ElseIfConditionAction, {}]
    end        
    
    #e.g a: if Airplane mode enabled
    #
    get /if (.*)/i do
      [IfConditionAction, {}]
    end    
    
    get /else/i do
      [ElseAction, {}]
    end    
    
    get /End If/i do
      [EndIfAction, {}]
    end          
    
    
    # -- Connectivity ------------------------------------------------------
    
    get /^(Enable|Disable) HotSpot/i do |state|
      enable, state = if state.downcase == 'enable' then
        [true, 0]
      else
        [false, 1]
      end
      [SetHotspotAction, {turn_wifi_on: enable, state: state }]
    end   
    
    # e.g. message popup: hello world!
    get /^(?:message popup|popup message): (.*)/i do |msg|
      [ToastAction, {msg: msg}]
    end

    # e.g. Popup Message 'hello world!'
    get /^Popup[ _]Message ['"]([^'"]+)/i do |msg|
      [ToastAction, {msg: msg}]
    end
    
    # e.g. Popup Message\n  hello world!
    get /^Popup Message\n\s+(.*)/im do |msg|
      [ToastAction, {msg: msg}]
    end    
            
    # e.g. Popup Message
    get /^Popup Message$/i do
      [ToastAction, {}]
    end    
    
    # e.g. say current time
    get /^say current[ _]time/i do
      [SayTimeAction, {}]
    end    
    
    get /^Torch :?(.*)/i do |onoffstate|
      state = %w(on off toggle).index onoffstate.downcase
      [CameraFlashLightAction, {state: state}]
    end    
    
    get /^Take Picture/i do
      [TakePictureAction, {}]
    end
    
    get /^take_picture/i do
      [TakePictureAction, {}]
    end           
    
    # -- DEVICE ACTIONS ------------------------------------------------------
    
    get /^Speak text \(([^\)]+)\)/i do |text|
      [SpeakTextAction, {text: text}]
    end           
    
    get /^Speak text ['"]([^'"]+)/i do |text|
      [SpeakTextAction, {text: text}]
    end         
    
    get /^Speak text$/i do |text|
      [SpeakTextAction, {}]
    end     
    
    get /^Vibrate \(([^\)]+)/i do |pattern|
      [VibrateAction, {pattern: pattern}]
    end     
    
    get /^Vibrate$/i do |pattern|
      [VibrateAction, {pattern: 'short buzz'}]
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
        
    get /^HTTP GET$/i do

      [OpenWebPageAction, {}]
      
    end    
    
    # e.g. webhook entered_kitchen
    #
    get /(?:webhook|HTTP GET) ([^$]+)$/i do |s|
      key = s =~ /^http/ ? :url_to_open : :identifier      
      [OpenWebPageAction, {key => s}]
    end
    
    #
    get /^WebHook \(Url\)/i do
      [OpenWebPageAction, {}]
    end
    
    # e.g. webhook entered_kitchen
    #
    get /^webhook$/i do
      [OpenWebPageAction, {}, params[:macro]]
    end
    
    # -- Location ---------------------------------------------------------
    
    get /^Force Location Update$/i do
      [ForceLocationUpdateAction, params]
    end    
    
    get /^Share Location$/i do
      [ShareLocationAction, {}]
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
    
    get /(?:Keep Device|stay) Awake$/i do
      [KeepAwakeAction, {}]
    end    
    
    #a: Disable Keep Awake
    #
    get /Disable Keep Awake|stay awake off/i do
      [KeepAwakeAction, {enabled: false, screen_option: 0}]
    end    

    
    # -- MacroDroid Specific ------------------------------------------------
    #
    
    get /^((?:En|Dis)able) Macro$/i do |rawstate|
      state = %w(enable disable toggle).index(rawstate.downcase)
      [DisableMacroAction, {state: state}]
    end        
    
    get /^Set Variable$/i do
      [SetVariableAction, {}]
    end        

    get /^wait (\d+) seconds$/i do |seconds|
      [PauseAction, {delay_in_seconds: seconds.to_i}]
    end        
    
    # -- Screen ------------------------------------------------
    #
    get /^Screen (On|Off)$/i do |state|
      [ScreenOnAction, {screen_off: state.downcase == 'off'}]
    end       

  end

  alias find_action run_route


end
