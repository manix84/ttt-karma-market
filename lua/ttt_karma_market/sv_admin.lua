TTTKarmaMarket = TTTKarmaMarket or {}

local addon = TTTKarmaMarket
local requestMessage = addon.Config.AdminRequestMessage
local statusMessage = addon.Config.AdminStatusMessage

util.AddNetworkString(requestMessage)
util.AddNetworkString(statusMessage)

local allowedSorts = {
  alpha = true,
  gain = true,
  loss = true,
  volatile = true
}

local function isAdmin(ply)
  if not IsValid(ply) then return true end

  return ply:IsAdmin() or ply:IsSuperAdmin()
end

local function normaliseValue(key, raw)
  local data = addon.GetConVarData(key)
  if not data then return nil end

  if data.kind == "bool" then
    return tostring(raw) == "1" and "1" or "0"
  end

  if data.kind == "number" then
    local value = tonumber(raw) or tonumber(data.default) or 0
    if data.min then value = math.max(data.min, value) end
    if data.max then value = math.min(data.max, value) end

    return tostring(math.Round(value))
  end

  if key == "default_sort" then
    local value = tostring(raw or data.default)
    return allowedSorts[value] and value or data.default
  end

  return tostring(raw or data.default)
end

local function setConVar(key, raw)
  local data = addon.GetConVarData(key)
  local value = normaliseValue(key, raw)

  if not data or value == nil then return false end

  RunConsoleCommand(data.name, value)
  return true
end

local function sendStatus(ply)
  local summary = addon.GetDebugSummary and addon.GetDebugSummary() or {}
  local json = util.TableToJSON(summary, false) or "{}"

  net.Start(statusMessage)
  net.WriteString(json)

  if IsValid(ply) then
    net.Send(ply)
  end
end

local function resetConVars()
  for key, data in pairs(addon.ConVarDefaults or {}) do
    setConVar(key, data.default)
  end
end

local function printSummary(ply)
  local summary = addon.GetDebugSummary and addon.GetDebugSummary() or {}

  print("[TTT Karma Market] Debug summary requested by " .. (IsValid(ply) and ply:Nick() or "server"))
  PrintTable(summary)
end

net.Receive(requestMessage, function(_, ply)
  local action = net.ReadString()

  if action == "status" then
    sendStatus(ply)
    return
  end

  if not isAdmin(ply) then
    addon.Log("blocked non-admin settings request from", IsValid(ply) and ply:Nick() or "unknown")
    sendStatus(ply)
    return
  end

  if action == "set" then
    setConVar(net.ReadString(), net.ReadString())
  elseif action == "reset" then
    resetConVars()
  elseif action == "clear" then
    if addon.ClearRoundData then addon.ClearRoundData() end
  elseif action == "summary" then
    printSummary(ply)
  end

  sendStatus(ply)
end)
