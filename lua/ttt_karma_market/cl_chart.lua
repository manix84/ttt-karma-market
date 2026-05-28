TTTKarmaMarket = TTTKarmaMarket or {}
TTTKarmaMarket.Chart = TTTKarmaMarket.Chart or {}

local addon = TTTKarmaMarket

local PANEL = {}

function PANEL:Init()
  self.Candles = {}
  self:SetMouseInputEnabled(false)
end

function PANEL:SetCandles(candles)
  self.Candles = istable(candles) and candles or {}
  self:InvalidateLayout(true)
end

local function candleColour(candle)
  local colors = addon.Config.Colors

  if candle.close > candle.open then return colors.Gain end
  if candle.close < candle.open then return colors.Loss end

  return colors.Flat
end

local function valueRange(candles)
  local minValue
  local maxValue

  for _, candle in ipairs(candles) do
    minValue = minValue and math.min(minValue, candle.low) or candle.low
    maxValue = maxValue and math.max(maxValue, candle.high) or candle.high
  end

  minValue = minValue or 0
  maxValue = maxValue or 1

  if minValue == maxValue then
    minValue = minValue - 5
    maxValue = maxValue + 5
  else
    local padding = math.max(2, (maxValue - minValue) * 0.08)
    minValue = minValue - padding
    maxValue = maxValue + padding
  end

  return minValue, maxValue
end

function PANEL:Paint(w, h)
  local colors = addon.Config.Colors
  local candles = self.Candles or {}
  local left = 52
  local right = 16
  local top = 18
  local bottom = 32
  local chartW = math.max(1, w - left - right)
  local chartH = math.max(1, h - top - bottom)

  surface.SetDrawColor(colors.Background)
  surface.DrawRect(0, 0, w, h)

  if addon.GetBool("show_grid") then
    surface.SetDrawColor(colors.Grid)
    for i = 0, 4 do
      local y = top + (chartH * i / 4)
      surface.DrawLine(left, y, w - right, y)
    end
  end

  surface.SetDrawColor(colors.Axis)
  surface.DrawLine(left, top, left, top + chartH)
  surface.DrawLine(left, top + chartH, w - right, top + chartH)

  if #candles == 0 then
    draw.SimpleText("No karma data", "DermaDefault", w * 0.5, h * 0.5, colors.MutedText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return
  end

  local minValue, maxValue = valueRange(candles)
  local range = maxValue - minValue

  local function yFor(value)
    return top + chartH - ((value - minValue) / range) * chartH
  end

  if addon.GetBool("show_labels") then
    for i = 0, 4 do
      local value = maxValue - (range * i / 4)
      local y = top + (chartH * i / 4)
      draw.SimpleText(tostring(math.Round(value)), "DermaDefault", left - 8, y, colors.MutedText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end
  end

  local slot = chartW / math.max(#candles, 1)
  local bodyW = math.Clamp(slot * 0.54, 3, 18)

  for index, candle in ipairs(candles) do
    local x = left + slot * (index - 0.5)
    local highY = yFor(candle.high)
    local lowY = yFor(candle.low)
    local openY = yFor(candle.open)
    local closeY = yFor(candle.close)
    local bodyTop = math.min(openY, closeY)
    local bodyH = math.max(2, math.abs(closeY - openY))
    local color = candleColour(candle)

    surface.SetDrawColor(colors.Wick)
    surface.DrawLine(x, highY, x, lowY)

    surface.SetDrawColor(color)
    surface.DrawRect(math.floor(x - bodyW * 0.5), math.floor(bodyTop), math.ceil(bodyW), math.ceil(bodyH))
  end

  local first = candles[1]
  local last = candles[#candles]

  if first and last and addon.GetBool("show_labels") then
    draw.SimpleText(tostring(first.t or 0) .. "s", "DermaDefault", left, h - 18, colors.MutedText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(tostring(last.t or 0) .. "s", "DermaDefault", w - right, h - 18, colors.MutedText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
  end
end

vgui.Register("TTTKarmaMarketChart", PANEL, "DPanel")

function addon.Chart.Create(parent)
  return vgui.Create("TTTKarmaMarketChart", parent)
end
