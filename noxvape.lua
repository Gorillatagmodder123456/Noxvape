--[[
    NoxLib v1.2  —  noxvape GUI Framework
    - Synchronized RGB color picker
    - Fast Flag Manager (auto-creates noxvape_fastflags in workspace)
    - Profiles system (save/load/rename/delete + Sync to Menu Color)
]]

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Constants
local CONFIG_FILE = "noxvape.json"
local PROFILES_FOLDER = "noxvape_profiles"
local FFLAGS_FOLDER_NAME = "noxvape_fastflags"
local LOGO_FILE = "noxvapev4.png"
local LOGO_URL = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/noxvapev4.png"
local SEARCH_ICON_URL = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/icons8-search-24.png"
local POGCHAMP_URL = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/pogchamp-removebg-preview.png"
local SETTINGS_ICON_URL = "https://github.com/Gorillatagmodder123456/a/raw/main/ChatGPT%20Image%20Aug%2026%2C%202026%2C%2007_00_05%20AM.png"

local RGB_SPEED = 0.75

local Colors = {
    Background = Color3.fromRGB(1, 1, 2),
    Panel = Color3.fromRGB(4, 5, 7),
    PanelHover = Color3.fromRGB(9, 11, 15),
    ToggleOff = Color3.fromRGB(7, 9, 12),
    ToggleOffHover = Color3.fromRGB(12, 15, 20),
    ToggleOn = Color3.fromRGB(30, 100, 140),
    ToggleOnHover = Color3.fromRGB(40, 120, 165),
    Action = Color3.fromRGB(10, 12, 16),
    ActionHover = Color3.fromRGB(18, 22, 28),
    Setting = Color3.fromRGB(5, 7, 10),
    Accent = Color3.fromRGB(55, 150, 200),
    Warning = Color3.fromRGB(255, 165, 0),
    Error = Color3.fromRGB(220, 50, 50),
    Text = Color3.fromRGB(235, 240, 245),
    MutedText = Color3.fromRGB(140, 150, 160),
    Tooltip = Color3.fromRGB(3, 4, 6)
}

local UIFont = Font.new(
    "rbxasset://fonts/families/BuilderSans.json",
    Enum.FontWeight.SemiBold,
    Enum.FontStyle.Normal
)

-- Helpers
local function getCustomAsset(path)
    if type(getcustomasset) == "function" then return getcustomasset(path) end
    if type(getsynasset) == "function" then return getsynasset(path) end
    return nil
end

local function canUseFiles()
    return type(writefile) == "function"
        and type(readfile) == "function"
        and type(isfile) == "function"
end

local function listfilesSafe(folder)
    if type(listfiles) ~= "function" then return {} end
    local ok, res = pcall(listfiles, folder)
    if ok and type(res) == "table" then return res end
    return {}
end

local function makeFolderSafe(path)
    if type(makefolder) ~= "function" then return false end
    return (pcall(makefolder, path))
end

local function delFileSafe(path)
    if type(delfile) ~= "function" then return false end
    return (pcall(delfile, path))
end

local function isFolderSafe(path)
    if type(isfolder) ~= "function" then return false end
    local ok, res = pcall(isfolder, path)
    return ok and res
end

local function tw(obj, props, dur)
    if not obj or not obj.Parent then return end
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(dur or 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return true end
    local ok, result = pcall(fn, ...)
    if not ok then
        warn("[NoxLib]", result)
        return false, result
    end
    return true, result
end

-- =========================================================================
-- Fast Flag Folder (auto-created in workspace)
-- =========================================================================
local function ensureFastFlagsFolder()
    local folder = workspace:FindFirstChild(FFLAGS_FOLDER_NAME)
    if not folder then
        local ok, newFolder = pcall(function()
            local f = Instance.new("Folder")
            f.Name = FFLAGS_FOLDER_NAME
            f.Parent = workspace
            return f
        end)
        if ok then folder = newFolder end
    end
    return folder
end

-- =========================================================================
-- Config
-- =========================================================================
local config = {
    version = 1,
    features = {},
    tabs = {},
    positions = {},
    keybinds = {},
    settings = {},
    noxPosition = { x = 18, y = 75 },
    searchPosition = { x = 300, y = 50 },
    guiKeybind = "RightShift",
    guiSounds = false,
    soundId = "0",
    menuSounds = false,
    openSoundId = "0",
    closeSoundId = "0",
    soundVolume = 0.5,
    searchExpanded = false,
    menuColor = { r = 55/255, g = 150/255, b = 200/255 }
}

local function loadConfig()
    if not canUseFiles() then return end
    if not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not ok or type(data) ~= "table" then return end
    for k, v in pairs(data) do
        if type(config[k]) == "table" and type(v) == "table" then
            for kk, vv in pairs(v) do
                config[k][kk] = vv
            end
        else
            config[k] = v
        end
    end
end

local saveQueued = false

local function saveConfig()
    if not canUseFiles() then return end
    if saveQueued then return end
    saveQueued = true
    task.delay(0.12, function()
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(config))
        end)
        saveQueued = false
    end)
end

loadConfig()

local function repairConfig()
    for _, key in ipairs({"features", "tabs", "positions", "keybinds", "settings"}) do
        if type(config[key]) ~= "table" then config[key] = {} end
    end
    if type(config.noxPosition) ~= "table" then config.noxPosition = { x = 18, y = 75 } end
    if type(config.searchPosition) ~= "table" then config.searchPosition = { x = 300, y = 50 } end
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
    if type(config.searchExpanded) ~= "boolean" then config.searchExpanded = false end
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

-- Config helpers
local function ensureCategoryData(cat)
    if type(config.features[cat]) ~= "table" then config.features[cat] = {} end
    if type(config.keybinds[cat]) ~= "table" then config.keybinds[cat] = {} end
    if type(config.settings[cat]) ~= "table" then config.settings[cat] = {} end
end

local function colorToData(value)
    if typeof(value) ~= "Color3" then return value end
    return { r = value.R, g = value.G, b = value.B }
end

local function dataToColor(value)
    if type(value) == "table" and type(value.r) == "number"
        and type(value.g) == "number" and type(value.b) == "number" then
        return Color3.new(math.clamp(value.r, 0, 1), math.clamp(value.g, 0, 1), math.clamp(value.b, 0, 1))
    end
    return value
end

local function getFeatureState(cat, name)
    ensureCategoryData(cat)
    local value = config.features[cat][name]
    return type(value) == "boolean" and value or false
end

local function getKeybind(cat, name)
    ensureCategoryData(cat)
    local value = config.keybinds[cat][name]
    if type(value) == "string" and value ~= "" then return value end
    return nil
end

local function getSetting(cat, feat, key, default)
    ensureCategoryData(cat)
    if type(config.settings[cat][feat]) ~= "table" then
        config.settings[cat][feat] = {}
    end
    local value = config.settings[cat][feat][key]
    if value == nil then
        config.settings[cat][feat][key] = colorToData(default)
        return default
    end
    return dataToColor(value)
end

local function setSetting(cat, feat, key, value)
    ensureCategoryData(cat)
    if type(config.settings[cat][feat]) ~= "table" then
        config.settings[cat][feat] = {}
    end
    config.settings[cat][feat][key] = colorToData(value)
    saveConfig()
end

local function getPosition(name, dx, dy)
    local p = config.positions[name]
    if type(p) == "table" and type(p.x) == "number" and type(p.y) == "number" then
        return p.x, p.y
    end
    return dx, dy
end

-- Screen GUI
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

-- Notifications
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
            local response = request({ Url = POGCHAMP_URL, Method = "GET" })
            if response and response.Success and response.Body then
                writefile("nox_pogchamp.png", response.Body)
                local asset = getCustomAsset("nox_pogchamp.png")
                if asset then PogchampAsset = asset end
            end
        end)
    end
    PogchampAsset = PogchampAsset or "rbxassetid://10340520068"
end)

local function createNotification(msg, kind)
    if not screenGui or not screenGui.Parent then return end
    notifCounter += 1
    while #activeNotifs >= MAX_NOTIFS do
        local old = table.remove(activeNotifs, 1)
        if old and old.Parent then old:Destroy() end
    end
    local accent = kind == "warning" and Colors.Warning
        or kind == "error" and Colors.Error
        or Colors.Accent
    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.BackgroundColor3 = Colors.Panel
    notif.BackgroundTransparency = 0.12
    notif.BorderSizePixel = 0
    notif.Size = UDim2.fromOffset(330, 50)
    notif.LayoutOrder = notifCounter
    notif.ZIndex = 50001
    notif.ClipsDescendants = true
    notif.Parent = notifHolder
    table.insert(activeNotifs, notif)
    local side = Instance.new("Frame")
    side.BackgroundColor3 = accent
    side.BorderSizePixel = 0
    side.Size = UDim2.new(0, 3, 1, 0)
    side.ZIndex = 50005
    side.Parent = notif
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = UDim2.fromOffset(28, 28)
    img.Position = UDim2.fromOffset(6, 11)
    img.Image = PogchampAsset or "rbxassetid://10340520068"
    img.ScaleType = Enum.ScaleType.Fit
    img.ZIndex = 50003
    img.Parent = notif
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
    lbl.Parent = notif
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = accent
    bar.BackgroundTransparency = 0.2
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(1, 0, 0, 3)
    bar.Position = UDim2.new(0, 0, 1, -3)
    bar.ZIndex = 50004
    bar.Parent = notif
    notif.Position = UDim2.fromOffset(360, 0)
    notif.Size = UDim2.fromOffset(330 * 0.8, 50 * 0.8)
    tw(notif, { Position = UDim2.fromOffset(0, 0) }, 0.25)
    local springTween = TweenService:Create(
        notif,
        TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = UDim2.fromOffset(330, 50) }
    )
    springTween:Play()
    local duration = 2.4
    TweenService:Create(bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 3) }):Play()
    task.delay(duration + 0.15, function()
        if not notif.Parent then return end
        local slideOut = tw(notif, { Position = UDim2.fromOffset(360, 0) }, 0.2)
        TweenService:Create(
            notif,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Size = UDim2.fromOffset(330 * 0.8, 50 * 0.8) }
        ):Play()
        if slideOut then
            slideOut.Completed:Connect(function()
                if notif.Parent then notif:Destroy() end
                for i, value in ipairs(activeNotifs) do
                    if value == notif then table.remove(activeNotifs, i); break end
                end
            end)
        end
    end)
end

local function notifyEnabled(message) createNotification(message, "enabled") end
local function notifyWarning(message) createNotification(message, "warning") end
local function notifyError(message) createNotification(message, "error") end

-- Tooltip (FIXED: no GuiInset offset)
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
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 7)
        padding.PaddingBottom = UDim.new(0, 7)
        padding.PaddingLeft = UDim.new(0, 11)
        padding.PaddingRight = UDim.new(0, 11)
        padding.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.AutomaticSize = Enum.AutomaticSize.XY
        label.FontFace = UIFont
        label.TextSize = 16
        label.TextColor3 = Colors.Text
        label.Text = text
        label.ZIndex = 60001
        label.Parent = frame
        task.wait()
        if token ~= tooltipToken then
            if frame.Parent then frame:Destroy() end
            return
        end
        local viewport = camera.ViewportSize
        local width = frame.AbsoluteSize.X
        local height = frame.AbsoluteSize.Y
        local x = mouse.X + 14
        local y = mouse.Y + 16
        if x + width > viewport.X - 8 then x = mouse.X - width - 14 end
        if y + height > viewport.Y - 8 then y = mouse.Y - height - 16 end
        frame.Position = UDim2.fromOffset(
            math.clamp(x, 8, math.max(8, viewport.X - width - 8)),
            math.clamp(y, 8, math.max(8, viewport.Y - height - 8))
        )
        tooltip = frame
    end)
end

local function addTooltip(obj, text)
    if not text or text == "" then return end
    obj.MouseEnter:Connect(function() showTooltip(text) end)
    obj.MouseLeave:Connect(function() hideTooltip() end)
end

