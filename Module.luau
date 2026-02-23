local Settings, Connections = ...

local _ENV = (getgenv or getrenv or getfenv)()

if type(Settings) ~= "table" or type(Connections) ~= "table" then
    return {}
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

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

local Stepped = RunService.Stepped
local Heartbeat = RunService.Heartbeat
local RenderStepped = RunService.RenderStepped

local Player = Players.LocalPlayer
local Data = Player:WaitForChild("Data")
local Level = Data:WaitForChild("Level")
local Fragments = Data:WaitForChild("Fragments")
local Money = Data:WaitForChild("Beli")
local Race = Data:WaitForChild("Race")
local Subclass = Data:WaitForChild("Subclass")
local FruitCap = Data:WaitForChild("FruitCap")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Net = Modules:WaitForChild("Net")

local EXECUTOR_NAME = string.upper(identifyexecutor and identifyexecutor() or "NULL")
local IS_BLACKLISTED = table.find({"NULL", "XENO", "SWIFT", "JJSPLOIT"}, EXECUTOR_NAME) ~= nil

local hookmetamethod = (not IS_BLACKLISTED and hookmetamethod) or function(...) return ... end
local hookfunction = (not IS_BLACKLISTED and hookfunction) or function(...) return ... end
local sethiddenproperty = sethiddenproperty or function(...) return ... end
local setupvalue = setupvalue or (debug and debug.setupvalue)
local getupvalue = getupvalue or (debug and debug.getupvalue)

local BRING_TAG = _ENV._Bring_Tag or ("b" .. math.random(80, 20000) .. "t")
local KILLAURA_TAG = _ENV._KillAura_Tag or ("k" .. math.random(120, 20000) .. "t")

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local HIDDEN_SETTINGS = {
    SKILL_COOLDOWN = 0.5,
    CLEAR_AFTER = 50
}

local function GetEnemyName(str)
    return (str:find("Lv. ") and str:gsub(" %pLv. %d+%p", "") or str):gsub(" %pBoss%p", "")
end

local function GetCharacterHumanoid(Character)
    if Character:GetAttribute("IsBoat") or Character.Parent == SeaBeasts then
        local HealthValue = Character:FindFirstChild("Health")
        if HealthValue then
            return HealthValue
        else
            return Character:FindFirstChild("Humanoid"), true
        end
    else
        return Character:FindFirstChildOfClass("Humanoid")
    end
end

local function CheckPlayerAlly(__Player)
    if tostring(__Player.Team) == "Marines" and __Player.Team == Player.Team then
        return false
    elseif __Player:HasTag("Ally" .. Player.Name) or Player:HasTag("Ally" .. __Player.Name) then
        return false
    end
    return true
end

local function WaitChilds(Instance, ...)
    for _, ChildName in ipairs({...}) do
        Instance = Instance:WaitForChild(ChildName)
    end
    return Instance
end

local function FastWait(Seconds, Instance, ...)
    local Success, Result = pcall(function(...)
        for _, ChildName in ipairs({...}) do
            Instance = Instance:WaitForChild(ChildName, Seconds)
        end
        return Instance
    end, ...)
    return Success and Result or nil
end

function ToDictionary(array)
    local dict = {}
    for _, value in ipairs(array) do
        dict[value] = true
    end
    return dict
end

local sea1 = {2753915549, 85211729168715}
local sea2 = {4442272183, 79091703265657}
local sea3 = {7449423635, 100117331123089}

local function detectSea()
    local placeId = game.PlaceId
    if table.find(sea1, placeId) then
        return 1
    elseif table.find(sea2, placeId) then
        return 2
    elseif table.find(sea3, placeId) then
        return 3
    end
    return 0
end

local Cached = {
    Equipped = nil,
    Humanoids = {},
    Enemies = {},
    Progress = {},
    Bring = {},
    Tools = {},
    RaidIsland = nil,
    FruitsName = {},
    FruitsId = {}
}

