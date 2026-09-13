local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CONFIG_FILE = "noxvape.json"
local PROFILES_FOLDER = "noxvape_profiles"
local FFLAGS_FOLDER_NAME = "noxvape_fastflags"
local LOGO_FILE = "noxvapev4.png"
local LOGO_URL = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/noxvapev4.png"
local POGCHAMP_URL = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/pogchamp-removebg-preview.png"
local SETTINGS_ICON_URL = "https://github.com/Gorillatagmodder123456/a/raw/main/ChatGPT%20Image%20Aug%2026%2C%202026%2C%2007_00_05%20AM.png"
local RGB_SPEED = 0.75
local RGB_EPOCH = tick()
local DEFAULT_MENU_COLOR = Color3.fromRGB(55, 150, 200)

local Colors = {
	Panel = Color3.fromRGB(4, 5, 7),
	PanelHover = Color3.fromRGB(9, 11, 15),
	ToggleOff = Color3.fromRGB(7, 9, 12),
	ToggleOffHover = Color3.fromRGB(14, 14, 14),
	ToggleOn = Color3.fromRGB(30, 100, 140),
	ToggleOnHover = Color3.fromRGB(40, 120, 165),
	Action = Color3.fromRGB(10, 12, 16),
	ActionHover = Color3.fromRGB(20, 20, 22),
	Setting = Color3.fromRGB(5, 7, 10),
	Accent = DEFAULT_MENU_COLOR,
	Warning = Color3.fromRGB(255, 165, 0),
	Error = Color3.fromRGB(220, 50, 50),
	Text = Color3.fromRGB(235, 240, 245),
	MutedText = Color3.fromRGB(140, 150, 160),
	Tooltip = Color3.fromRGB(3, 4, 6)
}
local UIFont = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

local function getCustomAsset(p)
	if type(getcustomasset) == "function" then return getcustomasset(p) end
	if type(getsynasset) == "function" then return getsynasset(p) end
	return nil
end
local function canUseFiles()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end
local function listfilesSafe(f)
	if type(listfiles) ~= "function" then return {} end
	local ok, r = pcall(listfiles, f)
	if ok and type(r) == "table" then return r end
	return {}
end
local function makeFolderSafe(f) if type(makefolder) ~= "function" then return false end return (pcall(makefolder, f)) end
local function delFileSafe(f) if type(delfile) ~= "function" then return false end return (pcall(delfile, f)) end
local function isFolderSafe(f) if type(isfolder) ~= "function" then return false end local ok, r = pcall(isfolder, f) return ok and r end
local function tw(o, p, d) if not o or not o.Parent then return end local t = TweenService:Create(o, TweenInfo.new(d or 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), p) t:Play() return t end
local function safeCall(fn, ...) if type(fn) ~= "function" then return true end local ok, r = pcall(fn, ...) if not ok then warn("[NoxLib]", r) return false, r end return true, r end

local function ensureFastFlagsFolder()
	local ok, ex = pcall(function() return workspace:FindFirstChild(FFLAGS_FOLDER_NAME) end)
	if ok and ex then return ex end
	local ok2, c = pcall(function()
		local f = Instance.new("Folder")
		f.Name = FFLAGS_FOLDER_NAME
		f.Parent = workspace
		return f
	end)
	if ok2 and c and c.Parent then return c end
	return nil
end

local config = {
	version = 3,
	features = {}, tabs = {}, positions = {}, keybinds = {}, settings = {},
	noxPosition = { x = 18, y = 75 },
	searchPosition = { x = 300, y = 50 },
	guiKeybind = "RightShift",
	guiSounds = false, soundId = "0",
	menuSounds = false, openSoundId = "0", closeSoundId = "0",
	soundVolume = 0.5,
	menuColor = { r = 55/255, g = 150/255, b = 200/255 }
}

local function loadConfig()
	if not canUseFiles() then return end
	if not isfile(CONFIG_FILE) then return end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
	if not ok or type(data) ~= "table" then return end
	for k, v in pairs(data) do
		if type(config[k]) == "table" and type(v) == "table" then
			for kk, vv in pairs(v) do config[k][kk] = vv end
		else config[k] = v end
	end
end
local saveQueued = false
local function saveConfig()
	if not canUseFiles() then return end
	if saveQueued then return end
	saveQueued = true
	task.delay(0.12, function()
		pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
		saveQueued = false
	end)
end
loadConfig()

local function repairConfig()
	for _, k in ipairs({"features","tabs","positions","keybinds","settings"}) do
		if type(config[k]) ~= "table" then config[k] = {} end
	end
	if type(config.noxPosition) ~= "table" then config.noxPosition = {x=18,y=75} end
	if type(config.searchPosition) ~= "table" then config.searchPosition = {x=300,y=50} end
	config.noxPosition.x = tonumber(config.noxPosition.x) or 18
	config.noxPosition.y = tonumber(config.noxPosition.y) or 75
	config.searchPosition.x = tonumber(config.searchPosition.x) or 300
	config.searchPosition.y = tonumber(config.searchPosition.y) or 50
	if type(config.guiKeybind) ~= "string" or config.guiKeybind == "" then config.guiKeybind = "RightShift" end
	if type(config.guiSounds) ~= "boolean" then config.guiSounds = false end
	if type(config.soundId) ~= "string" then config.soundId = tostring(config.soundId or "0") end
	if type(config.menuSounds) ~= "boolean" then config.menuSounds = false end
	if type(config.openSoundId) ~= "string" then config.openSoundId = tostring(config.openSoundId or "0") end
	if type(config.closeSoundId) ~= "string" then config.closeSoundId = tostring(config.closeSoundId or "0") end
	config.soundVolume = math.clamp(tonumber(config.soundVolume) or 0.5, 0, 1)
	if type(config.menuColor) ~= "table" then
		config.menuColor = { r = 55/255, g = 150/255, b = 200/255 }
	else
		config.menuColor.r = tonumber(config.menuColor.r) or 55/255
		config.menuColor.g = tonumber(config.menuColor.g) or 150/255
		config.menuColor.b = tonumber(config.menuColor.b) or 200/255
	end
	config.settings["noxvape"] = config.settings["noxvape"] or {}
end
repairConfig()

local function deriveAccentSet(base)
	local h, s, v = base:ToHSV()
	return {
		Accent = base,
		ToggleOn = Color3.fromHSV(h, math.clamp(s * 0.85, 0, 1), math.clamp(v * 0.75, 0, 1)),
		ToggleOnHover = Color3.fromHSV(h, math.clamp(s * 0.90, 0, 1), math.clamp(v * 0.85, 0, 1))
	}
end

do
	local initial = Color3.new(config.menuColor.r, config.menuColor.g, config.menuColor.b)
	local set = deriveAccentSet(initial)
	Colors.Accent = set.Accent
	Colors.ToggleOn = set.ToggleOn
	Colors.ToggleOnHover = set.ToggleOnHover
end

local function ensureCategoryData(cat)
	if type(config.features[cat]) ~= "table" then config.features[cat] = {} end
	if type(config.keybinds[cat]) ~= "table" then config.keybinds[cat] = {} end
	if type(config.settings[cat]) ~= "table" then config.settings[cat] = {} end
end
local function colorToData(v) if typeof(v) ~= "Color3" then return v end return {r=v.R,g=v.G,b=v.B} end
local function dataToColor(v)
	if type(v) == "table" and type(v.r) == "number" and type(v.g) == "number" and type(v.b) == "number" then
		return Color3.new(math.clamp(v.r,0,1), math.clamp(v.g,0,1), math.clamp(v.b,0,1))
	end
	return v
end
local function getFeatureState(cat, name)
	ensureCategoryData(cat)
	local v = config.features[cat][name]
	return type(v) == "boolean" and v or false
end
local function getKeybind(cat, name)
	ensureCategoryData(cat)
	local v = config.keybinds[cat][name]
	if type(v) == "string" and v ~= "" then return v end
	return nil
end
local function getSetting(cat, feat, key, default)
	ensureCategoryData(cat)
	if type(config.settings[cat][feat]) ~= "table" then config.settings[cat][feat] = {} end
	local v = config.settings[cat][feat][key]
	if v == nil then
		config.settings[cat][feat][key] = colorToData(default)
		return default
	end
	return dataToColor(v)
end
local function setSetting(cat, feat, key, value)
	ensureCategoryData(cat)
	if type(config.settings[cat][feat]) ~= "table" then config.settings[cat][feat] = {} end
	config.settings[cat][feat][key] = colorToData(value)
	saveConfig()
end
local function getPosition(name, dx, dy)
	local p = config.positions[name]
	if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then return p.x, p.y end
	return dx, dy
end

local oldGui = playerGui:FindFirstChild("Nox")
if oldGui then oldGui:Destroy() end
local oldBlur = Lighting:FindFirstChild("NoxBlur")
if oldBlur then oldBlur:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Nox"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100000
screenGui.Parent = playerGui

local function applyMenuColorToGui(newColor)
	local oldAccent = Colors.Accent
	local oldOn = Colors.ToggleOn
	local oldOnHover = Colors.ToggleOnHover
	local set = deriveAccentSet(newColor)
	Colors.Accent = set.Accent
	Colors.ToggleOn = set.ToggleOn
	Colors.ToggleOnHover = set.ToggleOnHover
	config.menuColor = { r = newColor.R, g = newColor.G, b = newColor.B }
	saveConfig()
	for _, d in ipairs(screenGui:GetDescendants()) do
		if d:IsA("GuiObject") then
			local c = d.BackgroundColor3
			if c == oldAccent then d.BackgroundColor3 = Colors.Accent
			elseif c == oldOn then d.BackgroundColor3 = Colors.ToggleOn
			elseif c == oldOnHover then d.BackgroundColor3 = Colors.ToggleOnHover end
		end
		if d:IsA("UIStroke") then
			if d.Color == oldAccent then d.Color = Colors.Accent end
		end
		if d:IsA("ScrollingFrame") then
			if d.ScrollBarImageColor3 == oldAccent then d.ScrollBarImageColor3 = Colors.Accent end
		end
		if d:IsA("ImageLabel") then
			if d.ImageColor3 == oldAccent then d.ImageColor3 = Colors.Accent end
		end
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			if d.TextColor3 == oldAccent then d.TextColor3 = Colors.Accent end
		end
	end
end

local notifHolder = Instance.new("Frame")
notifHolder.Name = "Notifications"
notifHolder.BackgroundTransparency = 1
notifHolder.AnchorPoint = Vector2.new(1, 1)
notifHolder.Position = UDim2.new(1, -20, 1, -20)
notifHolder.Size = UDim2.fromOffset(360, 400)
notifHolder.ZIndex = 50000
notifHolder.Parent = screenGui
local notifLayout = Instance.new("UIListLayout")
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 8)
notifLayout.Parent = notifHolder

local notifCounter = 0
local activeNotifs = {}
local MAX_NOTIFS = 5
local PogchampAsset = nil

task.spawn(function()
	if type(request) == "function" and type(writefile) == "function" then
		pcall(function()
			local r = request({Url = POGCHAMP_URL, Method = "GET"})
			if r and r.Success and r.Body then
				writefile("nox_pogchamp.png", r.Body)
				local a = getCustomAsset("nox_pogchamp.png")
				if a then PogchampAsset = a end
			end
		end)
	end
	PogchampAsset = PogchampAsset or "rbxassetid://10340520068"
end)

local function createNotification(msg, kind)
	if not screenGui or not screenGui.Parent then return end
	notifCounter += 1
	while #activeNotifs >= MAX_NOTIFS do
		local o = table.remove(activeNotifs, 1)
		if o and o.Parent then o:Destroy() end
	end
	local accent = kind == "warning" and Colors.Warning or kind == "error" and Colors.Error or Colors.Accent
	local n = Instance.new("Frame")
	n.Name = "Notification"
	n.BackgroundColor3 = Colors.Panel
	n.BackgroundTransparency = 0.12
	n.BorderSizePixel = 0
	n.Size = UDim2.fromOffset(330, 50)
	n.LayoutOrder = notifCounter
	n.ZIndex = 50001
	n.ClipsDescendants = true
	n.Parent = notifHolder
	table.insert(activeNotifs, n)
	local side = Instance.new("Frame")
	side.BackgroundColor3 = accent
	side.BorderSizePixel = 0
	side.Size = UDim2.new(0, 3, 1, 0)
	side.ZIndex = 50005
	side.Parent = n
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromOffset(28, 28)
	img.Position = UDim2.fromOffset(6, 11)
	img.Image = PogchampAsset or "rbxassetid://10340520068"
	img.ScaleType = Enum.ScaleType.Fit
	img.ZIndex = 50003
	img.Parent = n
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Position = UDim2.fromOffset(42, 0)
	lbl.Size = UDim2.new(1, -56, 1, 0)
	lbl.FontFace = UIFont
	lbl.TextSize = 17
	lbl.TextColor3 = accent
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.TextTruncate = Enum.TextTruncate.AtEnd
	lbl.Text = tostring(msg or "")
	lbl.ZIndex = 50002
	lbl.Parent = n
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = accent
	bar.BackgroundTransparency = 0.2
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0, 3)
	bar.Position = UDim2.new(0, 0, 1, -3)
	bar.ZIndex = 50004
	bar.Parent = n
	n.Position = UDim2.fromOffset(360, 0)
	n.Size = UDim2.fromOffset(330 * 0.8, 50 * 0.8)
	tw(n, {Position = UDim2.fromOffset(0, 0)}, 0.25)
	TweenService:Create(n, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(330, 50)}):Play()
	local duration = 2.4
	TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 3)}):Play()
	task.delay(duration + 0.15, function()
		if not n.Parent then return end
		local so = tw(n, {Position = UDim2.fromOffset(360, 0)}, 0.2)
		TweenService:Create(n, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.fromOffset(330 * 0.8, 50 * 0.8)}):Play()
		if so then
			so.Completed:Connect(function()
				if n.Parent then n:Destroy() end
				for i, v in ipairs(activeNotifs) do if v == n then table.remove(activeNotifs, i); break end end
			end)
		end
	end)
