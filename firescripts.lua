repeat task.wait() until game:IsLoaded()
task.spawn(function()
    local ifh = getgenv().isfunctionhooked
    while task.wait(0.25) do
        pcall(function()
            local mt = getrawmetatable(game);
            local nmc = mt.__namecall;
            if getgenv().SimpleSpyExecuted or ifh(nmc) then
                while true do end;
            end;
        end)
    end
end)

local Library = loadstring(game:HttpGetAsync("https://github.com/cloudman4416/Fluent_Clone/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudman4416/Fluent_Clone/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudman4416/Fluent_Clone/master/Addons/InterfaceManager.lua"))()

local options = Library.Options

-- ============ AUTO-EXECUTE-ON-JOIN ============
-- Re-runs the hub after every teleport/rejoin (lobby -> map, map -> map, server hop).
local function getQueueTeleport()
    return (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
        or queue_on_teleport
        or queueonteleport
end

-- The exact loadstring you paste into your executor to run this hub.
-- Replace the URL with YOUR raw GitHub link (the "Raw" button url, NOT the /blob/ page).
local AUTOEXEC_LOADER = [[loadstring(game:HttpGet("https://raw.githubusercontent.com/rencito974/E/main/firescripts.lua"))()]]

local autoExecQueued = false
local function queueAutoExec()
    if autoExecQueued then return end          -- only queue ONCE per execution
    local qot = getQueueTeleport()
    if qot then
        pcall(qot, AUTOEXEC_LOADER)
        autoExecQueued = true
    end
end
local function clearAutoExec()
    local qot = getQueueTeleport()
    if qot then pcall(qot, "") end
    autoExecQueued = false
end
-- ==============================================

local linked = {}
linked.fallbackdist = 15
linked.distance = 15
linked.ordered = {}
linked.bosses = {}
linked.ouwi_names = {}
linked.blankTween = {
    Play = function() end;
    Cancel = function() end;
    Completed = {
        Wait = function() end;
    };
}
warn("---------------------------------")

-- SERVICES
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local LocalizationService = game:GetService("LocalizationService")

--SHITSPLOITS HANDLE PART


local exec = identifyexecutor()
local isBadExec = false
if table.find({"Xeno", "Solara"}, exec) then
    local data = loadstring(game:HttpGet("https://raw.githubusercontent.com/cloudman4416/scripts/refs/heads/main/2142948266/modular.lua"), "modular")()
    isBadExec = true
	getgenv().require = function(source)
        return data[source:GetFullName()]
    end
end

-- VARS
local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ANTI-AFK: the game kicks after 20 min of no REAL input (scripted movement doesn't count),
-- which was disconnecting the auto-grind before the mugen trip. Reset the idle timer whenever
-- it's about to fire. Runs in every place since the script re-executes on each teleport.
if not getgenv().__CloudyAntiAfk then
    getgenv().__CloudyAntiAfk = true
    local VirtualUser = game:GetService("VirtualUser")
    client.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end
-- ===== MUGEN LEADER SIGNAL (syncs the standalone alt mugen-loop scripts) =====
-- When THIS account (the leader) boards the Mugen train, publishMugenBoard writes a
-- shared file the alts (mugen_private_loop, same PC) read, so they board the SAME
-- train at the SAME instant - however late the dungeon makes us. Only the named
-- leader publishes; MUGEN_SIGNAL_LEADER must match LEADER_NAME in the alt script.
local MUGEN_SIGNAL_FILE   = "FireHub/PJS/mugen_board_signal.txt"
local MUGEN_SIGNAL_LEADER = "artu2"   -- account that publishes the board signal
local MUGEN_SIGNAL_LEAD   = 4          -- secs between publishing and boarding (time for alts to sync in)
local function publishMugenBoard()
    if client.Name:lower() ~= MUGEN_SIGNAL_LEADER:lower() then return end
    local boardAt = os.time() + MUGEN_SIGNAL_LEAD
    pcall(function() writefile(MUGEN_SIGNAL_FILE, math.floor(os.time() / 3600) .. "|" .. boardAt) end)
    repeat task.wait(0.2) until os.time() >= boardAt   -- hold so the alts gather, then board together
end

local ping = StatsService.Network.ServerStatsItem["Data Ping"]
local placeId = game.PlaceId
local jobId = game.JobId
local renv = getrenv and getrenv()._G
local SERVER_ID = tonumber(jobId:gsub("%D", ""):sub(-9))
linked.AttackPlace = table.find({11468075017, 11468034852, 13883059853, 13883279773, 17387475546, 17387482786}, placeId)
linked.MapPlace = table.find({13883059853, 13883279773, 17387475546, 17387482786}, placeId)
linked.LobbysPlace = table.find({5956785391, 9321822839}, placeId)
linked.playerValues = nil
linked.playerData = nil
if not linked.LobbysPlace then
    -- Bounded + guarded on purpose: a gamemode arena (1v1 etc.) may never replicate these,
    -- and the old infinite wait would stall the WHOLE script before it could load in there.
    pcall(function()
        local pv = ReplicatedStorage:FindFirstChild("PlayerValues")
        local pd = ReplicatedStorage:FindFirstChild("Player_Data")
        linked.playerValues = pv and pv:WaitForChild(client.Name, 30)
        linked.playerData   = pd and pd:WaitForChild(client.Name, 30)
    end)
end
local Handle_Initiate_S = ReplicatedStorage.Remotes.To_Server:WaitForChild("Handle_Initiate_S")
local Handle_Initiate_S_ = ReplicatedStorage.Remotes.To_Server:WaitForChild("Handle_Initiate_S_")
local New_Item = ReplicatedStorage.Remotes.To_Client:FindFirstChild("New_Item")
local places = require(game:GetService("ReplicatedStorage").Modules.Global.Map_Locaations)

-- DUMP

linked.ordered = {
    "Muichiro";
    "Rengoku";
    "BanditBoss";
    "Akaza";
    "Inosuke";
    "Enmu";
    "Reaper Boss";
    "Sound Trainee";
    "Tengen";
    "Snow Trainee";
    "Douma";
    "Flame Trainee";
    "Swampy";

	"Tamari";
    "Arrow";
    "Sanemi";
    "Kaden";
    "Zanegutsu";
    "Boss";
    "Sabito";
    "Water";
    "Ouwbae";
    "Bomb_boss";
    "Reaper Boss";
}

linked.bosses = {}

if workspace:FindFirstChild("Mobs") then
    for i, v in ipairs(linked.ordered) do
        local success;
        local real;
        while not success do
            success = pcall(function()
                real = workspace.Mobs:FindFirstChild(v, true)
                if real then
                    local info = require(real.Npc_Configuration)
                    linked.bosses[v] = {info["Npc_Spawning"]["Spawn_Locations"][1], info["Name"], real, info["Code"]}
                end
            end)
            if not success then
                warn(("Error at %s, retrying..."):format(tostring(v)))
                real:Destroy()
                task.wait(0.5)
            end
        end
    end
end

if placeId == 11468075017 then
    for i, v in pairs(ReplicatedStorage.Ouwigahara.Bosses:GetChildren()) do
        linked.ouwi_names[v.Name] = require(v).Name
    end

    for i, v in pairs(ReplicatedStorage.Ouwigahara.Mobs:GetChildren()) do
        linked.ouwi_names[v.Name] = require(v).Name
    end
end

local robloxLang = client.LocaleId
local lang = robloxLang:split("-")[1]:lower()


local translations
local translationUrl = "https://raw.githubusercontent.com/cloudman4416/scripts/refs/heads/main/2142948266/translations.json"

-- Try to load from file first
if isfile("FireHub/PJS/translations.json") then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile("FireHub/PJS/translations.json"))
    end)
    if success then
        translations = data
    end
end

-- If file doesn't exist or failed to load, download it
if not translations then
    local success, data = pcall(function()
        local jsonData = game:HttpGet(translationUrl)
        writefile("FireHub/PJS/translations.json", jsonData)
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success then
        translations = data
    else
        translations = {}
    end
end

local function getTrans(id, field)
    local data = translations[id]
    if data then
        return data[field][lang] or data[field]["en"]
    else
        return id
    end
end

local new_items = setmetatable({}, {
    __index = function(t, ind)
        return 0
    end
})

if New_Item then
    New_Item.OnClientEvent:Connect(function(item)
        new_items[item] += 1
        --webhook(item, (images:FindFirstChild(item) and images[item].Image.Image or ReplicatedStorage.Tools:FindFirstChild(item) and ReplicatedStorage.Tools[item].TextureId))
    end)
else
    warn("No Webhook for you lil bro")
end

local rarities = {"Mythic", "Supreme", "Polar", "Devourer", "Limited"}
local items_data = require(game:GetService("ReplicatedStorage").Modules.Data.ItemsData)
local colors = {
    normal = 16711680;
    dungeon = 1376000;
    mugen = 18431;
}

local function wbhook(mode)
    local filds = {}
    for i, v in pairs(new_items) do
        if table.find(rarities, items_data[i]["Data"][1]["Settings"]["Rarity"]) then
            table.insert(filds, {name = i, value = "x" .. v, inline = true})
        end
    end
    if #filds == 0 then return end
    local data = {
        username = "Step Mom",
        avatar_url = "https://cdn.discordapp.com/avatars/1300809146903429120/152ae0be266098e7a09ce8548796fc63.png",
        embeds = {
            {
                title = "Farm Result For ||" .. client.Name .. "||",
                description = "Configure your webhook in the script settings",
                timestamp = DateTime.now():ToIsoDate(),
                color = colors[mode],
                fields = filds
            }
        }
    }
    request({
        Url = options["iWebhook"].Value,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
        },
        Body = HttpService:JSONEncode(data),
    })
    table.clear(new_items)
end

-- CLOUD HUB SIGNATURE
--[[local yeah = false
local key = (isfile("CloudHub/Key") and readfile("CloudHub/Key") or _G.SCRIPT_KEY or "abcdefgh")

local succ, ret = pcall(function()
    local response = HttpService:JSONDecode(game:HttpGet("https://work.ink/_api/v2/token/isValid/" .. key))
    if response.valid then

    else
        Library:Notify({
            Title = "Key System",
            Content = "Please use the loader and complete the key system",
            Duration = 20
        })
        error("wrong key")
    end
end)

local arg = {...}
arg = arg[1]
if arg == "while false do end" then
    yeah = true
end

if not (succ and yeah) then
    print("No Diddy Blud")
    return false
end]]

workspace.FallenPartsDestroyHeight = -math.huge

