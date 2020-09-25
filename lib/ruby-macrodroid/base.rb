# file: ruby-macrodroid/base.rb

# This file contains the following classes:
#
#  ## Object class
#  
#  MacroObject
#  



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

    puts ('inside object h:'  + h.inspect).debug if @debug
    klass = Object.const_get h[:class_type]
    puts klass.inspect.highlight if $debug
    
    klass.new h
    
  end    
  
end