end
local function notifyEnabled(m) createNotification(m, "enabled") end
local function notifyWarning(m) createNotification(m, "warning") end
local function notifyError(m) createNotification(m, "error") end

local tooltip = nil
local tooltipToken = 0
local function hideTooltip()
	tooltipToken += 1
	if tooltip then pcall(function() tooltip:Destroy() end); tooltip = nil end
end
local function showTooltip(text)
	hideTooltip()
	tooltipToken += 1
	local token = tooltipToken
	task.delay(0.08, function()
		if token ~= tooltipToken then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		local mouse = UserInputService:GetMouseLocation()
		local frame = Instance.new("Frame")
		frame.Name = "Tooltip"
		frame.BackgroundColor3 = Colors.Tooltip
		frame.BorderSizePixel = 0
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.ZIndex = 60000
		frame.Parent = screenGui
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 7)
		pad.PaddingBottom = UDim.new(0, 7)
		pad.PaddingLeft = UDim.new(0, 11)
		pad.PaddingRight = UDim.new(0, 11)
		pad.Parent = frame
		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.AutomaticSize = Enum.AutomaticSize.XY
		lbl.FontFace = UIFont
		lbl.TextSize = 16
		lbl.TextColor3 = Colors.Text
		lbl.Text = text
		lbl.ZIndex = 60001
		lbl.Parent = frame
		task.wait()
		if token ~= tooltipToken then if frame.Parent then frame:Destroy() end return end
		local vp = camera.ViewportSize
		local w = frame.AbsoluteSize.X
		local h = frame.AbsoluteSize.Y
		local x = mouse.X + 14
		local y = mouse.Y + 16
		if x + w > vp.X - 8 then x = mouse.X - w - 14 end
		if y + h > vp.Y - 8 then y = mouse.Y - h - 16 end
		frame.Position = UDim2.fromOffset(math.clamp(x, 8, math.max(8, vp.X - w - 8)), math.clamp(y, 8, math.max(8, vp.Y - h - 8)))
		tooltip = frame
	end)
end
local function addTooltip(obj, text)
	if not text or text == "" then return end
	obj.MouseEnter:Connect(function() showTooltip(text) end)
	obj.MouseLeave:Connect(function() hideTooltip() end)
end

local function makeDraggable(obj, handle, posName, isNox)
	local dragging = false
	local dragStart
	local startPos
	local mc, ec
	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
		dragging = true
		dragStart = input.Position
		startPos = obj.Position
		hideTooltip()
		if mc then mc:Disconnect() end
		if ec then ec:Disconnect() end
		mc = UserInputService.InputChanged:Connect(function(ic)
			if not dragging or ic.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			local d = ic.Position - dragStart
			local x = startPos.X.Offset + d.X
			local y = startPos.Y.Offset + d.Y
			local cam = workspace.CurrentCamera
			if cam then
				local vp = cam.ViewportSize
				x = math.clamp(x, 0, math.max(0, vp.X - obj.AbsoluteSize.X))
				y = math.clamp(y, 0, math.max(0, vp.Y - obj.AbsoluteSize.Y))
			end
			obj.Position = UDim2.fromOffset(x, y)
		end)
		ec = UserInputService.InputEnded:Connect(function(ie)
			if ie.UserInputType ~= Enum.UserInputType.MouseButton1 and ie.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
			dragging = false
			if mc then mc:Disconnect(); mc = nil end
			if ec then ec:Disconnect(); ec = nil end
			if isNox then config.noxPosition = {x = obj.Position.X.Offset, y = obj.Position.Y.Offset}
			elseif posName == "searchBar" then config.searchPosition = {x = obj.Position.X.Offset, y = obj.Position.Y.Offset}
			else config.positions[posName] = {x = obj.Position.X.Offset, y = obj.Position.Y.Offset} end
			saveConfig()
		end)
	end)
end

local function buildColorPickerRow(parent, layoutOrder, initial, onChanged, labelText, options)
	options = options or {}
	local default = typeof(initial) == "Color3" and initial or Color3.fromRGB(255, 255, 255)
	local current = default
	local hue, saturation, value = current:ToHSV()
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 38)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.LayoutOrder = layoutOrder
	frame.Parent = parent
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0.5, 0, 0, 38)
	label.FontFace = UIFont
	label.TextSize = 16
	label.TextColor3 = Colors.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = labelText
	label.Parent = frame
	local preview = Instance.new("TextButton")
	preview.AutoButtonColor = false
	preview.BackgroundColor3 = current
	preview.BorderSizePixel = 0
	preview.AnchorPoint = Vector2.new(1, 0)
	preview.Position = UDim2.new(1, 0, 0, 5)
	preview.Size = UDim2.fromOffset(32, 28)
	preview.Text = ""
	preview.Parent = frame
	local ps = Instance.new("UIStroke")
	ps.Color = Color3.fromRGB(35, 40, 46)
	ps.Thickness = 1
	ps.Parent = preview
	local pickerFrame = Instance.new("Frame")
	pickerFrame.BackgroundColor3 = Colors.Panel
	pickerFrame.BorderSizePixel = 0
	pickerFrame.Position = UDim2.fromOffset(0, 42)
	pickerFrame.Size = UDim2.fromOffset(194, 190)
	pickerFrame.Visible = false
	pickerFrame.ZIndex = 25000
	pickerFrame.Parent = frame
	local pp = Instance.new("UIPadding")
	pp.PaddingTop = UDim.new(0, 8)
	pp.PaddingBottom = UDim.new(0, 8)
	pp.PaddingLeft = UDim.new(0, 8)
	pp.PaddingRight = UDim.new(0, 8)
	pp.Parent = pickerFrame
	local wheel = Instance.new("ImageButton")
	wheel.AutoButtonColor = false
	wheel.BackgroundTransparency = 1
	wheel.Size = UDim2.fromOffset(150, 150)
	wheel.Position = UDim2.fromOffset(8, 8)
	wheel.ZIndex = 25001
	wheel.Parent = pickerFrame
	wheel.Image = "rbxassetid://6020299385"
	wheel.ScaleType = Enum.ScaleType.Fit
	local wp = Instance.new("Frame")
	wp.AnchorPoint = Vector2.new(0.5, 0.5)
	wp.Size = UDim2.fromOffset(10, 10)
	wp.BackgroundColor3 = Color3.new(1, 1, 1)
	wp.BorderSizePixel = 1
	wp.BorderColor3 = Color3.new(0, 0, 0)
	wp.ZIndex = 25002
	wp.Parent = wheel
	local darkness = Instance.new("Frame")
	darkness.BackgroundColor3 = Color3.new(1, 1, 1)
	darkness.BorderSizePixel = 0
	darkness.Position = UDim2.fromOffset(164, 8)
	darkness.Size = UDim2.fromOffset(16, 150)
	darkness.ZIndex = 25001
	darkness.Parent = pickerFrame
	local dg = Instance.new("UIGradient")
	dg.Rotation = 90
	dg.Parent = darkness
	local ds = Instance.new("Frame")
	ds.AnchorPoint = Vector2.new(0.5, 0.5)
	ds.Position = UDim2.new(0.5, 0, 1 - value, 0)
	ds.Size = UDim2.new(1, 6, 0, 4)
	ds.BackgroundColor3 = Color3.new(1, 1, 1)
	ds.BorderSizePixel = 0
	ds.ZIndex = 25002
	ds.Parent = darkness
	local cd = Instance.new("Frame")
	cd.BackgroundColor3 = current
	cd.BorderSizePixel = 0
	cd.Position = UDim2.fromOffset(8, 166)
	cd.Size = UDim2.fromOffset(172, 12)
	cd.ZIndex = 25002
	cd.Parent = pickerFrame
	local cds = Instance.new("UIStroke")
	cds.Color = Color3.fromRGB(35, 40, 46)
	cds.Thickness = 1
	cds.Parent = cd
	local function updateWP()
		local cx = wheel.AbsoluteSize.X / 2
		local cy = wheel.AbsoluteSize.Y / 2
		local angle = math.pi - (hue * math.pi * 2)
		local radius = saturation * math.min(wheel.AbsoluteSize.X, wheel.AbsoluteSize.Y) / 2
		wp.Position = UDim2.fromOffset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius)
	end
	local function updateDS() ds.Position = UDim2.new(0.5, 0, 1 - value, 0) end
	local function updateGrad()
		dg.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, saturation, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
		})
	end
	local function applyColor()
		current = Color3.fromHSV(hue, saturation, value)
		preview.BackgroundColor3 = current
		cd.BackgroundColor3 = current
		updateWP()
		updateDS()
		updateGrad()
		safeCall(onChanged, current)
	end
	local function setFullColor(color)
		current = color
		hue, saturation, value = color:ToHSV()
		preview.BackgroundColor3 = current
		cd.BackgroundColor3 = current
		updateWP()
		updateDS()
		updateGrad()
		safeCall(onChanged, current)
	end
	local wheelDragging = false
	local dDragging = false
	local function updateWM()
		local mouse = UserInputService:GetMouseLocation()
		local center = wheel.AbsolutePosition + (wheel.AbsoluteSize / 2)
		local offset = mouse - center
		local radius = math.min(wheel.AbsoluteSize.X, wheel.AbsoluteSize.Y) / 2
		local dist = offset.Magnitude
		if dist > radius then offset = offset.Unit * radius; dist = radius end
		saturation = dist <= 0 and 0 or math.clamp(dist / radius, 0, 1)
		local angle = math.atan2(offset.Y, offset.X)
		hue = ((math.pi - angle) / (math.pi * 2)) % 1
		wp.Position = UDim2.fromOffset(wheel.AbsoluteSize.X / 2 + offset.X, wheel.AbsoluteSize.Y / 2 + offset.Y)
		updateGrad()
		applyColor()
	end
	local function updateDM()
		local my = UserInputService:GetMouseLocation().Y
		local top = darkness.AbsolutePosition.Y
		local h = darkness.AbsoluteSize.Y
		local pos = math.clamp(my - top, 0, h)
		value = 1 - math.clamp(pos / h, 0, 1)
		ds.Position = UDim2.new(0.5, 0, 0, pos)
		applyColor()
	end
	wheel.MouseButton1Down:Connect(function() wheelDragging = true; updateWM() end)
	darkness.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dDragging = true
		updateDM()
	end)
	ds.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dDragging = true
		updateDM()
	end)
	local cpc
	cpc = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		if not frame.Parent then if cpc then cpc:Disconnect() end return end
		if wheelDragging then updateWM()
		elseif dDragging then updateDM() end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		wheelDragging = false
		dDragging = false
	end)
	local syncBtn = Instance.new("TextButton")
	syncBtn.AutoButtonColor = false
	syncBtn.BackgroundColor3 = Colors.Action
	syncBtn.BorderSizePixel = 0
	syncBtn.Position = UDim2.fromOffset(0, 236)
	syncBtn.Size = UDim2.fromOffset(194, 32)
	syncBtn.FontFace = UIFont
	syncBtn.TextSize = 15
	syncBtn.TextColor3 = Colors.Text
	syncBtn.Text = "Sync to Menu Color"
	syncBtn.Visible = false
	syncBtn.ZIndex = 25003
	syncBtn.Parent = frame
	syncBtn.MouseEnter:Connect(function() syncBtn.BackgroundColor3 = Colors.ActionHover end)
	syncBtn.MouseLeave:Connect(function() syncBtn.BackgroundColor3 = Colors.Action end)
	syncBtn.MouseButton1Click:Connect(function()
		setFullColor(Colors.Accent)
		notifyEnabled("Synced picker to menu color")
	end)
	local function closePicker()
		pickerFrame.Visible = false
		syncBtn.Visible = false
		frame.Size = UDim2.new(1, 0, 0, 38)
	end
	local function openPicker()
		pickerFrame.Visible = true
		syncBtn.Visible = true
		frame.Size = UDim2.new(1, 0, 0, 276)
		updateWP()
		updateDS()
		updateGrad()
	end
	preview.MouseEnter:Connect(function() ps.Color = Colors.Accent end)
	preview.MouseLeave:Connect(function() ps.Color = Color3.fromRGB(35, 40, 46) end)
	preview.MouseButton1Click:Connect(function()
		if pickerFrame.Visible then closePicker() else openPicker() end
	end)
	updateWP()
	updateDS()
	updateGrad()
	local rgbBtn = Instance.new("TextButton")
	rgbBtn.AutoButtonColor = false
	rgbBtn.BackgroundColor3 = Colors.Action
	rgbBtn.BorderSizePixel = 0
	rgbBtn.AnchorPoint = Vector2.new(1, 0)
	rgbBtn.Position = UDim2.new(1, -38, 0, 5)
	rgbBtn.Size = UDim2.fromOffset(36, 28)
	rgbBtn.FontFace = UIFont
	rgbBtn.TextSize = 12
	rgbBtn.TextColor3 = Colors.Text
	rgbBtn.Text = "RGB"
	rgbBtn.ZIndex = 3
	rgbBtn.Parent = frame
	local autoRGB = false
	local rgbConn = nil
	local function toggleRGB()
		if autoRGB then
			autoRGB = false
			if rgbConn then rgbConn:Disconnect(); rgbConn = nil end
			rgbBtn.BackgroundColor3 = Colors.Action
		else
			autoRGB = true
			rgbBtn.BackgroundColor3 = Colors.Accent
			saturation = 1
			value = 1
			hue = ((tick() - RGB_EPOCH) * RGB_SPEED) % 1
			updateWP()
			updateDS()
			updateGrad()
			applyColor()
			rgbConn = RunService.Heartbeat:Connect(function()
				if not frame.Parent then
					if rgbConn then rgbConn:Disconnect(); rgbConn = nil end
					return
				end
				hue = ((tick() - RGB_EPOCH) * RGB_SPEED) % 1
				saturation = 1
				value = 1
				updateWP()
				updateDS()
				updateGrad()
				applyColor()
			end)
		end
	end
	rgbBtn.MouseEnter:Connect(function() if not autoRGB then rgbBtn.BackgroundColor3 = Colors.ActionHover end end)
	rgbBtn.MouseLeave:Connect(function() if not autoRGB then rgbBtn.BackgroundColor3 = Colors.Action end end)
	rgbBtn.MouseButton1Click:Connect(function() toggleRGB() end)
	addTooltip(rgbBtn, "Synchronized RGB cycling")
	return frame, setFullColor
