local Settings = ...

if type(Settings) ~= "table" then
  return nil
end

local _ENV = (getgenv or getrenv or getfenv)()

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator = Remotes:WaitForChild("Validator2")
local CommF = Remotes:WaitForChild("CommF_")
local CommE = Remotes:WaitForChild("CommE")

local ChestModels = workspace:WaitForChild("ChestModels")
local WorldOrigin = workspace:WaitForChild("_WorldOrigin")
local Characters = workspace:WaitForChild("Characters")
local SeaBeasts = workspace:WaitForChild("SeaBeasts")
local Enemies = workspace:WaitForChild("Enemies")
local Boats = workspace:WaitForChild("Boats")
local Map = workspace:WaitForChild("Map")

local EnemySpawns = WorldOrigin:WaitForChild("EnemySpawns")
local Locations = WorldOrigin:WaitForChild("Locations")

local RenderStepped = RunService.RenderStepped
local Heartbeat = RunService.Heartbeat
local Stepped = RunService.Stepped
local Player = Players.LocalPlayer

local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local BLACKLISTED_EXECUTORS = { "NULL" }

local EXECUTOR_NAME = identifyexecutor and string.upper(identifyexecutor()) or "NULL"
local IS_BLACKLISTED_EXECUTOR = false
for _, v in ipairs(BLACKLISTED_EXECUTORS) do
    if v == EXECUTOR_NAME then
        IS_BLACKLISTED_EXECUTOR = true
        break
    end
end

local hookmetamethod = (not IS_BLACKLISTED_EXECUTOR and hookmetamethod) or (function(...) return ... end)
local hookfunction = (not IS_BLACKLISTED_EXECUTOR and hookfunction) or (function(...) return ... end)
local sethiddenproperty = sethiddenproperty or (function(...) return ... end)
local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local BRING_TAG = _ENV._Bring_Tag or ("b" .. math.random(80, 20000) .. "t")
local KILLAURA_TAG = _ENV._KillAura_Tag or ("k" .. math.random(120, 20000) .. "t")

local HIDDEN_SETTINGS = {
    SKILL_COOLDOWN = 0.5,
    CLEAR_AFTER = 50
}

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local Connections = {}
if _ENV.rz_connections then
    for _, Connection in ipairs(_ENV.rz_connections) do
        Connection:Disconnect()
    end
end
_ENV.rz_connections = Connections

local function GetEnemyName(str)
    local s = str:gsub(" %pLv. %d+%p", ""):gsub(" %pBoss%p", "")
    return s
end

local function CheckPlayerAlly(__Player)
    if tostring(__Player.Team) == "Marines" and __Player.Team == Player.Team then
        return false
    end
    if __Player:HasTag("Ally" .. Player.Name) or Player:HasTag("Ally" .. __Player.Name) then
        return false
    end
    return true
end

local function WaitChilds(Instance, ...)
    local args = { ... }
    for _, ChildName in ipairs(args) do
        Instance = Instance:WaitForChild(ChildName)
    end
    return Instance
end

local function FastWait(Seconds, Instance, ...)
    local args = { ... }
    local Success, Result = pcall(function()
        for _, ChildName in ipairs(args) do
            Instance = Instance:WaitForChild(ChildName, Seconds)
        end
        return Instance
    end)
    if Success then
        return Result
    end
    return nil
end

local function CreateNewClear()
    local COUNT_NEWINDEX = 0
    return {
        __newindex = function(self, index, value)
            if COUNT_NEWINDEX >= HIDDEN_SETTINGS.CLEAR_AFTER then
                for key, cache in pairs(self) do
                    if typeof(cache) == "Instance" and not cache:IsDescendantOf(game) then
                        rawset(self, key, nil)
                    end
                end
                COUNT_NEWINDEX = 0
            end
            COUNT_NEWINDEX = COUNT_NEWINDEX + 1
            rawset(self, index, value)
        end
    }
end

function CreateDictionary(array, value)
    local Dictionary = {}
    for _, str in ipairs(array) do
        if type(value) == "table" then
            Dictionary[str] = {}
        else
            Dictionary[str] = value
        end
    end
    return Dictionary
end

local Signal = {}
do
    local Connection = {}
    Connection.__index = Connection
    function Connection:Disconnect()
        if not self.Connected then
            return
        end
        for i, v in ipairs(self.Signal.Connections) do
            if v == self then
                table.remove(self.Signal.Connections, i)
                break
            end
        end
        self.Function = nil
        self.Connected = false
    end
    function Connection:Fire(...)
        if self.Function then
            task.spawn(self.Function, ...)
        end
    end
    function Connection.new()
        return setmetatable({ Connected = true }, Connection)
    end

    Signal.__index = Signal
    function Signal:Connect(fn)
        if type(fn) ~= "function" then
            return nil
        end
        local NewConnection = Connection.new()
        NewConnection.Function = fn
        NewConnection.Signal = self
        table.insert(self.Connections, NewConnection)
        return NewConnection
    end
    function Signal:Once(fn)
        local conn
        conn = self:Connect(function(...)
            fn(...)
            conn:Disconnect()
        end)
        return conn
    end
    function Signal:Wait()
        local co = coroutine.running()
        local conn
        conn = self:Connect(function(...)
            conn:Disconnect()
            task.spawn(co, ...)
        end)
        return coroutine.yield()
    end
    function Signal:Fire(...)
        for _, conn in ipairs(self.Connections) do
            if conn.Connected then
                conn:Fire(...)
            end
        end
    end
    function Signal.new()
        return setmetatable({ Connections = {} }, Signal)
    end
end

local sea1 = { 2753915549, 85211729168715 }
local sea2 = { 4442272183, 79091703265657 }
local sea3 = { 7449423635, 100117331123089 }

local function detectSea(placeId)
    for _, v in ipairs(sea1) do
        if v == placeId then return 1 end
    end
    for _, v in ipairs(sea2) do
        if v == placeId then return 2 end
    end
    for _, v in ipairs(sea3) do
        if v == placeId then return 3 end
    end
    return 0
end

