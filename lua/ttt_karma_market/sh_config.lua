TTTKarmaMarket = TTTKarmaMarket or {}
local addon = TTTKarmaMarket

local function C(r, g, b, a)
  if Color then
    return Color(r, g, b, a or 255)
  end

  return { r = r, g = g, b = b, a = a or 255 }
end

addon.ConVarDefaults = addon.ConVarDefaults or {
  enabled = { name = "ttt_karma_market_enabled", default = "1", kind = "bool", help = "Enable TTT Karma Market round tracking and display." },
  debug = { name = "ttt_karma_market_debug", default = "0", kind = "bool", help = "Print TTT Karma Market debug messages." },
  sample_interval = { name = "ttt_karma_market_sample_interval", default = "10", kind = "number", min = 1, max = 120, help = "Seconds between karma samples." },
  popup_fallback = { name = "ttt_karma_market_popup_fallback", default = "1", kind = "bool", help = "Open a popup when the TTT end-round tab cannot be extended." },
  max_candles = { name = "ttt_karma_market_max_candles", default = "60", kind = "number", min = 1, max = 240, help = "Maximum candles stored for each player." },
  chart_height = { name = "ttt_karma_market_chart_height", default = "420", kind = "number", min = 220, max = 900, help = "Preferred chart height in the fallback window." },
  show_grid = { name = "ttt_karma_market_show_grid", default = "1", kind = "bool", help = "Show chart grid lines." },
  show_labels = { name = "ttt_karma_market_show_labels", default = "1", kind = "bool", help = "Show chart axis labels." },
  auto_sort = { name = "ttt_karma_market_auto_sort", default = "1", kind = "bool", help = "Sort players automatically when the chart opens." },
  default_sort = { name = "ttt_karma_market_default_sort", default = "alpha", kind = "string", help = "Default player sorting mode." }
}

addon.Config = addon.Config or {
  NetMessage = "TTTKarmaMarket_Send",
  AdminRequestMessage = "TTTKarmaMarket_AdminRequest",
  AdminStatusMessage = "TTTKarmaMarket_AdminStatus",

  Colors = {
    Background = C(18, 20, 24),
    Panel = C(28, 32, 38),
    Grid = C(58, 64, 74),
    Axis = C(118, 126, 138),
    Text = C(232, 236, 241),
    MutedText = C(158, 166, 178),
    Gain = C(70, 190, 116),
    Loss = C(225, 82, 82),
    Flat = C(150, 154, 162),
    Wick = C(218, 224, 232),
    Selected = C(46, 92, 132)
  }
}

if SERVER then
  local flags = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY)

  for _, data in pairs(addon.ConVarDefaults) do
    if not GetConVar(data.name) then
      CreateConVar(data.name, data.default, flags, data.help)
    end
  end
end

function addon.GetConVarData(key)
  return addon.ConVarDefaults and addon.ConVarDefaults[key] or nil
end

function addon.GetConVarValue(key)
  local data = addon.GetConVarData(key)
  if not data then return nil end

  local convar = GetConVar(data.name)
  if not convar then return data.default end

  return convar:GetString()
end

function addon.GetBool(key)
  local data = addon.GetConVarData(key)
  local convar = data and GetConVar(data.name)

  if convar then return convar:GetBool() end

  return data and data.default == "1" or false
end

function addon.GetNumber(key)
  local data = addon.GetConVarData(key)
  local convar = data and GetConVar(data.name)
  local value = convar and convar:GetFloat() or tonumber(data and data.default) or 0

  if data and data.min then value = math.max(data.min, value) end
  if data and data.max then value = math.min(data.max, value) end

  return value
end

function addon.GetString(key)
  local value = addon.GetConVarValue(key)

  return tostring(value or "")
end