local Module = {
    GameData = {
        Sea = detectSea(),
        SeasName = {"Main", "Dressrosa", "Zou"},
        MaxMastery = 600,
        MaxLevel = workspace:GetAttribute("LEVEL_CAP") or 2800
    },
    Debounce = {
        TargetDebounce = 0,
        UpdateDebounce = 0,
        GetEnemy = 0,
        Skills = {}
    },
    IsSuperBring = false,
    RemoveCanTouch = 0,
    AttackCooldown = 0,
    PirateRaid = 0,
    Webhooks = true,
    JobIds = true,
    Progress = {},
    EnemyLocations = {},
    SpawnLocations = {},
    Cached = Cached,
    Signals = {
        Notify = {Fire = function(...) end},
        Error = {Fire = function(...) end}
    },
    RunFunctions = {},
    allMobs = {
        __RaidBoss = {},
        __Bones = {},
        __Elite = {},
        __CakePrince = {}
    }
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
    ["Don Swan"] = {RaidBoss = true, Position = CFrame.new(2289, 15, 808)},
    ["Cursed Captain"] = {RaidBoss = true, Position = CFrame.new(912, 186, 33591)},
    ["Darkbeard"] = {RaidBoss = true, Position = CFrame.new(3695, 13, -3599)},
    ["Diamond"] = {IsBoss = true, Level = 750, Position = CFrame.new(-1569, 199, -31), Quest = {"Area1Quest", CFrame.new(-427, 73, 1835)}},
    ["Jeremy"] = {IsBoss = true, Level = 850, Position = CFrame.new(2316, 449, 787), Quest = {"Area2Quest", CFrame.new(635, 73, 919)}},
    ["Orbitus"] = {IsBoss = true, Level = 925, Position = CFrame.new(-2086, 73, -4208), Quest = {"MarineQuest3", CFrame.new(-2441, 73, -3219)}},
    ["Smoke Admiral"] = {IsBoss = true, Level = 1150, Position = CFrame.new(-5078, 24, -5352), Quest = {"IceSideQuest", CFrame.new(-6061, 16, -4904)}},
    ["Awakened Ice Admiral"] = {IsBoss = true, Level = 1400, Position = CFrame.new(6473, 297, -6944), Quest = {"FrostQuest", CFrame.new(5668, 28, -6484)}},
    ["Tide Keeper"] = {IsBoss = true, Level = 1475, Position = CFrame.new(-3711, 77, -11469), Quest = {"ForgottenQuest", CFrame.new(-3056, 240, -10145)}},
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

function Module.FireRemote(...)
    return CommF:InvokeServer(...)
end

function Module.IsAlive(Character)
    if Character then
        local Humanoid = Cached.Humanoids[Character] or GetCharacterHumanoid(Character)
        if Humanoid then
            if not Cached.Humanoids[Character] then
                Cached.Humanoids[Character] = Humanoid
            end
            local health = Humanoid.ClassName == "Humanoid" and Humanoid.Health or Humanoid.Value
            return health and health > 0
        end
        return Character.Parent == Boats
    end
    return false
end

function Module.IsBoss(Name)
    return Module.Bosses[Name] and true or false
end

function Module.Rejoin()
    task.spawn(TeleportService.TeleportToPlaceInstance, TeleportService, game.PlaceId, game.JobId, Player)
end

function Module:TravelTo(Sea)
    Module.FireRemote("Travel" .. self.GameData.SeasName[Sea])
end

function Module:IsBlacklistedExecutor()
    return IS_BLACKLISTED
end

function Module.EquipTool(ToolName, ByType)
    ByType = ByType or not ToolName
    ToolName = ToolName or Settings.FarmTool
    
    if not Module.IsAlive(Player.Character) then
        return nil
    end
    
    local Equipped = Cached.Equipped
    
    if Equipped and Equipped.Parent and Equipped[ByType and "ToolTip" or "Name"] == ToolName then
        if Equipped.Parent == Player.Backpack then
            Player.Character.Humanoid:EquipTool(Equipped)
        elseif Equipped.Parent == Player.Character then
            return nil
        end
    end
    
    if ToolName and not ByType then
        local Tool = Player.Backpack:FindFirstChild(ToolName)
        if Tool then
            Cached.Equipped = Tool
            Player.Character.Humanoid:EquipTool(Tool)
        end
        return nil
    end
    
    for _, Tool in ipairs(Player.Backpack:GetChildren()) do
        if Tool:IsA("Tool") and Tool.ToolTip == ToolName then
            Cached.Equipped = Tool
            Player.Character.Humanoid:EquipTool(Tool)
            return nil
        end
    end
end

function Module.UseSkills(Skills)
    if not Skills then return end
    for Skill, Enabled in pairs(Skills) do
        if Enabled then
            VirtualInputManager:SendKeyEvent(true, Skill, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Skill, false, game)
        end
    end
end

function Module.KillAura(Distance, Name)
    Distance = Distance or 500
    for _, Enemy in ipairs(Enemies:GetChildren()) do
        local Part = Enemy.PrimaryPart
        if (not Name or Enemy.Name == Name) and Part and not Enemy:HasTag(KILLAURA_TAG) then
            if Module.IsAlive(Enemy) and Player:DistanceFromCharacter(Part.Position) < Distance then
                Enemy:AddTag(KILLAURA_TAG)
            end
        end
    end
end

function Module:BringEnemies(ToEnemy, SuperBring)
    if not Module.IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
        return nil
    end
    
    pcall(sethiddenproperty, Player, "SimulationRadius", 9e9)
    
    if Settings.BringMobs then
        Module.IsSuperBring = SuperBring or false
        
        local Name = ToEnemy.Name
        local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
        local Target = ToEnemy.PrimaryPart.CFrame
        local Tag = SuperBring and "ALL_MOBS" or Name
        
        if not Cached.Bring[Tag] or (Target.Position - Cached.Bring[Tag].Position).Magnitude > 25 then
            Cached.Bring[Tag] = Target
        end
        
        local EnemyList = SuperBring and Enemies:GetChildren() or Module.allMobs[Name]
        
        if EnemyList then
            for _, Enemy in ipairs(EnemyList) do
                if Enemy.Parent ~= Enemies or Enemy:HasTag(BRING_TAG) then
                    continue
                end
                if not Enemy:FindFirstChild("CharacterReady") then
                    continue
                end
                
                local Part = Enemy.PrimaryPart
                if Module.IsAlive(Enemy) and Part then
                    if (Position - Part.Position).Magnitude < Settings.BringDistance then
                        Enemy:AddTag(BRING_TAG)
                    end
                end
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
    local Entry = Cached.Progress[Tag]
    if Entry and (tick() - Entry.debounce) < 2 then
        return Entry.result
    end
    
    local Result = self.FireRemote(...)
    
    if Entry then
        Entry.result = Result
        Entry.debounce = tick()
    else
        Cached.Progress[Tag] = {
            debounce = tick(),
            result = Result
        }
    end
    
    return Result
end

function Module:RemoveBoatCollision(Boat)
    for _, Object in ipairs(Boat:GetDescendants()) do
        if Object:IsA("BasePart") and Object.CanCollide then
            Object.CanCollide = false
        end
    end
end

Module.Chests = setmetatable({}, {
    __call = function(self, SelectedIsland)
        if self.Cached and not self.Cached:GetAttribute("IsDisabled") then
            if not SelectedIsland or self.Cached:IsDescendantOf(SelectedIsland) then
                return self.Cached
            end
        end
        
        local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
        local Chests = CollectionService:GetTagged("_ChestTagged")
        local Distance, Nearest = math.huge, nil
        
        for _, Chest in ipairs(Chests) do
            if not SelectedIsland or Chest:IsDescendantOf(SelectedIsland) then
                if not Chest:GetAttribute("IsDisabled") then
                    local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
                    if Magnitude < Distance then
                        Distance, Nearest = Magnitude, Chest
                    end
                end
            end
        end
        
        self.Cached = Nearest
        return Nearest
    end
})

Module.Berry = setmetatable({}, {
    __call = function(self, BerryArray)
        if self.Cached and self.Cached:IsDescendantOf(Map) then
            return self.Cached
        end
        
        local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
        local Bushes = CollectionService:GetTagged("BerryBush")
        local Distance, Nearest = math.huge, nil
        
        for _, Bush in ipairs(Bushes) do
            for AttributeName, BerryName in pairs(Bush:GetAttributes()) do
                if not BerryArray or table.find(BerryArray, BerryName) then
                    local Magnitude = (Bush.Parent:GetPivot().Position - Position).Magnitude
                    if Magnitude < Distance then
                        Distance, Nearest = Magnitude, Bush
                    end
                end
            end
        end
        
        self.Cached = Nearest
        return Nearest
    end
})

Module.FruitsName = setmetatable({}, {
    __index = function(self, Fruit)
        if Fruit.Name ~= "Fruit " then
            rawset(self, Fruit, Fruit.Name)
            return Fruit.Name
        end
        
        local Model = Fruit:WaitForChild("Fruit", 5)
        local Handle = FastWait(2, Model, "Idle") or FastWait(1, Model, "Animation") or FastWait(1, Model, "Fruit")
        
        if Handle and (Handle:IsA("Animation") or Handle:IsA("MeshPart")) then
            local Property = Handle:IsA("MeshPart") and "MeshId" or "AnimationId"
            local RealName = Module.FruitsId[Handle[Property] or ""]
            if RealName then
                rawset(self, Fruit, "Fruit [" .. RealName .. "]")
                return rawget(self, Fruit)
            end
        end
        
        rawset(self, Fruit, "Fruit [ ??? ]")
        return "Fruit [ ??? ]"
    end
})

Module.Enemies = {
    GetEnemyByTag = function(_, Tag)
        for _, Enemy in ipairs(Enemies:GetChildren()) do
            if Enemy.Name == Tag and Module.IsAlive(Enemy) then
                return Enemy
            end
        end
    end,
    GetClosestByTag = function(_, Tag)
        local Position = Player.Character and Player.Character:GetPivot().Position
        if not Position then return end
        local Distance, Closest = math.huge, nil
        for _, Enemy in ipairs(Enemies:GetChildren()) do
            if Enemy.Name == Tag and Module.IsAlive(Enemy) and Enemy.PrimaryPart then
                local Magnitude = (Enemy.PrimaryPart.Position - Position).Magnitude
                if Magnitude < Distance then
                    Distance, Closest = Magnitude, Enemy
                end
            end
        end
        return Closest
    end,
    GetClosest = function(_, EnemiesList)
        local Position = Player.Character and Player.Character:GetPivot().Position
        if not Position then return end
        local Distance, Closest = math.huge, nil
        for _, Name in ipairs(EnemiesList) do
            local Enemy = Module.Enemies.GetClosestByTag(Module.Enemies, Name)
            if Enemy and Enemy.PrimaryPart then
                local Magnitude = (Enemy.PrimaryPart.Position - Position).Magnitude
                if Magnitude < Distance then
                    Distance, Closest = Magnitude, Enemy
                end
            end
        end
        return Closest
    end,
    IsSpawned = function(_, Name)
        for _, Enemy in ipairs(Enemies:GetChildren()) do
            if Enemy.Name == Name and Module.IsAlive(Enemy) then
                return true
            end
        end
        return false
    end
}

Module.EnemySpawned = function(Name)
    if type(Name) == "table" then
        return Module.Enemies.GetClosest(Module.Enemies, Name)
    else
        return Module.Enemies.GetEnemyByTag(Module.Enemies, Name)
    end
end

Module.Inventory = {
    Unlocked = setmetatable({}, {__index = function() return false end}),
    Mastery = setmetatable({}, {__index = function() return 0 end}),
    Count = setmetatable({}, {__index = function() return 0 end})
}

Module.FastAttack = {
    attackMobs = true,
    attackPlayers = true,
    Debounce = 0,
    ComboDebounce = 0,
    M1Combo = 0,
    ShootDebounce = 0,
    attack = function()
        if not Settings.AutoClick or tick() - Module.AttackCooldown < 0.3 then
            return
        end
        if not Module.IsAlive(Player.Character) then
            return
        end
        
        local Character = Player.Character
        local Tool = Character:FindFirstChildOfClass("Tool")
        if not Tool then
            return
        end
        
        local ToolTip = Tool.ToolTip
        if not ToolTip or (ToolTip ~= "Melee" and ToolTip ~= "Sword" and ToolTip ~= "Blox Fruit" and ToolTip ~= "Gun") then
            return
        end
        
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        
        Module.AttackCooldown = tick()
    end
}

Module.Tween = Instance.new("BodyVelocity")
Module.Tween.Velocity = Vector3.zero
Module.Tween.MaxForce = Vector3.new(9e9, 9e9, 9e9)
Module.Tween.P = 1000

if _ENV.tween_bodyvelocity then
    _ENV.tween_bodyvelocity:Destroy()
end
_ENV.tween_bodyvelocity = Module.Tween

Module.Hooking = {
    Skills = ToDictionary({"Z", "X", "C", "V", "F"}),
    ClosestsEnemies = {},
    SetTarget = function(self, RootPart, Character, IsEnemy)
        table.clear(self.ClosestsEnemies)
        self.ClosestsEnemies.Closest = RootPart
        Module.Debounce.TargetDebounce = tick()
        
        if IsEnemy and Character then
            for _, Enemy in ipairs(Enemies:GetChildren()) do
                if Enemy ~= Character and Enemy:FindFirstChild("UpperTorso") then
                    table.insert(self.ClosestsEnemies, Enemy.UpperTorso)
                end
            end
        end
    end,
    EnableBypass = function()
        if _ENV._Enabled_Speed_Bypass then
            return
        end
        _ENV._Enabled_Speed_Bypass = true
        
        local old
        old = hookmetamethod(Player, "__newindex", function(self, index, value)
            if tostring(self) == "Humanoid" and index == "WalkSpeed" then
                return old(self, "WalkSpeed", _ENV.WalkSpeedBypass or value)
            end
            return old(self, index, value)
        end)
    end
}

Module.RaidList = {
    "Phoenix", "Dough", "Flame", "Ice", "Quake", "Light",
    "Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand"
}

Module.new = function(CFrame, Speed, Instant, Ignore)
    local Character = Player.Character
    if not Module.IsAlive(Character) then
        return
    end
    local Root = Character.PrimaryPart
    if not Root then
        return
    end
    
    if Instant then
        Root.CFrame = CFrame
        return
    end
    
    local Distance = (Root.Position - CFrame.Position).Magnitude
    local TweenSpeed = Speed or Settings.TweenSpeed or 200
    
    if Distance < 380 then
        local Tween = TweenService:Create(Root, TweenInfo.new(Distance / (TweenSpeed * 2), Enum.EasingStyle.Linear), {CFrame = CFrame})
        Tween:Play()
    else
        local Tween = TweenService:Create(Root, TweenInfo.new(Distance / TweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame})
        Tween:Play()
    end
end

function Module:ServerHop()
    local PlaceID = game.PlaceId
    local Success, Servers = pcall(function()
        return HttpService:JSONDecode(HttpService:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?limit=100"))
    end)
    
    if Success and Servers and Servers.data then
        for _, Server in ipairs(Servers.data) do
            if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
                if ReplicatedStorage:FindFirstChild("__ServerBrowser") then
                    ReplicatedStorage.__ServerBrowser:InvokeServer("teleport", Server.id)
                end
                return
            end
        end
    end
end

function EnableBuso()
    local Character = Player.Character
    if Settings.AutoBuso and Module.IsAlive(Character) and not Character:FindFirstChild("HasBuso") then
        if Character:HasTag("Buso") then
            Module.FireRemote("Buso")
        elseif Money.Value >= 25000 then
            Module.FireRemote("BuyHaki", "Buso")
        end
    end
end

function GetToolByName(Name)
    local Cached = Cached.Tools[Name]
    if Cached and Cached.Parent and (Cached.Parent == Player.Character or Cached.Parent == Player.Backpack) then
        return Cached
    end
    
    if Player.Character then
        local Tool = Player.Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name)
        if Tool then
            Cached.Tools[Name] = Tool
            return Tool
        end
    end
end

function GetToolMastery(Name)
    local Tool = GetToolByName(Name)
    return Tool and Tool:GetAttribute("Level") or 0
end

function VerifyTool(Name)
    return GetToolByName(Name) and true or false
end

function VerifyToolTip(Tip)
    if Player.Character then
        for _, Tool in ipairs(Player.Character:GetChildren()) do
            if Tool:IsA("Tool") and Tool.ToolTip == Tip then
                return Tool
            end
        end
    end
    for _, Tool in ipairs(Player.Backpack:GetChildren()) do
        if Tool:IsA("Tool") and Tool.ToolTip == Tip then
            return Tool
        end
    end
end

Module.EnableBuso = EnableBuso
Module.GetToolByName = GetToolByName
Module.GetToolMastery = GetToolMastery
Module.VerifyTool = VerifyTool
Module.VerifyToolTip = VerifyToolTip

table.insert(Connections, Stepped:Connect(Module.FastAttack.attack))

return Module