local Module = {}
do
    local Cached = {
        Closest = nil,
        Equipped = nil,
        Humanoids = setmetatable({}, CreateNewClear()),
        Enemies = {},
        Progress = {},
        Bring = {},
        Tools = {}
    }

    Module.GameData = {
        Sea = detectSea(game.PlaceId),
        SeasName = { "Main", "Dressrosa", "Zou" },
        MaxMastery = 600,
        MaxLevel = workspace:GetAttribute("LEVEL_CAP"),
        StringVersion = require(ReplicatedStorage.BuildInfo).VERSION
    }

    Module.Debounce = {
        TargetDebounce = 0,
        UpdateDebounce = 0,
        GetEnemy = 0,
        Skills = {}
    }

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

    Module.Bosses = {
        ["Saber Expert"] = { NoQuest = true, Position = CFrame.new(-1461, 30, -51) },
        ["The Saw"] = { RaidBoss = true, Position = CFrame.new(-690, 15, 1583) },
        ["Greybeard"] = { RaidBoss = true, Position = CFrame.new(-5043, 25, 4262) },
        ["The Gorilla King"] = { IsBoss = true, Level = 20, Position = CFrame.new(-1128, 6, -451), Quest = { "JungleQuest", CFrame.new(-1598, 37, 153) } },
        ["Bobby"] = { IsBoss = true, Level = 55, Position = CFrame.new(-1131, 14, 4080), Quest = { "BuggyQuest1", CFrame.new(-1140, 4, 3829) } },
        ["Yeti"] = { IsBoss = true, Level = 105, Position = CFrame.new(1185, 106, -1518), Quest = { "SnowQuest", CFrame.new(1385, 87, -1298) } },
        ["Vice Admiral"] = { IsBoss = true, Level = 130, Position = CFrame.new(-4807, 21, 4360), Quest = { "MarineQuest2", CFrame.new(-5035, 29, 4326), 2 } },
        ["Swan"] = { IsBoss = true, Level = 240, Position = CFrame.new(5230, 4, 749), Quest = { "ImpelQuest", CFrame.new(5191, 4, 692) } },
        ["Chief Warden"] = { IsBoss = true, Level = 230, Position = CFrame.new(5230, 4, 749), Quest = { "ImpelQuest", CFrame.new(5191, 4, 692), 2 } },
        ["Warden"] = { IsBoss = true, Level = 220, Position = CFrame.new(5230, 4, 749), Quest = { "ImpelQuest", CFrame.new(5191, 4, 692), 1 } },
        ["Magma Admiral"] = { IsBoss = true, Level = 350, Position = CFrame.new(-5694, 18, 8735), Quest = { "MagmaQuest", CFrame.new(-5319, 12, 8515) } },
        ["Fishman Lord"] = { IsBoss = true, Level = 425, Position = CFrame.new(61350, 31, 1095), Quest = { "FishmanQuest", CFrame.new(61122, 18, 1567) } },
        ["Wysper"] = { IsBoss = true, Level = 500, Position = CFrame.new(-7927, 5551, -637), Quest = { "SkyExp1Quest", CFrame.new(-7861, 5545, -381) } },
        ["Thunder God"] = { IsBoss = true, Level = 575, Position = CFrame.new(-7751, 5607, -2315), Quest = { "SkyExp2Quest", CFrame.new(-7903, 5636, -1412) } },
        ["Cyborg"] = { IsBoss = true, Level = 675, Position = CFrame.new(6138, 10, 3939), Quest = { "FountainQuest", CFrame.new(5258, 39, 4052) } },
        ["Don Swan"] = { RaidBoss = true, Position = CFrame.new(2289, 15, 808) },
        ["Cursed Captain"] = { RaidBoss = true, Position = CFrame.new(912, 186, 33591) },
        ["Darkbeard"] = { RaidBoss = true, Position = CFrame.new(3695, 13, -3599) },
        ["Diamond"] = { IsBoss = true, Level = 750, Position = CFrame.new(-1569, 199, -31), Quest = { "Area1Quest", CFrame.new(-427, 73, 1835) } },
        ["Jeremy"] = { IsBoss = true, Level = 850, Position = CFrame.new(2316, 449, 787), Quest = { "Area2Quest", CFrame.new(635, 73, 919) } },
        ["Orbitus"] = { IsBoss = true, Level = 925, Position = CFrame.new(-2086, 73, -4208), Quest = { "MarineQuest3", CFrame.new(-2441, 73, -3219) } },
        ["Smoke Admiral"] = { IsBoss = true, Level = 1150, Position = CFrame.new(-5078, 24, -5352), Quest = { "IceSideQuest", CFrame.new(-6061, 16, -4904) } },
        ["Awakened Ice Admiral"] = { IsBoss = true, Level = 1400, Position = CFrame.new(6473, 297, -6944), Quest = { "FrostQuest", CFrame.new(5668, 28, -6484) } },
        ["Tide Keeper"] = { IsBoss = true, Level = 1475, Position = CFrame.new(-3711, 77, -11469), Quest = { "ForgottenQuest", CFrame.new(-3056, 240, -10145) } },
        ["Tyrant of the Skies"] = { RaidBoss = true, Position = CFrame.new(-16252, 153, 1394) },
        ["Cake Prince"] = { RaidBoss = true, Position = CFrame.new(-2103, 70, -12165) },
        ["Dough King"] = { RaidBoss = true, Position = CFrame.new(-2103, 70, -12165) },
        ["rip_indra True Form"] = { RaidBoss = true, Position = CFrame.new(-5333, 424, -2673) },
        ["Stone"] = { IsBoss = true, Level = 1550, Position = CFrame.new(-1049, 40, 6791), Quest = { "PiratePortQuest", CFrame.new(-449, 109, 5950) } },
        ["Hydra Leader"] = { IsBoss = true, Level = 1675, Position = CFrame.new(5836, 1019, -83), Quest = { "VenomCrewQuest", CFrame.new(5214, 1004, 761) } },
        ["Kilo Admiral"] = { IsBoss = true, Level = 1750, Position = CFrame.new(2904, 509, -7349), Quest = { "MarineTreeIsland", CFrame.new(2485, 74, -6788) } },
        ["Captain Elephant"] = { IsBoss = true, Level = 1875, Position = CFrame.new(-13393, 319, -8423), Quest = { "DeepForestIsland", CFrame.new(-13233, 332, -7626) } },
        ["Beautiful Pirate"] = { IsBoss = true, Level = 1950, Position = CFrame.new(5370, 22, -89), Quest = { "DeepForestIsland2", CFrame.new(-12682, 391, -9901) } },
        ["Cake Queen"] = { IsBoss = true, Level = 2175, Position = CFrame.new(-710, 382, -11150), Quest = { "IceCreamIslandQuest", CFrame.new(-818, 66, -10964) } },
        ["Longma"] = { NoQuest = true, Position = CFrame.new(-10218, 333, -9444) }
    }

    Module.Shop = {
        { "Frags", { { "Race Reroll", { "BlackbeardReward", "Reroll", "2" } }, { "Reset Stats", { "BlackbeardReward", "Refund", "2" } } } },
        { "Ability Teacher", {
            { "Buy Geppo", { "BuyHaki", "Geppo" } },
            { "Buy Buso", { "BuyHaki", "Buso" } },
            { "Buy Soru", { "BuyHaki", "Soru" } },
            { "Buy Ken", { "KenTalk", "Buy" } }
        } },
        { "Sword", {
            { "Buy Katana", { "BuyItem", "Katana" } },
            { "Buy Cutlass", { "BuyItem", "Cutlass" } },
            { "Buy Dual Katana", { "BuyItem", "Dual Katana" } },
            { "Buy Iron Mace", { "BuyItem", "Iron Mace" } },
            { "Buy Triple Katana", { "BuyItem", "Triple Katana" } },
            { "Buy Pipe", { "BuyItem", "Pipe" } },
            { "Buy Dual-Headed Blade", { "BuyItem", "Dual-Headed Blade" } },
            { "Buy Soul Cane", { "BuyItem", "Soul Cane" } },
            { "Buy Bisento", { "BuyItem", "Bisento" } }
        } },
        { "Gun", {
            { "Buy Musket", { "BuyItem", "Musket" } },
            { "Buy Slingshot", { "BuyItem", "Slingshot" } },
            { "Buy Flintlock", { "BuyItem", "Flintlock" } },
            { "Buy Refined Slingshot", { "BuyItem", "Refined Slingshot" } },
            { "Buy Dual Flintlock", { "BuyItem", "Dual Flintlock" } },
            { "Buy Cannon", { "BuyItem", "Cannon" } },
            { "Buy Kabucha", { "BlackbeardReward", "Slingshot", "2" } }
        } },
        { "Accessories", {
            { "Buy Black Cape", { "BuyItem", "Black Cape" } },
            { "Buy Swordsman Hat", { "BuyItem", "Swordsman Hat" } },
            { "Buy Tomoe Ring", { "BuyItem", "Tomoe Ring" } },
            { "Buy Ghoul Mask", { "Ectoplasm", "Buy", 2 } }
        } },
        { "Race", { { "Ghoul Race", { "Ectoplasm", "Change", 4 } }, { "Cyborg Race", { "CyborgTrainer", "Buy" } } } }
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
    Module.Cached = Cached

    Module.Signals = {}
    do
        local Signals = Module.Signals
        Signals.PossibleStaff = Signal.new()
        Signals.OptionChanged = Signal.new()
        Signals.EnemyAdded = Signal.new()
        Signals.EnemyDied = Signal.new()
        Signals.Notify = Signal.new()
        Signals.Error = Signal.new()

        Signals.Error:Connect(function(ErrorMessage)
            _ENV.loadedFarm = false
            _ENV.OnFarm = false
            local Message = Instance.new("Message", workspace)
            _ENV.redz_hub_error = Message
            Message.Text = ("OMG-Hub error [ " .. (Settings.RunningOption or "Null") .. " ] " .. tostring(ErrorMessage))
        end)
    end

    Module.RunFunctions = {}
    do
        function Module.RunFunctions.Translator(Window, Translation)
            local MakeTab = Window.MakeTab
            Window.MakeTab = function(self, Configs)
                if Translation[Configs[1]] then
                    Configs[1] = Translation[Configs[1]]
                end
                local Tab = MakeTab(self, Configs)
                local NewTab = {}
                function NewTab:AddSection(Name)
                    return Tab:AddSection(Translation[Name] or Name)
                end
                function NewTab:AddButton(Configs)
                    local Translator = Translation[Configs[1]]
                    if Translator then
                        if type(Translator) == "string" then
                            Configs[1] = Translator
                        else
                            Configs[1] = Translator[1]
                            Configs.Desc = Translator[2]
                        end
                    end
                    return Tab:AddButton(Configs)
                end
                function NewTab:AddToggle(Configs)
                    local Translator = Translation[Configs[1]]
                    if Translator then
                        if type(Translator) == "string" then
                            Configs[1] = Translator
                        else
                            Configs[1] = Translator[1]
                            Configs.Desc = Translator[2]
                        end
                    end
                    return Tab:AddToggle(Configs)
                end
                function NewTab:AddSlider(Configs)
                    local Translator = Translation[Configs[1]]
                    if Translator then
                        if type(Translator) == "string" then
                            Configs[1] = Translator
                        else
                            Configs[1] = Translator[1]
                            Configs.Desc = Translator[2]
                        end
                    end
                    return Tab:AddSlider(Configs)
                end
                function NewTab:AddDropdown(Configs)
                    local Translator = Translation[Configs[1]]
                    if Translator then
                        if type(Translator) == "string" then
                            Configs[1] = Translator
                        else
                            Configs[1] = Translator[1]
                            Configs.Desc = Translator[2]
                        end
                    end
                    return Tab:AddDropdown(Configs)
                end
                function NewTab:AddTextBox(Configs)
                    local Translator = Translation[Configs[1]]
                    if Translator then
                        if type(Translator) == "string" then
                            Configs[1] = Translator
                        else
                            Configs[1] = Translator[1]
                            Configs.Desc = Translator[2]
                        end
                    end
                    return Tab:AddTextBox(Configs)
                end
                for k, v in pairs(Tab) do
                    if NewTab[k] == nil then
                        NewTab[k] = v
                    end
                end
                return NewTab
            end
        end

        function Module.RunFunctions.Quests(self, QuestsModule, getTasks)
            local MaxLvl
            if self.Sea == 1 then
                MaxLvl = { 0, 700 }
            elseif self.Sea == 2 then
                MaxLvl = { 700, 1500 }
            else
                MaxLvl = { 1500, math.huge }
            end
            local bl_Quests = { "BartiloQuest", "MarineQuest", "CitizenQuest" }
            for name, task in pairs(QuestsModule) do
                local blocked = false
                for _, bn in ipairs(bl_Quests) do
                    if bn == name then
                        blocked = true
                        break
                    end
                end
                if blocked then
                    goto continue
                end
                for num, mission in pairs(task) do
                    local Level = mission.LevelReq
                    if Level >= MaxLvl[1] and Level < MaxLvl[2] then
                        local target, positions = getTasks(mission)
                        table.insert(self.QuestList, {
                            Name = name,
                            Count = num,
                            Enemy = { Name = target, Level = Level, Position = positions }
                        })
                    end
                end
                ::continue::
            end
            table.sort(self.QuestList, function(v1, v2) return v1.Enemy.Level < v2.Enemy.Level end)
        end

        function Module.RunFunctions.LibraryToggle(EnabledOptions, Options)
            return function(...)
                local Tab, Settings, Flag = ...
                Options[Flag] = Tab:AddToggle({
                    Settings[1],
                    type(Settings[2]) ~= "string" and Settings[2],
                    function(Value) EnabledOptions[Flag] = Value end,
                    Flag,
                    Desc = (type(Settings[2]) == "string" and Settings[2]) or Settings[3]
                })
            end
        end

        function Module.RunFunctions.FarmQueue(Options)
            local Success, ErrorMessage = pcall(function()
                while task.wait(Settings.SmoothMode and 0.25 or 0) do
                    local Enabled = false
                    for _, Option in ipairs(Options) do
                        Settings.RunningOption = Option.Name
                        local Method = Option.Function()
                        if Method then
                            Settings.RunningMethod = type(Method) == "string" and Method
                            Enabled = true
                            break
                        else
                            Settings.RunningOption = nil
                            Settings.RunningMethod = nil
                        end
                    end
                    _ENV.OnFarm = (_ENV.teleporting or Enabled)
                end
            end)
            if not Success then
                Module.Signals.Error:Fire(ErrorMessage)
            end
        end
    end

    function Module.FireRemote(...)
        return CommF:InvokeServer(...)
    end

    function Module.IsAlive(Character)
        if not Character then
            return false
        end
        local Humanoids = Cached.Humanoids
        local Humanoid = Humanoids[Character]
        if not Humanoid then
            Humanoid = Character:FindFirstChild("Humanoid")
            if not Humanoid and Character.Parent == Boats then
                return true
            elseif Character.Parent == SeaBeasts then
                Humanoid = Character:FindFirstChild("Health")
            end
        end
        if Humanoid then
            if not Humanoids[Character] then
                Humanoids[Character] = Humanoid
            end
            if Humanoid.ClassName == "Humanoid" then
                return Humanoid.Health > 0
            else
                return Humanoid.Value > 0
            end
        end
        return false
    end

    function Module.KillAura(Distance, Name)
        Distance = Distance or 500
        local EnemyList = Enemies:GetChildren()
        for i = 1, #EnemyList do
            local Enemy = EnemyList[i]
            local PrimaryPart = Enemy.PrimaryPart
            if (not Name or Enemy.Name == Name) and PrimaryPart and not Enemy:HasTag(KILLAURA_TAG) then
                if Module.IsAlive(Enemy) and Player:DistanceFromCharacter(PrimaryPart.Position) < Distance then
                    Enemy:AddTag(KILLAURA_TAG)
                end
            end
        end
    end

    function Module.IsBoss(Name)
        return Module.Bosses[Name] ~= nil
    end

    function Module.Rejoin()
        task.spawn(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, Player)
    end

    function Module:ServerHop()
        local PlaceID = game.PlaceId
        local AllIDs = {}
        local foundAnything = ""
        local actualHour = os.date("!*t").hour
        local function TPReturner()
            local Site
            if foundAnything == "" then
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
            else
                Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
            end
            if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
                foundAnything = Site.nextPageCursor
            end
            local num = 0
            for _, v in pairs(Site.data) do
                local Possible = true
                local ID = tostring(v.id)
                if tonumber(v.maxPlayers) > tonumber(v.playing) then
                    for _, Existing in pairs(AllIDs) do
                        if num ~= 0 then
                            if ID == tostring(Existing) then
                                Possible = false
                                break
                            end
                        else
                            if tonumber(actualHour) ~= tonumber(Existing) then
                                pcall(function()
                                    AllIDs = {}
                                    table.insert(AllIDs, actualHour)
                                end)
                            end
                        end
                        num = num + 1
                    end
                    if Possible then
                        table.insert(AllIDs, ID)
                        wait()
                        pcall(function()
                            wait()
                            game:GetService("ReplicatedStorage").__ServerBrowser:InvokeServer("teleport", ID)
                        end)
                        wait(4)
                    end
                end
            end
        end
        local function TeleportLoop()
            while wait() do
                pcall(function()
                    TPReturner()
                    if foundAnything ~= "" then
                        TPReturner()
                    end
                end)
            end
        end
        TeleportLoop()
    end

    function Module.EnemySpawned(EnemyName)
        local Enemies = Module.Enemies
        if type(EnemyName) == "table" then
            return Enemies:GetClosest(EnemyName)
        else
            return Enemies:GetEnemyByTag(EnemyName)
        end
    end

    function Module:IsBlacklistedExecutor()
        return IS_BLACKLISTED_EXECUTOR
    end

    function Module:TravelTo(Sea)
        Module.FireRemote("Travel" .. self.GameData.SeasName[Sea])
    end

    function Module.EquipTool(ToolName, ByType)
        if not ToolName then
            ByType = true
            ToolName = Settings.FarmTool
        end
        if not Module.IsAlive(Player.Character) then
            return
        end
        local Equipped = Cached.Equipped
        local key
        if ByType then
            key = "ToolTip"
        else
            key = "Name"
        end
        if Equipped and Equipped.Parent and Equipped[key] == ToolName then
            if Equipped:GetAttribute("Locks") then
                Equipped:SetAttribute("Locks", nil)
            end
            if Equipped.Parent == Player.Backpack then
                Player.Character.Humanoid:EquipTool(Equipped)
            elseif Equipped.Parent == Player.Character then
                return
            end
        end
        if ToolName and not ByType then
            local BackpackTool = Player.Backpack:FindFirstChild(ToolName)
            if BackpackTool then
                Cached.Equipped = BackpackTool
                Player.Character.Humanoid:EquipTool(BackpackTool)
            end
        else
            for _, Tool in ipairs(Player.Backpack:GetChildren()) do
                if Tool:IsA("Tool") and Tool.ToolTip == ToolName then
                    Cached.Equipped = Tool
                    Player.Character.Humanoid:EquipTool(Tool)
                    return
                end
            end
        end
    end

    function Module:BringEnemies(ToEnemy, SuperBring)
        if not self.IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
            return
        end
        if Settings.BringMobs then
            Module.IsSuperBring = SuperBring and true or false
            local Name = ToEnemy.Name
            local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local Target = ToEnemy.PrimaryPart.CFrame
            local BringPositionTag
            if SuperBring then
                BringPositionTag = "ALL_MOBS"
            else
                BringPositionTag = Name
            end
            if not Cached.Bring[BringPositionTag] or (Target.Position - Cached.Bring[BringPositionTag].Position).Magnitude > 25 then
                Cached.Bring[BringPositionTag] = Target
            end
            local EnemyList
            if not SuperBring then
                EnemyList = self.Enemies:GetTagged(Name)
            else
                EnemyList = Enemies:GetChildren()
            end
            if EnemyList then
                for i = 1, #EnemyList do
                    local Enemy = EnemyList[i]
                    if Enemy.Parent ~= Enemies or Enemy:HasTag(BRING_TAG) then
                        goto continue
                    end
                    if not Enemy:FindFirstChild("CharacterReady") then
                        goto continue
                    end
                    local PrimaryPart = Enemy.PrimaryPart
                    if self.IsAlive(Enemy) and PrimaryPart then
                        if (Position - PrimaryPart.Position).Magnitude < Settings.BringDistance then
                            Enemy:AddTag(BRING_TAG)
                        end
                    end
                    ::continue::
                end
            end
        else
            if not Cached.Bring[ToEnemy] then
                Cached.Bring[ToEnemy] = ToEnemy.PrimaryPart.CFrame
            end
            ToEnemy.PrimaryPart.CFrame = Cached.Bring[ToEnemy]
        end
    end

    function Module:GetRaidIsland()
        if Cached.RaidIsland and Cached.RaidIsland:IsDescendantOf(Locations) then
            return Cached.RaidIsland
        end
        for i = 5, 1, -1 do
            local Name = "Island " .. i
            for _, Island in ipairs(Locations:GetChildren()) do
                if Island.Name == Name and Player:DistanceFromCharacter(Island.Position) < 3500 then
                    Cached.RaidIsland = Island
                    return Island
                end
            end
        end
    end

    function Module:GetProgress(Tag, ...)
        local Progress = Cached.Progress
        local entry = Progress[Tag]
        if entry and (tick() - entry.debounce) < 2 then
            return entry.result
        end
        local result = self.FireRemote(...)
        if entry then
            entry.result = result
            entry.debounce = tick()
        else
            Progress[Tag] = { debounce = tick(), result = result }
        end
        return result
    end

    function Module:RemoveVolcanoLava()
        local PrehistoricIsland = Map.PrehistoricIsland
        if PrehistoricIsland then
            local core = PrehistoricIsland:FindFirstChild("Core")
            if core then
                local interior = core:FindFirstChild("InteriorLava")
                if interior then
                    interior:Destroy()
                end
            end
            for _, Instance in ipairs(PrehistoricIsland:GetDescendants()) do
                if Instance:IsA("BasePart") and string.find(string.lower(Instance.Name), "lava") then
                    Instance:Destroy()
                end
            end
        end
    end

    function Module:RemoveBoatCollision(Boat)
        for _, obj in ipairs(Boat:GetDescendants()) do
            if obj:IsA("BasePart") and obj.CanCollide then
                obj.CanCollide = false
            end
        end
    end

    Module.Chests = setmetatable({}, {
        __call = function(self, SelectedIsland)
            local CachedChest = self.Cached
            if CachedChest and not CachedChest:GetAttribute("IsDisabled") then
                if not SelectedIsland or CachedChest:IsDescendantOf(SelectedIsland) then
                    return CachedChest
                end
            end
            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end
            local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local Chests = CollectionService:GetTagged("_ChestTagged")
            local Distance = math.huge
            local Nearest = nil
            for i = 1, #Chests do
                local Chest = Chests[i]
                local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
                if not SelectedIsland or Chest:IsDescendantOf(SelectedIsland) then
                    if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
                        Distance = Magnitude
                        Nearest = Chest
                    end
                end
            end
            self.Debounce = tick()
            self.Cached = Nearest
            return Nearest
        end
    })

    Module.Berry = setmetatable({}, {
        __call = function(self, BerryArray)
            local CachedBush = self.Cached
            if CachedBush and CachedBush:IsDescendantOf(Map) then
                return CachedBush
            end
            if self.Debounce and (tick() - self.Debounce) < 0.5 then
                return nil
            end
            local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
            local BerryBush = CollectionService:GetTagged("BerryBush")
            local Distance = math.huge
            local Nearest = nil
            for i = 1, #BerryBush do
                local Bush = BerryBush[i]
                for AttributeName, BerryName in pairs(Bush:GetAttributes()) do
                    if not BerryArray then
                        -- accept any
                    else
                        local found = false
                        for _, b in ipairs(BerryArray) do
                            if b == BerryName then
                                found = true
                                break
                            end
                        end
                        if not found then
                            goto continue
                        end
                    end
                    local Magnitude = (Bush.Parent:GetPivot().Position - Position).Magnitude
                    if Magnitude < Distance then
                        Distance = Magnitude
                        Nearest = Bush
                    end
                    ::continue::
                end
            end
            self.Debounce = tick()
            self.Cached = Nearest
            return Nearest
        end
    })

    Module.FruitsName = setmetatable({}, {
        __index = function(self, Fruit)
            local RealFruitsName = Module.FruitsId
            local Name = Fruit.Name
            if Name ~= "Fruit " then
                rawset(self, Fruit, Name)
                return Name
            end
            rawset(self, Fruit, "Fruit [ ??? ]")
            local Model = Fruit:WaitForChild("Fruit", 9e9)
            local Idle = FastWait(2, Model, "Idle") or FastWait(1, Model, "Animation") or FastWait(1, Model, "Fruit")
            if Idle then
                local Property
                if Idle:IsA("MeshPart") then
                    Property = Idle.MeshId
                elseif Idle:IsA("Animation") then
                    Property = Idle.AnimationId
                else
                    Property = ""
                end
                local RealName = RealFruitsName[Property]
                if RealName and type(RealName) == "string" then
                    rawset(self, Fruit, "Fruit [ " .. RealName .. " ]")
                end
            end
            return rawget(self, Fruit)
        end
    })

    Module.Enemies = (function()
        local EnemiesModule = CreateDictionary({ "__CakePrince", "__PirateRaid", "__RaidBoss", "__TyrantSkies", "__Bones", "__Elite", "__Others" }, {})
        local Signals = Module.Signals
        local IsAlive = Module.IsAlive
        local SeaCastle = CFrame.new(-5556, 314, -2988)
        local TagsMobs = {
            __Elite = CreateDictionary({ "Deandre", "Diablo", "Urban" }, true),
            __Bones = CreateDictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }, true),
            __CakePrince = CreateDictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" }, true),
            __TyrantSkies = CreateDictionary({ "Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter" }, true)
        }
        local Attachment = Instance.new("Attachment")
        do
            local AlignPosition = Instance.new("AlignPosition")
            AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
            AlignPosition.Position = Vector3.new(0, 20, 0)
            AlignPosition.Responsiveness = 200
            AlignPosition.MaxForce = math.huge
            AlignPosition.Parent = Attachment
            AlignPosition.Attachment0 = Attachment
        end

        local function New(list, NewEnemy)
            for _, v in ipairs(list) do
                if v == NewEnemy then
                    return
                end
            end
            local Humanoid = NewEnemy:WaitForChild("Humanoid")
            if Humanoid and Humanoid.ClassName == "Humanoid" and Humanoid.Health > 0 then
                table.insert(list, NewEnemy)
                Humanoid.Died:Wait()
                for i, v in ipairs(list) do
                    if v == NewEnemy then
                        table.remove(list, i)
                        break
                    end
                end
            end
        end

        local function IsFromPiratesSea(Enemy)
            if not Enemy:FindFirstChild("Humanoid") or Enemy.Humanoid.Health <= 0 then
                return
            end
            local HumanoidRootPart = Enemy:FindFirstChild("HumanoidRootPart")
            if HumanoidRootPart and Enemy.Name ~= "rip_indra True Form" and Enemy.Name ~= "Blank Buddy" then
                if (HumanoidRootPart.Position - SeaCastle.Position).Magnitude <= 750 then
                    task.spawn(New, EnemiesModule.__PirateRaid, Enemy)
                    Module.PirateRaid = tick()
                end
            end
        end

        local function NewEnemyAdded(Enemy)
            local EnemyName = Enemy.Name
            local Others = EnemiesModule.__Others
            if not Others[EnemyName] then
                Others[EnemyName] = {}
            end
            task.spawn(New, Others[EnemyName], Enemy)
            if Module.GameData.Sea == 3 then
                task.spawn(IsFromPiratesSea, Enemy)
            end
            if Enemy:GetAttribute("RaidBoss") then
                task.spawn(New, EnemiesModule.__RaidBoss, Enemy)
            elseif EnemiesModule["__" .. EnemyName] then
                task.spawn(New, EnemiesModule["__" .. EnemyName], Enemy)
            else
                for Tag, Mobs in pairs(TagsMobs) do
                    if Mobs[EnemyName] then
                        task.spawn(New, EnemiesModule[Tag], Enemy)
                        break
                    end
                end
            end
        end

        function EnemiesModule.IsSpawned(EnemyName)
            local CachedLoc = Module.SpawnLocations[EnemyName]
            if CachedLoc and CachedLoc.Parent then
                if CachedLoc:GetAttribute("Active") then
                    return true
                end
                if EnemiesModule:GetEnemyByTag(EnemyName) then
                    return true
                end
                return false
            end
            return EnemiesModule:GetEnemyByTag(EnemyName) ~= nil
        end

        function EnemiesModule:GetTagged(TagName)
            return self["__" .. TagName] or self.__Others[TagName]
        end

        function EnemiesModule:GetEnemyByTag(TagName)
            local CachedEnemy = Cached.Enemies[TagName]
            if CachedEnemy and IsAlive(CachedEnemy) then
                return CachedEnemy
            end
            local Enemies = self:GetTagged(TagName)
            if Enemies then
                for i = 1, #Enemies do
                    local Enemy = Enemies[i]
                    if IsAlive(Enemy) then
                        Cached.Enemies[TagName] = Enemy
                        return Enemy
                    end
                end
            end
        end

        function EnemiesModule:GetClosest(EnemiesArray)
            local SpecialTag = table.concat(EnemiesArray, ".")
            local CachedEnemy = Cached.Enemies[SpecialTag]
            if CachedEnemy and IsAlive(CachedEnemy) then
                return CachedEnemy
            end
            local Distance = math.huge
            local Nearest = nil
            for i = 1, #EnemiesArray do
                local Enemy = self:GetClosestByTag(EnemiesArray[i])
                if Enemy and Enemy.PrimaryPart then
                    local Magnitude = Player:DistanceFromCharacter(Enemy.PrimaryPart.Position)
                    if Magnitude < Distance then
                        Distance = Magnitude
                        Nearest = Enemy
                    end
                end
            end
            if Nearest then
                Cached.Enemies[SpecialTag] = Nearest
            end
            return Nearest
        end

        function EnemiesModule:GetClosestByTag(TagName)
            local CachedEnemy = Cached.Enemies[TagName]
            if CachedEnemy and IsAlive(CachedEnemy) then
                return CachedEnemy
            end
            local Enemies = self:GetTagged(TagName)
            if Enemies then
                local Distance = math.huge
                local Nearest = nil
                local Position = (Player.Character or Player.CharacterAdded()):GetPivot().Position
                for i = 1, #Enemies do
                    local Enemy = Enemies[i]
                    local PrimaryPart = Enemy.PrimaryPart
                    if PrimaryPart and IsAlive(Enemy) then
                        local Magnitude = (Position - PrimaryPart.Position).Magnitude
                        if Magnitude <= 15 then
                            Cached.Enemies[TagName] = Enemy
                            return Enemy
                        elseif Magnitude < Distance then
                            Distance = Magnitude
                            Nearest = Enemy
                        end
                    end
                end
                if Nearest then
                    Cached.Enemies[TagName] = Nearest
                    return Nearest
                end
            end
        end

        function EnemiesModule:CreateNewTag(Tag, EnemiesArray)
            local NewTag = {}
            self["__" .. Tag] = NewTag
            for i = 1, #EnemiesArray do
                self["__" .. EnemiesArray[i]] = NewTag
                local Others = self.__Others[EnemiesArray[i]]
                if Others then
                    for j = 1, #Others do
                        task.spawn(New, NewTag, Others[j])
                    end
                end
            end
            return NewTag
        end

        local function Bring(Enemy)
            local PlayerRootPart = (Player.Character or Player.CharacterAdded()):WaitForChild("HumanoidRootPart")
            local RootPart = Enemy:WaitForChild("HumanoidRootPart")
            local Humanoid = Enemy:WaitForChild("Humanoid")
            local EnemyName = Enemy.Name
            sethiddenproperty(Player, "SimulationRadius", math.huge)

            local BodyVelocity = Instance.new("BodyVelocity", RootPart)
            BodyVelocity.Velocity = Vector3.zero
            BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

            local BodyPosition = Instance.new("BodyPosition", RootPart)
            BodyPosition.Position = RootPart.Position
            BodyPosition.P, BodyPosition.D = 3e4, 3e3
            BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

            while PlayerRootPart and RootPart and Humanoid and Humanoid.Health > 0 and Enemy and Enemy.Parent == Enemies and Enemy:HasTag(BRING_TAG) do
                local Target
                if Module.IsSuperBring then
                    Target = Cached.Bring["ALL_MOBS"]
                else
                    Target = Cached.Bring[EnemyName]
                end
                if Target and (PlayerRootPart.Position - RootPart.Position).Magnitude <= Settings.BringDistance then
                    if (RootPart.Position - Target.Position).Magnitude <= 70 then
                        RootPart.CFrame = Target
                    else
                        RootPart.CanCollide = false
                        BodyPosition.Position = Target.Position
                    end
                end
                task.wait()
            end
            if Enemy and Enemy:HasTag(BRING_TAG) then
                Enemy:RemoveTag(BRING_TAG)
            end
        end

        local function KillAura(Enemy)
            local Humanoid = Enemy:FindFirstChild("Humanoid")
            local RootPart = Enemy:FindFirstChild("HumanoidRootPart")
            pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
            if Humanoid and RootPart then
                RootPart.CanCollide = false
                RootPart.Size = Vector3.new(60, 60, 60)
                Humanoid:ChangeState(15)
                Humanoid.Health = 0
                task.wait()
                Enemy:RemoveTag(KILLAURA_TAG)
            end
        end

        for _, Enemy in ipairs(CollectionService:GetTagged("BasicMob")) do
            NewEnemyAdded(Enemy)
        end
        for _, Enemy in ipairs(Enemies:GetChildren()) do
            NewEnemyAdded(Enemy)
        end

        table.insert(Connections, CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(NewEnemyAdded))
        table.insert(Connections, Enemies.ChildAdded:Connect(NewEnemyAdded))
        table.insert(Connections, CollectionService:GetInstanceAddedSignal(KILLAURA_TAG):Connect(KillAura))
        table.insert(Connections, CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(Bring))

        return EnemiesModule
    end)()

    Module.Inventory = (function()
        local Inventory = {
            Unlocked = setmetatable({}, { __index = function() return false end }),
            Mastery = setmetatable({}, { __index = function() return 0 end }),
            Count = setmetatable({}, { __index = function() return 0 end }),
            MasteryRequirements = {},
            Items = {},
        }

        function Inventory:UpdateItem(item)
            if type(item) == "table" then
                if item.Type == "Wear" then
                    item.Type = "Accessory"
                end
                local Name = item.Name
                self.Items[Name] = item
                self.Unlocked[Name] = true
                if item.Count then
                    self.Count[Name] = item.Count
                end
                if item.Mastery then
                    self.Mastery[Name] = item.Mastery
                end
                if item.MasteryRequirements then
                    self.MasteryRequirements[Name] = item.MasteryRequirements
                end
            end
        end

        function Inventory:RemoveItem(ItemName)
            if type(ItemName) == "string" then
                self.Unlocked[ItemName] = nil
                self.Mastery[ItemName] = nil
                self.Count[ItemName] = nil
                self.Items[ItemName] = nil
            end
        end

        local function OnClientEvent(Method, ...)
            if Method == "ItemChanged" then
                Inventory:UpdateItem(...)
            elseif Method == "ItemAdded" then
                Inventory:UpdateItem(...)
            elseif Method == "ItemRemoved" then
                Inventory:RemoveItem(...)
            elseif Method == "Notify" then
                Module.Signals.Notify:Fire(...)
            end
        end

        task.spawn(function()
            table.insert(Connections, CommE.OnClientEvent:Connect(OnClientEvent))
            for _, item in ipairs(Module.FireRemote("getInventory")) do
                Inventory:UpdateItem(item)
            end
        end)

        return Inventory
    end)()

    Module.FastAttack = (function()
        local FastAttack = {
            Distance = 50,
            attackMobs = true,
            attackPlayers = true,
            Equipped = nil,
            Debounce = 0,
            ComboDebounce = 0,
            ShootDebounce = 0,
            M1Combo = 0,
            Overheat = { ["Dragonstorm"] = { MaxOverheat = 3, Cooldown = 0, TotalOverheat = 0, Distance = 400, Shooting = false } },
            ShootsPerTarget = { ["Dual Flintlock"] = 2 },
            SpecialShoots = { ["Skull Guitar"] = "TAP", ["Bazooka"] = "Position", ["Cannon"] = "Position", ["Dragonstorm"] = "Overheat" },
            HitboxLimbs = { "RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand" }
        }

        local RE_RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
        local RE_ShootGunEvent = Net:WaitForChild("RE/ShootGunEvent")
        local RE_RegisterHit = Net:WaitForChild("RE/RegisterHit")
        local Events = ReplicatedStorage:WaitForChild("Events")

        local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
            return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
        end)
        local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
            return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
        end)
        local HIT_FUNCTION
        task.defer(function()
            if getsenv then
                HIT_FUNCTION = (getmenv or getsenv)(Net)._G.SendHitsToServer
            end
        end)

        local IsAlive = Module.IsAlive

        FastAttack.ShootsFunctions = {
            ["Skull Guitar"] = function(self, Equipped, Position)
                Equipped.RemoteEvent:FireServer("TAP", Position)
            end
        }

        local function ExpandsHitBox(Enemies)
            for i = 1, #Enemies do
                Enemies[i][2].Size = Vector3.one * 50
                Enemies[i][2].Transparency = 1
            end
        end

        function FastAttack:ShootInTarget(TargetPosition)
            local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip == "Gun" then
                if Equipped:FindFirstChild("Cooldown") and (tick() - self.ShootDebounce) >= Equipped.Cooldown.Value then
                    if self.ShootsFunctions[Equipped.Name] then
                        return self.ShootsFunctions[Equipped.Name](self, Equipped, TargetPosition)
                    end
                    if SUCCESS_SHOOT and SHOOT_FUNCTION then
                        local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
                        if ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
                            local attr = Equipped:GetAttribute("LocalTotalShots") or 0
                            Equipped:SetAttribute("LocalTotalShots", attr + 1)
                            GunValidator:FireServer(self:GetValidator2())
                            if ShootType == "TAP" then
                                Equipped.RemoteEvent:FireServer("TAP", TargetPosition)
                            else
                                RE_ShootGunEvent:FireServer(TargetPosition)
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

        function FastAttack:CheckStun(ToolTip, Character, Humanoid)
            local Stun = Character:FindFirstChild("Stun")
            local Busy = Character:FindFirstChild("Busy")
            if Humanoid.Sit and (ToolTip == "Sword" or ToolTip == "Melee" or ToolTip == "Gun") then
                return false
            end
            return true
        end

        function FastAttack:Process(assert, EnemiesFolder, BladeHits, Position, Distance)
            if not assert then
                return
            end
            local HitboxLimbs = self.HitboxLimbs
            local Mobs = EnemiesFolder:GetChildren()
            for i = 1, #Mobs do
                local Enemy = Mobs[i]
                local BasePart = Enemy:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)]) or Enemy.PrimaryPart
                if not BasePart then
                    goto continue
                end
                local CanAttack
                if Enemy.Parent == Characters then
                    local plr = Players:GetPlayerFromCharacter(Enemy)
                    CanAttack = plr and CheckPlayerAlly(plr)
                else
                    CanAttack = true
                end
                if Enemy ~= Player.Character and (Enemy.Parent ~= Characters or CanAttack) then
                    if IsAlive(Enemy) and (Position - BasePart.Position).Magnitude <= Distance then
                        if not self.EnemyRootPart then
                            self.EnemyRootPart = BasePart
                        else
                            table.insert(BladeHits, { Enemy, BasePart })
                        end
                    end
                end
                ::continue::
            end
        end

        function FastAttack:GetAllBladeHits(Character, Distance)
            local Position = Character:GetPivot().Position
            local BladeHits = {}
            Distance = Distance or self.Distance
            self:Process(self.attackMobs, Enemies, BladeHits, Position, Distance)
            self:Process(self.attackMobs, SeaBeasts, BladeHits, Position, Distance)
            self:Process(self.attackPlayers, Characters, BladeHits, Position, Distance)
            return BladeHits
        end

        function FastAttack:GetClosestEnemy(Character, Distance)
            local BladeHits = self:GetAllBladeHits(Character, Distance)
            local Dist = math.huge
            local Closest = nil
            for i = 1, #BladeHits do
                local Magnitude
                if Closest then
                    Magnitude = (Closest.Position - BladeHits[i][2].Position).Magnitude
                else
                    Magnitude = Dist
                end
                if Magnitude < Dist then
                    Dist = Magnitude
                    Closest = BladeHits[i][2]
                end
            end
            return Closest
        end

        function FastAttack:GetGunHits(Character, Distance)
            local BladeHits = self:GetAllBladeHits(Character, Distance)
            local GunHits = {}
            for i = 1, #BladeHits do
                if #GunHits == 0 then
                    table.insert(GunHits, BladeHits[i][2])
                else
                    if (BladeHits[i][2].Position - GunHits[1].Position).Magnitude <= 10 then
                        table.insert(GunHits, BladeHits[i][2])
                    end
                end
            end
            return GunHits
        end

        function FastAttack:GetCombo()
            local Combo
            if tick() - self.ComboDebounce <= 0.4 then
                Combo = self.M1Combo
            else
                Combo = 0
            end
            if Combo >= 4 then
                Combo = 1
            else
                Combo = Combo + 1
            end
            self.ComboDebounce = tick()
            self.M1Combo = Combo
            return Combo
        end

        function FastAttack:UseFruitM1(Character, Equipped, Combo)
            local Position = Character:GetPivot().Position
            local EnemyList = Enemies:GetChildren()
            for i = 1, #EnemyList do
                local Enemy = EnemyList[i]
                local PrimaryPart = Enemy.PrimaryPart
                if IsAlive(Enemy) and PrimaryPart and (PrimaryPart.Position - Position).Magnitude <= 50 then
                    local Direction = (PrimaryPart.Position - Position).Unit
                    return Equipped.LeftClickRemote:FireServer(Direction, Combo)
                end
            end
        end

        function FastAttack:UseNormalClick(Humanoid, Character, Cooldown)
            self.EnemyRootPart = nil
            local BladeHits = self:GetAllBladeHits(Character)
            local EnemyHitBox = self.EnemyRootPart
            if EnemyHitBox then
                if SUCCESS_FLAGS and COMBAT_REMOTE_THREAD and HIT_FUNCTION then
                    RE_RegisterAttack:FireServer(Cooldown)
                    HIT_FUNCTION(EnemyHitBox, BladeHits)
                elseif SUCCESS_FLAGS and not COMBAT_REMOTE_THREAD then
                    RE_RegisterAttack:FireServer(Cooldown)
                    RE_RegisterHit:FireServer(EnemyHitBox, BladeHits)
                else
                    table.insert(BladeHits, { EnemyHitBox.Parent, EnemyHitBox })
                    ExpandsHitBox(BladeHits)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end
        end

        function FastAttack:GetValidator2()
            local v1 = getupvalue(SHOOT_FUNCTION, 15)
            local v2 = getupvalue(SHOOT_FUNCTION, 13)
            local v3 = getupvalue(SHOOT_FUNCTION, 16)
            local v4 = getupvalue(SHOOT_FUNCTION, 17)
            local v5 = getupvalue(SHOOT_FUNCTION, 14)
            local v6 = getupvalue(SHOOT_FUNCTION, 12)
            local v7 = getupvalue(SHOOT_FUNCTION, 18)

            local v8 = v6 * v2
            local v9 = (v5 * v2 + v6 * v1) % v3
            v9 = (v9 * v3 + v8) % v4
            v5 = math.floor(v9 / v3)
            v6 = v9 - v5 * v3
            v7 = v7 + 1

            setupvalue(SHOOT_FUNCTION, 15, v1)
            setupvalue(SHOOT_FUNCTION, 13, v2)
            setupvalue(SHOOT_FUNCTION, 16, v3)
            setupvalue(SHOOT_FUNCTION, 17, v4)
            setupvalue(SHOOT_FUNCTION, 14, v5)
            setupvalue(SHOOT_FUNCTION, 12, v6)
            setupvalue(SHOOT_FUNCTION, 18, v7)

            return math.floor(v9 / v4 * 16777215), v7
        end

        function FastAttack:UseGunShoot(Character, Equipped)
            if not Equipped.Enabled then
                return
            end
            local ShootType = self.SpecialShoots[Equipped.Name] or "Normal"
            if ShootType == "Normal" or ShootType == "Overheat" then
                if ShootType == "Overheat" then
                    local Data = self.Overheat[Equipped.Name]
                    if Data.Shooting then
                        return
                    end
                    local Target = self:GetClosestEnemy(Character, Data.Distance or 100)
                    if Target then
                        Data.Shooting = true
                        while Equipped and Equipped.Parent == Player.Character and Data.TotalOverheat < Data.MaxOverheat do
                            if Target and Target.Parent and IsAlive(Target.Parent) then
                                local attr = Equipped:GetAttribute("LocalTotalShots") or 0
                                Equipped:SetAttribute("LocalTotalShots", attr + 1)
                                GunValidator:FireServer(self:GetValidator2())
                                RE_ShootGunEvent:FireServer(Target.Position, { Target })
                                Data.TotalOverheat = Data.TotalOverheat + task.wait(Data.Cooldown)
                            else
                                break
                            end
                        end
                        while Data.TotalOverheat > 0 do
                            Data.TotalOverheat = math.clamp(Data.TotalOverheat - task.wait(), 0, Data.MaxOverheat)
                        end
                        Data.Shooting = false
                    end
                else
                    local Hits = self:GetGunHits(Character, 120)
                    local Target = Hits[1] and Hits[1].Position
                    if Target then
                        local attr = Equipped:GetAttribute("LocalTotalShots") or 0
                        Equipped:SetAttribute("LocalTotalShots", attr + 1)
                        GunValidator:FireServer(self:GetValidator2())
                        local shots = self.ShootsPerTarget[Equipped.Name] or 1
                        for _ = 1, shots do
                            RE_ShootGunEvent:FireServer(Target, Hits)
                        end
                    end
                end
            elseif ShootType == "Position" or (ShootType == "TAP" and Equipped:FindFirstChild("RemoteEvent")) then
                local Target = self:GetClosestEnemy(Character, 200)
                if Target then
                    if self.ShootsFunctions[Equipped.Name] then
                        return self.ShootsFunctions[Equipped.Name](self, Equipped, Target.Position)
                    end
                    local attr = Equipped:GetAttribute("LocalTotalShots") or 0
                    Equipped:SetAttribute("LocalTotalShots", attr + 1)
                    GunValidator:FireServer(self:GetValidator2())
                    if ShootType == "TAP" then
                        Equipped.RemoteEvent:FireServer("TAP", Target.Position)
                    else
                        RE_ShootGunEvent:FireServer(Target.Position)
                    end
                end
            end
        end

        function FastAttack.attack()
            if not Settings.AutoClick then
                return
            end
            if not IsAlive(Player.Character) then
                return
            end
            local self = FastAttack
            local Character = Player.Character
            local Humanoid = Character.Humanoid
            local Equipped = Character:FindFirstChildOfClass("Tool")
            if not Equipped then
                return
            end
            local ToolTip = Equipped.ToolTip
            local ToolName = Equipped.Name
            if ToolTip ~= "Gun" and ToolTip ~= "Melee" and ToolTip ~= "Blox Fruit" and ToolTip ~= "Sword" then
                return
            end
            local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3
            if (tick() - self.Debounce) >= Cooldown and self:CheckStun(ToolTip, Character, Humanoid) then
                local Combo = self:GetCombo()
                if Combo >= 4 then
                    Cooldown = Cooldown + 0.01
                end
                self.Equipped = Equipped
                if Combo >= 4 and ToolTip ~= "Gun" then
                    self.Debounce = tick() + 0.05
                else
                    self.Debounce = tick()
                end
                if ToolTip == "Blox Fruit" then
                    if ToolName == "Ice-Ice" or ToolName == "Light-Light" then
                        return self:UseNormalClick(Humanoid, Character, Cooldown)
                    elseif Equipped:FindFirstChild("LeftClickRemote") then
                        if ToolName == "Blade-Blade" or ToolName == "Gas-Gas" then
                            return self:UseFruitM1(Character, Equipped, Combo)
                        else
                            return Equipped.LeftClickRemote:FireServer(Vector3.new(0.01, -500, 0.01), 1, true)
                        end
                    end
                elseif ToolTip == "Gun" then
                    if SUCCESS_SHOOT and SHOOT_FUNCTION then
                        return self:UseGunShoot(Character, Equipped)
                    end
                else
                    return self:UseNormalClick(Humanoid, Character, Cooldown)
                end
            end
        end

        table.insert(Connections, Stepped:Connect(FastAttack.attack))
        return FastAttack
    end)()

    Module.RaidList = (function()
        local Success, RaidModule = pcall(require, ReplicatedStorage:WaitForChild("Raids"))
        if not Success or type(RaidModule) ~= "table" then
            return { "Phoenix", "Dough", "Flame", "Ice", "Quake", "Light", "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand" }
        end
        local AdvancedRaids = RaidModule.advancedRaids or {}
        local NormalRaids = RaidModule.raids or {}
        local RaidList = {}
        for i = 1, #AdvancedRaids do
            table.insert(RaidList, AdvancedRaids[i])
        end
        for i = 1, #NormalRaids do
            table.insert(RaidList, NormalRaids[i])
        end
        return RaidList
    end)()

    Module.Tween = (function()
        local BodyVelocity = Instance.new("BodyVelocity")
        BodyVelocity.Velocity = Vector3.zero
        BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyVelocity.P = 1000
        if _ENV.tween_bodyvelocity then
            _ENV.tween_bodyvelocity:Destroy()
        end
        _ENV.tween_bodyvelocity = BodyVelocity

        local IsAlive = Module.IsAlive
        local CanRemoveTag = false
        local BaseParts = {}
        local CanCollideObjects = {}
        local CanTouchObjects = {}

        do
            local function AddObjectToBaseParts(Object)
                if Object:IsA("BasePart") and (Object.CanCollide or Object.CanTouch) then
                    table.insert(BaseParts, Object)
                    if Object.CanCollide then
                        CanCollideObjects[Object] = true
                    end
                    if Object.CanTouch then
                        CanTouchObjects[Object] = true
                    end
                end
            end
            local function RemoveObjectsFromBaseParts(BasePart)
                for i, v in ipairs(BaseParts) do
                    if v == BasePart then
                        table.remove(BaseParts, i)
                        break
                    end
                end
            end
            local function NewCharacter(Character)
                table.clear(BaseParts)
                table.clear(CanCollideObjects)
                table.clear(CanTouchObjects)
                for _, Object in ipairs(Character:GetDescendants()) do
                    AddObjectToBaseParts(Object)
                end
                Character.DescendantAdded:Connect(AddObjectToBaseParts)
                Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
                Character:WaitForChild("Humanoid", 9e9).Died:Wait()
                table.clear(BaseParts)
                table.clear(CanCollideObjects)
                table.clear(CanTouchObjects)
            end
            table.insert(Connections, Player.CharacterAdded:Connect(NewCharacter))
            if Player.Character then
                task.spawn(NewCharacter, Player.Character)
            end
        end

        local function NoClipOnStepped(Character)
            if not IsAlive(Character) then
                return
            end
            if _ENV.OnFarm and not Player:HasTag("Teleporting") then
                Player:AddTag("Teleporting")
                CanRemoveTag = true
            elseif not _ENV.OnFarm and CanRemoveTag and Player:HasTag("Teleporting") then
                Player:RemoveTag("Teleporting")
                CanRemoveTag = false
            end
            if _ENV.OnFarm then
                for i = 1, #BaseParts do
                    local BasePart = BaseParts[i]
                    local CanTouchValue = (tick() - Module.RemoveCanTouch > 1)
                    if CanTouchObjects[BasePart] and BasePart.CanTouch ~= CanTouchValue then
                        BasePart.CanTouch = CanTouchValue
                    end
                    if CanCollideObjects[BasePart] and BasePart.CanCollide then
                        BasePart.CanCollide = false
                    end
                end
            elseif Character.PrimaryPart and (not Character.PrimaryPart.CanCollide or not Character.PrimaryPart.CanTouch) then
                for i = 1, #BaseParts do
                    local BasePart = BaseParts[i]
                    if CanCollideObjects[BasePart] then
                        BasePart.CanCollide = true
                    end
                    if CanTouchObjects[BasePart] then
                        BasePart.CanTouch = true
                    end
                end
            end
        end

        local function UpdateVelocityOnStepped(Character)
            local RootPart = Character and Character:FindFirstChild("UpperTorso")
            local Humanoid = Character and Character:FindFirstChild("Humanoid")
            local BodyVelocity = _ENV.tween_bodyvelocity
            if _ENV.OnFarm and RootPart and Humanoid and Humanoid.Health > 0 then
                if BodyVelocity.Parent ~= RootPart then
                    BodyVelocity.Parent = RootPart
                end
            else
                if BodyVelocity.Parent then
                    BodyVelocity.Parent = nil
                end
            end
            if BodyVelocity.Velocity ~= Vector3.zero and (not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm) then
                BodyVelocity.Velocity = Vector3.zero
            end
        end

        table.insert(Connections, Stepped:Connect(function()
            local Character = Player.Character
            UpdateVelocityOnStepped(Character)
            NoClipOnStepped(Character)
        end))

        return BodyVelocity
    end)()

    Module.Hooking = (function()
        local Hooking = {
            Skills = CreateDictionary({ "Z", "X", "C", "V", "F" }, true),
            ClosestsEnemies = {}
        }
        local Enabled = _ENV.rz_EnabledOptions
        local Debounce = Module.Debounce
        local IsAlive = Module.IsAlive

        local function GetNextTarget(Mode, ClosestList)
            if (tick() - Debounce.TargetDebounce) <= 2 or _ENV[Mode] then
                if ClosestList then
                    return Hooking.ClosestsEnemies
                else
                    return Hooking.ClosestsEnemies.Closest
                end
            end
        end

        function Hooking:SetTarget(RootPart, Character, IsEnemy)
            table.clear(self.ClosestsEnemies)
            self.ClosestsEnemies.Closest = RootPart
            Debounce.TargetDebounce = tick()
            if IsEnemy then
                local enemies = Module.Enemies:GetTagged(Character.Name)
                if enemies then
                    for i = 1, #enemies do
                        local Enemy = enemies[i]
                        if Enemy ~= Character and Enemy:FindFirstChild("UpperTorso") then
                            table.insert(self.ClosestsEnemies, Enemy.UpperTorso)
                        end
                    end
                end
            end
        end

        function Hooking.UpdateClosests()
            local SmoothDebounce = Settings.SmoothMode and 0.5 or 0.25
            if (tick() - Debounce.TargetDebounce) <= 2 or (tick() - Debounce.UpdateDebounce) <= SmoothDebounce then
                return
            end
            Debounce.UpdateDebounce = tick()
            local Equipped = IsAlive(Player.Character) and Player.Character:FindFirstChildOfClass("Tool")
            if Equipped and Equipped.ToolTip then
                local ClosestsEnemies = Hooking.ClosestsEnemies
                table.clear(ClosestsEnemies)
                local Position = Player.Character:GetPivot().Position
                local PlayersList = Players:GetPlayers()
                local EnemiesList = Enemies:GetChildren()
                local Distance = 900
                local ClosestsDistance = 60
                if Equipped.ToolTip == "Gun" then
                    Distance = 120
                    ClosestsDistance = 120
                end
                for i = 1, #PlayersList do
                    local __Player = PlayersList[i]
                    local Character = __Player.Character
                    if Player ~= __Player and CheckPlayerAlly(__Player) and IsAlive(Character) then
                        local UpperTorso = Character:FindFirstChild("UpperTorso")
                        if UpperTorso then
                            local Magnitude = (UpperTorso.Position - Position).Magnitude
                            if Magnitude <= ClosestsDistance then
                                table.insert(ClosestsEnemies, UpperTorso)
                            end
                            if Magnitude <= Distance then
                                ClosestsEnemies.Closest = UpperTorso
                                Distance = Magnitude
                            end
                        end
                    end
                end
                if Settings.NoAimMobs then
                    return
                end
                for i = 1, #EnemiesList do
                    local Enemy = EnemiesList[i]
                    local UpperTorso = Enemy and Enemy:FindFirstChild("UpperTorso")
                    if UpperTorso and IsAlive(Enemy) then
                        local Magnitude = (UpperTorso.Position - Position).Magnitude
                        if Magnitude <= ClosestsDistance then
                            table.insert(ClosestsEnemies, UpperTorso)
                        end
                        if Magnitude <= Distance then
                            Distance = Magnitude
                            ClosestsEnemies.Closest = UpperTorso
                        end
                    end
                end
            end
        end

        task.defer(function()
            if _ENV.original_namecall then
                return
            end
            local old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
                if string.lower(getnamecallmethod()) ~= "fireserver" then
                    return old_namecall(self, ...)
                end
                local Name = self.Name
                if Name == "RE/ShootGunEvent" then
                    local Position, EnemiesList = ...
                    if typeof(Position) == "Vector3" and type(EnemiesList) == "table" then
                        local ClosestList = GetNextTarget("AimBot_Gun", true)
                        if ClosestList and #ClosestList > 0 then
                            for i = 1, #ClosestList do
                                local BasePart = ClosestList[i]
                                if BasePart and (not EnemiesList[1] or (BasePart.Position - EnemiesList[1].Position).Magnitude <= 15) then
                                    table.insert(EnemiesList, BasePart)
                                end
                            end
                            return old_namecall(self, EnemiesList[1].Position, EnemiesList)
                        end
                    end
                elseif Name == "RemoteEvent" then
                    local v1, v2 = ...
                    if typeof(v1) == "Vector3" and not v2 then
                        local Target = GetNextTarget("AimBot_Skills", false)
                        if Target then
                            return old_namecall(self, Target.Position)
                        end
                    elseif v1 == "TAP" and typeof(v2) == "Vector3" then
                        local Target = GetNextTarget("AimBot_Tap", false)
                        if Target then
                            return old_namecall(self, "TAP", Target.Position)
                        end
                    end
                end
                return old_namecall(self, ...)
            end)
            _ENV.original_namecall = old_namecall
        end)

        table.insert(Connections, Heartbeat:Connect(Hooking.UpdateClosests))
        return Hooking
    end)()

    task.defer(function()
        local DeathEffect = require(WaitChilds(ReplicatedStorage, "Effect", "Container", "Death"))
        local CameraShaker = require(WaitChilds(ReplicatedStorage, "Util", "CameraShaker"))
        if CameraShaker then
            CameraShaker:Stop()
        end
        if hookfunction then
            hookfunction(DeathEffect, function(...) return ... end)
        end
    end)

    task.spawn(function()
        local SpawnLocations = Module.SpawnLocations
        local EnemyLocations = Module.EnemyLocations
        local function NewIslandAdded(Island)
            if string.find(Island.Name, "Island") then
                Cached.RaidIsland = nil
            end
        end
        local function NewSpawn(Part)
            local EnemyName = GetEnemyName(Part.Name)
            if not EnemyLocations[EnemyName] then
                EnemyLocations[EnemyName] = {}
            end
            local EnemySpawn = Part.CFrame + Vector3.new(0, 25, 0)
            SpawnLocations[EnemyName] = Part
            local found = false
            for _, v in ipairs(EnemyLocations[EnemyName]) do
                if v == EnemySpawn then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(EnemyLocations[EnemyName], EnemySpawn)
            end
        end
        for _, Spawn in ipairs(EnemySpawns:GetChildren()) do
            NewSpawn(Spawn)
        end
        table.insert(Connections, EnemySpawns.ChildAdded:Connect(NewSpawn))
        table.insert(Connections, Locations.ChildAdded:Connect(NewIslandAdded))
    end)

    function Module:EnableBuso()
        local Character = Player.Character
        if Settings.AutoBuso and self.IsAlive(Character) and not Character:FindFirstChild("HasBuso") then
            if Character:HasTag("Buso") then
                self.FireRemote("Buso")
            elseif Money.Value >= 25000 then
                self.FireRemote("BuyHaki", "Buso")
            end
        end
    end

    function Module:GetToolByName(Name)
        local CachedTool = self.Cached.Tools[Name]
        if CachedTool and (CachedTool.Parent == Player.Character or CachedTool.Parent == Player.Backpack) then
            return CachedTool
        end
        if self.IsAlive(Player.Character) then
            local Tool = Player.Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name)
            if Tool then
                self.Cached.Tools[Name] = Tool
                return Tool
            end
        end
    end

    function Module:GetToolMastery(Name)
        local Tool = self:GetToolByName(Name)
        if Tool then
            return Tool:GetAttribute("Level") or 0
        end
        return 0
    end

    function Module:GetToolTip(ToolTip, Folder)
        for _, Tool in ipairs(Folder:GetChildren()) do
            if Tool:IsA("Tool") and Tool.ToolTip == ToolTip then
                self.Cached.Tools["ToolTip_" .. ToolTip] = Tool
                return Tool
            end
        end
    end

    function Module:VerifyToolTip(ToolTip)
        local CachedTool = self.Cached.Tools["ToolTip_" .. ToolTip]
        if CachedTool and (CachedTool.Parent == Player.Character or CachedTool.Parent == Player.Backpack) then
            return CachedTool
        end
        local Character = self.IsAlive(Player.Character) and Player.Character
        local Tool = self:GetToolTip(ToolTip, Player.Backpack)
        if not Tool and Character then
            Tool = self:GetToolTip(ToolTip, Character)
        end
        return Tool
    end

    function Module:VerifyTool(Name)
        return self:GetToolByName(Name) ~= nil
    end
end

return Module
