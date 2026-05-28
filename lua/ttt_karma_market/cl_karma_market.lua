TTTKarmaMarket = TTTKarmaMarket or {}

local addon = TTTKarmaMarket
local latestData = {}

local function readPlayerRecord()
  local record = {
    name = net.ReadString(),
    steamID = net.ReadString(),
    starting = net.ReadInt(16),
    ending = net.ReadInt(16),
    high = net.ReadInt(16),
    low = net.ReadInt(16),
    biggestGain = net.ReadInt(16),
    biggestLoss = net.ReadInt(16),
    candles = {}
  }

  local candleCount = net.ReadUInt(16)

  for i = 1, candleCount do
    record.candles[i] = {
      t = net.ReadUInt(16),
      open = net.ReadInt(16),
      high = net.ReadInt(16),
      low = net.ReadInt(16),
      close = net.ReadInt(16)
    }
  end

  return record
end

local function presentData(data)
  timer.Simple(0.25, function()
    if addon.UI.TryInjectEndRoundTab(data) then return end

    timer.Simple(1, function()
      if addon.UI.TryInjectEndRoundTab(data) then return end
      addon.UI.OpenFallbackPopup(data)
    end)
  end)
end

net.Receive(addon.Config.NetMessage, function()
  if not addon.GetBool("enabled") then return end

  local count = net.ReadUInt(8)
  local data = {}

  for i = 1, count do
    data[i] = readPlayerRecord()
  end

  latestData = data
  addon.Log("received end-round data for", #data, "players")
  presentData(latestData)
end)

hook.Add("TTTEndRound", "TTTKarmaMarket_ClientEndRound", function()
  if not addon.GetBool("enabled") then return end
  if not latestData or #latestData == 0 then return end

  presentData(latestData)
end)
