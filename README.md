# Using Ruby-MacroDroid and ProjectSimulator together

    require 'projectsimulator'
    require 'ruby-macrodroid'

    s ="
    m: popup test
    t: at 7:30am on Mon, Tue, Wed
    a: message popup: hello world
    "

    md = MacroDroid.new(s)
    ps = ProjectSimulator::Controller.new(md)

    $env = {}
    $env[:time] = Time.parse '7:29am'
    ps.trigger :timer
    #=> []

    $env[:time] = Time.parse '7:30am'
    ps.trigger :timer
    #=> ["notifications/toast: hello world"]

The above example demonstrates using the Ruby-MacroDroid gem with the ProjectSimulator gem to simulate the trigger of a macro at a specific time. The "notifications/toast" topic refers to the style of notification. In this case a popup toaster message is intended to be displayed.

macrodroid simulator projectsimulator macro simulate test

---------------------------------

# Ruby-macrodroid: Creating a macro from plain text

    require 'ruby-macrodroid'

    s ="
    m: popup test
    t: at 7:30am on Mon, Tue
    a: message popup: hello world
    "

    File.write '/home/james/m24.mdr', MacroDroid.new(s).to_json

In the above example, a macro called 'popup test' is created which triggers at 7:30am, every Monday and Tuesday, and displays the popup message 'hello world'.

macrodroid macro popup

--------------------------

# Ruby-Macrodroid: Configuring a Macro using the TimerTrigger and ToastAction

    require 'ruby-macrodroid'

    droid = MacroDroid.new

    # Create a new macro
    macro = Macro.new

    # Configure the timer to trigger at 7:30am on a Monday and Tuesday
    h = {
      days_of_week: [true, true, false, false, false, false, false], 
      hour: 7,  
      minute: 30
    }

    # Create the Day/Time Trigger
    trigger = TimerTrigger.new h
    macro.add trigger

    # Create the Popup Message
    action = ToastAction.new message_text: 'hello world!'
    macro.add action

    droid.add macro

    # Save the macro
    File.write '/home/james/m2020.mdr', droid.to_json

The above snippets creates a Macrodroid macro including a Day/Time trigger which runs at 7:30 on Monday and Tuesday, and a Popup message action which display the message 'hello world!'.

macrodroid macro android

--------------------------

# Browsing the MacroDroid macros using the ruby-macrodroid gem


    require 'ruby-macrodroid'

    droid = MacroDroid.new '/home/james/mymacros.mdr', debug: true
    droid.macros
    droid.macros.first.triggers.first
    droid.macros.first.triggers.first.to_h
    puts droid.to_h.pretty_inspect

Sample output

<pre>
{"cellTowerGroups"=>[],
 "cellTowersIgnore"=>[],
 "drawerConfiguration"=>
  {"drawerItems"=>[],
   "backgroundColor"=>-1,
   "headerColor"=>-12692882,
   "leftSide"=>false,
   "swipeAreaColor"=>-7829368,
   "swipeAreaHeight"=>20,
   "swipeAreaOffset"=>40,
   "swipeAreaOpacity"=>80,
   "swipeAreaWidth"=>14,
   "visibleSwipeAreaWidth"=>0},
 "variables"=>[],
 "userIcons"=>[],
 "macroList"=>
  [{"localVariables"=>
     [{"m_stringValue"=>"55.9292432,-3.127153",
       "m_name"=>"gps123",
       "m_decimalValue"=>0.0,
       "isLocal"=>true,
       "m_booleanValue"=>false,
       "excludeFromLog"=>false,
       "m_intValue"=>0,
       "m_type"=>2}],
    "m_actionList"=>
     [{"m_constraintList"=>[],
       "m_isOrCondition"=>false,
       "m_isDisabled"=>false,
       "m_simId"=>0,
       "m_outputChannel"=>5,
       "m_oldVariableFormat"=>true,
       "m_email"=>"",
       "m_variable"=>
        {"m_stringValue"=>"55.9292432,-3.127153",
         "m_name"=>"gps123",
         "m_decimalValue"=>0.0,
         "isLocal"=>true,
         "m_booleanValue"=>false,
         "excludeFromLog"=>false,
         "m_intValue"=>0,
         "m_type"=>2},
       "m_classType"=>"ShareLocationAction",
       "m_SIGUID"=>-5922099493900720560},
      {"m_constraintList"=>[],
       "m_isOrCondition"=>false,
       "m_isDisabled"=>false,
       "m_destination"=>"192.168.4.196",
       "m_message"=>"locateme/[lv=gps123]",
       "m_port"=>1024,
       "m_classType"=>"UDPCommandAction",
       "m_SIGUID"=>-8039007008301146494}],
    "m_category"=>"Uncategorized",
    "m_triggerList"=>
     [{"m_constraintList"=>[],
       "m_isOrCondition"=>false,
       "m_isDisabled"=>false,
       "fakeIcon"=>2131230995,
       "identifier"=>"incoming123",
       "m_classType"=>"WebHookTrigger",
       "m_SIGUID"=>-8047094238669100337}],
    "m_constraintList"=>[],
    "m_description"=>"",
    "m_name"=>"locateme",
    "m_excludeLog"=>false,
    "m_GUID"=>-4795648784590462863,
    "m_isOrCondition"=>false,
    "m_enabled"=>true,
    "m_descriptionOpen"=>true,
    "m_headingColor"=>0},
   {"localVariables"=>[],
    "m_actionList"=>
     [{"m_constraintList"=>[],
       "m_isOrCondition"=>false,
       "m_isDisabled"=>false,
       "m_destination"=>"192.168.4.196",
       "m_message"=>"batterystatus: [battery]",
       "m_port"=>1024,
       "m_classType"=>"UDPCommandAction",
       "m_SIGUID"=>-7385497187551422543}],
    "m_category"=>"Uncategorized",
    "m_triggerList"=>
     [{"m_constraintList"=>[],
       "m_isOrCondition"=>false,
       "m_isDisabled"=>false,
       "fakeIcon"=>2131230995,
       "m_ssidList"=>["MyWIFI8046"],
       "m_wifiState"=>2,
       "m_classType"=>"WifiConnectionTrigger",
       "m_SIGUID"=>-5203256210821000491}],
    "m_constraintList"=>[],
    "m_description"=>"",
    "m_name"=>"test123",
    "m_excludeLog"=>false,
    "m_GUID"=>-5658339251678407814,
    "m_isOrCondition"=>false,
    "m_enabled"=>true,
    "m_descriptionOpen"=>false,
    "m_headingColor"=>0}],
 "notificationButtonBarConfig"=>"",
 "stopWatches"=>[],
 "notificationButtonLatestId"=>0,
 "exportFormat"=>2,
 "exportAppVersion"=>9089}

</pre>  

## Resources

* ruby-macrodroid https://rubygems.org/gems/ruby-macrodroid

macrodroid gem macro droid android json
