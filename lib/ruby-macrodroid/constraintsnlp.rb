#!/usr/bin/env ruby

# file: constraintsnlp.rb


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
    
    # -- MacroDroid specific -----------------------------------------------------------------------
    
    get /^(\w+) (=) (.*)/i do |loperand, operator, roperand|
      
      h = {
        loperand: loperand, 
        operator: operator, 
        roperand: roperand
      }
      
      [MacroDroidVariableConstraint, h]
      
    end
    
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
