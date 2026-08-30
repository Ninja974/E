-- ============================================================================
-- PROJECT SLAYERS - 1v1 PARTNER LOOP  (standalone, run this on the OTHER account)
-- Executor Lua (Roblox), single file. Pairs with the "1v1 (partner only)" section
-- in the CloudHub source (cloudhubsourceupdatedforme.lua) running on your main.
--
-- WHAT IT DOES (place-driven state machine, re-runs itself on every teleport):
--   anywhere -> Hub  -> follow the main account into ITS hub server
--   Hub      -> agree on one queue instant with the main, set gamemode 1v1, queue up
--   Arena    -> is the main account actually in this match?
--                  yes -> stay and fight (this script does NOT attack; run your own
--                         killaura / the hub's killaura alongside it)
--                  no  -> broadcast an abort so the MAIN drops its match too, then
--                         leave back to the Hub and requeue - both accounts, together
--
-- BOTH ACCOUNTS MUST BE ON THE SAME PC. They coordinate through the executor's
-- shared writefile folder - no HTTP, no server, nothing the game can see:
--   FireHub/PJS/1v1_hub_server.txt    "<jobId>|<epoch>"    published by the MAIN
--   FireHub/PJS/1v1_queue_signal.txt  "<queueAt>"          the second both queue at
--   FireHub/PJS/1v1_abort.txt         "<epoch>|<writer>"   "wrong opponent, bail now"
--
-- CROSS-TELEPORT PERSISTENCE: Roblox kills scripts on teleport. To keep looping, this
--   re-injects itself from a copy in the executor's workspace folder (LOADER_FILE), or
--   from a raw GitHub URL if you'd rather host it (LOADER_URL). Neither = one hop only.
-- ============================================================================

--========================= CONFIG - EDIT THESE ==============================
local PARTNER_NAME    = "artu2"      -- REQUIRED: exact username of your MAIN account (the one running CloudHub)
-- How this script re-injects itself after a teleport. LOADER_URL wins if both are set.
-- It must be the RAW github link (the "Raw" button), NOT the /blob/ page - HttpGet on a
--   /blob/ url returns GitHub's HTML, and loadstring chokes on it.
-- Re-upload this file to that repo after every edit, or the teleport keeps loading the
--   OLD version from GitHub while your local copy sits here unused.
-- LOADER_FILE is the offline fallback: a copy in the executor's own workspace folder,
--   which is what readfile() reads from. A full Windows path does NOT work - the
--   executor sandboxes readfile to that one folder.
local LOADER_URL      = "https://raw.githubusercontent.com/rencito974/E/main/pjs_1v1_partner.lua"
local LOADER_FILE     = "pjs_1v1_partner.lua"
local VERIFY_SECONDS  = 25      -- how long the arena gets to load the partner in before we call it a wrong match
local MAX_MATCH_MIN   = 10      -- failsafe: leave back to the hub if a match never ends
local ARROW_KA        = false   -- fight back with the arrow KA once the right opponent is confirmed.
                                -- OFF by default: if you're farming wins on the main, this account
                                -- should stand there and take it. Needs a bow build to do anything.
local QUEUE_LEAD      = 5       -- secs between publishing the queue instant and both accounts firing it
local QUEUE_GRACE     = 20      -- a queue signal older than this is stale
local ABORT_FRESH     = 15      -- an abort older than this is ignored
local REQUEUE_WAIT    = 25      -- if queu_up didn't take, how long to sit in the hub before retrying
local FOLLOW_COOLDOWN = 10      -- secs between attempts to teleport into the main's hub server
local JUMP_ANTIAFK    = true    -- jump every 60s too (resets the game's own movement AFK check)
--============================================================================

repeat task.wait() until game:IsLoaded()

-- SERVICES
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local VirtualUser       = game:GetService("VirtualUser")

local client  = Players.LocalPlayer
local placeId = game.PlaceId
local jobId   = game.JobId

-- PLACE IDS (verified against the hub source)
local HUB   = 9321822839

-- Every place that ISN'T a gamemode match. Anything else we land in is the arena
-- (the 1v1 arena place id varies by gamemode/map, so it's identified by exclusion).
local NOT_ARENA = {
    [5956785391]  = true,   -- Lobby
    [9321822839]  = true,   -- Hub
    [17387475546] = true, [13883279773] = true,   -- Map 1 public / private
    [17387482786] = true, [13883059853] = true,   -- Map 2 public / private
    [11468075017] = true,   -- Ouwigahara dungeon
    [11468034852] = true,   -- Mugen train
}

--========================= ANTI-AFK (hardened) ==============================
-- Re-armed on EVERY execution. A teleport lands in a fresh DataModel, so the old
-- Idled connection is DEAD - a getgenv guard would leave every place after the
-- first with no anti-afk, which is exactly how you get idle-kicked mid-loop.
do
    local function resetIdle()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end

    client.Idled:Connect(resetIdle)

    task.spawn(function()
        while task.wait(60) do
            resetIdle()
            if JUMP_ANTIAFK then
                pcall(function()
                    local hum = client.Character and client.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Jump = true end
                end)
            end
        end
    end)
end

--===================== TELEPORT PERSISTENCE (queue) =========================
local function queuePersist()
    local code
    if LOADER_URL ~= "" then
        code = ("loadstring(game:HttpGet(%q))()"):format(LOADER_URL)
    elseif LOADER_FILE ~= "" then
        -- readfile is relative to the executor's workspace folder, and the queued chunk
        -- runs in the NEXT place - so check the file is actually readable now, while we
        -- can still say something about it, instead of failing silently after a teleport.
        local ok, present = pcall(function() return isfile(LOADER_FILE) end)
        if not (ok and present) then
            warn(("[1v1Partner] LOADER_FILE %q isn't in the executor's workspace folder - copy this script there, or the loop stops after one teleport."):format(LOADER_FILE))
            return
        end
        code = ("loadstring(readfile(%q))()"):format(LOADER_FILE)
    else
        warn("[1v1Partner] no LOADER_FILE or LOADER_URL - this will do ONE teleport hop, then stop.")
        return
    end

    local q = (syn and syn.queue_on_teleport)
        or (fluxus and fluxus.queue_on_teleport)
        or queue_on_teleport
        or queueonteleport
    if q then
        pcall(q, code)
    else
        warn("[1v1Partner] executor has no queue_on_teleport - cross-teleport looping unavailable.")
    end
end

--========================= SHARED-FILE PROTOCOL =============================
local S_HUBSRV = "FireHub/PJS/1v1_hub_server.txt"
local S_QUEUE  = "FireHub/PJS/1v1_queue_signal.txt"
local S_ABORT  = "FireHub/PJS/1v1_abort.txt"

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

-- The main account's hub instance, if it published one in the last minute.
local function readHubServer()
    local d = readf(S_HUBSRV); if not d then return nil end
    local id, at = d:match("^([^|]+)|(%-?%d+)$")
    at = tonumber(at)
    if not id or not at then return nil end
    if os.time() - at > 60 then return nil end   -- stale: the main isn't sitting in the hub
    return id
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

-- Read from the player list, not the streamed-in character: with StreamingEnabled a
-- far-away partner has no HumanoidRootPart on our client and would read as "gone".
local function partnerHere()
    local want = PARTNER_NAME:lower()
    if want == "" then return false end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == want or p.DisplayName:lower() == want then return true end
    end
    return false
end

--============================ STATUS HUD ====================================
-- Corner label + heartbeat so you can glance at this instance and see its state and
-- that the thread is alive. Rebuilt every execution (each teleport is a fresh DataModel).
local C_WAIT  = Color3.fromRGB(240, 205, 90)
local C_GO    = Color3.fromRGB(90, 220, 120)
local C_RUN   = Color3.fromRGB(90, 165, 240)
local C_LEAVE = Color3.fromRGB(240, 150, 80)
local setStatus
do
    local parent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())
    if not parent then parent = pcall(function() return game:GetService("CoreGui").Name end) and game:GetService("CoreGui") or nil end
    if not parent then parent = client:WaitForChild("PlayerGui") end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Partner1v1HUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then pcall(function() gui.Parent = client:WaitForChild("PlayerGui") end) end

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.Position = UDim2.new(0, 8, 1, -8)
    frame.Size = UDim2.new(0, 250, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame); stroke.Color = Color3.fromRGB(60, 60, 72); stroke.Thickness = 1

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 12, 0, 9)
    dot.BackgroundColor3 = C_GO
    dot.BorderSizePixel = 0
    dot.Parent = frame
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 30, 0, 5)
    title.Size = UDim2.new(1, -36, 0, 16)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(235, 235, 240)
    title.Text = "1v1Partner - " .. client.Name
    title.Parent = frame

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 12, 0, 24)
    label.Size = UDim2.new(1, -18, 0, 24)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextColor3 = Color3.fromRGB(205, 205, 215)
    label.Text = "starting..."
    label.Parent = frame

    local startAt = tick()
    setStatus = function(text, color)
        pcall(function()
            if text then label.Text = text end
            if color then dot.BackgroundColor3 = color end
        end)
    end

    task.spawn(function()
        local on = false
        while gui.Parent do
            on = not on
            dot.BackgroundTransparency = on and 0 or 0.65
            local up = math.floor(tick() - startAt)
            title.Text = ("1v1Partner - %s  [%dm%02ds]"):format(client.Name, math.floor(up / 60), up % 60)
            task.wait(0.5)
        end
    end)
