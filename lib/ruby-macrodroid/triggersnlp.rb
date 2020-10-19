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
    
    # -- Device Events ----------------------------------------------------
  
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

    #  MacroDroid specific ---------------------------------------------------------------

    get /^EmptyTrigger$/i do       
      [EmptyTrigger, params]
    end          
    
  end

  alias find_trigger run_route

  def to_s(colour: false)
    'TriggersNlp ' + @h.inspect
  end

  alias to_summary to_s
end