-- Draggable
local function makeDraggable(obj, handle, posName, isNox)
    local dragging = false
    local dragStart
    local startPos
    local mouseConnection
    local endConnection
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        dragging = true
        dragStart = input.Position
        startPos = obj.Position
        hideTooltip()
        if mouseConnection then mouseConnection:Disconnect() end
        if endConnection then endConnection:Disconnect() end
        mouseConnection = UserInputService.InputChanged:Connect(function(inputChanged)
            if not dragging or inputChanged.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local delta = inputChanged.Position - dragStart
            local x = startPos.X.Offset + delta.X
            local y = startPos.Y.Offset + delta.Y
            local camera = workspace.CurrentCamera
            if camera then
                local viewport = camera.ViewportSize
                x = math.clamp(x, 0, math.max(0, viewport.X - obj.AbsoluteSize.X))
                y = math.clamp(y, 0, math.max(0, viewport.Y - obj.AbsoluteSize.Y))
            end
            obj.Position = UDim2.fromOffset(x, y)
        end)
        endConnection = UserInputService.InputEnded:Connect(function(inputEnded)
            if inputEnded.UserInputType ~= Enum.UserInputType.MouseButton1
                and inputEnded.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
            dragging = false
            if mouseConnection then mouseConnection:Disconnect(); mouseConnection = nil end
            if endConnection then endConnection:Disconnect(); endConnection = nil end
            if isNox then
                config.noxPosition = { x = obj.Position.X.Offset, y = obj.Position.Y.Offset }
            elseif posName == "searchBar" then
                config.searchPosition = { x = obj.Position.X.Offset, y = obj.Position.Y.Offset }
            else
                config.positions[posName] = { x = obj.Position.X.Offset, y = obj.Position.Y.Offset }
            end
            saveConfig()
        end)
    end)
end

-- Features API
local buttonData = {}
local categoryFrames = {}
local categoryStates = {}
local Features = {}

function Features.get(cat, name) return buttonData[cat] and buttonData[cat][name] end
function Features.isEnabled(cat, name)
    local data = Features.get(cat, name)
    if data and data.getState then return data.getState() end
    return getFeatureState(cat, name)
end
function Features.set(cat, name, enabled)
    local data = Features.get(cat, name)
    if not data then
        ensureCategoryData(cat)
        config.features[cat][name] = enabled and true or false
        saveConfig()
        return false
    end
    local current = data.getState and data.getState() or false
    if current == enabled then return true end
    if data.toggle then data.toggle(); return true end
    ensureCategoryData(cat)
    config.features[cat][name] = enabled and true or false
    if data.button then data.button.BackgroundColor3 = enabled and Colors.Accent or Colors.Action end
    saveConfig()
    return true
end
function Features.forceOff(cat, name)
    local data = Features.get(cat, name)
    ensureCategoryData(cat)
    if data and data.getState and data.getState() and type(data.action) == "function" then
        pcall(data.action, false)
    end
    config.features[cat][name] = false
    if data then
        if type(data.setState) == "function" then
            data.setState(false, true)
        elseif data.button then
            data.button.BackgroundColor3 = Colors.Action
        end
    end
    saveConfig()
    return true
end
function Features.disable(cat, name) return Features.forceOff(cat, name) end
function Features.enable(cat, name) return Features.set(cat, name, true) end

local _categories = {}
local _categoryMap = {}

-- Sounds
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

-- Blur
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
    for gui, previous in pairs(disabledGuiStates) do
        if gui and gui.Parent then pcall(function() gui.Enabled = previous end) end
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
        for _, notification in ipairs(activeNotifs) do
            if notification and notification.Parent then notification:Destroy() end
        end
        activeNotifs = {}
    end)
    pcall(function() if screenGui then screenGui:Destroy() end end)
    buttonData = {}
    categoryFrames = {}
    categoryStates = {}
end

-- =========================================================================
-- FAST FLAG MANAGER
-- =========================================================================
local function findLoaderFolder()
    -- Priority 1: the auto-created noxvape_fastflags folder
    local preferred = workspace:FindFirstChild(FFLAGS_FOLDER_NAME)
    if preferred and (preferred:IsA("Folder") or preferred:IsA("Configuration")) then
        return preferred
    end

    -- Fallback: look for common alternate folder names
    local candidates = {"loader", "Loader", "FastFlags", "fastflags", "fflags", "FFlags", "Flags", "flags"}
    for _, name in ipairs(candidates) do
        local f = workspace:FindFirstChild(name)
        if f and (f:IsA("Folder") or f:IsA("Configuration")) then return f end
    end

    -- Last resort: any folder with a *.json StringValue
    for _, f in ipairs(workspace:GetChildren()) do
        if f:IsA("Folder") then
            for _, ch in ipairs(f:GetChildren()) do
                local n = string.lower(ch.Name)
                if string.find(n, "%.json", 1, true) then return f end
            end
        end
    end
    return nil
end

local function getFlagsFromFolder(folder)
    local list = {}
    if not folder then return list end
    for _, child in ipairs(folder:GetChildren()) do
        local flags = nil
        local name = child.Name
        if child:IsA("StringValue") then
            local ok, decoded = pcall(function() return HttpService:JSONDecode(child.Value) end)
            if ok and type(decoded) == "table" then flags = decoded end
        elseif child:IsA("ModuleScript") then
            local ok, res = pcall(require, child)
            if ok and type(res) == "table" then flags = res end
        end
        if flags then
            table.insert(list, { name = name, flags = flags })
        end
    end
    return list
end

local function applyFastFlags(flags)
    if type(flags) ~= "table" then return 0 end
    local count = 0
    for k, v in pairs(flags) do
        local ok = pcall(function()
            if type(setfflag) == "function" then
                setfflag(tostring(k), tostring(v))
            end
        end)
        if ok then count = count + 1 end
    end
    return count
end

-- =========================================================================
-- PROFILES
-- =========================================================================
local function ensureProfilesFolder()
    if type(isfolder) == "function" and type(makefolder) == "function" then
        if not isFolderSafe(PROFILES_FOLDER) then
            makeFolderSafe(PROFILES_FOLDER)
        end
    end
end

local function listProfiles()
    if not canUseFiles() then return {} end
    ensureProfilesFolder()
    local files = listfilesSafe(PROFILES_FOLDER)
    local list = {}
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(list, name) end
    end
    table.sort(list, function(a, b) return string.lower(a) < string.lower(b) end)
    return list
end

local function captureCurrentConfig()
    return {
        features = HttpService:JSONDecode(HttpService:JSONEncode(config.features)),
        settings = HttpService:JSONDecode(HttpService:JSONEncode(config.settings)),
        keybinds = HttpService:JSONDecode(HttpService:JSONEncode(config.keybinds)),
        tabs = HttpService:JSONDecode(HttpService:JSONEncode(config.tabs)),
        noxPosition = HttpService:JSONDecode(HttpService:JSONEncode(config.noxPosition)),
        searchPosition = HttpService:JSONDecode(HttpService:JSONEncode(config.searchPosition)),
        guiSounds = config.guiSounds,
        menuSounds = config.menuSounds,
        soundVolume = config.soundVolume,
        soundId = config.soundId,
        openSoundId = config.openSoundId,
        closeSoundId = config.closeSoundId,
        guiKeybind = config.guiKeybind,
        menuColor = HttpService:JSONDecode(HttpService:JSONEncode(config.menuColor or {r=55/255,g=150/255,b=200/255}))
    }
end

local function saveProfile(name)
    if not canUseFiles() then return false end
    ensureProfilesFolder()
    local data = captureCurrentConfig()
    data.name = name
    local ok = pcall(function()
        writefile(PROFILES_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
    return ok
end

local function readProfile(name)
    if not canUseFiles() then return nil end
    local path = PROFILES_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

local function writeProfileData(name, data)
    if not canUseFiles() then return false end
    ensureProfilesFolder()
    return (pcall(function()
        writefile(PROFILES_FOLDER .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    end))
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
    if type(data.menuColor) == "table" then config.menuColor = data.menuColor end
    saveConfig()
    return true
end

local function deleteProfile(name)
    if not canUseFiles() then return false end
    local path = PROFILES_FOLDER .. "/" .. name .. ".json"
    if not isfile(path) then return false end
    return delFileSafe(path)
end

-- =========================================================================
-- Init state
-- =========================================================================
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
        local categoryName = card.Name
        if card and card.Parent then
            card.Visible = visible and categoryStates[categoryName]
        end
    end
    local searchFrame = screenGui:FindFirstChild("SearchBar")
    if searchFrame then searchFrame.Visible = visible end
    if visible then
        disableOtherScreenGuis()
        local searchBox = searchFrame and searchFrame:FindFirstChildOfClass("TextBox")
        if searchBox and searchBox.Text ~= "" then filterButtons(searchBox.Text) end
        if not was then playMenuSound(true) end
    else
        restoreOtherScreenGuis()
        if was then playMenuSound(false) end
    end
    updateBlur()
end

-- =========================================================================
-- FAST FLAG MANAGER WINDOW
-- =========================================================================
local function createFastFlagWindow()
    if fastFlagWindow then
        fastFlagWindow.Visible = not fastFlagWindow.Visible
        return
    end
    local winX, winY = getPosition("fastFlagWindow", 340, 100)
    local window = Instance.new("Frame")
    window.Name = "FastFlagWindow"
    window.BackgroundColor3 = Colors.Panel
    window.BackgroundTransparency = 0
    window.BorderSizePixel = 0
    window.Size = UDim2.fromOffset(340, 440)
    window.Position = UDim2.fromOffset(winX, winY)
    window.ClipsDescendants = true
    window.ZIndex = 45000
    window.Parent = screenGui
    fastFlagWindow = window

    local header = Instance.new("TextButton")
    header.AutoButtonColor = false
    header.BackgroundColor3 = Colors.Panel
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 40)
    header.FontFace = UIFont
    header.TextSize = 18
    header.TextColor3 = Colors.Text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  Fast Flag Manager"
    header.ZIndex = 45001
    header.Parent = window

    local closeBtn = Instance.new("TextButton")
    closeBtn.AutoButtonColor = false
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.fromOffset(40, 40)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, 0, 0, 0)
    closeBtn.FontFace = UIFont
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = Colors.MutedText
    closeBtn.Text = "✕"
    closeBtn.ZIndex = 45002
    closeBtn.Parent = header
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Colors.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Colors.MutedText end)
    closeBtn.MouseButton1Click:Connect(function() window.Visible = false end)

    makeDraggable(window, header, "fastFlagWindow", false)

    local hint = Instance.new("TextLabel")
    hint.BackgroundTransparency = 1
    hint.Position = UDim2.fromOffset(12, 44)
    hint.Size = UDim2.new(1, -24, 0, 18)
    hint.FontFace = UIFont
    hint.TextSize = 12
    hint.TextColor3 = Colors.MutedText
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextTruncate = Enum.TextTruncate.AtEnd
    hint.Text = "JSON files go in workspace → " .. FFLAGS_FOLDER_NAME
    hint.ZIndex = 45003
    hint.Parent = window

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Position = UDim2.fromOffset(12, 68)
    content.Size = UDim2.new(1, -24, 1, -136)
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Colors.Accent
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.fromOffset(0, 0)
    content.ZIndex = 45003
    content.Parent = window

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 4)
    contentLayout.Parent = content

    local selectedFlags = {}

    local refreshBtn
    local loadAllBtn

    local function refreshList()
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        selectedFlags = {}

        local folder = findLoaderFolder()
        if not folder then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.FontFace = UIFont
            empty.TextSize = 15
            empty.TextColor3 = Colors.MutedText
            empty.Text = "No '" .. FFLAGS_FOLDER_NAME .. "' folder found in workspace."
            empty.LayoutOrder = 1
            empty.Parent = content
            return
        end

        local entries = getFlagsFromFolder(folder)
        if #entries == 0 then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.FontFace = UIFont
            empty.TextSize = 15
            empty.TextColor3 = Colors.MutedText
            empty.Text = "Folder '" .. folder.Name .. "' has no valid JSONs."
            empty.LayoutOrder = 1
            empty.Parent = content
            return
        end

        for i, entry in ipairs(entries) do
            local row = Instance.new("Frame")
            row.Name = entry.name
            row.BackgroundColor3 = Colors.Setting
            row.BackgroundTransparency = 0
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

            local flagCount = 0
            for _ in pairs(entry.flags) do flagCount += 1 end

            local nameLbl = Instance.new("TextLabel")
            nameLbl.BackgroundTransparency = 1
            nameLbl.Position = UDim2.fromOffset(40, 0)
            nameLbl.Size = UDim2.new(1, -110, 1, 0)
            nameLbl.FontFace = UIFont
            nameLbl.TextSize = 14
            nameLbl.TextColor3 = Colors.Text
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Text = entry.name .. " (" .. flagCount .. ")"
            nameLbl.ZIndex = 45005
            nameLbl.Parent = row

            local loadBtn = Instance.new("TextButton")
            loadBtn.AutoButtonColor = false
            loadBtn.BackgroundColor3 = Colors.Action
            loadBtn.BorderSizePixel = 0
            loadBtn.AnchorPoint = Vector2.new(1, 0.5)
            loadBtn.Position = UDim2.new(1, -6, 0.5, 0)
            loadBtn.Size = UDim2.fromOffset(60, 26)
            loadBtn.FontFace = UIFont
            loadBtn.TextSize = 13
            loadBtn.TextColor3 = Colors.Text
            loadBtn.Text = "Load"
            loadBtn.ZIndex = 45005
            loadBtn.Parent = row

            local function updateCheck()
                if selectedFlags[entry.name] then
                    check.BackgroundColor3 = Colors.Accent
                else
                    check.BackgroundColor3 = Colors.Action
                end
            end
            updateCheck()

            check.MouseButton1Click:Connect(function()
                if selectedFlags[entry.name] then
                    selectedFlags[entry.name] = nil
                else
                    selectedFlags[entry.name] = true
                end
                updateCheck()
            end)

            loadBtn.MouseEnter:Connect(function() loadBtn.BackgroundColor3 = Colors.ActionHover end)
            loadBtn.MouseLeave:Connect(function() loadBtn.BackgroundColor3 = Colors.Action end)
            loadBtn.MouseButton1Click:Connect(function()
                playButtonSound()
                local n = applyFastFlags(entry.flags)
                notifyEnabled("Loaded " .. n .. " flags from " .. entry.name)
            end)
        end
    end

    loadAllBtn = Instance.new("TextButton")
    loadAllBtn.AutoButtonColor = false
    loadAllBtn.BackgroundColor3 = Colors.Accent
    loadAllBtn.BorderSizePixel = 0
    loadAllBtn.Position = UDim2.new(0, 12, 1, -60)
    loadAllBtn.Size = UDim2.new(1, -136, 0, 40)
    loadAllBtn.FontFace = UIFont
    loadAllBtn.TextSize = 15
    loadAllBtn.TextColor3 = Colors.Text
    loadAllBtn.Text = "Load Selected"
    loadAllBtn.ZIndex = 45006
    loadAllBtn.Parent = window

    refreshBtn = Instance.new("TextButton")
    refreshBtn.AutoButtonColor = false
    refreshBtn.BackgroundColor3 = Colors.Action
    refreshBtn.BorderSizePixel = 0
    refreshBtn.AnchorPoint = Vector2.new(1, 0)
    refreshBtn.Position = UDim2.new(1, -12, 1, -60)
    refreshBtn.Size = UDim2.fromOffset(112, 40)
    refreshBtn.FontFace = UIFont
    refreshBtn.TextSize = 15
    refreshBtn.TextColor3 = Colors.Text
    refreshBtn.Text = "Refresh"
    refreshBtn.ZIndex = 45006
    refreshBtn.Parent = window

    refreshBtn.MouseButton1Click:Connect(function()
        playButtonSound()
        refreshList()
    end)

    loadAllBtn.MouseButton1Click:Connect(function()
        playButtonSound()
        local total = 0
        for name, _ in pairs(selectedFlags) do
            local entry
            for _, e in ipairs(getFlagsFromFolder(findLoaderFolder())) do
                if e.name == name then entry = e; break end
            end
            if entry then total = total + applyFastFlags(entry.flags) end
        end
        if total > 0 then
            notifyEnabled("Loaded " .. total .. " flags total")
        else
            notifyWarning("No flags selected")
        end
    end)

    task.defer(refreshList)
