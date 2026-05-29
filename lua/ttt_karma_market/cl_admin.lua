TTTKarmaMarket = TTTKarmaMarket or {}
TTTKarmaMarket.Admin = TTTKarmaMarket.Admin or {}

local addon = TTTKarmaMarket
local admin = addon.Admin
local requestMessage = addon.Config.AdminRequestMessage
local statusMessage = addon.Config.AdminStatusMessage

admin.Status = admin.Status or {}
admin.StatusLabel = admin.StatusLabel or nil

local sortLabels = {
  { "Alphabetical", "alpha" },
  { "Biggest Gain", "gain" },
  { "Biggest Loss", "loss" },
  { "Most Volatile", "volatile" }
}

local function sendAction(action)
  net.Start(requestMessage)
  net.WriteString(action)
  net.SendToServer()
end

local function sendSet(key, value)
  net.Start(requestMessage)
  net.WriteString("set")
  net.WriteString(key)
  net.WriteString(tostring(value))
  net.SendToServer()
end

local function addCheck(panel, key, label, tooltip)
  local row = vgui.Create("DCheckBoxLabel")
  row:SetText(label)
  row:SetValue(addon.GetBool(key) and 1 or 0)
  row:SetDark(true)
  row:SetTooltip(tooltip)
  row:DockMargin(0, 4, 0, 4)

  row.OnChange = function(_, checked)
    sendSet(key, checked and "1" or "0")
  end

  panel:AddItem(row)

  return row
end

local function addSlider(panel, key, label, minValue, maxValue, decimals, tooltip)
  local slider = vgui.Create("DNumSlider")
  slider:SetText(label)
  slider:SetMin(minValue)
  slider:SetMax(maxValue)
  slider:SetDecimals(decimals or 0)
  slider:SetValue(addon.GetNumber(key))
  slider:SetTooltip(tooltip)
  slider:DockMargin(0, 4, 0, 4)

  slider.OnValueChanged = function(_, value)
    sendSet(key, tostring(math.Round(value)))
  end

  panel:AddItem(slider)

  return slider
end

local function addSortDropdown(panel)
  local label = vgui.Create("DLabel")
  label:SetText("Default sorting mode")
  label:SetDark(true)
  panel:AddItem(label)

  local combo = vgui.Create("DComboBox")
  combo:SetTooltip("Initial sorting mode used when the Karma Market panel opens.")

  local selected = addon.GetString("default_sort")
  for _, item in ipairs(sortLabels) do
    combo:AddChoice(item[1], item[2], item[2] == selected)
  end

  combo.OnSelect = function(_, _, _, value)
    sendSet("default_sort", value)
  end

  panel:AddItem(combo)
end

