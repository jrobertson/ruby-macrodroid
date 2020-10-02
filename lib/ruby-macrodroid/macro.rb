# file: ruby-macrodroid/macro.rb


# This file contains the following classes:
#  
#  ## Macro class
#  
#  Macro



VAR_TYPES = {
  String: [2, :string_value], 
  TrueClass: [0, :boolean_value], 
  TrueClass: [0, :boolean_value],
  Integer: [1, :int_value],
  Float: [3, :decimal_value]
}


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
      local_variables: varify(@local_variables),
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
      
      @local_variables = node.xpath('variable').map do |e|
        
        label, v = e.text.to_s.split(/: */,2)
        
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
        
        [label, value]
      end
      
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
              o = r[0].new([description, self]) if r              
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
            r[0].new(h) if r
            
          end
          
        else
          
          trigger = e.text.strip
          r = tp.find_trigger trigger
          r[0].new(r[1]) if r
          
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
              o = r[0].new([description, self]) if r
              puts 'after o' if @debug
              o
              
            end
            
          else
            
            action = e.text.strip
            r = ap.find_action action

            a = e.xpath('item/*')

            h = if a.any? then
              a.map {|node| [node.name.to_sym, node.text.to_s]}.to_h
            else
              {}
            end

            r = ap.find_action action          
            r[0].new(h) if r
            
          end
          
        else
          
          action = e.text.strip
          r = ap.find_action action          
          r[0].new(r[1]) if r
          
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
  
  def varify(local_variables)
    
        
    local_variables.map do |key, value|
            
      puts 'value ' + value.class.to_s.to_sym.inspect
      puts 'VAR_TYPES: ' + VAR_TYPES.inspect
      type = VAR_TYPES[value.class.to_s.to_sym]
      puts 'type: ' + type.inspect
      h = {
        boolean_value: false,
        decimal_value: 0.0,
        int_value: 0,
        name: key,
        string_value: '',
        type: type[0]
      }
      h[type[1]] = value
      h
    end
    
  end

end
