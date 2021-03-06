--
-- (C) 2013-17 - ntop.org
--

dirs = ntop.getDirs()
package.path = dirs.installdir .. "/scripts/lua/modules/?.lua;" .. package.path

if (ntop.isPro()) then
  package.path = dirs.installdir .. "/pro/scripts/callbacks/?.lua;" .. package.path
end

require "lua_utils"
require "graph_utils"
require "rrd_utils"
local callback_utils = require "callback_utils"

-- callback_utils.harverstOldRRDFiles("eno1")
-- tprint(interface.getMacInfo("68:5B:35:A7:DE:85"))
-- tprint(getPathFromMac("0C:C4:7A:CC:BD:40"))
-- dofile(dirs.installdir .. "/scripts/callbacks/5min.lua")
-- dofile(dirs.installdir .. "/scripts/callbacks/daily.lua")

-- Toggle debug
local enable_second_debug = false

if((_GET ~= nil) and (_GET["verbose"] ~= nil)) then
   enable_second_debug = true
end

if(enable_second_debug) then
   sendHTTPHeader('text/plain')
end

local ifnames = interface.getIfNames()
local when = os.time()

callback_utils.foreachInterface(ifnames, interface_rrd_creation_enabled, function(ifname, ifstats)
   if(enable_second_debug) then print("Processing "..ifname.."\n") end
   -- tprint(ifstats)
   basedir = fixPath(dirs.workingdir .. "/" .. ifstats.id .. "/rrd")
   
   --io.write(basedir.."\n")
   if(not(ntop.exists(basedir))) then
      if(enable_second_debug) then io.write('Creating base directory ', basedir, '\n') end
      ntop.mkdir(basedir)
   end
   
   -- Traffic stats
   makeRRD(basedir, when, ifstats.id, "iface", "bytes", 1, ifstats.stats.bytes)
   makeRRD(basedir, when, ifstats.id, "iface", "packets", 1, ifstats.stats.packets)
   
   -- ZMQ stats
   if ifstats.zmqRecvStats ~= nil then
      makeRRD(basedir, when, ifstats.id, "iface", "num_zmq_received_flows",
	      1, tolongint(ifstats.zmqRecvStats.flows))     
   else
      -- Packet interface
      makeRRD(basedir, when, ifstats.id, "iface", "drops", 1, ifstats.stats.drops)
   end
end)