end

--============================ QUEUE HELPERS =================================
-- Party objects live directly under ReplicatedStorage.parties; each account owns its
-- own solo party in the hub and queues it. Same remotes the hub source uses.
local function findMyParty()
    local container = ReplicatedStorage:FindFirstChild("parties")
    if not container then return nil end
    for _, v in ipairs(container:GetChildren()) do
        local owner = v:FindFirstChild("ownerid")
        if owner and owner.Value == client.Name then
            return v
        end
    end
end

local function queue1v1()
    local party, t0 = nil, os.clock()
    repeat
        party = findMyParty()
        if not party then task.wait(1) end
    until party or (os.clock() - t0 > 30)
    if not party then
        warn("[1v1Partner] couldn't find my party in the hub - not queuing this round.")
        setStatus("no party found in hub", C_LEAVE)
        return false
    end
    local t1 = os.clock()
    repeat
        ReplicatedStorage:WaitForChild("change_game_mode"):FireServer(party.gamemodeequiped, "1v1")
        task.wait(0.3)
    until party.gamemodeequiped.Value == "1v1" or (os.clock() - t1 > 15)
    ReplicatedStorage:WaitForChild("queu_up"):FireServer()
    return true
end

--=============================== STATE: HUB =================================
-- Follow the main into ITS hub server (the hub is sharded - queuing from two
-- different shards can never match you), then queue together on the shared instant.
local function hubPhase()
    local lastFollow = 0
    while true do
        if partnerHere() then
            setStatus("hub - syncing queue with " .. PARTNER_NAME, C_GO)
            local queueAt = agreeQueueTime()
            repeat task.wait(0.2) until os.time() >= queueAt
            queue1v1()
            -- still standing here = the queue didn't take; wait it out, then retry
            local t0 = os.clock()
            repeat task.wait(0.5) until (os.clock() - t0) > REQUEUE_WAIT
        else
            local srv = readHubServer()
            if srv and srv ~= jobId and (os.clock() - lastFollow) > FOLLOW_COOLDOWN then
                lastFollow = os.clock()
                setStatus("hopping into " .. PARTNER_NAME .. "'s hub server", C_WAIT)
                pcall(function() TeleportService:TeleportToPlaceInstance(HUB, srv, client) end)
            elseif not srv then
                setStatus("waiting for " .. PARTNER_NAME .. " to reach the hub", C_WAIT)
            else
                setStatus("in the right hub server - waiting for " .. PARTNER_NAME, C_WAIT)
            end
            task.wait(2)
        end
    end