end

local buttonData = {}
local categoryFrames = {}
local categoryStates = {}
local Features = {}

function Features.get(cat, name) return buttonData[cat] and buttonData[cat][name] end
function Features.isEnabled(cat, name)
	local d = Features.get(cat, name)
	if d and d.getState then return d.getState() end
	return getFeatureState(cat, name)
end
function Features.set(cat, name, enabled)
	local d = Features.get(cat, name)
	if not d then
		ensureCategoryData(cat)
		config.features[cat][name] = enabled and true or false
		saveConfig()
		return false
	end
	local cur = d.getState and d.getState() or false
	if cur == enabled then return true end
	if d.toggle then d.toggle(); return true end
	ensureCategoryData(cat)
	config.features[cat][name] = enabled and true or false
	if d.button then d.button.BackgroundColor3 = enabled and Colors.Accent or Colors.Action end
	saveConfig()
	return true
end
function Features.forceOff(cat, name)
	local d = Features.get(cat, name)
	ensureCategoryData(cat)
	if d and d.getState and d.getState() and type(d.action) == "function" then pcall(d.action, false) end
	config.features[cat][name] = false
	if d then
		if type(d.setState) == "function" then d.setState(false, true)
		elseif d.button then d.button.BackgroundColor3 = Colors.Action end
	end
	saveConfig()
	return true
end
function Features.disable(cat, name) return Features.forceOff(cat, name) end
function Features.enable(cat, name) return Features.set(cat, name, true) end

local _categories = {}
local _categoryMap = {}

local soundObj = Instance.new("Sound")
soundObj.Name = "GUIClickSound"
soundObj.Volume = config.soundVolume
soundObj.Parent = screenGui
local menuSoundObj = Instance.new("Sound")
menuSoundObj.Name = "MenuSound"
menuSoundObj.Volume = config.soundVolume
menuSoundObj.Parent = screenGui
local function playButtonSound()
	if not config.guiSounds then return end
	local id = config.soundId
	if id and id ~= "" and id ~= "0" then
		soundObj.SoundId = "rbxassetid://" .. id
		pcall(function() soundObj:Play() end)
	end
end
local function playMenuSound(isOpen)
	if not config.menuSounds then return end
	local id = isOpen and config.openSoundId or config.closeSoundId
	if id and id ~= "" and id ~= "0" then
		menuSoundObj.SoundId = "rbxassetid://" .. id
		pcall(function() menuSoundObj:Play() end)
	end
end

local dimFrame = Instance.new("Frame")
dimFrame.Name = "BackgroundDim"
dimFrame.BackgroundColor3 = Color3.new(0, 0, 0)
dimFrame.BackgroundTransparency = 0.55
dimFrame.BorderSizePixel = 0
dimFrame.Size = UDim2.fromScale(1, 1)
dimFrame.ZIndex = 10000
dimFrame.Visible = false
dimFrame.Active = true
dimFrame.Parent = screenGui
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "NoxBlur"
blurEffect.Size = 18
blurEffect.Enabled = false
blurEffect.Parent = Lighting

local tabPanel
local function updateBlur()
	if not tabPanel then return end
	blurEffect.Enabled = getSetting("noxvape", "blur", "enabled", false) and tabPanel.Visible
	dimFrame.Visible = tabPanel.Visible
end

local disabledGuiStates = {}
local otherGuisDisabled = false
local function disableOtherScreenGuis()
	if otherGuisDisabled then return end
	otherGuisDisabled = true
	disabledGuiStates = {}
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui ~= screenGui then
			disabledGuiStates[gui] = gui.Enabled
			gui.Enabled = false
		end
	end
end
local function restoreOtherScreenGuis()
	if not otherGuisDisabled then return end
	for gui, prev in pairs(disabledGuiStates) do
		if gui and gui.Parent then pcall(function() gui.Enabled = prev end) end
	end
	disabledGuiStates = {}
	otherGuisDisabled = false
end

local function selfDestruct()
	restoreOtherScreenGuis()
	createNotification("Self destruct initiated. Goodbye!", "warning")
	task.wait(0.35)
	pcall(function() if soundObj then soundObj:Stop(); soundObj:Destroy() end end)
	pcall(function() if menuSoundObj then menuSoundObj:Stop(); menuSoundObj:Destroy() end end)
	pcall(function() if blurEffect then blurEffect.Enabled = false; blurEffect:Destroy() end end)
	pcall(function() if dimFrame then dimFrame:Destroy() end end)
	pcall(function()
		for _, n in ipairs(activeNotifs) do if n and n.Parent then n:Destroy() end end
		activeNotifs = {}
	end)
	pcall(function() if screenGui then screenGui:Destroy() end end)
end

local function findLoaderFolder()
	local pref = workspace:FindFirstChild(FFLAGS_FOLDER_NAME)
	if pref and (pref:IsA("Folder") or pref:IsA("Configuration")) then return pref end
	for _, name in ipairs({"loader","Loader","FastFlags","fastflags","fflags","FFlags","Flags","flags"}) do
		local f = workspace:FindFirstChild(name)
		if f and (f:IsA("Folder") or f:IsA("Configuration")) then return f end
	end
	return nil
end
local function getFlagsFromFolder(folder)
	local list = {}
	if not folder then return list end
	for _, child in ipairs(folder:GetChildren()) do
		local flags = nil
		if child:IsA("StringValue") then
			local ok, decoded = pcall(function() return HttpService:JSONDecode(child.Value) end)
			if ok and type(decoded) == "table" then flags = decoded end
		elseif child:IsA("ModuleScript") then
			local ok, res = pcall(require, child)
			if ok and type(res) == "table" then flags = res end
		end
		if flags then table.insert(list, {name = child.Name, flags = flags, instance = child}) end
	end
	return list
end
local function getFFlagFunction()
	if type(setfflag) == "function" then return setfflag end
	if type(SetFastFlag) == "function" then return SetFastFlag end
	if type(SetFFlag) == "function" then return SetFFlag end
	if type(SetFlag) == "function" then return SetFlag end
	if _G and type(_G.setfflag) == "function" then return _G.setfflag end
	if _G and type(_G.SetFastFlag) == "function" then return _G.SetFastFlag end
	return nil
end
local function applyFastFlags(flags)
	if type(flags) ~= "table" then return 0, "not a table" end
	local fn = getFFlagFunction()
	if not fn then return 0, "setfflag not available in this executor" end
	local count = 0
	for k, v in pairs(flags) do
		local ok = pcall(function() fn(tostring(k), tostring(v)) end)
		if ok then count += 1 end
	end
	return count, nil
end

local function ensureProfilesFolder()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		if not isFolderSafe(PROFILES_FOLDER) then makeFolderSafe(PROFILES_FOLDER) end
	end
