--[[
    NoxLib v1.0  —  noxvape GUI Framework
    Host this file on GitHub and load it with:
        local NoxLib = loadstring(game:HttpGet("YOUR_RAW_URL"))()

    API:
        NoxLib.addCategory(name)
        NoxLib.addButton(categoryName, opts)
            opts = {
                name        = "MyFeature",
                toggle      = true,         -- true = toggle, false = one-shot button
                description = "Tooltip text",
                action      = function(enabled) ... end,
                settings    = {             -- optional, shows on right-click
                    { type="slider",  name="Speed", key="speed", default=10, min=1, max=100 },
                    { type="textbox", name="ID",    key="id",    default="0" },
                }
            }
        NoxLib.notify(message, type)   -- type: "enabled"|"warning"|"error"
        NoxLib.Features.isEnabled(category, name)
        NoxLib.Features.enable(category, name)
        NoxLib.Features.disable(category, name)
        NoxLib.Features.forceOff(category, name)
        NoxLib.getSetting(cat, feat, key, default)
        NoxLib.setSetting(cat, feat, key, value)
        NoxLib.saveConfig()
        NoxLib.setMenuVisible(bool)
        NoxLib.init()    -- call AFTER all addCategory/addButton calls
]]

-- ─── Services ────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local RunService       = game:GetService("RunService")
local player           = Players.LocalPlayer
local playerGui        = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ─── Constants ───────────────────────────────────────────────────────────────
local CONFIG_FILE       = "noxvape.json"
local LOGO_FILE         = "noxvapev4.png"
local LOGO_URL          = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/noxvapev4.png"
local SEARCH_ICON_URL   = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/icons8-search-24.png"
local POGCHAMP_URL      = "https://raw.githubusercontent.com/Gorillatagmodder123456/a/main/pogchamp-removebg-preview.png"
local SETTINGS_ICON_URL = "https://github.com/Gorillatagmodder123456/a/raw/main/ChatGPT%20Image%20Aug%2026%2C%202026%2C%2007_00_05%20AM.png"

-- ─── Colors ──────────────────────────────────────────────────────────────────
local Colors = {
    Background    = Color3.fromRGB(1,1,2),
    Panel         = Color3.fromRGB(4,5,7),
    PanelHover    = Color3.fromRGB(9,11,15),
    ToggleOff     = Color3.fromRGB(7,9,12),
    ToggleOffHover= Color3.fromRGB(12,15,20),
    ToggleOn      = Color3.fromRGB(30,100,140),
    ToggleOnHover = Color3.fromRGB(40,120,165),
    Action        = Color3.fromRGB(10,12,16),
    ActionHover   = Color3.fromRGB(18,22,28),
    Setting       = Color3.fromRGB(5,7,10),
    Accent        = Color3.fromRGB(55,150,200),
    Warning       = Color3.fromRGB(255,165,0),
    Error         = Color3.fromRGB(220,50,50),
    Text          = Color3.fromRGB(235,240,245),
    MutedText     = Color3.fromRGB(140,150,160),
    Tooltip       = Color3.fromRGB(3,4,6),
}
local UIFont = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

-- ─── Internal helpers ─────────────────────────────────────────────────────────
local function getCustomAsset(path)
    if type(getcustomasset) == "function" then return getcustomasset(path) end
    if type(getsynasset)    == "function" then return getsynasset(path)    end
    return nil
end

local function canUseFiles()
    return type(writefile)=="function" and type(readfile)=="function" and type(isfile)=="function"
end