local function formatStatus()
  if not addon.GetBool("debug") then
    return "Enable debug logging to show live round tracking details."
  end

  local status = admin.Status or {}
  local lines = {
    "Active players tracked: " .. tostring(status.playersTracked or 0),
    "Timer active: " .. tostring(status.timerExists == true),
    "Round active: " .. tostring(status.roundActive == true),
    "Sample interval: " .. tostring(status.sampleInterval or "?") .. "s",
    "Max candles: " .. tostring(status.maxCandles or "?"),
    "Last sample: " .. ((status.lastSampleAgo or -1) >= 0 and tostring(status.lastSampleAgo) .. "s ago" or "never"),
    "Networking: " .. ((status.lastNetworkAgo or -1) >= 0 and tostring(status.lastNetworkCount or 0) .. " players sent " .. tostring(status.lastNetworkAgo) .. "s ago" or "not sent")
  }

  if istable(status.candleCounts) then
    lines[#lines + 1] = "Candle counts:"

    for _, item in ipairs(status.candleCounts) do
      lines[#lines + 1] = "  " .. tostring(item.name) .. ": " .. tostring(item.candles)
    end
  end

  return table.concat(lines, "\n")
end

local function refreshStatus()
  sendAction("status")
end

local function openSampleChart()
  if not addon.UI or not addon.UI.OpenFallbackPopup then return end

  local data = {
    {
      name = "Sample Trader",
      steamID = "SAMPLE:1",
      starting = 1000,
      ending = 1037,
      high = 1052,
      low = 982,
      biggestGain = 31,
      biggestLoss = -18,
      candles = {
        { t = 0, open = 1000, high = 1012, low = 996, close = 1008 },
        { t = 10, open = 1008, high = 1028, low = 1002, close = 1024 },
        { t = 20, open = 1024, high = 1031, low = 1006, close = 1010 },
        { t = 30, open = 1010, high = 1041, low = 1008, close = 1038 },
        { t = 40, open = 1038, high = 1052, low = 1029, close = 1037 }
      }
    },
    {
      name = "Flat Karma",
      steamID = "SAMPLE:2",
      starting = 1000,
      ending = 1000,
      high = 1000,
      low = 1000,
      biggestGain = 0,
      biggestLoss = 0,
      candles = {
        { t = 0, open = 1000, high = 1000, low = 1000, close = 1000 }
      }
    }
  }

  addon.UI.OpenFallbackPopup(data)
end

local function buildPanel(panel)
  panel:ClearControls()
  panel:Help("TTT Karma Market")
  panel:Help("Server-authoritative settings replicate to clients where Garry's Mod exposes the ConVars.")

  addCheck(panel, "enabled", "Enable addon", "Track karma and show the end-round market panel.")
  addCheck(panel, "debug", "Enable debug logging", "Print lifecycle, sampling, networking, and admin messages.")
  addCheck(panel, "popup_fallback", "Enable popup fallback", "Open a standalone popup if TTT's end-round sheet cannot be found.")
  addCheck(panel, "show_grid", "Show chart grid", "Draw horizontal chart grid lines.")
  addCheck(panel, "show_labels", "Show labels", "Draw karma and time labels around the chart.")
  addCheck(panel, "auto_sort", "Auto-sort players", "Apply the default sorting mode when opening the panel.")

  addSlider(panel, "sample_interval", "Sample interval", 1, 120, 0, "Seconds between karma snapshots.")
  addSlider(panel, "max_candles", "Max candles", 1, 240, 0, "Maximum candles stored for each player.")
  addSlider(panel, "chart_height", "Chart height", 220, 900, 0, "Preferred fallback popup chart height.")

  addSortDropdown(panel)

  local reset = vgui.Create("DButton")
  reset:SetText("Reset settings to defaults")
  reset:SetTooltip("Restore every Karma Market ConVar to its default value.")
  reset.DoClick = function() sendAction("reset") end
  panel:AddItem(reset)

  local clear = vgui.Create("DButton")
  clear:SetText("Force clear round data")
  clear:SetTooltip("Clear the server's current in-memory karma sample data.")
  clear.DoClick = function() sendAction("clear") end
  panel:AddItem(clear)

  local summary = vgui.Create("DButton")
  summary:SetText("Print debug summary to console")
  summary:SetTooltip("Print server-side debug state to the server console.")
  summary.DoClick = function() sendAction("summary") end
  panel:AddItem(summary)

  local preview = vgui.Create("DButton")
  preview:SetText("Open sample chart")
  preview:SetTooltip("Open a local sample Karma Market popup without waiting for a TTT round.")
  preview.DoClick = openSampleChart
  panel:AddItem(preview)

  local status = vgui.Create("DLabel")
  status:SetText(formatStatus())
  status:SetDark(true)
  status:SetWrap(true)
  status:SetAutoStretchVertical(true)
  status:SetTooltip("Live debug state reported by the server.")
  panel:AddItem(status)

  admin.StatusLabel = status
  refreshStatus()

  timer.Create("TTTKarmaMarket_AdminStatusRefresh", 1, 0, function()
    if not IsValid(admin.StatusLabel) then
      timer.Remove("TTTKarmaMarket_AdminStatusRefresh")
      return
    end

    refreshStatus()
    admin.StatusLabel:SetText(formatStatus())
  end)
end

hook.Add("PopulateToolMenu", "TTTKarmaMarket_AdminPanel", function()
  spawnmenu.AddToolMenuOption("Utilities", "TTT", "TTTKarmaMarket", "Karma Market", "", "", buildPanel)
end)

net.Receive(statusMessage, function()
  local json = net.ReadString()
  admin.Status = util.JSONToTable(json or "{}") or {}

  if IsValid(admin.StatusLabel) then
    admin.StatusLabel:SetText(formatStatus())
  end
end)