end
local function listProfiles()
	if not canUseFiles() then return {} end
	ensureProfilesFolder()
	local raw = listfilesSafe(PROFILES_FOLDER)
	local list = {}
	local seen = {}
	for _, rp in ipairs(raw) do
		local s = tostring(rp)
		local norm = s:gsub("\\", "/")
		local name = norm:match("([^/]+)%.json$")
		if name and not seen[name] then
			seen[name] = true
			local path = s
			if not isfile(path) then
				local t1 = PROFILES_FOLDER .. "/" .. name .. ".json"
				local t2 = PROFILES_FOLDER .. "\\" .. name .. ".json"
				if isfile(t1) then path = t1 elseif isfile(t2) then path = t2 end
			end
			table.insert(list, {name = name, path = path})
		end
	end
	table.sort(list, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
	return list
end
local function findProfileEntry(name)
	for _, e in ipairs(listProfiles()) do if e.name == name then return e end end
	return nil
end
local function readProfile(name)
	if not canUseFiles() then return nil end
	local e = findProfileEntry(name)
	if e then
		local ok, d = pcall(function() return HttpService:JSONDecode(readfile(e.path)) end)
		if ok and type(d) == "table" then return d end
	end
	for _, p in ipairs({PROFILES_FOLDER .. "/" .. name .. ".json", PROFILES_FOLDER .. "\\" .. name .. ".json", name .. ".json"}) do
		if isfile(p) then
			local ok, d = pcall(function() return HttpService:JSONDecode(readfile(p)) end)
			if ok and type(d) == "table" then return d end
		end
	end
	return nil
end
local function writeProfileData(name, data)
	if not canUseFiles() then return false end
	ensureProfilesFolder()
	for _, p in ipairs({PROFILES_FOLDER .. "/" .. name .. ".json", PROFILES_FOLDER .. "\\" .. name .. ".json", name .. ".json"}) do
		local ok = pcall(function() writefile(p, HttpService:JSONEncode(data)) end)
		if ok and isfile(p) then return true end
	end
	return false
end
local function deleteProfile(name)
	if not canUseFiles() then return false end
	local e = findProfileEntry(name)
	if e then if delFileSafe(e.path) then return true end end
	for _, p in ipairs({PROFILES_FOLDER .. "/" .. name .. ".json", PROFILES_FOLDER .. "\\" .. name .. ".json", name .. ".json"}) do
		if isfile(p) then if delFileSafe(p) then return true end end
	end
	return false
end
local function captureCurrentConfig()
	return {
		features = HttpService:JSONDecode(HttpService:JSONEncode(config.features)),
		settings = HttpService:JSONDecode(HttpService:JSONEncode(config.settings)),
		keybinds = HttpService:JSONDecode(HttpService:JSONEncode(config.keybinds)),
		tabs = HttpService:JSONDecode(HttpService:JSONEncode(config.tabs)),
		noxPosition = HttpService:JSONDecode(HttpService:JSONEncode(config.noxPosition)),
		searchPosition = HttpService:JSONDecode(HttpService:JSONEncode(config.searchPosition)),
		guiSounds = config.guiSounds, menuSounds = config.menuSounds,
		soundVolume = config.soundVolume, soundId = config.soundId,
		openSoundId = config.openSoundId, closeSoundId = config.closeSoundId,
		guiKeybind = config.guiKeybind,
		menuColor = HttpService:JSONDecode(HttpService:JSONEncode(config.menuColor))
	}
end
local function saveProfile(name)
	if not canUseFiles() then return false, "no file access" end
	ensureProfilesFolder()
	local data = captureCurrentConfig()
	data.name = name
	return writeProfileData(name, data), nil
end
local function countEnabledFeatures(data)
	local count = 0
	local list = {}
	if type(data) ~= "table" or type(data.features) ~= "table" then return 0, list end
	for cat, feats in pairs(data.features) do
		if type(feats) == "table" then
			for name, v in pairs(feats) do
				if v == true then
					count += 1
					table.insert(list, cat .. " / " .. name)
				end
			end
		end
	end
	return count, list
end
local function applyProfileData(data)
	if type(data) ~= "table" then return false end
	if type(data.features) == "table" then config.features = data.features end
	if type(data.settings) == "table" then config.settings = data.settings end
	if type(data.keybinds) == "table" then config.keybinds = data.keybinds end
	if type(data.tabs) == "table" then config.tabs = data.tabs end
	if type(data.noxPosition) == "table" then config.noxPosition = data.noxPosition end
	if type(data.searchPosition) == "table" then config.searchPosition = data.searchPosition end
	if type(data.guiSounds) == "boolean" then config.guiSounds = data.guiSounds end
	if type(data.menuSounds) == "boolean" then config.menuSounds = data.menuSounds end
	if type(data.soundVolume) == "number" then config.soundVolume = data.soundVolume end
	if type(data.soundId) == "string" then config.soundId = data.soundId end
	if type(data.openSoundId) == "string" then config.openSoundId = data.openSoundId end
	if type(data.closeSoundId) == "string" then config.closeSoundId = data.closeSoundId end
	if type(data.guiKeybind) == "string" then config.guiKeybind = data.guiKeybind end
	if type(data.menuColor) == "table" then
		local newColor = Color3.new(data.menuColor.r, data.menuColor.g, data.menuColor.b)
		applyMenuColorToGui(newColor)
	end
	for cat, feats in pairs(buttonData) do
		for name, d in pairs(feats) do
			if d.isToggle then
				local newState = false
				if config.features[cat] and config.features[cat][name] == true then newState = true end
				local curState = d.getState and d.getState() or false
				if curState ~= newState then
					if type(d.action) == "function" then pcall(d.action, newState) end
					if d.setState then d.setState(newState, true) end
				end
			end
		end
	end
	saveConfig()
	return true
end

local waitingForBind = nil
local settingsWindow = nil
local settingsVisible = false
local fastFlagWindow = nil
local profilesWindow = nil
local filterButtons

local function setMenuVisible(visible)
	if not tabPanel then return end
	local was = tabPanel.Visible
	tabPanel.Visible = visible
	dimFrame.Visible = visible
	if settingsWindow then settingsWindow.Visible = visible and settingsVisible end
	if fastFlagWindow then fastFlagWindow.Visible = visible and fastFlagWindow.Visible end
	if profilesWindow then profilesWindow.Visible = visible and profilesWindow.Visible end
	for _, card in pairs(categoryFrames) do
		if card and card.Parent then card.Visible = visible and categoryStates[card.Name] end
	end
	local sf = screenGui:FindFirstChild("SearchBar")
	if sf then sf.Visible = visible end
	if visible then
		disableOtherScreenGuis()
		local sb = sf and sf:FindFirstChildOfClass("TextBox")
		if sb and sb.Text ~= "" and filterButtons then filterButtons(sb.Text) end
		if not was then playMenuSound(true) end
	else
		restoreOtherScreenGuis()
		if was then playMenuSound(false) end
	end
	updateBlur()
end

local function createFastFlagWindow()
	if fastFlagWindow then fastFlagWindow.Visible = not fastFlagWindow.Visible return end
	local wx, wy = getPosition("fastFlagWindow", 340, 100)
	local w = Instance.new("Frame")
	w.Name = "FastFlagWindow"
	w.BackgroundColor3 = Colors.Panel
	w.BorderSizePixel = 0
	w.Size = UDim2.fromOffset(360, 500)
	w.Position = UDim2.fromOffset(wx, wy)
	w.ClipsDescendants = true
	w.ZIndex = 45000
	w.Parent = screenGui
	fastFlagWindow = w
	local h = Instance.new("TextButton")
	h.AutoButtonColor = false
	h.BackgroundColor3 = Colors.Panel
	h.BorderSizePixel = 0
	h.Size = UDim2.new(1, 0, 0, 40)
	h.FontFace = UIFont
	h.TextSize = 18
	h.TextColor3 = Colors.Text
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = "  Fast Flag Manager"
	h.ZIndex = 45001
	h.Parent = w
	local cb = Instance.new("TextButton")
	cb.AutoButtonColor = false
	cb.BackgroundTransparency = 1
	cb.Size = UDim2.fromOffset(40, 40)
	cb.AnchorPoint = Vector2.new(1, 0)
	cb.Position = UDim2.new(1, 0, 0, 0)
	cb.FontFace = UIFont
	cb.TextSize = 20
	cb.TextColor3 = Colors.MutedText
	cb.Text = "X"
	cb.ZIndex = 45002
	cb.Parent = h
	cb.MouseEnter:Connect(function() cb.TextColor3 = Colors.Text end)
	cb.MouseLeave:Connect(function() cb.TextColor3 = Colors.MutedText end)
	cb.MouseButton1Click:Connect(function() w.Visible = false end)
	makeDraggable(w, h, "fastFlagWindow", false)
	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.fromOffset(12, 44)
	hint.Size = UDim2.new(1, -24, 0, 18)
	hint.FontFace = UIFont
	hint.TextSize = 12
	hint.TextColor3 = Colors.MutedText
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "Import JSON or drop StringValues into workspace > " .. FFLAGS_FOLDER_NAME
	hint.ZIndex = 45003
	hint.Parent = w
	local importRow = Instance.new("Frame")
	importRow.BackgroundTransparency = 1
	importRow.Position = UDim2.fromOffset(12, 66)
	importRow.Size = UDim2.new(1, -24, 0, 60)
	importRow.ZIndex = 45003
	importRow.Parent = w
	local importName = Instance.new("TextBox")
	importName.BackgroundColor3 = Colors.ToggleOff
	importName.BorderSizePixel = 0
	importName.Position = UDim2.fromOffset(0, 0)
	importName.Size = UDim2.new(0.4, -4, 0, 26)
	importName.FontFace = UIFont
	importName.TextSize = 13
	importName.TextColor3 = Colors.Text
	importName.PlaceholderText = "Name..."
	importName.PlaceholderColor3 = Colors.MutedText
	importName.Text = ""
	importName.ClearTextOnFocus = false
	importName.ZIndex = 45004
	importName.Parent = importRow
	local importJson = Instance.new("TextBox")
	importJson.BackgroundColor3 = Colors.ToggleOff
	importJson.BorderSizePixel = 0
	importJson.Position = UDim2.fromOffset(0, 30)
	importJson.Size = UDim2.new(1, -84, 0, 26)
	importJson.FontFace = UIFont
	importJson.TextSize = 13
	importJson.TextColor3 = Colors.Text
	importJson.PlaceholderText = '{"FFlagExample":"True", ...}'
	importJson.PlaceholderColor3 = Colors.MutedText
	importJson.Text = ""
	importJson.ClearTextOnFocus = false
	importJson.ZIndex = 45004
	importJson.Parent = importRow
	local importBtn = Instance.new("TextButton")
	importBtn.AutoButtonColor = false
	importBtn.BackgroundColor3 = Colors.Accent
	importBtn.BorderSizePixel = 0
	importBtn.AnchorPoint = Vector2.new(1, 0)
	importBtn.Position = UDim2.new(1, 0, 0, 30)
	importBtn.Size = UDim2.fromOffset(80, 26)
	importBtn.FontFace = UIFont
	importBtn.TextSize = 13
	importBtn.TextColor3 = Colors.Text
	importBtn.Text = "Import"
	importBtn.ZIndex = 45004
	importBtn.Parent = importRow
	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Position = UDim2.fromOffset(12, 134)
	content.Size = UDim2.new(1, -24, 1, -204)
	content.ScrollBarThickness = 4
	content.ScrollBarImageColor3 = Colors.Accent
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.ZIndex = 45003
	content.Parent = w
	local cl = Instance.new("UIListLayout")
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.Padding = UDim.new(0, 4)
	cl.Parent = content
	local selected = {}
	local function refresh()
		for _, c in ipairs(content:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		selected = {}
		local folder = findLoaderFolder()
		if not folder then
			local e = Instance.new("TextLabel")
			e.BackgroundTransparency = 1
			e.Size = UDim2.new(1, 0, 0, 40)
			e.FontFace = UIFont
			e.TextSize = 15
			e.TextColor3 = Colors.MutedText
			e.Text = "No '" .. FFLAGS_FOLDER_NAME .. "' folder found."
			e.LayoutOrder = 1
			e.Parent = content
			return
		end
		local entries = getFlagsFromFolder(folder)
		if #entries == 0 then
			local e = Instance.new("TextLabel")
			e.BackgroundTransparency = 1
			e.Size = UDim2.new(1, 0, 0, 40)
			e.FontFace = UIFont
			e.TextSize = 15
			e.TextColor3 = Colors.MutedText
			e.Text = "Folder '" .. folder.Name .. "' has no valid JSONs."
			e.LayoutOrder = 1
			e.Parent = content
			return
		end
		for i, entry in ipairs(entries) do
			local row = Instance.new("Frame")
			row.BackgroundColor3 = Colors.Setting
			row.BorderSizePixel = 0
			row.Size = UDim2.new(1, 0, 0, 36)
			row.LayoutOrder = i
			row.ZIndex = 45004
			row.Parent = content
			local check = Instance.new("TextButton")
			check.AutoButtonColor = false
			check.BackgroundColor3 = Colors.Action
			check.BorderSizePixel = 0
			check.Position = UDim2.fromOffset(6, 5)
			check.Size = UDim2.fromOffset(26, 26)
			check.Text = ""
			check.ZIndex = 45005
			check.Parent = row
			local count = 0
			for _ in pairs(entry.flags) do count += 1 end
			local nl = Instance.new("TextLabel")
			nl.BackgroundTransparency = 1
			nl.Position = UDim2.fromOffset(40, 0)
			nl.Size = UDim2.new(1, -110, 1, 0)
			nl.FontFace = UIFont
			nl.TextSize = 14
			nl.TextColor3 = Colors.Text
			nl.TextXAlignment = Enum.TextXAlignment.Left
			nl.TextTruncate = Enum.TextTruncate.AtEnd
			nl.Text = entry.name .. " (" .. count .. ")"
			nl.ZIndex = 45005
			nl.Parent = row
			local lb = Instance.new("TextButton")
			lb.AutoButtonColor = false
			lb.BackgroundColor3 = Colors.Action
			lb.BorderSizePixel = 0
			lb.AnchorPoint = Vector2.new(1, 0.5)
			lb.Position = UDim2.new(1, -36, 0.5, 0)
			lb.Size = UDim2.fromOffset(56, 26)
			lb.FontFace = UIFont
			lb.TextSize = 13
			lb.TextColor3 = Colors.Text
			lb.Text = "Load"
			lb.ZIndex = 45005
			lb.Parent = row
			local db = Instance.new("TextButton")
			db.AutoButtonColor = false
			db.BackgroundColor3 = Colors.Error
			db.BorderSizePixel = 0
			db.AnchorPoint = Vector2.new(1, 0.5)
			db.Position = UDim2.new(1, -6, 0.5, 0)
			db.Size = UDim2.fromOffset(26, 26)
			db.FontFace = UIFont
			db.TextSize = 14
			db.TextColor3 = Colors.Text
			db.Text = "X"
			db.ZIndex = 45005
			db.Parent = row
			local function upd()
				check.BackgroundColor3 = selected[entry.name] and Colors.Accent or Colors.Action
			end
			upd()
			check.MouseButton1Click:Connect(function()
				if selected[entry.name] then selected[entry.name] = nil else selected[entry.name] = true end
				upd()
			end)
			lb.MouseEnter:Connect(function() lb.BackgroundColor3 = Colors.ActionHover end)
			lb.MouseLeave:Connect(function() lb.BackgroundColor3 = Colors.Action end)
			lb.MouseButton1Click:Connect(function()
				playButtonSound()
				local n, err = applyFastFlags(entry.flags)
				if err then notifyError("Failed: " .. err)
				else notifyEnabled("Loaded " .. n .. " flags from " .. entry.name) end
			end)
			db.MouseEnter:Connect(function() db.BackgroundColor3 = Color3.fromRGB(255, 80, 80) end)
			db.MouseLeave:Connect(function() db.BackgroundColor3 = Colors.Error end)
			db.MouseButton1Click:Connect(function()
				playButtonSound()
				if entry.instance and entry.instance.Parent then
					entry.instance:Destroy()
					notifyWarning("Deleted flags: " .. entry.name)
					task.defer(refresh)
				end
			end)
		end
	end
	importBtn.MouseEnter:Connect(function() importBtn.BackgroundColor3 = Colors.ToggleOnHover end)
	importBtn.MouseLeave:Connect(function() importBtn.BackgroundColor3 = Colors.Accent end)
	importBtn.MouseButton1Click:Connect(function()
		playButtonSound()
		local name = importName.Text:gsub("%s+", "_")
		if name == "" then notifyError("Enter a name"); return end
		local raw = importJson.Text
		if raw == "" then notifyError("Paste JSON"); return end
		local ok, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(decoded) ~= "table" then notifyError("Invalid JSON") return end
		local folder = findLoaderFolder() or ensureFastFlagsFolder()
		if not folder then notifyError("Could not create folder"); return end
		local existing = folder:FindFirstChild(name)
		if existing then existing:Destroy() end
		local sv = Instance.new("StringValue")
		sv.Name = name
		sv.Value = raw
		sv.Parent = folder
		notifyEnabled("Imported " .. name)
		importName.Text = ""
		importJson.Text = ""
		task.defer(refresh)
	end)
	local la = Instance.new("TextButton")
	la.AutoButtonColor = false
	la.BackgroundColor3 = Colors.Accent
	la.BorderSizePixel = 0
	la.Position = UDim2.new(0, 12, 1, -60)
	la.Size = UDim2.new(1, -136, 0, 40)
	la.FontFace = UIFont
	la.TextSize = 15
	la.TextColor3 = Colors.Text
	la.Text = "Load Selected"
	la.ZIndex = 45006
	la.Parent = w
	local rf = Instance.new("TextButton")
	rf.AutoButtonColor = false
	rf.BackgroundColor3 = Colors.Action
	rf.BorderSizePixel = 0
	rf.AnchorPoint = Vector2.new(1, 0)
	rf.Position = UDim2.new(1, -12, 1, -60)
	rf.Size = UDim2.fromOffset(112, 40)
	rf.FontFace = UIFont
	rf.TextSize = 15
	rf.TextColor3 = Colors.Text
	rf.Text = "Refresh"
	rf.ZIndex = 45006
	rf.Parent = w
	rf.MouseButton1Click:Connect(function() playButtonSound() refresh() end)
	la.MouseButton1Click:Connect(function()
		playButtonSound()
		local total = 0
		local folder = findLoaderFolder()
		for name in pairs(selected) do
			for _, e in ipairs(getFlagsFromFolder(folder)) do
				if e.name == name then
					local n = applyFastFlags(e.flags)
					total = total + n
					break
				end
			end
		end
		if total > 0 then notifyEnabled("Loaded " .. total .. " flags total")
		else notifyWarning("No flags selected") end
	end)
	task.defer(refresh)
end

local function createProfilesWindow()
	if profilesWindow then profilesWindow.Visible = not profilesWindow.Visible return end
	local wx, wy = getPosition("profilesWindow", 660, 100)
	local w = Instance.new("Frame")
	w.Name = "ProfilesWindow"
	w.BackgroundColor3 = Colors.Panel
	w.BorderSizePixel = 0
	w.Size = UDim2.fromOffset(320, 500)
	w.Position = UDim2.fromOffset(wx, wy)
	w.ClipsDescendants = true
	w.ZIndex = 46000
	w.Parent = screenGui
	profilesWindow = w
	local h = Instance.new("TextButton")
	h.AutoButtonColor = false
	h.BackgroundColor3 = Colors.Panel
	h.BorderSizePixel = 0
	h.Size = UDim2.new(1, 0, 0, 40)
	h.FontFace = UIFont
	h.TextSize = 18
	h.TextColor3 = Colors.Text
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = "  Profiles"
	h.ZIndex = 46001
	h.Parent = w
	local cb = Instance.new("TextButton")
	cb.AutoButtonColor = false
	cb.BackgroundTransparency = 1
	cb.Size = UDim2.fromOffset(40, 40)
	cb.AnchorPoint = Vector2.new(1, 0)
	cb.Position = UDim2.new(1, 0, 0, 0)
	cb.FontFace = UIFont
	cb.TextSize = 20
	cb.TextColor3 = Colors.MutedText
	cb.Text = "X"
	cb.ZIndex = 46002
	cb.Parent = h
	cb.MouseEnter:Connect(function() cb.TextColor3 = Colors.Text end)
	cb.MouseLeave:Connect(function() cb.TextColor3 = Colors.MutedText end)
	cb.MouseButton1Click:Connect(function() w.Visible = false end)
	makeDraggable(w, h, "profilesWindow", false)
	local nr = Instance.new("Frame")
	nr.BackgroundTransparency = 1
	nr.Position = UDim2.fromOffset(12, 48)
	nr.Size = UDim2.new(1, -24, 0, 34)
	nr.ZIndex = 46003
	nr.Parent = w
	local ni = Instance.new("TextBox")
	ni.BackgroundColor3 = Colors.ToggleOff
	ni.BorderSizePixel = 0
	ni.Size = UDim2.new(1, -84, 1, 0)
	ni.FontFace = UIFont
	ni.TextSize = 14
	ni.TextColor3 = Colors.Text
	ni.PlaceholderText = "New profile name..."
	ni.PlaceholderColor3 = Colors.MutedText
	ni.Text = ""
	ni.ClearTextOnFocus = false
	ni.ZIndex = 46004
	ni.Parent = nr
	local sb = Instance.new("TextButton")
	sb.AutoButtonColor = false
	sb.BackgroundColor3 = Colors.Accent
	sb.BorderSizePixel = 0
	sb.AnchorPoint = Vector2.new(1, 0)
	sb.Position = UDim2.new(1, 0, 0, 0)
	sb.Size = UDim2.fromOffset(76, 34)
	sb.FontFace = UIFont
	sb.TextSize = 14
	sb.TextColor3 = Colors.Text
	sb.Text = "Save"
	sb.ZIndex = 46004
	sb.Parent = nr
	local previewLabel = Instance.new("TextLabel")
	previewLabel.BackgroundTransparency = 1
	previewLabel.Position = UDim2.fromOffset(12, 86)
	previewLabel.Size = UDim2.new(1, -24, 0, 18)
	previewLabel.FontFace = UIFont
	previewLabel.TextSize = 11
	previewLabel.TextColor3 = Colors.MutedText
	previewLabel.TextXAlignment = Enum.TextXAlignment.Left
	previewLabel.TextTruncate = Enum.TextTruncate.AtEnd
	previewLabel.Text = ""
	previewLabel.ZIndex = 46003
	previewLabel.Parent = w
	local function updatePreview()
		local count, list = countEnabledFeatures({features = config.features})
		if count == 0 then previewLabel.Text = "Nothing enabled (profile will be empty)"
		elseif count <= 3 then previewLabel.Text = "Saves " .. count .. " enabled: " .. table.concat(list, ", ")
		else previewLabel.Text = "Saves " .. count .. " enabled features" end
	end
	updatePreview()
	local pl = Instance.new("ScrollingFrame")
	pl.BackgroundTransparency = 1
	pl.BorderSizePixel = 0
	pl.Position = UDim2.fromOffset(12, 108)
	pl.Size = UDim2.new(1, -24, 1, -168)
	pl.ScrollBarThickness = 4
	pl.ScrollBarImageColor3 = Colors.Accent
	pl.ScrollingDirection = Enum.ScrollingDirection.Y
	pl.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pl.CanvasSize = UDim2.fromOffset(0, 0)
	pl.ZIndex = 46003
	pl.Parent = w
	local pll = Instance.new("UIListLayout")
	pll.SortOrder = Enum.SortOrder.LayoutOrder
	pll.Padding = UDim.new(0, 4)
	pll.Parent = pl
	local refresh
	refresh = function()
		for _, c in ipairs(pl:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
		local list = listProfiles()
		if #list == 0 then
			local e = Instance.new("TextLabel")
			e.BackgroundTransparency = 1
			e.Size = UDim2.new(1, 0, 0, 40)
			e.FontFace = UIFont
			e.TextSize = 14
			e.TextColor3 = Colors.MutedText
			e.Text = "No profiles yet."
			e.LayoutOrder = 1
			e.Parent = pl
			return
		end
		for i, entry in ipairs(list) do
			local row = Instance.new("Frame")
			row.BackgroundColor3 = Colors.Setting
			row.BorderSizePixel = 0
			row.Size = UDim2.new(1, 0, 0, 42)
			row.LayoutOrder = i
			row.ZIndex = 46004
			row.Parent = pl
			local nl = Instance.new("TextLabel")
			nl.BackgroundTransparency = 1
			nl.Position = UDim2.fromOffset(8, 0)
			nl.Size = UDim2.new(1, -110, 1, 0)
			nl.FontFace = UIFont
			nl.TextSize = 15
			nl.TextColor3 = Colors.Text
			nl.TextXAlignment = Enum.TextXAlignment.Left
			nl.TextTruncate = Enum.TextTruncate.AtEnd
			nl.Text = entry.name
			nl.ZIndex = 46005
			nl.Parent = row
			local lb = Instance.new("TextButton")
			lb.AutoButtonColor = false
			lb.BackgroundColor3 = Colors.Accent
			lb.BorderSizePixel = 0
			lb.AnchorPoint = Vector2.new(1, 0.5)
			lb.Position = UDim2.new(1, -36, 0.5, 0)
			lb.Size = UDim2.fromOffset(56, 26)
			lb.FontFace = UIFont
			lb.TextSize = 13
			lb.TextColor3 = Colors.Text
			lb.Text = "Load"
			lb.ZIndex = 46005
			lb.Parent = row
			local db = Instance.new("TextButton")
			db.AutoButtonColor = false
			db.BackgroundColor3 = Colors.Error
			db.BorderSizePixel = 0
			db.AnchorPoint = Vector2.new(1, 0.5)
			db.Position = UDim2.new(1, -6, 0.5, 0)
			db.Size = UDim2.fromOffset(26, 26)
			db.FontFace = UIFont
			db.TextSize = 14
			db.TextColor3 = Colors.Text
			db.Text = "X"
			db.ZIndex = 46005
			db.Parent = row
			lb.MouseEnter:Connect(function() lb.BackgroundColor3 = Colors.ToggleOnHover end)
			lb.MouseLeave:Connect(function() lb.BackgroundColor3 = Colors.Accent end)
			lb.MouseButton1Click:Connect(function()
				playButtonSound()
				local d = readProfile(entry.name)
				if not d then notifyError("Failed to read profile: " .. entry.name); return end
				local ok = applyProfileData(d)
				if ok then notifyEnabled("Loaded profile: " .. entry.name)
				else notifyError("Failed to apply profile") end
			end)
			db.MouseEnter:Connect(function() db.BackgroundColor3 = Color3.fromRGB(255, 80, 80) end)
			db.MouseLeave:Connect(function() db.BackgroundColor3 = Colors.Error end)
			db.MouseButton1Click:Connect(function()
				playButtonSound()
				if deleteProfile(entry.name) then
					notifyWarning("Deleted profile: " .. entry.name)
					task.defer(refresh)
				else notifyError("Delete failed") end
			end)
		end
	end
	sb.MouseButton1Click:Connect(function()
		playButtonSound()
		local name = ni.Text:gsub("%s+", "_")
		if name == "" then notifyError("Enter a profile name"); return end
		local ok, err = saveProfile(name)
		if ok then
			local count = countEnabledFeatures({features = config.features})
			notifyEnabled("Saved '" .. name .. "' (" .. count .. " enabled)")
			ni.Text = ""
			refresh()
			updatePreview()
		else notifyError("Save failed: " .. tostring(err)) end
	end)
	UserInputService.InputBegan:Connect(function(input, gp)
		if w.Visible then task.defer(updatePreview) end
	end)
	task.defer(refresh)
end

local function createSettingsWindow()
	if settingsWindow then settingsWindow.Visible = not settingsWindow.Visible settingsVisible = settingsWindow.Visible return end
	local wx, wy = getPosition("settingsWindow", 50, 100)
	local w = Instance.new("Frame")
	w.Name = "SettingsWindow"
	w.BackgroundColor3 = Colors.Panel
	w.BorderSizePixel = 0
	w.Size = UDim2.fromOffset(320, 620)
	w.Position = UDim2.fromOffset(wx, wy)
	w.ClipsDescendants = true
	w.ZIndex = 40000
	w.Parent = screenGui
	local h = Instance.new("TextButton")
	h.AutoButtonColor = false
	h.BackgroundColor3 = Colors.Panel
	h.BorderSizePixel = 0
	h.Size = UDim2.new(1, 0, 0, 40)
	h.FontFace = UIFont
	h.TextSize = 20
	h.TextColor3 = Colors.Text
	h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = "  Settings"
	h.ZIndex = 40001
	h.Parent = w
	local cb = Instance.new("TextButton")
	cb.AutoButtonColor = false
	cb.BackgroundTransparency = 1
	cb.Size = UDim2.fromOffset(40, 40)
	cb.AnchorPoint = Vector2.new(1, 0)
	cb.Position = UDim2.new(1, 0, 0, 0)
	cb.FontFace = UIFont
	cb.TextSize = 20
	cb.TextColor3 = Colors.MutedText
	cb.Text = "X"
	cb.ZIndex = 40002
	cb.Parent = h
	cb.MouseEnter:Connect(function() cb.TextColor3 = Colors.Text end)
	cb.MouseLeave:Connect(function() cb.TextColor3 = Colors.MutedText end)
	cb.MouseButton1Click:Connect(function() w.Visible = false settingsVisible = false end)
	makeDraggable(w, h, "settingsWindow", false)
	local content = Instance.new("ScrollingFrame")
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Position = UDim2.fromOffset(12, 48)
	content.Size = UDim2.new(1, -24, 1, -58)
	content.ScrollBarThickness = 4
	content.ScrollBarImageColor3 = Colors.Accent
	content.ScrollingDirection = Enum.ScrollingDirection.Y
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.fromOffset(0, 0)
	content.ZIndex = 40003
	content.Parent = w
	local cl = Instance.new("UIListLayout")
	cl.SortOrder = Enum.SortOrder.LayoutOrder
	cl.Padding = UDim.new(0, 10)
	cl.Parent = content
	local function addLabel(text, order)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, 22)
		l.FontFace = UIFont
		l.TextSize = 17
		l.TextColor3 = Colors.Text
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = text
		l.LayoutOrder = order
		l.Parent = content
	end
	local function addCheck(labelText, getter, setter, order, tip)
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Size = UDim2.new(1, 0, 0, 34)
		f.LayoutOrder = order
		f.Parent = content
		local c = Instance.new("TextButton")
		c.AutoButtonColor = false
		c.BackgroundColor3 = getter() and Colors.Accent or Colors.Action
		c.BorderSizePixel = 0
		c.Position = UDim2.fromOffset(0, 3)
		c.Size = UDim2.fromOffset(26, 26)
		c.Text = ""
		c.Parent = f
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromOffset(34, 0)
		l.Size = UDim2.new(1, -34, 1, 0)
		l.FontFace = UIFont
		l.TextSize = 17
		l.TextColor3 = Colors.Text
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = labelText
		l.Parent = f
		addTooltip(l, tip or "Toggle")
		local function upd() c.BackgroundColor3 = getter() and Colors.Accent or Colors.Action end
		c.MouseEnter:Connect(function() c.BackgroundColor3 = getter() and Colors.ToggleOnHover or Colors.ToggleOffHover end)
		c.MouseLeave:Connect(function() upd() end)
		c.MouseButton1Click:Connect(function()
			playButtonSound(); setter(not getter()); upd(); saveConfig()
		end)
		addTooltip(c, tip or "Toggle")
	end
	local function addTextRow(labelText, getter, setter, order, ph)
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Size = UDim2.new(1, 0, 0, 34)
		f.LayoutOrder = order
		f.Parent = content
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(0.4, 0, 1, 0)
		l.FontFace = UIFont
		l.TextSize = 15
		l.TextColor3 = Colors.Text
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = labelText
		l.Parent = f
		local tb = Instance.new("TextBox")
		tb.BackgroundColor3 = Colors.ToggleOff
		tb.BorderSizePixel = 0
		tb.AnchorPoint = Vector2.new(1, 0.5)
		tb.Position = UDim2.new(1, 0, 0.5, 0)
		tb.Size = UDim2.fromOffset(150, 28)
		tb.FontFace = UIFont
		tb.TextSize = 15
		tb.TextColor3 = Colors.Text
		tb.PlaceholderText = ph or ""
		tb.Text = getter()
		tb.ClearTextOnFocus = false
		tb.Parent = f
		tb.FocusLost:Connect(function()
			local t = tb.Text:gsub("%s+", "")
			if t == "" then t = ph or "0" end
			tb.Text = t; setter(t); saveConfig()
		end)
	end
	local function addVolSlider(order)
		local f = Instance.new("Frame")
		f.BackgroundTransparency = 1
		f.Size = UDim2.new(1, 0, 0, 50)
		f.LayoutOrder = order
		f.Parent = content
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0, 20)
		l.FontFace = UIFont
		l.TextSize = 15
		l.TextColor3 = Colors.Text
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Text = "Volume (" .. math.floor(config.soundVolume * 100) .. "%)"
		l.Parent = f
		local s = Instance.new("Frame")
		s.BackgroundColor3 = Colors.ToggleOff
		s.BorderSizePixel = 0
		s.Position = UDim2.fromOffset(0, 26)
		s.Size = UDim2.new(1, 0, 0, 14)
		s.Parent = f
		local fill = Instance.new("Frame")
		fill.BackgroundColor3 = Colors.Accent
		fill.BorderSizePixel = 0
		fill.Size = UDim2.new(config.soundVolume, 0, 1, 0)
		fill.Parent = s
		local knob = Instance.new("TextButton")
		knob.AutoButtonColor = false
		knob.BackgroundColor3 = Colors.Accent
		knob.BorderSizePixel = 0
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.Position = UDim2.new(config.soundVolume, 0, 0.5, 0)
		knob.Size = UDim2.fromOffset(14, 18)
		knob.Text = ""
		knob.Parent = s
		local dr = false
		local function upd(p)
			p = math.clamp(p, 0, 1)
			config.soundVolume = p
			soundObj.Volume = p
			menuSoundObj.Volume = p
			fill.Size = UDim2.new(p, 0, 1, 0)
			knob.Position = UDim2.new(p, 0, 0.5, 0)
			l.Text = "Volume (" .. math.floor(p * 100) .. "%)"
			saveConfig()
		end
		knob.MouseButton1Down:Connect(function() dr = true end)
		s.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			dr = true
			local mp = UserInputService:GetMouseLocation()
			local pos = mp.X - s.AbsolutePosition.X
			upd(pos / s.AbsoluteSize.X)
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dr or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			if not s.Parent then return end
			local mp = UserInputService:GetMouseLocation()
			local pos = mp.X - s.AbsolutePosition.X
			upd(pos / s.AbsoluteSize.X)
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dr = false end
		end)
	end
	local function addBtn(labelText, onClick, order, primary)
		local b = Instance.new("TextButton")
		b.AutoButtonColor = false
		b.BackgroundColor3 = primary and Colors.Accent or Colors.Action
		b.BorderSizePixel = 0
		b.Size = UDim2.new(1, 0, 0, 38)
		b.FontFace = UIFont
		b.TextSize = 16
		b.TextColor3 = Colors.Text
		b.Text = labelText
		b.LayoutOrder = order
		b.Parent = content
		b.MouseEnter:Connect(function() b.BackgroundColor3 = primary and Colors.ToggleOnHover or Colors.ActionHover end)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = primary and Colors.Accent or Colors.Action end)
		b.MouseButton1Click:Connect(function() playButtonSound() onClick() end)
		return b
	end
	addLabel("Button Sounds", 1)
	addCheck("Button Sounds", function() return config.guiSounds end, function(v) config.guiSounds = v end, 2, "Play sounds on button clicks")
	addTextRow("Sound ID", function() return config.soundId end, function(v) config.soundId = v end, 3, "0")
	addLabel("Open / Close Sounds", 4)
	addCheck("Open/Close Sounds", function() return config.menuSounds end, function(v) config.menuSounds = v end, 5, "Play on menu open/close")
	addTextRow("Open ID", function() return config.openSoundId end, function(v) config.openSoundId = v end, 6, "0")
	addTextRow("Close ID", function() return config.closeSoundId end, function(v) config.closeSoundId = v end, 7, "0")
	addVolSlider(8)
	addLabel("Visual Settings", 9)
	addCheck("Blur Background", function()
		return getSetting("noxvape", "blur", "enabled", false)
	end, function(v)
		setSetting("noxvape", "blur", "enabled", v)
		updateBlur()
	end, 10, "Blur background when GUI open")
	addLabel("Menu Color", 11)
	local currentMenuColor = Color3.new(config.menuColor.r, config.menuColor.g, config.menuColor.b)
	local colorPickerFrame = buildColorPickerRow(content, 12, currentMenuColor, function(c)
		applyMenuColorToGui(c)
	end, "Accent Color")
	addBtn("Revert to Default", function()
		applyMenuColorToGui(DEFAULT_MENU_COLOR)
		notifyEnabled("Menu color reset to default")
	end, 13, false)
	addLabel("Managers", 14)
	addBtn("Fast Flag Manager", function() createFastFlagWindow() end, 15, false)
	addBtn("Profiles", function() createProfilesWindow() end, 16, false)
	addLabel("Other", 17)
	local sf = Instance.new("Frame")
	sf.BackgroundTransparency = 1
	sf.Size = UDim2.new(1, 0, 0, 42)
	sf.LayoutOrder = 18
	sf.Parent = content
	local sd = Instance.new("TextButton")
	sd.AutoButtonColor = false
	sd.BackgroundColor3 = Colors.Action
	sd.BorderSizePixel = 0
	sd.Size = UDim2.new(1, 0, 1, 0)
	sd.FontFace = UIFont
	sd.TextSize = 17
	sd.TextColor3 = Colors.Text
	sd.Text = "Self Destruct"
	sd.Parent = sf
	sd.MouseEnter:Connect(function() tw(sd, {BackgroundColor3 = Colors.ActionHover}, 0.08) end)
	sd.MouseLeave:Connect(function() tw(sd, {BackgroundColor3 = Colors.Action}, 0.08) end)
	sd.MouseButton1Click:Connect(function() playButtonSound() selfDestruct() end)
	addTooltip(sd, "Permanently destroy the GUI")
	settingsWindow = w
	settingsVisible = true
