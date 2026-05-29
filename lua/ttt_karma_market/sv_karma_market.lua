TTTKarmaMarket = TTTKarmaMarket or {}

local addon = TTTKarmaMarket
local config = addon.Config
local timerName = "TTTKarmaMarket_Sample"
local lastSampleAt = 0
local lastNetworkAt = 0
local lastNetworkCount = 0

util.AddNetworkString(config.NetMessage)

local roundActive = false
local roundStartedAt = 0
local records = {}

local function clampCount(value, bits)
  return math.Clamp(value or 0, 0, math.pow(2, bits) - 1)
end

local function getRoundTime()
  if roundStartedAt <= 0 then return 0 end

  return math.max(0, math.floor(CurTime() - roundStartedAt))
end

local function ensureRecord(ply)
  local steamID = addon.GetPlayerSteamID(ply)
  local karma = addon.GetPlayerKarma(ply)

  records[steamID] = records[steamID] or {
    name = addon.SafePlayerName(ply),
    steamID = steamID,
    starting = karma,
    ending = karma,
    high = karma,
    low = karma,
    biggestGain = 0,
    biggestLoss = 0,
    candles = {}
  }

  records[steamID].name = addon.SafePlayerName(ply)

  return records[steamID]
end

local function updateSummary(record, candle)
  record.ending = candle.close
  record.high = math.max(record.high, candle.high)
  record.low = math.min(record.low, candle.low)
  record.biggestGain = math.max(record.biggestGain, candle.close - candle.open)
  record.biggestLoss = math.min(record.biggestLoss, candle.close - candle.open)
end

local function appendCandle(record, karma)
  local candles = record.candles
  local t = getRoundTime()
  local previous = candles[#candles]
  local open = previous and previous.close or record.starting

  local candle = {
    t = t,
    open = open,
    high = math.max(open, karma),
    low = math.min(open, karma),
    close = karma
  }

  candles[#candles + 1] = candle

  while #candles > addon.GetNumber("max_candles") do
    table.remove(candles, 1)
  end

  updateSummary(record, candle)
end

local function sampleRound()
  if not roundActive or not addon.GetBool("enabled") then return end

  lastSampleAt = CurTime()

  for _, ply in ipairs(player.GetHumans()) do
    local record = ensureRecord(ply)
    appendCandle(record, addon.GetPlayerKarma(ply))
  end
end

local function writePlayerRecord(record)
  local candles = record.candles or {}

  net.WriteString(record.name or "")
  net.WriteString(record.steamID or "")
  net.WriteInt(addon.RoundNumber(record.starting), 16)
  net.WriteInt(addon.RoundNumber(record.ending), 16)
  net.WriteInt(addon.RoundNumber(record.high), 16)
  net.WriteInt(addon.RoundNumber(record.low), 16)
  net.WriteInt(addon.RoundNumber(record.biggestGain), 16)
  net.WriteInt(addon.RoundNumber(record.biggestLoss), 16)
  net.WriteUInt(clampCount(#candles, 16), 16)

  for _, candle in ipairs(candles) do
    net.WriteUInt(clampCount(candle.t, 16), 16)
    net.WriteInt(addon.RoundNumber(candle.open), 16)
    net.WriteInt(addon.RoundNumber(candle.high), 16)
    net.WriteInt(addon.RoundNumber(candle.low), 16)
    net.WriteInt(addon.RoundNumber(candle.close), 16)
  end
end

local function sendRoundData()
  local payload = {}

  for _, record in pairs(records) do
    payload[#payload + 1] = record
  end

  table.sort(payload, function(a, b)
    return string.lower(a.name or "") < string.lower(b.name or "")
  end)

  local sentCount = math.min(#payload, 255)

  net.Start(config.NetMessage)
  net.WriteUInt(sentCount, 8)

  for i = 1, sentCount do
    writePlayerRecord(payload[i])
  end

  net.Broadcast()
  lastNetworkAt = CurTime()
  lastNetworkCount = sentCount
  addon.Log("sent end-round karma market data for", sentCount, "players")
end

local function stopSampling()
  timer.Remove(timerName)
  roundActive = false
end

hook.Add("TTTPrepareRound", "TTTKarmaMarket_PrepareRound", function()
  stopSampling()

  if not addon.GetBool("enabled") then
    addon.Log("round ignored because addon is disabled")
    return
  end

  records = {}
  roundActive = true
  roundStartedAt = CurTime()
  lastSampleAt = 0

  addon.Log("round started", addon.GetTTTVariantName())

  for _, ply in ipairs(player.GetHumans()) do
    ensureRecord(ply)
  end

  timer.Create(timerName, math.max(1, addon.GetNumber("sample_interval")), 0, sampleRound)
end)

hook.Add("PlayerDisconnected", "TTTKarmaMarket_PlayerDisconnected", function(ply)
  if not roundActive then return end

  local record = ensureRecord(ply)
  appendCandle(record, addon.GetPlayerKarma(ply))
  addon.Log("captured disconnecting player", record.name)
end)

hook.Add("TTTEndRound", "TTTKarmaMarket_EndRound", function()
  if not roundActive then return end

  addon.Log("round ended")
  sampleRound()
  stopSampling()

  if addon.GetBool("enabled") then
    sendRoundData()
  end
end)

hook.Add("ShutDown", "TTTKarmaMarket_Shutdown", stopSampling)

cvars.AddChangeCallback("ttt_karma_market_sample_interval", function()
  if not roundActive then return end

  timer.Create(timerName, math.max(1, addon.GetNumber("sample_interval")), 0, sampleRound)
  addon.Log("sample interval updated to", addon.GetNumber("sample_interval"))
end, "TTTKarmaMarket_SampleInterval")

function addon.ClearRoundData()
  records = {}
  lastSampleAt = 0
  lastNetworkAt = 0
  lastNetworkCount = 0
  addon.Log("round data cleared")
end

function addon.GetDebugSummary()
  local playerCount = 0
  local candleCounts = {}

  for _, record in pairs(records) do
    playerCount = playerCount + 1
    candleCounts[#candleCounts + 1] = {
      name = record.name or "Unknown Player",
      candles = #(record.candles or {})
    }
  end

  table.sort(candleCounts, function(a, b)
    return string.lower(a.name) < string.lower(b.name)
  end)

  return {
    enabled = addon.GetBool("enabled"),
    debug = addon.GetBool("debug"),
    variant = addon.GetTTTVariantName(),
    roundActive = roundActive,
    playersTracked = playerCount,
    candleCounts = candleCounts,
    timerExists = timer.Exists(timerName),
    sampleInterval = addon.GetNumber("sample_interval"),
    maxCandles = addon.GetNumber("max_candles"),
    lastSampleAgo = lastSampleAt > 0 and math.Round(CurTime() - lastSampleAt, 1) or -1,
    lastNetworkAgo = lastNetworkAt > 0 and math.Round(CurTime() - lastNetworkAt, 1) or -1,
    lastNetworkCount = lastNetworkCount
  }
end