local function tw(obj, props, dur)
    if not obj or not obj.Parent then return end
    local a = TweenService:Create(obj, TweenInfo.new(dur or 0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
    a:Play(); return a
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return true end
    local ok, result = pcall(fn, ...)
    if not ok then warn("[NoxLib]", result); return false, result end
    return true, result
end

-- ─── Config ──────────────────────────────────────────────────────────────────
local config = {
    version        = 1,
    features       = {},
    tabs           = {},
    positions      = {},
    keybinds       = {},
    settings       = {},
    noxPosition    = {x=18,  y=75},
    searchPosition = {x=300, y=50},
    guiKeybind     = "RightShift",
    guiSounds      = false,
    soundId        = "0",
    menuSounds     = false,
    openSoundId    = "0",
    closeSoundId   = "0",
    soundVolume    = 0.5,
    searchExpanded = false,
}

local function loadConfig()
    if not canUseFiles() or not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if not ok or type(data)~="table" then return end
    for k,v in pairs(data) do
        if type(config[k])=="table" and type(v)=="table" then
            for kk,vv in pairs(v) do config[k][kk]=vv end
        else config[k]=v end
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
    for _,key in ipairs({"features","tabs","positions","keybinds","settings"}) do
        if type(config[key])~="table" then config[key]={} end
    end
    if type(config.noxPosition)~="table"    then config.noxPosition={x=18,y=75}     end
    if type(config.searchPosition)~="table" then config.searchPosition={x=300,y=50} end
    config.noxPosition.x    = tonumber(config.noxPosition.x) or 18
    config.noxPosition.y    = tonumber(config.noxPosition.y) or 75
    config.searchPosition.x = tonumber(config.searchPosition.x) or 300
    config.searchPosition.y = tonumber(config.searchPosition.y) or 50
    if type(config.guiKeybind)~="string" or config.guiKeybind=="" then config.guiKeybind="RightShift" end
    if type(config.guiSounds)~="boolean"    then config.guiSounds=false end
    if type(config.soundId)~="string"       then config.soundId=tostring(config.soundId or "0") end
    if type(config.menuSounds)~="boolean"   then config.menuSounds=false end
    if type(config.openSoundId)~="string"   then config.openSoundId=tostring(config.openSoundId or "0") end
    if type(config.closeSoundId)~="string"  then config.closeSoundId=tostring(config.closeSoundId or "0") end
    config.soundVolume = math.clamp(tonumber(config.soundVolume) or 0.5,0,1)
    if type(config.searchExpanded)~="boolean" then config.searchExpanded=false end
    config.settings["noxvape"] = config.settings["noxvape"] or {}
end
repairConfig()

-- ─── Config accessors (public) ───────────────────────────────────────────────
local function ensureCategoryData(cat)
    if type(config.features[cat])~="table" then config.features[cat]={} end
    if type(config.keybinds[cat])~="table"  then config.keybinds[cat]={} end
    if type(config.settings[cat])~="table"  then config.settings[cat]={} end
end

local function getFeatureState(cat,name)
    ensureCategoryData(cat)
    local v=config.features[cat][name]
    return type(v)=="boolean" and v or false
end

local function getKeybind(cat,name)
    ensureCategoryData(cat)
    local k=config.keybinds[cat][name]
    return (type(k)=="string" and k~="") and k or nil
end

local function getSetting(cat,feat,key,default)
    ensureCategoryData(cat)
    if type(config.settings[cat][feat])~="table" then config.settings[cat][feat]={} end
    local v=config.settings[cat][feat][key]
    if v==nil then config.settings[cat][feat][key]=default; return default end
    return v
end

local function setSetting(cat,feat,key,value)
    ensureCategoryData(cat)
    if type(config.settings[cat][feat])~="table" then config.settings[cat][feat]={} end
    config.settings[cat][feat][key]=value
    saveConfig()
end

local function getPosition(name,dx,dy)
    local p=config.positions[name]
    if type(p)=="table" and type(p.x)=="number" and type(p.y)=="number" then return p.x,p.y end
    return dx,dy
end

-- ─── Screen GUI (built immediately, before init()) ────────────────────────────
local oldGui = playerGui:FindFirstChild("Nox")
if oldGui then oldGui:Destroy() end
local oldBlur = Lighting:FindFirstChild("NoxBlur")
if oldBlur then oldBlur:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name="Nox"; screenGui.ResetOnSpawn=false; screenGui.IgnoreGuiInset=true
screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; screenGui.DisplayOrder=100000
screenGui.Parent=playerGui

-- ─── Notifications ────────────────────────────────────────────────────────────
local notifHolder = Instance.new("Frame")
notifHolder.Name="Notifications"; notifHolder.BackgroundTransparency=1
notifHolder.AnchorPoint=Vector2.new(1,1); notifHolder.Position=UDim2.new(1,-20,1,-20)
notifHolder.Size=UDim2.fromOffset(360,400); notifHolder.ZIndex=50000; notifHolder.Parent=screenGui

local notifLayout=Instance.new("UIListLayout")
notifLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right
notifLayout.VerticalAlignment=Enum.VerticalAlignment.Bottom
notifLayout.SortOrder=Enum.SortOrder.LayoutOrder; notifLayout.Padding=UDim.new(0,8)
notifLayout.Parent=notifHolder

local notifCounter=0; local activeNotifs={}; local MAX_NOTIFS=5
local PogchampAsset=nil

task.spawn(function()
    if type(request)=="function" and type(writefile)=="function" then
        pcall(function()
            local r=request({Url=POGCHAMP_URL,Method="GET"})
            if r and r.Success and r.Body then
                writefile("nox_pogchamp.png",r.Body)
                local a=getCustomAsset("nox_pogchamp.png")
                if a then PogchampAsset=a end
            end
        end)
    end
    PogchampAsset = PogchampAsset or "rbxassetid://10340520068"
end)

local function createNotification(msg, kind)
    if not screenGui or not screenGui.Parent then return end
    notifCounter+=1
    while #activeNotifs>=MAX_NOTIFS do
        local old=table.remove(activeNotifs,1)
        if old and old.Parent then old:Destroy() end
    end
    local accent = kind=="warning" and Colors.Warning or kind=="error" and Colors.Error or Colors.Accent

    local notif=Instance.new("Frame")
    notif.BackgroundColor3=Colors.Panel; notif.BackgroundTransparency=0.12
    notif.BorderSizePixel=0; notif.Size=UDim2.fromOffset(330,50)
    notif.LayoutOrder=notifCounter; notif.ZIndex=50001; notif.ClipsDescendants=true
    notif.Parent=notifHolder
    table.insert(activeNotifs,notif)

    local side=Instance.new("Frame")
    side.BackgroundColor3=accent; side.BorderSizePixel=0
    side.Size=UDim2.new(0,3,1,0); side.ZIndex=50005; side.Parent=notif

    local img=Instance.new("ImageLabel")
    img.BackgroundTransparency=1; img.Size=UDim2.fromOffset(28,28)
    img.Position=UDim2.fromOffset(6,11); img.Image=PogchampAsset or "rbxassetid://10340520068"
    img.ScaleType=Enum.ScaleType.Fit; img.ZIndex=50003; img.Parent=notif

    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1; lbl.Position=UDim2.fromOffset(42,0)
    lbl.Size=UDim2.new(1,-56,1,0); lbl.FontFace=UIFont; lbl.TextSize=17
    lbl.TextColor3=accent; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextYAlignment=Enum.TextYAlignment.Center; lbl.TextTruncate=Enum.TextTruncate.AtEnd
    lbl.Text=tostring(msg or ""); lbl.ZIndex=50002; lbl.Parent=notif

    local bar=Instance.new("Frame")
    bar.BackgroundColor3=accent; bar.BackgroundTransparency=0.2; bar.BorderSizePixel=0
    bar.Size=UDim2.new(1,0,0,3); bar.Position=UDim2.new(0,0,1,-3); bar.ZIndex=50004; bar.Parent=notif

    notif.Position=UDim2.fromOffset(360,0)
    tw(notif,{Position=UDim2.fromOffset(0,0)},0.22)
    local dur=2.4
    TweenService:Create(bar,TweenInfo.new(dur,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,3)}):Play()
    task.delay(dur+0.15,function()
        if not notif.Parent then return end
        local a2=tw(notif,{Position=UDim2.fromOffset(360,0)},0.18)
        a2.Completed:Connect(function()
            if notif.Parent then notif:Destroy() end
            for i,v in ipairs(activeNotifs) do if v==notif then table.remove(activeNotifs,i) break end end
        end)
    end)
end

local function notifyEnabled(m) createNotification(m,"enabled") end
local function notifyWarning(m) createNotification(m,"warning") end
local function notifyError(m)   createNotification(m,"error")   end

-- ─── Tooltip ─────────────────────────────────────────────────────────────────
local tooltip,tooltipToken=nil,0

local function hideTooltip()
    tooltipToken+=1
    if tooltip then pcall(function() tooltip:Destroy() end) tooltip=nil end
end

local function showTooltip(text)
    hideTooltip(); tooltipToken+=1; local tok=tooltipToken
    task.delay(0.08,function()
        if tok~=tooltipToken then return end
        local cam=workspace.CurrentCamera; if not cam then return end
        local mouse=UserInputService:GetMouseLocation()
        local f=Instance.new("Frame")
        f.Name="Tooltip"; f.BackgroundColor3=Colors.Tooltip; f.BorderSizePixel=0
        f.AutomaticSize=Enum.AutomaticSize.XY; f.ZIndex=60000; f.Parent=screenGui
        local pad=Instance.new("UIPadding")
        pad.PaddingTop=UDim.new(0,7); pad.PaddingBottom=UDim.new(0,7)
        pad.PaddingLeft=UDim.new(0,11); pad.PaddingRight=UDim.new(0,11); pad.Parent=f
        local l=Instance.new("TextLabel")
        l.BackgroundTransparency=1; l.AutomaticSize=Enum.AutomaticSize.XY
        l.FontFace=UIFont; l.TextSize=16; l.TextColor3=Colors.Text; l.Text=text; l.ZIndex=60001; l.Parent=f
        task.wait()
        if tok~=tooltipToken then if f.Parent then f:Destroy() end return end
        local vp=cam.ViewportSize; local w,h=f.AbsoluteSize.X,f.AbsoluteSize.Y
        local x,y=mouse.X+14,mouse.Y+16
        if x+w>vp.X-8 then x=mouse.X-w-14 end
        if y+h>vp.Y-8 then y=mouse.Y-h-16 end
        f.Position=UDim2.fromOffset(math.clamp(x,8,math.max(8,vp.X-w-8)),math.clamp(y,8,math.max(8,vp.Y-h-8)))
        tooltip=f
    end)
end

local function addTooltip(obj,text)
    if not text or text=="" then return end
    obj.MouseEnter:Connect(function() showTooltip(text) end)
    obj.MouseLeave:Connect(function() hideTooltip() end)
end

-- ─── Draggable ───────────────────────────────────────────────────────────────
local function makeDraggable(obj,handle,posName,isNox)
    local dragging=false; local dragStart,startPos; local mc,ec
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1 and inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
        dragging=true; dragStart=inp.Position; startPos=obj.Position; hideTooltip()
        if mc then mc:Disconnect() end; if ec then ec:Disconnect() end
        mc=UserInputService.InputChanged:Connect(function(i)
            if not dragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
            local d=i.Position-dragStart
            local x=startPos.X.Offset+d.X; local y=startPos.Y.Offset+d.Y
            local cam=workspace.CurrentCamera
            if cam then local vp=cam.ViewportSize
                x=math.clamp(x,0,math.max(0,vp.X-obj.AbsoluteSize.X))
                y=math.clamp(y,0,math.max(0,vp.Y-obj.AbsoluteSize.Y))
            end
            obj.Position=UDim2.fromOffset(x,y)
        end)
        ec=UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.MouseButton2 then return end
            dragging=false
            if mc then mc:Disconnect(); mc=nil end; if ec then ec:Disconnect(); ec=nil end
            if isNox then config.noxPosition={x=obj.Position.X.Offset,y=obj.Position.Y.Offset}
            elseif posName=="searchBar" then config.searchPosition={x=obj.Position.X.Offset,y=obj.Position.Y.Offset}
            else config.positions[posName]={x=obj.Position.X.Offset,y=obj.Position.Y.Offset} end
            saveConfig()
        end)
    end)
end

-- ─── Features API ────────────────────────────────────────────────────────────
local buttonData      = {}
local categoryFrames  = {}
local categoryStates  = {}

local Features = {}
function Features.get(cat,name)      return buttonData[cat] and buttonData[cat][name] end
function Features.isEnabled(cat,name)
    local d=Features.get(cat,name)
    if d and d.getState then return d.getState() end
    return getFeatureState(cat,name)
end
function Features.set(cat,name,enabled)
    local d=Features.get(cat,name)
    if not d then ensureCategoryData(cat); config.features[cat][name]=enabled and true or false; saveConfig(); return false end
    local cur=d.getState and d.getState() or false
    if cur==enabled then return true end
    if d.toggle then d.toggle(); return true end
    ensureCategoryData(cat); config.features[cat][name]=enabled and true or false
    if d.button then d.button.BackgroundColor3=enabled and Colors.Accent or Colors.Action end
    saveConfig(); return true
end
function Features.forceOff(cat,name)
    local d=Features.get(cat,name); ensureCategoryData(cat)
    if d and d.getState and d.getState() and type(d.action)=="function" then pcall(d.action,false) end
    config.features[cat][name]=false
    if d then
        if type(d.setState)=="function" then d.setState(false,true)
        elseif d.button then d.button.BackgroundColor3=Colors.Action end
    end
    saveConfig(); return true
end
function Features.disable(cat,name) return Features.forceOff(cat,name) end
function Features.enable(cat,name)  return Features.set(cat,name,true)  end

