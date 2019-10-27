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