end

-- =========================================================================
-- PROFILES WINDOW
-- =========================================================================
local function createProfilesWindow()
    if profilesWindow then
        profilesWindow.Visible = not profilesWindow.Visible
        return
    end
    local winX, winY = getPosition("profilesWindow", 660, 100)
    local window = Instance.new("Frame")
    window.Name = "ProfilesWindow"
    window.BackgroundColor3 = Colors.Panel
    window.BackgroundTransparency = 0
    window.BorderSizePixel = 0
    window.Size = UDim2.fromOffset(360, 500)
    window.Position = UDim2.fromOffset(winX, winY)
    window.ClipsDescendants = true
    window.ZIndex = 46000
    window.Parent = screenGui
    profilesWindow = window

    local header = Instance.new("TextButton")
    header.AutoButtonColor = false
    header.BackgroundColor3 = Colors.Panel
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 40)
    header.FontFace = UIFont
    header.TextSize = 18
    header.TextColor3 = Colors.Text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  Profiles"
    header.ZIndex = 46001
    header.Parent = window

    local closeBtn = Instance.new("TextButton")
    closeBtn.AutoButtonColor = false
    closeBtn.BackgroundTransparency = 1
    closeBtn.Size = UDim2.fromOffset(40, 40)
    closeBtn.AnchorPoint = Vector2.new(1, 0)
    closeBtn.Position = UDim2.new(1, 0, 0, 0)
    closeBtn.FontFace = UIFont
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = Colors.MutedText
    closeBtn.Text = "✕"
    closeBtn.ZIndex = 46002
    closeBtn.Parent = header
    closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Colors.Text end)
    closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Colors.MutedText end)
    closeBtn.MouseButton1Click:Connect(function() window.Visible = false end)

    makeDraggable(window, header, "profilesWindow", false)

    local newRow = Instance.new("Frame")
    newRow.BackgroundTransparency = 1
    newRow.Position = UDim2.fromOffset(12, 48)
    newRow.Size = UDim2.new(1, -24, 0, 34)
    newRow.ZIndex = 46003
    newRow.Parent = window

    local nameInput = Instance.new("TextBox")
    nameInput.BackgroundColor3 = Colors.ToggleOff
    nameInput.BorderSizePixel = 0
    nameInput.Size = UDim2.new(1, -84, 1, 0)
    nameInput.FontFace = UIFont
    nameInput.TextSize = 14
    nameInput.TextColor3 = Colors.Text
    nameInput.PlaceholderText = "New profile name..."
    nameInput.PlaceholderColor3 = Colors.MutedText
    nameInput.Text = ""
    nameInput.ClearTextOnFocus = false
    nameInput.ZIndex = 46004
    nameInput.Parent = newRow

    local saveBtn = Instance.new("TextButton")
    saveBtn.AutoButtonColor = false
    saveBtn.BackgroundColor3 = Colors.Accent
    saveBtn.BorderSizePixel = 0
    saveBtn.AnchorPoint = Vector2.new(1, 0)
    saveBtn.Position = UDim2.new(1, 0, 0, 0)
    saveBtn.Size = UDim2.fromOffset(76, 34)
    saveBtn.FontFace = UIFont
    saveBtn.TextSize = 14
    saveBtn.TextColor3 = Colors.Text
    saveBtn.Text = "Save"
    saveBtn.ZIndex = 46004
    saveBtn.Parent = newRow

    local profileList = Instance.new("ScrollingFrame")
    profileList.Name = "Profiles"
    profileList.BackgroundTransparency = 1
    profileList.BorderSizePixel = 0
    profileList.Position = UDim2.fromOffset(12, 90)
    profileList.Size = UDim2.new(1, -24, 1, -150)
    profileList.ScrollBarThickness = 4
    profileList.ScrollBarImageColor3 = Colors.Accent
    profileList.ScrollingDirection = Enum.ScrollingDirection.Y
    profileList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    profileList.CanvasSize = UDim2.fromOffset(0, 0)
    profileList.ZIndex = 46003
    profileList.Parent = window

    local profileLayout = Instance.new("UIListLayout")
    profileLayout.SortOrder = Enum.SortOrder.LayoutOrder
    profileLayout.Padding = UDim.new(0, 4)
    profileLayout.Parent = profileList

    local refreshProfiles

    local function makeProfileRow(name, index)
        local row = Instance.new("Frame")
        row.Name = name
        row.BackgroundColor3 = Colors.Setting
        row.BackgroundTransparency = 0
        row.BorderSizePixel = 0
        row.Size = UDim2.new(1, 0, 0, 66)
        row.LayoutOrder = index
        row.ZIndex = 46004
        row.Parent = profileList

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "NameLabel"
        nameLbl.BackgroundTransparency = 1
        nameLbl.Position = UDim2.fromOffset(8, 4)
        nameLbl.Size = UDim2.new(1, -16, 0, 22)
        nameLbl.FontFace = UIFont
        nameLbl.TextSize = 15
        nameLbl.TextColor3 = Colors.Text
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Text = name
        nameLbl.ZIndex = 46005
        nameLbl.Parent = row

        local btnY = 32
        local btnH = 26

        local loadBtn = Instance.new("TextButton")
        loadBtn.AutoButtonColor = false
        loadBtn.BackgroundColor3 = Colors.Accent
        loadBtn.BorderSizePixel = 0
        loadBtn.Position = UDim2.fromOffset(8, btnY)
        loadBtn.Size = UDim2.fromOffset(52, btnH)
        loadBtn.FontFace = UIFont
        loadBtn.TextSize = 12
        loadBtn.TextColor3 = Colors.Text
        loadBtn.Text = "Load"
        loadBtn.ZIndex = 46005
        loadBtn.Parent = row

        local renameBtn = Instance.new("TextButton")
        renameBtn.AutoButtonColor = false
        renameBtn.BackgroundColor3 = Colors.Action
        renameBtn.BorderSizePixel = 0
        renameBtn.Position = UDim2.fromOffset(64, btnY)
        renameBtn.Size = UDim2.fromOffset(56, btnH)
        renameBtn.FontFace = UIFont
        renameBtn.TextSize = 12
        renameBtn.TextColor3 = Colors.Text
        renameBtn.Text = "Rename"
        renameBtn.ZIndex = 46005
        renameBtn.Parent = row

        local syncBtn = Instance.new("TextButton")
        syncBtn.AutoButtonColor = false
        syncBtn.BackgroundColor3 = Colors.Action
        syncBtn.BorderSizePixel = 0
        syncBtn.Position = UDim2.fromOffset(124, btnY)
        syncBtn.Size = UDim2.fromOffset(120, btnH)
        syncBtn.FontFace = UIFont
        syncBtn.TextSize = 12
        syncBtn.TextColor3 = Colors.Text
        syncBtn.Text = "Sync to Menu Color"
        syncBtn.ZIndex = 46005
        syncBtn.Parent = row

        local delBtn = Instance.new("TextButton")
        delBtn.AutoButtonColor = false
        delBtn.BackgroundColor3 = Colors.Error
        delBtn.BorderSizePixel = 0
        delBtn.AnchorPoint = Vector2.new(1, 0)
        delBtn.Position = UDim2.new(1, -8, 0, btnY)
        delBtn.Size = UDim2.fromOffset(48, btnH)
        delBtn.FontFace = UIFont
        delBtn.TextSize = 12
        delBtn.TextColor3 = Colors.Text
        delBtn.Text = "Del"
        delBtn.ZIndex = 46005
        delBtn.Parent = row

        loadBtn.MouseButton1Click:Connect(function()
            playButtonSound()
            local data = readProfile(name)
            if not data then notifyError("Failed to read profile"); return end
            applyProfileData(data)
            notifyEnabled("Loaded profile: " .. name)
        end)

        renameBtn.MouseButton1Click:Connect(function()
            playButtonSound()
            local newName = nameLbl.Text
            if not newName or newName == "" then return end
            if newName == name then return end
            local data = readProfile(name)
            if not data then notifyError("Failed to read profile"); return end
            if writeProfileData(newName, data) then
                deleteProfile(name)
                notifyEnabled("Renamed to " .. newName)
                refreshProfiles()
            else
                notifyError("Rename failed")
            end
        end)

        nameLbl.TextEditable = false
        nameLbl.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local box = Instance.new("TextBox")
                box.BackgroundColor3 = Colors.ToggleOff
                box.BorderSizePixel = 0
                box.Size = nameLbl.Size
                box.Position = nameLbl.Position
                box.FontFace = UIFont
                box.TextSize = nameLbl.TextSize
                box.TextColor3 = nameLbl.TextColor3
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.Text = nameLbl.Text
                box.ClearTextOnFocus = false
                box.ZIndex = 46006
                box.Parent = row

                box:CaptureFocus()

                local finished = false
                local function finish(commit)
                    if finished then return end
                    finished = true
                    if commit and box.Text ~= "" and box.Text ~= name then
                        local data = readProfile(name)
                        if data and writeProfileData(box.Text, data) then
                            deleteProfile(name)
                            notifyEnabled("Renamed to " .. box.Text)
                            box:Destroy()
                            refreshProfiles()
                            return
                        end
                    end
                    box:Destroy()
                end

                box.FocusLost:Connect(function(enterPressed) finish(enterPressed) end)
            end
        end)

        syncBtn.MouseButton1Click:Connect(function()
            playButtonSound()
            local data = readProfile(name)
            if not data then notifyError("Failed to read profile"); return end
            data.menuColor = {
                r = config.menuColor.r,
                g = config.menuColor.g,
                b = config.menuColor.b
            }
            if writeProfileData(name, data) then
                notifyEnabled("Synced '" .. name .. "' to current menu color")
            else
                notifyError("Sync failed")
            end
        end)

        delBtn.MouseButton1Click:Connect(function()
            playButtonSound()
            if deleteProfile(name) then
                notifyWarning("Deleted profile: " .. name)
                refreshProfiles()
            else
                notifyError("Delete failed")
            end
        end)
    end

    refreshProfiles = function()
        for _, child in ipairs(profileList:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        local list = listProfiles()
        if #list == 0 then
            local empty = Instance.new("TextLabel")
            empty.BackgroundTransparency = 1
            empty.Size = UDim2.new(1, 0, 0, 40)
            empty.FontFace = UIFont
            empty.TextSize = 14
            empty.TextColor3 = Colors.MutedText
            empty.Text = "No profiles yet. Type a name above and click Save."
            empty.LayoutOrder = 1
            empty.Parent = profileList
            return
        end
        for i, name in ipairs(list) do
            makeProfileRow(name, i)
        end
    end

    saveBtn.MouseButton1Click:Connect(function()
        playButtonSound()
        local name = nameInput.Text:gsub("%s+", "_")
        if name == "" then notifyError("Enter a profile name"); return end
        if saveProfile(name) then
            notifyEnabled("Saved profile: " .. name)
            nameInput.Text = ""
            refreshProfiles()
        else
            notifyError("Save failed")
        end
    end)

    task.defer(refreshProfiles)
end

-- =========================================================================
-- SETTINGS WINDOW
-- =========================================================================
local function createSettingsWindow()
    if settingsWindow then
        settingsWindow.Visible = not settingsWindow.Visible
        settingsVisible = settingsWindow.Visible
        return
    end
    local winX, winY = getPosition("settingsWindow", 50, 100)
    local window = Instance.new("Frame")
    window.Name = "SettingsWindow"
    window.BackgroundColor3 = Colors.Panel
    window.BackgroundTransparency = 0
    window.BorderSizePixel = 0
    window.Size = UDim2.fromOffset(300, 520)
    window.Position = UDim2.fromOffset(winX, winY)
    window.ClipsDescendants = true
    window.ZIndex = 40000
    window.Parent = screenGui

    local header = Instance.new("TextButton")
    header.AutoButtonColor = false
    header.BackgroundColor3 = Colors.Panel
    header.BackgroundTransparency = 0
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 40)
    header.FontFace = UIFont
    header.TextSize = 20
    header.TextColor3 = Colors.Text
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "  Settings"
    header.ZIndex = 40001
    header.Parent = window

    local closeButton = Instance.new("TextButton")
    closeButton.AutoButtonColor = false
    closeButton.BackgroundTransparency = 1
    closeButton.Size = UDim2.fromOffset(40, 40)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.Position = UDim2.new(1, 0, 0, 0)
    closeButton.FontFace = UIFont
    closeButton.TextSize = 20
    closeButton.TextColor3 = Colors.MutedText
    closeButton.Text = "✕"
    closeButton.ZIndex = 40002
    closeButton.Parent = header
    closeButton.MouseEnter:Connect(function() closeButton.TextColor3 = Colors.Text end)
    closeButton.MouseLeave:Connect(function() closeButton.TextColor3 = Colors.MutedText end)
    closeButton.MouseButton1Click:Connect(function()
        window.Visible = false
        settingsVisible = false
    end)

    makeDraggable(window, header, "settingsWindow", false)

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
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
    content.Parent = window

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = content

    local function addLabel(text, order)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, 22)
        label.FontFace = UIFont
        label.TextSize = 17
        label.TextColor3 = Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = text
        label.LayoutOrder = order
        label.Parent = content
    end

    local function addCheck(labelText, getter, setter, order, tip)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.LayoutOrder = order
        frame.Parent = content
        local check = Instance.new("TextButton")
        check.AutoButtonColor = false
        check.BackgroundColor3 = getter() and Colors.Accent or Colors.Action
        check.BackgroundTransparency = 0
        check.BorderSizePixel = 0
        check.Position = UDim2.fromOffset(0, 3)
        check.Size = UDim2.fromOffset(26, 26)
        check.Text = ""
        check.Parent = frame
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(34, 0)
        label.Size = UDim2.new(1, -34, 1, 0)
        label.FontFace = UIFont
        label.TextSize = 17
        label.TextColor3 = Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = labelText
        label.Parent = frame
        addTooltip(label, tip or "Toggle")
        local function update() check.BackgroundColor3 = getter() and Colors.Accent or Colors.Action end
        check.MouseEnter:Connect(function()
            check.BackgroundColor3 = getter() and Colors.ToggleOnHover or Colors.ToggleOffHover
        end)
        check.MouseLeave:Connect(function() update() end)
        check.MouseButton1Click:Connect(function()
            playButtonSound()
            setter(not getter())
            update()
            saveConfig()
        end)
        addTooltip(check, tip or "Toggle")
    end

    local function addTextRow(labelText, getter, setter, order, placeholder)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 34)
        frame.LayoutOrder = order
        frame.Parent = content
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(0.4, 0, 1, 0)
        label.FontFace = UIFont
        label.TextSize = 15
        label.TextColor3 = Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = labelText
        label.Parent = frame
        local textbox = Instance.new("TextBox")
        textbox.BackgroundColor3 = Colors.ToggleOff
        textbox.BorderSizePixel = 0
        textbox.AnchorPoint = Vector2.new(1, 0.5)
        textbox.Position = UDim2.new(1, 0, 0.5, 0)
        textbox.Size = UDim2.fromOffset(150, 28)
        textbox.FontFace = UIFont
        textbox.TextSize = 15
        textbox.TextColor3 = Colors.Text
        textbox.PlaceholderText = placeholder or ""
        textbox.Text = getter()
        textbox.ClearTextOnFocus = false
        textbox.Parent = frame
        textbox.FocusLost:Connect(function()
            local text = textbox.Text:gsub("%s+", "")
            if text == "" then text = placeholder or "0" end
            textbox.Text = text
            setter(text)
            saveConfig()
        end)
    end

    local function addVolumeSlider(order)
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.new(1, 0, 0, 50)
        frame.LayoutOrder = order
        frame.Parent = content
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.new(1, 0, 0, 20)
        label.FontFace = UIFont
        label.TextSize = 15
        label.TextColor3 = Colors.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Text = "Volume (" .. math.floor(config.soundVolume * 100) .. "%)"
        label.Parent = frame
        local sliderBg = Instance.new("Frame")
        sliderBg.BackgroundColor3 = Colors.ToggleOff
        sliderBg.BorderSizePixel = 0
        sliderBg.Position = UDim2.fromOffset(0, 26)
        sliderBg.Size = UDim2.new(1, 0, 0, 14)
        sliderBg.Parent = frame
        local fill = Instance.new("Frame")
        fill.BackgroundColor3 = Colors.Accent
        fill.BorderSizePixel = 0
        fill.Size = UDim2.new(config.soundVolume, 0, 1, 0)
        fill.Parent = sliderBg
        local knob = Instance.new("TextButton")
        knob.AutoButtonColor = false
        knob.BackgroundColor3 = Colors.Accent
        knob.BorderSizePixel = 0
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(config.soundVolume, 0, 0.5, 0)
        knob.Size = UDim2.fromOffset(14, 18)
        knob.Text = ""
        knob.Parent = sliderBg
        local dragging = false
        local function update(pct)
            pct = math.clamp(pct, 0, 1)
            config.soundVolume = pct
            soundObj.Volume = pct
            menuSoundObj.Volume = pct
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, 0, 0.5, 0)
            label.Text = "Volume (" .. math.floor(pct * 100) .. "%)"
            saveConfig()
        end
        knob.MouseButton1Down:Connect(function() dragging = true end)
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            dragging = true
            local mousePos = UserInputService:GetMouseLocation()
            local position = mousePos.X - sliderBg.AbsolutePosition.X
            update(math.clamp(position / sliderBg.AbsoluteSize.X, 0, 1))
        end)
        UserInputService.InputChanged:Connect(function(input)
            if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            if not sliderBg.Parent then return end
            local mousePos = UserInputService:GetMouseLocation()
            local position = mousePos.X - sliderBg.AbsolutePosition.X
            update(math.clamp(position / sliderBg.AbsoluteSize.X, 0, 1))
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)
    end

    local function addButton(labelText, onClick, order, isPrimary)
        local btn = Instance.new("TextButton")
        btn.AutoButtonColor = false
        btn.BackgroundColor3 = isPrimary and Colors.Accent or Colors.Action
        btn.BorderSizePixel = 0
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.FontFace = UIFont
        btn.TextSize = 16
        btn.TextColor3 = Colors.Text
        btn.Text = labelText
        btn.LayoutOrder = order
        btn.Parent = content
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = isPrimary and Colors.ToggleOnHover or Colors.ActionHover
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = isPrimary and Colors.Accent or Colors.Action
        end)
        btn.MouseButton1Click:Connect(function()
            playButtonSound()
            onClick()
        end)
        return btn
    end

    addLabel("Button Sounds", 1)
    addCheck("Button Sounds", function() return config.guiSounds end, function(v) config.guiSounds = v end, 2, "Play sounds on button clicks")
    addTextRow("Sound ID", function() return config.soundId end, function(v) config.soundId = v end, 3, "0")

    addLabel("Open / Close Sounds", 4)
    addCheck("Open/Close Sounds", function() return config.menuSounds end, function(v) config.menuSounds = v end, 5, "Play sounds on menu open/close")
    addTextRow("Open ID", function() return config.openSoundId end, function(v) config.openSoundId = v end, 6, "0")
    addTextRow("Close ID", function() return config.closeSoundId end, function(v) config.closeSoundId = v end, 7, "0")
    addVolumeSlider(8)

    addLabel("Visual Settings", 9)
    addCheck("Blur Background", function()
        return getSetting("noxvape", "blur", "enabled", false)
    end, function(value)
        setSetting("noxvape", "blur", "enabled", value)
        updateBlur()
    end, 10, "Blur background when GUI is open")

    addLabel("Managers", 11)
    addButton("Fast Flag Manager", function() createFastFlagWindow() end, 12, false)
    addButton("Profiles", function() createProfilesWindow() end, 13, false)

    addLabel("Other", 14)

    local sdFrame = Instance.new("Frame")
    sdFrame.BackgroundTransparency = 1
    sdFrame.Size = UDim2.new(1, 0, 0, 42)
    sdFrame.LayoutOrder = 15
    sdFrame.Parent = content

    local sd = Instance.new("TextButton")
    sd.AutoButtonColor = false
    sd.BackgroundColor3 = Colors.Action
    sd.BorderSizePixel = 0
    sd.Size = UDim2.new(1, 0, 1, 0)
    sd.FontFace = UIFont
    sd.TextSize = 17
    sd.TextColor3 = Colors.Text
    sd.Text = "Self Destruct"
    sd.Parent = sdFrame
    sd.MouseEnter:Connect(function() tw(sd, { BackgroundColor3 = Colors.ActionHover }, 0.08) end)
    sd.MouseLeave:Connect(function() tw(sd, { BackgroundColor3 = Colors.Action }, 0.08) end)
    sd.MouseButton1Click:Connect(function() playButtonSound(); selfDestruct() end)
    addTooltip(sd, "Permanently destroy the GUI")

    settingsWindow = window
    settingsVisible = true