-- ─── Category registry (filled before init()) ─────────────────────────────────
-- Internal list: { {name, items=[{name,toggle,desc,action,settings},...]} }
local _categories = {}
local _categoryMap= {}   -- name -> category table

-- ─── Sound objects ───────────────────────────────────────────────────────────
local soundObj=Instance.new("Sound"); soundObj.Name="GUIClickSound"; soundObj.Volume=config.soundVolume; soundObj.Parent=screenGui
local menuSoundObj=Instance.new("Sound"); menuSoundObj.Name="MenuSound"; menuSoundObj.Volume=config.soundVolume; menuSoundObj.Parent=screenGui

local function playButtonSound()
    if not config.guiSounds then return end
    local id=config.soundId
    if id and id~="" and id~="0" then soundObj.SoundId="rbxassetid://"..id; pcall(function() soundObj:Play() end) end
end
local function playMenuSound(isOpen)
    if not config.menuSounds then return end
    local id=isOpen and config.openSoundId or config.closeSoundId
    if id and id~="" and id~="0" then menuSoundObj.SoundId="rbxassetid://"..id; pcall(function() menuSoundObj:Play() end) end
end

-- ─── Dim + Blur ──────────────────────────────────────────────────────────────
local dimFrame=Instance.new("Frame"); dimFrame.Name="BackgroundDim"
dimFrame.BackgroundColor3=Color3.new(0,0,0); dimFrame.BackgroundTransparency=0.55
dimFrame.BorderSizePixel=0; dimFrame.Size=UDim2.fromScale(1,1); dimFrame.ZIndex=10000
dimFrame.Visible=false; dimFrame.Active=true; dimFrame.Parent=screenGui

local blurEffect=Instance.new("BlurEffect"); blurEffect.Name="NoxBlur"
blurEffect.Size=18; blurEffect.Enabled=false; blurEffect.Parent=Lighting

local tabPanel  -- forward-declared; assigned in init()

local function updateBlur()
    if not tabPanel then return end
    blurEffect.Enabled=getSetting("noxvape","blur","enabled",false) and tabPanel.Visible
    dimFrame.Visible=tabPanel.Visible
end

-- ─── Other GUI management ────────────────────────────────────────────────────
local disabledGuiStates={}; local otherGuisDisabled=false

local function disableOtherScreenGuis()
    if otherGuisDisabled then return end
    otherGuisDisabled=true; disabledGuiStates={}
    for _,gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui~=screenGui then disabledGuiStates[gui]=gui.Enabled; gui.Enabled=false end
    end
end

local function restoreOtherScreenGuis()
    if not otherGuisDisabled then return end
    for gui,prev in pairs(disabledGuiStates) do
        if gui and gui.Parent then pcall(function() gui.Enabled=prev end) end
    end
    disabledGuiStates={}; otherGuisDisabled=false
end

local function selfDestruct()
    restoreOtherScreenGuis()
    createNotification("Self destruct initiated. Goodbye!","warning")
    task.wait(0.35)
    pcall(function() if soundObj     then soundObj:Stop();     soundObj:Destroy()     end end)
    pcall(function() if menuSoundObj then menuSoundObj:Stop(); menuSoundObj:Destroy() end end)
    pcall(function() if blurEffect   then blurEffect.Enabled=false; blurEffect:Destroy() end end)
    pcall(function() if dimFrame     then dimFrame:Destroy()   end end)
    pcall(function()
        for _,n in ipairs(activeNotifs) do if n and n.Parent then n:Destroy() end end
        activeNotifs={}
    end)
    pcall(function() if screenGui then screenGui:Destroy() end end)
    buttonData={}; categoryFrames={}; categoryStates={}
end

-- ─── init() — builds the entire UI from registered categories ─────────────────
local waitingForBind=nil
local settingsWindow=nil; local settingsVisible=false
local filterButtons  -- forward-declared

local function setMenuVisible(visible)
    if not tabPanel then return end
    local was=tabPanel.Visible
    tabPanel.Visible=visible; dimFrame.Visible=visible
    if settingsWindow then settingsWindow.Visible=visible and settingsVisible end
    for _,card in pairs(categoryFrames) do
        local catName=card.Name
        if card and card.Parent then card.Visible=visible and categoryStates[catName] end
    end
    -- search bar
    local sf=screenGui:FindFirstChild("SearchBar")
    if sf then sf.Visible=visible end
    if visible then
        disableOtherScreenGuis()
        local sb=sf and sf:FindFirstChildOfClass("TextBox")
        if sb and sb.Text~="" then filterButtons(sb.Text) end
        if not was then playMenuSound(true) end
    else
        restoreOtherScreenGuis()
        if was then playMenuSound(false) end
    end
    updateBlur()
end