end

local function init()
	ensureFastFlagsFolder()
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 10001
	root.Parent = screenGui

	for ci, catDef in ipairs(_categories) do
		local catName = catDef.name
		local items = catDef.items
		ensureCategoryData(catName)
		local sx, sy = getPosition(catName, 240 + ((ci - 1) * 218), 75)
		local card = Instance.new("Frame")
		card.Name = catName
		card.BackgroundColor3 = Colors.Panel
		card.BorderSizePixel = 0
		card.Size = UDim2.fromOffset(210, 560)
		card.Position = UDim2.fromOffset(sx, sy)
		card.Visible = config.tabs[catName] == true
		card.ClipsDescendants = true
		card.ZIndex = 11000 + ci
		card.Parent = root
		categoryFrames[catName] = card
		categoryStates[catName] = card.Visible
		local hdr = Instance.new("TextButton")
		hdr.Name = "Header"
		hdr.AutoButtonColor = false
		hdr.BackgroundColor3 = Colors.Panel
		hdr.BorderSizePixel = 0
		hdr.Size = UDim2.new(1, 0, 0, 46)
		hdr.Text = ""
		hdr.ZIndex = 11020 + ci
		hdr.Parent = card
		local cl2 = Instance.new("TextLabel")
		cl2.BackgroundTransparency = 1
		cl2.Size = UDim2.new(1, 0, 1, 0)
		cl2.FontFace = UIFont
		cl2.TextSize = 18
		cl2.TextColor3 = Colors.Text
		cl2.TextXAlignment = Enum.TextXAlignment.Center
		cl2.TextYAlignment = Enum.TextYAlignment.Center
		cl2.Text = catName
		cl2.ZIndex = 11021 + ci
		cl2.Parent = hdr
		makeDraggable(card, hdr, catName, false)
		hdr.MouseEnter:Connect(function() tw(hdr, {BackgroundColor3 = Colors.PanelHover}, 0.08) end)
		hdr.MouseLeave:Connect(function() tw(hdr, {BackgroundColor3 = Colors.Panel}, 0.08) end)
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Buttons"
		scroll.BackgroundTransparency = 1
		scroll.BorderSizePixel = 0
		scroll.Position = UDim2.fromOffset(8, 54)
		scroll.Size = UDim2.new(1, -16, 1, -62)
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = Colors.Accent
		scroll.ScrollingDirection = Enum.ScrollingDirection.Y
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.fromOffset(0, 0)
		scroll.ZIndex = 11010 + ci
		scroll.Parent = card
		local bl = Instance.new("UIListLayout")
		bl.SortOrder = Enum.SortOrder.LayoutOrder
		bl.Padding = UDim.new(0, 3)
		bl.Parent = scroll
		local sp = Instance.new("UIPadding")
		sp.PaddingBottom = UDim.new(0, 8)
		sp.Parent = scroll

		for ii, item in ipairs(items) do
			local itemName = item.name
			local isToggle = item.toggle
			local description = item.description
			local action = item.action or function() end
			local extraSettings = item.settings
			local currentState = false
			if isToggle then currentState = getFeatureState(catName, itemName) end
			local wrapper = Instance.new("Frame")
			wrapper.Name = itemName .. "_Wrapper"
			wrapper.BackgroundTransparency = 1
			wrapper.Size = UDim2.new(1, 0, 0, 36)
			wrapper.AutomaticSize = Enum.AutomaticSize.Y
			wrapper.LayoutOrder = ii
			wrapper.ZIndex = 11100 + ci
			wrapper.Parent = scroll
			local button = Instance.new("TextButton")
			button.Name = itemName
			button.AutoButtonColor = false
			button.BackgroundColor3 = isToggle and (currentState and Colors.Accent or Colors.Action) or Colors.Action
			button.BorderSizePixel = 0
			button.Size = UDim2.new(1, 0, 0, 36)
			button.Text = ""
			button.ZIndex = 11110 + ci
			button.Parent = wrapper
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Name = "ModuleName"
			nameLabel.BackgroundTransparency = 1
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.FontFace = UIFont
			nameLabel.TextSize = 17
			nameLabel.TextColor3 = Colors.Text
			nameLabel.TextXAlignment = Enum.TextXAlignment.Center
			nameLabel.TextYAlignment = Enum.TextYAlignment.Center
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.Text = itemName
			nameLabel.ZIndex = 11111 + ci
			nameLabel.Parent = button
			local settingsFrame = Instance.new("Frame")
			settingsFrame.Name = "Settings"
			settingsFrame.BackgroundColor3 = Colors.Setting
			settingsFrame.BorderSizePixel = 0
			settingsFrame.Position = UDim2.fromOffset(0, 36)
			settingsFrame.Size = UDim2.new(1, 0, 0, 0)
			settingsFrame.AutomaticSize = Enum.AutomaticSize.Y
			settingsFrame.Visible = false
			settingsFrame.ZIndex = 11105 + ci
			settingsFrame.Parent = wrapper
			local sp2 = Instance.new("UIPadding")
			sp2.PaddingTop = UDim.new(0, 6)
			sp2.PaddingBottom = UDim.new(0, 6)
			sp2.PaddingLeft = UDim.new(0, 8)
			sp2.PaddingRight = UDim.new(0, 8)
			sp2.Parent = settingsFrame
			local sl = Instance.new("UIListLayout")
			sl.SortOrder = Enum.SortOrder.LayoutOrder
			sl.Padding = UDim.new(0, 4)
			sl.Parent = settingsFrame
			local hovering = false
			local function refreshColor()
				if isToggle then
					button.BackgroundColor3 = currentState and Colors.Accent or Colors.Action
				else
					button.BackgroundColor3 = hovering and Colors.ActionHover or Colors.Action
				end
			end
			button.MouseEnter:Connect(function() hovering = true refreshColor() end)
			button.MouseLeave:Connect(function() hovering = false refreshColor() end)
			addTooltip(button, description)
			local function performToggle()
				if not isToggle then
					local ok = pcall(action)
					if not ok then warn("[NoxLib] action failed") end
					return
				end
				local newState = not currentState
				local ok, result = pcall(action, newState)
				local success = ok and result ~= false
				if success then
					currentState = newState
					config.features[catName][itemName] = currentState
					refreshColor()
					if currentState then notifyEnabled(itemName .. " enabled")
					else notifyWarning(itemName .. " disabled") end
					saveConfig()
				else refreshColor() end
			end
			button.MouseButton1Click:Connect(function() playButtonSound() performToggle() end)
			button.MouseButton2Click:Connect(function()
				hideTooltip()
				settingsFrame.Visible = not settingsFrame.Visible
			end)
			local kbr = Instance.new("Frame")
			kbr.BackgroundTransparency = 1
			kbr.Size = UDim2.new(1, 0, 0, 32)
			kbr.LayoutOrder = 1
			kbr.Parent = settingsFrame
			local kbl = Instance.new("TextLabel")
			kbl.BackgroundTransparency = 1
			kbl.Size = UDim2.new(0.45, 0, 1, 0)
			kbl.FontFace = UIFont
			kbl.TextSize = 14
			kbl.TextColor3 = Colors.Text
			kbl.TextXAlignment = Enum.TextXAlignment.Left
			kbl.Text = "Bind"
			kbl.Parent = kbr
			addTooltip(kbl, "Click to bind a key")
			local kbb = Instance.new("TextButton")
			kbb.AutoButtonColor = false
			kbb.BackgroundColor3 = Colors.Action
			kbb.BorderSizePixel = 0
			kbb.AnchorPoint = Vector2.new(1, 0.5)
			kbb.Position = UDim2.new(1, 0, 0.5, 0)
			kbb.Size = UDim2.fromOffset(96, 28)
			kbb.FontFace = UIFont
			kbb.TextSize = 16
			kbb.TextColor3 = Colors.Text
			kbb.TextXAlignment = Enum.TextXAlignment.Center
			kbb.TextYAlignment = Enum.TextYAlignment.Center
			kbb.Text = getKeybind(catName, itemName) or "NONE"
			kbb.Parent = kbr
			kbb.MouseButton1Click:Connect(function()
				playButtonSound()
				if waitingForBind then
					waitingForBind.button.Text = getKeybind(waitingForBind.category, waitingForBind.feature) or "NONE"
					waitingForBind.button.BackgroundColor3 = Colors.Action
				end
				waitingForBind = {category = catName, feature = itemName, button = kbb}
				kbb.Text = "Press key..."
				kbb.BackgroundColor3 = Colors.Accent
			end)
			if type(extraSettings) == "table" then
				for si, setting in ipairs(extraSettings) do
					if type(setting) ~= "table" then continue end
					local st = tostring(setting.type or "")
					local sn = tostring(setting.name or setting.key or ("Setting " .. si))
					local sk = tostring(setting.key or setting.name or ("setting" .. si))
					local order = 10 + si
					if st == "slider" then
						local mn = tonumber(setting.min) or 0
						local mx = tonumber(setting.max) or 100
						if mx < mn then mn, mx = mx, mn end
						local df = tonumber(setting.default) or mn
						df = math.clamp(df, mn, mx)
						local step = tonumber(setting.step) or 1
						if step <= 0 then step = 1 end
						local current = tonumber(getSetting(catName, itemName, sk, df)) or df
						local function rTS(v)
							v = math.clamp(v, mn, mx)
							local s = math.floor(((v - mn) / step) + 0.5)
							return math.clamp(mn + s * step, mn, mx)
						end
						current = rTS(current)
						local function fmt(v)
							if step >= 1 and step == math.floor(step) then return tostring(math.floor(v + 0.5)) end
							local d = 0; local t = step
							while d < 10 and math.abs(t - math.floor(t)) > 0.000001 do t *= 10; d += 1 end
							return string.format("%." .. d .. "f", v)
						end
						local f = Instance.new("Frame")
						f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 0, 48)
						f.LayoutOrder = order; f.Parent = settingsFrame
						local l = Instance.new("TextLabel")
						l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 0, 18)
						l.FontFace = UIFont; l.TextSize = 14; l.TextColor3 = Colors.Text
						l.TextXAlignment = Enum.TextXAlignment.Left
						l.Text = sn .. " (" .. fmt(current) .. ")"; l.Parent = f
						local sb = Instance.new("Frame")
						sb.BackgroundColor3 = Colors.ToggleOff; sb.BorderSizePixel = 0
						sb.Position = UDim2.fromOffset(0, 24); sb.Size = UDim2.new(1, 0, 0, 14); sb.Parent = f
						local range = mx - mn
						local pct = range == 0 and 0 or math.clamp((current - mn) / range, 0, 1)
						local fill = Instance.new("Frame")
						fill.BackgroundColor3 = Colors.Accent; fill.BorderSizePixel = 0
						fill.Size = UDim2.new(pct, 0, 1, 0); fill.Parent = sb
						local knob = Instance.new("TextButton")
						knob.AutoButtonColor = false; knob.BackgroundColor3 = Colors.Accent
						knob.BorderSizePixel = 0; knob.AnchorPoint = Vector2.new(0.5, 0.5)
						knob.Position = UDim2.new(pct, 0, 0.5, 0)
						knob.Size = UDim2.fromOffset(12, 16); knob.Text = ""; knob.Parent = sb
						local drg = false
						local function upd(v)
							v = rTS(v); setSetting(catName, itemName, sk, v)
							local p = range == 0 and 0 or math.clamp((v - mn) / range, 0, 1)
							fill.Size = UDim2.new(p, 0, 1, 0)
							knob.Position = UDim2.new(p, 0, 0.5, 0)
							l.Text = sn .. " (" .. fmt(v) .. ")"
							safeCall(setting.onChanged or setting.action, v)
						end
						knob.MouseButton1Down:Connect(function() drg = true end)
						sb.InputBegan:Connect(function(input)
							if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
							drg = true
							local wdt = sb.AbsoluteSize.X
							if wdt > 0 then
								local mp = UserInputService:GetMouseLocation()
								local p = mp.X - sb.AbsolutePosition.X
								upd(mn + math.clamp(p / wdt, 0, 1) * range)
							end
						end)
						local sc
						sc = UserInputService.InputChanged:Connect(function(input)
							if not drg or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
							if not sb.Parent then if sc then sc:Disconnect() end return end
							local wdt = sb.AbsoluteSize.X
							if wdt <= 0 then return end
							local mp = UserInputService:GetMouseLocation()
							local p = mp.X - sb.AbsolutePosition.X
							upd(mn + math.clamp(p / wdt, 0, 1) * range)
						end)
						UserInputService.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then drg = false end
						end)
					elseif st == "colorpicker" then
						local df = typeof(setting.default) == "Color3" and setting.default or Color3.fromRGB(255, 255, 255)
						local cur = getSetting(catName, itemName, sk, df)
						if typeof(cur) ~= "Color3" then cur = df end
						buildColorPickerRow(settingsFrame, order, cur, function(c)
							setSetting(catName, itemName, sk, c)
							safeCall(setting.onChanged or setting.action, c)
						end, sn)
					elseif st == "dropdown" then
						local options = type(setting.options) == "table" and setting.options or {}
						local df = setting.default or options[1] or "None"
						local cur = getSetting(catName, itemName, sk, df)
						local f = Instance.new("Frame")
						f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 0, 38)
						f.LayoutOrder = order; f.Parent = settingsFrame
						local l = Instance.new("TextLabel")
						l.BackgroundTransparency = 1; l.Size = UDim2.new(0.5, 0, 1, 0)
						l.FontFace = UIFont; l.TextSize = 16; l.TextColor3 = Colors.Text
						l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = sn; l.Parent = f
						local dd = Instance.new("TextButton")
						dd.AutoButtonColor = false; dd.BackgroundColor3 = Colors.Action
						dd.BorderSizePixel = 0; dd.AnchorPoint = Vector2.new(1, 0)
						dd.Position = UDim2.new(1, 0, 0, 0)
						dd.Size = UDim2.fromOffset(120, 38); dd.FontFace = UIFont
						dd.TextSize = 15; dd.TextColor3 = Colors.Text
						dd.TextTruncate = Enum.TextTruncate.AtEnd
						dd.Text = tostring(cur); dd.ZIndex = 20050; dd.Parent = f
						local dc = Instance.new("Frame")
						dc.BackgroundColor3 = Colors.Setting; dc.BorderSizePixel = 0
						dc.Size = UDim2.new(1, 0, 0, 0); dc.AutomaticSize = Enum.AutomaticSize.Y
						dc.LayoutOrder = order + 100; dc.Visible = false
						dc.ZIndex = 20051; dc.Parent = settingsFrame
						local ol = Instance.new("UIListLayout")
						ol.SortOrder = Enum.SortOrder.LayoutOrder
						ol.Padding = UDim.new(0, 2); ol.Parent = dc
						local function closeDd() dc.Visible = false; dd.BackgroundColor3 = Colors.Action end
						for oi, opt in ipairs(options) do
							local ob = Instance.new("TextButton")
							ob.AutoButtonColor = false; ob.BackgroundColor3 = Colors.Action
							ob.BorderSizePixel = 0; ob.Size = UDim2.new(1, 0, 0, 34)
							ob.FontFace = UIFont; ob.TextSize = 15; ob.TextColor3 = Colors.Text
							ob.Text = tostring(opt); ob.LayoutOrder = oi
							ob.ZIndex = 20052; ob.Parent = dc
							ob.MouseEnter:Connect(function() ob.BackgroundColor3 = Colors.ActionHover end)
							ob.MouseLeave:Connect(function() ob.BackgroundColor3 = Colors.Action end)
							ob.MouseButton1Click:Connect(function()
								cur = opt
								dd.Text = tostring(cur)
								setSetting(catName, itemName, sk, cur)
								safeCall(setting.onChanged or setting.action, cur)
								closeDd()
							end)
						end
						dd.MouseEnter:Connect(function() dd.BackgroundColor3 = Colors.ActionHover end)
						dd.MouseLeave:Connect(function() if not dc.Visible then dd.BackgroundColor3 = Colors.Action end end)
						dd.MouseButton1Click:Connect(function()
							dc.Visible = not dc.Visible
							dd.BackgroundColor3 = dc.Visible and Colors.ActionHover or Colors.Action
						end)
					elseif st == "checkbox" then
						local df = setting.default == true
						local cur = getSetting(catName, itemName, sk, df) == true
						local f = Instance.new("Frame")
						f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 0, 38)
						f.LayoutOrder = order; f.Parent = settingsFrame
						local ck = Instance.new("TextButton")
						ck.AutoButtonColor = false
						ck.BackgroundColor3 = cur and Colors.ToggleOn or Colors.ToggleOff
						ck.BorderSizePixel = 0; ck.Position = UDim2.fromOffset(6, 4)
						ck.Size = UDim2.fromOffset(30, 30); ck.Text = ""; ck.Parent = f
						local l = Instance.new("TextLabel")
						l.BackgroundTransparency = 1; l.Position = UDim2.fromOffset(48, 0)
						l.Size = UDim2.new(1, -48, 1, 0); l.FontFace = UIFont
						l.TextSize = 16; l.TextColor3 = Colors.Text
						l.TextXAlignment = Enum.TextXAlignment.Left
						l.TextTruncate = Enum.TextTruncate.AtEnd
						l.Text = sn; l.Parent = f
						local function upd() ck.BackgroundColor3 = cur and Colors.ToggleOn or Colors.ToggleOff end
						ck.MouseEnter:Connect(function() ck.BackgroundColor3 = cur and Colors.ToggleOnHover or Colors.ToggleOffHover end)
						ck.MouseLeave:Connect(function() upd() end)
						ck.MouseButton1Click:Connect(function()
							cur = not cur
							upd()
							setSetting(catName, itemName, sk, cur)
							safeCall(setting.onChanged or setting.action, cur)
						end)
					elseif st == "textbox" then
						local f = Instance.new("Frame")
						f.BackgroundTransparency = 1; f.Size = UDim2.new(1, 0, 0, 34)
						f.LayoutOrder = order; f.Parent = settingsFrame
						local l = Instance.new("TextLabel")
						l.BackgroundTransparency = 1; l.Size = UDim2.new(0.4, 0, 1, 0)
						l.FontFace = UIFont; l.TextSize = 14; l.TextColor3 = Colors.Text
						l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = sn; l.Parent = f
						local tb = Instance.new("TextBox")
						tb.BackgroundColor3 = Colors.ToggleOff; tb.BorderSizePixel = 0
						tb.AnchorPoint = Vector2.new(1, 0.5); tb.Position = UDim2.new(1, 0, 0.5, 0)
						tb.Size = UDim2.fromOffset(140, 28); tb.FontFace = UIFont
						tb.TextSize = 14; tb.TextColor3 = Colors.Text
						tb.Text = tostring(getSetting(catName, itemName, sk, setting.default or ""))
						tb.ClearTextOnFocus = false; tb.Parent = f
						tb.FocusLost:Connect(function()
							setSetting(catName, itemName, sk, tb.Text)
							safeCall(setting.onChanged or setting.action, tb.Text)
						end)
					end
				end
			end
			buttonData[catName] = buttonData[catName] or {}
			buttonData[catName][itemName] = {
				button = button, wrapper = wrapper, settings = settingsFrame,
				isToggle = isToggle, keybindButton = kbb, action = action,
				getState = function() return currentState end,
				toggle = performToggle,
				setState = function(state, skipSave)
					currentState = state and true or false
					config.features[catName][itemName] = currentState
					refreshColor()
					if not skipSave then saveConfig() end
				end
			}
			if isToggle and currentState then
				local ok, result = pcall(action, true)
				if not ok or result == false then
					currentState = false
					config.features[catName][itemName] = false
					refreshColor()
					notifyWarning(itemName .. " disabled (condition not met)")
					saveConfig()
				end
			end
		end
	end

	local nx = tonumber(config.noxPosition.x) or 18
	local ny = tonumber(config.noxPosition.y) or 75
	tabPanel = Instance.new("Frame")
	tabPanel.Name = "noxvape"
	tabPanel.BackgroundColor3 = Colors.Panel
	tabPanel.BorderSizePixel = 0
	tabPanel.Size = UDim2.fromOffset(210, 560)
	tabPanel.Position = UDim2.fromOffset(nx, ny)
	tabPanel.ClipsDescendants = true
	tabPanel.ZIndex = 20000
	tabPanel.Parent = screenGui
	local th = Instance.new("TextButton")
	th.Name = "Header"
	th.AutoButtonColor = false
	th.BackgroundColor3 = Colors.Panel
	th.BorderSizePixel = 0
	th.Size = UDim2.new(1, 0, 0, 46)
	th.Text = ""
	th.ZIndex = 20001
	th.Parent = tabPanel
	local logo = Instance.new("ImageLabel")
	logo.BackgroundTransparency = 1
	logo.AnchorPoint = Vector2.new(0.5, 0.5)
	logo.Position = UDim2.fromScale(0.5, 0.5)
	logo.Size = UDim2.fromScale(1.4, 1.4)
	logo.ScaleType = Enum.ScaleType.Fit
	logo.ZIndex = 20002
	logo.Parent = th
	task.spawn(function()
		if type(request) == "function" and type(writefile) == "function" then
			local need = true
			if type(isfile) == "function" then need = not isfile(LOGO_FILE) end
			if need then
				pcall(function()
					local r = request({Url = LOGO_URL, Method = "GET"})
					if r and r.Success and r.Body then writefile(LOGO_FILE, r.Body) end
				end)
			end
		end
		task.wait(0.12)
		if type(isfile) == "function" and isfile(LOGO_FILE) then
			local ok, a = pcall(function() return getCustomAsset(LOGO_FILE) end)
			if ok and a then logo.Image = a end
		end
	end)
	makeDraggable(tabPanel, th, "noxvape", true)
	local ts = Instance.new("Frame")
	ts.BackgroundTransparency = 1
	ts.Position = UDim2.fromOffset(8, 54)
	ts.Size = UDim2.new(1, -16, 0, 450)
	ts.ZIndex = 20004
	ts.Parent = tabPanel
	local tl = Instance.new("UIListLayout")
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Padding = UDim.new(0, 3)
	tl.Parent = ts
	for i, catDef in ipairs(_categories) do
		local cn = catDef.name
		local tb = Instance.new("TextButton")
		tb.Name = cn
		tb.LayoutOrder = i
		tb.AutoButtonColor = false
		tb.BackgroundColor3 = Colors.Action
		tb.BorderSizePixel = 0
		tb.Size = UDim2.new(1, 0, 0, 36)
		tb.FontFace = UIFont
		tb.TextSize = 17
		tb.TextColor3 = Colors.Text
		tb.Text = cn
		tb.TextXAlignment = Enum.TextXAlignment.Center
		tb.ZIndex = 20005
		tb.Parent = ts
		tb.MouseEnter:Connect(function() tw(tb, {BackgroundColor3 = Colors.ActionHover}, 0.08) end)
		tb.MouseLeave:Connect(function() tw(tb, {BackgroundColor3 = Colors.Action}, 0.08) end)
		tb.MouseButton1Click:Connect(function()
			playButtonSound()
			local c = categoryFrames[cn]
			if not c or not c.Parent then return end
			categoryStates[cn] = not categoryStates[cn]
			c.Visible = categoryStates[cn]
			config.tabs[cn] = categoryStates[cn]
			saveConfig()
		end)
		addTooltip(tb, "Toggle " .. cn .. " tab")
	end
	local sc = Instance.new("Frame")
	sc.BackgroundTransparency = 1
	sc.Position = UDim2.new(1, -48, 1, -48)
	sc.Size = UDim2.fromOffset(40, 40)
	sc.ZIndex = 20015
	sc.Parent = tabPanel
	local sb = Instance.new("TextButton")
	sb.AutoButtonColor = false
	sb.BackgroundTransparency = 1
	sb.BorderSizePixel = 0
	sb.Size = UDim2.fromScale(1, 1)
	sb.Text = ""
	sb.ZIndex = 20016
	sb.Parent = sc
	local si = Instance.new("ImageLabel")
	si.BackgroundTransparency = 1
	si.AnchorPoint = Vector2.new(0.5, 0.5)
	si.Position = UDim2.fromScale(0.5, 0.5)
	si.Size = UDim2.fromScale(1, 1)
	si.ScaleType = Enum.ScaleType.Fit
	si.ImageColor3 = Color3.fromRGB(255, 255, 255)
	si.ZIndex = 20017
	si.Parent = sb
	task.spawn(function()
		if type(request) == "function" and type(writefile) == "function" then
			pcall(function()
				local r = request({Url = SETTINGS_ICON_URL, Method = "GET"})
				if r and r.Success and r.Body then
					writefile("nox_settings_icon.png", r.Body)
					local a = getCustomAsset("nox_settings_icon.png")
					if a then si.Image = a end
				end
			end)
		end
	end)
	if si.Image == "" then si.Image = "rbxassetid://6034654127" end
	sb.MouseEnter:Connect(function() tw(si, {ImageColor3 = Color3.fromRGB(180, 180, 180)}, 0.1) end)
	sb.MouseLeave:Connect(function() tw(si, {ImageColor3 = Color3.fromRGB(255, 255, 255)}, 0.1) end)
	addTooltip(sb, "Open GUI settings")
	sb.MouseButton1Click:Connect(function() playButtonSound() createSettingsWindow() end)
	local sxf = Instance.new("Frame")
	sxf.Name = "SearchBar"
	sxf.BackgroundColor3 = Colors.Panel
	sxf.BorderSizePixel = 0
	sxf.Size = UDim2.fromOffset(220, 40)
	sxf.Position = UDim2.fromOffset(tonumber(config.searchPosition.x) or 300, tonumber(config.searchPosition.y) or 50)
	sxf.ZIndex = 30000
	sxf.Parent = screenGui
	local sh = Instance.new("TextButton")
	sh.AutoButtonColor = false
	sh.BackgroundColor3 = Colors.Panel
	sh.BorderSizePixel = 0
	sh.Size = UDim2.new(1, 0, 0, 40)
	sh.Text = ""
	sh.ZIndex = 30001
	sh.Parent = sxf
	makeDraggable(sxf, sh, "searchBar", false)
	local sbx = Instance.new("TextBox")
	sbx.BackgroundColor3 = Colors.ToggleOff
	sbx.BorderSizePixel = 0
	sbx.Position = UDim2.fromOffset(8, 5)
	sbx.Size = UDim2.new(1, -16, 1, -10)
	sbx.FontFace = UIFont
	sbx.TextSize = 18
	sbx.TextColor3 = Colors.Text
	sbx.PlaceholderText = "Search features..."
	sbx.PlaceholderColor3 = Colors.MutedText
	sbx.Text = ""
	sbx.ZIndex = 30002
	sbx.Parent = sxf

	filterButtons = function(q)
		if not tabPanel.Visible then return end
		q = string.lower(q)
		for cn, card in pairs(categoryFrames) do
			if card and card.Parent then
				local scr = card:FindFirstChild("Buttons")
				if scr then
					local anyV = false
					for _, ch in ipairs(scr:GetChildren()) do
						if ch:IsA("Frame") and ch.Name:match("_Wrapper$") then
							local b = ch:FindFirstChildOfClass("TextButton")
							if b then
								local mn = b:FindFirstChild("ModuleName")
								local text = (mn and mn.Text ~= "") and mn.Text or b.Name
								local v = q == "" or string.find(string.lower(text), q, 1, true) ~= nil
								ch.Visible = v
								if v then anyV = true end
							end
						end
					end
					card.Visible = (q ~= "" and anyV) or (q == "" and categoryStates[cn])
				end
			end
		end
	end
	sbx:GetPropertyChangedSignal("Text"):Connect(function() filterButtons(sbx.Text) end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or nil
		if not key then return end
		if waitingForBind then
			if key == "Backspace" or key == "Escape" then
				config.keybinds[waitingForBind.category][waitingForBind.feature] = nil
				waitingForBind.button.Text = "NONE"
			else
				local used = false
				for cat, feats in pairs(config.keybinds) do
					if type(feats) == "table" then
						for f, b in pairs(feats) do
							if b == key and not (cat == waitingForBind.category and f == waitingForBind.feature) then
								used = true
								break
							end
						end
					end
					if used then break end
				end
				if used then
					notifyError("Key already bound!")
					waitingForBind.button.Text = getKeybind(waitingForBind.category, waitingForBind.feature) or "NONE"
				else
					config.keybinds[waitingForBind.category][waitingForBind.feature] = key
					waitingForBind.button.Text = key
				end
			end
			waitingForBind.button.BackgroundColor3 = Colors.Action
			waitingForBind = nil
			saveConfig()
			return
		end
		if gp then return end
		if key == config.guiKeybind then
			hideTooltip()
			setMenuVisible(not tabPanel.Visible)
			return
		end
		if UserInputService:GetFocusedTextBox() then return end
		for cn, feats in pairs(config.keybinds) do
			if type(feats) ~= "table" then continue end
			for fn, b in pairs(feats) do
				if b == key then
					local d = buttonData[cn] and buttonData[cn][fn]
					if d and d.toggle then d.toggle() end
					break
				end
			end
		end
	end)

	playerGui.ChildAdded:Connect(function(child)
		if not otherGuisDisabled then return end
		if child:IsA("ScreenGui") and child ~= screenGui then
			task.defer(function()
				if otherGuisDisabled and child.Parent then
					disabledGuiStates[child] = child.Enabled
					child.Enabled = false
				end
			end)
		end
	end)

	setMenuVisible(tabPanel.Visible)
	saveConfig()