end

--=============================== ARROW KA ===================================
-- Same two loops as your standalone "Maps/Hub 1v1.lua", locked to PARTNER_NAME:
-- spam arrow_knock_back_damage at them, and re-cast the arrow_knock_back skill on
-- its cooldown so the damage remote keeps landing. Stops when the place changes.
local function startArrowKA()
    if not ARROW_KA then return end
    local toServer = ReplicatedStorage:FindFirstChild("Remotes")
    toServer = toServer and toServer:FindFirstChild("To_Server")
    local dmg   = toServer and toServer:FindFirstChild("Handle_Initiate_S")
    local skill = toServer and toServer:FindFirstChild("Handle_Initiate_S_")
    if not (dmg and skill) then
        warn("[1v1Partner] arrow KA remotes not present in this place - skipping.")
        return
    end

    local function target()
        local want = PARTNER_NAME:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= client and (p.Name:lower() == want or p.DisplayName:lower() == want) then
                return p
            end
        end
    end

    task.spawn(function()
        while true do
            local t = target()
            local char = t and t.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    dmg:FireServer("arrow_knock_back_damage", client.Character, char:GetModelCFrame(), char, 400, 400)
                end)
            end
            task.wait(0.3)
        end
    end)

    task.spawn(function()
        while true do
            pcall(function() skill:InvokeServer("skil_ting_asd", client, "arrow_knock_back", 5) end)
            task.wait(6)
        end
    end)
