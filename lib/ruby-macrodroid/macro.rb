# file: ruby-macrodroid/macro.rb


# This file contains the following classes:
#  
#  ## Nlp classes
#  
#  TriggersNlp ActionsNlp ConstraintsNlp
#     
#  ## Macro class
#  
#  Macro



VAR_TYPES = {
  String: [2, :string_value], 
  TrueClass: [0, :boolean_value], 
  FalseClass: [0, :boolean_value],
  Integer: [1, :int_value],
  Float: [3, :decimal_value]
}

class TriggersNlp
  include AppRoutes

  def initialize(macro=nil)

    super()
    params = {macro: macro}
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

class ActionsNlp
  include AppRoutes

  def initialize(macro=nil)

    super()
    params = {macro: macro}
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
      [OpenWebPageAction, params]
    end
    
    # e.g. webhook entered_kitchen
    #
    get /^webhook$/i do
      [OpenWebPageAction, params]
    end
    
    # -- Location ---------------------------------------------------------
    
    get /^Force Location Update$/i do
      [ForceLocationUpdateAction, params]
    end    
    
    get /^Share Location$/i do
      [ShareLocationAction, params]
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
    
    get /Keep Device Awake$/i do
      [KeepAwakeAction, params]
    end    
    
    #a: Disable Keep Awake
    #
    get /Disable Keep Awake/i do
      [KeepAwakeAction, {enabled: false, screen_option: 0}]
    end    

    #e.g a: if Airplane mode enabled
    #
    get /if (.*)/i do
      [IfConditionAction, {}]
    end
    
    get /End If/i do
      [EndIfAction, {}]
    end          
    
    # -- MacroDroid Specific ------------------------------------------------
    #
    get /^Set Variable$/i do
      [SetVariableAction, {}]
    end        

  end

  alias find_action run_route


end

class ConstraintsNlp
  include AppRoutes

  def initialize()

    super()
    params = {}
    constraints(params)

  end

  def constraints(params) 
    
    # Device State        
    
    get /^Device (locked|unlocked)/i do |state|
      [DeviceLockedConstraint, {locked: state.downcase == 'locked'}]
    end

    get /^airplane mode (.*)/i do |state|
      [AirplaneModeConstraint, {enabled: (state =~ /^enabled|on$/i) == 0}]
    end
    
    # 
    
    # -- Sensors -----------------------------------
    #
    get /^Light Sensor (Less|Greater) than (50.0)lx/i do |operator, val|

      level, option = operator.downcase == 'less' ? [-1,0] : [1,1]
      
      h = {
        light_level: level,
        light_level_float: val,
        option: option
      }
      
      [LightLevelConstraint, h]
    end
    
    get /^Proximity Sensor: (Near|Far)/i do |distance|      
      [ProximitySensorConstraint, {near: distance.downcase == 'near'}]
    end
    
    
    # -- Screen and Speaker ---------------------------
    #
    get /^Screen (On|Off)/i do |state|      
      [ScreenOnOffConstraint, {screen_on: state.downcase == 'on'}]
    end    

  end

  alias find_constraint run_route

end


class MacroError < Exception
end

