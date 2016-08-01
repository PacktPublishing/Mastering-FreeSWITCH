dofile("/usr/local/freeswitch/scripts/utils.lua")

function isready(session, line, logfile,call_uuid,this_call_caller_id)
  if (not (session:ready() ) ) then
    stamp("HANGUP: SESSION NOT READY at LINE: "..line.."\n",whichline(),logfile,call_uuid,this_call_caller_id)
    freeswitch.consoleLog("WARNING","The End (https://en.wikipedia.org/wiki/The_End_%28The_Doors_song%29)\n")
    stamp("***ENDED***",whichline(),logfile,call_uuid,this_call_caller_id)
    error()
  end
end

function isnil(variable, line, logfile,call_uuid,this_call_caller_id,session)
  if (variable == nil) then
    stamp("ERROR: VARIABLE IS NIL at LINE: "..line.."\n",whichline(),logfile,call_uuid,this_call_caller_id)
    session:speak("We are sorry, an internal error has occurred, this call will be terminated. Please pardon and call again.");
    freeswitch.consoleLog("WARNING","The End (https://en.wikipedia.org/wiki/The_End_%28The_Doors_song%29)\n")
    stamp("***ENDED***",whichline(),logfile,call_uuid,this_call_caller_id)
    error()
  end
end

function input_callback(session, type, obj, arg)
  freeswitch.consoleLog("WARNING", "CALLBACK: type: " .. type .. "\n");
  if (type == "dtmf") then
    freeswitch.consoleLog("WARNING", "CALLBACK: digit: [" .. obj['digit'] .. "]\nduration: [" .. obj['duration'] .. "]\n");
    if ( (obj['digit'] == "*") or (obj['digit'] == "#") ) then
      freeswitch.consoleLog("WARNING", "CALLBACK: got " .. obj['digit'] .. " let's break out of blocking operation\n");
      return "break"
    end
  end
end

function myHangupHook(session, status, arg)
  -- call was hanged up during call, before script ended or being transferred away from this script
  freeswitch.consoleLog("WARNING", "myHangupHook=" .. status .. " hangupCause="..session:hangupCause().."\n")
end

if(env) then
  -- we are in api_hangup_hook, after call ended

  local call_uuid = env:getHeader("call_uuid")
  local mduration = env:getHeader("mduration")
  local billmsec = env:getHeader("billmsec")
  local progressmsec = env:getHeader("progressmsec")
  local answermsec = env:getHeader("answermsec")
  local waitmsec = env:getHeader("waitmsec")
  local progress_mediamsec = env:getHeader("progress_mediamsec")
  local flow_billmsec = env:getHeader("flow_billmsec")
  local log_filename = env:getHeader("this_call_log_filename")
  local this_call_caller_id = env:getHeader("this_call_caller_id")

  freeswitch.consoleLog("WARNING", "ACCOUNTING in MILLISECONDS:\nmduration="..mduration.."\nbillmsec="..billmsec.."\nprogressmsec="..progressmsec.."\nanswermsec="..answermsec.."\nwaitmsec="..waitmsec.."\nprogress_mediamsec="..progress_mediamsec.."\nflow_billmsec="..flow_billmsec.."\n")
  local logfile = assert(io.open(log_filename, "a"))
  stamp("ACCOUNTING in MILLISECONDS:\nmduration="..mduration.."\nbillmsec="..billmsec.."\nprogressmsec="..progressmsec.."\nanswermsec="..answermsec.."\nwaitmsec="..waitmsec.."\nprogress_mediamsec="..progress_mediamsec.."\nflow_billmsec="..flow_billmsec.."\n", whichline(),logfile,call_uuid,this_call_caller_id)
  local dat = env:serialize()
  freeswitch.consoleLog("WARNING", "DUMP BEGINS\n"..dat.."\nDUMP ENDS\n") 
  stamp("DUMP BEGINS\n"..dat.."\nDUMP ENDS\n", whichline(),logfile,call_uuid,this_call_caller_id)
  goto END_HANGUP_HOOK
