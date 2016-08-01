dofile("/usr/local/freeswitch/scripts/utils.lua")

------------------------------------
local orig_logfile = argv[1]
local call_uuid = argv[2]
local this_call_caller_id = argv[3]
local query = fs_urldecode(argv[4])
------------------------------------

------------------------------------
local my_logfile = orig_logfile .. "_query"
local logfile = assert(io.open(my_logfile, "a"));
------------------------------------

------------------------------------
local api = freeswitch.API();
------------------------------------

------------------------------------
stamp("***BEGIN***",whichline(),logfile,call_uuid,this_call_caller_id)
------------------------------------

stamp("query="..query,whichline(),logfile,call_uuid,this_call_caller_id)

local curl_response = api:execute("curl", query)
local session = freeswitch.Session(call_uuid);
session:setVariable("curl_response_data", curl_response)
session:setVariable("from_luarun_end_query", "1")

stamp("curl_response="..curl_response,whichline(),logfile,call_uuid,this_call_caller_id)

------------------------------------
::goodbye::
------------------------------------
stamp("***ENDED***",whichline(),logfile,call_uuid,this_call_caller_id)
logfile:flush();
logfile:close();
------------------------------------

