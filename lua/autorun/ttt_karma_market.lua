TTTKarmaMarket = TTTKarmaMarket or {}

AddCSLuaFile("ttt_karma_market/sh_config.lua")
AddCSLuaFile("ttt_karma_market/sh_types.lua")

include("ttt_karma_market/sh_config.lua")
include("ttt_karma_market/sh_types.lua")

if SERVER then
  AddCSLuaFile("ttt_karma_market/cl_chart.lua")
  AddCSLuaFile("ttt_karma_market/cl_ui.lua")
  AddCSLuaFile("ttt_karma_market/cl_admin.lua")
  AddCSLuaFile("ttt_karma_market/cl_karma_market.lua")

  include("ttt_karma_market/sv_karma_market.lua")
  include("ttt_karma_market/sv_admin.lua")
else
  include("ttt_karma_market/cl_chart.lua")
  include("ttt_karma_market/cl_ui.lua")
  include("ttt_karma_market/cl_admin.lua")
  include("ttt_karma_market/cl_karma_market.lua")
end
