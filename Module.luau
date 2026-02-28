local Settings, Connections = ...

local _ENV = (getgenv or getrenv or getfenv)()

if type(Settings) ~= "table" or type(Connections) ~= "table" then
    return {}
end

-- Services
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

-- Remote objects
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator = Remotes:WaitForChild("Validator2")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")
local RE_RegisterAttack = ReplicatedStorage:WaitForChild("RE"):WaitForChild("RegisterAttack")
local RE_RegisterHit = ReplicatedStorage:WaitForChild("RE"):WaitForChild("RegisterHit")
local RE_ShootGunEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("ShootGunEvent")

-- Workspace folders
local ChestModels = workspace:WaitForChild("ChestModels")
local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local Map = workspace:WaitForChild("Map")
local NPCs = workspace:WaitForChild("NPCs")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

-- RunService events
local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped

-- Player data
local Player = Players.LocalPlayer
local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")
local Race = Data:WaitForChild("Race")
local Stats = Data:WaitForChild("Stats")
local Points = Data:WaitForChild("Points")
local Subclass = Data:WaitForChild("Subclass")

-- Player GUI
local PlayerGui = Player:WaitForChild("PlayerGui")
local MainGui = PlayerGui:WaitForChild("Main")
local Notifications = PlayerGui:WaitForChild("Notifications")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")
local Flags = require(Modules:WaitForChild("Flags"))
local CombatController = require(Modules:WaitForChild("Controllers"):WaitForChild("CombatController"))

-- Executor detection
local BLACKLISTED_EXECUTORS = {"NULL"}
local EXECUTOR_NAME = string.upper(identifyexecutor and identifyexecutor() or "NULL")
local IS_BLACKLISTED_EXECUTOR = table.find(BLACKLISTED_EXECUTORS, EXECUTOR_NAME) and true or false

-- Hook functions
local hookmetamethod = (not IS_BLACKLISTED_EXECUTOR and hookmetamethod) or function(...) return ... end
local hookfunction = (not IS_BLACKLISTED_EXECUTOR and hookfunction) or function(...) return ... end
local sethiddenproperty = sethiddenproperty or function() end
local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

-- Tags
local BRING_TAG = _ENV._Bring_Tag or ("b" .. math.random(80, 20000) .. "t")
local KILLAURA_TAG = _ENV._KillAura_Tag or ("k" .. math.random(120, 20000) .. "t")

-- Hidden settings
local HIDDEN_SETTINGS = {
    SKILL_COOLDOWN = 0.5,
    CLEAR_AFTER = 50
}

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

-- Helper functions
local function GetEnemyName(str)
    return (str:find("Lv. ") and str:gsub(" %pLv. %d+%p", "") or str):gsub(" %pBoss%p", "")
end

local function CheckPlayerAlly(targetPlayer)
    if tostring(targetPlayer.Team) == "Marines" and targetPlayer.Team == Player.Team then
        return false
    elseif targetPlayer:HasTag("Ally" .. Player.Name) or Player:HasTag("Ally" .. targetPlayer.Name) then
        return false
    end
    return true
end

local function WaitChilds(instance, ...)
    for _, childName in ipairs({...}) do
        instance = instance:WaitForChild(childName)
    end
    return instance
end

local function FastWait(seconds, instance, ...)
    local success, result = pcall(function()
        for _, childName in ipairs({...}) do
            instance = instance:WaitForChild(childName, seconds)
        end
        return instance
    end)
    return success and result or nil
end

local function CreateNewClear()
    local count = 0
    return {
        __newindex = function(self, index, value)
            if count >= HIDDEN_SETTINGS.CLEAR_AFTER then
                for key, cache in pairs(self) do
                    if typeof(cache) == "Instance" and not cache:IsDescendantOf(game) then
                        rawset(self, key, nil)
                    end
                end
                count = 0
            end
            count = count + 1
            return rawset(self, index, value)
        end
    }
end

function CreateDictionary(array, defaultValue)
    local dict = {}
    for _, key in ipairs(array) do
        dict[key] = (type(defaultValue) == "table") and {} or defaultValue
    end
    return dict
end

-- Signal implementation
local Signal = {}
do
    local Connection = {}
    do
        Connection.__index = Connection
        
        function Connection:Disconnect()
            if not self.Connected then return end
            local index = table.find(self.Signal, self)
            if index then table.remove(self.Signal, index) end
            self.Function = nil
            self.Connected = false
        end
        
        function Connection:Fire(...)
            if not self.Function then return end
            task.spawn(self.Function, ...)
        end
        
        function Connection.new()
            return setmetatable({Connected = true}, Connection)
        end
        
        setmetatable(Connection, {
            __index = function(_, index)
                error("Attempt to get Connection::" .. tostring(index) .. " (not a valid member)", 2)
            end,
            __newindex = function()
                error("Attempt to set Connection member (not a valid member)", 2)
            end
        })
    end
    
    Signal.__index = Signal
    
    function Signal:Connect(func)
        if type(func) ~= "function" then return nil end
        local newConnection = Connection.new()
        newConnection.Function = func
        newConnection.Signal = self
        table.insert(self.Connections, newConnection)
        return newConnection
    end
    
    function Signal:Once(func)
        local conn
        conn = self:Connect(function(...)
            func(...)
            conn:Disconnect()
        end)
        return conn
    end
    
    function Signal:Wait()
        local waitingCoroutine = coroutine.running()
        local conn = self:Connect(function(...)
            conn:Disconnect()
            task.spawn(waitingCoroutine, ...)
        end)
        return coroutine.yield()
    end
    
    function Signal:Fire(...)
        for _, connection in ipairs(self.Connections) do
            if connection.Connected then
                connection:Fire(...)
            end
        end
    end
    
    function Signal.new()
        return setmetatable({Connections = {}}, Signal)
    end
    
    setmetatable(Signal, {
        __index = function(_, index)
            error("Attempt to get Signal::" .. tostring(index) .. " (not a valid member)", 2)
        end,
        __newindex = function()
            error("Attempt to set Signal member (not a valid member)", 2)
        end
    })
end

-- Sea detection
local SEA_IDS = {
    [1] = {2753915549, 85211729168715},
    [2] = {4442272183, 79091703265657},
    [3] = {7449423635, 100117331123089}
}

local function DetectSea(placeId)
    for sea, ids in pairs(SEA_IDS) do
        if table.find(ids, placeId) then
            return sea
        end
    end
    return 0
end