end

local NoxLib = {}

function NoxLib.addCategory(name)
	assert(type(name) == "string" and name ~= "", "NoxLib.addCategory: name must be a non-empty string")
	if _categoryMap[name] then return end
	local c = { name = name, items = {} }
	table.insert(_categories, c)
	_categoryMap[name] = c
end

function NoxLib.addButton(categoryName, opts)
	assert(type(categoryName) == "string", "NoxLib.addButton: categoryName must be string")
	assert(type(opts) == "table", "NoxLib.addButton: opts must be table")
	assert(type(opts.name) == "string" and opts.name ~= "", "NoxLib.addButton: opts.name required")
	if not _categoryMap[categoryName] then NoxLib.addCategory(categoryName) end
	local c = _categoryMap[categoryName]
	table.insert(c.items, {
		name = opts.name,
		toggle = opts.toggle ~= false,
		description = opts.description or "",
		action = opts.action or function() end,
		settings = opts.settings
	})
end

function NoxLib.notify(msg, kind) createNotification(msg, kind or "enabled") end
function NoxLib.notifyEnabled(msg) notifyEnabled(msg) end
function NoxLib.notifyWarning(msg) notifyWarning(msg) end
function NoxLib.notifyError(msg) notifyError(msg) end

NoxLib.Features = Features
NoxLib.getSetting = getSetting
NoxLib.setSetting = setSetting
NoxLib.saveConfig = saveConfig
NoxLib.setMenuVisible = setMenuVisible
NoxLib.Colors = Colors

function NoxLib.init() init() end

_G.NoxLib = NoxLib

return NoxLib