end

-- =========================================================================
-- MAIN INIT
-- =========================================================================
local function init()
    -- Auto-create noxvape_fastflags folder in workspace
    ensureFastFlagsFolder()

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.BackgroundTransparency = 1
    root.Size = UDim2.fromScale(1, 1)
    root.ZIndex = 10001
    root.Parent = screenGui

    for categoryIndex, categoryDefinition in ipairs(_categories) do
        local categoryName = categoryDefinition.name
        local items = categoryDefinition.items
        ensureCategoryData(categoryName)

        local savedX, savedY = getPosition(categoryName, 240 + ((categoryIndex - 1) * 218), 75)

        local card = Instance.new("Frame")
        card.Name = categoryName
        card.BackgroundColor3 = Colors.Panel
        card.BackgroundTransparency = 0
        card.BorderSizePixel = 0
        card.Size = UDim2.fromOffset(210, 560)
        card.Position = UDim2.fromOffset(savedX, savedY)
        card.Visible = config.tabs[categoryName] == true
        card.ClipsDescendants = true
        card.ZIndex = 11000 + categoryIndex
        card.Parent = root

        categoryFrames[categoryName] = card
        categoryStates[categoryName] = card.Visible

        local header = Instance.new("TextButton")
        header.Name = "Header"
        header.AutoButtonColor = false
        header.BackgroundColor3 = Colors.Panel
        header.BackgroundTransparency = 0
        header.BorderSizePixel = 0
        header.Size = UDim2.new(1, 0, 0, 46)
        header.Text = ""
        header.ZIndex = 11020 + categoryIndex
        header.Parent = card

        local categoryLabel = Instance.new("TextLabel")
        categoryLabel.BackgroundTransparency = 1
        categoryLabel.Size = UDim2.new(1, 0, 1, 0)
        categoryLabel.FontFace = UIFont
        categoryLabel.TextSize = 18
        categoryLabel.TextColor3 = Colors.Text
        categoryLabel.TextXAlignment = Enum.TextXAlignment.Center
        categoryLabel.TextYAlignment = Enum.TextYAlignment.Center
        categoryLabel.Text = categoryName
        categoryLabel.ZIndex = 11021 + categoryIndex
        categoryLabel.Parent = header

        makeDraggable(card, header, categoryName, false)

        header.MouseEnter:Connect(function() tw(header, { BackgroundColor3 = Colors.PanelHover }, 0.08) end)
        header.MouseLeave:Connect(function() tw(header, { BackgroundColor3 = Colors.Panel }, 0.08) end)

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
        scroll.ZIndex = 11010 + categoryIndex
        scroll.Parent = card

        local buttonLayout = Instance.new("UIListLayout")
        buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
        buttonLayout.Padding = UDim.new(0, 3)
        buttonLayout.Parent = scroll

        local scrollPadding = Instance.new("UIPadding")
        scrollPadding.PaddingBottom = UDim.new(0, 8)
        scrollPadding.Parent = scroll

        for itemIndex, item in ipairs(items) do
            local itemName = item.name
            local isToggle = item.toggle
            local description = item.description
            local action = item.action or function() end
            local extraSettings = item.settings

            local currentState = isToggle and getFeatureState(categoryName, itemName) or false

            local wrapper = Instance.new("Frame")
            wrapper.Name = itemName .. "_Wrapper"
            wrapper.BackgroundTransparency = 1
            wrapper.Size = UDim2.new(1, 0, 0, 36)
            wrapper.AutomaticSize = Enum.AutomaticSize.Y
            wrapper.LayoutOrder = itemIndex
            wrapper.ZIndex = 11100 + categoryIndex
            wrapper.Parent = scroll

            local button = Instance.new("TextButton")
            button.Name = itemName
            button.AutoButtonColor = false
            button.BackgroundColor3 = isToggle and (currentState and Colors.Accent or Colors.Action) or Colors.Action
            button.BackgroundTransparency = 0
            button.BorderSizePixel = 0
            button.Size = UDim2.new(1, 0, 0, 36)
            button.Text = ""
            button.ZIndex = 11110 + categoryIndex
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
            nameLabel.ZIndex = 11111 + categoryIndex
            nameLabel.Parent = button

            local settingsFrame = Instance.new("Frame")
            settingsFrame.Name = "Settings"
            settingsFrame.BackgroundColor3 = Colors.Setting
            settingsFrame.BackgroundTransparency = 0
            settingsFrame.BorderSizePixel = 0
            settingsFrame.Position = UDim2.fromOffset(0, 36)
            settingsFrame.Size = UDim2.new(1, 0, 0, 0)
            settingsFrame.AutomaticSize = Enum.AutomaticSize.Y
            settingsFrame.Visible = false
            settingsFrame.ZIndex = 11105 + categoryIndex
            settingsFrame.Parent = wrapper

            local settingsPadding = Instance.new("UIPadding")
            settingsPadding.PaddingTop = UDim.new(0, 6)
            settingsPadding.PaddingBottom = UDim.new(0, 6)
            settingsPadding.PaddingLeft = UDim.new(0, 8)
            settingsPadding.PaddingRight = UDim.new(0, 8)
            settingsPadding.Parent = settingsFrame

            local settingsLayout = Instance.new("UIListLayout")
            settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
            settingsLayout.Padding = UDim.new(0, 4)
            settingsLayout.Parent = settingsFrame

            local hovering = false

            local function refreshColor()
                if isToggle then
                    button.BackgroundColor3 = currentState and Colors.Accent or Colors.Action
                else
                    button.BackgroundColor3 = hovering and Colors.ActionHover or Colors.Action
                end
            end

            button.MouseEnter:Connect(function() hovering = true; refreshColor() end)
            button.MouseLeave:Connect(function() hovering = false; refreshColor() end)
            addTooltip(button, description)

            local function performToggle()
                if not isToggle then
                    local ok, result = pcall(action)
                    if not ok then warn("[NoxLib]", result) end
                    return
                end
                local newState = not currentState
                local ok, result = pcall(action, newState)
                local success = ok and result ~= false
                if not ok then warn("[NoxLib]", result) end
                if success then
                    currentState = newState
                    config.features[categoryName][itemName] = currentState
                    refreshColor()
                    if currentState then notifyEnabled(itemName .. " enabled")
                    else notifyWarning(itemName .. " disabled") end
                    saveConfig()
                else
                    refreshColor()
                end
            end

            button.MouseButton1Click:Connect(function() playButtonSound(); performToggle() end)
            button.MouseButton2Click:Connect(function()
                hideTooltip()
                settingsFrame.Visible = not settingsFrame.Visible
            end)

            local keybindRow = Instance.new("Frame")
            keybindRow.BackgroundTransparency = 1
            keybindRow.Size = UDim2.new(1, 0, 0, 32)
            keybindRow.LayoutOrder = 1
            keybindRow.Parent = settingsFrame

            local keybindLabel = Instance.new("TextLabel")
            keybindLabel.BackgroundTransparency = 1
            keybindLabel.Size = UDim2.new(0.45, 0, 1, 0)
            keybindLabel.FontFace = UIFont
            keybindLabel.TextSize = 14
            keybindLabel.TextColor3 = Colors.Text
            keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            keybindLabel.Text = "Bind"
            keybindLabel.Parent = keybindRow
            addTooltip(keybindLabel, "Click to bind a key")

            local keybindButton = Instance.new("TextButton")
            keybindButton.AutoButtonColor = false
            keybindButton.BackgroundColor3 = Colors.Action
            keybindButton.BackgroundTransparency = 0
            keybindButton.BorderSizePixel = 0
            keybindButton.AnchorPoint = Vector2.new(1, 0.5)
            keybindButton.Position = UDim2.new(1, 0, 0.5, 0)
            keybindButton.Size = UDim2.fromOffset(96, 28)
            keybindButton.FontFace = UIFont
            keybindButton.TextSize = 16
            keybindButton.TextColor3 = Colors.Text
            keybindButton.TextXAlignment = Enum.TextXAlignment.Center
            keybindButton.TextYAlignment = Enum.TextYAlignment.Center
            keybindButton.Text = getKeybind(categoryName, itemName) or "NONE"
            keybindButton.Parent = keybindRow
            keybindButton.MouseEnter:Connect(function() keybindButton.BackgroundColor3 = Colors.ActionHover end)
            keybindButton.MouseLeave:Connect(function() keybindButton.BackgroundColor3 = Colors.Action end)
            addTooltip(keybindButton, "Backspace/Escape to clear")

            keybindButton.MouseButton1Click:Connect(function()
                playButtonSound()
                if waitingForBind then
                    waitingForBind.button.Text = getKeybind(waitingForBind.category, waitingForBind.feature) or "NONE"
                    waitingForBind.button.BackgroundColor3 = Colors.Action
                end
                waitingForBind = { category = categoryName, feature = itemName, button = keybindButton }
                keybindButton.Text = "Press key..."
                keybindButton.BackgroundColor3 = Colors.Accent
            end)

            if type(extraSettings) == "table" then
                for settingIndex, setting in ipairs(extraSettings) do
                    if type(setting) ~= "table" then continue end
                    local settingType = tostring(setting.type or "")
                    local settingName = tostring(setting.name or setting.key or ("Setting " .. settingIndex))
                    local settingKey = tostring(setting.key or setting.name or ("setting" .. settingIndex))
                    local order = 10 + settingIndex

                    if settingType == "slider" then
                        local min = tonumber(setting.min) or 0
                        local max = tonumber(setting.max) or 100
                        if max < min then min, max = max, min end
                        local default = tonumber(setting.default)
                        if default == nil then default = min end
                        default = math.clamp(default, min, max)
                        local step = tonumber(setting.step) or 1
                        if step <= 0 then step = 1 end
                        local current = tonumber(getSetting(categoryName, itemName, settingKey, default)) or default

                        local function roundToStep(value)
                            value = math.clamp(value, min, max)
                            local steps = math.floor(((value - min) / step) + 0.5)
                            local result = min + (steps * step)
                            return math.clamp(result, min, max)
                        end
                        current = roundToStep(current)

                        local function formatValue(value)
                            if step >= 1 and step == math.floor(step) then
                                return tostring(math.floor(value + 0.5))
                            end
                            local decimals = 0
                            local temp = step
                            while decimals < 10 and math.abs(temp - math.floor(temp)) > 0.000001 do
                                temp *= 10; decimals += 1
                            end
                            return string.format("%." .. decimals .. "f", value)
                        end

                        local frame = Instance.new("Frame")
                        frame.BackgroundTransparency = 1
                        frame.Size = UDim2.new(1, 0, 0, 48)
                        frame.LayoutOrder = order
                        frame.Parent = settingsFrame

                        local label = Instance.new("TextLabel")
                        label.BackgroundTransparency = 1
                        label.Size = UDim2.new(1, 0, 0, 18)
                        label.FontFace = UIFont
                        label.TextSize = 14
                        label.TextColor3 = Colors.Text
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.Text = settingName .. " (" .. formatValue(current) .. ")"
                        label.Parent = frame

                        local sliderBg = Instance.new("Frame")
                        sliderBg.BackgroundColor3 = Colors.ToggleOff
                        sliderBg.BorderSizePixel = 0
                        sliderBg.Position = UDim2.fromOffset(0, 24)
                        sliderBg.Size = UDim2.new(1, 0, 0, 14)
                        sliderBg.Parent = frame

                        local range = max - min
                        local percentage = range == 0 and 0 or math.clamp((current - min) / range, 0, 1)

                        local fill = Instance.new("Frame")
                        fill.BackgroundColor3 = Colors.Accent
                        fill.BorderSizePixel = 0
                        fill.Size = UDim2.new(percentage, 0, 1, 0)
                        fill.Parent = sliderBg

                        local knob = Instance.new("TextButton")
                        knob.AutoButtonColor = false
                        knob.BackgroundColor3 = Colors.Accent
                        knob.BorderSizePixel = 0
                        knob.AnchorPoint = Vector2.new(0.5, 0.5)
                        knob.Position = UDim2.new(percentage, 0, 0.5, 0)
                        knob.Size = UDim2.fromOffset(12, 16)
                        knob.Text = ""
                        knob.Parent = sliderBg

                        local dragging = false

                        local function updateSlider(value)
                            value = roundToStep(value)
                            setSetting(categoryName, itemName, settingKey, value)
                            local pct = range == 0 and 0 or math.clamp((value - min) / range, 0, 1)
                            fill.Size = UDim2.new(pct, 0, 1, 0)
                            knob.Position = UDim2.new(pct, 0, 0.5, 0)
                            label.Text = settingName .. " (" .. formatValue(value) .. ")"
                            safeCall(setting.onChanged or setting.action, value)
                        end

                        knob.MouseButton1Down:Connect(function() dragging = true end)
                        sliderBg.InputBegan:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                            dragging = true
                            local width = sliderBg.AbsoluteSize.X
                            if width > 0 then
                                local mousePos = UserInputService:GetMouseLocation()
                                local position = mousePos.X - sliderBg.AbsolutePosition.X
                                updateSlider(min + math.clamp(position / width, 0, 1) * range)
                            end
                        end)
                        local sliderConnection
                        sliderConnection = UserInputService.InputChanged:Connect(function(input)
                            if not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            if not sliderBg.Parent then
                                if sliderConnection then sliderConnection:Disconnect() end
                                return
                            end
                            local width = sliderBg.AbsoluteSize.X
                            if width <= 0 then return end
                            local mousePos = UserInputService:GetMouseLocation()
                            local position = mousePos.X - sliderBg.AbsolutePosition.X
                            updateSlider(min + math.clamp(position / width, 0, 1) * range)
                        end)
                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                        end)

                    elseif settingType == "colorpicker" then
                        local default = typeof(setting.default) == "Color3" and setting.default or Color3.fromRGB(255, 255, 255)
                        local current = getSetting(categoryName, itemName, settingKey, default)
                        if typeof(current) ~= "Color3" then current = default end

                        local hue, saturation, value = Color3.toHSV(current)

                        local frame = Instance.new("Frame")
                        frame.BackgroundTransparency = 1
                        frame.Size = UDim2.new(1, 0, 0, 38)
                        frame.AutomaticSize = Enum.AutomaticSize.Y
                        frame.LayoutOrder = order
                        frame.Parent = settingsFrame

                        local label = Instance.new("TextLabel")
                        label.BackgroundTransparency = 1
                        label.Size = UDim2.new(0.5, 0, 0, 38)
                        label.FontFace = UIFont
                        label.TextSize = 16
                        label.TextColor3 = Colors.Text
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.TextYAlignment = Enum.TextYAlignment.Center
                        label.Text = settingName
                        label.Parent = frame

                        local preview = Instance.new("TextButton")
                        preview.Name = "ColorPreview"
                        preview.AutoButtonColor = false
                        preview.BackgroundColor3 = current
                        preview.BorderSizePixel = 0
                        preview.AnchorPoint = Vector2.new(1, 0)
                        preview.Position = UDim2.new(1, 0, 0, 5)
                        preview.Size = UDim2.fromOffset(32, 28)
                        preview.Text = ""
                        preview.Parent = frame

                        local previewStroke = Instance.new("UIStroke")
                        previewStroke.Color = Color3.fromRGB(35, 40, 46)
                        previewStroke.Thickness = 1
                        previewStroke.Transparency = 0
                        previewStroke.Parent = preview

                        local pickerFrame = Instance.new("Frame")
                        pickerFrame.Name = "ColorPicker"
                        pickerFrame.BackgroundColor3 = Colors.Panel
                        pickerFrame.BorderSizePixel = 0
                        pickerFrame.Position = UDim2.fromOffset(0, 42)
                        pickerFrame.Size = UDim2.fromOffset(194, 190)
                        pickerFrame.Visible = false
                        pickerFrame.ZIndex = 25000
                        pickerFrame.Parent = frame

                        local pickerPadding = Instance.new("UIPadding")
                        pickerPadding.PaddingTop = UDim.new(0, 8)
                        pickerPadding.PaddingBottom = UDim.new(0, 8)
                        pickerPadding.PaddingLeft = UDim.new(0, 8)
                        pickerPadding.PaddingRight = UDim.new(0, 8)
                        pickerPadding.Parent = pickerFrame

                        local wheel = Instance.new("ImageButton")
                        wheel.Name = "ColorWheel"
                        wheel.AutoButtonColor = false
                        wheel.BackgroundTransparency = 1
                        wheel.Size = UDim2.fromOffset(150, 150)
                        wheel.Position = UDim2.fromOffset(8, 8)
                        wheel.ZIndex = 25001
                        wheel.Parent = pickerFrame
                        wheel.Image = "rbxassetid://6020299385"
                        wheel.ScaleType = Enum.ScaleType.Fit

                        local wheelPicker = Instance.new("Frame")
                        wheelPicker.Name = "Picker"
                        wheelPicker.AnchorPoint = Vector2.new(0.5, 0.5)
                        wheelPicker.Size = UDim2.fromOffset(10, 10)
                        wheelPicker.BackgroundColor3 = Color3.new(1, 1, 1)
                        wheelPicker.BorderSizePixel = 1
                        wheelPicker.BorderColor3 = Color3.new(0, 0, 0)
                        wheelPicker.ZIndex = 25002
                        wheelPicker.Parent = wheel

                        local darkness = Instance.new("Frame")
                        darkness.Name = "DarknessPicker"
                        darkness.BackgroundColor3 = Color3.new(1, 1, 1)
                        darkness.BorderSizePixel = 0
                        darkness.Position = UDim2.fromOffset(164, 8)
                        darkness.Size = UDim2.fromOffset(16, 150)
                        darkness.ZIndex = 25001
                        darkness.Parent = pickerFrame

                        local darknessGradient = Instance.new("UIGradient")
                        darknessGradient.Rotation = 90
                        darknessGradient.Parent = darkness

                        local darknessSlider = Instance.new("Frame")
                        darknessSlider.Name = "Slider"
                        darknessSlider.AnchorPoint = Vector2.new(0.5, 0.5)
                        darknessSlider.Position = UDim2.new(0.5, 0, 1 - value, 0)
                        darknessSlider.Size = UDim2.new(1, 6, 0, 4)
                        darknessSlider.BackgroundColor3 = Color3.new(1, 1, 1)
                        darknessSlider.BorderSizePixel = 0
                        darknessSlider.ZIndex = 25002
                        darknessSlider.Parent = darkness

                        local colorDisplay = Instance.new("Frame")
                        colorDisplay.Name = "ColorDisplay"
                        colorDisplay.BackgroundColor3 = current
                        colorDisplay.BorderSizePixel = 0
                        colorDisplay.Position = UDim2.fromOffset(8, 166)
                        colorDisplay.Size = UDim2.fromOffset(172, 12)
                        colorDisplay.ZIndex = 25002
                        colorDisplay.Parent = pickerFrame

                        local colorDisplayStroke = Instance.new("UIStroke")
                        colorDisplayStroke.Color = Color3.fromRGB(35, 40, 46)
                        colorDisplayStroke.Thickness = 1
                        colorDisplayStroke.Parent = colorDisplay

                        local function updateWheelPicker()
                            local centerX = wheel.AbsoluteSize.X / 2
                            local centerY = wheel.AbsoluteSize.Y / 2
                            local angle = math.pi - (hue * math.pi * 2)
                            local radius = saturation * math.min(wheel.AbsoluteSize.X, wheel.AbsoluteSize.Y) / 2
                            wheelPicker.Position = UDim2.fromOffset(
                                centerX + math.cos(angle) * radius,
                                centerY + math.sin(angle) * radius
                            )
                        end

                        local function updateDarknessSlider()
                            darknessSlider.Position = UDim2.new(0.5, 0, 1 - value, 0)
                        end

                        local function updateGradient()
                            darknessGradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, saturation, 1)),
                                ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                            })
                        end

                        local function applyColor()
                            current = Color3.fromHSV(hue, saturation, value)
                            preview.BackgroundColor3 = current
                            colorDisplay.BackgroundColor3 = current
                            updateWheelPicker()
                            updateDarknessSlider()
                            updateGradient()
                            setSetting(categoryName, itemName, settingKey, current)
                            safeCall(setting.onChanged or setting.action, current)
                        end

                        local wheelDragging = false
                        local darknessDragging = false

                        local function updateWheelFromMouse()
                            local mouse = UserInputService:GetMouseLocation()
                            local center = wheel.AbsolutePosition + (wheel.AbsoluteSize / 2)
                            local offset = mouse - center
                            local radius = math.min(wheel.AbsoluteSize.X, wheel.AbsoluteSize.Y) / 2
                            local distance = offset.Magnitude
                            if distance > radius then
                                offset = offset.Unit * radius
                                distance = radius
                            end
                            saturation = distance <= 0 and 0 or math.clamp(distance / radius, 0, 1)
                            local angle = math.atan2(offset.Y, offset.X)
                            hue = (math.pi - angle) / (math.pi * 2)
                            hue = hue % 1
                            wheelPicker.Position = UDim2.fromOffset(
                                wheel.AbsoluteSize.X / 2 + offset.X,
                                wheel.AbsoluteSize.Y / 2 + offset.Y
                            )
                            updateGradient()
                            applyColor()
                        end

                        local function updateDarknessFromMouse()
                            local mouseY = UserInputService:GetMouseLocation().Y
                            local top = darkness.AbsolutePosition.Y
                            local height = darkness.AbsoluteSize.Y
                            local position = math.clamp(mouseY - top, 0, height)
                            value = 1 - math.clamp(position / height, 0, 1)
                            darknessSlider.Position = UDim2.new(0.5, 0, 0, position)
                            applyColor()
                        end

                        wheel.MouseButton1Down:Connect(function()
                            wheelDragging = true
                            updateWheelFromMouse()
                        end)
                        darkness.InputBegan:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                            darknessDragging = true
                            updateDarknessFromMouse()
                        end)
                        darknessSlider.InputBegan:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                            darknessDragging = true
                            updateDarknessFromMouse()
                        end)

                        local colorPickerConnection
                        colorPickerConnection = UserInputService.InputChanged:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                            if not frame.Parent then
                                if colorPickerConnection then colorPickerConnection:Disconnect() end
                                return
                            end
                            if wheelDragging then updateWheelFromMouse()
                            elseif darknessDragging then updateDarknessFromMouse() end
                        end)

                        UserInputService.InputEnded:Connect(function(input)
                            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                            wheelDragging = false
                            darknessDragging = false
                        end)

                        local function closePicker()
                            pickerFrame.Visible = false
                            frame.Size = UDim2.new(1, 0, 0, 38)
                        end

                        local function openPicker()
                            pickerFrame.Visible = true
                            frame.Size = UDim2.new(1, 0, 0, 232)
                            updateWheelPicker()
                            updateDarknessSlider()
                            updateGradient()
                        end

                        preview.MouseEnter:Connect(function() previewStroke.Color = Colors.Accent end)
                        preview.MouseLeave:Connect(function() previewStroke.Color = Color3.fromRGB(35, 40, 46) end)
                        preview.MouseButton1Click:Connect(function()
                            if pickerFrame.Visible then closePicker() else openPicker() end
                        end)

                        updateWheelPicker()
                        updateDarknessSlider()
                        updateGradient()

                        -- SYNCHRONIZED RGB BUTTON
                        local rgbBtn = Instance.new("TextButton")
                        rgbBtn.Name = "RGBButton"
                        rgbBtn.AutoButtonColor = false
                        rgbBtn.BackgroundColor3 = Colors.Action
                        rgbBtn.BackgroundTransparency = 0
                        rgbBtn.BorderSizePixel = 0
                        rgbBtn.AnchorPoint = Vector2.new(1, 0)
                        rgbBtn.Position = UDim2.new(1, -40, 0, 5)
                        rgbBtn.Size = UDim2.fromOffset(36, 28)
                        rgbBtn.FontFace = UIFont
                        rgbBtn.TextSize = 13
                        rgbBtn.TextColor3 = Colors.Text
                        rgbBtn.Text = "RGB"
                        rgbBtn.ZIndex = 3
                        rgbBtn.Parent = frame

                        local autoRGB = false
                        local rgbConnection = nil

                        local function toggleRGB()
                            if autoRGB then
                                autoRGB = false
                                if rgbConnection then rgbConnection:Disconnect(); rgbConnection = nil end
                                rgbBtn.BackgroundColor3 = Colors.Action
                            else
                                autoRGB = true
                                rgbBtn.BackgroundColor3 = Colors.Accent
                                rgbConnection = RunService.Heartbeat:Connect(function()
                                    if not frame.Parent then
                                        if rgbConnection then rgbConnection:Disconnect(); rgbConnection = nil end
                                        return
                                    end
                                    hue = (tick() * RGB_SPEED) % 1
                                    updateWheelPicker()
                                    updateGradient()
                                    applyColor()
                                end)
                            end
                        end

                        rgbBtn.MouseEnter:Connect(function()
                            if not autoRGB then rgbBtn.BackgroundColor3 = Colors.ActionHover end
                        end)
                        rgbBtn.MouseLeave:Connect(function()
                            if not autoRGB then rgbBtn.BackgroundColor3 = Colors.Action end
                        end)
                        rgbBtn.MouseButton1Click:Connect(function()
                            playButtonSound()
                            toggleRGB()
                        end)
                        addTooltip(rgbBtn, "Synchronized RGB cycling")

                    elseif settingType == "dropdown" then
                        local options = type(setting.options) == "table" and setting.options or {}
                        local default = setting.default
                        if default == nil then default = options[1] or "None" end
                        local current = getSetting(categoryName, itemName, settingKey, default)

                        local frame = Instance.new("Frame")
                        frame.BackgroundTransparency = 1
                        frame.BorderSizePixel = 0
                        frame.Size = UDim2.new(1, 0, 0, 38)
                        frame.LayoutOrder = order
                        frame.Parent = settingsFrame

                        local label = Instance.new("TextLabel")
                        label.BackgroundTransparency = 1
                        label.Size = UDim2.new(0.5, 0, 1, 0)
                        label.FontFace = UIFont
                        label.TextSize = 16
                        label.TextColor3 = Colors.Text
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.Text = settingName
                        label.Parent = frame

                        local dropdown = Instance.new("TextButton")
                        dropdown.AutoButtonColor = false
                        dropdown.BackgroundColor3 = Colors.Action
                        dropdown.BorderSizePixel = 0
                        dropdown.AnchorPoint = Vector2.new(1, 0)
                        dropdown.Position = UDim2.new(1, 0, 0, 0)
                        dropdown.Size = UDim2.fromOffset(120, 38)
                        dropdown.FontFace = UIFont
                        dropdown.TextSize = 15
                        dropdown.TextColor3 = Colors.Text
                        dropdown.TextTruncate = Enum.TextTruncate.AtEnd
                        dropdown.Text = tostring(current)
                        dropdown.ZIndex = 20050
                        dropdown.Parent = frame

                        local dropdownContainer = Instance.new("Frame")
                        dropdownContainer.Name = "DropdownOptions"
                        dropdownContainer.BackgroundColor3 = Colors.Setting
                        dropdownContainer.BackgroundTransparency = 0
                        dropdownContainer.BorderSizePixel = 0
                        dropdownContainer.Size = UDim2.new(1, 0, 0, 0)
                        dropdownContainer.AutomaticSize = Enum.AutomaticSize.Y
                        dropdownContainer.LayoutOrder = order + 100
                        dropdownContainer.Visible = false
                        dropdownContainer.ZIndex = 20051
                        dropdownContainer.Parent = settingsFrame

                        local optionsLayout = Instance.new("UIListLayout")
                        optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                        optionsLayout.Padding = UDim.new(0, 2)
                        optionsLayout.Parent = dropdownContainer

                        local function closeDropdown()
                            dropdownContainer.Visible = false
                            dropdown.BackgroundColor3 = Colors.Action
                        end

                        for optionIndex, option in ipairs(options) do
                            local optionButton = Instance.new("TextButton")
                            optionButton.AutoButtonColor = false
                            optionButton.BackgroundColor3 = Colors.Action
                            optionButton.BorderSizePixel = 0
                            optionButton.Size = UDim2.new(1, 0, 0, 34)
                            optionButton.FontFace = UIFont
                            optionButton.TextSize = 15
                            optionButton.TextColor3 = Colors.Text
                            optionButton.Text = tostring(option)
                            optionButton.LayoutOrder = optionIndex
                            optionButton.ZIndex = 20052
                            optionButton.Parent = dropdownContainer
                            optionButton.MouseEnter:Connect(function() optionButton.BackgroundColor3 = Colors.ActionHover end)
                            optionButton.MouseLeave:Connect(function() optionButton.BackgroundColor3 = Colors.Action end)
                            optionButton.MouseButton1Click:Connect(function()
                                current = option
                                dropdown.Text = tostring(current)
                                setSetting(categoryName, itemName, settingKey, current)
                                safeCall(setting.onChanged or setting.action, current)
                                closeDropdown()
                            end)
                        end

                        dropdown.MouseEnter:Connect(function() dropdown.BackgroundColor3 = Colors.ActionHover end)
                        dropdown.MouseLeave:Connect(function()
                            if not dropdownContainer.Visible then
                                dropdown.BackgroundColor3 = Colors.Action
                            end
                        end)
                        dropdown.MouseButton1Click:Connect(function()
                            dropdownContainer.Visible = not dropdownContainer.Visible
                            dropdown.BackgroundColor3 = dropdownContainer.Visible and Colors.ActionHover or Colors.Action
                        end)

                    elseif settingType == "checkbox" then
                        local default = setting.default == true
                        local current = getSetting(categoryName, itemName, settingKey, default) == true

                        local frame = Instance.new("Frame")
                        frame.BackgroundTransparency = 1
                        frame.BorderSizePixel = 0
                        frame.Size = UDim2.new(1, 0, 0, 38)
                        frame.LayoutOrder = order
                        frame.Parent = settingsFrame

                        local check = Instance.new("TextButton")
                        check.Name = "Check"
                        check.AutoButtonColor = false
                        check.BackgroundColor3 = current and Colors.ToggleOn or Colors.ToggleOff
                        check.BorderSizePixel = 0
                        check.Position = UDim2.fromOffset(6, 4)
                        check.Size = UDim2.fromOffset(30, 30)
                        check.Text = ""
                        check.Parent = frame

                        local label = Instance.new("TextLabel")
                        label.BackgroundTransparency = 1
                        label.Position = UDim2.fromOffset(48, 0)
                        label.Size = UDim2.new(1, -48, 1, 0)
                        label.FontFace = UIFont
                        label.TextSize = 16
                        label.TextColor3 = Colors.Text
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.TextTruncate = Enum.TextTruncate.AtEnd
                        label.Text = settingName
                        label.Parent = frame

                        local function updateCheckbox()
                            check.BackgroundColor3 = current and Colors.ToggleOn or Colors.ToggleOff
                        end
                        check.MouseEnter:Connect(function()
                            check.BackgroundColor3 = current and Colors.ToggleOnHover or Colors.ToggleOffHover
                        end)
                        check.MouseLeave:Connect(function() updateCheckbox() end)
                        check.MouseButton1Click:Connect(function()
                            current = not current
                            updateCheckbox()
                            setSetting(categoryName, itemName, settingKey, current)
                            safeCall(setting.onChanged or setting.action, current)
                        end)

                    elseif settingType == "textbox" then
                        local frame = Instance.new("Frame")
                        frame.BackgroundTransparency = 1
                        frame.Size = UDim2.new(1, 0, 0, 34)
                        frame.LayoutOrder = order
                        frame.Parent = settingsFrame

                        local label = Instance.new("TextLabel")
                        label.BackgroundTransparency = 1
                        label.Size = UDim2.new(0.4, 0, 1, 0)
                        label.FontFace = UIFont
                        label.TextSize = 14
                        label.TextColor3 = Colors.Text
                        label.TextXAlignment = Enum.TextXAlignment.Left
                        label.Text = settingName
                        label.Parent = frame

                        local textbox = Instance.new("TextBox")
                        textbox.BackgroundColor3 = Colors.ToggleOff
                        textbox.BorderSizePixel = 0
                        textbox.AnchorPoint = Vector2.new(1, 0.5)
                        textbox.Position = UDim2.new(1, 0, 0.5, 0)
                        textbox.Size = UDim2.fromOffset(140, 28)
                        textbox.FontFace = UIFont
                        textbox.TextSize = 14
                        textbox.TextColor3 = Colors.Text
                        textbox.Text = tostring(getSetting(categoryName, itemName, settingKey, setting.default or ""))
                        textbox.ClearTextOnFocus = false
                        textbox.Parent = frame
                        textbox.FocusLost:Connect(function()
                            setSetting(categoryName, itemName, settingKey, textbox.Text)
                            safeCall(setting.onChanged or setting.action, textbox.Text)
                        end)
                    end
                end
            end

            buttonData[categoryName] = buttonData[categoryName] or {}
            buttonData[categoryName][itemName] = {
                button = button,
                wrapper = wrapper,
                settings = settingsFrame,
                isToggle = isToggle,
                keybindButton = keybindButton,
                action = action,
                getState = function() return currentState end,
                toggle = performToggle,
                setState = function(state, skipSave)
                    currentState = state and true or false
                    config.features[categoryName][itemName] = currentState
                    refreshColor()
                    if not skipSave then saveConfig() end
                end
            }

            if isToggle and currentState then
                local ok, result = pcall(action, true)
                if not ok or result == false then
                    currentState = false
                    config.features[categoryName][itemName] = false
                    refreshColor()
                    notifyWarning(itemName .. " disabled (condition not met)")
                    saveConfig()
                end
            end
        end
    end

    -- Tab panel
    local noxX = tonumber(config.noxPosition.x) or 18
    local noxY = tonumber(config.noxPosition.y) or 75

    tabPanel = Instance.new("Frame")
    tabPanel.Name = "noxvape"
    tabPanel.BackgroundColor3 = Colors.Panel
    tabPanel.BackgroundTransparency = 0
    tabPanel.BorderSizePixel = 0
    tabPanel.Size = UDim2.fromOffset(210, 560)
    tabPanel.Position = UDim2.fromOffset(noxX, noxY)
    tabPanel.ClipsDescendants = true
    tabPanel.ZIndex = 20000
    tabPanel.Parent = screenGui

    local tabHeader = Instance.new("TextButton")
    tabHeader.Name = "Header"
    tabHeader.AutoButtonColor = false
    tabHeader.BackgroundColor3 = Colors.Panel
    tabHeader.BackgroundTransparency = 0
    tabHeader.BorderSizePixel = 0
    tabHeader.Size = UDim2.new(1, 0, 0, 46)
    tabHeader.Text = ""
    tabHeader.ZIndex = 20001
    tabHeader.Parent = tabPanel

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.BackgroundTransparency = 1
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.fromScale(0.5, 0.5)
    logo.Size = UDim2.fromScale(1.4, 1.4)
    logo.ScaleType = Enum.ScaleType.Fit
    logo.ZIndex = 20002
    logo.Parent = tabHeader

    task.spawn(function()
        if type(request) == "function" and type(writefile) == "function" then
            local needDownload = true
            if type(isfile) == "function" then
                needDownload = not isfile(LOGO_FILE)
            end
            if needDownload then
                pcall(function()
                    local response = request({ Url = LOGO_URL, Method = "GET" })
                    if response and response.Success and response.Body then
                        writefile(LOGO_FILE, response.Body)
                    end
                end)
            end
        end
        task.wait(0.12)
        if type(isfile) == "function" and isfile(LOGO_FILE) then
            local ok, asset = pcall(function() return getCustomAsset(LOGO_FILE) end)
            if ok and asset then logo.Image = asset end
        end
    end)

    makeDraggable(tabPanel, tabHeader, "noxvape", true)

    local tabScroll = Instance.new("Frame")
    tabScroll.Name = "Tabs"
    tabScroll.BackgroundTransparency = 1
    tabScroll.Position = UDim2.fromOffset(8, 54)
    tabScroll.Size = UDim2.new(1, -16, 0, 450)
    tabScroll.ZIndex = 20004
    tabScroll.Parent = tabPanel

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.Parent = tabScroll

    for index, categoryDefinition in ipairs(_categories) do
        local categoryName = categoryDefinition.name
        local tabButton = Instance.new("TextButton")
        tabButton.Name = categoryName
        tabButton.LayoutOrder = index
        tabButton.AutoButtonColor = false
        tabButton.BackgroundColor3 = Colors.Action
        tabButton.BackgroundTransparency = 0
        tabButton.BorderSizePixel = 0
        tabButton.Size = UDim2.new(1, 0, 0, 36)
        tabButton.FontFace = UIFont
        tabButton.TextSize = 17
        tabButton.TextColor3 = Colors.Text
        tabButton.Text = categoryName
        tabButton.TextXAlignment = Enum.TextXAlignment.Center
        tabButton.ZIndex = 20005
        tabButton.Parent = tabScroll
        tabButton.MouseEnter:Connect(function() tw(tabButton, { BackgroundColor3 = Colors.ActionHover }, 0.08) end)
        tabButton.MouseLeave:Connect(function() tw(tabButton, { BackgroundColor3 = Colors.Action }, 0.08) end)
        tabButton.MouseButton1Click:Connect(function()
            playButtonSound()
            local card = categoryFrames[categoryName]
            if not card or not card.Parent then return end
            categoryStates[categoryName] = not categoryStates[categoryName]
            card.Visible = categoryStates[categoryName]
            config.tabs[categoryName] = categoryStates[categoryName]
            saveConfig()
        end)
        addTooltip(tabButton, "Toggle " .. categoryName .. " tab")
    end

    local settingsContainer = Instance.new("Frame")
    settingsContainer.Name = "SettingsButtonContainer"
    settingsContainer.BackgroundTransparency = 1
    settingsContainer.BorderSizePixel = 0
    settingsContainer.Position = UDim2.new(1, -48, 1, -48)
    settingsContainer.Size = UDim2.fromOffset(40, 40)
    settingsContainer.ZIndex = 20015
    settingsContainer.Parent = tabPanel

    local settingsButton = Instance.new("TextButton")
    settingsButton.Name = "SettingsButton"
    settingsButton.AutoButtonColor = false
    settingsButton.BackgroundTransparency = 1
    settingsButton.BorderSizePixel = 0
    settingsButton.Size = UDim2.fromScale(1, 1)
    settingsButton.Text = ""
    settingsButton.ZIndex = 20016
    settingsButton.Parent = settingsContainer

    local settingsIcon = Instance.new("ImageLabel")
    settingsIcon.Name = "SettingsIcon"
    settingsIcon.BackgroundTransparency = 1
    settingsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    settingsIcon.Position = UDim2.fromScale(0.5, 0.5)
    settingsIcon.Size = UDim2.fromScale(1, 1)
    settingsIcon.ScaleType = Enum.ScaleType.Fit
    settingsIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    settingsIcon.ZIndex = 20017
    settingsIcon.Parent = settingsButton

    task.spawn(function()
        if type(request) == "function" and type(writefile) == "function" then
            pcall(function()
                local response = request({ Url = SETTINGS_ICON_URL, Method = "GET" })
                if response and response.Success and response.Body then
                    writefile("nox_settings_icon.png", response.Body)
                    local asset = getCustomAsset("nox_settings_icon.png")
                    if asset then settingsIcon.Image = asset end
                end
            end)
        end
    end)

    if settingsIcon.Image == "" then
        settingsIcon.Image = "rbxassetid://6034654127"
    end

    settingsButton.MouseEnter:Connect(function() tw(settingsIcon, { ImageColor3 = Color3.fromRGB(180, 180, 180) }, 0.1) end)
    settingsButton.MouseLeave:Connect(function() tw(settingsIcon, { ImageColor3 = Color3.fromRGB(255, 255, 255) }, 0.1) end)
    addTooltip(settingsButton, "Open GUI settings")

    settingsButton.MouseButton1Click:Connect(function()
        playButtonSound()
        createSettingsWindow()
    end)

    -- Search
    local searchX = tonumber(config.searchPosition.x) or 300
    local searchY = tonumber(config.searchPosition.y) or 50
    local searchExpanded = config.searchExpanded or false

    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchBar"
    searchFrame.BackgroundColor3 = Colors.Panel
    searchFrame.BackgroundTransparency = 0
    searchFrame.BorderSizePixel = 0
    searchFrame.Size = searchExpanded and UDim2.fromOffset(420, 40) or UDim2.fromOffset(220, 40)
    searchFrame.Position = UDim2.fromOffset(searchX, searchY)
    searchFrame.ZIndex = 30000
    searchFrame.Parent = screenGui

    local searchHeader = Instance.new("TextButton")
    searchHeader.AutoButtonColor = false
    searchHeader.BackgroundColor3 = Colors.Panel
    searchHeader.BackgroundTransparency = 0
    searchHeader.BorderSizePixel = 0
    searchHeader.Size = UDim2.new(1, 0, 0, 40)
    searchHeader.Text = ""
    searchHeader.ZIndex = 30001
    searchHeader.Parent = searchFrame

    makeDraggable(searchFrame, searchHeader, "searchBar", false)

    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundColor3 = Colors.ToggleOff
    searchBox.BackgroundTransparency = 0
    searchBox.BorderSizePixel = 0
    searchBox.Position = UDim2.fromOffset(42, 5)
    searchBox.Size = UDim2.new(1, -52, 1, -10)
    searchBox.FontFace = UIFont
    searchBox.TextSize = 18
    searchBox.TextColor3 = Colors.Text
    searchBox.PlaceholderText = "Search features..."
    searchBox.PlaceholderColor3 = Colors.MutedText
    searchBox.Text = ""
    searchBox.ZIndex = 30002
    searchBox.Parent = searchFrame

    local searchButton = Instance.new("TextButton")
    searchButton.AutoButtonColor = false
    searchButton.BackgroundColor3 = Colors.Action
    searchButton.BackgroundTransparency = 0
    searchButton.BorderSizePixel = 0
    searchButton.Position = UDim2.fromOffset(5, 5)
    searchButton.Size = UDim2.fromOffset(30, 30)
    searchButton.Text = ""
    searchButton.ZIndex = 30003
    searchButton.Parent = searchFrame

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Size = UDim2.fromOffset(18, 18)
    searchIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    searchIcon.Image = "rbxassetid://6031154871"
    searchIcon.ImageColor3 = Colors.Text
    searchIcon.ScaleType = Enum.ScaleType.Fit
    searchIcon.ZIndex = 30004
    searchIcon.Parent = searchButton
    addTooltip(searchButton, "Toggle search bar width")

    task.spawn(function()
        if type(request) == "function" and type(writefile) == "function" then
            pcall(function()
                local response = request({ Url = SEARCH_ICON_URL, Method = "GET" })
                if response and response.Success and response.Body then
                    writefile("nox_search_icon.png", response.Body)
                    local asset = getCustomAsset("nox_search_icon.png")
                    if asset then searchIcon.Image = asset end
                end
            end)
        end
    end)

    local function toggleSearchExpand()
        searchExpanded = not searchExpanded
        config.searchExpanded = searchExpanded
        if searchExpanded then
            searchFrame.Size = UDim2.fromOffset(420, 40)
            searchButton.BackgroundColor3 = Colors.Accent
            searchIcon.ImageColor3 = Colors.Accent
        else
            searchFrame.Size = UDim2.fromOffset(220, 40)
            searchButton.BackgroundColor3 = Colors.Action
            searchIcon.ImageColor3 = Colors.Text
        end
        saveConfig()
    end

    searchButton.MouseEnter:Connect(function()
        searchButton.BackgroundColor3 = searchExpanded and Colors.ToggleOnHover or Colors.ActionHover
    end)
    searchButton.MouseLeave:Connect(function()
        searchButton.BackgroundColor3 = searchExpanded and Colors.Accent or Colors.Action
    end)
    searchButton.MouseButton1Click:Connect(function() playButtonSound(); toggleSearchExpand() end)

    filterButtons = function(query)
        if not tabPanel.Visible then return end
        query = string.lower(query)
        for categoryName, card in pairs(categoryFrames) do
            if card and card.Parent then
                local scroll = card:FindFirstChild("Buttons")
                if scroll then
                    local anyVisible = false
                    for _, child in ipairs(scroll:GetChildren()) do
                        if child:IsA("Frame") and child.Name:match("_Wrapper$") then
                            local button = child:FindFirstChildOfClass("TextButton")
                            if button then
                                local moduleName = button:FindFirstChild("ModuleName")
                                local text = (moduleName and moduleName.Text ~= "") and moduleName.Text or button.Name
                                local visible = query == "" or string.find(string.lower(text), query, 1, true) ~= nil
                                child.Visible = visible
                                if visible then anyVisible = true end
                            end
                        end
                    end
                    card.Visible = (query ~= "" and anyVisible) or (query == "" and categoryStates[categoryName])
                end
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        filterButtons(searchBox.Text)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or nil
        if not key then return end
        if waitingForBind then
            if key == "Backspace" or key == "Escape" then
                config.keybinds[waitingForBind.category][waitingForBind.feature] = nil
                waitingForBind.button.Text = "NONE"
            else
                local used = false
                for category, features in pairs(config.keybinds) do
                    if type(features) == "table" then
                        for feature, bound in pairs(features) do
                            if bound == key and not (category == waitingForBind.category and feature == waitingForBind.feature) then
                                used = true; break
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
        if gameProcessed then return end
        if key == config.guiKeybind then
            hideTooltip()
            setMenuVisible(not tabPanel.Visible)
            return
        end
        if UserInputService:GetFocusedTextBox() then return end
        for categoryName, features in pairs(config.keybinds) do
            if type(features) ~= "table" then continue end
            for featureName, bound in pairs(features) do
                if bound == key then
                    local data = buttonData[categoryName] and buttonData[categoryName][featureName]
                    if data and data.toggle then data.toggle() end
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

-- Public API
local NoxLib = {}

function NoxLib.addCategory(name)
    assert(type(name) == "string" and name ~= "", "NoxLib.addCategory: name must be a non-empty string")
    if _categoryMap[name] then return end
    local category = { name = name, items = {} }
    table.insert(_categories, category)
    _categoryMap[name] = category
end

function NoxLib.addButton(categoryName, opts)
    assert(type(categoryName) == "string", "NoxLib.addButton: categoryName must be string")
    assert(type(opts) == "table", "NoxLib.addButton: opts must be table")
    assert(type(opts.name) == "string" and opts.name ~= "", "NoxLib.addButton: opts.name required")
    if not _categoryMap[categoryName] then NoxLib.addCategory(categoryName) end
    local category = _categoryMap[categoryName]
    table.insert(category.items, {
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