local function init()
    -- ── Root frame ────────────────────────────────────────────────────────────
    local root=Instance.new("Frame"); root.Name="Root"; root.BackgroundTransparency=1
    root.Size=UDim2.fromScale(1,1); root.ZIndex=10001; root.Parent=screenGui

    -- ── Category cards ────────────────────────────────────────────────────────
    for catIndex,catDef in ipairs(_categories) do
        local catName=catDef.name; local items=catDef.items
        ensureCategoryData(catName)
        local savedX,savedY=getPosition(catName, 240+((catIndex-1)*218), 75)

        local card=Instance.new("Frame"); card.Name=catName
        card.BackgroundColor3=Colors.Panel; card.BackgroundTransparency=0; card.BorderSizePixel=0
        card.Size=UDim2.fromOffset(210,560); card.Position=UDim2.fromOffset(savedX,savedY)
        card.Visible=config.tabs[catName]==true; card.ClipsDescendants=true
        card.ZIndex=11000+catIndex; card.Parent=root
        categoryFrames[catName]=card; categoryStates[catName]=card.Visible

        local hdr=Instance.new("TextButton"); hdr.Name="Header"; hdr.AutoButtonColor=false
        hdr.BackgroundColor3=Colors.Panel; hdr.BackgroundTransparency=0; hdr.BorderSizePixel=0
        hdr.Size=UDim2.new(1,0,0,46); hdr.Text=""; hdr.ZIndex=11020+catIndex; hdr.Parent=card
        local catLbl=Instance.new("TextLabel"); catLbl.BackgroundTransparency=1
        catLbl.Size=UDim2.new(1,0,1,0); catLbl.FontFace=UIFont; catLbl.TextSize=18
        catLbl.TextColor3=Colors.Text; catLbl.TextXAlignment=Enum.TextXAlignment.Center
        catLbl.TextYAlignment=Enum.TextYAlignment.Center; catLbl.Text=catName
        catLbl.ZIndex=11021+catIndex; catLbl.Parent=hdr
        makeDraggable(card,hdr,catName,false)
        hdr.MouseEnter:Connect(function() tw(hdr,{BackgroundColor3=Colors.PanelHover},0.08) end)
        hdr.MouseLeave:Connect(function() tw(hdr,{BackgroundColor3=Colors.Panel},0.08) end)

        local scroll=Instance.new("ScrollingFrame"); scroll.Name="Buttons"
        scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
        scroll.Position=UDim2.fromOffset(8,54); scroll.Size=UDim2.new(1,-16,1,-62)
        scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=Colors.Accent
        scroll.ScrollingDirection=Enum.ScrollingDirection.Y
        scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.CanvasSize=UDim2.fromOffset(0,0)
        scroll.ZIndex=11010+catIndex; scroll.Parent=card
        local ul=Instance.new("UIListLayout"); ul.SortOrder=Enum.SortOrder.LayoutOrder
        ul.Padding=UDim.new(0,3); ul.Parent=scroll
        local sp=Instance.new("UIPadding"); sp.PaddingBottom=UDim.new(0,8); sp.Parent=scroll

        for itemIndex,item in ipairs(items) do
            local itemName    = item.name
            local isToggle    = item.toggle
            local description = item.description
            local action      = item.action or function() end
            local extraSettings = item.settings
            local currentState = isToggle and getFeatureState(catName,itemName) or false

            local wrapper=Instance.new("Frame"); wrapper.Name=itemName.."_Wrapper"
            wrapper.BackgroundTransparency=1; wrapper.Size=UDim2.new(1,0,0,36)
            wrapper.AutomaticSize=Enum.AutomaticSize.Y; wrapper.LayoutOrder=itemIndex
            wrapper.ZIndex=11100+catIndex; wrapper.Parent=scroll

            local button=Instance.new("TextButton"); button.Name=itemName; button.AutoButtonColor=false
            button.BackgroundColor3=isToggle and (currentState and Colors.Accent or Colors.Action) or Colors.Action
            button.BackgroundTransparency=0; button.BorderSizePixel=0
            button.Size=UDim2.new(1,0,0,36); button.Text=""; button.ZIndex=11110+catIndex; button.Parent=wrapper

            local nameLbl=Instance.new("TextLabel"); nameLbl.Name="ModuleName"
            nameLbl.BackgroundTransparency=1; nameLbl.Size=UDim2.new(1,0,1,0)
            nameLbl.FontFace=UIFont; nameLbl.TextSize=17; nameLbl.TextColor3=Colors.Text
            nameLbl.TextXAlignment=Enum.TextXAlignment.Center; nameLbl.TextYAlignment=Enum.TextYAlignment.Center
            nameLbl.TextTruncate=Enum.TextTruncate.AtEnd; nameLbl.Text=itemName
            nameLbl.ZIndex=11111+catIndex; nameLbl.Parent=button

            local sf2=Instance.new("Frame"); sf2.Name="Settings"; sf2.BackgroundColor3=Colors.Setting
            sf2.BackgroundTransparency=0; sf2.BorderSizePixel=0; sf2.Position=UDim2.fromOffset(0,36)
            sf2.Size=UDim2.new(1,0,0,0); sf2.AutomaticSize=Enum.AutomaticSize.Y; sf2.Visible=false
            sf2.ZIndex=11105+catIndex; sf2.Parent=wrapper
            local sfp=Instance.new("UIPadding"); sfp.PaddingTop=UDim.new(0,6); sfp.PaddingBottom=UDim.new(0,6)
            sfp.PaddingLeft=UDim.new(0,8); sfp.PaddingRight=UDim.new(0,8); sfp.Parent=sf2
            local sfl=Instance.new("UIListLayout"); sfl.SortOrder=Enum.SortOrder.LayoutOrder
            sfl.Padding=UDim.new(0,4); sfl.Parent=sf2

            local hovering=false
            local function refreshColor()
                if isToggle then button.BackgroundColor3=currentState and Colors.Accent or Colors.Action
                else button.BackgroundColor3=hovering and Colors.ActionHover or Colors.Action end
            end
            button.MouseEnter:Connect(function() hovering=true; refreshColor() end)
            button.MouseLeave:Connect(function() hovering=false; refreshColor() end)
            addTooltip(button,description)

            local function performToggle()
                if not isToggle then local ok,e=pcall(action); if not ok then warn("[NoxLib]",e) end; return end
                local newState=not currentState
                local ok,result=pcall(action,newState)
                local success=ok and result~=false
                if not ok then warn("[NoxLib]",result) end
                if success then
                    currentState=newState; config.features[catName][itemName]=currentState
                    refreshColor()
                    if currentState then notifyEnabled(itemName.." enabled") else notifyWarning(itemName.." disabled") end
                    saveConfig()
                else refreshColor() end
            end

            button.MouseButton1Click:Connect(function() playButtonSound(); performToggle() end)
            button.MouseButton2Click:Connect(function() hideTooltip(); sf2.Visible=not sf2.Visible end)

            -- Keybind row
            local kbRow=Instance.new("Frame"); kbRow.BackgroundTransparency=1
            kbRow.Size=UDim2.new(1,0,0,32); kbRow.LayoutOrder=1; kbRow.Parent=sf2
            local kbLbl=Instance.new("TextLabel"); kbLbl.BackgroundTransparency=1
            kbLbl.Size=UDim2.new(0.45,0,1,0); kbLbl.FontFace=UIFont; kbLbl.TextSize=14
            kbLbl.TextColor3=Colors.Text; kbLbl.TextXAlignment=Enum.TextXAlignment.Left
            kbLbl.Text="Bind"; kbLbl.Parent=kbRow
            addTooltip(kbLbl,"Click to bind a key")
            local kbBtn=Instance.new("TextButton"); kbBtn.AutoButtonColor=false
            kbBtn.BackgroundColor3=Colors.Action; kbBtn.BackgroundTransparency=0; kbBtn.BorderSizePixel=0
            kbBtn.AnchorPoint=Vector2.new(1,0.5); kbBtn.Position=UDim2.new(1,0,0.5,0)
            kbBtn.Size=UDim2.fromOffset(96,28); kbBtn.FontFace=UIFont; kbBtn.TextSize=16
            kbBtn.TextColor3=Colors.Text; kbBtn.Text=getKeybind(catName,itemName) or "NONE"; kbBtn.Parent=kbRow
            kbBtn.MouseEnter:Connect(function() kbBtn.BackgroundColor3=Colors.ActionHover end)
            kbBtn.MouseLeave:Connect(function() kbBtn.BackgroundColor3=Colors.Action end)
            addTooltip(kbBtn,"Backspace/Escape to clear")
            kbBtn.MouseButton1Click:Connect(function()
                playButtonSound()
                if waitingForBind then
                    waitingForBind.button.Text=getKeybind(waitingForBind.category,waitingForBind.feature) or "NONE"
                    waitingForBind.button.BackgroundColor3=Colors.Action
                end
                waitingForBind={category=catName,feature=itemName,button=kbBtn}
                kbBtn.Text="Press key..."; kbBtn.BackgroundColor3=Colors.Accent
            end)

            -- Extra settings
            if type(extraSettings)=="table" then
                for si,setting in ipairs(extraSettings) do
                    if type(setting)~="table" then
                        continue
                    end

                    local settingType = tostring(setting.type or "")
                    local settingName = tostring(setting.name or setting.key or ("Setting "..si))
                    local settingKey = tostring(setting.key or setting.name or ("setting"..si))
                    local order = 10 + si

                   if settingType=="slider" then
    local min = tonumber(setting.min) or 0
    local max = tonumber(setting.max) or 100
    if max < min then min,max=max,min end

    local default = tonumber(setting.default)
    if default==nil then default=min end
    default=math.clamp(default,min,max)

    -- Optional increment:
    -- step = 1     -> whole numbers
    -- step = 0.1   -> 0.1 increments
    -- step = 0.05  -> 0.05 increments
    -- step = 0.01  -> 0.01 increments
    local step = tonumber(setting.step) or 1
    if step <= 0 then step = 1 end

    local cv=tonumber(getSetting(catName,itemName,settingKey,default)) or default

    local function roundToStep(value)
        value = math.clamp(value,min,max)

        local steps = math.floor(((value-min)/step)+0.5)
        local result = min + (steps*step)

        return math.clamp(result,min,max)
    end

    cv=roundToStep(cv)

    local function formatValue(value)
        if step >= 1 and step == math.floor(step) then
            return tostring(math.floor(value+0.5))
        end

        local decimals=0
        local temp=step

        while decimals < 10 and math.abs(temp-math.floor(temp)) > 0.000001 do
            temp=temp*10
            decimals+=1
        end

        return string.format("%."..decimals.."f",value)
    end

    local fr=Instance.new("Frame")
    fr.BackgroundTransparency=1
    fr.Size=UDim2.new(1,0,0,48)
    fr.LayoutOrder=order
    fr.Parent=sf2

    local lbl=Instance.new("TextLabel")
    lbl.BackgroundTransparency=1
    lbl.Size=UDim2.new(1,0,0,18)
    lbl.FontFace=UIFont
    lbl.TextSize=14
    lbl.TextColor3=Colors.Text
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Text=settingName.." ("..formatValue(cv)..")"
    lbl.Parent=fr

    local sbg=Instance.new("Frame")
    sbg.BackgroundColor3=Colors.ToggleOff
    sbg.BorderSizePixel=0
    sbg.Position=UDim2.fromOffset(0,24)
    sbg.Size=UDim2.new(1,0,0,14)
    sbg.Parent=fr

    local range=max-min
    local pct=(range==0) and 0 or math.clamp((cv-min)/range,0,1)

    local sfill=Instance.new("Frame")
    sfill.BackgroundColor3=Colors.Accent
    sfill.BorderSizePixel=0
    sfill.Size=UDim2.new(pct,0,1,0)
    sfill.Parent=sbg

    local sknob=Instance.new("TextButton")
    sknob.AutoButtonColor=false
    sknob.BackgroundColor3=Colors.Accent
    sknob.BorderSizePixel=0
    sknob.AnchorPoint=Vector2.new(0.5,0.5)
    sknob.Position=UDim2.new(pct,0,0.5,0)
    sknob.Size=UDim2.fromOffset(12,16)
    sknob.Text=""
    sknob.Parent=sbg

    local function supdate(val)
        val=roundToStep(val)

        setSetting(catName,itemName,settingKey,val)

        local p=(range==0) and 0 or math.clamp((val-min)/range,0,1)

        sfill.Size=UDim2.new(p,0,1,0)
        sknob.Position=UDim2.new(p,0,0.5,0)

        lbl.Text=settingName.." ("..formatValue(val)..")"

        safeCall(setting.onChanged or setting.action,val)
    end

    local sdrag=false

    sknob.MouseButton1Down:Connect(function()
        sdrag=true
    end)

    sbg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            sdrag=true

            local width=sbg.AbsoluteSize.X

            if width>0 then
                local pos=UserInputService:GetMouseLocation().X-sbg.AbsolutePosition.X

                supdate(
                    min+math.clamp(pos/width,0,1)*range
                )
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not sdrag or inp.UserInputType~=Enum.UserInputType.MouseMovement then
            return
        end

        if not sbg.Parent then
            return
        end

        local width=sbg.AbsoluteSize.X

        if width<=0 then
            return
        end

        local pos=UserInputService:GetMouseLocation().X-sbg.AbsolutePosition.X

        supdate(
            min+math.clamp(pos/width,0,1)*range
        )
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            sdrag=false
        end
    end)

                    elseif settingType=="dropdown" then
                        local options=type(setting.options)=="table" and setting.options or {}
                        local default=setting.default
                        if default==nil then default=options[1] or "None" end
                        local current=getSetting(catName,itemName,settingKey,default)

                        local frame=Instance.new("Frame")
                        frame.BackgroundTransparency=1
                        frame.BorderSizePixel=0
                        frame.Size=UDim2.new(1,0,0,38)
                        frame.LayoutOrder=order
                        frame.Parent=sf2

                        local label=Instance.new("TextLabel")
                        label.BackgroundTransparency=1
                        label.Size=UDim2.new(0.5,0,1,0)
                        label.FontFace=UIFont
                        label.TextSize=16
                        label.TextColor3=Colors.Text
                        label.TextXAlignment=Enum.TextXAlignment.Left
                        label.Text=settingName
                        label.Parent=frame

                        local dropdown=Instance.new("TextButton")
                        dropdown.AutoButtonColor=false
                        dropdown.BackgroundColor3=Colors.Action
                        dropdown.BorderSizePixel=0
                        dropdown.AnchorPoint=Vector2.new(1,0)
                        dropdown.Position=UDim2.new(1,0,0,0)
                        dropdown.Size=UDim2.fromOffset(120,38)
                        dropdown.FontFace=UIFont
                        dropdown.TextSize=15
                        dropdown.TextColor3=Colors.Text
                        dropdown.TextTruncate=Enum.TextTruncate.AtEnd
                        dropdown.Text=tostring(current)
                        dropdown.ZIndex=20050
                        dropdown.Parent=frame

                        local dropdownContainer=Instance.new("Frame")
                        dropdownContainer.Name="DropdownOptions"
                        dropdownContainer.BackgroundColor3=Colors.Setting
                        dropdownContainer.BackgroundTransparency=0
                        dropdownContainer.BorderSizePixel=0
                        dropdownContainer.Size=UDim2.new(1,0,0,0)
                        dropdownContainer.AutomaticSize=Enum.AutomaticSize.Y
                        dropdownContainer.LayoutOrder=order+100
                        dropdownContainer.Visible=false
                        dropdownContainer.ZIndex=20051
                        dropdownContainer.Parent=sf2

                        local optionsLayout=Instance.new("UIListLayout")
                        optionsLayout.SortOrder=Enum.SortOrder.LayoutOrder
                        optionsLayout.Padding=UDim.new(0,2)
                        optionsLayout.Parent=dropdownContainer

                        local function closeDropdown()
                            dropdownContainer.Visible=false
                            dropdown.BackgroundColor3=Colors.Action
                        end

                        for optionIndex,option in ipairs(options) do
                            local optionButton=Instance.new("TextButton")
                            optionButton.AutoButtonColor=false
                            optionButton.BackgroundColor3=Colors.Action
                            optionButton.BorderSizePixel=0
                            optionButton.Size=UDim2.new(1,0,0,34)
                            optionButton.FontFace=UIFont
                            optionButton.TextSize=15
                            optionButton.TextColor3=Colors.Text
                            optionButton.Text=tostring(option)
                            optionButton.LayoutOrder=optionIndex
                            optionButton.ZIndex=20052
                            optionButton.Parent=dropdownContainer

                            optionButton.MouseEnter:Connect(function()
                                optionButton.BackgroundColor3=Colors.ActionHover
                            end)
                            optionButton.MouseLeave:Connect(function()
                                optionButton.BackgroundColor3=Colors.Action
                            end)
                            optionButton.MouseButton1Click:Connect(function()
                                current=option
                                dropdown.Text=tostring(current)
                                setSetting(catName,itemName,settingKey,current)
                                safeCall(setting.onChanged or setting.action,current)
                                closeDropdown()
                            end)
                        end

                        dropdown.MouseEnter:Connect(function()
                            dropdown.BackgroundColor3=Colors.ActionHover
                        end)
                        dropdown.MouseLeave:Connect(function()
                            if not dropdownContainer.Visible then
                                dropdown.BackgroundColor3=Colors.Action
                            end
                        end)
                        dropdown.MouseButton1Click:Connect(function()
                            dropdownContainer.Visible=not dropdownContainer.Visible
                            dropdown.BackgroundColor3=dropdownContainer.Visible and Colors.ActionHover or Colors.Action
                        end)

                    elseif settingType=="checkbox" then
                        local default=setting.default==true
                        local current=getSetting(catName,itemName,settingKey,default)==true

                        local frame=Instance.new("Frame")
                        frame.BackgroundTransparency=1
                        frame.BorderSizePixel=0
                        frame.Size=UDim2.new(1,0,0,38)
                        frame.LayoutOrder=order
                        frame.Parent=sf2

                        local check=Instance.new("TextButton")
                        check.Name="Check"
                        check.AutoButtonColor=false
                        check.BackgroundColor3=current and Colors.ToggleOn or Colors.ToggleOff
                        check.BorderSizePixel=0
                        check.Position=UDim2.fromOffset(6,4)
                        check.Size=UDim2.fromOffset(30,30)
                        check.Text=""
                        check.Parent=frame

                        local label=Instance.new("TextLabel")
                        label.BackgroundTransparency=1
                        label.Position=UDim2.fromOffset(48,0)
                        label.Size=UDim2.new(1,-48,1,0)
                        label.FontFace=UIFont
                        label.TextSize=16
                        label.TextColor3=Colors.Text
                        label.TextXAlignment=Enum.TextXAlignment.Left
                        label.TextTruncate=Enum.TextTruncate.AtEnd
                        label.Text=settingName
                        label.Parent=frame

                        local function updateCheckbox()
                            check.BackgroundColor3=current and Colors.ToggleOn or Colors.ToggleOff
                        end

                        check.MouseEnter:Connect(function()
                            check.BackgroundColor3=current and Colors.ToggleOnHover or Colors.ToggleOffHover
                        end)
                        check.MouseLeave:Connect(updateCheckbox)
                        check.MouseButton1Click:Connect(function()
                            current=not current
                            updateCheckbox()
                            setSetting(catName,itemName,settingKey,current)
                            safeCall(setting.onChanged or setting.action,current)
                        end)

                    elseif settingType=="textbox" then
                        local fr=Instance.new("Frame")
                        fr.BackgroundTransparency=1
                        fr.Size=UDim2.new(1,0,0,34)
                        fr.LayoutOrder=order
                        fr.Parent=sf2

                        local lbl=Instance.new("TextLabel")
                        lbl.BackgroundTransparency=1
                        lbl.Size=UDim2.new(0.4,0,1,0)
                        lbl.FontFace=UIFont
                        lbl.TextSize=14
                        lbl.TextColor3=Colors.Text
                        lbl.TextXAlignment=Enum.TextXAlignment.Left
                        lbl.Text=settingName
                        lbl.Parent=fr

                        local tb=Instance.new("TextBox")
                        tb.BackgroundColor3=Colors.ToggleOff
                        tb.BorderSizePixel=0
                        tb.AnchorPoint=Vector2.new(1,0.5)
                        tb.Position=UDim2.new(1,0,0.5,0)
                        tb.Size=UDim2.fromOffset(140,28)
                        tb.FontFace=UIFont
                        tb.TextSize=14
                        tb.TextColor3=Colors.Text
                        tb.Text=tostring(getSetting(catName,itemName,settingKey,setting.default or ""))
                        tb.ClearTextOnFocus=false
                        tb.Parent=fr

                        tb.FocusLost:Connect(function()
                            setSetting(catName,itemName,settingKey,tb.Text)
                            safeCall(setting.onChanged or setting.action,tb.Text)
                        end)
                    end
                end
            end

            buttonData[catName]=buttonData[catName] or {}
            buttonData[catName][itemName]={
                button=button, wrapper=wrapper, settings=sf2, isToggle=isToggle,
                keybindButton=kbBtn, action=action,
                getState=function() return currentState end,
                toggle=performToggle,
                setState=function(state,skipSave)
                    currentState=state and true or false
                    config.features[catName][itemName]=currentState
                    refreshColor()
                    if not skipSave then saveConfig() end
                end
            }

            if isToggle and currentState then
                local ok,result=pcall(action,true)
                if not ok or result==false then
                    currentState=false; config.features[catName][itemName]=false
                    refreshColor(); notifyWarning(itemName.." disabled (condition not met)"); saveConfig()
                end
            end
        end
    end

    -- ── Tab panel ─────────────────────────────────────────────────────────────
    local noxX=tonumber(config.noxPosition.x) or 18
    local noxY=tonumber(config.noxPosition.y) or 75
    tabPanel=Instance.new("Frame"); tabPanel.Name="noxvape"
    tabPanel.BackgroundColor3=Colors.Panel; tabPanel.BackgroundTransparency=0; tabPanel.BorderSizePixel=0
    tabPanel.Size=UDim2.fromOffset(210,560); tabPanel.Position=UDim2.fromOffset(noxX,noxY)
    tabPanel.ClipsDescendants=true; tabPanel.ZIndex=20000; tabPanel.Parent=screenGui

    local tabHdr=Instance.new("TextButton"); tabHdr.Name="Header"; tabHdr.AutoButtonColor=false
    tabHdr.BackgroundColor3=Colors.Panel; tabHdr.BackgroundTransparency=0; tabHdr.BorderSizePixel=0
    tabHdr.Size=UDim2.new(1,0,0,46); tabHdr.Text=""; tabHdr.ZIndex=20001; tabHdr.Parent=tabPanel

    local logoImg=Instance.new("ImageLabel"); logoImg.Name="Logo"; logoImg.BackgroundTransparency=1
    logoImg.AnchorPoint=Vector2.new(0.5,0.5); logoImg.Position=UDim2.fromScale(0.5,0.5)
    logoImg.Size=UDim2.fromScale(1.4,1.4); logoImg.ScaleType=Enum.ScaleType.Fit
    logoImg.ZIndex=20002; logoImg.Parent=tabHdr
    task.spawn(function()
        if type(request)=="function" and type(writefile)=="function" then
            local need=true
            if type(isfile)=="function" then need=not isfile(LOGO_FILE) end
            if need then pcall(function()
                local r=request({Url=LOGO_URL,Method="GET"})
                if r and r.Success and r.Body then writefile(LOGO_FILE,r.Body) end
            end) end
        end
        task.wait(0.12)
        if type(isfile)=="function" and isfile(LOGO_FILE) then
            local ok,a=pcall(function() return getCustomAsset(LOGO_FILE) end)
            if ok and a then logoImg.Image=a end
        end
    end)
    makeDraggable(tabPanel,tabHdr,"noxvape",true)

    local tabScroll=Instance.new("Frame"); tabScroll.Name="Tabs"; tabScroll.BackgroundTransparency=1
    tabScroll.Position=UDim2.fromOffset(8,54); tabScroll.Size=UDim2.new(1,-16,0,450)
    tabScroll.ZIndex=20004; tabScroll.Parent=tabPanel
    local tabListLayout=Instance.new("UIListLayout"); tabListLayout.SortOrder=Enum.SortOrder.LayoutOrder
    tabListLayout.Padding=UDim.new(0,3); tabListLayout.Parent=tabScroll

    for idx,catDef in ipairs(_categories) do
        local catName=catDef.name
        local tb2=Instance.new("TextButton"); tb2.Name=catName; tb2.LayoutOrder=idx
        tb2.AutoButtonColor=false; tb2.BackgroundColor3=Colors.Action
        tb2.BackgroundTransparency=0; tb2.BorderSizePixel=0; tb2.Size=UDim2.new(1,0,0,36)
        tb2.FontFace=UIFont; tb2.TextSize=17; tb2.TextColor3=Colors.Text
        tb2.Text=catName; tb2.TextXAlignment=Enum.TextXAlignment.Center; tb2.ZIndex=20005; tb2.Parent=tabScroll
        tb2.MouseEnter:Connect(function() tw(tb2,{BackgroundColor3=Colors.ActionHover},0.08) end)
        tb2.MouseLeave:Connect(function() tw(tb2,{BackgroundColor3=Colors.Action},0.08) end)
        tb2.MouseButton1Click:Connect(function()
            playButtonSound()
            local card=categoryFrames[catName]; if not card or not card.Parent then return end
            categoryStates[catName]=not categoryStates[catName]
            card.Visible=categoryStates[catName]; config.tabs[catName]=categoryStates[catName]; saveConfig()
        end)
        addTooltip(tb2,"Toggle "..catName.." tab")
    end

    -- ── Settings gear button ──────────────────────────────────────────────────
    local sbc=Instance.new("Frame"); sbc.Name="SettingsButtonContainer"
    sbc.BackgroundTransparency=1; sbc.BorderSizePixel=0
    sbc.Position=UDim2.new(1,-48,1,-48); sbc.Size=UDim2.fromOffset(40,40)
    sbc.ZIndex=20015; sbc.Parent=tabPanel
    local sbtn=Instance.new("TextButton"); sbtn.Name="SettingsButton"; sbtn.AutoButtonColor=false
    sbtn.BackgroundTransparency=1; sbtn.BorderSizePixel=0; sbtn.Size=UDim2.fromScale(1,1)
    sbtn.Text=""; sbtn.ZIndex=20016; sbtn.Parent=sbc
    local sico=Instance.new("ImageLabel"); sico.Name="SettingsIcon"; sico.BackgroundTransparency=1
    sico.AnchorPoint=Vector2.new(0.5,0.5); sico.Position=UDim2.fromScale(0.5,0.5)
    sico.Size=UDim2.fromScale(1,1); sico.ScaleType=Enum.ScaleType.Fit
    sico.ImageColor3=Color3.fromRGB(255,255,255); sico.ZIndex=20017; sico.Parent=sbtn
    task.spawn(function()
        if type(request)=="function" and type(writefile)=="function" then
            pcall(function()
                local r=request({Url=SETTINGS_ICON_URL,Method="GET"})
                if r and r.Success and r.Body then
                    writefile("nox_settings_icon.png",r.Body)
                    local a=getCustomAsset("nox_settings_icon.png"); if a then sico.Image=a end
                end
            end)
        end
    end)
    if sico.Image=="" then sico.Image="rbxassetid://6034654127" end
    sbtn.MouseEnter:Connect(function() tw(sico,{ImageColor3=Color3.fromRGB(180,180,180)},0.1) end)
    sbtn.MouseLeave:Connect(function() tw(sico,{ImageColor3=Color3.fromRGB(255,255,255)},0.1) end)
    addTooltip(sbtn,"Open GUI settings")

    -- ── Settings window (auto-wired, always available) ─────────────────────────
    local function createSettingsWindow()
        if settingsWindow then settingsWindow.Visible=not settingsWindow.Visible; settingsVisible=settingsWindow.Visible; return end
        local winX,winY=getPosition("settingsWindow",50,100)
        local win=Instance.new("Frame"); win.Name="SettingsWindow"
        win.BackgroundColor3=Colors.Panel; win.BackgroundTransparency=0; win.BorderSizePixel=0
        win.Size=UDim2.fromOffset(280,480); win.Position=UDim2.fromOffset(winX,winY)
        win.ClipsDescendants=true; win.ZIndex=40000; win.Parent=screenGui

        local whdr=Instance.new("TextButton"); whdr.AutoButtonColor=false
        whdr.BackgroundColor3=Colors.Panel; whdr.BackgroundTransparency=0; whdr.BorderSizePixel=0
        whdr.Size=UDim2.new(1,0,0,40); whdr.FontFace=UIFont; whdr.TextSize=20
        whdr.TextColor3=Colors.Text; whdr.TextXAlignment=Enum.TextXAlignment.Left
        whdr.Text="  Settings"; whdr.ZIndex=40001; whdr.Parent=win

        local cBtn=Instance.new("TextButton"); cBtn.AutoButtonColor=false
        cBtn.BackgroundTransparency=1; cBtn.Size=UDim2.fromOffset(40,40)
        cBtn.AnchorPoint=Vector2.new(1,0); cBtn.Position=UDim2.new(1,0,0,0)
        cBtn.FontFace=UIFont; cBtn.TextSize=20; cBtn.TextColor3=Colors.MutedText
        cBtn.Text="✕"; cBtn.ZIndex=40002; cBtn.Parent=whdr
        cBtn.MouseEnter:Connect(function() cBtn.TextColor3=Colors.Text end)
        cBtn.MouseLeave:Connect(function() cBtn.TextColor3=Colors.MutedText end)
        cBtn.MouseButton1Click:Connect(function() win.Visible=false; settingsVisible=false end)
        makeDraggable(win,whdr,"settingsWindow",false)

        local content=Instance.new("ScrollingFrame"); content.Name="Content"
        content.BackgroundTransparency=1; content.BorderSizePixel=0
        content.Position=UDim2.fromOffset(12,48); content.Size=UDim2.new(1,-24,1,-58)
        content.ScrollBarThickness=4; content.ScrollBarImageColor3=Colors.Accent
        content.ScrollingDirection=Enum.ScrollingDirection.Y
        content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.CanvasSize=UDim2.fromOffset(0,0)
        content.ZIndex=40003; content.Parent=win
        local cl=Instance.new("UIListLayout"); cl.SortOrder=Enum.SortOrder.LayoutOrder
        cl.Padding=UDim.new(0,10); cl.Parent=content

        local function addLabel(text,order)
            local l=Instance.new("TextLabel"); l.BackgroundTransparency=1
            l.Size=UDim2.new(1,0,0,22); l.FontFace=UIFont; l.TextSize=17; l.TextColor3=Colors.Text
            l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text; l.LayoutOrder=order; l.Parent=content
        end
        local function addCheck(labelText,getter,setter,order,tip)
            local fr=Instance.new("Frame"); fr.BackgroundTransparency=1
            fr.Size=UDim2.new(1,0,0,34); fr.LayoutOrder=order; fr.Parent=content
            local chk=Instance.new("TextButton"); chk.AutoButtonColor=false
            chk.BackgroundColor3=getter() and Colors.Accent or Colors.Action
            chk.BackgroundTransparency=0; chk.BorderSizePixel=0
            chk.Position=UDim2.fromOffset(0,3); chk.Size=UDim2.fromOffset(26,26); chk.Text=""; chk.Parent=fr
            local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1
            lbl.Position=UDim2.fromOffset(34,0); lbl.Size=UDim2.new(1,-34,1,0)
            lbl.FontFace=UIFont; lbl.TextSize=17; lbl.TextColor3=Colors.Text
            lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText; lbl.Parent=fr
            addTooltip(lbl,tip or "Toggle")
            local function upd() chk.BackgroundColor3=getter() and Colors.Accent or Colors.Action end
            chk.MouseEnter:Connect(function() if chk.Parent then chk.BackgroundColor3=getter() and Colors.ToggleOnHover or Colors.ToggleOffHover end end)
            chk.MouseLeave:Connect(function() if chk.Parent then upd() end end)
            chk.MouseButton1Click:Connect(function() playButtonSound(); setter(not getter()); upd(); saveConfig() end)
            addTooltip(chk,tip or "Toggle")
        end
        local function addTextRow(labelText,getter,setter,order,placeholder)
            local fr=Instance.new("Frame"); fr.BackgroundTransparency=1
            fr.Size=UDim2.new(1,0,0,34); fr.LayoutOrder=order; fr.Parent=content
            local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1
            lbl.Size=UDim2.new(0.4,0,1,0); lbl.FontFace=UIFont; lbl.TextSize=15
            lbl.TextColor3=Colors.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Text=labelText; lbl.Parent=fr
            local tb=Instance.new("TextBox"); tb.BackgroundColor3=Colors.ToggleOff; tb.BorderSizePixel=0
            tb.AnchorPoint=Vector2.new(1,0.5); tb.Position=UDim2.new(1,0,0.5,0)
            tb.Size=UDim2.fromOffset(140,28); tb.FontFace=UIFont; tb.TextSize=15
            tb.TextColor3=Colors.Text; tb.PlaceholderText=placeholder or ""
            tb.Text=getter(); tb.ClearTextOnFocus=false; tb.Parent=fr
            tb.FocusLost:Connect(function() local t=tb.Text:gsub("%s+",""); if t=="" then t=placeholder or "0" end; tb.Text=t; setter(t); saveConfig() end)
        end
        local function addVolumeSlider(order)
            local fr=Instance.new("Frame"); fr.BackgroundTransparency=1
            fr.Size=UDim2.new(1,0,0,50); fr.LayoutOrder=order; fr.Parent=content
            local lbl=Instance.new("TextLabel"); lbl.BackgroundTransparency=1
            lbl.Size=UDim2.new(1,0,0,20); lbl.FontFace=UIFont; lbl.TextSize=15
            lbl.TextColor3=Colors.Text; lbl.TextXAlignment=Enum.TextXAlignment.Left
            lbl.Text="Volume ("..math.floor(config.soundVolume*100).."%)" ; lbl.Parent=fr
            local sbg=Instance.new("Frame"); sbg.BackgroundColor3=Colors.ToggleOff; sbg.BorderSizePixel=0
            sbg.Position=UDim2.fromOffset(0,26); sbg.Size=UDim2.new(1,0,0,14); sbg.Parent=fr
            local sfill=Instance.new("Frame"); sfill.BackgroundColor3=Colors.Accent; sfill.BorderSizePixel=0
            sfill.Size=UDim2.new(config.soundVolume,0,1,0); sfill.Parent=sbg
            local sknob=Instance.new("TextButton"); sknob.AutoButtonColor=false
            sknob.BackgroundColor3=Colors.Accent; sknob.BorderSizePixel=0
            sknob.AnchorPoint=Vector2.new(0.5,0.5); sknob.Position=UDim2.new(config.soundVolume,0,0.5,0)
            sknob.Size=UDim2.fromOffset(14,18); sknob.Text=""; sknob.Parent=sbg
            local drag=false
            local function upd(pct)
                pct=math.clamp(pct,0,1); config.soundVolume=pct
                soundObj.Volume=pct; menuSoundObj.Volume=pct
                sfill.Size=UDim2.new(pct,0,1,0); sknob.Position=UDim2.new(pct,0,0.5,0)
                lbl.Text="Volume ("..math.floor(pct*100).."%)"; saveConfig()
            end
            sknob.MouseButton1Down:Connect(function() drag=true end)
            UserInputService.InputChanged:Connect(function(inp)
                if not drag or inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
                if not sbg.Parent then return end
                local pos=UserInputService:GetMouseLocation().X-sbg.AbsolutePosition.X
                upd(math.clamp(pos/sbg.AbsoluteSize.X,0,1))
            end)
            UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
            sbg.InputBegan:Connect(function(inp)
                if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                    drag=true; local pos=UserInputService:GetMouseLocation().X-sbg.AbsolutePosition.X
                    upd(math.clamp(pos/sbg.AbsoluteSize.X,0,1))
                end
            end)
        end

        addLabel("Button Sounds",1)
        addCheck("Button Sounds",function() return config.guiSounds end,function(v) config.guiSounds=v end,2,"Play sounds on button clicks")
        addTextRow("Sound ID",function() return config.soundId end,function(v) config.soundId=v end,3,"0")
        addLabel("Open / Close Sounds",4)
        addCheck("Open/Close Sounds",function() return config.menuSounds end,function(v) config.menuSounds=v end,5,"Play sounds on menu open/close")
        addTextRow("Open ID",function() return config.openSoundId end,function(v) config.openSoundId=v end,6,"0")
        addTextRow("Close ID",function() return config.closeSoundId end,function(v) config.closeSoundId=v end,7,"0")
        addVolumeSlider(8)
        addLabel("Visual Settings",9)
        addCheck("Blur Background",
            function() return getSetting("noxvape","blur","enabled",false) end,
            function(v) setSetting("noxvape","blur","enabled",v); updateBlur() end,
            10,"Blur background when GUI is open")
        addLabel("Other",11)

        local sdf=Instance.new("Frame"); sdf.BackgroundTransparency=1
        sdf.Size=UDim2.new(1,0,0,42); sdf.LayoutOrder=12; sdf.Parent=content
        local sdBtn=Instance.new("TextButton"); sdBtn.AutoButtonColor=false
        sdBtn.BackgroundColor3=Colors.Action; sdBtn.BackgroundTransparency=0; sdBtn.BorderSizePixel=0
        sdBtn.Size=UDim2.new(1,0,1,0); sdBtn.FontFace=UIFont; sdBtn.TextSize=17
        sdBtn.TextColor3=Colors.Text; sdBtn.Text="Self Destruct"; sdBtn.Parent=sdf
        sdBtn.MouseEnter:Connect(function() tw(sdBtn,{BackgroundColor3=Colors.ActionHover},0.08) end)
        sdBtn.MouseLeave:Connect(function() tw(sdBtn,{BackgroundColor3=Colors.Action},0.08) end)
        sdBtn.MouseButton1Click:Connect(function() playButtonSound(); selfDestruct() end)
        addTooltip(sdBtn,"Permanently destroy the GUI")

        settingsWindow=win; settingsVisible=true
    end
    sbtn.MouseButton1Click:Connect(function() playButtonSound(); createSettingsWindow() end)

    -- ── Search bar ────────────────────────────────────────────────────────────
    local searchX=tonumber(config.searchPosition.x) or 300
    local searchY=tonumber(config.searchPosition.y) or 50
    local searchExpanded=config.searchExpanded or false
    local searchFrame=Instance.new("Frame"); searchFrame.Name="SearchBar"
    searchFrame.BackgroundColor3=Colors.Panel; searchFrame.BackgroundTransparency=0; searchFrame.BorderSizePixel=0
    searchFrame.Size=searchExpanded and UDim2.fromOffset(420,40) or UDim2.fromOffset(220,40)
    searchFrame.Position=UDim2.fromOffset(searchX,searchY); searchFrame.ZIndex=30000; searchFrame.Parent=screenGui
    local searchHdr=Instance.new("TextButton"); searchHdr.AutoButtonColor=false
    searchHdr.BackgroundColor3=Colors.Panel; searchHdr.BackgroundTransparency=0; searchHdr.BorderSizePixel=0
    searchHdr.Size=UDim2.new(1,0,0,40); searchHdr.Text=""; searchHdr.ZIndex=30001; searchHdr.Parent=searchFrame
    makeDraggable(searchFrame,searchHdr,"searchBar",false)
    local searchBox=Instance.new("TextBox"); searchBox.BackgroundColor3=Colors.ToggleOff
    searchBox.BackgroundTransparency=0; searchBox.BorderSizePixel=0
    searchBox.Position=UDim2.fromOffset(42,5); searchBox.Size=UDim2.new(1,-52,1,-10)
    searchBox.FontFace=UIFont; searchBox.TextSize=18; searchBox.TextColor3=Colors.Text
    searchBox.PlaceholderText="Search features..."; searchBox.PlaceholderColor3=Colors.MutedText
    searchBox.Text=""; searchBox.ZIndex=30002; searchBox.Parent=searchFrame
    local searchBtn=Instance.new("TextButton"); searchBtn.AutoButtonColor=false
    searchBtn.BackgroundColor3=Colors.Action; searchBtn.BackgroundTransparency=0; searchBtn.BorderSizePixel=0
    searchBtn.Position=UDim2.fromOffset(5,5); searchBtn.Size=UDim2.fromOffset(30,30)
    searchBtn.Text=""; searchBtn.ZIndex=30003; searchBtn.Parent=searchFrame
    local sico2=Instance.new("ImageLabel"); sico2.BackgroundTransparency=1
    sico2.Size=UDim2.fromOffset(18,18); sico2.Position=UDim2.new(0.5,-9,0.5,-9)
    sico2.Image="rbxassetid://6031154871"; sico2.ImageColor3=Colors.Text
    sico2.ScaleType=Enum.ScaleType.Fit; sico2.ZIndex=30004; sico2.Parent=searchBtn
    addTooltip(searchBtn,"Toggle search bar width")
    task.spawn(function()
        if type(request)=="function" and type(writefile)=="function" then
            pcall(function()
                local r=request({Url=SEARCH_ICON_URL,Method="GET"})
                if r and r.Success and r.Body then
                    writefile("nox_search_icon.png",r.Body)
                    local a=getCustomAsset("nox_search_icon.png"); if a then sico2.Image=a end
                end
            end)
        end
    end)
    local function toggleSearchExpand()
        searchExpanded=not searchExpanded; config.searchExpanded=searchExpanded
        if searchExpanded then searchFrame.Size=UDim2.fromOffset(420,40); searchBtn.BackgroundColor3=Colors.Accent; sico2.ImageColor3=Colors.Accent
        else searchFrame.Size=UDim2.fromOffset(220,40); searchBtn.BackgroundColor3=Colors.Action; sico2.ImageColor3=Colors.Text end
        saveConfig()
    end
    searchBtn.MouseEnter:Connect(function() searchBtn.BackgroundColor3=searchExpanded and Colors.ToggleOnHover or Colors.ActionHover end)
    searchBtn.MouseLeave:Connect(function() searchBtn.BackgroundColor3=searchExpanded and Colors.Accent or Colors.Action end)
    searchBtn.MouseButton1Click:Connect(function() playButtonSound(); toggleSearchExpand() end)

    filterButtons=function(query)
        if not tabPanel.Visible then return end
        query=string.lower(query)
        for catName,card in pairs(categoryFrames) do
            if card and card.Parent then
                local sc=card:FindFirstChild("Buttons")
                if sc then
                    local anyVis=false
                    for _,child in ipairs(sc:GetChildren()) do
                        if child:IsA("Frame") and child.Name:match("_Wrapper$") then
                            local btn=child:FindFirstChildOfClass("TextButton")
                            if btn then
                                local nl=btn:FindFirstChild("ModuleName")
                                local txt=(nl and nl.Text~="") and nl.Text or btn.Name
                                local vis=query=="" or string.find(string.lower(txt),query,1,true)~=nil
                                child.Visible=vis; if vis then anyVis=true end
                            end
                        end
                    end
                    card.Visible=(query~="" and anyVis) or (query=="" and categoryStates[catName])
                end
            end
        end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterButtons(searchBox.Text) end)

    -- ── Input handler ─────────────────────────────────────────────────────────
    UserInputService.InputBegan:Connect(function(inp,gp)
        if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
        local key=inp.KeyCode~=Enum.KeyCode.Unknown and inp.KeyCode.Name or nil
        if not key then return end
        if waitingForBind then
            if key=="Backspace" or key=="Escape" then
                config.keybinds[waitingForBind.category][waitingForBind.feature]=nil
                waitingForBind.button.Text="NONE"
            else
                local used=false
                for cat,feats in pairs(config.keybinds) do
                    if type(feats)=="table" then
                        for feat,bound in pairs(feats) do
                            if bound==key and not (cat==waitingForBind.category and feat==waitingForBind.feature) then used=true break end
                        end
                    end
                    if used then break end
                end
                if used then notifyError("Key already bound!"); waitingForBind.button.Text=getKeybind(waitingForBind.category,waitingForBind.feature) or "NONE"
                else config.keybinds[waitingForBind.category][waitingForBind.feature]=key; waitingForBind.button.Text=key end
            end
            waitingForBind.button.BackgroundColor3=Colors.Action; waitingForBind=nil; saveConfig(); return
        end
        if gp then return end
        if key==config.guiKeybind then hideTooltip(); setMenuVisible(not tabPanel.Visible); return end
        if UserInputService:GetFocusedTextBox() then return end
        for catName,feats in pairs(config.keybinds) do
            if type(feats)~="table" then continue end
            for featName,bound in pairs(feats) do
                if bound==key then
                    local d=buttonData[catName] and buttonData[catName][featName]
                    if d and d.toggle then d.toggle() end; break
                end
            end
        end
    end)

    playerGui.ChildAdded:Connect(function(child)
        if not otherGuisDisabled then return end
        if child:IsA("ScreenGui") and child~=screenGui then
            task.defer(function()
                if otherGuisDisabled and child.Parent then disabledGuiStates[child]=child.Enabled; child.Enabled=false end
            end)
        end
    end)

    setMenuVisible(tabPanel.Visible)
    saveConfig()
