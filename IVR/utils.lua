function shell(c)
  local o, h
  h = assert(io.popen(c,"r"))
  o = h:read("*all")
  h:close()
  return o
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function LuaRunWeb(session, logfilename, query, nochecksession)
  local api = freeswitch.API();
  api:execute("luarun", "LuaRunWeb.lua "..logfilename.." "..session:getVariable("call_uuid").." "..session:getVariable("this_call_caller_id").." "..fs_urlencode(query));
  session:setVariable("from_luarun_end_query", "0")
  local from_luarun_end_query = session:getVariable("from_luarun_end_query")
  local return_value = "CURL ERROR NO_SESSION"
  while(from_luarun_end_query == "0") do
    if(nochecksession==0) then
      if (not (session:ready() ) ) then
        goto goodbye;
      end
    end
    api:execute("msleep", 300) -- pause a third of a second
    from_luarun_end_query = session:getVariable("from_luarun_end_query")
  end
  return_value = session:getVariable("curl_response_data")
  ::goodbye::
  return return_value
end

function whichline()
  return debug.getinfo(2, 'l').currentline
end

function fs_urlencode(s)
  local fsapi = freeswitch.API();
  return fsapi:execute("url_encode", s)
end

function fs_urldecode(s)
  local fsapi = freeswitch.API();
  return fsapi:execute("url_decode", s)
end

function stamp(string,whichline,logfilename, uuid, callerid)
  local logfile=logfilename
  local local_date = shell("date");
  logfile:write(local_date);
  logfile:write("call_uuid="..uuid.."\n");
  logfile:write("caller_id="..callerid.."\n");
  logfile:write("line="..whichline.."\n");
  logfile:write("\n\n");
  logfile:write(trim(string).."\n\n");
  logfile:write("=========\n\n");
  logfile:flush();
end

