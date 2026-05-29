TTTKarmaMarket = TTTKarmaMarket or {}
TTTKarmaMarket.UI = TTTKarmaMarket.UI or {}

local addon = TTTKarmaMarket
local ui = addon.UI

local function numeric(value)
  return tonumber(value) or 0
end

local function playerNet(record)
  return numeric(record.ending) - numeric(record.starting)
end

local function volatility(record)
  return numeric(record.high) - numeric(record.low)
end

local function formatSigned(value)
  value = numeric(value)
  if value > 0 then return "+" .. tostring(value) end

  return tostring(value)
end

local function makeHeader(parent)
  local header = vgui.Create("DPanel", parent)
  header:Dock(TOP)
  header:SetTall(72)
  header:DockMargin(0, 0, 0, 8)

  header.Paint = function(_, w, h)
    surface.SetDrawColor(addon.Config.Colors.Panel)
    surface.DrawRect(0, 0, w, h)
  end

  local title = vgui.Create("DLabel", header)
  title:Dock(TOP)
  title:DockMargin(12, 8, 12, 0)
  title:SetTall(24)
  title:SetFont("DermaLarge")
  title:SetTextColor(addon.Config.Colors.Text)

  local summary = vgui.Create("DLabel", header)
  summary:Dock(TOP)
  summary:DockMargin(12, 2, 12, 0)
  summary:SetTall(24)
  summary:SetFont("DermaDefault")
  summary:SetTextColor(addon.Config.Colors.MutedText)

  return title, summary
end

local function sortRecords(records, mode)
  if mode == "none" then return end

  table.sort(records, function(a, b)
    if mode == "gain" then return playerNet(a) > playerNet(b) end
    if mode == "loss" then return playerNet(a) < playerNet(b) end
    if mode == "volatile" then return volatility(a) > volatility(b) end

    return string.lower(a.name or "") < string.lower(b.name or "")
  end)
end

function ui.CreateKarmaMarketPanel(parent, data)
  local colors = addon.Config.Colors
  local panel = vgui.Create("DPanel", parent)
  panel:Dock(FILL)
  panel:SetPaintBackground(false)

  local title, summary = makeHeader(panel)

  local body = vgui.Create("DPanel", panel)
  body:Dock(FILL)
  body:SetPaintBackground(false)

  local left = vgui.Create("DPanel", body)
  left:Dock(LEFT)
  left:SetWide(250)
  left:DockMargin(0, 0, 8, 0)
  left.Paint = function(_, w, h)
    surface.SetDrawColor(colors.Panel)
    surface.DrawRect(0, 0, w, h)
  end

  local sortBar = vgui.Create("DPanel", left)
  sortBar:Dock(TOP)
  sortBar:SetTall(96)
  sortBar:DockMargin(8, 8, 8, 4)
  sortBar:SetPaintBackground(false)

  local list = vgui.Create("DListView", left)
  list:Dock(FILL)
  list:DockMargin(8, 0, 8, 8)
  list:SetMultiSelect(false)
  list:AddColumn("Player")
  list:AddColumn("Net")

  local chart = addon.Chart.Create(body)
  chart:Dock(FILL)

  local records = table.Copy(data or {})
  local function selectRecord(record)
    chart:SetCandles(record and record.candles or {})

    if not record then
      title:SetText("Karma Market")
      summary:SetText("No player data was captured.")
      return
    end

    local net = playerNet(record)
    title:SetText(record.name or "Unknown Player")
    summary:SetText(
      "Start: " .. numeric(record.starting) ..
      "   End: " .. numeric(record.ending) ..
      "   Net: " .. formatSigned(net) ..
      "   Volatility: " .. volatility(record) ..
      "   Biggest gain: " .. formatSigned(record.biggestGain) ..
      "   Biggest loss: " .. formatSigned(record.biggestLoss)
    )
  end

  local function rebuildList(mode)
    sortRecords(records, mode)
    list:Clear()

    for _, record in ipairs(records) do
      local line = list:AddLine(record.name or "Unknown Player", formatSigned(playerNet(record)))
      line.Record = record
    end

    if #records > 0 then
      list:SelectFirstItem()
      selectRecord(records[1])
    else
      selectRecord(nil)
    end
  end

  local buttons = {
    { "Alphabetical", "alpha" },
    { "Biggest gain", "gain" },
    { "Biggest loss", "loss" },
    { "Most volatile", "volatile" }
  }

  for _, item in ipairs(buttons) do
    local button = vgui.Create("DButton", sortBar)
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, 4)
    button:SetTall(20)
    button:SetText(item[1])
    button.DoClick = function()
      rebuildList(item[2])
    end
  end

  function list:OnRowSelected(_, line)
    if line and line.Record then
      selectRecord(line.Record)
    end
  end

  local initialSort = "none"

  if addon.GetBool("auto_sort") then
    initialSort = addon.GetString("default_sort")
  end

  rebuildList(initialSort)

  return panel
end

local function findPropertySheet(panel)
  if not IsValid(panel) then return nil end
  if panel:GetClassName() == "DPropertySheet" then return panel end

  for _, child in ipairs(panel:GetChildren()) do
    local found = findPropertySheet(child)
    if IsValid(found) then return found end
  end

  return nil
end

function ui.TryInjectEndRoundTab(data)
  if addon.IsTTT2() and addon.GetBool("ttt2_force_popup") then
    addon.Log("using popup fallback for TTT2")
    return false
  end

  local world = vgui.GetWorldPanel()
  local sheet = findPropertySheet(world)

  if not IsValid(sheet) or not isfunction(sheet.AddSheet) then
    return false
  end

  for _, item in ipairs(sheet.Items or {}) do
    if item and item.Name == "Karma Market" then
      if IsValid(item.Panel) then
        item.Panel:Clear()
        ui.CreateKarmaMarketPanel(item.Panel, data)
      end

      if IsValid(item.Tab) and isfunction(sheet.SetActiveTab) then
        sheet:SetActiveTab(item.Tab)
      end

      addon.Log("refreshed Karma Market end-round tab")
      return true
    end
  end

  local panel = ui.CreateKarmaMarketPanel(sheet, data)
  sheet:AddSheet("Karma Market", panel, "icon16/chart_bar.png")
  addon.Log("injected Karma Market end-round tab")

  return true
end

function ui.OpenFallbackPopup(data)
  if not addon.GetBool("popup_fallback") then return end

  if IsValid(ui.FallbackFrame) then
    ui.FallbackFrame:Remove()
  end

  local frame = vgui.Create("DFrame")
  frame:SetTitle("Karma Market")
  frame:SetSize(math.min(ScrW() - 80, 980), math.min(ScrH() - 80, addon.GetNumber("chart_height") + 220))
  frame:Center()
  frame:MakePopup()

  ui.FallbackFrame = frame
  ui.CreateKarmaMarketPanel(frame, data)
  addon.Log("opened fallback popup")
end