class Macro
  using ColouredText
  using Params

  attr_reader :local_variables, :triggers, :actions, :constraints, 
      :guid, :deviceid
  attr_accessor :title, :description, :remote_url

  def initialize(name=nil, geofences: nil, deviceid: nil, remote_url: nil, 
                 debug: false)

    @title, @geofences, @deviceid, @debug = name, geofences, deviceid, debug
    @remote_url = remote_url
    
    puts 'inside Macro#initialize' if @debug    
          
    @local_variables, @triggers, @actions, @constraints = {}, [], [], []
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
    
    a = @local_variables.map do |k,v|
      varify(k,v).to_camelcase.map{|key,value| ['m_' + key, value]}.to_h
    end

    h = {
      local_variables: a,
      m_trigger_list: @triggers.map(&:to_h),
      m_action_list: @actions.map(&:to_h),
      m_category: @category,
      m_constraint_list: @constraints.map(&:to_h),
      m_description: '',
      m_name: title(),
      m_excludeLog: false,
      m_GUID: guid(),
      m_isOrCondition: false,
      m_enabled: true,
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
    
    @category = h[:category]
    @title = h[:name]
    @description = h[:description]
    
    # fetch the local variables
    if h[:local_variables].any? and h[:local_variables].first.any? then
      
      @local_variables = h[:local_variables].map do |var|

        val = case var[:type]
        when 0 # boolean
          var[:boolean_value]
        when 1 # integer
          var[:int_value]
        when 2 # string
          var[:string_value]
        when 3 # decimal
          var[:decimal_Value]
        end
        
        [var[:name], val]
        
      end.to_h
    end
    
    # fetch the triggers
    @triggers = h[:trigger_list].map do |trigger|
      puts 'trigger: ' + trigger.inspect if @debug
      #exit      
      object(trigger.to_snake_case)

    end

    @actions = h[:action_list].map do |action|
      object(action.to_snake_case)
    end
    puts 'before fetch constraints' if @debug
    # fetch the constraints                               
    @constraints = h[:constraint_list].map do |constraint|
      object(constraint.to_snake_case)
    end                               
    puts 'after fetch constraints' if @debug    
    @h = h

    %i(local_variables m_trigger_list m_action_list m_constraint_list)\
      .each {|x| @h[x] = [] }
    puts 'after @h set' if @debug    
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
      @category = node.attributes[:category]
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
      
      d = node.element('description')
      
      if d then
        
        desc = []
        desc << d.text.strip
        
        if d.element('item/description') then
          desc <<  d.text('item/description').strip
        end
        
        @description = desc.join("\n")

      end
      
      node.xpath('variable').each {|e| set_var(*e.text.to_s.split(/: */,2)) }
      
      #@description = node.attributes[:description]      
      
      tp = TriggersNlp.new(self)      
      
      @triggers = node.xpath('trigger').flat_map do |e|
        
        r = tp.find_trigger e.text
        
        puts 'found trigger ' + r.inspect if @debug
        
        item = e.element('item')
        if item then
          
          if item.element('description') then
            
            item.xpath('description').map do |description|
              
              inner_lines = description.text.to_s.strip.lines
              puts 'inner_lines: ' + inner_lines.inspect if @debug
              
              trigger = if e.text.to_s.strip.empty? then
                inner_lines.shift.strip
              else
                e.text.strip
              end
              
              puts 'trigger: ' + trigger.inspect if @debug
              
              r = tp.find_trigger trigger          
              puts 'r: ' + r.inspect if @debug
              #o = r[0].new([description, self]) if r
              o = object_create(r[0], [description, self]) if r                            
              puts 'after o' if @debug
              o
              
            end
            
          else
            
            trigger = e.text.strip
            r = tp.find_trigger trigger

            a = e.xpath('item/*')

            h = if a.any? then
              a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
            else
              {}
            end

            r = tp.find_trigger trigger          
            #r[0].new(h) if r
            if r then
              object_create(r[0], h)
            else
              raise MacroError, 'App-routes: Trigger "' + trigger + '" not found' 
            end
            
          end
          
        else
          
          trigger = e.text.strip
          r = tp.find_trigger trigger
          #r[0].new(r[1]) if r
          
          if r then
            object_create(r[0],r[1])
          else
            raise MacroError, 'App-routes: Trigger "' + trigger + '" not found' 
          end
          
        end
        
        
      end
    

      
      ap = ActionsNlp.new self    
      
      @actions = node.xpath('action').flat_map do |e|
        
        puts 'action e: ' + e.xml.inspect if @debug
        puts 'e.text ' + e.text if @debug
        
        item = e.element('item')
        if item then
          
          if item.element('description') then
            
            item.xpath('description').map do |description|
              
              inner_lines = description.text.to_s.strip.lines
              puts 'inner_lines: ' + inner_lines.inspect if @debug
              
              action = if e.text.to_s.strip.empty? then
                inner_lines.shift.strip
              else
                e.text.strip
              end
              
              puts 'action: ' + action.inspect if @debug
              
              r = ap.find_action action          
              puts 'r: ' + r.inspect if @debug
              puts 'description: ' + description.xml.inspect if @debug
              #o = r[0].new([description, self]) if r
              o = object_create(r[0],[description, self]) if r
              puts 'after o' if @debug
              o
              
            end
            
          else
            
            action = e.text.strip
            puts 'action: ' + action.inspect if @debug
            r = ap.find_action action

            a = e.xpath('item/*')

            h = if a.any? then
              a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
            else
              {}
            end
            puts 'h: ' + h.inspect if @debug

            #r = ap.find_action action          
            #r[0].new(h.merge(macro: self)) if r
            object_create(r[0], h.merge(macro: self)) if r
            
          end
          
        else
          
          action = e.text.strip
          r = ap.find_action action          
          #r[0].new(r[1]) if r
          object_create(r[0],r[1]) if r
          
        end

      end      
                               
      cp = ConstraintsNlp.new      
      
      @constraints = node.xpath('constraint').map do |e|
        
        r = cp.find_constraint e.text
        puts 'found constraint ' + r.inspect if @debug
        
        object_create(r[0], r[1]) if r
        
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
  
  def set_var(label, v='')
        
    value = if v.to_f.to_s == v
      v.to_f
    elsif v.downcase == 'true'
      true
    elsif v.downcase == 'false' 
      false
    elsif v.to_i.to_s == v
      v.to_i
    else
      v
    end

    if not @local_variables.has_key? label.to_sym then
      @local_variables.merge!({label.to_sym => value}) 
    end

    varify(label, value)
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
    
    indent = 0 #@actions.map(&:to_s).join.lines.length > 0 ? 1 : 0
    
    a = []
    a << '# ' + @category + "\n" if @category
    a <<  (colour ? "m".bg_cyan.gray.bold : 'm') + ': ' + @title

    
    if @description and @description.length >= 1 then
      a << (colour ? "d".bg_gray.gray.bold : 'd') + ': ' \
               + @description.gsub(/\n/,"\n  ")
    end    
    
    if @local_variables.length >= 1 then
      
      vars = @local_variables.map do |k,v|
        label = colour ? 'v'.bg_magenta : 'v'
        label += ': '
        label + "%s: %s" % [k,v]
      end
      
      a << vars.join("\n")
    end    

    puts 'before triggers' if @debug
    
    a << @triggers.map do |x|
      
      puts 'x: ' + x.inspect if @debug
      raise 'Macro#to_s trigger cannot be nil' if x.nil?
      
      s =-x.to_s(colour: colour)
      puts 's: ' + s.inspect if @debug
      
      s2 = if s.lines.length > 1 then        
        "\n" + s.lines.map {|x| x.prepend ('  ' * (indent+1)) }.join
      else
        ' ' + s
      end         
      
      puts 's2: ' + s2.inspect if @debug
      
      #s.lines > 1 ? "\n" + x : x
      (colour ? "t".bg_red.gray.bold : 't') + ":" + s2
    end.join("\n")
    
    puts 'before actions' if @debug
    actions = @actions.map do |x|

      puts 'x: ' + x.inspect if @debug
      raise 'Macro#to_s action cannot be nil' if x.nil?
      s = x.to_s(colour: colour)
      #puts 's: ' + s.inspect      
      

      
      r = if indent <= 0 then
      
        lines = s.lines
        
        if lines.length > 1 then        
          s = lines.map {|x| x.prepend ('  ' * (indent+1)) }.join
        end      

        s2 = s.lines.length > 1 ? "\n" + s : ' ' + s        
        
        if colour then
          "a".bg_blue.gray.bold + ":" + s2
        else
          "a:" + s2
        end
        
      elsif indent > 0 
      
        if s =~ /^Else/ then
          ('  ' * (indent-1)) + "%s" % s
        elsif s =~ /^End/
          indent -= 1
          ('  ' * indent) + "%s" % s
        else
          s2 = s.lines[0] + s.lines[1..-1].map {|x| ('  ' * indent) + x }.join
          ('  ' * indent) + "%s" % s2
        end        
        
      end
      
      if s =~ /^(?:If|DO \/ WHILE)/i then
        
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


    

    a << actions

    
    puts 'before constraints' if @debug
    if @constraints.any? then
      a << @constraints.map do |x|
        (colour ? "c".bg_green.gray.bold : 'c') + ": %s" % x
      end.join("\n") 
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
    puts klass.inspect.highlight if @debug
    
    if klass == GeofenceTrigger then
      puts 'GeofenceTrigger found'.highlight if @debug
      GeofenceTrigger.new(h, geofences: @geofences)
    else
      puts 'before klass' if @debug
      h2 = h.merge( macro: self)
      puts 'h2: ' + h2.inspect if @debug      
      r = klass.new h2 
      puts 'r:' + r.inspect if @debug
      r
      
    end
    
  end
  
  def object_create(klass, *args)

    begin
      klass.new(*args)
    rescue
      raise MacroError, klass.to_s + ': ' + ($!).to_s
    end
  end
  
  def varify(label, value='')
                        

    type = VAR_TYPES[value.class.to_s.to_sym]

    h = {
      boolean_value: false,
      decimal_value: 0.0,
      int_value: 0,
      name: label,
      string_value: '',
      type: type[0]
    }
    h[type[1]] = value
    h
    
  end

end
