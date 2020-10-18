#!/usr/bin/env ruby

# file: ruby-macrodroid.rb

# This file contains the following classes:
#
#  ## Nlp classes
#  
#  TriggersNlp ActionsNlp ConstraintsNlp
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
#require 'glw'
#require 'geozone'
require 'geocoder'
require 'subunit'
require 'rxfhelper'
require 'chronic_cron'


# PASTE_START

MODEL =<<EOF
device
  connectivity
    airplane_mode is disabled
EOF

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
    def to_camelcase(h=self)
      
      h.inject({}) do |r,x|
                
        key, value = x   
        
        val = if value.is_a?(Hash) then
          to_camelcase(value)
        elsif value.is_a?(Array) and value.first.is_a? Hash
          value.map {|row| to_camelcase(row)}
        else
          value          
        end
        
        r.merge({key.to_s.gsub(/(?<!^m)_[a-z]/){|x| x[-1].upcase} => val})
      end
      
    end


  end

end



class MacroDroidError < Exception
end

class MacroDroid
  include RXFHelperModule
  using ColouredText
  using Params  

  attr_reader :macros, :geofences, :yaml
  attr_accessor :deviceid, :remote_url, :picture_path
  
  # note: The deviceid can only be found from an existing Webhook trigger, 
  #       generated from MacroDroid itself.

  def initialize(obj=nil, deviceid: nil, remote_url: nil, 
                 picture_path: '/storage/emulated/0/Pictures', debug: false)

    @deviceid, @remote_url, @debug = deviceid, remote_url, debug    
    @picture_path = picture_path
    
    @geofences = {}
    @macros = []
    
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
          
          import_txt(s)
          
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
  
  def export(filepath)
    FileX.write filepath, to_json
  end
  
  def import(s)
    import_txt(s)
  end

  def to_json()

    to_h.to_json

  end
  

  def to_h()

    h = {
      geofence_data: {
        geofence_map: @geofences.map {|key, value| [key, value.to_h] }.to_h
      },
      macro_list:  @macros.map(&:to_h)
    }
    @h.merge(h).to_camelcase

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
                    remote_url: @remote_url, picture_path: @picture_path, 
                    parent: self, debug: @debug )
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
    
    a = doc.root.xpath('item').map do |node|
      puts ('geofences: ' + geofences.inspect).highlight if @debug
      Macro.new(geofences: geofences.map(&:last), deviceid: @deviceid, 
                remote_url: @remote_url, picture_path: @picture_path, 
                parent: self, debug: @debug).import_xml(node)
      
    end
    
    @macros.concat a

  end

  def import_txt(s)
    
    puts 'before RowX.new' if @debug

    s2 = s.gsub(/^g:/,'geofence:').gsub(/^m:/,'macro:')\
        .gsub(/^d:/,'description:').gsub(/^v:/,'variable:')\
        .gsub(/^t:/,'trigger:').gsub(/^a:/,'action:')\
        .gsub(/^c:/,'constraint:').gsub(/^#.*/,'')
    
    a = s2.split(/(?=^macro:)/)
    
    raw_geofences = a.shift if a.first =~ /^geofence/
    raw_macros = a.join
    #raw_macros, raw_geofences .reverse
    
    puts 'raw_macros: ' + raw_macros.inspect if @debug
    
    if raw_geofences then
      
      geoxml = RowX.new(raw_geofences).to_xml
      
      geodoc = Rexle.new(geoxml)  
      geofences = geodoc.root.xpath('item/geofence')        
      @geofences = fetch_geofences(geofences) if geofences.any?          
      
    end
    
    xml = RowX.new(raw_macros, allow_lonely_keyfield: true).to_xml
    puts 'xml: ' + xml if @debug
    import_rowxml(xml)
    
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
      puts 'node: ' + node.inspect if @debug    
      Macro.new(geofences: @geofences.map(&:last), deviceid: @deviceid, 
                picture_path: @picture_path, parent: self, debug: @debug)\
                .import_xml(node)
      
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

# PASTE_END

require 'ruby-macrodroid/base'
require 'ruby-macrodroid/triggers'
require 'ruby-macrodroid/actions'
require 'ruby-macrodroid/constraints'
require 'ruby-macrodroid/macro'