else
  -- we are in the call

  session:setInputCallback("input_callback", "ciao")

  local log_filename = "/tmp/welcome.log";
  local logfile = assert(io.open(log_filename, "a"))

  local call_uuid = session:getVariable("call_uuid")
  local sip_P_Asserted_Identity = session:getVariable("sip_P-Asserted-Identity");
  local caller_id = session:getVariable("effective_caller_id_number");

  local this_call_caller_id = nil

  if(not(sip_P_Asserted_Identity == nil)) then
    this_call_caller_id = sip_P_Asserted_Identity;
  else
    this_call_caller_id = caller_id
  end

  stamp("***BEGIN***",whichline(),logfile,call_uuid,this_call_caller_id)

  session:setHangupHook("myHangupHook")

  session:setVariable("this_call_log_filename", log_filename )
  session:setVariable("this_call_caller_id", this_call_caller_id )
  session:setVariable("api_hangup_hook", "lua welcome.lua" ) -- execute this file again, this time as api_hangup_hook, see before

  session:answer();

  stamp("ANSWERED",whichline(),logfile,call_uuid,this_call_caller_id)

  session:set_tts_params("flite", "rms");
  session:setVariable("tts_engine", "flite");
  session:setVariable("tts_voice", "rms");

  ::FIRST_MENU::
  stamp("FIRST_MENU",whichline(),logfile,call_uuid,this_call_caller_id)
  while (session:ready() == true) do
    local digits = session:playAndGetDigits(1, 1, 3, 3000, "#", "say:Welcome to the VoIp World! This is Blind Users Programming Community. Powered by Freeswitch, the free ultimate PBX. Thanks to Tony! Please select an action. To go to a nested menu, press 1. To call Freeswitch I V R, press 2. To hear classical music at very low volume, press 3. For originating an outgoing call to FreeSWITCH conference, and bridge the two legs, press 4. Press 5 to break out from while ready loop and exit the call. 6 will tell you the exact time from web. Press 7 to interrogate the internal filesystem database. For remote database, press 8. Press 9 for a back ground asynchronous web query.","say:You have not pressed a key between 1 and 9!","[1-9]", digits, 3000, "operator");
    if (digits == "1") then
      stamp("FIRST_MENU: 1",whichline(),logfile,call_uuid,this_call_caller_id)
      goto SECOND_MENU
    end
    if (digits == "2") then
      stamp("FIRST_MENU: 2",whichline(),logfile,call_uuid,this_call_caller_id)
      session:execute("transfer","5000");
    end
    if (digits == "3") then
      stamp("FIRST_MENU: 3",whichline(),logfile,call_uuid,this_call_caller_id)
      session:streamFile("/usr/local/freeswitch/sounds/music/8000/suite-espanola-op-47-leyenda.wav");
    end
    if (digits == "4") then
      stamp("FIRST_MENU: 4",whichline(),logfile,call_uuid,this_call_caller_id)
      session:execute("bridge","sofia/external/888@conference.freeswitch.org");
    end
    if (digits == "5") then
      stamp("FIRST_MENU: 5",whichline(),logfile,call_uuid,this_call_caller_id)
      break;
    end
    if (digits == "6") then
      stamp("FIRST_MENU: 6",whichline(),logfile,call_uuid,this_call_caller_id)
      local api = freeswitch.API();
      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      local utc_hours_right_now = api:execute("curl", "http://www.timeapi.org/utc/now?\\H");
      isnil(utc_hours_right_now, whichline(), logfile,call_uuid,this_call_caller_id,session)

      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      local utc_minutes_right_now = api:execute("curl", "http://www.timeapi.org/utc/now?\\M");
      isnil(utc_minutes_right_now, whichline(), logfile,call_uuid,this_call_caller_id,session)

      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      session:speak("U T C hour is " .. utc_hours_right_now .. ", while U T C minute is " .. utc_minutes_right_now .. ".");
    end
    if (digits == "7") then
      stamp("FIRST_MENU: 7",whichline(),logfile,call_uuid,this_call_caller_id)
      local dbh = freeswitch.Dbh("sqlite://core")
      if dbh:connected() == false then
        freeswitch.consoleLog("WARNING", "db.lua cannot connect to database\n")
        isnil(dbh:connected(), whichline(), logfile,call_uuid,this_call_caller_id,session)
      else
        freeswitch.consoleLog("WARNING", "db.lua correctly connect to database\n")
      end
      local description = nil
      dbh:query("select description from interfaces where type=\"api\" and name=\"bg_system\"", function(row)
          description = row.description
        end)
      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      isnil(description, whichline(), logfile,call_uuid,this_call_caller_id,session)
      freeswitch.consoleLog("WARNING",string.format("api bg_system description = %s", description))
      session:speak("API bg_system description is. " .. description .. ".");
    end
    if (digits == "8") then
      stamp("FIRST_MENU: 8",whichline(),logfile,call_uuid,this_call_caller_id)
      local dbh = freeswitch.Dbh("pgsql://hostaddr=192.168.1.108 dbname=test user=fusionpbx password='ciapalo'") -- FIXME XXX FIXME
      if dbh:connected() == false then
        freeswitch.consoleLog("WARNING", "db.lua cannot connect to database\n")
        isnil(dbh:connected(), whichline(), logfile,call_uuid,this_call_caller_id,session)
      else
        freeswitch.consoleLog("WARNING", "db.lua correctly connect to database\n")
      end
      local name = nil
      dbh:query("select name from test_table limit 1", function(row)
          name = row.name
        end)
      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      isnil(name, whichline(), logfile,call_uuid,this_call_caller_id,session)
      freeswitch.consoleLog("WARNING",string.format("name = %s", name))
      session:speak("name is. " .. name .. ".");
    end

    if (digits == "9") then
      stamp("FIRST_MENU: 9",whichline(),logfile,call_uuid,this_call_caller_id)
      local utc_hours_right_now = LuaRunWeb(session, log_filename, "http://www.timeapi.org/utc/now?\\H",0)
      isnil(utc_hours_right_now, whichline(), logfile,call_uuid,this_call_caller_id,session)
      local utc_minutes_right_now = LuaRunWeb(session, log_filename, "http://www.timeapi.org/utc/now?\\M",0)
      isnil(utc_minutes_right_now, whichline(), logfile,call_uuid,this_call_caller_id,session)
      isready(session, whichline(), logfile,call_uuid,this_call_caller_id)
      session:speak("U T C hour is " .. utc_hours_right_now .. ", while U T C minute is " .. utc_minutes_right_now .. ".");
    end
  end
  goto END

  ::SECOND_MENU::
  stamp("SECOND_MENU",whichline(),logfile,call_uuid,this_call_caller_id)
  while (session:ready() == true) do
    local digits = session:playAndGetDigits(1, 1, 3, 3000, "#", "say:This is the second menu. We are showing nested menus using dreaded gotos. Yes, you can use various nested loops instead, if you like. To call music on hold, press 1. To go to the first menu, press 2. To go to the third menu, press 3.","say:You have not pressed a key between 1 and 3!","[1-3]", digits, 3000, "operator");
    if (digits == "1") then
      stamp("SECOND_MENU: 1",whichline(),logfile,call_uuid,this_call_caller_id)
      session:execute("transfer","9664");
    end
    if (digits == "2") then
      stamp("SECOND_MENU: 2",whichline(),logfile,call_uuid,this_call_caller_id)
      goto FIRST_MENU
    end
    if (digits == "3") then
      stamp("SECOND_MENU: 3",whichline(),logfile,call_uuid,this_call_caller_id)
      goto THIRD_MENU
    end
  end
  goto END

  ::THIRD_MENU::
  stamp("THIRD_MENU",whichline(),logfile,call_uuid,this_call_caller_id)
  while (session:ready() == true) do
    local digits = session:playAndGetDigits(1, 1, 3, 3000, "#", "say:This is the third menu. Again, nested menus. To call Lenny, the telemarketers punisher, press 1. To go to the first menu, press 2. To go to the second menu, press 3.","say:You have not pressed a key between 1 and 3!","[1-3]", digits, 3000, "operator");
    if (digits == "1") then
      stamp("THIRD_MENU: 1",whichline(),logfile,call_uuid,this_call_caller_id)
      session:setVariable("effective_caller_id_name", "Giovanni Maruzzelli"); -- FIXME XXX
      session:setVariable("effective_caller_id_number", "14158781565"); -- FIXME XXX
      session:execute("bridge","{absolute_codec_string=pcmu,pcma}sofia/external/13475147296@in.callcentric.com");
    end
    if (digits == "2") then
      stamp("THIRD_MENU: 2",whichline(),logfile,call_uuid,this_call_caller_id)
      goto FIRST_MENU
    end
    if (digits == "3") then
      stamp("THIRD_MENU: 3",whichline(),logfile,call_uuid,this_call_caller_id)
      goto SECOND_MENU
    end
  end
  goto END

  ::END::
  freeswitch.consoleLog("WARNING","The End (https://en.wikipedia.org/wiki/The_End_%28The_Doors_song%29)\n")
  stamp("***ENDED***",whichline(),logfile,call_uuid,this_call_caller_id)
end

::END_HANGUP_HOOK::
--nothing here
