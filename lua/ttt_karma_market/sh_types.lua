TTTKarmaMarket = TTTKarmaMarket or {}

local addon = TTTKarmaMarket

function addon.Log(...)
  if not addon.GetBool or not addon.GetBool("debug") then return end

  print("[TTT Karma Market]", ...)
end

function addon.IsTTT2()
  -- TTT2 exposes its own globals in most builds. KARMA.DoKarmaChange is a
  -- documented TTT2 karma helper, so it is a useful fallback signal.
  if istable(TTT2) then return true end
  if istable(KARMA) and isfunction(KARMA.DoKarmaChange) then return true end

  return false
end

function addon.GetTTTVariantName()
  if addon.IsTTT2() then return "TTT2" end

  return "Classic TTT"
end

function addon.RoundNumber(value)
  local number = tonumber(value) or 0

  if number >= 0 then
    return math.floor(number + 0.5)
  end

  return math.ceil(number - 0.5)
end

function addon.GetPlayerKarma(ply)
  if not IsValid(ply) then return 0 end

  local ok, value

  if isfunction(ply.GetBaseKarma) then
    ok, value = pcall(ply.GetBaseKarma, ply)
    if ok and value ~= nil then
      return addon.RoundNumber(value)
    end
  end

  if isfunction(ply.GetLiveKarma) then
    ok, value = pcall(ply.GetLiveKarma, ply)
    if ok and value ~= nil then
      return addon.RoundNumber(value)
    end
  end

  if isfunction(ply.GetNWFloat) then
    ok, value = pcall(ply.GetNWFloat, ply, "karma", 0)
    if ok and value ~= nil then
      return addon.RoundNumber(value)
    end
  end

  if isfunction(ply.GetNWInt) then
    ok, value = pcall(ply.GetNWInt, ply, "karma", 0)
    if ok and value ~= nil then
      return addon.RoundNumber(value)
    end
  end

  return 0
end

function addon.GetPlayerSteamID(ply)
  if not IsValid(ply) then return "UNKNOWN" end

  if isfunction(ply.SteamID64) then
    local id64 = ply:SteamID64()
    if id64 and id64 ~= "" then return id64 end
  end

  if isfunction(ply.SteamID) then
    local id = ply:SteamID()
    if id and id ~= "" then return id end
  end

  return "BOT:" .. tostring(ply:EntIndex())
end

function addon.SafePlayerName(ply)
  if not IsValid(ply) then return "Disconnected Player" end

  if isfunction(ply.Nick) then
    local ok, name = pcall(ply.Nick, ply)
    if ok and name and name ~= "" then return name end
  end

  return "Unknown Player"
end