if linked.playerData then
    Handle_Initiate_S:FireServer("Change_Value", linked.playerData:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage"), SERVER_ID)
end

client.CharacterAdded:Connect(function(Character)
    local wagon = Character:WaitForChild(client.Name .. "'s Wagon", math.huge)
    if wagon then wagon:Destroy() end
end)

task.defer(function()
    local wagon = client.Character:WaitForChild(client.Name .. "'s Wagon", math.huge)
    if wagon then wagon:Destroy() end
end)

local antiatk = Instance.new("ScreenGui")
antiatk.DisplayOrder = -1000
antiatk.Enabled = false
antiatk.IgnoreGuiInset = true
antiatk.ResetOnSpawn = false
local fram = Instance.new("Frame", antiatk)
fram.Active = true
fram.AnchorPoint = Vector2.new(0.5, 0.5)
fram.BackgroundTransparency = 1
fram.Position = UDim2.fromScale(0.5, 0.5)
fram.Size = UDim2.fromScale(1, 1)

antiatk.Parent = client.PlayerGui

-- FUNCTIONS

linked.SafeCallback = function(func, toggle)
	local succ, ret = pcall(func)
	if succ then return end
	toggle:SetValue(false)
	toggle:SetValue(true)
end


linked.tweento = function(coords, skip)
    if not coords then
        return linked.blankTween
    end
    local hrp = client.Character:WaitForChild("HumanoidRootPart")
    local Distance = (coords.Position - hrp.Position).Magnitude
    local Speed = Distance/options["sTweenSpeed"].Value

    local tween = TweenService:Create(hrp,
        TweenInfo.new(Speed, Enum.EasingStyle.Linear),
        { CFrame = coords}
    )

    if linked.tween then linked.tween:Cancel() end
    tween:Play()
    linked.tween = tween
    return tween
end

linked.tpto = function(p1)
    client.Character:WaitForChild("HumanoidRootPart").CFrame = p1
end

linked.smartTp = function(dest:CFrame, offset:CFrame)
    print("very smart but dangerous")
    dest = dest.Position
    local closest = nil
    local shortest = (client.Character.HumanoidRootPart.Position - dest).Magnitude
    for loc, coord in pairs(places) do
        if linked.playerData.MapUi.UnlockedLocations:FindFirstChild(loc) and client.PlayerGui.Map_Ui.Holder.Locations:FindFirstChild(loc) then
            local dist = (coord-dest).Magnitude
            if dist < shortest then
                closest = loc
                shortest = dist
            end
        end
    end
    if closest then
        local args = {
            [1] = `Players.{client.Name}.PlayerGui.Npc_Dialogue.Guis.ScreenGui.LocalScript`,
            [2] = os.clock(),
            [3] = closest
        }
        game:GetService("ReplicatedStorage"):WaitForChild("teleport_player_to_location_for_map_tang"):InvokeServer(unpack(args))
    end
    print("H1")
    linked.tweento(CFrame.new(dest) * (offset or CFrame.new())).Completed:Wait()
    print("H2")
end

linked.findBoss = function(name, delay)
    local data = linked.bosses[name]
    return data[3]:WaitForChild(data[2], delay or 0.4)
end

linked.findMob = function(players, multi)
    local v1 = {}
    for _, tag in ipairs({"Bosses", "Npcs", (players and "Players") or nil}) do
        for _, v in ipairs(CollectionService:GetTagged(tag)) do
            local plr = game.Players:GetPlayerFromCharacter(v)
            if v:IsDescendantOf(workspace.Mobs) or (plr and plr.Name ~= client.Name and not ReplicatedStorage.PlayerValues[v.Name]:FindFirstChild("KnockedOut") and not ReplicatedStorage.PlayerValues[v.Name]:FindFirstChild("in_safe_zone")) then
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 and (options.sKaDist.Value == 350 or (hrp.Position - client.Character:WaitForChild("HumanoidRootPart").Position).Magnitude <= options.sKaDist.Value) then
                    if multi then
                        table.insert(v1, v)
                    else
                        return v
                    end
                end
            end
        end
    end
    if multi then
        return v1
    end
end

linked.noclip = function()
    for i, v in ipairs(client.Character:GetChildren()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end

linked.farmHelper = function()
	local Farm = {}
    client.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	local _conn = RunService.Stepped:Connect(linked.noclip)
	local antifall = Instance.new("BodyVelocity")
	antifall.Velocity = Vector3.new(0, 0, 0)
	antifall.Parent = client.Character.HumanoidRootPart
	local _conn2 = client.CharacterAdded:Connect(function(Character)
		antifall.Parent = Character:WaitForChild("HumanoidRootPart")
	end)

	function Farm:Stop()
        client.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
		_conn:Disconnect()
		_conn2:Disconnect()
		antifall:Destroy()
        for i, v in ipairs(client.Character:GetChildren()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
            end
        end
	end
	return Farm
end

linked.getPower = function(name)
	local thang = client.PlayerGui.Power_Adder:FindFirstChild((name == "Blood" and "Blood_Burst") or name)
	if thang then
		return thang
	end
	for i, v in ipairs(client.PlayerGui.Power_Adder:GetChildren()) do
		if v:FindFirstChild("Mastery_Equiped") and v.Mastery_Equiped.Value == name then
			return v
		end
	end
end

linked.webhook = function(name, link)
    local ret;
    if link then
        local img_link = string.match(link, "id=(%d+)")
        repeat
            ret = request({
                Url = `https://thumbnails.roblox.com/v1/assets?assetIds={img_link}&size=250x250&format=Png&cacheBust={tostring(tick())}`,
                Method = "GET",
                Headers = {
                    ["Content-Type"] = "text/json",
                }
            })
            task.wait(0.3)
        until HttpService:JSONDecode(ret.Body)["data"][1]["state"] == "Completed"
    end
    local msg = {
        ["embeds"] = {
            {
                ["title"] = "Got An Item !!!",
                ["color"] = 16711680,
                ["fields"] = {},
                ["thumbnail"] = {
                    ["url"] = link and HttpService:JSONDecode(ret.Body)["data"][1]["imageUrl"] or nil;
                },
                ["description"] = `||{client.Name}|| collected a \n{name}`,
                ["timestamp"] = DateTime.now():ToIsoDate(),
            },
        },
        ["username"] = "Step Mom",
        ["avatar_url"] = "https://cdn.discordapp.com/avatars/1300809146903429120/152ae0be266098e7a09ce8548796fc63.png",
    }
    request({
        Url = options["iWebhook"].Value,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
        },
        Body = HttpService:JSONEncode(msg),
    })
end

local SafeCallback, tweento, tpto, smartTp, findBoss, findMob, noclip, farmHelper, getPower, webhook = linked.SafeCallback, linked.tweento, linked.tpto, linked.smartTp, linked.findBoss, linked.findMob, linked.noclip, linked.farmHelper, linked.getPower, linked.webhook

-- GUI PART
--local SaveManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent-Renewed/master/Addons/SaveManager.luau"))()
--local InterfaceManager = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent-Renewed/master/Addons/InterfaceManager.luau"))()

local viewportSize = camera.ViewportSize

local Window = Library:CreateWindow{
    Title = "FireHub | Project Slayer",
    TabWidth = math.clamp(viewportSize.X/8, 100, 150),
    Size = UDim2.fromOffset(viewportSize.X/2, viewportSize.Y/1.8),
    Resize = false, -- Resize this ^ Size according to a 1920x1080 screen, good for mobile users but may look weird on some devices
    MinSize = Vector2.new(470, 380),
    Acrylic = false, -- The blur may be detectable, setting this to false disables blur entirely
    Theme = "Obsidian",
    MinimizeKey = Enum.KeyCode.RightShift -- Used when theres no MinimizeKeybind
}

if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui", gethui() or game.CoreGui)
    ScreenGui.IgnoreGuiInset = true
    local Frame = Instance.new("ImageButton", ScreenGui)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.Size = UDim2.fromOffset(viewportSize.Y/10, viewportSize.Y/10)
    Frame.Position = UDim2.new(0.35, 0, 0, viewportSize.Y/20 + 5)
    Window.Root.Active = true
    Frame.Activated:Connect(function()
        Window:Minimize()
    end)
    local frame = Frame
    local UIS = UserInputService

    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local Tabs = {
    ["Lobby"] = Window:AddTab({Title = "Lobby/Hub", Icon = "home"});
    ["Auto Farm"] = Window:AddTab({Title = "Auto Farm", Icon = "repeat"});
    ["Kill Aura"] = Window:AddTab({Title = "Kill Aura", Icon = "sword"});
    ["1v1"] = Window:AddTab({Title = "1v1", Icon = "sword"});
    ["Skills"] = Window:AddTab({Title = "Skills", Icon = "repeat"});
    ["Misc"] = Window:AddTab({Title = "Misc", Icon = "feather"});
    ["Quests"] = Window:AddTab({Title = "Quests", Icon = "carrot"});
    ["Buffs"] = Window:AddTab({Title = "Buffs", Icon = "shield"});
    ["Teleport"] = Window:AddTab({Title = "Teleport", Icon = "map"});
    ["Dungeon"] = Window:AddTab({Title = "Dungeon", Icon = "skull"});
    ["Mugen"] = Window:AddTab({Title = "Mugen", Icon = "train"});
    ["Webhook"] = Window:AddTab({Title = "Webhook", Icon = "cog"});
    ["Settings"] = Window:AddTab({Title = "Settings", Icon = "settings"});
    ["Music"] = Window:AddTab({Title = "Music", Icon = "music"});
    
}

-- LOBBY

local maps = {
    ["Map 1"] = 17387475546;
    ["Map 2"] = 17387482786;
    ["Hub"] = 9321822839;
}

Tabs["Lobby"]:AddSection(getTrans("seLobby", "Title"))

Tabs["Lobby"]:AddButton({
    Title = getTrans("bDailySpin", "Title");
    Callback = function()
        if placeId == 5956785391 then
            ReplicatedStorage:WaitForChild("spins_thing_remote", math.huge):InvokeServer()
        end
    end
})

Tabs["Lobby"]:AddSlider("sSlot", {
    Title = getTrans("sSlot", "Title"),
    Description = getTrans("sSlot", "Desc"),
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 0,
})

Tabs["Lobby"]:AddInput("iCode", {
    Title = getTrans("iCode", "Title"),
    Default = nil,
    Placeholder = "Enter private server code",
    Numeric = false, -- Only allows numbers
    Finished = false -- Only calls callback when you press enter
})

Tabs["Lobby"]:AddDropdown("dMapSelect", {
    Title = getTrans("dMapSelect", "Title"),
    Values = {"Map 1", "Map 2", "Hub"};
    Default = "Map 2",
    Multi = false,
})

linked._autoJoinServerRunning = false
linked.autoJoinServer = function()
    if placeId ~= 5956785391 then return end
    if linked._autoJoinServerRunning then return end
    linked._autoJoinServerRunning = true
    task.spawn(function()
        repeat task.wait() until game:IsLoaded()
        pcall(function()
            workspace.Is_Customization_place:WaitForChild("Slot3")
            client:WaitForChild("Slot")
            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Apply_Slot"):InvokeServer(options["sSlot"].Value)
        end)
        while task.wait(1) do
            if not options["tAutoJoin"].Value then break end
            if options["iCode"].Value ~= "" then
                ReplicatedStorage:WaitForChild("handle_privateserver"):InvokeServer("join", options["iCode"].Value, maps[options["dMapSelect"].Value])
            else
                TeleportService:Teleport(maps[options["dMapSelect"].Value], client)
            end
        end
        linked._autoJoinServerRunning = false
    end)
end

Tabs["Lobby"]:AddToggle("tAutoJoin", {
    Title = getTrans("tAutoJoin", "Title");
    Description = getTrans("tAutoJoin", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then linked.autoJoinServer() end
end)

Tabs["Lobby"]:AddSection(getTrans("seHub", "Title"))

Tabs["Lobby"]:AddDropdown("dHubMode", {
    Title = getTrans("dHubMode", "Title");
    Values = {"Ouwigahara", "1v1", "2v2", "3v3", "4v4", "5v5", "Trading"};
    Default = "Ouwigahara";
    Multi = false;
})

-- party objects live directly under ReplicatedStorage.parties (confirmed in-game).
-- cheap direct lookup, no whole-game scan.
linked.getPartyContainer = function()
    return ReplicatedStorage:FindFirstChild("parties")
end

linked.findMyParty = function()
    local container = linked.getPartyContainer()
    if not container then return nil end
    for _, v in ipairs(container:GetChildren()) do
        local owner = v:FindFirstChild("ownerid")
        if owner and owner.Value == client.Name then
            return v
        end
    end
end

linked.autoJoinGamemode = function(mode)
    if placeId ~= 9321822839 then return end
    mode = mode or options.dHubMode.Value          -- caller can force a mode (grind uses "Ouwigahara")
    task.spawn(function()
        local party, t0 = nil, os.clock()
        repeat
            party = linked.findMyParty()
            if not party then task.wait(1) end
        until party or (os.clock() - t0 > 30)
        if not party then
            Library:Notify({ Title = "Auto Join Gamemode", Content = "Couldn't find your party in the hub", Duration = 5 })
            return
        end
        local t1 = os.clock()
        repeat
            ReplicatedStorage:WaitForChild("change_game_mode"):FireServer(party.gamemodeequiped, mode)
            task.wait(0.3)
        until party.gamemodeequiped.Value == mode or (os.clock() - t1 > 15)
        ReplicatedStorage:WaitForChild("queu_up"):FireServer()
    end)
end

Tabs["Lobby"]:AddToggle("tHubJoin", {
    Title = getTrans("tHubJoin", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then linked.autoJoinGamemode() end
end)


-- ============ HUB 1v1 (PARTNER-ONLY) ============
-- Queues the hub's 1v1 gamemode over and over until the match contains ONE specific
-- account - the username typed in the Partner box. Land against anyone else (or an
-- empty arena) and BOTH accounts leave the match and requeue together.
--
-- Both accounts run on the same PC, so they coordinate through the executor's shared
-- file folder (same trick as the Mugen leader signal above):
--   1v1_hub_server.txt   "<jobId>|<epoch>"    THIS account's hub instance - the partner
--                                             script teleports into the same hub server
--   1v1_queue_signal.txt "<queueAt>"          the exact second BOTH fire queu_up, so the
--                                             matchmaker sees two fresh queues at once
--   1v1_abort.txt        "<epoch>|<writer>"   "wrong opponent - bail out now" broadcast
-- The other account runs pjs_1v1_partner.lua, which speaks this same protocol.
do
    local S_HUBSRV = "FireHub/PJS/1v1_hub_server.txt"
    local S_QUEUE  = "FireHub/PJS/1v1_queue_signal.txt"
    local S_ABORT  = "FireHub/PJS/1v1_abort.txt"

    local HUB1V1       = 9321822839
    local QUEUE_LEAD   = 5    -- secs between publishing the queue instant and both accounts firing it
    local QUEUE_GRACE  = 20   -- a queue signal older than this is stale and gets rewritten
    local ABORT_FRESH  = 15   -- an abort older than this is ignored
    local REQUEUE_WAIT = 25   -- if queu_up didn't take, how long to sit in the hub before retrying

    -- Every place that ISN'T a gamemode match. Anything we land in that's not on this
    -- list is treated as the 1v1 arena (its place id changes per gamemode/map).
    local NOT_ARENA = {
        [5956785391]  = true,   -- Lobby
        [9321822839]  = true,   -- Hub
        [17387475546] = true, [13883279773] = true,   -- Map 1 public / private
        [17387482786] = true, [13883059853] = true,   -- Map 2 public / private
        [11468075017] = true,   -- Ouwigahara dungeon
        [11468034852] = true,   -- Mugen train
    }

    pcall(function()
        if makefolder then
            if not isfolder("FireHub") then makefolder("FireHub") end
            if not isfolder("FireHub/PJS") then makefolder("FireHub/PJS") end
        end
    end)

    local function readf(p)
        local ok, d = pcall(function() return isfile(p) and readfile(p) or nil end)
        return ok and d or nil
    end
    local function writef(p, d) pcall(function() writefile(p, d) end) end

    local function on1v1()  return options.t1v1Auto and options.t1v1Auto.Value end
    local function partnerName()
        local v = (options.i1v1Partner and options.i1v1Partner.Value) or ""
        return (tostring(v):gsub("^%s*(.-)%s*$", "%1"))
    end

    -- Read from the player list, not the streamed-in character: with StreamingEnabled a
    -- far-away partner has no HumanoidRootPart on our client and would read as "gone".
    local function partnerHere()
        local want = partnerName():lower()
        if want == "" then return false end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == want or p.DisplayName:lower() == want then return true end
        end
        return false
    end

    local function writeQueue(at) writef(S_QUEUE, tostring(at)) end
    local function readQueue()
        local d = readf(S_QUEUE); if not d then return nil end
        local q = tonumber(d:match("^%s*(%-?%d+)%s*$"))
        if not q then return nil end
        if os.time() > q + QUEUE_GRACE then return nil end   -- last round's signal -> ignore
        return q
    end

    -- Both accounts run this; whoever gets there first writes the instant, then BOTH
    -- re-read after a beat so a simultaneous write can't leave them a second apart.
    local function agreeQueueTime()
        local q = readQueue()
        if q then return q end
        q = os.time() + QUEUE_LEAD
        writeQueue(q)
        task.wait(1.5)
        return readQueue() or q
    end

    local function writeAbort() writef(S_ABORT, os.time() .. "|" .. client.Name) end
    local function readAbort()
        local d = readf(S_ABORT); if not d then return nil end
        local at, who = d:match("^(%-?%d+)|(.+)$")
        at = tonumber(at)
        if not at or not who then return nil end
        return at, who
    end

    -- Publish our hub instance while we sit in the hub, so the partner script can
    -- TeleportToPlaceInstance into THIS server instead of a random hub shard.
    local function publishHubServer()
        task.spawn(function()
            while on1v1() and placeId == HUB1V1 do
                writef(S_HUBSRV, jobId .. "|" .. os.time())
                task.wait(5)
            end
        end)
    end

    -- HUB: wait for the partner to show up in our server, agree on one queue instant,
    -- then both fire queu_up on it. Loops until the queue actually takes us out.
    local function hubPhase()
        local warned = false
        while on1v1() do
            if partnerName() == "" then
                if not warned then
                    warned = true
                    Library:Notify({
                        Title = "Auto 1v1",
                        Content = "Type your other account's username in the Partner box first.",
                        Duration = 8
                    })
                end
                task.wait(2)
            elseif not partnerHere() then
                task.wait(2)   -- the partner script follows us into this hub server on its own
            else
                local queueAt = agreeQueueTime()
                repeat task.wait(0.2) until os.time() >= queueAt or not on1v1()
                if not on1v1() then break end
                linked.autoJoinGamemode("1v1")
                -- still standing here after this = the queue didn't take; wait it out and retry
                local t0 = os.clock()
                repeat task.wait(0.5) until (os.clock() - t0) > REQUEUE_WAIT or not on1v1()
            end
        end
    end

    -- ARENA: the actual check. Give the partner a few seconds to load in; if it's anyone
    -- else in here, broadcast the abort (so the partner's match dies too) and go back.
    local function arenaPhase()
        local entered  = os.time()
        local waitFor  = tonumber(options.s1v1Wait and options.s1v1Wait.Value) or 25
        local maxMatch = (tonumber(options.s1v1MaxMatch and options.s1v1MaxMatch.Value) or 10) * 60
        local deadline = os.clock() + waitFor
        local verified = false

        while on1v1() and os.clock() < deadline do
            if partnerHere() then verified = true; break end
            -- partner bailed from THEIR match first -> don't sit out our own timer
            local at, who = readAbort()
            if at and who ~= client.Name and at >= entered and (os.time() - at) <= ABORT_FRESH then
                break
            end
            task.wait(0.5)
        end

        if not on1v1() then return end

        if verified then
            Library:Notify({
                Title = "Auto 1v1",
                Content = ("Matched with %s - go."):format(partnerName()),
                Duration = 5
            })
            -- failsafe: never sit in a match forever if it never ends on its own
            task.delay(maxMatch, function()
                if on1v1() then TeleportService:Teleport(HUB1V1, client) end
            end)
        else
            writeAbort()   -- tells the other account to drop its match too
            Library:Notify({
                Title = "Auto 1v1",
                Content = ("%s isn't in this match - leaving and requeuing."):format(
                    partnerName() ~= "" and partnerName() or "Partner"),
                Duration = 5
            })
            task.wait(0.5)
            TeleportService:Teleport(HUB1V1, client)
        end
    end

    linked.run1v1Controller = function()
        if not on1v1() then return end
        if linked._1v1Ran then return end       -- once per execution (Callback + startup call)
        linked._1v1Ran = true
        task.spawn(function()
            repeat task.wait() until game:IsLoaded()
            task.wait(1)
            if not on1v1() then linked._1v1Ran = false; return end
            if placeId == HUB1V1 then
                publishHubServer()
                hubPhase()
            elseif NOT_ARENA[placeId] then
                TeleportService:Teleport(HUB1V1, client)   -- lobby/map/dungeon -> back to the hub
            else
                arenaPhase()
            end
        end)
    end
end

Tabs["1v1"]:AddSection("Partner match")

Tabs["1v1"]:AddParagraph({
    Title = "How Auto 1v1 works";
    Content = "Queues 1v1 in the hub until you get matched against ONE account - the username below. Anything else and both accounts leave the match and requeue together.\n\nSETUP:\n- This account: type the OTHER account's username below, turn Auto 1v1 on, and turn on Auto Execute (Settings tab) so it survives teleports.\n- Other account: run pjs_1v1_partner.lua with PARTNER_NAME set to THIS account's username.\n\nBoth accounts must be on the same PC - they sync through shared executor files. The partner script follows this account into its hub server on its own. Don't run Auto Grind at the same time.\n\nArrow KA below is your old Maps/Hub 1v1 script - it locks onto the Partner account automatically, so you don't have to pick from the dropdown.";
})

Tabs["1v1"]:AddInput("i1v1Partner", {
    Title = "Partner username";
    Default = nil;
    Placeholder = "exact username of your other account";
    Numeric = false;
    Finished = true;
})

Tabs["1v1"]:AddSlider("s1v1Wait", {
    Title = "Seconds to wait for the partner in a match";
    Description = "How long the arena gets to load the partner in before we call it a wrong match";
    Default = 25;
    Min = 5;
    Max = 60;
    Rounding = 0;
})

Tabs["1v1"]:AddSlider("s1v1MaxMatch", {
    Title = "Max minutes in a match";
    Description = "Failsafe - leaves back to the hub if a match never ends";
    Default = 10;
    Min = 1;
    Max = 30;
    Rounding = 0;
})

Tabs["1v1"]:AddToggle("t1v1Auto", {
    Title = "Auto 1v1 vs partner";
    Description = "Requeue until the match is you two, leave and retry otherwise";
    Default = false;
    Callback = function(Value)
        if Value then
            -- both controllers own navigation; running them together fights over the hub
            if options.tMasterFarm and options.tMasterFarm.Value then
                options.tMasterFarm:SetValue(false)
                Library:Notify({ Title = "Auto 1v1", Content = "Auto Grind turned off - they can't both drive.", Duration = 5 })
            end
            linked.run1v1Controller()
        else
            linked._1v1Ran = false
        end
    end
})

-- ---- ARROW KA (ported from your standalone "Maps/Hub 1v1.lua") ----
-- The Kill Aura tab's arrow KA is gated on race/mastery/playerData and skips the
-- lobby places, so it's dead weight in a 1v1. This one is the stripped version that
-- actually works there: pick ONE player and hammer arrow_knock_back_damage at them,
-- re-casting the arrow_knock_back skill on its cooldown so the damage keeps landing.
-- Target = the Partner box if that account is in the server, otherwise the dropdown.

Tabs["1v1"]:AddSection("Arrow KA")

-- Seeded with the players already here rather than an empty list + empty Default -
-- some Fluent builds throw while rendering a dropdown that has neither.
local initialTargets = {}
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= client then table.insert(initialTargets, p.Name) end
end

Tabs["1v1"]:AddDropdown("d1v1Target", {
    Title = "Arrow KA target";
    Description = "Auto-fills with everyone else in the server. Ignored while the Partner box matches someone here.";
    Values = initialTargets;
    Multi = false;
})

-- keep the dropdown in sync with the server, and auto-pick when there's only one
-- other player (which is exactly the 1v1 case)
task.spawn(function()
    local function sameList(a, b)
        if #a ~= #b then return false end
        for i = 1, #a do if a[i] ~= b[i] then return false end end
        return true
    end
    while task.wait(1) do
        -- only churn the dropdown while one of the 1v1 features is actually armed;
        -- a 40-player map server would otherwise rebuild it on every join/leave
        local armed = (options.tArrowKA and options.tArrowKA.Value)
            or (options.t1v1Auto and options.t1v1Auto.Value)
        if options.d1v1Target and armed then
            local names = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= client then table.insert(names, p.Name) end
            end
            if not sameList(options.d1v1Target.Values, names) then
                options.d1v1Target:SetValues(names)
                if #names == 1 then options.d1v1Target:SetValue(names[1]) end
            end
        end
    end
end)

linked.arrowKaTarget = function()
    -- the partner takes priority, so the KA follows the 1v1 without re-picking by hand
    local want = (options.i1v1Partner and tostring(options.i1v1Partner.Value or "") or ""):lower()
    if want ~= "" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= client and (p.Name:lower() == want or p.DisplayName:lower() == want) then
                return p
            end
        end
    end
    local pick = options.d1v1Target and options.d1v1Target.Value
    if type(pick) == "string" and pick ~= "" then
        return Players:FindFirstChild(pick)
    end
    return nil
end

Tabs["1v1"]:AddToggle("tArrowKA", {
    Title = "Arrow KA (single target)";
    Description = "Spams arrow knock back at the target. Needs a bow build.";
    Default = false;
    Callback = function(Value)
        if not Value then return end
        -- damage loop
        task.spawn(function()
            while options.tArrowKA.Value do
                local target = linked.arrowKaTarget()
                local char = target and target.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pcall(function()
                        Handle_Initiate_S:FireServer(
                            "arrow_knock_back_damage",
                            client.Character,
                            char:GetModelCFrame(),
                            char,
                            400,
                            400
                        )
                    end)
                end
                task.wait(0.3)
            end
        end)
        -- skill re-cast loop (the damage remote only lands while the skill is active)
        task.spawn(function()
            while options.tArrowKA.Value do
                pcall(function()
                    Handle_Initiate_S_:InvokeServer("skil_ting_asd", client, "arrow_knock_back", 5)
                end)
                task.wait(6)
            end
        end)
    end
})

Tabs["Lobby"]:AddSection(getTrans("seClan", "Title"))

Tabs["Lobby"]:AddButton({
    Title = getTrans("bClanSpin", "Title");
    Callback = function()
        if placeId == 5956785391 then
            Handle_Initiate_S_:InvokeServer("check_can_spin")
        end
    end
})

local clans = require(game:GetService("ReplicatedStorage").Modules.Global.Random_Clan_Picker)

local raw_clans = {}

for i, v in pairs(clans) do
    if typeof(v) == "table" then
        for a, b in ipairs(v) do
            table.insert(raw_clans, b)
        end
    end
end

Tabs["Lobby"]:AddDropdown("dClan", {
    Title = "Clan Selection";
    Values = raw_clans;
    Default = {"Kamado", "Agatsuma", "Rengoku", "Uzui"};
    Multi = true;
})

Tabs["Lobby"]:AddToggle("tSpinClan", {
    Title = "Spin For Clan";
    Description = "Spin until you get one of the selected clan";
    Default = false;
    Callback = function(Value)
        if placeId == 5956785391 and Value then
            Window:Dialog({
                Title = "ATTENTION",
                Content = "Are you really sure you want to spin you current clan off ?",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            task.defer(function()
                                while options.tSpinClan.Value do
                                    local succ, ret = Handle_Initiate_S_:InvokeServer("check_can_spin")
                                    if succ then
                                        print(ret)
                                        if options.dClan.Value[ret] then
                                            Library:Notify({
                                                Title = "LETS GO",
                                                Content = `You spun one of the selected clans`,
                                                Duration = 5
                                            })
                                            options.tSpinClan:SetValue(false); break
                                        end
                                    end
                                    task.wait()
                                end
                            end)
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            options.tSpinClan:SetValue(false); return
                        end
                    }
                }
            })
        else
            if options.tSpinClan then
                options.tSpinClan:SetValue(false)
            end
        end
    end
})

-- AUTO FARM

local weapons = {
    ["Combat"] = "fist_combat";
    ["Scythe"] = "Scythe_Combat_Slash";
    ["Sword"] = "Sword_Combat_Slash";
    ["Fans"] = "fans_combat_slash";
    ["Claws"] = "claw_Combat_Slash";
}

Tabs["Auto Farm"]:AddDropdown("dWeaponSelect", {
    Title = getTrans("dWeaponSelect", "Title");
    Values = {"Combat", "Scythe", "Sword", "Fans", "Claws"};
    Default = "Claws";
    Multi = false;
}):OnChanged(function(Value)
    if Value == "Scythe" then
        --linked.fallbackdist = 9
        linked.distance = 7
    else
        --linked.fallbackdist = 15
        linked.distance = 15
    end
end)

Tabs["Auto Farm"]:AddSlider("sTweenSpeed", {
    Title = getTrans("sTweenSpeed", "Title");
    Description = "If you have a weak device please lower this value";
    Default = 300;
    Min = 100;
    Max = 500;
    Rounding = 0;
})
Tabs["Auto Farm"]:AddToggle("tAutoBoss", {
	Title = getTrans("tAutoBoss", "Title");
    Description = getTrans("tAutoBoss", "Desc");
	Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            if not linked.MapPlace then return end
            options.tAutoFlower:SetValue(false)
            local farmhelp = farmHelper()
            --[[local pos = client.Character.HumanoidRootPart.Position
            local closest = math.huge
            local ind = 1
            for i, v in ipairs(linked.ordered) do
                local coord = linked.bosses[boss] and linked.bosses[boss][1]
                if not coord then continue end
                if (coord - pos).Magnitude < closest then
                    ind = i
                    closest = (coord - pos).Magnitude
                end
            end
            local s = {}
            for i = 1, #linked.ordered do
                s[i] = linked.ordered[((i-2+ind) % #linked.ordered) + 1]
            end]]
            while options.tAutoBoss.Value do
                for _, boss in ipairs(linked.ordered) do
                    local coord = linked.bosses[boss] and linked.bosses[boss][1]
                    if not coord then continue end
                    if options.tAutoBoss.Value then
                        if options.tMuzanQuest.Value then
                            for i, v in ipairs(ReplicatedStorage.Muzan_Quests[client.Name]:GetChildren()) do
                                if v.Name:match("^Eliminate (.+)$") == linked.bosses[boss][2] then
                                    ReplicatedStorage.Remotes.To_Server:WaitForChild("muzan_quest_ting"):FireServer(v.Name, "Do")
                                    break
                                end
                            end
                        end
                        tweento(CFrame.new(coord) * CFrame.new(0, -35, 0)).Completed:Wait()
                        --smartTp(CFrame.new(coord) * CFrame.new(0, 3, 0))
                        local boboss = findBoss(boss, 0.6)
                        while boboss and boboss:FindFirstChild("HumanoidRootPart") and boboss:FindFirstChild("Humanoid").Health > 0 and options.tAutoBoss.Value do
                            tpto(
                                CFrame.new(boboss.HumanoidRootPart.Position) *
                                ((options.tAutoM1.Value and CFrame.new(0, linked.distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)) or CFrame.new(0, -35, 0))
                            )
                            task.wait()
                        end
                        if not options.tAutoBoss.Value and not options.tJoinMugen.Value then tweento(CFrame.new(coord) * CFrame.new(0, 3, 0), true).Completed:Wait() end
                    end
                end
                task.wait()
            end
            farmhelp:Stop()
        end)
    end
end)

Tabs["Auto Farm"]:AddToggle("tAutoM1", {
	Title = getTrans("tAutoM1", "Title");
    Description = "Cycles through ALL weapons - 8 attacks each per rotation";
	Default = false;
}):OnChanged(function(Value)
    task.spawn(function()
        if Value then
            task.spawn(function()
                antiatk.Enabled = true
                
                -- Create list of all weapons
                local weaponList = {}
                for weaponName, weaponRemote in pairs(weapons) do
                    table.insert(weaponList, {name = weaponName, remote = weaponRemote})
                end
                
                local currentWeaponIndex = 1  -- Start with first weapon
                
                while options.tAutoM1.Value do
                    repeat task.wait() until (not client:FindFirstChild("combotangasd123") or client.combotangasd123.Value == 0) and not linked.playerValues:FindFirstChild("Stun") and not linked.playerValues:FindFirstChild("KnockedOut")
                    if not options.tAutoM1.Value then break end
                    task.wait(0.1)
                    
                    -- Get current weapon
                    local currentWeapon = weaponList[currentWeaponIndex]
                    
                    -- Attack 8 times with current weapon
                    for i = 1, 8 do
                        Handle_Initiate_S:FireServer(currentWeapon.remote, nil, client.Character, client.Character:WaitForChild("HumanoidRootPart"), client.Character:WaitForChild("Humanoid"), 919, "ground_slash", nil, 1/0)
                        Handle_Initiate_S:FireServer(currentWeapon.remote, nil, client.Character, client.Character.HumanoidRootPart, client.Character.Humanoid, 1/0, "ground_slash", nil, 1/0)
                    end
                    
                    -- Move to next weapon (cycle back to 1 after reaching end)
                    currentWeaponIndex = (currentWeaponIndex % #weaponList) + 1
                    
                    task.wait(0.5)
                end
                antiatk.Enabled = false
            end)
        end
    end)
end)
Tabs["Auto Farm"]:AddToggle("tAutoBlock", {
    Title = getTrans("tAutoBlock", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        while options["tAutoBlock"].Value do
            local args = {
                [1] = "add_blocking",
                [2] = `Players.{client.Name}.PlayerScripts.Skills_Modules.Combat.Combat//Block`,
                [3] =  os.clock(),
                [4] = linked.playerValues,
                [5] = 99999
            }
            Handle_Initiate_S:FireServer(unpack(args))
            task.wait(0.5)
        end
        Handle_Initiate_S:FireServer("remove_blocking", linked.playerValues)
    end
end)

Tabs["Auto Farm"]:AddToggle("tMuzanQuest", {
    Title = "Auto Take Muzan Quest";
    Description = "This work in sync with autoboss and only take quest of boss you'r about to kill";
    Default = false
})

Tabs["Auto Farm"]:AddToggle("tAutoChest", {
	Title = getTrans("tAutoChest", "Title");
	Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options.tAutoChest.Value do
                for a, b in ipairs(CollectionService:GetTagged("Chests")) do
                    if b.Name == "Loot_Chest" then
                        for c, d in ipairs(b:WaitForChild("Drops"):GetChildren()) do
                            b.Add_To_Inventory:InvokeServer(d.Name)
                            d:Destroy()
                        end
                    end
                end
                task.wait()
            end
        end)
    end
end)


Tabs["Auto Farm"]:AddToggle("tAutoFlower", {
    Title = getTrans("tAutoFlower", "Title");
    Description = getTrans("tAutoFlower", "Desc");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            options.tAutoBoss:SetValue(false)
            local farmhelp = farmHelper()
            while options["tAutoFlower"].Value do
                local closest 
                local distance = math.huge
                for i, v in ipairs(workspace:WaitForChild("Demon_Flowers_Spawn", math.huge):GetChildren()) do
                    if not v:IsA("Model") then continue end
                    local dist = (v:GetModelCFrame().Position - client.Character:WaitForChild("HumanoidRootPart").Position).Magnitude
                    if dist < distance then
                        closest = v
                        distance = dist
                    end
                end
                pcall(function()
                    tweento(closest:GetModelCFrame()).Completed:Wait()
                    closest["Cube.002"].CFrame = closest["Cube.002"].CFrame * CFrame.new(0, 5, 0)
                    task.wait(0.5)
                    fireproximityprompt(closest["Cube.002"].Pick_Demon_Flower_Thing)
                    closest:Destroy()
                end)
            end
            farmhelp:Stop()
        end)
    end
end)

-- KILL AURAS
Tabs["Kill Aura"]:AddToggle("tKillaura", {
    Title = "Killaura Toggle";
    Description = "This need to be toggled on for the killaura you activated below to get active";
    Default = true;
})

Tabs["Kill Aura"]:AddToggle("tInclPlrs", {
    Title = "Include Players in Kill Aura";
    Description = getTrans("tInclPlrs", "Desc");
    Default = false;
})

Tabs["Kill Aura"]:AddSlider("sKaDist", {
    Title = "Killaura Max Distance";
    Description = "I recommend to let this to max";
    Default = 350;
    Min = 20;
    Max = 350;
    Rounding = 0;
})

Tabs["Kill Aura"]:AddParagraph({
    Title = "Information",
    Content = "Potential strengh is a ratio of cooldown and dmg\nBig potential strengh = big dps"
})

local add = require(game:GetService("ReplicatedStorage").Modules.Global.skills_custom_add_thing)
local cd_mod = require(game:GetService("ReplicatedStorage").Modules.Global.skill_cooldowns) or {}
if isBadExec and linked.AttackPlace then
    for _, v in ipairs(game.StarterGui:WaitForChild("Power_Adder"):GetDescendants()) do
        if v.Name == "Actual_Skill_Name" and v.Parent:FindFirstChild("CoolDown") ~= nil then
            cd_mod[v.Value] = v.Parent.CoolDown.Value
        end
    end
end
local skill_data = require(game:GetService("ReplicatedStorage").Modules.Server.Skills_Modules_Handler).Skills
cd_mod["Rapid_Slashes_Damage"] = 12;--"Thunderbreathingrapidslashes";
cd_mod["thunderbreathingthunderrain"] = 20;--"thunder_rumblinmg_thunder_bolkt_skill";
cd_mod["ice_demon_art_barren_hanging_garden_damage"] = 25;--"ice_demon_art_barren_hanging_garden";


local function newKa(rm5, ...)
    local values = {}
	local cd5 = (cd_mod[rm5] or 5) - 5
    local add5 = (add[rm5] and add[rm5] + 3) or 1
	local cdAtk = cd5/(add5) + math.clamp(1/add5, 0, 0.2)
    local data = skill_data[rm5]
    local art = data["Art"] or data["Power"]
    local mastery = data["Mastery"]
    local races = data["Race"]
    local item = data["Item"]
	for i, v in ipairs({...}) do

		local togName = `t{mastery}{i}Ka`
        table.insert(values, togName)
		local strengh = math.round(v.Boost / cdAtk)

        Tabs["Kill Aura"]:AddToggle(togName, {
            Title = `{mastery} KA ({v.Mastery} mastery required, {strengh} potential strengh)`;
            Description = v.Info;
            Default = false;
        }):OnChanged(function(Value)
            if Value then
                for i, v in ipairs(values) do
                    if v ~= togName and options[v].Value then
                            Library:Notify({
                            Title = "Attention",
                            Content = `Activate only a single killaura`,
                            Duration = 5
                        })
                        options[togName]:SetValue(false)
                        return
                    end
                end
                local Race = linked.playerData.Race.Value
                if not table.find(races, Race) then
                    Library:Notify({
                        Title = "Attention",
                        Content = `You don't have the correct race DUMAH`,
                        Duration = 5
                    })
                    options[togName]:SetValue(false)
                    return
                end
                local pow = (Race == 3 and linked.playerData.Demon_Art.Value) or ((Race == 1 or Race == 2) and linked.playerData.Power.Value )
                if art and pow ~= art then
                    Library:Notify({
                        Title = "Attention",
                        Content = `You don't have {art:lower()} DUMAH`,
                        Duration = 5
                    })
                    options[togName]:SetValue(false)
                    return
                end
                if item and not (client.Backpack:FindFirstChild(item, true) or client.Character:FindFirstChild(item, true)) then
                    Library:Notify({
                        Title = "Attention",
                        Content = `You don't have the required item : {mastery}`,
                        Duration = 5
                    })
                    options[togName]:SetValue(false)
                    return
                end
                if linked.playerData.Mastery_Bundle:FindFirstChild("mastery") and linked.playerData.Mastery_Bundle[mastery].Max.Value / 30 < v.Mastery then
                    Library:Notify({
                        Title = "Attention",
                        Content = `You don't have {v.Mastery} mastery DUMAH`,
                        Duration = 5
                    })
                    options[togName]:SetValue(false)
                    return
                end
                if options.tGodMode.Value then
                    Library:Notify({
                        Title = "Attention",
                        Content = "Can't toggle godmode and arrow ka at the same time",
                        Duration = 3
                    })
                    options[togName]:SetValue(false)
                    return
                end
                task.spawn(function()
                    if not linked.LobbysPlace then
                        while true do
                            for i, v in ipairs(values) do 
                                if options[v].Value and options.tKillaura.Value then
                                    local args = {
                                        [1] = "skil_ting_asd",
                                        [2] = client,
                                        [3] = rm5,
                                        [4] = 5
                                    }
                                    Handle_Initiate_S:FireServer(unpack(args))
                                    task.wait(cd5 + 0.1)
                                end
                            end
                            task.wait()
                        end
                    end
                end)
                task.defer(function()
                    while options[togName].Value do
                        local target = findMob(options.tInclPlrs.Value) --workspace.PrivateServerDummies["Dummy (Infinite Hp)"]
                        if target and options.tKillaura.Value then
                            --[[if v.Skill == "Koketsu_arrow_damage" then
                                task.spawn(function()
                                    Handle_Initiate_S_:InvokeServer("Arrow_knock_back_throw", client, client.Character:WaitForChild("HumanoidRootPart"), target.HumanoidRootPart.CFrame)

                                    local smegma = workspace.Debree:WaitForChild(client.Name .. "'s arrow", 2)
                                    smegma.Name = "UsedTypeShit"

                                    if not target:FindFirstChild("HumanoidRootPart") then return end

                                    Handle_Initiate_S:FireServer("Koketsu_arrow_damage", client.Character, smegma, target.HumanoidRootPart.CFrame)

                                    while smegma.Parent == workspace.Debree do
                                        smegma.Damagething:FireServer()
                                        task.wait()
                                    end
                                end)
                                task.wait(cdAtk)
                                continue
                            end]]
                            
                            local args = {
                                [1] = v.Skill,
                                [2] = client.Character,
                                [3] = target.HumanoidRootPart.CFrame
                            }

                            for a, b in ipairs(v.Args) do
                                if b == "CFrame" then
                                    args[3] = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, -100)
                                    table.insert(args, target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 100))
                                    continue
                                elseif b == "nil" then
                                    args[3 + a] = nil
                                elseif b == "target" then
                                    args[3 + a] = target
                                else
                                    args[3 + a] = b
                                end 
                            end

                            Handle_Initiate_S:FireServer(table.unpack(args, 1, 3+#v.Args))
                            task.wait(cdAtk)
                        else
                            task.wait()
                        end
                    end
                end)
            end
        end)
	end
end

---------------------Claws
Tabs["Kill Aura"]:AddSection("Claws (every race)")

newKa("Claws//Spin", {Mastery = 20, Skill = "Claw_Spin_Damage", Boost = 100, Args = {100}})


---------------------BLOOD DEMON ARTS

Tabs["Kill Aura"]:AddSection("Blood Demon Art")

---------------------ARROW

newKa("arrow_knock_back", {Mastery = 1, Skill = "arrow_knock_back_damage", Boost = 150, Args = {"nil", "nil", 200}}, {Mastery = 22, Skill = "piercing_arrow_damage", Boost = 30, Args = {}}--[[, {Mastery = 31, Skill = "Koketsu_arrow_damage", Boost = math.huge, Args = {}}]])

--[[Tabs["Kill Aura"]:AddButton({
    Title = "Glitch";
    Callback = function()

        local targets = findMob(false, true)
        
        Handle_Initiate_S:FireServer("skil_ting_asd", client, "arrow_knock_back", 5)

        --Handle_Initiate_S:FireServer("arrow_knock_back_damage", client.Character, targets[1].HumanoidRootPart.CFrame, nil, nil, 7)
        local args = {
            "fist_combat",
            client,
            client.Character,
            client.Character:WaitForChild("HumanoidRootPart"),
            client.Character:WaitForChild("Humanoid"),
            1
        }
        Handle_Initiate_S_:InvokeServer(unpack(args))

        task.wait(0.7)

        Handle_Initiate_S_:InvokeServer("Arrow_knock_back_throw", client, client.Character:WaitForChild("HumanoidRootPart"), targets[1].HumanoidRootPart.CFrame)

        local smegma = workspace.Debree:WaitForChild(client.Name .. "'s arrow", 2)
        smegma.Name = "UsedTypeShit"

        for i, v in ipairs(targets) do
            Handle_Initiate_S:FireServer("Koketsu_arrow_damage", client.Character, smegma, v.HumanoidRootPart.CFrame, v)
        end

        for i = 1, 4 do
            smegma.Damagething:FireServer()
            task.wait()
        end

        while smegma.Parent == workspace.Debree do
            smegma.Damagething:FireServer()
            task.wait()
        end

    end
})]]

---------------------BLOOD BURST

newKa("blood_burst_explosive_land_mines", {Mastery = 30, Skill = "blood_burst_blood_shot_damage", Boost = 100, Args = {100}})

---------------------DREAM

newKa("Dream_Bda_Melodic_Whisper", {Mastery = 38, Skill = "dreasm_bda_damsdasdasd", Boost = 350, Args = {175}})

---------------------REAPER

newKa("reaperbda_reapofdispair", {Mastery = 1, Skill = "slash_thing_damage", Boost = 19, Args = {}}, {Mastery = 23, Skill = "blazing_amputation_damage", Boost = 100, Args = {100}})
--newKa("Reaper", "Reaper_demon_art_runasd123", {Mastery = 45, Skill = "blazing_amputation_damage", Boost = 100, Args = {100}})

---------------------ICE

newKa("ice_demon_art_wintry_iciles", {Mastery = 1, Skill = "ice_demon_art_wintry_iciles_damage", Boost = 10, Args = {}}, {Mastery = 35, Skill = "ice_demon_art_barren_hanging_garden_damage2", Boost = 100, Args = {100}})

---------------------SWAMP

newKa("swampbda_swamp_puddle", {Mastery = 1, Skill = "swamp_puddle_damage", Boost = 3, Args = {}}, {Mastery = 17, Skill = "swamp_traveling_claws_damage", Boost = 75, Args = {75}})

---------------------SHOCKWAVE

newKa("akaza_bda_chaotic_type", {Mastery = 39, Skill = "Akaza_Crown_Split_damage", Boost = 100, Args = {100}})

---------------------TAMARI

newKa("Tamari2_double_Throw", {Mastery = 10, Skill = "Tamari_Double_Throw_Damage_new", Boost = 26, Args = {"target", 26}})



---------------------BREATHINGS

Tabs["Kill Aura"]:AddSection("Breathing")

---------------------Beast

newKa("beast_breathing_crazy_cutting", {Mastery = 20, Skill = "beast_breathing_pierce_damage", Boost = 100, Args = {100}})

---------------------Flame

newKa("flame_breathing_flaming_eruption", {Mastery = 32, Skill = "flmae_rising_scorch_damage", Boost = 100, Args = {100}})

---------------------INSECT

newKa("Insect_breathing_compound_eye_hexagon", {Mastery = 23, Skill = "inssect_flatter_damage", Boost = 100, Args = {100}})

---------------------Mist

newKa("mist_breathing_eight_layerd_Dispersing_mist", {Mastery = 20, Skill = "mist_cloud_haze_damage", Boost = 100, Args = {100}}, {Mastery = 48, Skill = "mist_breathing_shifting_flow_flash_damage", Boost = 150, Args = {150}})

---------------------Snow

newKa("snow_breathing_frost_path", {Mastery = 17, Skill = "snow_breathing_frozen_desert_damage", Boost = 100, Args = {100}})

---------------------Sound

newKa("sound_breathing_resounding_slashes", {Mastery = 32, Skill = "sound_breathing_roar_damage", Boost = 200, Args = {200}})

---------------------THUNDER

newKa("Thunderbreathingrapidslashes", {Mastery = 20, Skill = "thunder_clap_and_flash_damage", Boost = 100, Args = {"CFrame", 100, 200}, Info = "Hit in a 200 meter radius (very op)"})

---------------------Water

newKa("Water_wheel", {Mastery = 17, Skill = "water_surface_slash_damage", Boost = 100, Args = {100}})

---------------------Wind

newKa("wind_breathing_cold_mountain_wind", {Mastery = 37, Skill = "Purifying_wind_damage", Boost = 100, Args = {100}})

--SKILLS

Tabs["Skills"]:AddToggle("tAutoSkill", {
    Title = "Auto Skill";
    Description = "Toggle the what you want below";
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            local FakeCombat = Instance.new("Folder")
            Instance.new("BoolValue", FakeCombat).Name = "CombatIsEquiped"
            Instance.new("IntValue", FakeCombat).Name = "Id"
            FakeCombat:Clone().Parent = client.Character
            local _conn = client.CharacterAdded:Connect(function(char)
                FakeCombat:Clone().Parent = client.Character
            end)
            while options.tAutoSkill.Value do task.wait() end
            _conn:Disconnect()
            client.Character:FindFirstChild("Folder"):Destroy()
        end)
    end
end)

if renv and linked.AttackPlace then
    local succ, err = pcall(function()
        local tang = linked.playerData:WaitForChild("Keys", math.huge)
        local skill = renv.skills_modules_thing
        for i = 1, 6 do
            Tabs["Skills"]:AddToggle(`tMove{i}`, {
                Title = `Use {tang:WaitForChild("Move"..i)["2"].Value}`;
                Default = false;
            }):OnChanged(function(Value)
                if Value then
                    task.spawn(function()
                        local Race = linked.playerData.Race.Value
                        local art = ( Race == 3 and linked.playerData.Demon_Art.Value) or ((Race == 1 or Race == 2) and linked.playerData.Power.Value)
                        while options[`tMove{i}`].Value do
                            local skill_config = getPower(art)["Skills"]:GetChildren()[i]
                            if skill_config.Locked.Value then
                                task.wait()
                                continue
                            end
                            skill[skill_config["Actual_Skill_Name"].Value]["Down"](skill_config)
                            task.wait(0.1)
                            skill[skill_config["Actual_Skill_Name"].Value]["Up"](skill_config)
                            task.wait(skill_config["CoolDown"].Value + 1)
                        end
                    end)
                end
            end)
        end
    end)
    if not succ then
        Library:Notify({
            Title = "Attention",
            Content = "Your exploit doesn't support auto skill\n".. err,
            Duration = 5
        })
    end
end

--MISC

Tabs["Misc"]:AddButton({
    Title = "Spin Ur BDA",
    Description = "Spin your Blood Demon Art",
    Callback = function()
        pcall(function()
            Handle_Initiate_S_:InvokeServer("check_can_spin_demon_art")
        end)
    end
})

Tabs["Misc"]:AddToggle("tAutoSoul", {
    Title = getTrans("tAutoSoul", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options["tAutoSoul"].Value do
                for i, v in ipairs(workspace.Debree:GetChildren()) do
                    if v.Name == "Soul" then
                        v:WaitForChild("Handle"):WaitForChild("Eatthedamnsoul"):FireServer()
                    end
                end
                task.wait()
            end
        end)
    end
end)

local block_conn;
Tabs["Misc"]:AddToggle("tAntiBlock", {
    Title = getTrans("tAntiBlock", "Title");
    Description = getTrans("tAntiBlock", "Desc");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            for i, v in ipairs(CollectionService:GetTagged("Blocking")) do
                if v.Parent == linked.playerValues then
                    continue
                end
                Handle_Initiate_S:FireServer("remove_blocking", v.Parent)
            end
            block_conn = CollectionService:GetInstanceAddedSignal("Blocking"):Connect(function(v) 
                if v.Parent == linked.playerValues then
                    return
                end
                task.wait(0.1)
                Handle_Initiate_S:FireServer("remove_blocking", v.Parent)
            end)
        end)
    else
        if block_conn then
            block_conn:Disconnect()
        end
    end
end)

Tabs["Misc"]:AddToggle("tFx", {
    Title = "Spam Random Visual and Sound Effects on Everyone";
    Description = "water, swamp";
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options.tFx.Value do
                for i, v in ipairs(CollectionService:GetTagged("Players")) do
                    if Players:GetPlayerFromCharacter(v) and v:FindFirstChild("HumanoidRootPart") then
                        local fxs = {
                            {
                                `Players.{v.Name}.PlayerScripts.Client_Modules.Main_Script`,
                                os.clock(),
                                "water_splash_particle",
                                v:GetModelCFrame().Position
                            },
                            {
                                `Players.{client.Name}.PlayerScripts.Client_Modules.Main_Script`,
                                os.clock(),
                                "Swamp_Travel_Loop",
                                {
                                    Character = v
                                }
                            }
                        }
                        ReplicatedStorage.Remotes.To_Server:WaitForChild("Handle_Initiate_C"):FireServer(unpack(fxs[math.random(1, #fxs)]))
                        task.wait(0.7)
                    end
                end
                task.wait()
            end
        end)
    end
end)

Tabs["Misc"]:AddToggle("tSwampTrap", {
    Title = "Spam Swamp Trap Damage on Self";
    Description = "spams swamp trap at everyone around you on loop";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options.tSwampTrap.Value do
                task.wait()
                local char = client.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local args = {
                        [1] = "swamp_trap_damage",
                        [2] = char,
                        [3] = hrp.CFrame * CFrame.Angles(1.228732031677282e-07, -1.199800729751587, 8.192461109501892e-08)
                    }
                    Handle_Initiate_S:FireServer(unpack(args))
                end
                task.wait(0.1)
            end
        end)
    end
end)

Tabs["Misc"]:AddButton({
    Title = getTrans("bTpToMuzan", "Title");
    Description = getTrans("bTpToMuzan", "Desc");
    Callback = function()
        local farmhelp = farmHelper()
        if workspace:FindFirstChild("Muzan") then
            tweento(CFrame.new(workspace.Muzan.SpawnPos.Value)).Completed:Wait()
        else
            Library:Notify({
                Title = "Muzan",
                Content = "Muzan Is Not Spawned Wait For The Night",
                Duration = 2
            })
        end
        farmhelp:Stop()
    end
})

Tabs["Misc"]:AddButton({
    Title = getTrans("bDoctorQuest", "Title");
    Callback = function()
        local args = {
            [1] = "Quest_add",
            [2] = `Players.{client.Name}.PlayerGui.Npc_Dialogue.LocalScript.Functions`,
            [3] = os.clock(),
            [4] = {},
            [5] = client,
            [6] = "doctorhigoshimabringbacktomuzan"
        }
        Handle_Initiate_S:FireServer(unpack(args))
    end
})

Tabs["Misc"]:AddToggle("tGourds", {
    Title = "Auto Blow Gourds";
    Description = "Will buy and blow gourds the most efficiently possible until you have max breathing level";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options.tGourds.Value do
                if linked.playerData.BreathingProgress["1"].Value == 900 then
                    Library:Notify({
                        Title = "Attention",
                        Content = "You maxed out gourd progress",
                        Duration = 3
                    })
                    options.tGourds:SetValue(false)
                    return
                end
                local prop = linked.playerData.Custom_Properties
                local typ = "Small Gourd"
                local i = 3
                if prop.Used_Small_Gourd.Value < 7 then
                    typ = "Small Gourd"
                    i = 1
                elseif prop.Used_Medium_Gourd.Value < 7 then
                    typ = "Small Gourd"
                    i = 2
                else
                    typ = "Big Gourd"
                    i = 3
                end
                Handle_Initiate_S:FireServer("buysomething", client, typ, linked.playerData.Yen)

                local gourd = linked.playerData.Inventory.Items:WaitForChild(typ, 3)
                if not gourd then 
                    Library:Notify({
                        Title = "Attention",
                        Content = "Error while getting gourd, make sure you got enough money",
                        Duration = 5
                    })
                    options.tGourds:SetValue(false)
                    return
                end

                if not client.Backpack:FindFirstChild(typ) then Handle_Initiate_S:FireServer("change_equip_for_item", client, linked.playerData["Inventory"], gourd) end

                local blows = prop:WaitForChild(gourd.Settings.Id.Value).Blows

                local tool = client.Backpack:WaitForChild(typ)

                while blows.Parent ~= nil do
                    Handle_Initiate_S_:InvokeServer("blow_in_gourd_thing", client, tool, i)
                    task.wait()
                end
                task.wait()
            end
        end)
    end
end)

Tabs["Misc"]:AddButton({
    Title = "CRASH SERVER";
    Description = "Clicking this button will crash the current server instantly and immediatly";
    Callback = function()
        if linked.AttackPlace then
            Window:Dialog({
                Title = "ATTENTION",
                Content = "Are you really sure of what you are about to do ?",
                Buttons = {
                    {
                        Title = "Confirm",
                        Callback = function()
                            Handle_Initiate_S:FireServer("ricespiritdamage", client, CFrame.new(0, 0, 0), 999999)
                        end
                    },
                    {
                        Title = "Cancel",
                        Callback = function()
                            print("Cancelled the dialog.")
                        end
                    }
                }
            })
        end
    end
})

Tabs["Misc"]:AddButton({
    Title = "Infinite coin spawn on you";
    Description = "Reset to stop";
    Callback = function()
        require(client.PlayerScripts.Client_Modules.Modules.Extra2.coineff)(client.Character.HumanoidRootPart, math.huge)
    end
})
Tabs["Misc"]:AddSection("Gamepasses")

Tabs["Misc"]:AddButton({
    Title = getTrans("bGPProg", "Title");
    Description = getTrans("bGPProg", "Desc");
    Callback = function()
        local unlock = Instance.new("Part")
        unlock.Name = "18589360"
        unlock.Parent = client.gamepasses
    end
})

Tabs["Misc"]:AddButton({
    Title = getTrans("bGPSpins", "Title");
    Description = getTrans("bGPSpins", "Desc");
    Callback = function()
        local unlock = Instance.new("Part")
        unlock.Name = "46503236"
        unlock.Parent = client.gamepasses
    end
})

Tabs["Misc"]:AddButton({
    Title = getTrans("bGPGourd", "Title");
    Description = getTrans("bGPGourd", "Desc");
    Callback = function()
        local unlock = Instance.new("Part")
        unlock.Name = "19241624"
        unlock.Parent = client.gamepasses
    end
})

-- QUESTS

local fullnames = renv and renv.fullnames or {}

Tabs["Quests"]:AddSection(getTrans("seQuests", "Title"))

--[[Tabs["Quests"]:AddToggle("tAutoRice", {
    Title = getTrans("tAutoRice", "Title");
    Default = false;
})

Tabs["Quests"]:AddToggle("tAutoWagon", {
    Title = getTrans("tAutoWagon", "Title");
    Default = false;
})]]

Tabs["Quests"]:AddButton({
    Title = getTrans("bTTarget", "Title");
    Callback = function()
        local text = `Players.{client.Name}.PlayerGui.ExcessGuis.chairui.Holder.LocalScript`
        if not fullnames[text] then
            local target = workspace:WaitForChild("Target_Training") -- or workspace.Map:FindFirstChild("Chunk23")
            if not target then 
                Library:Notify({
                    Title = "Attention",
                    Content = "Targets not found",
                    Duration = 3
                })
                return
            end
            local farmhelp = farmHelper()
            tweento(target:GetModelCFrame()).Completed:Wait()
            target:WaitForChild("Chair"):WaitForChild("Detect_Part"):WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        Handle_Initiate_S_:InvokeServer("Quest_add", text, os.clock, {}, client, "donetargettraining")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("chairui")) 
    end
})

Tabs["Quests"]:AddButton({
    Title = getTrans("bTMeditation", "Title");
    Callback = function()
        if not fullnames[`Players.{client.Name}.PlayerGui.ExcessGuis.Meditate_gui.Holder.LocalScript`] then
            local spot = workspace.Debree:WaitForChild("thundertrainingmeditate", 1) or workspace.Debree:WaitForChild("mediatasd123vv", 1) -- or workspace.Map:FindFirstChild("Chunk23")
            if not spot then 
                Library:Notify({
                    Title = "Attention",
                    Content = "No Meditate Quest",
                    Duration = 3
                })
                return
            end
            local farmhelp = farmHelper()
            tweento(spot.CFrame).Completed:Wait()
            local mat = workspace:WaitForChild("Meditate_Mat", 1) or workspace.Map:WaitForChild("Chunk23"):WaitForChild("Meditate_Mat")
            mat:WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.Meditate_gui.Holder.LocalScript`, os.clock, {}, client, "donedoingmeditation")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("Meditate_gui"))
    end
})

Tabs["Quests"]:AddButton({
    Title = getTrans("bTPushup", "Title");
    Callback = function()
        if not fullnames[`Players.{client.Name}.PlayerGui.ExcessGuis.Push_Up_Gui.Holder.push_up_mat_local_script`] then
            local spot = workspace.Debree:WaitForChild("thundertrainingpushups", 2)-- or workspace.Map:FindFirstChild("Chunk23")
            if not spot then 
                Library:Notify({
                    Title = "Attention",
                    Content = "No Pushup Quest",
                    Duration = 3
                })
                return
            end
            local farmhelp = farmHelper()
            tweento(spot.CFrame).Completed:Wait()
            local mat; for i, v in ipairs(workspace:GetChildren()) do 
                if v.Name == "Push_Ups_Mat" and #v:GetChildren() > 0 then 
                    mat = v 
                    break
                end
            end
            mat = mat or workspace.Map:WaitForChild("Chunk23"):WaitForChild("Push_Ups_Mat")
            mat:WaitForChild("Initiated"):FireServer()
            --workspace.Map:WaitForChild("Chunk23"):WaitForChild("Push_Ups_Mat"):WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.Push_Up_Gui.Holder.push_up_mat_local_script`, os.clock, {}, client, "donepushuptraining")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("Push_Up_Gui"))
    end
})

Tabs["Quests"]:AddButton({
    Title = getTrans("bTLightning", "Title");
    Callback = function()
        --thundertrainingthunderdodge
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.thnder_gui.Holder.LocalScript`, os.clock(), {}, client, "donelightningdodge")
    end
})

Tabs["Quests"]:AddButton({
    Title = "Auto Cup";
    Callback = function()
        if not fullnames[`Players.{client.Name}.PlayerGui.ExcessGuis.cup_game_gui.Holder.cup_game_script123`] then
            local cup = workspace:WaitForChild("cup game", 2)
            if not cup.Model then 
                Library:Notify({
                    Title = "Attention",
                    Content = "No cup to win here",
                    Duration = 3
                })
                return
            end
            local farmhelp = farmHelper()
            tweento(cup.Model:GetModelCFrame()).Completed:Wait()
            cup.Model:WaitForChild("Main"):WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.cup_game_gui.Holder.cup_game_script123`, os.clock(), {}, client, "donecuptraining123asd")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("cup_game_gui"))
    end
})

Tabs["Quests"]:AddButton({
    Title = "Auto Book Quest";
    Callback = function()
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerScripts.Small_Scripts.Soryu_trainer_book_find`, os.clock(), {}, client, "givebookasd123asdasd")
    end
})

Tabs["Quests"]:AddButton({
    Title = "Split Boulder";
    Description = "Auto-equips all katanas and splits boulder";
    Callback = function()
        -- Auto-equip all katanas
        for _, sword in ipairs(ReplicatedStorage.Assets.Sword_Parts:GetChildren()) do
            if sword.Name:match("Katana") then
                local tool = client.Backpack:FindFirstChild(sword.Name:gsub("_", " ")) or client.Character:FindFirstChild(sword.Name:gsub("_", " "))
                if tool then
                    pcall(function()
                        ReplicatedStorage.Remotes.To_Server.Handle_Sword_Assets:InvokeServer(
                            "equipsword",
                            client.Character,
                            client.Character.RightHand,
                            client.Character.LeftHand,
                            sword.Equiped,
                            sword.ArmWeld,
                            tool,
                            tool:FindFirstChild("swordid") and tool.swordid.Value or 0
                        )
                        task.wait(0.1)
                    end)
                end
            end
        end
        
        -- Boulder split logic (unchanged)
        if not fullnames[`Players.{client.Name}.PlayerGui.ExcessGuis.boulder_split_ui.Holder.LocalScript`] then
            local boulder = workspace:WaitForChild("Boulder_To_Split", 2)
            if not boulder then 
                Library:Notify({Title = "Attention", Content = "No boulder to split here", Duration = 3})
                return
            end
            local farmhelp = farmHelper()
            tweento(boulder:GetModelCFrame() * CFrame.new(0, 8, 0)).Completed:Wait()
            boulder:WaitForChild("Main"):WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.boulder_split_ui.Holder.LocalScript`, os.clock(), {}, client, "donebouldersplitthing")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("boulder_split_ui"))
    end
})

Tabs["Quests"]:AddButton({
    Title = "Find Glowy Rocks";
    Callback = function()
        local rocks = workspace:WaitForChild("Sea_Rocks", 2)
        if rocks then
            local farmhelp = farmHelper()
            for i, v in ipairs(rocks:GetChildren()) do
                if v:IsA("Model") then
                    tweento(v:GetModelCFrame()).Completed:Wait()
                    task.wait(0.2)
                    v:WaitForChild("Main"):WaitForChild("take_rock"):WaitForChild("RemoteEvent"):FireServer()
                end
            end
            tweento(CFrame.new(677, 279, -2962)).Completed:Wait()
            farmhelp:Stop()
        else
            Library:Notify({
                Title = "Attention",
                Content = "No rocks to collect here",
                Duration = 3
            })
        end
    end
})

Tabs["Quests"]:AddButton({
    Title = "Pull Boulder";
    Callback = function()
        if true then --not fullnames[`Players.{client.Name}.PlayerGui.ExcessGuis.boulder_pull_ui.Holder.LocalScript`] then
            local boulder = workspace:WaitForChild("Rock", 2)
            if not boulder then 
                Library:Notify({
                    Title = "Attention",
                    Content = "No rock to pull here",
                    Duration = 3
                })
                return
            end
            local farmhelp = farmHelper()
            tweento(boulder:GetModelCFrame() * CFrame.new(0, 3, 0)).Completed:Wait()
            boulder:WaitForChild("Un_Part_experiemnt"):WaitForChild("Initiated"):FireServer()
            task.wait(0.2)
            farmhelp:Stop()
        end
        Handle_Initiate_S_:InvokeServer("Quest_add", `Players.{client.Name}.PlayerGui.ExcessGuis.boulder_pull_ui.Holder.LocalScript`, os.clock(), {}, client, "doneboulderpulling")
        Handle_Initiate_S:FireServer("remove_item", client.PlayerGui.ExcessGuis:FindFirstChild("boulder_pull_ui"))
    end
})


-- BUFFS

local skillMod = require(game:GetService("ReplicatedStorage").Modules.Server.Skills_Modules_Handler).Skills
local gmSkills = {
    "scythe_asteroid_reap";
    "Water_Surface_Slash";
    "insect_breathing_dance_of_the_centipede";
    "blood_burst_explosive_choke_slam";
    "Wind_breathing_black_wind_mountain_mist";
    "snow_breatihng_layers_frost";
    "flame_breathing_flaming_eruption";
    "Beast_breathing_devouring_slash";
    "akaza_flashing_williow_skillasd";
    "dream_bda_flesh_monster";
    "swamp_bda_swamp_domain";
    "sound_breathing_smoke_screen";
    "ice_demon_art_bodhisatva";
}
local newtbl = {}
if linked.AttackPlace then
    for i, v in ipairs(gmSkills) do
        for a, b in ipairs(game:GetService("Players").LocalPlayer.PlayerGui.Power_Adder:GetChildren()) do
            if b:IsA("Configuration") and b.Mastery_Equiped.Value == skillMod[v]["Mastery"] then
                for c, d in ipairs(b.Skills:GetChildren()) do
                    if d.Actual_Skill_Name.Value == v then
                        table.insert(newtbl, `{skillMod[v]["Mastery"]} -- {if d:FindFirstChild("Locked_Txt") then "Ult Unlocked" else `Mas {skillMod[v]["MasteryNeed"]}`}`)
                    end
                end
            end
        end
    end
end

Tabs["Buffs"]:AddDropdown("dGodMode", {
    Title = getTrans("dGodMode", "Title");
    Values = newtbl;
    Default = nil;
    Multi = false;
})

Tabs["Buffs"]:AddToggle("tGodMode", {
    Title = getTrans("tGodMode", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        if options["tKillaura"].Value then
            Library:Notify({
                Title = "Attention",
                Content = "Can't toggle godmode and killaura at the same time",
                Duration = 3
            })
            options["tGodMode"]:SetValue(false)
            return
        end
        task.spawn(function()
            --linked.distance = 6
            while options["tGodMode"].Value do
                local skillName = gmSkills[table.find(newtbl, options["dGodMode"].Value)]
                local args = {
                    [1] = "skil_ting_asd",
                    [2] = client,
                    [3] = skillName,
                    [4] = 1
                }
                
                Handle_Initiate_S:FireServer(unpack(args))  
                task.wait(skillMod[skillName]["addiframefor"] - 0.2)
            end
            --linked.distance = 7
        end)
    end
end)

Tabs["Buffs"]:AddToggle("tWarDrum", {
    Title = getTrans("tWarDrum", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options["tWarDrum"].Value do
                ReplicatedStorage.Remotes:WaitForChild("war_Drums_remote", math.huge):FireServer(true)
                task.wait(20)
            end
        end)
    end
end)
options["tWarDrum"]:SetValue(true)

Tabs["Buffs"]:AddToggle("tSunImm", {
    Title = getTrans("tSunImm", "Title");
    Default = true;
}):OnChanged(function(Value)
    pcall(function()
        client.PlayerScripts.Small_Scripts.Gameplay.Sun_Damage.Disabled = Value
    end)
end)

Tabs["Buffs"]:AddToggle("tInfStam", {
    Title = getTrans("tInfStam", "Title");
    Default = true;
}):OnChanged(function(Value)
    if not linked.playerValues then return end
    if Value then
        linked.playerValues:WaitForChild("Stamina", math.huge).MinValue = 9999
        linked.playerValues:WaitForChild("Stamina", math.huge).Value = 9999
    else
        linked.playerValues:WaitForChild("Stamina", math.huge).MinValue = 0
    end
end)

Tabs["Buffs"]:AddToggle("tInfBreath", {
    Title = getTrans("tInfBreath", "Title");
    Default = true;
}):OnChanged(function(Value)
    if not linked.playerValues then return end
    if Value then
        linked.playerValues:WaitForChild("Breath", math.huge).MinValue = 9999
        linked.playerValues:WaitForChild("Breath", math.huge).Value = 9999
    else
        linked.playerValues:WaitForChild("Breath", math.huge).MinValue = 0
    end
end)

Tabs["Buffs"]:AddToggle("tKamReg", {
    Title = "Kamado Demon Infinite Regenration";
    Description = "YOU NEED TO BE DEMON AND HAVE KAMADO CLAN";
    Default = false;
}):OnChanged(function(Value)
    if linked.AttackPlace and linked.playerData:WaitForChild("Clan").Value == "Kamado" and linked.playerData.Race.Value == 3 then
        ReplicatedStorage.Remotes:WaitForChild("heal_tang123asd"):FireServer(Value)
    else
        options["tKamReg"]:SetValue(false)
    end
end)

Tabs["Buffs"]:AddToggle("tBlaze", {
    Title = "Heart Ablaze Mode For Non Demon";
    Description = "Only requirement is not being a demon";
    Deafult = false;
}):OnChanged(function(Value)
    if not linked.AttackPlace or linked.playerData.Race == 3 then options["tBlaze"]:SetValue(false); return end
    if (not client:FindFirstChild("hacktanbgasd12312312") or client.hacktanbgasd12312312.Value == 0) then
        if Value then
            Handle_Initiate_S:FireServer("skil_ting_asd", client, "heart_ablaze_mode", 5)
            ReplicatedStorage.Remotes:WaitForChild("heart_ablaze_mode_remote"):FireServer(true)
        else
            ReplicatedStorage.Remotes:WaitForChild("heart_ablaze_mode_remote"):FireServer(false)
        end
    else
        Library:Notify({
            Title = "Attention",
            Content = "Please Wait a bit before using it",
            Duration = 3
        })
        options["tBlaze"]:SetValue(false)
    end
end)

--TELEPORT

local actualPlaces = {}

if linked.MapPlace then
    for i, v in ipairs(StarterGui.Map_Ui.Holder.Locations:GetChildren()) do
        if places[v.Name] then
            table.insert(actualPlaces, v.Name)
        end
    end
end

local downLoc = {
    "Zapiwara Mountain";
    "Kabiwaru Village";
    "Final Selection";
    "Ouwbayashi Home";
    "Slasher Demon";
    "Cave 1";
    "Village 2";
    "Mist trainer location";
    "Wop City";
    "Mugen Train Station";
    "Akeza Cave";
}


Tabs["Teleport"]:AddDropdown("dLocSelect", {
    Title = getTrans("dLocSelect", "Title");
    Values = actualPlaces;
    Default = nil;
    Multi = false;
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bTeleport", "Title");
    Description = getTrans("bTeleport", "Desc");
    Default = false;
    Callback = function()
        local coords = places[options.dLocSelect.Value]
        if coords then
            local farmhelp = farmHelper()
            if table.find(downLoc, options.dLocSelect.Value) then
                smartTp(CFrame.new(coords), CFrame.new(0, 3, 0))
            else
                smartTp(CFrame.new(coords))
            end
            farmhelp:Stop()
        end
    end
})

local quest_place = {}

for i, v in ipairs(CollectionService:GetTagged("Npcs")) do
    if v.Parent == workspace then table.insert(quest_place, v.Name) end
end

table.sort(quest_place)

Tabs["Teleport"]:AddDropdown("dQuestTp", {
    Title = "Select Npc To Tp";
    Values = quest_place;
    Default = nil;
    Multi = false;
})

Tabs["Teleport"]:AddButton({
    Title = "Teleport To Selected Npc";
    Callback = function()
        local npc = workspace:FindFirstChild(options.dQuestTp.Value or "FireHub_fgzahbgfuoirehzaof")
        if not npc then return end
        local farmhelp = farmHelper()
        smartTp(npc:GetModelCFrame())
        farmhelp:Stop()
    end
})

Tabs["Teleport"]:AddSection(getTrans("seExtTeleport", "Title"))

Tabs["Teleport"]:AddButton({
    Title = getTrans("bRejoin", "Title");
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bLobby", "Title");
    Callback = function()
        TeleportService:Teleport(5956785391, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bTp1", "Title");
    Callback = function()
        TeleportService:Teleport(17387475546, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bTp1Priv", "Title");
    Callback = function()
        TeleportService:Teleport(13883279773, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bTp2", "Title");
    Callback = function()
        TeleportService:Teleport(17387482786, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bTp2Priv", "Title");
    Callback = function()
        TeleportService:Teleport(13883059853, client)
    end
})

Tabs["Teleport"]:AddButton({
    Title = getTrans("bHub", "Title");
    Callback = function()
        TeleportService:Teleport(9321822839, client)
    end
})
--DUNGEON

Tabs["Dungeon"]:AddDropdown("dDungeonMode", {
    Title = getTrans("dDungeonMode", "Title");
    Values = {"Normal", "Competitive"};
    Default = "Normal";
    Multi = false
})

Tabs["Dungeon"]:AddToggle("tJoinDungeon", {
    Title = getTrans("tJoinDungeon", "Title");
    Default = false
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            while options.tJoinDungeon.Value do
                ReplicatedStorage:WaitForChild("TeleportCirclesEvent", math.huge):FireServer(options.dDungeonMode.Value)
                task.wait(13)
            end
            ReplicatedStorage:WaitForChild("TeleportCirclesEvent", math.huge):FireServer(options.dDungeonMode.Value)
        end)
    end
end)

Tabs["Dungeon"]:AddToggle("tAutoDungeonMob", {
    Title = getTrans("tAutoDungeonMob", "Title");
    Description = getTrans("tAutoDungeonMob", "Desc");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            local farmhelp = farmHelper()
            client.Character:WaitForChild("Humanoid").Died:Once(function()
                options.tAutoDungeonMob:SetValue(false)
            end)
            while options.tAutoDungeonMob.Value do
                for i, v in ipairs(workspace.Mobs:GetChildren()) do
                    if not options.tAutoDungeonMob.Value then
                        break
                    end
                    local model = v:FindFirstChildWhichIsA("Model")
                    local hrp = model and model:FindFirstChild("HumanoidRootPart")
                    local humanoid = model and model:FindFirstChild("Humanoid")
                    local spawnloc = v:FindFirstChild("Npc_Configuration") and v.Npc_Configuration:FindFirstChild("spawnlocaitonasd123")

                    local loc = (hrp and hrp.CFrame) or (spawnloc and CFrame.new(spawnloc.Value))

                    if not loc or (humanoid and humanoid.Health <= 0) then continue end

                    tweento(
                        loc * (options.tAutoM1.Value and CFrame.new(0, linked.distance, 0) or CFrame.new(0, -35, 0))
                    ).Completed:Wait()

                    model = v:WaitForChild(linked.ouwi_names[v.Name], 2)
                    while model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") and options.tAutoDungeonMob.Value do
                        tpto(
                            CFrame.new(model.HumanoidRootPart.Position) * 
                            ((options.tAutoM1.Value and CFrame.new(0, linked.distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)) or CFrame.new(0, -35, 0))
                        )
                        task.wait()
                    end
                end
                task.wait()
            end
            farmhelp:Stop()
        end)
    end
end)

local orbs = {"BloodMoney", "DoublePoints", "HealthRegen", "InstaKill", "MobCamouflage", "StaminaRegen", "WisteriaPoisoning"}

Tabs["Dungeon"]:AddDropdown("dOrbs", {
    Title = getTrans("dOrbs", "Title");
    Values = table.clone(orbs);
    Multi = true;
    Default = orbs;
})

local orb_conn;
Tabs["Dungeon"]:AddToggle("tCollectOrb", {
    Title = getTrans("tCollectOrb", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        orb_conn = workspace.Map.ChildAdded:Connect(function(child)
            if options.dOrbs.Value[child.Name] then
                local touch;repeat touch = child:FindFirstChild("TouchInterest", true); task.wait(0.1) until touch
                repeat 
                    firetouchinterest(client.Character.HumanoidRootPart, touch.Parent, 0)
                    task.wait(0.1)
                    firetouchinterest(client.Character.HumanoidRootPart, touch.Parent, 1)
                    task.wait(0.1)
                until not child:IsDescendantOf(workspace.Map)
            end
        end)

        for i, v in ipairs(workspace.Map:GetChildren()) do
            if options.dOrbs.Value[v.Name] then
                task.defer(function()
                    repeat 
                        firetouchinterest(client.Character.HumanoidRootPart, v:FindFirstChild("TouchInterest", true).Parent, 0)
                        task.wait(0.1)
                        firetouchinterest(client.Character.HumanoidRootPart, v:FindFirstChild("TouchInterest", true).Parent, 1)
                        task.wait(0.1)
                    until not v:IsDescendantOf(workspace.Map)
                end)
            end
        end
    else
        if orb_conn then
            orb_conn:Disconnect()
        end
    end
end)

Tabs["Dungeon"]:AddToggle("tAutoShop", {
    Title = getTrans("tAutoShop", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        client:WaitForChild("OuwigaharaSpectate", math.huge)
        if options.tAutoShop.Value then
            ReplicatedStorage.TeleportToShop:FireServer()
        end
    end
end)

Tabs["Dungeon"]:AddToggle("tAutoQuit", {
    Title = getTrans("tAutoQuit", "Title");
    Description = "Use with 'Auto to shop' toggle above\nWill wait for your chests to spawn first btw";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        client:WaitForChild("TeleportToShop", math.huge)
        if options.tAutoQuit.Value then
            task.wait((workspace.delay_chest_amount.Value / 3.7) + 10)
            pcall(function()
                wbhook("dungeon")
            end)
            TeleportService:Teleport(9321822839, client)
        end
    end
end)


Tabs["Dungeon"]:AddInput("iDieTime", {
    Title = getTrans("iDieTime", "Title");
    Default = nil;
    Placeholder = "Ex : 30";
    Numeric = true;
    Finished = true;
})

Tabs["Dungeon"]:AddToggle("tTimeDie", {
    Title = getTrans("tTimeDie", "Title");
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            local time = workspace:WaitForChild("Total_Time", math.huge)
            local inp = options.iDieTime
            while options.tTimeDie.Value do
                if time.Value / 60 >= (tonumber(inp.Value) or math.huge) then
                    client.Character:WaitForChild("Humanoid").Health = 0
                    break
                end
                task.wait()
            end
        end)
    end 
end)

-- MUGEN
Tabs["Mugen"]:AddSlider("sMugenTeleporter", {
    Title = "Choose Mugen Teleporter";
    Description = "Select wich mugen train teleport you should use when auto joining";
    Default = 1;
    Min = 1;
    Max = 7;
    Rounding = 0;
})

Tabs["Mugen"]:AddToggle("tJoinMugen", {
    Title = "Auto Join Mugen Train";
    Default = false;
    Callback = function(Value)
        if Value then
            task.spawn(function()
                task.wait(0.2)
                if not linked.MapPlace then return end
                local farmhelp = farmHelper()
                while options["tJoinMugen"].Value do
                    local tim = (tick() / 60) % 60
                    if tim > 0 and tim < 10 then
                        local tickets = linked.playerData.Inventory.Items:FindFirstChild("Mugen Train Ticket")
                        if not tickets or tickets.Amount.Value <= 0 then
                            ReplicatedStorage:WaitForChild("purchase_mugen_ticket"):FireServer(1)
                        end
                        options["tAutoBoss"]:SetValue(false)
                        publishMugenBoard()   -- leader: signal the alts to board WITH us, then board together
                        tweento(CFrame.new(workspace.MugenTrain.Teleporters["Teleport" .. options.sMugenTeleporter.Value]:GetModelCFrame().Position)).Completed:Wait()
                        break
                    end
                    task.wait()
                end
                farmhelp:Stop()
            end)
        end
    end
})

local _connections = {}
Tabs["Mugen"]:AddToggle("tAutoMugan", {
    Title = "Full Auto Solo Mugen";
    Description = "Fully automatic BUTT you need to have set a killaura before, this will toggle the main killaura on and off during mugen but not the selected killaura";
    Default = false;
    Callback = function(Value)
        if Value then
            local cutscenes = ReplicatedStorage:WaitForChild("MugenTrain", math.huge)
            cutscenes:WaitForChild("Cutscene1", math.huge)
            _connections[1] = cutscenes.Cutscene1.OnClientEvent:Once(function()
                task.wait(12)
                tpto(workspace.Map.MugenTrain.Cart1.Rengoku.SkipDialogue.CFrame)
                task.wait(1)
                fireproximityprompt(workspace.Map.MugenTrain.Cart1.Rengoku.SkipDialogue.StartDialogue)
            end)
            _connections[3] = cutscenes.Cutscene3.OnClientEvent:Once(function()
                task.wait(8)
                client.Character:WaitForChild("HumanoidRootPart")
                firetouchinterest(client.Character.HumanoidRootPart, workspace.Map.DreamWorld.DreamWorldDetection, 0)
                task.wait()
                firetouchinterest(client.Character.HumanoidRootPart, workspace.Map.DreamWorld.DreamWorldDetection, 1)
                options["tKillaura"]:SetValue(true)
            end)
            _connections[4] = cutscenes.Cutscene4.OnClientEvent:Once(function()
                options["tKillaura"]:SetValue(true)
            end)
            _connections[6] = cutscenes.Cutscene6.OnClientEvent:Once(function()
                options["tKillaura"]:SetValue(false)
            end)
            _connections[7] = cutscenes.Cutscene7.OnClientEvent:Once(function()
                task.wait(7)
                options["tKillaura"]:SetValue(true)
            end)
            _connections[8] = cutscenes.Cutscene8.OnClientEvent:Once(function()
                task.wait(10)
                for i, v in ipairs(workspace.Debree.clash_folder:GetChildren()) do
                    local args = {
                        [1] = "Change_Value",
                        [2] = v:GetChildren()[1],
                        [3] = 200
                    }
                    Handle_Initiate_S:FireServer(unpack(args))
                end
            end)
            _connections[10] = cutscenes.Cutscene10.OnClientEvent:Once(function()
                options.tAutoChest:SetValue(true)
                task.wait(17)
                if options.tWebHook.Value then wbhook("mugen") end
                task.wait(1)
                TeleportService:Teleport(5956785391, client)
            end)
        else
            for i, v in ipairs(_connections) do
                v:Disconnect()
            end
        end
    end
})

Tabs["Mugen"]:AddToggle("tAutoHell", {
    Title = "Auto Activate Hell Mode";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            local prox = workspace:WaitForChild("HardMode", math.huge):WaitForChild("ProximityPrompt", math.huge)
            tpto(prox.Parent.CFrame)
            task.wait(1)
            fireproximityprompt(prox)
        end)
    end
end)

Tabs["Mugen"]:AddToggle("tAutoMugenMob", {
    Title = "Tween Above Mobs";
    Description = "Use this if you dont have arrow\nHighy recommend using godmode with this or you may die";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            local farmhelp = farmHelper()
            client.Character:WaitForChild("Humanoid").Died:Once(function()
                print("died")
            end)
            while options.tAutoMugenMob.Value do
                for i, v in ipairs(workspace:WaitForChild("Mobs"):GetChildren()) do
                    if not options.tAutoMugenMob.Value then break end
                    local model = v:FindFirstChildWhichIsA("Model")
                    local hrp = model and model:FindFirstChild("HumanoidRootPart")
                    local humanoid = model and model:FindFirstChild("Humanoid")

                    local loc = (hrp and hrp.CFrame)

                    if not loc or (humanoid and humanoid.Health <= 0) then continue end

                    tweento(
                        loc * (options.tAutoM1.Value and CFrame.new(0, linked.distance, 0) or CFrame.new(0, -35, 0))
                    ).Completed:Wait()

                    while model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 and model:FindFirstChild("HumanoidRootPart") and options.tAutoMugenMob.Value do
                        tpto(
                            CFrame.new(model.HumanoidRootPart.Position) * 
                            ((options.tAutoM1.Value and CFrame.new(0, linked.distance, 0) * CFrame.Angles(math.rad(-90), 0, 0)) or CFrame.new(0, -35, 0))
                        )
                        task.wait()
                    end
                end
                task.wait()
            end
            farmhelp:Stop()
        end)
    end
end)

Tabs["Mugen"]:AddButton({
    Title = "Insta Clash For Everyone";
    Callback = function()
         for i, v in ipairs(workspace.Debree.clash_folder:GetChildren()) do
            local args = {
                [1] = "Change_Value",
                [2] = v:GetChildren()[1],
                [3] = 200
            }
            Handle_Initiate_S:FireServer(unpack(args))
        end
    end
})

Tabs["Mugen"]:AddToggle("tQuitMugen", {
    Title = "Auto Quit Mugen";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        _connections[10] = ReplicatedStorage:WaitForChild("MugenTrain", math.huge):WaitForChild("Cutscene10", math.huge).OnClientEvent:Once(function()
            options.tAutoChest:SetValue(true)
            task.wait(17)
            local prox = workspace.Map.Carriage:FindFirstChild("MenuTeleportProximity", true)
            tpto(prox.Parent.CFrame)
            if options.tWebHook.Value then wbhook("mugen") end
            task.wait(1)
            fireproximityprompt(prox)
        end)
    else
        if _connections[10] then _connections[10]:Disconnect() end
    end
end)

-- WEBHOOK

Tabs["Webhook"]:AddInput("iWebhook", {
    Title = getTrans("iWebhook", "Title");
    Default = nil;
    Placeholder = "Enter your webhook link";
    Numeric = false; -- Only allows numbers
    Finished = true; -- Only calls callback when you press enter
})

Tabs["Webhook"]:AddInput("iWbhookTime", {
    Title = "Delay Between Webhooks";
    Description = "Enter time in minutes";
    Default = 10;
    Placeholder = "Ex : 10";
    Numeric = true; -- Only allows numbers
    Finished = true; -- Only calls callback when you press enter
})

--local images = client.PlayerGui:FindFirstChild("MainGuis") and client.PlayerGui.MainGuis:FindFirstChild("Info2") and client.PlayerGui.MainGuis.Info2:FindFirstChild("Holder") and client.PlayerGui.MainGuis.Info2.Holder:FindFirstChild("Items_Holder")

Tabs["Webhook"]:AddToggle("tWebHook", {
    Title = getTrans("tWebHook", "Title");
    Description = "If your in dungeon or mugen train it will send webhook before auto quitting (you need it enabled of course)";
    Default = false;
}):OnChanged(function(Value)
    if Value then
        task.spawn(function()
            if placeId == 11468075017 or placeId == 11468034852 then
                --task.wait(0.2)
                --if options.tAutoQuit.Value or options.tAutoMugan.Value then return end
                return
            end
            local timer = tick()
            while options.tWebHook.Value do
                if tick() - timer >= (tonumber(options.iWbhookTime.Value) or math.huge) * 60 then
                    wbhook("normal")
                    timer = tick()
                end
                task.wait(task.wait(1))
            end
        end)
    end
end)

makefolder("FireHub")
makefolder("FireHub/PJS")
makefolder("FireHub/PJS/" .. client.UserId)

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FireHub")
InterfaceManager:BuildInterfaceSection(Tabs["Settings"])

SaveManager:IgnoreThemeSettings()
SaveManager:SetLibrary(Library)
-- Auto Grind owns these action toggles; excluding them from configs stops autoload from
-- firing them in the wrong place (e.g. Auto Join Dungeon yanking you off Map 2 during mugen).
SaveManager:SetIgnoreIndexes({
    "tJoinDungeon", "tAutoDungeonMob", "tCollectOrb", "tAutoShop", "tAutoQuit",
    "tJoinMugen", "tAutoMugan", "tQuitMugen", "tAutoMugenMob", "tAutoHell"
})
SaveManager:SetFolder("FireHub/PJS/" .. client.UserId)
SaveManager:BuildConfigSection(Tabs["Settings"])
Tabs["Settings"]:AddToggle("tAutoExec", {
    Title = getTrans("tAutoExec", "Title");
    Default = true;
    Callback = function(Value)
        getgenv().AutoExecCloudy = Value
        if Value then
            queueAutoExec()   -- guarded: queues at most once per execution
        else
            clearAutoExec()
        end
    end
})

Tabs["Settings"]:AddToggle("tHopHackers", {
    Title = "Avoid Hacker Servers";
    Description = "If someone else is using CloudHub in the server, automatically change server",
        Default = false;
}):OnChanged(function(Value)
    if Value then
        for i, v in ipairs(ReplicatedStorage.Player_Data:GetChildren()) do
            if v.Name ~= client.Name and v:WaitForChild("Custom_Properties"):WaitForChild("Nezuko_pacifier_stuff"):WaitForChild("Shrinkage").Value == SERVER_ID then
                local save = HttpService:JSONDecode((isfile("FireHub/Servers") and readfile("FireHub/Servers")) or `\{"Refresh":{tick()}, "Joined":[], "History":[]\}`)
                if tick() - save.Refresh >= 20 then
                    save.Joined = {}
                    save.Refresh = tick()
                end

                local ret = game:HttpGet(`https://games.roblox.com/v1/games/{placeId}/servers/Public?sortOrder=Asc&limit=100`)
                if ret ~= "" then
                    local dec = HttpService:JSONDecode(ret)
                    if dec.data then
                        save.History = dec.data 
                        for i, v in ipairs(dec.data) do
                            if v.playing > 1 then
                                TeleportService:TeleportToPlaceInstance(placeId, v.id, client)
                                table.insert(save.Joined, v.id)
                                break
                            end
                        end
                    end
                else
                    for i, v in ipairs(save.History) do
                        if v.playing > 1 then
                            TeleportService:TeleportToPlaceInstance(placeId, v.id, client)
                            table.insert(save.Joined, v.id)
                            break
                        end
                    end
                end

                writefile("FireHub/Servers", HttpService:JSONEncode(save))
            end
        end
    end
end)




-- ADVANCED MUSIC SYSTEM
local currentSound = nil
local musicFolder = "FireHub/Music"
local musicPlaylist = {}
local currentSongIndex = 1
local isPaused = false
local loopMode = "off" -- "off", "one", "all"
local shuffleMode = false
local songQueue = {}

if not isfolder(musicFolder) then makefolder(musicFolder) end

-- Core Functions
local function downloadMusic(url, fileName)
    local filePath = musicFolder .. "/" .. fileName
    if isfile(filePath) then return true, filePath, "Already downloaded" end
    
    local success, result = pcall(function()
        writefile(filePath, game:HttpGet(url))
    end)
    
    return success, (success and filePath or nil), (success and "Downloaded successfully!" or "Download failed: " .. tostring(result))
end

local function playMusic(filePath, volume, songName)
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
    end
    
    currentSound = Instance.new("Sound")
    currentSound.SoundId = getcustomasset(filePath)
    currentSound.Volume = volume or 0.5
    currentSound.Looped = (loopMode == "one")
    currentSound.Parent = workspace
    currentSound:Play()
    isPaused = false
    
    if loopMode ~= "one" then
        currentSound.Ended:Connect(function()
            if loopMode == "all" or currentSongIndex < #musicPlaylist then
                playNextSong()
            end
        end)
    end
    
    if songName then
        Library:Notify({Title = "Now Playing", Content = songName, Duration = 3})
    end
    
    return currentSound
end

local function playNextSong()
    if #musicPlaylist == 0 then return end
    
    -- Check queue first
    if #songQueue > 0 then
        local queuedSong = table.remove(songQueue, 1)
        local filePath = musicFolder .. "/" .. queuedSong.fileName
        
        if isfile(filePath) then
            playMusic(filePath, options.sMusicVolume.Value, queuedSong.name)
        else
            local success, path = downloadMusic(queuedSong.url, queuedSong.fileName)
            if success then playMusic(path, options.sMusicVolume.Value, queuedSong.name) end
        end
        return
    end
    
    -- Normal playlist behavior
    currentSongIndex = shuffleMode and math.random(1, #musicPlaylist) or (currentSongIndex % #musicPlaylist) + 1
    local song = musicPlaylist[currentSongIndex]
    local filePath = musicFolder .. "/" .. song.fileName
    
    if isfile(filePath) then
        playMusic(filePath, options.sMusicVolume.Value, song.name)
    else
        local success, path = downloadMusic(song.url, song.fileName)
        if success then playMusic(path, options.sMusicVolume.Value, song.name) end
    end
end

local function playPreviousSong()
    if #musicPlaylist == 0 then return end
    currentSongIndex = currentSongIndex - 1
    if currentSongIndex < 1 then currentSongIndex = #musicPlaylist end
    
    local song = musicPlaylist[currentSongIndex]
    local filePath = musicFolder .. "/" .. song.fileName
    if isfile(filePath) then playMusic(filePath, options.sMusicVolume.Value, song.name) end
end

local function pauseMusic()
    if currentSound and not isPaused then
        currentSound:Pause()
        isPaused = true
        return true
    end
    return false
end

local function resumeMusic()
    if currentSound and isPaused then
        currentSound:Resume()
        isPaused = false
        return true
    end
    return false
end

local function stopAllMusic()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
        isPaused = false
    end
end

local function updateMusicDropdown()
    local songNames = {}
    for _, song in ipairs(musicPlaylist) do
        table.insert(songNames, song.name)
    end
    options.dMusicSelect:SetValues(songNames)
    if #songNames > 0 and not options.dMusicSelect.Value then
        options.dMusicSelect:SetValue(songNames[1])
    end
end

local function savePlaylist()
    if #musicPlaylist > 0 then
        writefile("FireHub/PJS/playlist.json", HttpService:JSONEncode(musicPlaylist))
    end
end

local function loadSavedPlaylist()
    if isfile("FireHub/PJS/playlist.json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("FireHub/PJS/playlist.json"))
        end)
        
        if success and data then
            musicPlaylist = data
            updateMusicDropdown()
            Library:Notify({Title = "Playlist Loaded", Content = #musicPlaylist .. " songs loaded", Duration = 3})
        end
    end
end

local function exportPlaylist()
    if #musicPlaylist == 0 then
        return nil, "Playlist is empty"
    end
    
    local exportData = HttpService:JSONEncode(musicPlaylist)
    local fileName = "playlist_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    writefile("FireHub/Music/" .. fileName, exportData)
    
    return fileName, "Exported successfully"
end

local function importPlaylist(fileName)
    local filePath = "FireHub/Music/" .. fileName
    
    if not isfile(filePath) then
        return false, "File not found"
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(filePath))
    end)
    
    if success and data then
        for _, song in ipairs(data) do
            table.insert(musicPlaylist, song)
        end
        updateMusicDropdown()
        savePlaylist()
        return true, "Imported " .. #data .. " songs"
    else
        return false, "Invalid playlist file"
    end
end

-- UI SECTION
Tabs["Music"]:AddSection("Music Player")

Tabs["Music"]:AddInput("iMusicUrl", {
    Title = "Music URL";
    Placeholder = "https://.../song.mp3";
    Numeric = false;
})

Tabs["Music"]:AddInput("iMusicName", {
    Title = "Music Name";
    Placeholder = "Enter Name";
    Numeric = false;
})

Tabs["Music"]:AddButton({
    Title = "Add to Playlist";
    Callback = function()
        local url = options.iMusicUrl.Value
        local name = options.iMusicName.Value
        
        if url == "" or name == "" then
            Library:Notify({Title = "Error", Content = "Enter both URL and name", Duration = 3})
            return
        end
        
        table.insert(musicPlaylist, {
            name = name,
            url = url,
            fileName = name:gsub("%s+", "_"):gsub("[^%w_%-]", "") .. ".mp3"
        })
        
        Library:Notify({Title = "Added", Content = name .. " (#" .. #musicPlaylist .. ")", Duration = 2})
        updateMusicDropdown()
        options.iMusicUrl:SetValue("")
        options.iMusicName:SetValue("")
        savePlaylist()
    end
})

Tabs["Music"]:AddSection("Playback Controls")

Tabs["Music"]:AddDropdown("dMusicSelect", {
    Title = "Select Song";
    Values = {};
    Multi = false;
})

Tabs["Music"]:AddButton({
    Title = "Play Selected";
    Callback = function()
        local selected = options.dMusicSelect.Value
        if not selected or selected == "" then
            Library:Notify({Title = "Error", Content = "Select a song first", Duration = 2})
            return
        end
        
        for i, s in ipairs(musicPlaylist) do
            if s.name == selected then
                currentSongIndex = i
                local success, filePath = downloadMusic(s.url, s.fileName)
                if success then
                    playMusic(filePath, options.sMusicVolume.Value, s.name)
                else
                    Library:Notify({Title = "Error", Content = "Download failed", Duration = 3})
                end
                break
            end
        end
    end
})

Tabs["Music"]:AddButton({
    Title = "Pause / Resume";
    Callback = function()
        if isPaused then
            if resumeMusic() then Library:Notify({Title = "Resumed", Content = "", Duration = 1}) end
        else
            if pauseMusic() then Library:Notify({Title = "Paused", Content = "", Duration = 1}) end
        end
    end
})

Tabs["Music"]:AddButton({Title = "Stop", Callback = function() stopAllMusic() end})
Tabs["Music"]:AddButton({Title = "Next", Callback = function() playNextSong() end})
Tabs["Music"]:AddButton({Title = "Previous", Callback = function() playPreviousSong() end})

Tabs["Music"]:AddSection("Settings")

Tabs["Music"]:AddSlider("sMusicVolume", {
    Title = "Volume";
    Default = 0.5;
    Min = 0;
    Max = 1;
    Rounding = 2;
}):OnChanged(function(value)
    if currentSound then currentSound.Volume = value end
end)

Tabs["Music"]:AddDropdown("dLoopMode", {
    Title = "Loop Mode";
    Values = {"Off", "Loop One", "Loop All"};
    Default = "Off";
    Multi = false;
}):OnChanged(function(value)
    loopMode = (value == "Off" and "off") or (value == "Loop One" and "one") or "all"
    if currentSound then currentSound.Looped = (loopMode == "one") end
end)

Tabs["Music"]:AddToggle("tShuffleMode", {
    Title = "Shuffle";
    Default = false;
}):OnChanged(function(value)
    shuffleMode = value
end)

Tabs["Music"]:AddSection("Playlist Management")

Tabs["Music"]:AddButton({
    Title = "Remove Selected";
    Callback = function()
        local selected = options.dMusicSelect.Value
        if not selected or selected == "" then return end
        
        for i, song in ipairs(musicPlaylist) do
            if song.name == selected then
                table.remove(musicPlaylist, i)
                updateMusicDropdown()
                savePlaylist()
                Library:Notify({Title = "Removed", Content = selected, Duration = 2})
                return
            end
        end
    end
})

Tabs["Music"]:AddButton({
    Title = "View Playlist";
    Callback = function()
        if #musicPlaylist == 0 then
            Library:Notify({Title = "Empty", Content = "No songs added", Duration = 2})
            return
        end
        
        local list = "Playlist (" .. #musicPlaylist .. " songs):\n\n"
        for i, song in ipairs(musicPlaylist) do
            list = list .. i .. ". " .. song.name .. "\n"
        end
        Library:Notify({Title = "Playlist", Content = list, Duration = 10})
    end
})

Tabs["Music"]:AddButton({
    Title = "Shuffle Order";
    Callback = function()
        if #musicPlaylist < 2 then return end
        for i = #musicPlaylist, 2, -1 do
            local j = math.random(i)
            musicPlaylist[i], musicPlaylist[j] = musicPlaylist[j], musicPlaylist[i]
        end
        updateMusicDropdown()
        savePlaylist()
        Library:Notify({Title = "Shuffled", Content = "Order randomized", Duration = 2})
    end
})

Tabs["Music"]:AddButton({
    Title = "Clear Playlist";
    Callback = function()
        table.clear(musicPlaylist)
        options.dMusicSelect:SetValues({})
        stopAllMusic()
        savePlaylist()
        Library:Notify({Title = "Cleared", Content = "All songs removed", Duration = 2})
    end
})

Tabs["Music"]:AddSection("Queue")

Tabs["Music"]:AddButton({
    Title = "Add to Queue";
    Callback = function()
        local selected = options.dMusicSelect.Value
        if not selected or selected == "" then return end
        
        for _, song in ipairs(musicPlaylist) do
            if song.name == selected then
                table.insert(songQueue, song)
                Library:Notify({Title = "Queued", Content = song.name .. " (#" .. #songQueue .. ")", Duration = 2})
                break
            end
        end
    end
})

Tabs["Music"]:AddButton({
    Title = "View Queue";
    Callback = function()
        if #songQueue == 0 then
            Library:Notify({Title = "Empty", Content = "No queued songs", Duration = 2})
            return
        end
        
        local list = "Queue (" .. #songQueue .. "):\n\n"
        for i, song in ipairs(songQueue) do
            list = list .. i .. ". " .. song.name .. "\n"
        end
        Library:Notify({Title = "Queue", Content = list, Duration = 10})
    end
})

Tabs["Music"]:AddButton({
    Title = "Clear Queue";
    Callback = function()
        local count = #songQueue
        table.clear(songQueue)
        if count > 0 then
            Library:Notify({Title = "Cleared", Content = "Removed " .. count .. " songs", Duration = 2})
        end
    end
})

Tabs["Music"]:AddSection("Import / Export")

Tabs["Music"]:AddButton({
    Title = "Export Playlist";
    Description = "Save playlist to file";
    Callback = function()
        local fileName, msg = exportPlaylist()
        if fileName then
            Library:Notify({
                Title = "Exported",
                Content = "Saved as: " .. fileName,
                Duration = 5
            })
        else
            Library:Notify({
                Title = "Error",
                Content = msg,
                Duration = 3
            })
        end
    end
})

Tabs["Music"]:AddInput("iImportFile", {
    Title = "Import Playlist File";
    Description = "Enter filename to import";
    Placeholder = "playlist_20250214_120000.json";
    Numeric = false;
    Finished = true;
    Callback = function(fileName)
        if fileName == "" then return end
        
        local success, msg = importPlaylist(fileName)
        Library:Notify({
            Title = success and "Success" or "Error",
            Content = msg,
            Duration = 3
        })
    end
})

Tabs["Music"]:AddSection("Quick Add")

local quickSongs = {
    {name = "Bastardo", url = "https://files.catbox.moe/pq0bcw.mp3"},
    {name = "Never Gonna Give You Up", url = "https://files.catbox.moe/qg0lrl.mp3"},
    {name = "Die For You (Remix)", url = "https://files.catbox.moe/t6jho2.mp3"},
    {name = "Living On A Prayer", url = "https://files.catbox.moe/hc77j2.mp3"},
    {name = "QUE VAS HACER HOY", url = "https://files.catbox.moe/p2z1wj.mp3"},
}

Tabs["Music"]:AddButton({
    Title = "Add All Pre-Made Songs",
    Callback = function()
        for _, song in ipairs(quickSongs) do
            table.insert(musicPlaylist, {
                name = song.name,
                url = song.url,
                fileName = song.name:gsub("%s+", "_"):gsub("[^%w_%-]", "") .. ".mp3"
            })
        end
        updateMusicDropdown()
        savePlaylist()
        Library:Notify({Title = "Added", Content = #quickSongs .. " songs added", Duration = 2})
    end
})

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local isRightCtrl = UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    
    if isRightCtrl then
        if input.KeyCode == Enum.KeyCode.N then
            playNextSong()
        elseif input.KeyCode == Enum.KeyCode.P then
            playPreviousSong()
        elseif input.KeyCode == Enum.KeyCode.Space then
            if isPaused then resumeMusic() else pauseMusic() end
        end
    end
end)

-- Auto-save
task.spawn(function()
    while task.wait(30) do savePlaylist() end
end)

-- Load on start
loadSavedPlaylist()

-- ============ AUTO GRIND (DUNGEONS + HOURLY MUGEN) ============
-- One master toggle that OWNS the Dungeon + Mugen toggles and enforces MUTUAL EXCLUSION:
--   dungeon phase -> dungeon toggles ON, mugen toggles OFF
--   mugen phase   -> mugen toggles ON, dungeon toggles OFF (so Auto Join Dungeon can't pull you away)
-- Flow: Lobby -> Hub -> Auto Join Dungeon -> dungeon -> Hub -> repeat;
--   each hour: Hub -> Lobby -> Map 2 -> Full Auto Mugen -> Lobby -> Hub -> resume.
-- These action toggles are excluded from autoload (SetIgnoreIndexes) so they never auto-fire in
-- the wrong place before the controller sets them. Rides on Auto Execute.
do
    local LOBBY, HUB   = 5956785391, 9321822839
    local MAP2_PUBLIC  = 17387482786
    local MAP2_PRIVATE = 13883059853
    local MARKER       = "FireHub/PJS/lastmugenhour"

    -- tJoinDungeon is the ENTRY (fired from the Hub); the rest run inside the dungeon.
    local DUNGEON_FARM = {"tAutoDungeonMob", "tCollectOrb", "tAutoShop", "tAutoQuit", "tTimeDie"}
    local MUGEN_SET    = {"tJoinMugen", "tAutoMugan", "tQuitMugen"}

    local function inLobby()    return placeId == LOBBY end
    local function inHub()      return placeId == HUB end
    local function inDungeon()  return placeId == 11468075017 end          -- Ouwigahara dungeon
    local function inMugen()    return placeId == 11468034852 end          -- Mugen Train place
    local function inMap2()     return placeId == MAP2_PUBLIC or placeId == MAP2_PRIVATE end

    -- Train is up the first 10 min of each hour. Leave for Map 2 up to LEAD secs early so we're
    -- standing there before it opens; tJoinMugen then waits and boards on its own at minute 0.
    local LEAD = 120
    -- CATCH DEADLINE: if a dungeon runs long we must bail in time to still make the
    -- Mugen train. MUGEN_DUNGEON_LEAVEBY = the latest second-of-hour we can still be
    -- IN the dungeon; at/after it (while the train window is open and mugen isn't done
    -- yet) we abandon the run and route to Map 2. Tune to your travel+board time:
    -- lower it if you keep missing the train, raise it to squeeze in more dungeon.
    local MUGEN_DUNGEON_LEAVEBY = 300   -- xx:05 by default (lower it if you still miss the train)
    local function secIntoHour() return tick() % 3600 end
    local function tripWindow()  local s = secIntoHour(); return s >= (3600 - LEAD) or s < 600 end
    local function targetHour()  local s = secIntoHour(); local h = math.floor(tick() / 3600); return (s >= (3600 - LEAD)) and (h + 1) or h end
    local function mugenDone()   return isfile(MARKER) and tonumber(readfile(MARKER)) == targetHour() end
    local function mugenDue()    return tripWindow() and not mugenDone() end

    local function setSet(names, v) for _, n in ipairs(names) do if options[n] then task.spawn(function() options[n]:SetValue(v) end) end end end
    local function setOne(n, v)     if options[n] then options[n]:SetValue(v) end end
    local function allDungeonOff()  setOne("tJoinDungeon", false); setSet(DUNGEON_FARM, false) end
    -- tAutoHell reset here too so it re-fires (false->true) on the next Mugen entry
    local function allMugenOff()    setSet(MUGEN_SET, false); setOne("tAutoMugenMob", false); setOne("tAutoHell", false) end

    -- Runs while we're IN a dungeon. Each second it "thinks": is the Mugen train due
    -- this hour, still open, and are we now past the point where finishing the dungeon
    -- would make us miss it? If so, abandon the dungeon and head to the Lobby (-> Map 2)
    -- so we still catch the train. Below the deadline it does nothing - keep grinding.
    local function watchMugenCatch()
        task.spawn(function()
            while inDungeon() and options.tMasterFarm and options.tMasterFarm.Value do
                local s = secIntoHour()
                if mugenDue() and s < 600 and s >= MUGEN_DUNGEON_LEAVEBY then
                    warn(("[AutoGrind] can't finish the dungeon before the train (%.0fs into hour) - bailing to catch it."):format(s))
                    allDungeonOff()
                    allMugenOff()
                    task.wait(0.3)
                    TeleportService:Teleport(LOBBY, client)   -- Lobby -> Map 2 for the Mugen train
                    return
                end
                task.wait(1)
            end
        end)
    end

    -- only called while standing in the Lobby (a private-code join uses a lobby-only remote)
    local function joinMap2FromLobby()
        if options.dMap2Server and options.dMap2Server.Value == "Private" then
            local code = (options.iMap2Code and options.iMap2Code.Value) or ""
            if code ~= "" then
                ReplicatedStorage:WaitForChild("handle_privateserver"):InvokeServer("join", code, MAP2_PUBLIC)
            else
                TeleportService:Teleport(MAP2_PRIVATE, client)   -- random low-pop private, no code
            end
        else
            TeleportService:Teleport(MAP2_PUBLIC, client)
        end
    end

    linked.runFarmController = function()
        if not (options.tMasterFarm and options.tMasterFarm.Value) then return end
        if linked._farmRan then return end           -- once per execution (Callback + startup call)
        linked._farmRan = true
        task.spawn(function()
            -- kill the dungeon toggles the instant we land in Map 2 or the Mugen place, before
            -- anything else, so Auto Join Dungeon / Auto Tween can't fire during mugen
            if inMap2() or inMugen() then allDungeonOff() end
            repeat task.wait() until game:IsLoaded()
            task.wait(1)
            if not options.tMasterFarm.Value then return end
            if inDungeon() then
                allMugenOff()
                setOne("tJoinDungeon", true)          -- circles live in this place; stomp the portal FIRST
                setSet(DUNGEON_FARM, true)            -- then farm + shop + quit -> back to Hub
                watchMugenCatch()                     -- bail if the dungeon runs past the train-catch deadline
            elseif inMugen() then
                allDungeonOff()                       -- no dungeon stuff in the Mugen place
                setSet(MUGEN_SET, true)               -- Full Auto Solo Mugen + Auto Quit + Auto Join
                if options.tGrindHell and options.tGrindHell.Value then setOne("tAutoHell", true) end   -- hit the HardMode altar before the run
                if options.tGrindMugenTween and options.tGrindMugenTween.Value then setOne("tAutoMugenMob", true) end
            elseif inMap2() then
                if mugenDue() then
                    writefile(MARKER, tostring(targetHour())) -- claim the cycle so mugen can't loop
                    allDungeonOff()                   -- CRITICAL: dungeon set OFF so mugen can work
                    setSet(MUGEN_SET, true)           -- board + fight + quit (needs a killaura preset)
                    if options.tGrindMugenTween and options.tGrindMugenTween.Value then setOne("tAutoMugenMob", true) end
                else
                    allMugenOff(); allDungeonOff()
                    TeleportService:Teleport(LOBBY, client)   -- done/closed -> head back via the Lobby
                end
            elseif inHub() then
                if mugenDue() then
                    allDungeonOff()                   -- stop Auto Join Dungeon so we can leave for mugen
                    TeleportService:Teleport(LOBBY, client)   -- Map 2 is reached from the Lobby
                else
                    allMugenOff()
                    setOne("tJoinDungeon", true)          -- arm it in the hub and leave it on into the circles
                    linked.autoJoinGamemode("Ouwigahara") -- select Ouwigahara gamemode + queue into the dungeon
                end
            elseif inLobby() then
                if mugenDue() then
                    joinMap2FromLobby()               -- go do the hourly mugen
                else
                    allDungeonOff(); allMugenOff()
                    TeleportService:Teleport(HUB, client)     -- go to the Hub for dungeons
                end
            else
                TeleportService:Teleport(HUB, client)         -- anywhere else -> Hub
            end
        end)
    end
end

Tabs["Auto Farm"]:AddSection("Auto Grind")

Tabs["Auto Farm"]:AddParagraph({
    Title = "How to use Auto Grind";
    Content = "Farms Ouwigahara dungeons non stop, breaks for the Mugen train each hour, then returns to dungeons on its own.\n\nSETUP (turn these on, then save them as an autoload config in the Settings tab that autoload is what keeps it alive):\n- Auto Execute (Settings tab)\n- A RANGED killaura + Killaura Toggle (Kill Aura tab)\n- Auto Dungeon + Hourly Mugen (below)\n- Set Join Mode / Orbs / Die Time in the Dungeon tab, and Mugen Teleporter in the Mugen tab\n\nLeave every Dungeon and Mugen action toggle OFF - Auto Grind flips them on and off for you per place. Start it from anywhere; it routes itself to the Hub and begins.";
})

Tabs["Auto Farm"]:AddDropdown("dMap2Server", {
    Title = "Map 2 server (for Mugen)";
    Values = { "Public", "Private" };
    Default = "Public";
    Multi = false;
})

Tabs["Auto Farm"]:AddInput("iMap2Code", {
    Title = "Private server code (optional)";
    Placeholder = "Private + code = your server; Private + empty = random private";
    Numeric = false;
    Finished = true;
})

Tabs["Auto Farm"]:AddToggle("tGrindMugenTween", {
    Title = "Tween onto mobs in Mugen (melee builds)";
    Description = "Only if your killaura isn't ranged. Can fight the Full Auto cutscene steps - test it.";
    Default = false;
})

Tabs["Auto Farm"]:AddToggle("tGrindHell", {
    Title = "Activate Hell Mode each Mugen run";
    Description = "Auto Grind hits the HardMode altar on entering the train. Harder fight - only if your build can clear it.";
    Default = false;
})

Tabs["Auto Farm"]:AddToggle("tMasterFarm", {
    Title = "Auto Dungeon + Hourly Mugen";
    Default = false;
    Callback = function(Value)
        if Value then
            if options.t1v1Auto and options.t1v1Auto.Value then
                options.t1v1Auto:SetValue(false)   -- mutually exclusive: both own hub navigation
            end
            linked.runFarmController()
        else
            linked._farmRan = false
        end
    end
})

Window:SelectTab(1)

if not linked.AttackPlace then
    for i, v in options do
        if typeof(v) == "table" and v.OnChanged then
            v:OnChanged(function() end)
        end
    end
end

SaveManager:LoadAutoloadConfig()

-- fire the auto-exec queue on startup based on the (restored) toggle state
if options.tAutoExec and options.tAutoExec.Value then
    queueAutoExec()
end

-- these run the auto-join actions DIRECTLY on (re)join, bypassing the empty-handler
-- loop above that swallows OnChanged in the lobby/hub. this is what makes autoload work.
-- skipped while Auto Grind is on, since that controller owns navigation (avoids a hub tug-of-war).
local _navOwned = (options.tMasterFarm and options.tMasterFarm.Value)
    or (options.t1v1Auto and options.t1v1Auto.Value)   -- Auto 1v1 owns hub navigation too
if not _navOwned then
    if placeId == 5956785391 and options.tAutoJoin and options.tAutoJoin.Value then
        linked.autoJoinServer()
    end

    if placeId == 9321822839 and options.tHubJoin and options.tHubJoin.Value then
        linked.autoJoinGamemode()
    end
end

-- Auto Grind on + we (re)joined straight into the dungeon place: the Normal/Competitive circles
-- are HERE (same place id), so flip Auto Join Dungeon on immediately to stomp the portal, without
-- waiting on the controller pass (which can be delayed or die before it reaches the toggle).
if options.tMasterFarm and options.tMasterFarm.Value and placeId == 11468075017 then
    if options.tJoinDungeon then options.tJoinDungeon:SetValue(true) end
end

-- auto-grind controller: dungeons + hourly mugen, based out of Map 2 (self-gates on the toggle)
if linked.runFarmController then
    linked.runFarmController()
end

-- auto 1v1 controller: hub queue -> arena partner check -> leave + requeue (self-gates on the toggle)
if linked.run1v1Controller then
    linked.run1v1Controller()
end



--[[request(
    {
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Origin"] = "https://discord.com"
        },
        Body = HttpService:JSONEncode(
            {
                cmd = "INVITE_BROWSER",
                args = {code = "wgFBpD7mRh"},
                nonce = HttpService:GenerateGUID(false)
            }
        )
    }
)]]


pcall(function()
    client.PlayerGui.text_notification:Fire({
        Profile_Image = getcustomasset("CloudHub/logo.webp");
        custom_image_size = UDim2.fromScale(1.2, 1.0);
        Text = "<AnimateStepFrequency=2><AnimateStepTime=.002><TextScale=.288><AnimateStyle=Rainbow>Welcome to CloudHub\nJoin discord for support<AnimateStyle=/><TextScale=/><AnimateStepTime=/><AnimateStepFrequency=/>";
        Duration = 10;
    })
end)

client.OnTeleport:Once(function(State)
    if linked.MapPlace then
        wbhook("normal")
    end
end)
