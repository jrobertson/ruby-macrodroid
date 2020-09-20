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

    #a: Disable Keep Awake
    #
    get /if (.*)/i do
      [IfConditionAction, {}]
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

  attr_reader :local_variables, :triggers, :actions, :constraints, 
      :guid, :deviceid
  attr_accessor :title, :description

  def initialize(name=nil, geofences: nil, deviceid: nil, debug: false)

    @title, @geofences, @deviceid, @debug = name, geofences, deviceid, debug
    
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
      m_category: @category,
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
      puts 'trigger: ' + trigger.inspect
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
        puts 'e.text ' + e.text if @debug
        
        inner_lines = e.xpath('item/description/text()')        
        
        action = if e.text.to_s.strip.empty? then
          inner_lines.shift
        else
          e.text.strip
        end
        
        r = ap.find_action action
        puts 'found action ' + r.inspect if @debug
        
        if r then
          
          loose = inner_lines.shift
          
          raw_attributes = if loose then
          
            puts 'do something ' + loose.to_s if @debug
            loose.to_s
            
          else
            
            a = e.xpath('item/*')
            
            h = if a.any? then
              a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
            else
              {}
            end
            
            r[1].merge(h)
            
          end
          r[0].new(raw_attributes)
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
      
      if s =~ /^(?:If|WHILE \/ DO)/i then
        
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
    
    a << @triggers.map {|x| (colour ? "t".bg_red.gray.bold : 't') \
                     + ": %s" % x}.join("\n")
    a << actions

    
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
    puts klass.inspect.highlight if $debug
    
    if klass == GeofenceTrigger then
      puts 'GeofenceTrigger found'.highlight if $debug
      GeofenceTrigger.new(h, geofences: @geofences)
    else
      puts 'before klass'
      h2 = h.merge( macro: self)
      puts 'h2: ' + h2.inspect      
      r = klass.new h2 
      puts 'r:' + r.inspect
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
  attr_accessor :deviceid
  
  # note: The deviceid can only be found from an existing Webhook trigger, 
  #       generated from MacroDroid itself.

  def initialize(obj=nil, deviceid: nil, debug: false)

    @deviceid, @debug = deviceid, debug    
    
    @geofences = {}
    
    if obj then
      
      raw_s, _ = RXFHelper.read(obj)    
      
      s = raw_s.strip
      
      if s[0] == '{' then
        
        import_json(s) 
        puts 'after import_json' if @debug
        
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
      
      m = Macro.new(geofences: @geofences.map(&:last), deviceid: @deviceid, 
                    debug: @debug )
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
      Macro.new(geofences: geofences.map(&:last), deviceid: @deviceid, 
                debug: @debug).import_xml(node)
      
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
          
      Macro.new(geofences: @geofences.map(&:last), deviceid: @deviceid, 
                debug: @debug).import_xml(node)
      
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

require 'ruby-macrodroid/base'
require 'ruby-macrodroid/triggers'
require 'ruby-macrodroid/actions'
require 'ruby-macrodroid/constraints'