-- Main Module
local Module = {}
do
    -- Cached data
    local Cached = {
        Closest = nil,
        Equipped = nil,
        Humanoids = setmetatable({}, CreateNewClear()),
        Enemies = setmetatable({}, CreateNewClear()),
        Progress = {},
        Bring = {},
        Tools = {},
        RaidIsland = nil
    }
    
    Module.Cached = Cached
    Module.Debounce = {
        TargetDebounce = 0,
        UpdateDebounce = 0,
        GetEnemy = 0,
        Skills = {}
    }
    
    Module.IsSuperBring = false
    Module.RemoveCanTouch = 0
    Module.AttackCooldown = 0
    Module.PirateRaid = 0
    Module.Webhooks = true
    Module.JobIds = true
    Module.Progress = {}
    Module.EnemyLocations = {}
    Module.SpawnLocations = {}
    
    -- Game data
    Module.GameData = {
        Sea = DetectSea(game.PlaceId),
        SeasName = {"Main", "Dressrosa", "Zou"},
        MaxMastery = 600,
        MaxLevel = workspace:GetAttribute("LEVEL_CAP") or 2600,
        StringVersion = require(ReplicatedStorage:WaitForChild("BuildInfo")).VERSION
    }
    
    -- Fruit IDs
    Module.FruitsId = {
        ["rbxassetid://15124425041"] = "Rocket",
        ["rbxassetid://15123685330"] = "Spin",
        ["rbxassetid://15123613404"] = "Blade",
        ["rbxassetid://15123689268"] = "Spring",
        ["rbxassetid://15123595806"] = "Bomb",
        ["rbxassetid://15123677932"] = "Smoke",
        ["rbxassetid://15124220207"] = "Spike",
        ["rbxassetid://121545956771325"] = "Flame",
        ["rbxassetid://15123673019"] = "Sand",
        ["rbxassetid://15123618591"] = "Dark",
        ["rbxassetid://77885466312115"] = "Eagle",
        ["rbxassetid://15112600534"] = "Diamond",
        ["rbxassetid://15123640714"] = "Light",
        ["rbxassetid://15123668008"] = "Rubber",
        ["rbxassetid://15123662036"] = "Ghost",
        ["rbxassetid://15123645682"] = "Magma",
        ["rbxassetid://15123606541"] = "Quake",
        ["rbxassetid://15123606541"] = "Buddha",
        ["rbxassetid://15123643097"] = "Love",
        ["rbxassetid://15123681598"] = "Spider",
        ["rbxassetid://116828771482820"] = "Creation",
        ["rbxassetid://15123679712"] = "Sound",
        ["rbxassetid://15123654553"] = "Phoenix",
        ["rbxassetid://15123656798"] = "Portal",
        ["rbxassetid://15123670514"] = "Rumble",
        ["rbxassetid://15123652069"] = "Pain",
        ["rbxassetid://15123587371"] = "Blizzard",
        ["rbxassetid://15123633312"] = "Gravity",
        ["rbxassetid://15123648309"] = "Mammoth",
        ["rbxassetid://15694681122"] = "T-Rex",
        ["rbxassetid://15123624401"] = "Dough",
        ["rbxassetid://15123675904"] = "Shadow",
        ["rbxassetid://10773719142"] = "Venom",
        ["rbxassetid://15123616275"] = "Control",
        ["rbxassetid://11911905519"] = "Spirit",
        ["rbxassetid://15123638064"] = "Leopard",
        ["rbxassetid://15487764876"] = "Kitsune",
        ["rbxassetid://115276580506154"] = "Yeti",
        ["rbxassetid://118054805452821"] = "Gas",
        ["rbxassetid://95749033139458"] = "Dragon East"
    }
    
    -- Bosses data
    Module.Bosses = {
        -- Sea 1
        ["Saber Expert"] = {NoQuest = true, Position = CFrame.new(-1461, 30, -51)},
        ["The Saw"] = {RaidBoss = true, Position = CFrame.new(-690, 15, 1583)},
        ["Greybeard"] = {RaidBoss = true, Position = CFrame.new(-5043, 25, 4262)},
        ["The Gorilla King"] = {IsBoss = true, Level = 20, Position = CFrame.new(-1128, 6, -451), Quest = {"JungleQuest", CFrame.new(-1598, 37, 153)}},
        ["Bobby"] = {IsBoss = true, Level = 55, Position = CFrame.new(-1131, 14, 4080), Quest = {"BuggyQuest1", CFrame.new(-1140, 4, 3829)}},
        ["Yeti"] = {IsBoss = true, Level = 105, Position = CFrame.new(1185, 106, -1518), Quest = {"SnowQuest", CFrame.new(1385, 87, -1298)}},
        ["Vice Admiral"] = {IsBoss = true, Level = 130, Position = CFrame.new(-4807, 21, 4360), Quest = {"MarineQuest2", CFrame.new(-5035, 29, 4326), 2}},
        ["Swan"] = {IsBoss = true, Level = 240, Position = CFrame.new(5230, 4, 749), Quest = {"ImpelQuest", CFrame.new(5191, 4, 692)}},
        ["Chief Warden"] = {IsBoss = true, Level = 230, Position = CFrame.new(5230, 4, 749), Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 2}},
        ["Warden"] = {IsBoss = true, Level = 220, Position = CFrame.new(5230, 4, 749), Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 1}},
        ["Magma Admiral"] = {IsBoss = true, Level = 350, Position = CFrame.new(-5694, 18, 8735), Quest = {"MagmaQuest", CFrame.new(-5319, 12, 8515)}},
        ["Fishman Lord"] = {IsBoss = true, Level = 425, Position = CFrame.new(61350, 31, 1095), Quest = {"FishmanQuest", CFrame.new(61122, 18, 1567)}},
        ["Wysper"] = {IsBoss = true, Level = 500, Position = CFrame.new(-7927, 5551, -637), Quest = {"SkyExp1Quest", CFrame.new(-7861, 5545, -381)}},
        ["Thunder God"] = {IsBoss = true, Level = 575, Position = CFrame.new(-7751, 5607, -2315), Quest = {"SkyExp2Quest", CFrame.new(-7903, 5636, -1412)}},
        ["Cyborg"] = {IsBoss = true, Level = 675, Position = CFrame.new(6138, 10, 3939), Quest = {"FountainQuest", CFrame.new(5258, 39, 4052)}},
        
        -- Sea 2
        ["Don Swan"] = {RaidBoss = true, Position = CFrame.new(2289, 15, 808)},
        ["Cursed Captain"] = {RaidBoss = true, Position = CFrame.new(912, 186, 33591)},
        ["Darkbeard"] = {RaidBoss = true, Position = CFrame.new(3695, 13, -3599)},
        ["Diamond"] = {IsBoss = true, Level = 750, Position = CFrame.new(-1569, 199, -31), Quest = {"Area1Quest", CFrame.new(-427, 73, 1835)}},
        ["Jeremy"] = {IsBoss = true, Level = 850, Position = CFrame.new(2316, 449, 787), Quest = {"Area2Quest", CFrame.new(635, 73, 919)}},
        ["Orbitus"] = {IsBoss = true, Level = 925, Position = CFrame.new(-2086, 73, -4208), Quest = {"MarineQuest3", CFrame.new(-2441, 73, -3219)}},
        ["Smoke Admiral"] = {IsBoss = true, Level = 1150, Position = CFrame.new(-5078, 24, -5352), Quest = {"IceSideQuest", CFrame.new(-6229, 82, -4853)}},
        ["Awakened Ice Admiral"] = {IsBoss = true, Level = 1400, Position = CFrame.new(6473, 297, -6944), Quest = {"FrostQuest", CFrame.new(5668, 28, -6484)}},
        ["Tide Keeper"] = {IsBoss = true, Level = 1475, Position = CFrame.new(-3711, 77, -11469), Quest = {"ForgottenQuest", CFrame.new(-3056, 240, -10145)}},
        
        -- Sea 3
        ["Tyrant of the Skies"] = {RaidBoss = true, Position = CFrame.new(-16252, 153, 1394)},
        ["Cake Prince"] = {RaidBoss = true, Position = CFrame.new(-2103, 70, -12165)},
        ["Dough King"] = {RaidBoss = true, Position = CFrame.new(-2103, 70, -12165)},
        ["rip_indra True Form"] = {RaidBoss = true, Position = CFrame.new(-5333, 424, -2673)},
        ["Stone"] = {IsBoss = true, Level = 1550, Position = CFrame.new(-1049, 40, 6791), Quest = {"PiratePortQuest", CFrame.new(-449, 109, 5950)}},
        ["Hydra Leader"] = {IsBoss = true, Level = 1675, Position = CFrame.new(5836, 1019, -83), Quest = {"VenomCrewQuest", CFrame.new(5214, 1004, 761)}},
        ["Kilo Admiral"] = {IsBoss = true, Level = 1750, Position = CFrame.new(2904, 509, -7349), Quest = {"MarineTreeIsland", CFrame.new(2485, 74, -6788)}},
        ["Captain Elephant"] = {IsBoss = true, Level = 1875, Position = CFrame.new(-13393, 319, -8423), Quest = {"DeepForestIsland", CFrame.new(-13233, 332, -7626)}},
        ["Beautiful Pirate"] = {IsBoss = true, Level = 1950, Position = CFrame.new(5370, 22, -89), Quest = {"DeepForestIsland2", CFrame.new(-12682, 391, -9901)}},
        ["Cake Queen"] = {IsBoss = true, Level = 2175, Position = CFrame.new(-710, 382, -11150), Quest = {"IceCreamIslandQuest", CFrame.new(-818, 66, -10964)}},
        ["Longma"] = {NoQuest = true, Position = CFrame.new(-10218, 333, -9444)}
    }
    
    -- Shop data
    Module.Shop = {
        {"Frags", {{"Race Reroll", {"BlackbeardReward", "Reroll", "2"}}, {"Reset Stats", {"BlackbeardReward", "Refund", "2"}}}},
        {"Ability Teacher", {
            {"Buy Geppo", {"BuyHaki", "Geppo"}},
            {"Buy Buso", {"BuyHaki", "Buso"}},
            {"Buy Soru", {"BuyHaki", "Soru"}},
            {"Buy Ken", {"KenTalk", "Buy"}}
        }},
        {"Sword", {
            {"Buy Katana", {"BuyItem", "Katana"}},
            {"Buy Cutlass", {"BuyItem", "Cutlass"}},
            {"Buy Dual Katana", {"BuyItem", "Dual Katana"}},
            {"Buy Iron Mace", {"BuyItem", "Iron Mace"}},
            {"Buy Triple Katana", {"BuyItem", "Triple Katana"}},
            {"Buy Pipe", {"BuyItem", "Pipe"}},
            {"Buy Dual-Headed Blade", {"BuyItem", "Dual-Headed Blade"}},
            {"Buy Soul Cane", {"BuyItem", "Soul Cane"}},
            {"Buy Bisento", {"BuyItem", "Bisento"}}
        }},
        {"Gun", {
            {"Buy Musket", {"BuyItem", "Musket"}},
            {"Buy Slingshot", {"BuyItem", "Slingshot"}},
            {"Buy Flintlock", {"BuyItem", "Flintlock"}},
            {"Buy Refined Slingshot", {"BuyItem", "Refined Slingshot"}},
            {"Buy Dual Flintlock", {"BuyItem", "Dual Flintlock"}},
            {"Buy Cannon", {"BuyItem", "Cannon"}},
            {"Buy Kabucha", {"BlackbeardReward", "Slingshot", "2"}}
        }},
        {"Accessories", {
            {"Buy Black Cape", {"BuyItem", "Black Cape"}},
            {"Buy Swordsman Hat", {"BuyItem", "Swordsman Hat"}},
            {"Buy Tomoe Ring", {"BuyItem", "Tomoe Ring"}},
            {"Buy Ghoul Mask", {"Ectoplasm", "Buy", 2}}
        }},
        {"Race", {{"Ghoul Race", {"Ectoplasm", "Change", 4}}, {"Cyborg Race", {"CyborgTrainer", "Buy"}}}}
    }
    
    -- Signals
    Module.Signals = {}
    do
        local Signals = Module.Signals
        Signals.PossibleStaff = Signal.new()
        Signals.OptionChanged = Signal.new()
        Signals.EnemyAdded = Signal.new()
        Signals.EnemyDied = Signal.new()
        Signals.Notify = Signal.new()
        Signals.Error = Signal.new()
        
        Signals.Error:Connect(function(errorMsg)
            _ENV.loadedFarm = false
            _ENV.OnFarm = false
            local msg = Instance.new("Message", workspace)
            _ENV.redz_hub_error = msg
            msg.Text = "redz-Hub error [" .. (Settings.RunningOption or "Null") .. "] " .. errorMsg
        end)
    end
    
    -- Run functions
    Module.RunFunctions = {}
    do
        Module.RunFunctions.Translator = function(window, translation)
            local originalMakeTab = window.MakeTab
            window.MakeTab = function(self, config)
                if translation[config[1]] then
                    config[1] = translation[config[1]]
                end
                local tab = originalMakeTab(self, config)
                local newTab = {}
                
                function newTab:AddSection(name)
                    return tab:AddSection(translation[name] or name)
                end
                
                function newTab:AddButton(config)
                    local trans = translation[config[1]]
                    if trans then
                        config[1] = type(trans) == "string" and trans or trans[1]
                        config.Desc = type(trans) ~= "string" and trans[2]
                    end
                    return tab:AddButton(config)
                end
                
                function newTab:AddToggle(config)
                    local trans = translation[config[1]]
                    if trans then
                        config[1] = type(trans) == "string" and trans or trans[1]
                        config.Desc = type(trans) ~= "string" and trans[2]
                    end
                    return tab:AddToggle(config)
                end
                
                function newTab:AddSlider(config)
                    local trans = translation[config[1]]
                    if trans then
                        config[1] = type(trans) == "string" and trans or trans[1]
                        config.Desc = type(trans) ~= "string" and trans[2]
                    end
                    return tab:AddSlider(config)
                end
                
                function newTab:AddDropdown(config)
                    local trans = translation[config[1]]
                    if trans then
                        config[1] = type(trans) == "string" and trans or trans[1]
                        config.Desc = type(trans) ~= "string" and trans[2]
                    end
                    return tab:AddDropdown(config)
                end
                
                function newTab:AddTextBox(config)
                    local trans = translation[config[1]]
                    if trans then
                        config[1] = type(trans) == "string" and trans or trans[1]
                        config.Desc = type(trans) ~= "string" and trans[2]
                    end
                    return tab:AddTextBox(config)
                end
                
                for k, v in pairs(tab) do
                    if not newTab[k] then
                        newTab[k] = v
                    end
                end
                
                return newTab
            end
        end
        
        Module.RunFunctions.Quests = function(self, questsModule, getTasks)
            local maxLevel = {{0, 700}, {700, 1500}, {1500, math.huge}}[self.Sea]
            local blacklistedQuests = {"BartiloQuest", "MarineQuest", "CitizenQuest"}
            
            for name, task in questsModule do
                if not table.find(blacklistedQuests, name) then
                    for num, mission in task do
                        local level = mission.LevelReq
                        if level >= maxLevel[1] and level < maxLevel[2] then
                            local target, positions = getTasks(mission)
                            table.insert(self.QuestList, {
                                Name = name,
                                Count = num,
                                Enemy = {Name = target, Level = level, Position = positions}
                            })
                        end
                    end
                end
            end
            
            table.sort(self.QuestList, function(a, b) 
                return a.Enemy.Level < b.Enemy.Level 
            end)
        end
        
        Module.RunFunctions.LibraryToggle = function(enabledOptions, optionToggles)
            return function(...)
                local tab, settings, flag = ...
                optionToggles[flag] = tab:AddToggle({
                    settings[1],
                    type(settings[2]) ~= "string" and settings[2],
                    function(value) enabledOptions[flag] = value end,
                    flag,
                    Desc = (type(settings[2]) == "string" and settings[2]) or settings[3]
                })
            end
        end
        
        Module.RunFunctions.FarmQueue = function(options)
            local success, err = pcall(function()
                while task.wait(Settings.SmoothMode and 0.25 or 0) do
                    local enabled = false
                    for _, option in ipairs(options) do
                        Settings.RunningOption = option.Name
                        local method = option.Function()
                        if method then
                            Settings.RunningMethod = type(method) == "string" and method
                            enabled = true
                            break
                        else
                            Settings.RunningOption = nil
                            Settings.RunningMethod = nil
                        end
                    end
                    _ENV.OnFarm = (_ENV.teleporting or enabled)
                end
            end)
            if not success then
                Module.Signals.Error:Fire(err)
            end
        end
    end
    
    -- Core functions
    function Module.FireRemote(...)
        return CommF:InvokeServer(...)
    end
    
    function Module.IsAlive(character)
        if character then
            local humanoid = Cached.Humanoids[character] or character:FindFirstChild("Humanoid")
            
            if not humanoid and character.Parent == Boats then
                return true
            elseif character.Parent == SeaBeasts then
                humanoid = character:FindFirstChild("Health")
            end
            
            if humanoid then
                if not Cached.Humanoids[character] then
                    Cached.Humanoids[character] = humanoid
                end
                return humanoid[humanoid.ClassName == "Humanoid" and "Health" or "Value"] > 0
            end
        end
        return false
    end
    
    function Module.KillAura(distance, name)
        distance = distance or 500
        for _, enemy in ipairs(Enemies:GetChildren()) do
            local primaryPart = enemy.PrimaryPart
            if (not name or enemy.Name == name) and primaryPart and not enemy:HasTag(KILLAURA_TAG) then
                if Module.IsAlive(enemy) and Player:DistanceFromCharacter(primaryPart.Position) < distance then
                    enemy:AddTag(KILLAURA_TAG)
                end
            end
        end
    end
    
    function Module.IsBoss(name)
        return Module.Bosses[name] and true or false
    end
    
    function Module.Rejoin()
        task.spawn(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, Player)
    end
    
    function Module:ServerHop()
        local placeId = game.PlaceId
        local allIds = {}
        local foundAnything = ""
        local currentHour = os.date("!*t").hour
        
        local function fetchServers()
            local url = 'https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'
            if foundAnything ~= "" then
                url = url .. '&cursor=' .. foundAnything
            end
            
            local data = HttpService:JSONDecode(HttpService:HttpGetAsync(url))
            
            if data.nextPageCursor and data.nextPageCursor ~= "null" then
                foundAnything = data.nextPageCursor
            end
            
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers then
                    local possible = true
                    for _, existingId in ipairs(allIds) do
                        if tostring(server.id) == tostring(existingId) then
                            possible = false
                            break
                        end
                    end
                    
                    if possible then
                        table.insert(allIds, tostring(server.id))
                        task.wait()
                        pcall(function()
                            task.wait()
                            ReplicatedStorage:FindFirstChild("__ServerBrowser"):InvokeServer("teleport", tostring(server.id))
                        end)
                        task.wait(4)
                    end
                end
            end
        end
        
        while true do
            pcall(fetchServers)
            task.wait()
        end
    end
    
    function Module.EnemySpawned(enemyName)
        if type(enemyName) == "table" then
            return Module.Enemies:GetClosest(enemyName)
        else
            return Module.Enemies:GetEnemyByTag(enemyName)
        end
    end
    
    function Module:IsBlacklistedExecutor()
        return IS_BLACKLISTED_EXECUTOR
    end
    
    function Module:TravelTo(sea)
        Module.FireRemote("Travel" .. self.GameData.SeasName[sea])
    end
    
    function Module.EquipTool(toolName, byType)
        byType = byType == nil and true or byType
        toolName = toolName or Settings.FarmTool
        
        if not Module.IsAlive(Player.Character) then return end
        
        local equipped = Cached.Equipped
        
        if equipped and equipped.Parent then
            local nameToCheck = byType and equipped.ToolTip or equipped.Name
            if nameToCheck == toolName then
                if equipped:GetAttribute("Locks") then
                    equipped:SetAttribute("Locks", nil)
                end
                
                if equipped.Parent == Player.Backpack then
                    Player.Character.Humanoid:EquipTool(equipped)
                elseif equipped.Parent == Player.Character then
                    return
                end
            end
        end
        
        if toolName and not byType then
            local backpackTool = Player.Backpack:FindFirstChild(toolName)
            if backpackTool then
                Cached.Equipped = backpackTool
                Player.Character.Humanoid:EquipTool(backpackTool)
            end
        else
            for _, tool in ipairs(Player.Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool.ToolTip == toolName then
                    Cached.Equipped = tool
                    Player.Character.Humanoid:EquipTool(tool)
                    return
                end
            end
        end
    end
    
    function Module:BringEnemies(targetEnemy, superBring)
        if not self.IsAlive(targetEnemy) or not targetEnemy.PrimaryPart then return end
        
        if Settings.BringMobs then
            Module.IsSuperBring = superBring or false
            
            local enemyName = targetEnemy.Name
            local playerPos = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local targetPos = targetEnemy.PrimaryPart.CFrame
            local bringTag = superBring and "ALL_MOBS" or enemyName
            
            if not Cached.Bring[bringTag] or (targetPos.Position - Cached.Bring[bringTag].Position).Magnitude > 25 then
                Cached.Bring[bringTag] = targetPos
            end
            
            local enemyList = (not superBring and self.Enemies:GetTagged(enemyName)) or Enemies:GetChildren()
            
            for _, enemy in ipairs(enemyList) do
                if enemy.Parent == Enemies and not enemy:HasTag(BRING_TAG) and enemy:FindFirstChild("CharacterReady") then
                    local primaryPart = enemy.PrimaryPart
                    if self.IsAlive(enemy) and primaryPart and (playerPos - primaryPart.Position).Magnitude < Settings.BringDistance then
                        enemy:AddTag(BRING_TAG)
                    end
                end
            end
        else
            if not Cached.Bring[targetEnemy] then
                Cached.Bring[targetEnemy] = targetEnemy.PrimaryPart.CFrame
            end
            targetEnemy.PrimaryPart.CFrame = Cached.Bring[targetEnemy]
        end
    end
    
    function Module:GetRaidIsland()
        if Cached.RaidIsland and Cached.RaidIsland:IsDescendantOf(Locations) then
            return Cached.RaidIsland
        end
        
        for i = 5, 1, -1 do
            local islandName = "Island " .. i
            for _, island in ipairs(Locations:GetChildren()) do
                if island.Name == islandName and Player:DistanceFromCharacter(island.Position) < 3500 then
                    Cached.RaidIsland = island
                    return island
                end
            end
        end
    end
    
    function Module:GetProgress(tag, ...)
        local progress = Cached.Progress
        local entry = progress[tag]
        
        if entry and (tick() - entry.debounce) < 2 then
            return entry.result
        end
        
        local result = self.FireRemote(...)
        
        if entry then
            entry.result = result
            entry.debounce = tick()
        else
            progress[tag] = {
                debounce = tick(),
                result = result
            }
        end
        
        return result
    end
    
    function Module:RemoveVolcanoLava()
        local prehistoricIsland = Map:FindFirstChild("PrehistoricIsland")
        if not prehistoricIsland then return end
        
        local core = prehistoricIsland:FindFirstChild("Core")
        if core and core:FindFirstChild("InteriorLava") then
            core.InteriorLava:Destroy()
        end
        
        for _, obj in ipairs(prehistoricIsland:GetDescendants()) do
            if string.find(string.lower(obj.Name), "lava") and obj:IsA("BasePart") then
                obj:Destroy()
            end
        end
    end
    
    function Module:RemoveBoatCollision(boat)
        for _, obj in ipairs(boat:GetDescendants()) do
            if obj:IsA("BasePart") and obj.CanCollide then
                obj.CanCollide = false
            end
        end
    end
    
    -- Chests handler
    Module.Chests = setmetatable({}, {
        __call = function(self, selectedIsland)
            local cached = self.Cached
            
            if cached and not cached:GetAttribute("IsDisabled") then
                if not selectedIsland or cached:IsDescendantOf(selectedIsland) then
                    return cached
                end
            end
            
            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end
            
            local playerPos = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local chests = CollectionService:GetTagged("_ChestTagged")
            local distance, nearest = math.huge, nil
            
            for _, chest in ipairs(chests) do
                if not selectedIsland or chest:IsDescendantOf(selectedIsland) then
                    if not chest:GetAttribute("IsDisabled") then
                        local mag = (chest:GetPivot().Position - playerPos).Magnitude
                        if mag < distance then
                            distance, nearest = mag, chest
                        end
                    end
                end
            end
            
            self.Debounce = tick()
            self.Cached = nearest
            return nearest
        end
    })
    
    -- Berry bushes handler
    Module.Berry = setmetatable({}, {
        __call = function(self, berryArray)
            local cached = self.Cached
            
            if cached and cached:IsDescendantOf(Map) then
                for _ in pairs(cached:GetAttributes()) do
                    return cached
                end
            end
            
            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end
            
            local playerPos = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local bushes = CollectionService:GetTagged("BerryBush")
            local distance, nearest = math.huge, nil
            
            for _, bush in ipairs(bushes) do
                for attrName, berryName in pairs(bush:GetAttributes()) do
                    if not berryArray or table.find(berryArray, berryName) then
                        local mag = (bush.Parent:GetPivot().Position - playerPos).Magnitude
                        if mag < distance then
                            nearest, distance = bush, mag
                        end
                    end
                end
            end
            
            self.Debounce = tick()
            self.Cached = nearest
            return nearest
        end
    })
    
    -- Fruits name resolver
    Module.FruitsName = setmetatable({}, {
        __index = function(self, fruit)
            local realFruits = Module.FruitsId
            local name = fruit.Name
            
            if name ~= "Fruit " then
                rawset(self, fruit, name)
                return name
            end
            
            rawset(self, fruit, "Fruit [ ??? ]")
            
            local fruitModel = fruit:WaitForChild("Fruit", 9e9)
            local idle = FastWait(2, fruitModel, "Idle") or FastWait(1, fruitModel, "Animation") or FastWait(1, fruitModel, "Fruit")
            
            if idle and (idle:IsA("Animation") or idle:IsA("MeshPart")) then
                local property = idle:IsA("MeshPart") and "MeshId" or "AnimationId"
                local realName = realFruits[idle[property] or ""]
                if realName then
                    rawset(self, fruit, "Fruit [ " .. realName .. " ]")
                end
            end
            
            return rawget(self, fruit)
        end
    })
    
    -- Enemies module
    Module.Enemies = (function()
        local enemiesModule = CreateDictionary({
            "__CakePrince", "__PirateRaid", "__RaidBoss", "__TyrantSkies", "__Bones", "__Elite", "__Others"
        }, {})
        
        local Signals = Module.Signals
        local IsAlive = Module.IsAlive
        local seaCastlePos = CFrame.new(-5556, 314, -2988)
        
        local tagsMobs = {
            __Elite = CreateDictionary({"Deandre", "Diablo", "Urban"}, true),
            __Bones = CreateDictionary({"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"}, true),
            __CakePrince = CreateDictionary({"Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter"}, true),
            __TyrantSkies = CreateDictionary({"Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter"}, true)
        }
        
        local function addEnemyToList(list, enemy)
            if table.find(list, enemy) then return end
            
            local humanoid = enemy:WaitForChild("Humanoid")
            if humanoid and humanoid.ClassName == "Humanoid" and humanoid.Health > 0 then
                table.insert(list, enemy)
                humanoid.Died:Wait()
                table.remove(list, table.find(list, enemy))
            end
        end
        
        local function checkPirateSea(enemy)
            if not enemy:WaitForChild("Humanoid") or enemy.Humanoid.Health <= 0 then return end
            
            local rootPart = enemy:WaitForChild("HumanoidRootPart")
            if rootPart and enemy.Name ~= "rip_indra True Form" and enemy.Name ~= "Blank Buddy" then
                if (rootPart.Position - seaCastlePos.Position).Magnitude <= 750 then
                    task.spawn(addEnemyToList, enemiesModule.__PirateRaid, enemy)
                    Module.PirateRaid = tick()
                end
            end
        end
        
        local function onEnemyAdded(enemy)
            local enemyName = enemy.Name
            local others = enemiesModule.__Others
            
            others[enemyName] = others[enemyName] or {}
            task.spawn(addEnemyToList, others[enemyName], enemy)
            
            if Module.GameData.Sea == 3 then
                task.spawn(checkPirateSea, enemy)
            end
            
            if enemy:GetAttribute("RaidBoss") then
                task.spawn(addEnemyToList, enemiesModule.__RaidBoss, enemy)
            elseif enemiesModule["__" .. enemyName] then
                task.spawn(addEnemyToList, enemiesModule["__" .. enemyName], enemy)
            else
                for tag, mobs in pairs(tagsMobs) do
                    if mobs[enemyName] then
                        task.spawn(addEnemyToList, enemiesModule[tag], enemy)
                        break
                    end
                end
            end
        end
        
        function enemiesModule.IsSpawned(enemyName)
            local cached = Module.SpawnLocations[enemyName]
            if cached and cached.Parent then
                return (cached:GetAttribute("Active") or enemiesModule:GetEnemyByTag(enemyName)) and true or false
            end
            return enemiesModule:GetEnemyByTag(enemyName) and true or false
        end
        
        function enemiesModule:GetTagged(tagName)
            return self["__" .. tagName] or self.__Others[tagName]
        end
        
        function enemiesModule:GetEnemyByTag(tagName)
            local cachedEnemy = Cached.Enemies[tagName]
            if cachedEnemy and IsAlive(cachedEnemy) then
                return cachedEnemy
            end
            
            local enemies = self:GetTagged(tagName)
            if enemies and #enemies > 0 then
                for _, enemy in ipairs(enemies) do
                    if IsAlive(enemy) then
                        Cached.Enemies[tagName] = enemy
                        return enemy
                    end
                end
            end
        end
        
        function enemiesModule:GetClosest(enemyNames)
            local specialTag = table.concat(enemyNames, ".")
            local cachedEnemy = Cached.Enemies[specialTag]
            
            if cachedEnemy and IsAlive(cachedEnemy) then
                return cachedEnemy
            end
            
            local distance, nearest = math.huge, nil
            
            for _, name in ipairs(enemyNames) do
                local enemy = self:GetClosestByTag(name)
                if enemy and enemy.PrimaryPart then
                    local mag = Player:DistanceFromCharacter(enemy.PrimaryPart.Position)
                    if mag <= distance then
                        distance, nearest = mag, enemy
                    end
                end
            end
            
            if nearest then
                Cached.Enemies[specialTag] = nearest
                return nearest
            end
        end
        
        function enemiesModule:GetClosestByTag(tagName)
            local cachedEnemy = Cached.Enemies[tagName]
            if cachedEnemy and IsAlive(cachedEnemy) then
                return cachedEnemy
            end
            
            local enemies = self:GetTagged(tagName)
            if enemies and #enemies > 0 then
                local distance, nearest = math.huge, nil
                local playerPos = (Player.Character or Player.CharacterAdded():Wait()):GetPivot().Position
                
                for _, enemy in ipairs(enemies) do
                    local primaryPart = enemy.PrimaryPart
                    if primaryPart and IsAlive(enemy) then
                        local mag = (playerPos - primaryPart.Position).Magnitude
                        if mag <= 15 then
                            Cached.Enemies[tagName] = enemy
                            return enemy
                        elseif mag <= distance then
                            distance, nearest = mag, enemy
                        end
                    end
                end
                
                if nearest then
                    Cached.Enemies[tagName] = nearest
                    return nearest
                end
            end
        end
        
        function enemiesModule:CreateNewTag(tag, enemyList)
            local newTag = {}
            self["__" .. tag] = newTag
            
            for _, enemyName in ipairs(enemyList) do
                self["__" .. enemyName] = newTag
                local others = self.__Others[enemyName]
                if others then
                    for _, enemy in ipairs(others) do
                        task.spawn(addEnemyToList, newTag, enemy)
                    end
                end
            end
            
            return newTag
        end
        
        -- Bring function
        local function bringEnemy(enemy)
            local playerRoot = (Player.Character or Player.CharacterAdded():Wait()):WaitForChild("HumanoidRootPart")
            local enemyRoot = enemy:WaitForChild("HumanoidRootPart")
            local humanoid = enemy:WaitForChild("Humanoid")
            local enemyName = enemy.Name
            
            sethiddenproperty(Player, "SimulationRadius", math.huge)
            
            local bodyVelocity = Instance.new("BodyVelocity", enemyRoot)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            
            local bodyPosition = Instance.new("BodyPosition", enemyRoot)
            bodyPosition.Position = enemyRoot.Position
            bodyPosition.P = 30000
            bodyPosition.D = 3000
            bodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            
            while playerRoot and enemyRoot and humanoid and humanoid.Health > 0 and enemy.Parent == Enemies and enemy:HasTag(BRING_TAG) do
                local target = Cached.Bring[Module.IsSuperBring and "ALL_MOBS" or enemyName]
                
                if target and (playerRoot.Position - enemyRoot.Position).Magnitude <= Settings.BringDistance then
                    if (enemyRoot.Position - target.Position).Magnitude <= 70 then
                        enemyRoot.CFrame = target
                    else
                        enemyRoot.CanCollide = false
                        bodyPosition.Position = target.Position
                    end
                end
                task.wait()
            end
            
            if enemy and enemy:HasTag(BRING_TAG) then
                enemy:RemoveTag(BRING_TAG)
            end
        end
        
        -- KillAura function
        local function killAura(enemy)
            local humanoid = enemy:FindFirstChild("Humanoid")
            local rootPart = enemy:FindFirstChild("HumanoidRootPart")
            
            pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
            
            if humanoid and rootPart then
                rootPart.CanCollide = false
                rootPart.Size = Vector3.new(60, 60, 60)
                humanoid:ChangeState(15)
                humanoid.Health = 0
                task.wait()
                enemy:RemoveTag(KILLAURA_TAG)
            end
        end
        
        -- Initialize
        for _, enemy in ipairs(CollectionService:GetTagged("BasicMob")) do
            onEnemyAdded(enemy)
        end
        for _, enemy in ipairs(Enemies:GetChildren()) do
            onEnemyAdded(enemy)
        end
        
        table.insert(Connections, CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(onEnemyAdded))
        table.insert(Connections, Enemies.ChildAdded:Connect(onEnemyAdded))
        table.insert(Connections, CollectionService:GetInstanceAddedSignal(KILLAURA_TAG):Connect(killAura))
        table.insert(Connections, CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(bringEnemy))
        
        return enemiesModule
    end)()
    
    -- Inventory module
    Module.Inventory = (function()
        local inventory = {
            Unlocked = setmetatable({}, {__index = function() return false end}),
            Mastery = setmetatable({}, {__index = function() return 0 end}),
            Count = setmetatable({}, {__index = function() return 0 end}),
            MasteryRequirements = {},
            Items = {}
        }
        
        function inventory:UpdateItem(item)
            if type(item) == "table" then
                if item.Type == "Wear" then
                    item.Type = "Accessory"
                end
                
                local name = item.Name
                self.Items[name] = item
                
                if not self.Unlocked[name] then
                    self.Unlocked[name] = true
                end
                if item.Count then
                    self.Count[name] = item.Count
                end
                if item.Mastery then
                    self.Mastery[name] = item.Mastery
                end
                if item.MasteryRequirements then
                    self.MasteryRequirements[name] = item.MasteryRequirements
                end
            end
        end
        
        function inventory:RemoveItem(itemName)
            if type(itemName) == "string" then
                self.Unlocked[itemName] = nil
                self.Mastery[itemName] = nil
                self.Count[itemName] = nil
                self.Items[itemName] = nil
            end
        end
        
        local function onCommEvent(method, ...)
            if method == "ItemChanged" then
                inventory:UpdateItem(...)
            elseif method == "ItemAdded" then
                inventory:UpdateItem(...)
            elseif method == "ItemRemoved" then
                inventory:RemoveItem(...)
            elseif method == "Notify" then
                Module.Signals.Notify:Fire(...)
            end
        end
        
        task.spawn(function()
            table.insert(Connections, CommE.OnClientEvent:Connect(onCommEvent))
            for _, item in ipairs(Module.FireRemote("getInventory")) do
                inventory:UpdateItem(item)
            end
        end)
        
        return inventory
    end)()
    
    -- Fast attack module
    Module.FastAttack = (function()
        local fastAttack = {
            Distance = 50,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil,
            Debounce = 0,
            ComboDebounce = 0,
            ShootDebounce = 0,
            M1Combo = 0,
            
            Overheat = {
                ["Dragonstorm"] = {
                    MaxOverheat = 3,
                    Cooldown = 0,
                    TotalOverheat = 0,
                    Distance = 400,
                    Shooting = false
                }
            },
            ShootsPerTarget = {
                ["Dual Flintlock"] = 2
            },
            SpecialShoots = {
                ["Skull Guitar"] = "TAP",
                ["Bazooka"] = "Position",
                ["Cannon"] = "Position",
                ["Dragonstorm"] = "Overheat"
            },
            HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"},
            EnemyRootPart = nil
        }
        
        local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
        local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
        local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
        local Events = ReplicatedStorage:WaitForChild("Events")
        
        local combatRemoteThread = pcall(function()
            return Flags.COMBAT_REMOTE_THREAD or false
        end)
        
        local shootFunction = nil
        pcall(function()
            shootFunction = getupvalue(CombatController.Attack, 9)
        end)
        
        local hitFunction = nil
        task.defer(function()
            if getsenv then
                hitFunction = (getmenv or getsenv)(Net)._G.SendHitsToServer
            end
        end)
        
        local IsAlive = Module.IsAlive
        
        fastAttack.ShootsFunctions = {
            ["Skull Guitar"] = function(self, equipped, position)
                equipped.RemoteEvent:FireServer("TAP", position)
            end
        }
        
        local function expandHitBox(enemies)
            for _, enemyData in ipairs(enemies) do
                enemyData[2].Size = Vector3.one * 50
                enemyData[2].Transparency = 1
            end
        end
        
        function fastAttack:ShootInTarget(targetPos)
            local equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            
            if equipped and equipped.ToolTip == "Gun" then
                local cooldown = equipped:FindFirstChild("Cooldown")
                if cooldown and (tick() - self.ShootDebounce) >= cooldown.Value then
                    if self.ShootsFunctions[equipped.Name] then
                        return self.ShootsFunctions[equipped.Name](self, equipped, targetPos)
                    end
                    
                    if shootFunction then
                        local shootType = self.SpecialShoots[equipped.Name] or "Normal"
                        
                        if shootType == "Position" or (shootType == "TAP" and equipped:FindFirstChild("RemoteEvent")) then
                            equipped:SetAttribute("LocalTotalShots", (equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                            GunValidator:FireServer(self:GetValidator2())
                            
                            if shootType == "TAP" then
                                equipped.RemoteEvent:FireServer("TAP", targetPos)
                            else
                                RE_ShootGunEvent:FireServer(targetPos)
                            end
                            
                            self.ShootDebounce = tick()
                        end
                    else
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                        task.wait(0.05)
                        self.ShootDebounce = tick()
                    end
                end
            end
        end
        
        function fastAttack:CheckStun(toolTip, character, humanoid)
            local stun = character:FindFirstChild("Stun")
            local busy = character:FindFirstChild("Busy")
            
            if humanoid.Sit and (toolTip == "Sword" or toolTip == "Melee" or toolTip == "Gun") then
                return false
            end
            return true
        end
        
        function fastAttack:Process(shouldAttack, enemyFolder, bladeHits, position, distance)
            if not shouldAttack then return end
            
            local hitboxLimbs = self.HitboxLimbs
            local mobs = enemyFolder:GetChildren()
            
            for _, enemy in ipairs(mobs) do
                local basePart = enemy:FindFirstChild(hitboxLimbs[math.random(#hitboxLimbs)]) or enemy.PrimaryPart
                if not basePart then continue end
                
                local canAttack = enemy.Parent == Characters and CheckPlayerAlly(Players:GetPlayerFromCharacter(enemy))
                
                if enemy ~= Player.Character and (enemy.Parent ~= Characters or canAttack) then
                    if IsAlive(enemy) and (position - basePart.Position).Magnitude <= distance then
                        if not self.EnemyRootPart then
                            self.EnemyRootPart = basePart
                        else
                            table.insert(bladeHits, {enemy, basePart})
                        end
                    end
                end
            end
        end
        
        function fastAttack:GetAllBladeHits(character, distance)
            local pos = character:GetPivot().Position
            local bladeHits = {}
            distance = distance or self.Distance
            
            self:Process(self.attackMobs, Enemies, bladeHits, pos, distance)
            self:Process(self.attackMobs, SeaBeasts, bladeHits, pos, distance)
            self:Process(self.attackPlayers, Characters, bladeHits, pos, distance)
            
            return bladeHits
        end
        
        function fastAttack:GetClosestEnemy(character, distance)
            local bladeHits = self:GetAllBladeHits(character, distance)
            local dist, closest = math.huge, nil
            
            for _, enemyData in ipairs(bladeHits) do
                local mag = closest and (closest.Position - enemyData[2].Position).Magnitude or dist
                if mag <= dist then
                    dist, closest = mag, enemyData[2]
                end
            end
            
            return closest
        end
        
        function fastAttack:GetGunHits(character, distance)
            local bladeHits = self:GetAllBladeHits(character, distance)
            local gunHits = {}
            
            for _, enemyData in ipairs(bladeHits) do
                if not gunHits[1] or (enemyData[2].Position - gunHits[1].Position).Magnitude <= 10 then
                    table.insert(gunHits, enemyData[2])
                end
            end
            
            return gunHits
        end
        
        function fastAttack:GetCombo()
            local combo = tick() - self.ComboDebounce <= 0.4 and self.M1Combo or 0
            combo = combo >= 4 and 1 or combo + 1
            
            self.ComboDebounce = tick()
            self.M1Combo = combo
            
            return combo
        end
        
        function fastAttack:UseFruitM1(character, equipped, combo)
            local pos = character:GetPivot().Position
            
            for _, enemy in ipairs(Enemies:GetChildren()) do
                local primaryPart = enemy.PrimaryPart
                if IsAlive(enemy) and primaryPart and (primaryPart.Position - pos).Magnitude <= 50 then
                    local direction = (primaryPart.Position - pos).Unit
                    return equipped.LeftClickRemote:FireServer(direction, combo)
                end
            end
        end
        
        function fastAttack:UseNormalClick(humanoid, character, cooldown)
            self.EnemyRootPart = nil
            local bladeHits = self:GetAllBladeHits(character)
            local enemyHit = self.EnemyRootPart
            
            if enemyHit then
                if combatRemoteThread and hitFunction then
                    RE_RegisterAttack:FireServer(cooldown)
                    hitFunction(enemyHit, bladeHits)
                elseif combatRemoteThread then
                    RE_RegisterAttack:FireServer(cooldown)
                    RE_RegisterHit:FireServer(enemyHit, bladeHits)
                else
                    table.insert(bladeHits, {enemyHit.Parent, enemyHit})
                    expandHitBox(bladeHits)
                    
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end
        end
        
        function fastAttack:GetValidator2()
            if not shootFunction then return 0, 0 end
            
            local v1 = getupvalue(shootFunction, 15)
            local v2 = getupvalue(shootFunction, 13)
            local v3 = getupvalue(shootFunction, 16)
            local v4 = getupvalue(shootFunction, 17)
            local v5 = getupvalue(shootFunction, 14)
            local v6 = getupvalue(shootFunction, 12)
            local v7 = getupvalue(shootFunction, 18)
            
            local v8 = v6 * v2
            local v9 = (v5 * v2 + v6 * v1) % v3
            
            v9 = (v9 * v3 + v8) % v4
            v5 = math.floor(v9 / v3)
            v6 = v9 - v5 * v3
            v7 = v7 + 1
            
            setupvalue(shootFunction, 15, v1)
            setupvalue(shootFunction, 13, v2)
            setupvalue(shootFunction, 16, v3)
            setupvalue(shootFunction, 17, v4)
            setupvalue(shootFunction, 14, v5)
            setupvalue(shootFunction, 12, v6)
            setupvalue(shootFunction, 18, v7)
            
            return math.floor(v9 / v4 * 16777215), v7
        end
        
        function fastAttack:UseGunShoot(character, equipped)
            if not equipped.Enabled then return end
            
            local shootType = self.SpecialShoots[equipped.Name] or "Normal"
            
            if shootType == "Normal" or shootType == "Overheat" then
                if shootType == "Overheat" then
                    local data = self.Overheat[equipped.Name]
                    if data.Shooting then return end
                    
                    local target = self:GetClosestEnemy(character, data.Distance or 100)
                    if target then
                        data.Shooting = true
                        
                        while equipped and equipped.Parent == Player.Character and data.TotalOverheat < data.MaxOverheat do
                            if target and target.Parent and IsAlive(target.Parent) then
                                equipped:SetAttribute("LocalTotalShots", (equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                                GunValidator:FireServer(self:GetValidator2())
                                RE_ShootGunEvent:FireServer(target.Position, {target})
                                data.TotalOverheat = data.TotalOverheat + task.wait(data.Cooldown)
                            else
                                break
                            end
                        end
                        
                        while data.TotalOverheat > 0 do
                            data.TotalOverheat = math.clamp(data.TotalOverheat - task.wait(), 0, data.MaxOverheat)
                        end
                        
                        data.Shooting = false
                    end
                else
                    local hits = self:GetGunHits(character, 120)
                    local target = hits[1] and hits[1].Position
                    
                    if target then
                        equipped:SetAttribute("LocalTotalShots", (equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                        GunValidator:FireServer(self:GetValidator2())
                        
                        for _ = 1, (self.ShootsPerTarget[equipped.Name] or 1) do
                            RE_ShootGunEvent:FireServer(target, hits)
                        end
                    end
                end
            elseif shootType == "Position" or (shootType == "TAP" and equipped:FindFirstChild("RemoteEvent")) then
                local target = self:GetClosestEnemy(character, 200)
                if target then
                    if self.ShootsFunctions[equipped.Name] then
                        return self.ShootsFunctions[equipped.Name](self, equipped, target.Position)
                    end
                    
                    equipped:SetAttribute("LocalTotalShots", (equipped:GetAttribute("LocalTotalShots") or 0) + 1)
                    GunValidator:FireServer(self:GetValidator2())
                    
                    if shootType == "TAP" then
                        equipped.RemoteEvent:FireServer("TAP", target.Position)
                    else
                        RE_ShootGunEvent:FireServer(target.Position)
                    end
                end
            end
        end
        
        function fastAttack.attack()
            if not Settings.AutoClick then return end
            if not IsAlive(Player.Character) then return end
            
            local self = fastAttack
            local character = Player.Character
            local humanoid = character.Humanoid
            
            local equipped = character:FindFirstChildOfClass("Tool")
            local toolTip = equipped and equipped.ToolTip
            local toolName = equipped and equipped.Name
            
            if not equipped or (toolTip ~= "Gun" and toolTip ~= "Melee" and toolTip ~= "Blox Fruit" and toolTip ~= "Sword") then
                return
            end
            
            local cooldownObj = equipped:FindFirstChild("Cooldown")
            local cooldown = cooldownObj and cooldownObj.Value or 0.3
            
            if (tick() - self.Debounce) >= cooldown and self:CheckStun(toolTip, character, humanoid) then
                local combo = self:GetCombo()
                cooldown = cooldown + (combo >= 4 and 0.01 or 0)
                
                self.Equipped = equipped
                self.Debounce = (combo >= 4 and toolTip ~= "Gun") and (tick() + 0.05) or tick()
                
                if toolTip == "Blox Fruit" then
                    if toolName == "Ice-Ice" or toolName == "Light-Light" then
                        return self:UseNormalClick(humanoid, character, cooldown)
                    elseif equipped:FindFirstChild("LeftClickRemote") then
                        if toolName == "Blade-Blade" or toolName == "Gas-Gas" then
                            return self:UseFruitM1(character, equipped, combo)
                        else
                            return equipped.LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                        end
                    end
                elseif toolTip == "Gun" then
                    if shootFunction then
                        return self:UseGunShoot(character, equipped)
                    end
                else
                    return self:UseNormalClick(humanoid, character, cooldown)
                end
            end
        end
        
        table.insert(Connections, Stepped:Connect(fastAttack.attack))
        
        return fastAttack
    end)()
    
    -- Raid list
    Module.RaidList = (function()
        local success, raidModule = pcall(require, ReplicatedStorage:WaitForChild("Raids"))
        
        if not success or type(raidModule) ~= "table" then
            return {
                "Phoenix", "Dough", "Flame", "Ice", "Quake", "Light",
                "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand"
            }
        end
        
        local advancedRaids = raidModule.advancedRaids or {}
        local normalRaids = raidModule.raids or {}
        local raidList = {}
        
        for _, raid in ipairs(advancedRaids) do
            table.insert(raidList, raid)
        end
        for _, raid in ipairs(normalRaids) do
            table.insert(raidList, raid)
        end
        
        return raidList
    end)()
    
    -- Tween module
    Module.Tween = (function()
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.P = 1000
        
        if _ENV.tween_bodyvelocity then
            _ENV.tween_bodyvelocity:Destroy()
        end
        
        _ENV.tween_bodyvelocity = bodyVelocity
        
        local IsAlive = Module.IsAlive
        local canRemoveTag = false
        
        local baseParts, canCollideObjects, canTouchObjects = {}, {}, {}
        do
            local function addObject(obj)
                if obj:IsA("BasePart") and (obj.CanCollide or obj.CanTouch) then
                    table.insert(baseParts, obj)
                    if obj.CanCollide then canCollideObjects[obj] = true end
                    if obj.CanTouch then canTouchObjects[obj] = true end
                end
            end
            
            local function removeObject(obj)
                local idx = table.find(baseParts, obj)
                if idx then table.remove(baseParts, idx) end
            end
            
            local function onCharacterAdded(character)
                table.clear(baseParts)
                
                for _, obj in ipairs(character:GetDescendants()) do
                    addObject(obj)
                end
                
                character.DescendantAdded:Connect(addObject)
                character.DescendantRemoving:Connect(removeObject)
                
                character:WaitForChild("Humanoid", 9e9).Died:Wait()
                table.clear(baseParts)
            end
            
            table.insert(Connections, Player.CharacterAdded:Connect(onCharacterAdded))
            task.spawn(onCharacterAdded, Player.Character)
        end
        
        local function handleNoClip(character)
            if not IsAlive(character) then return end
            
            if _ENV.OnFarm and not Player:HasTag("Teleporting") then
                Player:AddTag("Teleporting")
                canRemoveTag = true
            elseif not _ENV.OnFarm and canRemoveTag and Player:HasTag("Teleporting") then
                Player:RemoveTag("Teleporting")
                canRemoveTag = false
            end
            
            if _ENV.OnFarm then
                for _, part in ipairs(baseParts) do
                    local canTouchVal = (tick() - Module.RemoveCanTouch) <= 1 and false or true
                    
                    if canTouchObjects[part] and part.CanTouch ~= canTouchVal then
                        part.CanTouch = canTouchVal
                    end
                    if canCollideObjects[part] and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            elseif character.PrimaryPart and (not character.PrimaryPart.CanCollide or not character.PrimaryPart.CanTouch) then
                for _, part in ipairs(baseParts) do
                    if canCollideObjects[part] then
                        part.CanCollide = true
                    end
                    if canTouchObjects[part] then
                        part.CanTouch = true
                    end
                end
            end
        end
        
        local function updateVelocity(character)
            local rootPart = character and character:FindFirstChild("UpperTorso")
            local humanoid = character and character:FindFirstChild("Humanoid")
            local bv = _ENV.tween_bodyvelocity
            
            if _ENV.OnFarm and rootPart and humanoid and humanoid.Health > 0 then
                if bv.Parent ~= rootPart then
                    bv.Parent = rootPart
                end
            elseif bv.Parent then
                bv.Parent = nil
            end
            
            if bv.Velocity ~= Vector3.zero and (not humanoid or not humanoid.SeatPart or not _ENV.OnFarm) then
                bv.Velocity = Vector3.zero
            end
        end
        
        table.insert(Connections, Stepped:Connect(function()
            local character = Player.Character
            updateVelocity(character)
            handleNoClip(character)
        end))
        
        return bodyVelocity
    end)()
    
    -- Hooking module
    Module.Hooking = (function()
        local hooking = {
            Skills = CreateDictionary({"Z", "X", "C", "V", "F"}, true),
            ClosestEnemies = {}
        }
        
        local Enabled = _ENV.rz_EnabledOptions
        local Debounce = Module.Debounce
        local IsAlive = Module.IsAlive
        
        local function getNextTarget(mode, returnList)
            if (tick() - Debounce.TargetDebounce) <= 2 or _ENV[mode] then
                return returnList and hooking.ClosestEnemies or hooking.ClosestEnemies.Closest
            end
        end
        
        function hooking:SetTarget(rootPart, character, isEnemy)
            table.clear(self.ClosestEnemies)
            self.ClosestEnemies.Closest = rootPart
            Debounce.TargetDebounce = tick()
            
            if isEnemy then
                for _, enemy in ipairs(Module.Enemies:GetTagged(character.Name) or {}) do
                    if enemy ~= character and enemy:FindFirstChild("UpperTorso") then
                        table.insert(self.ClosestEnemies, enemy.UpperTorso)
                    end
                end
            end
        end
        
        function hooking.UpdateClosest()
            local smoothDelay = Settings.SmoothMode and 0.5 or 0.25
            
            if (tick() - Debounce.TargetDebounce) <= 2 or (tick() - Debounce.UpdateDebounce) <= smoothDelay then
                return
            end
            
            Debounce.UpdateDebounce = tick()
            local equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            
            if equipped and equipped.ToolTip then
                local closestEnemies = hooking.ClosestEnemies
                table.clear(closestEnemies)
                
                local playerPos = Player.Character:GetPivot().Position
                local playerList = Players:GetPlayers()
                local enemyList = Enemies:GetChildren()
                
                local distance = equipped.ToolTip == "Gun" and 120 or 900
                local closestDist = equipped.ToolTip == "Gun" and 120 or 60
                
                -- Check players
                for _, otherPlayer in ipairs(playerList) do
                    local char = otherPlayer.Character
                    if Player ~= otherPlayer and CheckPlayerAlly(otherPlayer) and IsAlive(char) then
                        local upper = char:FindFirstChild("UpperTorso")
                        if upper then
                            local mag = (upper.Position - playerPos).Magnitude
                            if mag <= closestDist then
                                table.insert(closestEnemies, upper)
                            end
                            if mag <= distance then
                                closestEnemies.Closest = upper
                                distance = mag
                            end
                        end
                    end
                end
                
                if Settings.NoAimMobs then return end
                
                -- Check enemies
                for _, enemy in ipairs(enemyList) do
                    local upper = enemy and enemy:FindFirstChild("UpperTorso")
                    if upper and IsAlive(enemy) then
                        local mag = (upper.Position - playerPos).Magnitude
                        if mag <= closestDist then
                            table.insert(closestEnemies, upper)
                        end
                        if mag <= distance then
                            distance, closestEnemies.Closest = mag, upper
                        end
                    end
                end
            end
        end
        
        task.defer(function()
            if _ENV.original_namecall then return end
            
            local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                if string.lower(getnamecallmethod()) ~= "fireserver" then
                    return oldNamecall(self, ...)
                end
                
                local name = self.Name
                
                if name == "RE/ShootGunEvent" then
                    local position, enemies = ...
                    
                    if typeof(position) == "Vector3" and type(enemies) == "table" then
                        local closestList = getNextTarget("AimBot_Gun", true)
                        
                        if closestList and #closestList > 0 then
                            for _, part in ipairs(closestList) do
                                if part and (not enemies[1] or (part.Position - enemies[1].Position).Magnitude <= 15) then
                                    table.insert(enemies, part)
                                end
                            end
                            return oldNamecall(self, enemies[1].Position, enemies)
                        end
                    end
                elseif name == "RemoteEvent" then
                    local arg1, arg2 = ...
                    if typeof(arg1) == "Vector3" and not arg2 then
                        local target = getNextTarget("AimBot_Skills")
                        if target then
                            return oldNamecall(self, target.Position)
                        end
                    elseif arg1 == "TAP" and typeof(arg2) == "Vector3" then
                        local target = getNextTarget("AimBot_Tap")
                        if target then
                            return oldNamecall(self, "TAP", target.Position)
                        end
                    end
                end
                
                return oldNamecall(self, ...)
            end)
            
            _ENV.original_namecall = oldNamecall
        end)
        
        table.insert(Connections, Heartbeat:Connect(hooking.UpdateClosest))
        
        return hooking
    end)()
    
    -- Initialize various systems
    task.defer(function()
        local deathEffect = require(WaitChilds(ReplicatedStorage, "Effect", "Container", "Death"))
        local cameraShaker = require(WaitChilds(ReplicatedStorage, "Util", "CameraShaker"))
        
        if cameraShaker then
            cameraShaker:Stop()
        end
        if hookfunction then
            hookfunction(deathEffect, function(...) return ... end)
        end
    end)
    
    task.spawn(function()
        local spawnLocations = Module.SpawnLocations
        local enemyLocations = Module.EnemyLocations
        
        local function onIslandAdded(island)
            if island.Name:find("Island") then
                Cached.RaidIsland = nil
            end
        end
        
        local function onSpawnAdded(part)
            local enemyName = GetEnemyName(part.Name)
            enemyLocations[enemyName] = enemyLocations[enemyName] or {}
            
            local spawnPos = part.CFrame + Vector3.new(0, 25, 0)
            spawnLocations[enemyName] = part
            
            if not table.find(enemyLocations[enemyName], spawnPos) then
                table.insert(enemyLocations[enemyName], spawnPos)
            end
        end
        
        for _, spawn in ipairs(EnemySpawns:GetChildren()) do
            onSpawnAdded(spawn)
        end
        
        table.insert(Connections, EnemySpawns.ChildAdded:Connect(onSpawnAdded))
        table.insert(Connections, Locations.ChildAdded:Connect(onIslandAdded))
    end)
end

-- Global helper functions
function EnableBuso()
    local character = Player.Character
    if Settings.AutoBuso and Module.IsAlive(character) and not character:FindFirstChild("HasBuso") then
        if character:HasTag("Buso") then
            Module.FireRemote("Buso")
        elseif Money.Value >= 25000 then
            Module.FireRemote("BuyHaki", "Buso")
        end
    end
end

function GetToolByName(name)
    local cached = Module.Cached.Tools[name]
    local backpack = Player:FindFirstChild("Backpack")
    
    if cached and (cached.Parent == Player.Character or cached.Parent == backpack) then
        return cached
    end
    
    if Module.IsAlive(Player.Character) then
        local tool = Player.Character:FindFirstChild(name) or (backpack and backpack:FindFirstChild(name))
        if tool then
            Module.Cached.Tools[name] = tool
            return tool
        end
    end
end

function GetToolMastery(name)
    local tool = GetToolByName(name)
    return tool and tool:GetAttribute("Level") or 0
end

function GetToolByTip(toolTip, folder)
    for _, tool in ipairs(folder:GetChildren()) do
        if tool:IsA("Tool") and tool.ToolTip == toolTip then
            Module.Cached.Tools["ToolTip_" .. toolTip] = tool
            return tool
        end
    end
end

function VerifyToolByTip(toolTip)
    local cached = Module.Cached.Tools["ToolTip_" .. toolTip]
    
    if cached and (cached.Parent == Player.Character or cached.Parent == Player.Backpack) then
        return cached
    end
    
    local character = Module.IsAlive(Player.Character) and Player.Character
    return GetToolByTip(toolTip, Player.Backpack) or (character and GetToolByTip(toolTip, character))
end

function VerifyTool(name)
    return GetToolByName(name) and true or false
end

return Module