end

--============================== STATE: ARENA ================================
-- The check. Give the partner a few seconds to load in; if it's anyone else in here,
-- broadcast the abort (so the main drops its match too) and go back to the hub.
local function arenaPhase()
    local entered  = os.time()
    local deadline = os.clock() + VERIFY_SECONDS
    local verified = false

    setStatus("arena - checking the opponent", C_WAIT)
    while os.clock() < deadline do
        if partnerHere() then verified = true; break end
        -- the main bailed from ITS match first -> don't sit out our own timer
        local at, who = readAbort()
        if at and who ~= client.Name and at >= entered and (os.time() - at) <= ABORT_FRESH then
            warn("[1v1Partner] abort received from " .. who .. " - leaving this match.")
            break
        end
        task.wait(0.5)
    end

    if verified then
        setStatus("matched with " .. PARTNER_NAME .. " - fighting", C_RUN)
        warn("[1v1Partner] correct opponent - staying in this match.")
        startArrowKA()   -- no-op unless ARROW_KA is on
        -- failsafe: never sit in a match forever if it never ends on its own
        task.delay(MAX_MATCH_MIN * 60, function()
            setStatus("match ran long - leaving", C_LEAVE)
            TeleportService:Teleport(HUB, client)
        end)
    else
        writeAbort()   -- tells the main to drop its match too
        setStatus("wrong opponent - leaving + requeuing", C_LEAVE)
        warn("[1v1Partner] " .. PARTNER_NAME .. " is not in this match - leaving and requeuing.")
        task.wait(0.5)
        TeleportService:Teleport(HUB, client)
    end
end

--================================= DRIVER ===================================
if PARTNER_NAME == "" then
    setStatus("PARTNER_NAME is empty - edit the config", C_LEAVE)
    warn("[1v1Partner] set PARTNER_NAME to your MAIN account's username and run this again.")
    return
end

queuePersist()

task.spawn(function()
    task.wait(1)
    if placeId == HUB then
        hubPhase()
    elseif NOT_ARENA[placeId] then
        setStatus("routing to the Hub...", C_WAIT)
        TeleportService:Teleport(HUB, client)
    else
        arenaPhase()
    end
end)

warn(("[1v1Partner] loaded @ placeId %s | partner '%s'"):format(tostring(placeId), PARTNER_NAME))
