#!/usr/bin/env ruby

# file: triggersnlp.rb


class TriggersNlp
  include AppRoutes
  using ColouredText

  def initialize(macro=nil)

    super()
    params = {macro: macro}
    triggers(params)

  end

  def triggers(params)
    
    # -- Battery/Power ---------------------------------------------
    
    get /^Power Button Toggle \((\d)\)/i do |num|
      [PowerButtonToggleTrigger, {num_toggles: num.to_i}]
    end    
    
    get /^Power Button (\d) times$/i do |num|
      [PowerButtonToggleTrigger, {num_toggles: num.to_i}]
    end
    
    get /^Power Connected: (Wired \([^\)]+\))/i do |s|
      
      h = {
        power_connected_options: [true, true, true],
        has_set_usb_option: true,
        power_connected: true
      }
        
      a = ['Wired (Fast Charge)', 'Wireless', 'Wired (Slow Charge)']

      puts ('s: ' + s.inspect).debug
      
      options = s.downcase.split(/ \+ /)
      puts ('options: ' + options.inspect).debug
      
      h[:power_connected_options] = a.map {|x| options.include? x.downcase }
      
      [ExternalPowerTrigger, h]
    end
    
    get /^Power Connected: Any/i do |s|
      
      h = {
        power_connected_options: [true, true, true],
        has_set_usb_option: true,
        power_connected: true
      }
      
      [ExternalPowerTrigger, h]
    end   
    
    # -- Connectivity ----------------------------------------------------
    #
    
    # Wifi State Change
    
    get /^Connected to network (.*)$/i do |network|            
      [WifiConnectionTrigger, {ssid_list: [network], wifi_state: 2 }]
    end         
    
    get /^Connected to network$/i do            
      [WifiConnectionTrigger, {}]
    end       
    
  
    
    # -- Device Events ----------------------------------------------------
    
    get /^NFC Tag$/i do |state|            
      [NFCTrigger, {}]
    end         
  
    get /^Screen[ _](On|Off)/i do |state|            
      [ScreenOnOffTrigger, {screen_on: state.downcase == 'on'}]
    end      
    
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
    
    # eg. Proximity near
    #
    get /^Proximity (near|far|slow wave|fast wave)/i do |distance|
      
      [ProximityTrigger, {distance: distance}]
    end       
    
    get /^WebHook \(Url\)/i do       
      [WebHookTrigger, params]
    end      

    get /^WebHook/i do       
      [WebHookTrigger, params]
    end
    
    get /^wh/i do       
      [WebHookTrigger, params]
    end          

    #-- MacroDroid specific ---------------------------------------------------------------

    get /^EmptyTrigger$/i do       
      [EmptyTrigger, params]
    end
    
    #-- Sensors ---------------------------------------------------------------

    get /^Activity - (.*)$/i do |s|
      
      a = ['In Vehicle', 'On Bicycle', 'Running', 'Walking', 'Still']
      r = a.find {|x| x.downcase == s.downcase}
      h = r ? {selected_index: a.index(r)} : {}
      [ActivityRecognitionTrigger , h]
    end    
    
    # -- User Input ---------------------------------------------------------------

    get /^Media Button Pressed$/i do       
      [MediaButtonPressedTrigger, {}]
    end              
    
    get /^Media Button V2$/i do       
      [MediaButtonV2Trigger, {}]
    end
    
    get /^Shortcut Launched$/i do       
      [ShortcutTrigger, {}]
    end                  
    
    get /^Swipe Screen$/i do       
      [SwipeTrigger, {}]
    end
    
    get /^Swipe (top left) (across|diagonal|down)$/i do |start, motion|
                  
      swipe_motion = case motion.downcase.to_sym
      when :across
        0
      when :diagonal
        1
      when :down
        2
      end
      
      h = {
        swipe_start_area: (start.downcase == 'top left' ? 0 : 1),
        swipe_motion: swipe_motion
      }
      
      [SwipeTrigger, h]
      
    end
    
  end

  alias find_trigger run_route

  def to_s(colour: false)
    'TriggersNlp ' + @h.inspect
  end

  alias to_summary to_s
end
