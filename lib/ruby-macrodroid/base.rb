# file: ruby-macrodroid/base.rb

# This file contains the following classes:
#
#  ## Object class
#  
#  MacroObject
#  

module ObjectX
  
  def action_to_object(ap, e, item, macro)
    
    debug = true
    
    puts 'inside action_to_object: item.xml: ' + item.xml if debug
        
    if item.element('description') then
      
      item.xpath('description').map do |description|
        
        inner_lines = description.text.to_s.strip.lines
        puts 'inner_lines: ' + inner_lines.inspect if debug
        
        action = if e.text.to_s.strip.empty? then
          inner_lines.shift.strip
        else
          e.text.strip
        end
        
        puts 'action: ' + action.inspect if debug
        
        r = ap.find_action action          
        puts 'r: ' + r.inspect if debug
        puts 'description: ' + description.xml.inspect if debug
        #o = r[0].new([description, self]) if r
        index = macro.actions.length
        macro.add Action.new        
        o = object_create(r[0],[description, macro]) if r
        macro.actions[index] = o
        puts 'after o' if debug
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
      o = object_create(r[0], h.merge(macro: macro)) if r
      macro.add o
      o
      
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

    hashify(@h)

  end
  
  def siguid()
    @h[:siguid]
  end
  
  def to_s(colour: false, indent: 0)
    
    h = @h.clone    
    h.delete :macro
    @s ||= "#<%s %s>" % [self.class, h.inspect]
    operator = @h[:is_or_condition] ? 'OR' : 'AND'
    constraints = @constraints.map \
        {|x| 'c: ' + x.to_summary(colour: colour)}
    
    out = []
    out << "; %s" % @h[:comment] if @h[:comment] and @h[:comment].length > 1
    #s = @s.lines.map {|x| 'x' + x}.join
    
    lines = @s.lines
    
    if lines.length > 1 then        
      s = lines[0] + lines[1..-1].map {|x| x.prepend ('  ' * (indent+1)) }.join
    else
      s = @s
    end
    
    out << s
    out += constraints
    out.join("\n")
    
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

    puts ('inside object h:'  + h.inspect).debug if $debug
    klass = Object.const_get h[:class_type]
    puts klass.inspect.highlight if $debug
    
    klass.new h
    
  end
  
  private
  
  def hashify(h)
    
    h2 = h.inject({}) do |r,x|
      puts 'x: ' + x.inspect if $debug
      key, value = x
      puts 'key: ' + key.inspect if $debug
      new_key = key.to_s.gsub(/\w_\w/){|x| x[0] + x[-1].upcase}
      new_key = new_key.prepend 'm_' unless @list.include? new_key
      new_key = 'm_SIGUID' if new_key == 'm_siguid'
      new_val = value.is_a?(Hash) ? hashify(value) : value
      r.merge(new_key => new_val)
    end
    
    h2.merge('m_classType' => self.class.to_s)    
  end
  
end