end -- end init()

-- ─── Public API ──────────────────────────────────────────────────────────────
local NoxLib = {}

function NoxLib.addCategory(name)
    assert(type(name)=="string" and name~="","NoxLib.addCategory: name must be a non-empty string")
    if _categoryMap[name] then return end
    local catDef={name=name, items={}}
    table.insert(_categories, catDef)
    _categoryMap[name]=catDef
end

function NoxLib.addButton(categoryName, opts)
    assert(type(categoryName)=="string","NoxLib.addButton: categoryName must be string")
    assert(type(opts)=="table","NoxLib.addButton: opts must be table")
    assert(type(opts.name)=="string" and opts.name~="","NoxLib.addButton: opts.name required")
    if not _categoryMap[categoryName] then NoxLib.addCategory(categoryName) end
    local catDef=_categoryMap[categoryName]
    table.insert(catDef.items, {
        name        = opts.name,
        toggle      = opts.toggle ~= false,
        description = opts.description or "",
        action      = opts.action or function() end,
        settings    = opts.settings,
    })
end

function NoxLib.notify(msg, kind)   createNotification(msg, kind or "enabled") end
function NoxLib.notifyEnabled(msg)  notifyEnabled(msg)  end
function NoxLib.notifyWarning(msg)  notifyWarning(msg)  end
function NoxLib.notifyError(msg)    notifyError(msg)    end

NoxLib.Features        = Features
NoxLib.getSetting      = getSetting
NoxLib.setSetting      = setSetting
NoxLib.saveConfig      = saveConfig
NoxLib.setMenuVisible  = setMenuVisible
NoxLib.Colors          = Colors

function NoxLib.init()
    init()
end

_G.NoxLib = NoxLib
return NoxLib
