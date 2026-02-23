local Settings, Connections = ...
local importer = ...
assert(type(importer) == "table", "package importer not found")
assert(type(importer.Import) == "function", "Import not found")

local _ENV = (getgenv or getrenv or getfenv)()
local RobloxServices = importer:Import("RobloxServices")
local Connections = importer:Import("Connections")
local Obfuscated = importer:Import("Obfuscated")
local Settings = importer:Import("Settings")

if type(Settings) ~= "table" or type(Connections) ~= "table" then
	return {}
end
local _ENV = (getgenv or getrenv or getfenv)()

local VirtualInputManager: VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService: CollectionService = game:GetService("CollectionService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService: TeleportService = game:GetService("TeleportService")
local RunService: RunService = game:GetService("RunService")
local Players: Players = game:GetService("Players")
local VirtualInputManager: VirtualInputManager = RobloxServices.VirtualInputManager
local CollectionService: CollectionService = RobloxServices.CollectionService
local ReplicatedStorage: ReplicatedStorage = RobloxServices.ReplicatedStorage
local TeleportService: TeleportService = RobloxServices.TeleportService
local TweenService: TweenService = RobloxServices.TweenService
local RunService: RunService = RobloxServices.RunService
local Players: Players = RobloxServices.Players

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GunValidator: RemoteEvent = Remotes:WaitForChild("Validator2")
@@ -42,104 +46,136 @@ local Money: IntValue = Data:WaitForChild("Beli")
local Modules: Folder? = ReplicatedStorage:WaitForChild("Modules")
local Net: ModuleScript = Modules:WaitForChild("Net")

local BLACKLISTED_EXECUTORS: { string } = {"NULL"}

local EXECUTOR_NAME: string = string.upper(if identifyexecutor then identifyexecutor() else "NULL")
local IS_BLACKLISTED_EXECUTOR: boolean? = table.find({"NULL", "XENO", "JJSPLOIT"}, EXECUTOR_NAME)
local IS_BLACKLISTED_EXECUTOR: boolean = if table.find(BLACKLISTED_EXECUTORS, EXECUTOR_NAME) then true else false

local hookmetamethod = (not IS_BLACKLISTED_EXECUTOR and hookmetamethod) or (function(...) return ... end)
local hookfunction = (not IS_BLACKLISTED_EXECUTOR and hookfunction) or (function(...) return ... end)
local sethiddenproperty = sethiddenproperty or (function(...) return ... end)
local sethiddenproperty: (Instance, string, any?) -> (nil) = sethiddenproperty or (function(...) return ... end)

local setupvalue: (any, number, any?) -> (nil) = setupvalue or (debug and debug.setupvalue)
local getupvalue: (any, number) -> any = getupvalue or (debug and debug.getupvalue)

local BRING_TAG: string = _ENV._Bring_Tag or `b{math.random(80, 2e4)}t`
local KILLAURA_TAG: string = _ENV._KillAura_Tag or `k{math.random(120, 2e4)}t`

local ServerOwnerId: IntValue = ReplicatedStorage:FindFirstChild("PrivateServerOwnerId")
local ServerOwnerId: IntValue? = ReplicatedStorage:FindFirstChild("PrivateServerOwnerId")
local IsPrivateServer: boolean = if ServerOwnerId then ServerOwnerId.Value ~= 0 else true

local function getHookManager()
	local HookManager = {}
local function CreateDictionary(array: { string? }, value: any?): { [string]: any? }
	local Dictionary = {}
	
	for _, string in ipairs(array) do
		Dictionary[string] = if type(value) == "table" then {} else value
	end

	return Dictionary
end

local function NewHookManager()
	local HookManager = {}

	local hookedProperties = {}
	local protectedObjects = {}
	
	local originalIndex, originalNamecall
	local SafeObject = _ENV.rz_obfuscated_safe_object
	
	local function generateIndexError(object, index)
		local objectName = if typeof(object) == "Instance" then originalIndex(object, "ClassName") else tostring(object)
		return `{ tostring(index) } is not a valid member of { objectName }`
	local noclipObjects = {}
	local noclipProperties = {}

	local SafeObject = Obfuscated.SafeObject
	local cloneObject = SafeObject.Clone
	local originalCloneProperties = CreateDictionary(Obfuscated.OriginalProperties, true)

	local function isString(index)
		return type(index) == "string"
	end
	
	originalIndex = hookmetamethod(game, "__index", function(self, index)
		if protectedObjects[self] then
			if index == "Parent" then
				return originalIndex(self, "Parent")
			else
				return originalIndex(SafeObject, index)

	local originalIndex
	local originalNamecall

	originalIndex = hookmetamethod(game, "__index", function(object, index)
		local clone = protectedObjects[object]
		if clone and isString(index) and not originalCloneProperties[index] then
			object = clone
		else
			local isNoclip = noclipObjects[object]
			if isNoclip and noclipProperties[index] then
				return noclipProperties[index][object] or originalIndex(object, index)
			end
		end

		local hookedObject = hookedProperties[self]
		
		if hookedObject and hookedObject[index] ~= nil then
			return hookedObject[index]
		end
		
		local success, result = pcall(originalIndex, self, index)
		
		if not success then
			return error(result, 2)
		elseif typeof(result) == "Instance" and protectedObjects[result] then
			return error(generateIndexError(self, index), 2)
		local hooked = hookedProperties[object]
		if hooked and hooked[index] ~= nil then
			return hooked[index]
		end

		return result
		return originalIndex(object, index)
	end)
	

	originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local protectedErrorMessage = protectedObjects[self]
		if protectedErrorMessage then
		if protectedObjects[self] then
			return originalNamecall(SafeObject, ...)
		end
		return originalNamecall(self, ...)
	end)
	
	function HookManager.ProtectObject(object: Instance): (nil)

	function HookManager.ProtectObject(object: Instance)
		assert(object, `ProtectObject -> Instance expeted, got {typeof(object)}`)
		
		object.Name = SafeObject.Name
		protectedObjects[object] = true
		protectedObjects[object] = cloneObject(SafeObject)
	end
	
	function HookManager.UnprotectObject(object: Instance): (nil)
		protectedObjects[object] = nil

	function HookManager.UnprotectObject(object: Instance)
		if HookManager.IsProtected(object) then return end
		assert(object, `UnprotectObject -> Instance expeted, got {typeof(object)}`)
		
		local safeObject = protectedObjects[object]
		if safeObject then
			protectedObjects[object] = nil
			safeObject:Destroy()
		end
	end
	

	function HookManager.IsProtected(object: Instance): boolean
		return protectedObjects[object] ~= nil
	end
	
	function HookManager.HookProperty(object: Instance, property: string, value: any?): (nil)

	function HookManager.HookProperty(object: Instance, property: string, value: any?)
		if not hookedProperties[object] then
			hookedProperties[object] = {}
		end
		
		hookedProperties[object][property] = value
	end
	
	function HookManager.UnhookProperty(object: Instance, property: string): (nil)
		if hookedProperties[object] then
			hookedProperties[object][property] = nil

	function HookManager.UnhookProperty(object: Instance, property: string)
		local hooked = hookedProperties[object]
		if hooked then
			hooked[property] = nil

			if next(hookedProperties[object]) == nil then
			if next(hooked) == nil then
				hookedProperties[object] = nil
			end
		end
	end

	function HookManager.SetCanTouchObjects(list)
		noclipProperties.CanTouch = list
	end

	function HookManager.SetCanCollideObjects(list)
		noclipProperties.CanCollide = list
	end
	
	function HookManager.ClearNoclipObjects()
		table.clear(noclipObjects)
	end
	
	function HookManager.AddNoclipObject(object: Instance)
		noclipObjects[object] = true
	end

	function HookManager.Clear()
		table.clear(protectedObjects)
		table.clear(hookedProperties)
		HookManager.ClearNoclipObjects()
	end

	HookManager.OriginalIndex = originalIndex
@@ -148,30 +184,22 @@ local function getHookManager()
	return HookManager
end

if not _ENV.rz_hook_manager then
	_ENV.rz_hook_manager = getHookManager()
end

local HookManager = _ENV.rz_hook_manager
HookManager.Clear()

local WaitSeconds = nil;
local HookManager = (function()
	local manager = _ENV.rz_hook_manager or NewHookManager()
	_ENV.rz_hook_manager = manager
	return manager
end)()

local HIDDEN_SETTINGS: { [string]: any } = {
	SKILL_COOLDOWN = 0.5,
	CLEAR_AFTER = 50,

	SILENT_AIM_ENABLED = true,
	WALKSPEED_BYPASS_ENABLED = true
	WALKSPEED_BYPASS_ENABLED = true,
}

_ENV._Bring_Tag = BRING_TAG
_ENV._KillAura_Tag = KILLAURA_TAG

local HitboxLimbs = {"RightLowerArm", "RightUpperArm", "LeftLowerArm", "LeftUpperArm", "RightHand", "LeftHand"};

local function GetEnemyName(string: string): string
	return (string:find("Lv. ") and string:gsub(" %pLv. %d+%p", "") or string):gsub(" %pBoss%p", "")
local function GetEnemyName(text: string): string
	return text:gsub(if text:find("Lv. ") then " %pLv. %d+%p" else " %pBoss%p", "")
end

local function CheckPlayerAlly(__Player: Player): boolean
@@ -188,22 +216,6 @@ local function CheckPlayerAlly(__Player: Player): boolean
	return true
end

local function WaitChilds(Instance: Instance, ...): Instance?
	for _, Children: string in {...} do
		Instance = if Instance then Instance:WaitForChild(Children, WaitSeconds) else nil
	end
	
	return Instance
end

local function FastWait(Seconds: number, Instance: Instance, ...): Instance?
	WaitSeconds = if type(Seconds) == "number" then Seconds else nil
	local Success, _Instance = pcall(WaitChilds, Instance, ...)
	WaitSeconds = nil
	
	return if Success then _Instance else nil
end

local function CreateNewClear()
	local COUNT_NEWINDEX = 0

@@ -224,14 +236,8 @@ local function CreateNewClear()
	}
end

function CreateDictionary(array: { string? }, value: any?): { [string]: any? }
	local Dictionary = {}
	
	for _, string in ipairs(array) do
		Dictionary[string] = if type(value) == "table" then {} else value
	end
	
	return Dictionary
local function CreateDefaultDictionary(Value: any?): table
	return setmetatable({}, { __index = function() return Value end })
end

local HumanoidsCache do
@@ -252,11 +258,14 @@ local function GetHuamnoidHealth(Humanoid: Humanoid): number
	return Humanoid[if Humanoid.ClassName == "Humanoid" then "Health" else "Value"]
end

local function DistanceFromCharacter(Value: CFrame | BasePart): number
	return Player:DistanceFromCharacter(Value.Position)
local function DistanceFromCharacter(Value: CFrame | BasePart | Vector3): number
	if typeof(Value) ~= "Vector3" then
		Value = Value.Position
	end
	return Player:DistanceFromCharacter(Value)
end

local function IsAlive(Character, _Humanoid)
local function IsAlive(Character: Model, _Humanoid: Humanoid): boolean
	if _Humanoid then
		return GetHuamnoidHealth(_Humanoid) > 0
	elseif Character then
@@ -268,1167 +277,660 @@ local function IsAlive(Character, _Humanoid)
			return Character.Parent == Boats
		end
	end
	
	return false
end

local function NewErrorMessage(Message)
	-- local CoreGui = gethui and gethui() or game:GetService("CoreGui")
	
	return error(Message, 2)
end

local function ConvertVersionToNumber(Version: string): number
	local CurrentVersion;
	
	for Number in string.gmatch(string.sub(Version, 2, -1), "[^%.]+") do
		if not CurrentVersion then
			CurrentVersion = `{ Number }.`
		else
			CurrentVersion ..= Number
		end
	end
	
	return tonumber(CurrentVersion) or 0
end

local function NewConnection(Event: RBX, Action): (nil)
	table.insert(Connections, Event:Connect(Action))
end

local function FireRemote(...)
	return CommF:InvokeServer(...)
local function NewCollection(Tag: string): { Instance }
	local Objects = CollectionService:GetTagged(Tag)
	
	NewConnection(CollectionService:GetInstanceAddedSignal(Tag), function(Object)
		table.insert(Objects, Object)
	end)
	
	return Objects
end

local function GetRandomHitboxLimb(Character)
local function GetRandomHitboxLimb(Character: Model): BasePart?
	return Character:FindFirstChild(HitboxLimbs[math.random(#HitboxLimbs)])
end

local Signal = {} do
	local Connection = {} do
		Connection.__index = Connection
		
		function Connection:Disconnect(): (nil)
			if not self.Connected then
				return nil
			end
			
			local find = table.find(self.Signal, self)
			
			if find then
				table.remove(self.Signal, find)
			end
			
			self.Function = nil
			self.Connected = false
		end
		
		function Connection:Fire(...): (nil)
			if not self.Function then
				return nil
			end
			
			task.spawn(self.Function, ...)
		end
		
		function Connection.new(): Connection
			return setmetatable({
				Connected = true
			}, Connection)
		end
		
		setmetatable(Connection, {
			__index = function(self, index)
				error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(index)), 2)
			end,
			__newindex = function(tb, key, value)
				error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
			end
		})
local function CharacterEquipTool(Tool: Tool): boolean
	--[[if Tool:GetAttribute("Locks") then
		Tool:SetAttribute("Locks", nil)
	end]]
	
	if Tool.Parent == Player.Character then
		return true
	elseif Tool.Parent == Player.Backpack then
		Player.Character.Humanoid:EquipTool(Tool)
		return true
	end
	
	return false
end

local function EquipTool(ToolName: string, ByType: boolean?): (nil)
	if not IsAlive(Player.Character) then
		return nil
	end

	Signal.__index = Signal
	ByType = ByType or not ToolName
	ToolName = ToolName or Settings.FarmTool
	
	local Equipped = Cached.Equipped

	function Signal:Connect(Function): Connection
		if type(Function) ~= "function" then
	if Equipped and Equipped.Parent and Equipped[if ByType then "ToolTip" else "Name"] == ToolName then
		if CharacterEquipTool(Equipped) then
			return nil
		end
	end
	
	if ToolName and not ByType then
		local OnInventory = Player.Backpack:FindFirstChild(ToolName)

		local NewConnection = Connection.new()
		NewConnection.Function = Function
		NewConnection.Signal = self
		if OnInventory then
			Cached.Equipped = OnInventory
			CharacterEquipTool(OnInventory)
		end

		table.insert(self.Connections, NewConnection)
		return NewConnection
		return nil
	end

	function Signal:Once(Function): (nil)
		local Connection;
		Connection = self:Connect(function(...)
			Function(...)
			Connection:Disconnect()
		end)
		return Connection
	for _, Tool in Player.Backpack:GetChildren() do
		if Tool:IsA("Tool") and Tool.ToolTip == ToolName then
			Cached.Equipped = Tool
			CharacterEquipTool(Tool)
			return nil
		end
	end
end

local Cached = {
	Closest = nil,
	Equipped = nil,

	function Signal:Wait(): any?
		local WaitingCoroutine = coroutine.running()
		local Connection;Connection = self:Connect(function(...)
			Connection:Disconnect()
			task.spawn(WaitingCoroutine, ...)
		end)
		return coroutine.yield()
	end
	RealFruitsName = setmetatable({}, CreateNewClear()),
	RealFruitsId = setmetatable({}, CreateNewClear()),

	function Signal:Fire(...): (nil)
		for _, Connection in ipairs(self.Connections) do
			if Connection.Connected then
				Connection:Fire(...)
			end
		end
	end
	Enemies = {}, -- setmetatable({}, CreateNewClear()),
	Progress = {},
	Bring = {},
	Tools = {}
}

local GameData = {
	Sea = table.find({2753915549, 4442272183, 7449423635}, game.PlaceId) or 0,
	SeasName = { "Main", "Dressrosa", "Zou" },
	MaxMastery = 600,
	MaxLevel = 2650
}

GameData.StringVersion = Obfuscated.GetGameVersion(NewErrorMessage)
GameData.NumberVersion = ConvertVersionToNumber(GameData.StringVersion)

do
	if string.sub(GameData.StringVersion, 1, 1) ~= "v" then return Player:Kick() end
	
	local SplitVersion = string.split(string.sub(GameData.StringVersion, 2, -1), ".")
	local CurrentVersion = `{ SplitVersion[1] or 0 }.`;

	function Signal.new(): Signal
		return setmetatable({
			Connections = {}
		}, Signal)
	for i = 2, #SplitVersion do
		CurrentVersion ..= tostring(SplitVersion[i] or 0)
	end

	setmetatable(Signal, {
		__index = function(self, index)
			error(`Attempt to get Signal::{ tostring(index) } (not a valid member)`, 2)
		end,
		__newindex = function(self, index, value)
			error(`Attempt to set Signal::{ tostring(index) } (not a valid member)`, 2)
		end
	})
	GameData.NumberVersion =  tonumber(CurrentVersion) or 0
end

local Module = {} do
	Module.HookManager = HookManager
	
	local Cached = {
		Closest = nil,
		Equipped = nil,
		RealFruitsName = setmetatable({}, CreateNewClear()),
		RealFruitsId = setmetatable({}, CreateNewClear()),
		Enemies = {}, -- setmetatable({}, CreateNewClear()),
		Progress = {},
		Bring = {},
		Tools = {}
	}
local Module = {
	IsAlive = IsAlive,
	GameData = GameData,
	HookManager = HookManager,
	NewConnection = NewConnection,
	DistanceFromCharacter = DistanceFromCharacter
}

Module.CollectionService = (function()
	local CollectionObjects = {}

	local Debounces = {
		TargetDebounce = 0,
		UpdateDebounce = 0,
		GetEnemy = 0,
		Skills = {}
	}
	local Chests = NewCollection("_ChestTagged")
	local Berries = NewCollection("BerryBush")

	Module.GameData = {
		Sea = ({ [2753915549] = 1, [4442272183] = 2, [7449423635] = 3 })[game.PlaceId] or 0;
		SeasName = { "Main", "Dressrosa", "Zou" };
		MaxMastery = 600;
		MaxLevel = 2650;
		
		StringVersion = require(ReplicatedStorage.BuildInfo).VERSION;
	}
	local GetChestDebounce, CachedChest = 0;
	local GetBerryDebounce, CachedBerry = 0;
	
	CollectionObjects.Chests = Chests
	CollectionObjects.Berries = Berries
	
	local function CanCollectChest(Chest)
		return Chest and not Chest:GetAttribute("IsDisabled")
	end
	
	local function HasBerries(Bush)
		return if next(Bush:GetAttributes()) then true else false
	end

	Module.GameData.NumberVersion = (function()
		local SplitVersion = string.split(string.sub(Module.GameData.StringVersion, 2, -1), ".")
		local CurrentVersion = `{ SplitVersion[1] or 0 }.`;
	local function GetClosestChest(SelectedIsland)
		if CanCollectChest(CachedChest) and (not SelectedIsland or CachedChest:IsDescendantOf(SelectedIsland)) then
			return CachedChest
		elseif (tick() - GetChestDebounce) < 1 then
			return nil
		end
		
		local Distance, Closest = math.huge

		for i = 2, #SplitVersion do
			CurrentVersion ..= tostring(SplitVersion[i] or 0)
		for i = 1, #Chests do
			local Chest = Chests[i]
			if CanCollectChest(Chest) and (not SelectedIsland or CachedChest:IsDescendantOf(SelectedIsland)) then
				local Magnitude = Player:DistanceFromCharacter(Chest:GetPivot().Position)
				
				if Magnitude < Distance then
					Magnitude, Closest = Distance, Chest
				end
			end
		end

		return tonumber(CurrentVersion) or 0
	end)()
		GetChestDebounce = tick()
		CachedChest = Closest
		
		return Closest
	end

	do
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
	local function GetClosestBerry()
		if HasBerries(CachedBerry) and CachedBerry:IsDescendantOf(Map) then
			return CachedBerry
		elseif (tick() - GetBerryDebounce) < 1 then
			return nil
		end

		Module.Bosses = {
			-- Bosses Sea 1
			["Saber Expert"] = {
				NoQuest = true,
				Position = CFrame.new(-1461, 30, -51)
			},
			["The Saw"] = {
				RaidBoss = true,
				Position = CFrame.new(-690, 15, 1583)
			},
			["Greybeard"] = {
				RaidBoss = true,
				Position = CFrame.new(-5043, 25, 4262)
			},
			["The Gorilla King"] = {
				IsBoss = true,
				Level = 20,
				Position = CFrame.new(-1128, 6, -451),
				Quest = {"JungleQuest", CFrame.new(-1598, 37, 153)}
			},
			["Chef"] = {
				IsBoss = true,
				Level = 55,
				Position = CFrame.new(-1131, 14, 4080),
				Quest = {"BuggyQuest1", CFrame.new(-1140, 4, 3829)}
			},
			["Yeti"] = {
				IsBoss = true,
				Level = 105,
				Position = CFrame.new(1185, 106, -1518),
				Quest = {"SnowQuest", CFrame.new(1385, 87, -1298)}
			},
			["Vice Admiral"] = {
				IsBoss = true,
				Level = 130,
				Position = CFrame.new(-4807, 21, 4360),
				Quest = {"MarineQuest2", CFrame.new(-5035, 29, 4326), 2}
			},
			["Swan"] = {
				IsBoss = true,
				Level = 240,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692)}
			},
			["Chief Warden"] = {
				IsBoss = true,
				Level = 230,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 2}
			},
			["Warden"] = {
				IsBoss = true,
				Level = 220,
				Position = CFrame.new(5230, 4, 749),
				Quest = {"ImpelQuest", CFrame.new(5191, 4, 692), 1}
			},
			["Magma Admiral"] = {
				IsBoss = true,
				Level = 350,
				Position = CFrame.new(-5694, 18, 8735),
				Quest = {"MagmaQuest", CFrame.new(-5319, 12, 8515)}
			},
			["Fishman Lord"] = {
				IsBoss = true,
				Level = 425,
				Position = CFrame.new(61350, 31, 1095),
				Quest = {"FishmanQuest", CFrame.new(61122, 18, 1567)}
			},
			["Wysper"] = {
				IsBoss = true,
				Level = 500,
				Position = CFrame.new(-7927, 5551, -637),
				Quest = {"SkyExp1Quest", CFrame.new(-7861, 5545, -381)}
			},
			["Thunder God"] = {
				IsBoss = true,
				Level = 575,
				Position = CFrame.new(-7751, 5607, -2315),
				Quest = {"SkyExp2Quest", CFrame.new(-7903, 5636, -1412)}
			},
			["Cyborg"] = {
				IsBoss = true,
				Level = 675,
				Position = CFrame.new(6138, 10, 3939),
				Quest = {"FountainQuest", CFrame.new(5258, 39, 4052)}
			},
			
			-- Bosses Sea 2
			["Don Swan"] = {
				RaidBoss = true,
				Position = CFrame.new(2289, 15, 808)
			},
			["Cursed Captain"] = {
				RaidBoss = true,
				Position = CFrame.new(912, 186, 33591)
			},
			["Darkbeard"] = {
				RaidBoss = true,
				Position = CFrame.new(3695, 13, -3599)
			},
			["Diamond"] = {
				IsBoss = true,
				Level = 750,
				Position = CFrame.new(-1569, 199, -31),
				Quest = {"Area1Quest", CFrame.new(-427, 73, 1835)}
			},
			["Jeremy"] = {
				IsBoss = true,
				Level = 850,
				Position = CFrame.new(2316, 449, 787),
				Quest = {"Area2Quest", CFrame.new(635, 73, 919)}
			},
			["Orbitus"] = {
				IsBoss = true,
				Level = 925,
				Position = CFrame.new(-2086, 73, -4208),
				Quest = {"MarineQuest3", CFrame.new(-2441, 73, -3219)}
			},
			["Smoke Admiral"] = {
				IsBoss = true,
				Level = 1150,
				Position = CFrame.new(-5078, 24, -5352),
				Quest = {"IceSideQuest", CFrame.new(-6061, 16, -4904)}
			},
			["Awakened Ice Admiral"] = {
				IsBoss = true,
				Level = 1400,
				Position = CFrame.new(6473, 297, -6944),
				Quest = {"FrostQuest", CFrame.new(5668, 28, -6484)}
			},
			["Tide Keeper"] = {
				IsBoss = true,
				Level = 1475,
				Position = CFrame.new(-3711, 77, -11469),
				Quest = {"ForgottenQuest", CFrame.new(-3056, 240, -10145)}
			},
		local Distance, Closest = math.huge
		
		for i = 1, #Berries do
			local Bush = Berries[i]

			-- Bosses Sea 3
			["Tyrant of the Skies"] = {
				RaidBoss = true,
				Position = CFrame.new(-16252, 153, 1394)
			},
			["Cake Prince"] = {
				RaidBoss = true,
				Position = CFrame.new(-2103, 70, -12165)
			},
			["Dough King"] = {
				RaidBoss = true,
				Position = CFrame.new(-2103, 70, -12165)
			},
			["rip_indra True Form"] = {
				RaidBoss = true,
				Position = CFrame.new(-5333, 424, -2673)
			},
			["Stone"] = {
				IsBoss = true,
				Level = 1550,
				Position = CFrame.new(-1049, 40, 6791),
				Quest = {"PiratePortQuest", CFrame.new(-449, 109, 5950)}
			},
			["Hydra Leader"] = {
				IsBoss = true,
				Level = 1675,
				Position = CFrame.new(5836, 1019, -83),
				Quest = {"VenomCrewQuest", CFrame.new(5214, 1004, 761)}
			},
			["Kilo Admiral"] = {
				IsBoss = true,
				Level = 1750,
				Position = CFrame.new(2904, 509, -7349),
				Quest = {"MarineTreeIsland", CFrame.new(2485, 74, -6788)}
			},
			["Captain Elephant"] = {
				IsBoss = true,
				Level = 1875,
				Position = CFrame.new(-13393, 319, -8423),
				Quest = {"DeepForestIsland", CFrame.new(-13233, 332, -7626)}
			},
			["Beautiful Pirate"] = {
				IsBoss = true,
				Level = 1950,
				Position = CFrame.new(5370, 22, -89),
				Quest = {"DeepForestIsland2", CFrame.new(-12682, 391, -9901)}
			},
			["Cake Queen"] = {
				IsBoss = true,
				Level = 2175,
				Position = CFrame.new(-710, 382, -11150),
				Quest = {"IceCreamIslandQuest", CFrame.new(-818, 66, -10964)}
			},
			["Longma"] = {
				NoQuest = true,
				Position = CFrame.new(-10218, 333, -9444)
			}
		}
			if HasBerries(Bush) then
				local Magnitude = Player:DistanceFromCharacter(Bush.Parent:GetPivot().Position)
				
				if Magnitude < Distance then
					Magnitude, Closest = Distance, Bush
				end
			end
		end

		Module.Shop = {
			{"Frags", {{"Race Reroll", {"BlackbeardReward", "Reroll", "2"}}, {"Reset Stats", {"BlackbeardReward", "Refund", "2"}}}},
			{"Fighting Style", {
				{"Buy Black Leg", {"BuyBlackLeg"}},
				{"Buy Electro", {"BuyElectro"}},
				{"Buy Fishman Karate", {"BuyFishmanKarate"}},
				{"Buy Dragon Claw", {"BlackbeardReward", "DragonClaw", "2"}},
				{"Buy Superhuman", {"BuySuperhuman"}},
				{"Buy Death Step", {"BuyDeathStep"}},
				{"Buy Sharkman Karate", {"BuySharkmanKarate"}},
				{"Buy Electric Claw", {"BuyElectricClaw"}},
				{"Buy Dragon Talon", {"BuyDragonTalon"}},
				{"Buy GodHuman", {"BuyGodhuman"}},
				{"Buy Sanguine Art", {"BuySanguineArt"}}
				-- {"Buy Divine Art", {"BuyDivineArt"}}
			}},
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
				{"Buy Tomoe Ring", {"BuyItem", "Tomoe Ring"}}
			}},
			{"Race", {{"Ghoul Race", {"Ectoplasm", "Change", 4}}, {"Cyborg Race", {"CyborgTrainer", "Buy"}}}}
		}
		GetBerryDebounce = tick()
		CachedBerry = Closest
		
		return Closest
	end

	do
		Module.IsSuperBring = false;
	Module.GetClosestChest = GetClosestChest;
	Module.GetClosestBerry = GetClosestBerry;
	Module.HasBerries = HasBerries;
	
	return CollectionObjects
end)()

Module.Services = (function()
	local Services = {}
	
	Services.Network = (function()
		local Network = {}

		Module.RemoveCanTouch = 0;
		Module.AttackCooldown = 0;
		Module.PirateRaid = 0;
		local InvokeServer = CommF.InvokeServer;

		Module.Webhooks = true;
		Module.JobIds = true;
		local RF_TAG = "RF/%s";
		local RE_TAG = "RE/%s";

		Module.Progress = {};
		Module.EnemyLocations = {};
		Module.SpawnLocations = {};
		function Network.InvokeCommF(...)
			return InvokeServer(CommF, ...)
		end

		Module.Cached = Cached;
		-- Module.Debounce = Debounce
		Module.IsAlive = IsAlive;
		Module.FireRemote = FireRemote;
	end
	
	Module.Signals = {} do
		local Signals = Module.Signals
		function Network:RemoteFunction(RemoteName)
			return Net:WaitForChild(RF_TAG:format(RemoteName))
		end

		Signals.PossibleStaff = Signal.new()
		Signals.OptionChanged = Signal.new()
		Signals.EnemyAdded = Signal.new()
		Signals.EnemyDied = Signal.new()
		Signals.Notify = Signal.new()
		Signals.Error = Signal.new()

		Signals.Error:Connect(function(ErrorMessage)
			_ENV.loadedFarm = false
			_ENV.OnFarm = false
			
			local text = (`redz-Hub error [ {Settings.RunningOption or "Null"} ] {ErrorMessage}`)
			
			if _ENV.rz_error_message then
				_ENV.rz_error_message.Text ..= `\n\n{ text }`
				return nil
			end
			
			local Message = Instance.new("Message", workspace)
			_ENV.rz_error_message = Message
			Message.Text = text
		end)
	end
		function Network:RemoteEvent(RemoteName)
			return Net:WaitForChild(RE_TAG:format(RemoteName))
		end
		
		return Network
	end)()

	Module.RunFunctions = {} do
		Module.RunFunctions.TweenModule = function()
			local module = {}
			module.__index = module
			
			local TweenService = game:GetService("TweenService")
			
			local tweens = {}
			local EasingStyle = Enum.EasingStyle.Linear
			
			function module.new(obj, time, prop, value)
				local self = setmetatable({}, module)
	Services.GoodSignal = (function()
		local Signal = {}
		local Connection = {}
		
		Connection.__index = Connection
		Signal.__index = Signal
		
		do
			function Connection:Disconnect(): (nil)
				if not self.Connected then
					return nil
				end

				self.tween = TweenService:Create(obj, TweenInfo.new(time, EasingStyle), { [prop] = value })
				self.tween:Play()
				self.value = value
				self.object = obj
				local find = table.find(self.Signal, self)

				if tweens[obj] then
					tweens[obj]:destroy()
				if find then
					table.remove(self.Signal, find)
				end

				tweens[obj] = self
				return self
				self.Function = nil
				self.Connected = false
			end

			function module:destroy()
				self.tween:Pause()
				self.tween:Destroy()
			function Connection:Fire(...): (nil)
				if not self.Function then
					return nil
				end

				tweens[self.object] = nil
				setmetatable(self, nil)
				task.spawn(self.Function, ...)
			end

			function module:stopTween(obj)
				if obj and tweens[obj] then
					tweens[obj]:destroy()
				end
			function Connection.new(): Connection
				return setmetatable({
					Connected = true
				}, Connection)
			end

			return module
			setmetatable(Connection, {
				__index = function(self, index)
					error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(index)), 2)
				end,
				__newindex = function(tb, key, value)
					error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
				end
			})
		end

		Module.RunFunctions.Translator = function(Window, Translation)
			local MakeTab = Window.MakeTab
		function Signal:Connect(Function): Connection
			assert(type(Function) == "function", "function expected, got " .. type(Function))

			Window.MakeTab = function(self, Configs)
				if Translation[ Configs[1] ] then
					Configs[1] = Translation[ Configs[1] ]
				end
				
				local Tab = MakeTab(self, Configs)
				local NewTab = {}
				
				function NewTab:AddSection(Name)
					return Tab:AddSection(Translation[Name] or Name)
				end
				
				function NewTab:AddButton(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddButton(Configs)
			local NewConnection = Connection.new()
			NewConnection.Function = Function
			NewConnection.Signal = self
			
			table.insert(self.Connections, NewConnection)
			return NewConnection
		end
		
		function Signal:Once(Function): (nil)
			local Connection;
			Connection = self:Connect(function(...)
				Function(...)
				Connection:Disconnect()
			end)
			return Connection
		end
		
		function Signal:Wait(): any?
			local WaitingCoroutine = coroutine.running()
			local Connection;Connection = self:Connect(function(...)
				Connection:Disconnect()
				task.spawn(WaitingCoroutine, ...)
			end)
			return coroutine.yield()
		end
		
		function Signal:Fire(...): (nil)
			for _, Connection in ipairs(self.Connections) do
				if Connection.Connected then
					Connection:Fire(...)
				end
				
				function NewTab:AddToggle(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddToggle(Configs)
				end
				
				function NewTab:AddSlider(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddSlider(Configs)
				end
				
				function NewTab:AddDropdown(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddDropdown(Configs)
				end
				
				function NewTab:AddTextBox(Configs)
					local Translator = Translation[ Configs[1] ]
					
					if Translator then
						Configs[1] = type(Translator) == "string" and Translator or Translator[1]
						Configs.Desc = type(Translator) ~= "string" and Translator[2]
					end
					
					return Tab:AddTextBox(Configs)
				end
				
				for i,v in pairs(Tab) do
					if not NewTab[i] then
						NewTab[i] = v
					end
				end
				
				return NewTab
			end
		end

		Module.RunFunctions.Quests = function(self, QuestsModule, getTasks)
			local MaxLvl = ({ {0, 700}, {700, 1500}, {1500, math.huge} })[self.Sea]
			local bl_Quests = {"BartiloQuest", "MarineQuest", "CitizenQuest"}
			
			for name, task in QuestsModule do
				if table.find(bl_Quests, name) then continue end
				
				for num, mission in task do
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
			end
			
			table.sort(self.QuestList, function(v1, v2) return v1.Enemy.Level < v2.Enemy.Level end)
		function Signal.new(): Signal
			return setmetatable({
				Connections = {}
			}, Signal)
		end

		Module.RunFunctions.LibraryToggle = function(EnabledOptions, Options)
			return function(...)
				local Tab, Settings, Flag = ...
				
				Options[Flag] = Tab:AddToggle({
					Settings[1],																				 -- Name
					type(Settings[2]) ~= "string" and Settings[2],			 -- Default
					function(Value) EnabledOptions[Flag] = Value end,		-- Callback
					Flag,																								-- Flag
					Desc = (type(Settings[2]) == "string" and Settings[2]) or Settings[3]
				})
			end
		end
		
		Module.RunFunctions.FarmQueue = function(Options)
			local Success, ErrorMessage = pcall(function()
				local function GetQueue()
					for _, Option in Options do
						Settings.RunningOption = Option.Name
						local Method = Option.Function()
						
						if Method then
							if type(Method) == "string" then
								Settings.RunningMethod = Method
							end
							return Method
						end
					end
					
					Settings.RunningOption, Settings.RunningMethod = nil, nil
				end
				
				while task.wait(Settings.SmoothMode and 0.25 or 0) do
					if _ENV.teleporting then
						_ENV.OnFarm = true
					elseif Settings.FixOverflow then
						local Success, Response = pcall(GetQueue)
						
						_ENV.OnFarm = (not Success and _ENV.OnFarm) or Response
					else
						_ENV.OnFarm = if GetQueue() then true else false
					end
				end
			end)
			
			Module.Signals.Error:Fire(ErrorMessage)
		end
	end
		Signal.Signals = {
			BvChanged = Signal.new(),
			Notify = Signal.new(),
			Error = Signal.new(),
		}
		
		setmetatable(Signal, {
			__index = function(self, index)
				error(`Attempt to get Signal::{ tostring(index) } (not a valid member)`, 2)
			end,
			__newindex = function(self, index, value)
				error(`Attempt to set Signal::{ tostring(index) } (not a valid member)`, 2)
			end
		})
		
		return Signal
	end)()

	function Module.KillAura(Distance: number?, Name: string?): (nil)
		Distance = Distance or 500
	Services.PlayerManager = (function()
		local Manager = {
			RootPartPosition = Vector3.zero
		}

		local EnemyList = Enemies:GetChildren()
		local PlayerCharacter = Player.Character

		for i = 1, #EnemyList do
			local Enemy = EnemyList[i]
			local PrimaryPart = Enemy.PrimaryPart
			
			if (not Name or Enemy.Name == Name) and PrimaryPart and not Enemy:HasTag(KILLAURA_TAG) then
				if IsAlive(Enemy) and Player:DistanceFromCharacter(PrimaryPart.Position) < Distance then
					Enemy:AddTag(KILLAURA_TAG)
				end
		function Manager:CheckIsAlive()
			if not IsAlive(PlayerCharacter) then
				PlayerCharacter = nil
				return false
			end
		end
	end
	
	function Module.IsBoss(Name: string): boolean
		return Module.Bosses[Name] and true or false
	end
	
	function Module.UseSkills(Target: any?, Skills: table?): (nil)
		if Player:DistanceFromCharacter(Target.Position) >= 60 then
			return nil
			
			return true
		end

		local Equipped = Player.Character and Player.Character:FindFirstChildOfClass("Tool")
		local MasteryRequirements = Module.Inventory.MasteryRequirements
		function Manager:GetCharacter()
			return self:CheckIsAlive() and PlayerCharacter
		end

		if Equipped then
			local Level = Equipped:GetAttribute("Level") or 0
			local Mastery = MasteryRequirements[Equipped.Name]
			
			if Mastery == nil and Equipped:FindFirstChild("Data") then
				local Success, Requirements = pcall(require, Equipped.Data)
		function Manager:GetRootPartPosition()
			if self:CheckIsAlive() then
				local RootPart = PlayerCharacter.Humanoid.RootPart

				if Success and type(Requirements) == "table" then
					MasteryRequirements[Equipped.Name] = Requirements.Lvl or false
				else
					MasteryRequirements[Equipped.Name] = false
				if RootPart then
					local Position = RootPart.Position
					self.RootPartPosition = Position
					return Position
				end
			end

			for Skill, Enabled in Skills do
				if Mastery and not Mastery[Skill] then continue end
				if Mastery and Level < Mastery[Skill] then continue end
				
				local Debounce = Debounces.Skills[Skill]
				
				if Enabled and (not Debounce or (tick() - Debounce) >= HIDDEN_SETTINGS.SKILL_COOLDOWN) then
					VirtualInputManager:SendKeyEvent(true, Skill, false, game)
					VirtualInputManager:SendKeyEvent(false, Skill, false, game)
					Debounces.Skills[Skill] = tick()
				end
			end
		end
	end
	
	function Module.Rejoin(): (nil)
		if IsPrivateServer or #Players:GetPlayers() == 1 then
			TeleportService:Teleport(game.PlaceId, Player)
		else
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
			return self.RootPartPosition
		end
	end
	
	function Module.EnemySpawned(EnemyName)
		local Enemies = Module.Enemies
		return if type(EnemyName) == "table" then Enemies:GetClosest(EnemyName) else Enemies:GetEnemyByTag(EnemyName)
	end
	
	function Module:IsBlacklistedExecutor(): boolean
		return if IS_BLACKLISTED_EXECUTOR then true else false
	end
	
	function Module:TravelTo(Sea: number?): (nil)
		return FireRemote(`Travel{ self.GameData.SeasName[Sea] }`)
	end
	
	function Module:ServerHop(MaxPlayers: number?, Region: string?): (nil)
		self.RejoinBlocked = true -- bloqueia o Auto Rejoin

		MaxPlayers = math.min(MaxPlayers or self.SH_MaxPlrs or 8, 11)
		-- Region = Region or self.SH_Region or "Singapore"
		NewConnection(Player.CharacterAdded, function(...) PlayerCharacter = ... end)
		NewConnection(Player.CharacterRemoving, function() PlayerCharacter = nil end)

		local ServerBrowser = ReplicatedStorage.__ServerBrowser; -- o evento que gerência tudo relacionado a "servidores"
		local InvokeServer = ServerBrowser.InvokeServer; -- armazena a função de "InvokeServer" para otimizar
		local MyJobId = game.JobId; -- armazena o JobId do server atual, também para otimizar o loop
		local CurrentPage = 1; -- a "página" atual de servidores ServerBrowser:InvokeServer(1. 2. 3...)
		return Manager
	end)()
	
	Services.Inventory = (function()
		local Inventory = {
			Unlocked = CreateDefaultDictionary(false),
			Mastery = CreateDefaultDictionary(0),
			Count = CreateDefaultDictionary(0),
			MasteryRequirements = {},
			Items = {}
		}

		local function nextPage()
			local Success, Servers = pcall(InvokeServer, ServerBrowser, CurrentPage) -- retorna a lista de servidores da página atual
			CurrentPage += 1
			
			if Success ~= true then return end
			if type(Servers) ~= "table" then return end
			
			local lowServerCount, lowServerId = MaxPlayers;
		local NotificationSignal = Services.GoodSignal.Signals.Notify
		
		local function ItemUpdated(self, NewItemData)
			if type(NewItemData) ~= "table" then return end
			if NewItemData.Type == "Wear" then NewItemData.Type = "Acessory" end

			for id, data in Servers do
				if id ~= MyJobId and data.Count <= lowServerCount then
					lowServerCount, lowServerId = data.Count, id;
				end
			end
			local ItemName = NewItemData.Name
			self.Items[ItemName] = NewItemData

			if lowServerId then
				TeleportService:TeleportToPlaceInstance(game.PlaceId, lowServerId, Player)
			end
		end
		
		for index = 1, 100 do
			task.delay(index / 50, nextPage)
			if not self.Unlocked[ItemName] then self.Unlocked[ItemName] = true end
			if NewItemData.Count then self.Count[ItemName] = NewItemData.Count end
			if NewItemData.Mastery then self.Mastery[ItemName] = NewItemData.Mastery end
			if NewItemData.MasteryRequirements then self.MasteryRequirements[ItemName] = NewItemData.MasteryRequirements end
		end
	end
	
	function Module.EquipTool(ToolName: string, ByType: boolean?): (nil)
		ByType = if not ToolName then true else ByType
		ToolName = ToolName or Settings.FarmTool

		if not IsAlive(Player.Character) then
			return nil
		local function ItemRemoved(self, ItemName)
			if type(ItemName) == "string" then
				self.MasteryRequirements[ItemName] = nil
				self.Unlocked[ItemName] = nil
				self.Mastery[ItemName] = nil
				self.Count[ItemName] = nil
				self.Items[ItemName] = nil
			end
		end

		local Equipped = Cached.Equipped
		local Methods = {
			["ItemChanged"] = function(...) ItemUpdated(Inventory, ...) end;
			["ItemAdded"] = function(...) ItemUpdated(Inventory, ...) end;
			["ItemRemoved"] = function(...) ItemRemoved(Inventory, ...) end;
			["Notify"] = function(...) NotificationSignal:Fire(...) end;
		}

		if Equipped and Equipped.Parent and Equipped[if ByType then "ToolTip" else "Name"] == ToolName then
			if Equipped:GetAttribute("Locks") then
				Equipped:SetAttribute("Locks", nil)
			end
			
			if Equipped.Parent == Player.Character then
				return nil
			elseif Equipped.Parent == Player.Backpack then
				Player.Character.Humanoid:EquipTool(Equipped)
				return nil
		local function OnClientEvent(Method, ...)
			if Method and Methods[Method] then
				Methods[Method](...)
			end
		end

		if ToolName and not ByType then
			local BackpackTool = Player.Backpack:FindFirstChild(ToolName)
			
			if BackpackTool then
				Cached.Equipped = BackpackTool
				Player.Character.Humanoid:EquipTool(BackpackTool)
			end
		else
			for _, Tool in Player.Backpack:GetChildren() do
				if Tool:IsA("Tool") and Tool.ToolTip == ToolName then
					Cached.Equipped = Tool
					Player.Character.Humanoid:EquipTool(Tool)
					return nil
				end
			end
		local function GetInventory()
			return Services.Network.InvokeCommF("getInventory")
		end
	end
	
	function Module:BringEnemies(ToEnemy: Instance, SuperBring: boolean?, CustomCFrame: CFrame?, Distance: number?): (nil)
		if not IsAlive(ToEnemy) or not ToEnemy.PrimaryPart then
			return nil
		end
		
		pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)

		if Distance or Settings.BringMobs then
			Module.IsSuperBring = if SuperBring then true else false
			
			local Name = ToEnemy.Name
			local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
			local BringPositionTag = if SuperBring then "ALL_MOBS" else Name
			local Target = CustomCFrame or ToEnemy.PrimaryPart.CFrame
			local MaxDistance = Distance or Settings.BringDistance
		task.spawn(function()
			NewConnection(CommE.OnClientEvent, OnClientEvent)
			local InventoryItems = GetInventory();

			if not Cached.Bring[BringPositionTag] or (Target.Position - Cached.Bring[BringPositionTag].Position).Magnitude > 25 then
				Cached.Bring[BringPositionTag] = Target
			while type(InventoryItems) ~= "table" and task.wait(1) do
				InventoryItems = GetInventory()
			end

			local EnemyList = (not SuperBring and self.Enemies:GetTagged(Name)) or Enemies:GetChildren()
			
			for i = 1, #EnemyList do
				local Enemy = EnemyList[i]
				if not SuperBring and Enemy.Name ~= Name then continue end
				if Enemy.Parent ~= Enemies or Enemy:HasTag(BRING_TAG) then continue end
				if not Enemy:FindFirstChild("CharacterReady") then continue end
				
				local PrimaryPart = Enemy.PrimaryPart
				if IsAlive(Enemy) and PrimaryPart then
					if (Position - PrimaryPart.Position).Magnitude < MaxDistance then
						Enemy.Humanoid.WalkSpeed = 0
						Enemy.Humanoid.JumpPower = 0
						Enemy:AddTag(BRING_TAG)
					end
				end
			end
		else
			if not Cached.Bring[ToEnemy] then
				Cached.Bring[ToEnemy] = ToEnemy.PrimaryPart.CFrame
			for index = 1, #InventoryItems do
				ItemUpdated(InventoryItems[index])
			end
			
			ToEnemy.PrimaryPart.CFrame = Cached.Bring[ToEnemy]
		end
	end
	
	function Module:GetRaidIsland(): Instance?
		if Cached.RaidIsland and Cached.RaidIsland:IsDescendantOf(Locations) then
			return Cached.RaidIsland
		end
		end)

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
		return Inventory
	end)()

	function Module.GetProgress(...)
		local progressTag = ...
		local progressCache = Cached.Progress
		local entry = progressCache[progressTag]
	Services.Enemies = (function()
		local EnemiesModule = CreateDictionary({
			"__CakePrince", "__PirateRaid", "__TyrantSkies", "__Bones", "__Elite", "__Others"
		}, {})

		if entry and (tick() - entry.debounce) >= 2 then
			entry.result, entry.debounce = table.pack(FireRemote(...)), tick()
		elseif not entry then
			entry = { result = table.pack(FireRemote(...)), debounce = tick() }
			progressCache[progressTag] = entry
		end
		local TagsMobs = {
			["Deandre"] = "Elite", ["Diablo"] = "Elite", ["Urban"] = "Elite",
			
			["Reborn Skeleton"] = "Bones", ["Living Zombie"] = "Bones",
			["Demonic Soul"] = "Bones", ["Posessed Mummy"] = "Bones",
			
			["Head Baker"] = "CakePrince", ["Baking Staff"] = "CakePrince",
			["Cake Guard"] = "CakePrince", ["Cookie Crafter"] = "CakePrince",
			
			["Sun-kissed Warrior"] = "TyrantSkies", ["Skull Slayer"] = "TyrantSkies",
			["Isle Champion"] = "TyrantSkies", ["Serpent Hunter"] = "TyrantSkies",
		}

		return unpack(entry.result)
	end
	
	function Module:RemoveVolcanoLava()
		local PrehistoricIsland = Map.PrehistoricIsland
		local SpawnLocations = Module.SpawnLocations
		local CachedEnemies = Cached.Enemies
		local CachedBring = Cached.Bring

		if PrehistoricIsland.Core:FindFirstChild("InteriorLava") then
			PrehistoricIsland.Core.InteriorLava:Destroy()
		end
		local Attachment = Obfuscated.GetBringAttachment()

		for _, Instance in PrehistoricIsland:GetDescendants() do
			if string.find(string.lower(Instance.Name), "lava") and Instance:IsA("BasePart") then
				Instance:Destroy()
			end
		end
	end
	
	function Module:RemoveBoatCollision(Boat)
		local Objects = Boat:GetDescendants()
		local BringMobsCFrames = {}
		local BringMobsLookup = {}
		local IsSuperBring = false

		for i = 1, #Objects do
			local BasePart = Objects[i]
			if BasePart:IsA("BasePart") and BasePart.CanCollide then
				BasePart.CanCollide = false
			end
		end
	end
	
	function Module:GetRealFruitName(Fruit: Model?, ReturnsId: boolean?): string?
		if Fruit.Name ~= "Fruit " then
			return Fruit.Name
		end
		local UnprotectObject = HookManager.UnprotectObject
		local ProtectObject = HookManager.ProtectObject
		local OriginalIndex = HookManager.OriginalIndex
		
		local SpawnLocations = {}
		local EnemyLocations = {}

		local CacheName = Cached.RealFruitsName
		local CacheId = Cached.RealFruitsId
		EnemiesModule.SpawnLocations = SpawnLocations
		EnemiesModule.EnemyLocations = EnemyLocations

		if not CacheName[Fruit] then
			CacheName[Fruit] = if ReturnsId then "???" else "Fruit [ ??? ]"
		do
			local IslandsStartWord = "Island "

			local Model = Fruit:WaitForChild("Fruit", 9e9)
			local InstanceWithId = FastWait(2, Model, "Idle") or FastWait(1, Model, "Animation") or FastWait(1, Model, "Fruit")
			local function NewIslandAdded(Island)
				if string.sub(Island.Name, 1, #IslandsStartWord) == IslandsStartWord then
					CurrentRaidIsland = nil
				end
			end

			if InstanceWithId and (InstanceWithId:IsA("Animation") or InstanceWithId:IsA("MeshPart")) then
				local Property = if InstanceWithId:IsA("MeshPart") then "MeshId" else "AnimationId"
				local InstanceAssetId = InstanceWithId[Property]
				local RealName = self.FruitsId[InstanceAssetId]
			local function NewSpawn(Part)
				local EnemyName = GetEnemyName(Part.Name)
				EnemyLocations[EnemyName] = EnemyLocations[EnemyName] or {}

				CacheId[Fruit] = InstanceAssetId
				local EnemySpawn = Part.CFrame + Vector3.one * 25
				SpawnLocations[EnemyName] = Part

				if RealName and type(RealName) == "string" then
					CacheName[Fruit] = RealName
				if not table.find(EnemyLocations[EnemyName], EnemySpawn) then
					table.insert(EnemyLocations[EnemyName], EnemySpawn)
				end
			end
			
			for _, Spawn in EnemySpawns:GetChildren() do NewSpawn(Spawn) end
			NewConnection(EnemySpawns.ChildAdded, NewSpawn)
			NewConnection(Locations.ChildAdded, NewIslandAdded)
		end

		return if ReturnsId then CacheId[Fruit] else CacheName[Fruit]
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
			
			local Distance, Nearest = math.huge
			
			for i = 1, #Chests do
				local Chest = Chests[i]
				local Magnitude = (Chest:GetPivot().Position - Position).Magnitude
		local function CanBringMob(Enemy)
			return not BringMobsLookup[Enemy]
		end
		
		local function GetBringTag(EnemyName)
			return if IsSuperBring then "ALL_MOBS" else EnemyName
		end
		
		local function GetBringMobs(EnemyName)
			return if SuperBring then Enemies:GetChildren() else EnemiesModule:GetTagged(EnemyName)
		end
		
		local function StartBringMob(AlignPosition, Enemy, EnemyName, Humanoid, RootPart)
			while Enemy.Parent == Enemies and IsAlive(_, Humanoid) and RootPart.Parent == Enemy do
				local Target = BringMobsCFrames[GetBringTag(EnemyName)]
				local TargetPosition = Target and Target.Position

				if not SelectedIsland or Chest:IsDescendantOf(SelectedIsland) then
					if not Chest:GetAttribute("IsDisabled") and Magnitude < Distance then
						Distance, Nearest = Magnitude, Chest
				if Target and (TargetPosition - RootPart.Position).Magnitude <= Settings.BringDistance then
					if AlignPosition.Position ~= TargetPosition then
						AlignPosition.Position = TargetPosition
					end
				else
					break
				end
				
				task.wait(0.25)
			end
			
			self.Debounce = tick()
			self.Cached = Nearest
			return Nearest
		end
	})
	
	Module.Berry = setmetatable({}, {
		__call = function(self, BerryArray)
			local CachedBush = self.Cached
		
		local function BringMob(Enemy)
			if BringMobsLookup[Enemy] then return end

			if CachedBush and CachedBush:IsDescendantOf(Map) then
				for Tag, CFrame in pairs(CachedBush:GetAttributes()) do
					return CachedBush
				end
			end
			local EnemyName = Enemy.Name
			local Humanoid = Enemy.Humanoid
			local RootPart = Humanoid.RootPart

			if self.Debounce and (tick() - self.Debounce) < 0.5 then
				return nil
			end
			local CloneAttachment = Attachment:Clone()
			local AlignPosition = CloneAttachment.AlignPosition

			local Position = (Player.Character or Player.CharacterAdded:Wait()):GetPivot().Position
			local BerryBush = CollectionService:GetTagged("BerryBush")
			ProtectObject(CloneAttachment)
			CloneAttachment.Parent = RootPart

			local Distance, Nearest = math.huge
			pcall(StartBringMob, AlignPosition, Enemy, EnemyName, Humanoid, RootPart)

			for i = 1, #BerryBush do
				local Bush = BerryBush[i]
				
				for AttributeName, BerryName in pairs(Bush:GetAttributes()) do
					if not BerryArray or table.find(BerryArray, BerryName) then
						local Magnitude = (Bush.Parent:GetPivot().Position - Position).Magnitude
						
						if Magnitude < Distance then
							Nearest, Distance = Bush, Magnitude
						end
					end
				end
			end
			BringMobsLookup[Enemy] = nil

			self.Debounce = tick()
			self.Cached = Nearest
			return Nearest
			if CloneAttachment then
				UnprotectObject(CloneAttachment)
				CloneAttachment:Destroy()
			end
		end
	})

	Module.Enemies = (function()
		local EnemiesModule = CreateDictionary({
			"__CakePrince", "__PirateRaid", "__RaidBoss", "__TyrantSkies", "__Bones", "__Elite", "__Others", 
		}, {})
		
		local Signals = Module.Signals
		local SeaCastle = CFrame.new(-5556, 314, -2988)

		local TagsMobs = {
			__Elite = CreateDictionary({ "Deandre", "Diablo", "Urban" }, true),
			__Bones = CreateDictionary({ "Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy" }, true),
			__CakePrince = CreateDictionary({ "Head Baker", "Baking Staff", "Cake Guard", "Cookie Crafter" }, true),
			__TyrantSkies = CreateDictionary({ "Sun-kissed Warrior", "Skull Slayer", "Isle Champion", "Serpent Hunter" }, true)
		}
		
		local Attachment = Instance.new("Attachment") do
			local AlignPosition = Instance.new("AlignPosition")
			AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
			AlignPosition.Position = Vector3.new(0, 20, 0)
			AlignPosition.Responsiveness = 200
			AlignPosition.MaxForce = math.huge
			AlignPosition.Parent = Attachment
			AlignPosition.Attachment0 = Attachment
		function EnemiesModule.GetEnemy(EnemyName: string): Model?
			if type(EnemyName) == "table" then
				return EnemiesModule:GetClosest(EnemyName)
			else
				return EnemiesModule:GetEnemyByTag(EnemyName)
			end
		end

		local function New(list, NewEnemy)
			if table.find(list, NewEnemy) then return end
			
			local Humanoid = NewEnemy:WaitForChild("Humanoid")
		function EnemiesModule.IsSpawned(EnemyName: string): boolean
			local Cache = SpawnLocations[EnemyName]

			if Humanoid and Humanoid.Health > 0 then
				table.insert(list, NewEnemy)
				Humanoid.Died:Wait()
				local index = table.find(list, NewEnemy)
				if index then table.remove(list, index) end
			end
			return ((Cache and Cache:GetAttribute("Active")) or EnemiesModule:GetEnemyByTag(EnemyName)) and true or false
		end

		local function IsFromPiratesSea(Enemy)
			if not Enemy:WaitForChild("Humanoid") or Enemy.Humanoid.Health <= 0 then return end
		function EnemiesModule.BringMobs(ToEnemy: Instance, BringType: number?, ToCFrame: CFrame?, Distance: number?): (nil)
			local RootPart = IsAlive(ToEnemy) and ToEnemy.Humanoid.RootPart
			if not RootPart then return end

			local HumanoidRootPart = Enemy:WaitForChild("HumanoidRootPart")
			pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
			local ToEnemyName = ToEnemy.Name
			BringType = BringType or 0

			if HumanoidRootPart and (Enemy.Name ~= "rip_indra True Form" and Enemy.Name ~= "Blank Buddy") then
				if (HumanoidRootPart.Position - SeaCastle.Position).Magnitude <= 750 then
					task.spawn(New, EnemiesModule.__PirateRaid, Enemy)
					Module.PirateRaid = tick()
			if not Distance and (not Settings.BringMobs or BringType == 0) then
				if not BringMobsCFrames[ToEnemyName] then
					BringMobsCFrames[ToEnemyName] = RootPart.CFrame
				end
				
				RootPart.CFrame = BringMobsCFrames[ToEnemyName]
				return nil
			end
		end
		
		local function NewEnemyAdded(Enemy)
			local EnemyName = Enemy.Name
			local Others = EnemiesModule.__Others

			Others[EnemyName] = Others[EnemyName] or {}
			task.spawn(New, Others[EnemyName], Enemy)
			local MyRootPosition = Services.PlayerManager:GetRootPartPosition()
			IsSuperBring = BringType == 2

			if Module.GameData.Sea == 3 then
				task.spawn(IsFromPiratesSea, Enemy)
			end
			local BringTag = GetBringTag(ToEnemyName)
			local Target = ToCFrame or RootPart.CFrame
			local MaxDistance = Distance or Settings.BringDistance

			if Enemy:GetAttribute("RaidBoss") then
				task.spawn(New, EnemiesModule.__RaidBoss, Enemy)
			elseif EnemiesModule[`__{ EnemyName }`] then
				task.spawn(New, EnemiesModule[`__{ EnemyName }`], Enemy)
			else
				for Tag, Mobs in pairs(TagsMobs) do
					if Mobs[EnemyName] then
						task.spawn(New, EnemiesModule[Tag], Enemy)
						break
					end
				end
			if not BringMobsCFrames[BringTag] or (Target.Position - BringMobsCFrames[BringTag].Position).Magnitude > 25 then
				BringMobsCFrames[BringTag] = Target
			end
		end
		
		function EnemiesModule.IsSpawned(EnemyName: string): boolean
			local Cached = Module.SpawnLocations[EnemyName]

			if Cached and Cached.Parent then
				return (Cached:GetAttribute("Active") or EnemiesModule:GetEnemyByTag(EnemyName)) and true or false
			for _, Enemy in GetBringMobs(ToEnemyName) do
				if not Enemy:FindFirstChild("CharacterReady") then continue end
				if Enemy.Parent ~= Enemies or not SuperBring and Enemy.Name ~= Name then continue end
				
				local EnemyRootPart = IsAlive(Enemy) and Enemy.Humanoid.RootPart
				if not EnemyRootPart then continue end
				
				if (Position - PrimaryPart.Position).Magnitude < MaxDistance then
					BringMob(Enemy)
				end
			end
			
			return EnemiesModule:GetEnemyByTag(EnemyName) and true or false
		end

		function EnemiesModule:GetTagged(TagName: string): table?
			return self[`__{TagName}`] or self.__Others[TagName]
			return self[`__{ TagName }`] or self.__Others[TagName]
		end

		function EnemiesModule:GetEnemyByTag(TagName: string): Model?
			local CachedEnemy = Cached.Enemies[TagName]
			local CachedEnemy = CachedEnemies[TagName]

			if CachedEnemy and IsAlive(CachedEnemy) then
				return CachedEnemy
			end

			local Enemies = self:GetTagged(TagName)

			if Enemies and #Enemies > 0 then
				for i = 1, #Enemies do
					local Enemy = Enemies[i]
					
					if IsAlive(Enemy) then
						Cached.Enemies[TagName] = Enemy
						return Enemy
					end
			if Enemies then
				for index = 1, #Enemies do
					local Enemy = Enemies[index]
					CachedEnemies[TagName] = Enemy
					return Enemy
				end
			end
		end

		function EnemiesModule:GetClosest(Enemies: table): Model?
		function EnemiesModule:GetClosest(Enemies: { string }): Model?
			local SpecialTag = table.concat(Enemies, ".")
			local CachedEnemy = Cached.Enemies[SpecialTag]
			local CachedEnemy = CachedEnemies[SpecialTag]

			if CachedEnemy and IsAlive(CachedEnemy) then
				return CachedEnemy
@@ -1446,34 +948,33 @@ local Module = {} do
			end

			if Nearest then
				Cached.Enemies[SpecialTag] = Nearest
				CachedEnemies[SpecialTag] = Nearest
				return Nearest
			end
		end

		function EnemiesModule:GetClosestByTag(TagName: string): Model?
			local CachedEnemy = Cached.Enemies[TagName]
			local CachedEnemy = CachedEnemies[TagName]

			if CachedEnemy and IsAlive(CachedEnemy) then
				return CachedEnemy
			end

			local Enemies = self:GetTagged(TagName)

			if Enemies and #Enemies > 0 then
			if RootPart and Enemies and #Enemies > 0 then
				local RootPosition = Services.PlayerManager:GetRootPartPosition()
				local Distance, Nearest = math.huge

				local Position = (Player.Character or Player.CharacterAdded()):GetPivot().Position
				
				for i = 1, #Enemies do
					local Enemy = Enemies[i]
					local PrimaryPart = Enemy.PrimaryPart

					if PrimaryPart and IsAlive(Enemy) then
						local Magnitude = (Position - PrimaryPart.Position).Magnitude
					if PrimaryPart then
						local Magnitude = (RootPosition - PrimaryPart.Position).Magnitude

						if Magnitude <= 15 then
							Cached.Enemies[TagName] = Enemy
						if Magnitude <= 50 then
							CachedEnemies[TagName] = Enemy
							return Enemy
						elseif Magnitude <= Distance then
							Distance, Nearest = Magnitude, Enemy
@@ -1482,150 +983,171 @@ local Module = {} do
				end

				if Nearest then
					Cached.Enemies[TagName] = Nearest
					CachedEnemies[TagName] = Nearest
					return Nearest
				end
			end
		end

		function EnemiesModule:CreateNewTag(Tag: string, Enemies: table): table?
			local NewTag = {}
			self[`__{Tag}`] = NewTag
		do
			local SeaCastlePosition = Vector3.new(-5556, 314, -2988)
			local OthersEnemies = EnemiesModule.__Others
			local CurrentSea = GameData.Sea

			for i = 1, #Enemies do
				self[`__{Enemies[i]}`] = NewTag
				local Others = self.__Others[ Enemies[i] ]
			local function NewEnemy(self, Enemy)
				if table.find(self, Enemy) then return end

				if Others then
					for i = 1, #Others do
						task.spawm(newEnemy, NewTag, Others[i])
					end
				local Humanoid = Enemy:WaitForChild("Humanoid")
				
				if Humanoid and Humanoid.Health > 0 then
					table.insert(self, Enemy)
					Humanoid.Died:Wait()
					table.remove(self, table.find(self, Enemy))
				end
			end

			return NewTag
			local function IsFromSeaCastle(Enemy)
				if Enemy.Name == "rip_indra True Form" or Enemy.Name == "Blank Buddy" then return end
				if not Enemy:WaitForChild("Humanoid") or Enemy.Humanoid.Health <= 0 then return end
				
				local RootPart = Enemy:WaitForChild("HumanoidRootPart")
				
				if RootPart and (RootPart.Position - SeaCastlePosition).Magnitude <= 750 then
					task.spawn(NewEnemy, EnemiesModule.__PirateRaid, Enemy)
					EnemiesModule.PirateRaid = tick()
				end
			end
			
			local function NewEnemyAdded(Enemy)
				local EnemyName = Enemy.Name
				local TagName = `__{ EnemyName }`
				
				OthersEnemies[EnemyName] = OthersEnemies[EnemyName] or {}
				task.spawn(NewEnemy, OthersEnemies[EnemyName], Enemy)
				
				if CurrentSea == 3 then
					task.spawn(IsFromSeaCastle, Enemy)
				end
				
				if EnemiesModule[TagName] then
					task.spawn(NewEnemy, EnemiesModule[TagName], Enemy)
				elseif TagsMobs[EnemyName] then
					task.spawn(NewEnemy, EnemiesModule[`__{ TagsMobs[EnemyName] }`], Enemy)
				end
			end
			
			for _, Enemy in CollectionService:GetTagged("BasicMob") do NewEnemyAdded(Enemy) end
			table.insert(Connections, CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(NewEnemyAdded))
		end

		local function Bring(Enemy)
			local RootPart = Enemy:WaitForChild("HumanoidRootPart")
			local Humanoid = Enemy:WaitForChild("Humanoid")
			local EnemyName = Enemy.Name
		return EnemiesModule
	end)()
	
	Services.ToolService = (function()
		local ToolService = {}
		
		local InvokeCommF = Services.Network.InvokeCommF
		local ToolsCache = Cached.Tools
		local BUSO_PRICE = 25000
		
		local function FindFirstType(Tip: string): Tool?
			local Equipped = Player.Character:FindFirstChildOfClass("Tool")

			local CloneAttachment = Attachment:Clone()
			local AlignPosition = CloneAttachment.AlignPosition
			HookManager.ProtectObject(CloneAttachment)
			CloneAttachment.Parent = RootPart
			if Equipped and Equipped.ToolTip == Tip then
				return Equipped
			end

			while Enemy and Enemy.Parent == Enemies and Enemy:HasTag(BRING_TAG) do
				if not Humanoid or Humanoid.Health <= 0 then break end
				if not RootPart or RootPart.Parent ~= Enemy then break end
				
				local Target = Cached.Bring[if Module.IsSuperBring then "ALL_MOBS" else EnemyName]
				
				if Target and (Target.Position - RootPart.Position).Magnitude <= Settings.BringDistance then
					if AlignPosition.Position ~= Target.Position then
						AlignPosition.Position = Target.Position
					end
				else
					break
				end;task.wait()
			for _, Tool in Player.Backpack:GetChildren() do
				if Tool:IsA("Tool") and Tool.ToolTip == Tip then
					return Tool
				end
			end
		end
		
		local function BuyBuso()
			if Money.Value < BUSO_PRICE then return end

			if Enemy and Enemy:HasTag(BRING_TAG) then Enemy:RemoveTag(BRING_TAG) end
			if CloneAttachment then HookManager.UnprotectObject(CloneAttachment) CloneAttachment:Destroy() end
			InvokeCommF("BuyHaki", "Buso")
		end

		local function KillAura(Enemy)
			local Humanoid = Enemy:FindFirstChild("Humanoid")
			local RootPart = Enemy:FindFirstChild("HumanoidRootPart")
		local function GetTool(Name: string, ByType: boolean?): Tool?
			local Character = Player.Character
			if not IsAlive(Character) then return end

			pcall(sethiddenproperty, Player, "SimulationRadius", math.huge)
			local CacheTag = if ByType then `toolTip_{Name}` else Name
			local Cache = ToolsCache[CacheTag]
			
			if Cache and (Cache.Parent == Character or Cache.Parent == Player.Backpack) then
				return Cache
			end
			
			local HasTool = if ByType then FindFirstType(Name) else (Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name))

			if Humanoid and RootPart then
				RootPart.CanCollide = false
				RootPart.Size = Vector3.new(60, 60, 60)
				Humanoid:ChangeState(15)
				Humanoid.Health = 0
				task.wait()
				Enemy:RemoveTag(KILLAURA_TAG)
			if HasTool then
				ToolsCache[CacheTag] = HasTool
				return HasTool
			end
		end
		
		function ToolService.GetToolMastery(Name: string, ...): number
			local HasTool = GetTool(Name, ...)
			return HasTool and HasTool:GetAttribute("Level") or 0
		end
		
		function ToolService.VerifyTool(Name: string, ...): boolean
			return GetTool(Name, ...) and true or false
		end
		
		function ToolService.EnableBuso()
			local Character = Player.Character
			if IsAlive(Character) and not Character:FindFirstChild("HasBuso") then
				return if Character:HasTag("Buso") then InvokeCommF("Buso") else BuyBuso()
			end
		end

		for _, Enemy in CollectionService:GetTagged("BasicMob") do NewEnemyAdded(Enemy) end
		table.insert(Connections, CollectionService:GetInstanceAddedSignal("BasicMob"):Connect(NewEnemyAdded))
		ToolService.EquipTool = EquipTool

		table.insert(Connections, CollectionService:GetInstanceAddedSignal(KILLAURA_TAG):Connect(KillAura))
		table.insert(Connections, CollectionService:GetInstanceAddedSignal(BRING_TAG):Connect(Bring))
		
		return EnemiesModule
		return ToolService
	end)()

	Module.Inventory = (function()
		local Inventory = {
			Unlocked = setmetatable({}, { __index = function() return false end }),
			Mastery = setmetatable({}, { __index = function() return 0 end }),
			Count = setmetatable({}, { __index = function() return 0 end }),
			MasteryRequirements = {},
			Items = {},
	Module.FastAttack = (function()
		local FastAttack = {}
		
		local ATTACK_RANGE = {
			["Blox Fruit"] = 40,
			["Melee"] = 50,
			["Sword"] = 50,
			["Gun"] = 300,
		}

		function Inventory:UpdateItem(item)
			if type(item) == "table" then
				if item.Type == "Wear" then
					item.Type = "Accessory"
				end
				
				local Name = item.Name
				
				self.Items[Name] = item
				
				if not self.Unlocked[Name] then self.Unlocked[Name] = true end
				if item.Count then self.Count[Name] = item.Count end
				if item.Mastery then self.Mastery[Name] = item.Mastery end
				if item.MasteryRequirements then self.MasteryRequirements[Name] = item.MasteryRequirements end
			end
		end
		local SendHitsToServer = Obfuscated.SendHitsToServer
		local GetPartBoundsInBox = Obfuscated.GetPartBoundsInBox
		local GetMaxHits = Obfuscated.GetMaxHits

		function Inventory:RemoveItem(ItemName)
			if type(ItemName) == "string" then
				self.Unlocked[ItemName] = nil
				self.Mastery[ItemName] = nil
				self.Count[ItemName] = nil
				self.Items[ItemName] = nil
			end
		end
		local RE_ShootGunEvent = Services.Network:RemoteEvent("ShootGunEvent")

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
		Obfuscated.SetRigisterAttackEvent(Services.Network:RemoteEvent("RegisterAttack"))
		Obfuscated.SetRigisterHitEvent(Services.Network:RemoteEvent("RegisterHit"))

		task.spawn(function()
			table.insert(Connections, CommE.OnClientEvent:Connect(OnClientEvent))
			local InventoryItems = nil;
		local function attack()
			local Character = Player.Character
			if not IsAlive(Character) then return end

			repeat
				task.wait(1)
				InventoryItems = FireRemote("getInventory")
			until type(InventoryItems) == "table"
			local Humanoid = Character.Humanoid
			local RootPart = Humanoid.RootPart

			for index = 1, #InventoryItems do
				Inventory:UpdateItem(InventoryItems[index])
			if not RootPart then return end
			
			local Equipped = Character:FindFirstChildOfClass("Tool")
			
			if Equipped then
				
			end
		end)
		end

		return Inventory
	end)()
	
	Module.FastAttack = (function()
		local FastAttack = {
		return FastAttack
		
		--[[local FastAttack = {
			Distance = 50,
			attackMobs = true,
			attackPlayers = true,
@@ -1665,11 +1187,11 @@ local Module = {} do
		local Events: Folder = ReplicatedStorage:WaitForChild("Events")
		
		local SUCCESS_FLAGS, COMBAT_REMOTE_THREAD = pcall(function()
			return require(Modules.Flags).COMBAT_REMOTE_THREAD or false
			return rawget(require(Modules.Flags), "COMBAT_REMOTE_THREAD") or false
		end)
		
		local SUCCESS_SHOOT, SHOOT_FUNCTION = pcall(function()
			return getupvalue(require(ReplicatedStorage.Controllers.CombatController).Attack, 9)
			return getupvalue(rawget(require(ReplicatedStorage.Controllers.CombatController), "Attack"), 9)
		end)
		
		local HIT_FUNCTION; task.defer(function()
@@ -1685,7 +1207,7 @@ local Module = {} do
				local Success, ScriptEnv = pcall(getsenv, LocalScript)
				
				if Success and ScriptEnv then
					HIT_FUNCTION = ScriptEnv._G.SendHitsToServer
					HIT_FUNCTION = rawget(ScriptEnv._G, "SendHitsToServer")
				end
			end
		end)
@@ -1726,13 +1248,6 @@ local Module = {} do
			table.insert(CurrentBladeHits, { Character, RootPart })
		end
		
		local function GetMaxHits(Character)
			if Character:FindFirstChild("HumanoidRootPart") and Character.HumanoidRootPart:FindFirstChild("Buddha") then
				return 10
			end
			return 1
		end
		
		local function ProcessSeaEventsHits(Distance)
			for _, SeaBeast in SeaBeasts:GetChildren() do
				local BasePart = SeaBeast:FindFirstChildOfClass("MeshPart")
@@ -1780,7 +1295,7 @@ local Module = {} do
		local function ProcessHits(List: Folder, Equipped: Tool, Distance: number): (nil)
			local MyCharacter = Player.Character;
			local Targets = List:GetChildren();
			local MaxHits = GetMaxHits(MyCharacter) + 1;
			local MaxHits = GetMaxHits(MyCharacter);
			
			for i = 1, #Targets do
				if #CurrentBladeHits >= MaxHits then break end
@@ -1906,15 +1421,41 @@ local Module = {} do
			end
		end
		
		function FastAttack:SuperFastAttack(EnemyHitBox, BladeHits, Cooldown)
			if Module.SuperFastAttack and Settings.FastAttack then
				local Enemy = EnemyHitBox.Parent
				local Times = if Enemy:GetAttribute("IsBoss") then 25 elseif Enemy:GetAttribute("RaidBoss") then 40 else 6
				
				self.Debounce = tick() + 9e9;
				local Overheat = 0;
				
				table.insert(BladeHits, { EnemyHitBox.Parent, EnemyHitBox })
				table.insert(BladeHits, math.random())
				
				while Overheat <= 0.4 do
					for i = 1, Times do
						RE_RegisterAttack:FireServer(self:GetCombo())
						HIT_FUNCTION(EnemyHitBox, BladeHits)
					end
					Overheat += task.wait(if Times > 10 then 0.07 else 0)
				end
				
				self.Debounce = 0;
				return true;
			end
		end
		
		function FastAttack:UseNormalClick(Cooldown: number): (nil)
			self:UpdateBladeHits()
			
			if #CurrentBladeHits > 0 then
				local PrimaryRootPart = table.remove(CurrentBladeHits)[2]
				
				if SUCCESS_FLAGS and COMBAT_REMOTE_THREAD and HIT_FUNCTION then
					RE_RegisterAttack:FireServer(Cooldown)
					HIT_FUNCTION(PrimaryRootPart, CurrentBladeHits)
					if not self:SuperFastAttack(PrimaryRootPart, CurrentBladeHits, Cooldown) then
						RE_RegisterAttack:FireServer(Cooldown)
						HIT_FUNCTION(PrimaryRootPart, CurrentBladeHits)
					end
				elseif SUCCESS_FLAGS and not COMBAT_REMOTE_THREAD then
					RE_RegisterAttack:FireServer(Cooldown)
					RE_RegisterHit:FireServer(PrimaryRootPart, CurrentBladeHits)
@@ -2032,14 +1573,14 @@ local Module = {} do
				return nil
			end
			
			local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or 0.3;
			local Cooldown = Equipped:FindFirstChild("Cooldown") and Equipped.Cooldown.Value or DEFAULT_COOLDOWN;
			
			if (tick() - self.Debounce) >= Cooldown and CheckStun(ToolTip, Character, Humanoid) then
				local Combo = self:GetCombo();
				if Combo >= 4 then Cooldown += 0.05 end;
				if Combo >= 4 then Cooldown += GetCooldownIncrrament(Equipped.Name, ) end;
				
				self.Equipped = Equipped;
				self.Debounce = if Combo >= 4 and ToolTip ~= "Gun" then tick() + (Cooldown / 2) else tick();
				self.Debounce = if Combo >= 4 and ToolTip ~= "Gun" then tick() + 0.05 else tick();
				MyRootPartPosition = Character.Humanoid.RootPart.Position;
				
				if ToolTip == "Blox Fruit" and not self.NormalClickFruits[Equipped.Name] then
@@ -2056,517 +1597,332 @@ local Module = {} do
			end
		end))
		
		return FastAttack
		return FastAttack]]
	end)()

	Module.RaidList = (function()
		local Success, RaidModule = pcall(require, ReplicatedStorage:WaitForChild("Raids"))
	return Services
end)()

local DisableCanTouchDebounce = 0

function Module.DisableCanTouch()
	DisableCanTouchDebounce = tick()
end

Module.TweenBodyVelocity = (function()
	local ClearNoclipParts = HookManager.ClearNoclipParts
	local AddNoclipObject = HookManager.AddNoclipObject
	local UnprotectObject = HookManager.UnprotectObject
	local ProtectObject = HookManager.ProtectObject
	local OriginalIndex = HookManager.OriginalIndex
	
	local BodyVeloChangedSignal = Module.Services.GoodSignal.Signals.BvChanged
	
	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.Velocity = Vector3.zero
	BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	BodyVelocity.P = 1000
	
	if _ENV.tween_bodyvelocity then
		UnprotectObject(_ENV.tween_bodyvelocity)
		_ENV.tween_bodyvelocity:Destroy()
	end
	
	ProtectObject(BodyVelocity)
	_ENV.tween_bodyvelocity = BodyVelocity
	
	local IsA, FindFirstChild = game.IsA, game.FindFirstChild
	local IsCustomTag = false
	
	local BaseParts, CanCollideObjects, CanTouchObjects = {}, {}, {} do
		HookManager.SetCanCollideObjects(CanCollideObjects)
		HookManager.SetCanTouchObjects(CanTouchObjects)

		if not Success or type(RaidModule) ~= "table" then
			return {
				"Phoenix", "Dough", "Flame", "Ice", "Quake", "Light";
				"Dark", "Spider", "Rumble", "Magma", "Buddha", "Sand";
			}
		local function AddObjectToBaseParts(Object)
			if Object ~= BodyVelocity and IsA(Object, "BasePart") and (Object.CanCollide or Object.CanTouch) then
				table.insert(BaseParts, Object)
				AddNoclipObject(Object)
				
				if OriginalIndex(Object, "CanCollide") then CanCollideObjects[Object] = true end
				if OriginalIndex(Object, "CanTouch") then CanTouchObjects[Object] = true end
			end
		end

		local AdvancedRaids = RaidModule.advancedRaids or {}
		local NormalRaids = RaidModule.raids or {}
		local RaidList = {}
		local function RemoveObjectsFromBaseParts(BasePart)
			local index = table.find(BaseParts, BasePart)
			
			if index then
				table.remove(BaseParts, index)
			end
		end

		for i = 1, #AdvancedRaids do table.insert(RaidList, AdvancedRaids[i]) end
		for i = 1, #NormalRaids do table.insert(RaidList, NormalRaids[i]) end
		local function NewCharacter(Character)
			if not Character then return end
			table.clear(BaseParts)
			
			for _, Object in Character:GetDescendants() do AddObjectToBaseParts(Object) end
			Character.DescendantAdded:Connect(AddObjectToBaseParts)
			Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
			
			Character:WaitForChild("Humanoid", 9e9).Died:Wait()
			table.clear(BaseParts)
			ClearNoclipParts()
		end

		return RaidList
	end)()
		NewConnection(Player.CharacterAdded, NewCharacter)
		task.spawn(NewCharacter, Player.Character)
	end

	Module.Tween = (function()
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.Velocity = Vector3.zero
		BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		BodyVelocity.P = 1000
		
		HookManager.ProtectObject(BodyVelocity)
		
		if _ENV.tween_bodyvelocity then
			HookManager.UnprotectObject(_ENV.tween_bodyvelocity)
			_ENV.tween_bodyvelocity:Destroy()
	local function NoClipOnStepped(Character)
		if not IsCustomTag and _ENV.OnFarm then
			IsCustomTag = true
		end

		_ENV.tween_bodyvelocity = BodyVelocity
		
		local IsCustomTag = false
		if _ENV.OnFarm and not Player:HasTag("Teleporting") then
			Player:AddTag("Teleporting")
			IsCustomTag = true
		elseif IsCustomTag and not _ENV.OnFarm and Player:HasTag("Teleporting") then
			Player:RemoveTag("Teleporting")
			IsCustomTag = false
		end

		local BaseParts, CanCollideObjects, CanTouchObjects = {}, {}, {} do
			local function AddObjectToBaseParts(Object)
				if Object ~= BodyVelocity and Object:IsA("BasePart") and (Object.CanCollide or Object.CanTouch) then
					table.insert(BaseParts, Object)
					
					if Object.CanCollide then CanCollideObjects[Object] = true end
					if Object.CanTouch then CanTouchObjects[Object] = true end
				end
			end
			
			local function RemoveObjectsFromBaseParts(BasePart)
				local index = table.find(BaseParts, BasePart)
		if _ENV.OnFarm then
			for i = 1, #BaseParts do
				local BasePart = BaseParts[i]
				local CanTouchValue = if (tick() - DisableCanTouchDebounce) <= 1 then false else true

				if index then
					table.remove(BaseParts, index)
				if CanTouchObjects[BasePart] and BasePart.CanTouch ~= CanTouchValue then
					BasePart.CanTouch = CanTouchValue
				end
				if CanCollideObjects[BasePart] and BasePart.CanCollide then
					BasePart.CanCollide = false
				end
			end
			
			local function NewCharacter(Character)
				table.clear(BaseParts)
		elseif Character.PrimaryPart and (not Character.PrimaryPart.CanCollide or not Character.PrimaryPart.CanTouch) then
			for i = 1, #BaseParts do
				local BasePart = BaseParts[i]

				for _, Object in ipairs(Character:GetDescendants()) do AddObjectToBaseParts(Object) end
				Character.DescendantAdded:Connect(AddObjectToBaseParts)
				Character.DescendantRemoving:Connect(RemoveObjectsFromBaseParts)
				
				Character:WaitForChild("Humanoid", 9e9).Died:Wait()
				table.clear(BaseParts)
			end
			
			table.insert(Connections, Player.CharacterAdded:Connect(NewCharacter))
			task.spawn(NewCharacter, Player.Character)
		end
		
		local function NoClipOnStepped(Character)
			if not IsAlive(Character) then return end
			
			if not IsCustomTag and _ENV.OnFarm then
				IsCustomTag = true
			end
			
			if _ENV.OnFarm and not Player:HasTag("Teleporting") then
				Player:AddTag("Teleporting")
				IsCustomTag = true
			elseif IsCustomTag and not _ENV.OnFarm and Player:HasTag("Teleporting") then
				Player:RemoveTag("Teleporting")
				IsCustomTag = false
			end
			
			if _ENV.OnFarm then
				for i = 1, #BaseParts do
					local BasePart = BaseParts[i]
					local CanTouchValue = if (tick() - Module.RemoveCanTouch) <= 1 then false else true
					
					if CanTouchObjects[BasePart] and BasePart.CanTouch ~= CanTouchValue then
						BasePart.CanTouch = CanTouchValue
					end
					if CanCollideObjects[BasePart] and BasePart.CanCollide then
						BasePart.CanCollide = false
					end
				if CanCollideObjects[BasePart] then
					BasePart.CanCollide = true
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
				if CanTouchObjects[BasePart] then
					BasePart.CanTouch = true
				end
			end
		end
	end
	
	local function UpdateVelocityOnStepped(Character)
		local BasePart = FindFirstChild(Character, "UpperTorso")
		local Humanoid = FindFirstChild(Character, "Humanoid")
		local BodyVelocity = _ENV.tween_bodyvelocity

		local OriginalIndex = HookManager.OriginalIndex
		local NewParent = if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then BasePart else nil

		local function UpdateVelocityOnStepped(Character)
			local BasePart = Character:FindFirstChild("UpperTorso")
			local Humanoid = Character:FindFirstChild("Humanoid")
			local BodyVelocity = _ENV.tween_bodyvelocity
			
			local NewParent = if _ENV.OnFarm and BasePart and Humanoid and Humanoid.Health > 0 then BasePart else nil
			
			if OriginalIndex(BodyVelocity, "Parent") ~= NewParent then
				BodyVelocity.Parent = NewParent
			end
			
			if OriginalIndex(BodyVelocity, "Velocity") ~= Vector3.zero and (
				not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm
			) then
				BodyVelocity.Velocity = Vector3.zero
			end
		if OriginalIndex(BodyVelocity, "Parent") ~= NewParent then
			BodyVelocity.Parent = NewParent
			BodyVeloChangedSignal:Fire(NewParent)
		end

		table.insert(Connections, Stepped:Connect(function()
			local Character = Player.Character
			if IsAlive(Character) then
				UpdateVelocityOnStepped(Character)
				NoClipOnStepped(Character)
			end
		end))
		local Velocity = OriginalIndex(BodyVelocity, "Velocity")

		return BodyVelocity
	end)()
		if Velocity ~= Vector3.zero and (not Humanoid or not Humanoid.SeatPart or not _ENV.OnFarm) then
			BodyVelocity.Velocity = Vector3.zero
		end
	end

	Module.Hooking = (function()
		local Hooking = {
			Skills = CreateDictionary({ "Z", "X", "C", "V", "F" }, true)
		}
		
		local Enabled = _ENV.rz_EnabledOptions;
		local ClosestEnemie = nil;
		
		local DisableUpdateClosest = 0;
		local UpdateClosestsDebounce = 0;
		local CharacterBasePartName = "RightLowerArm";
		
		local function _GetCurrentTarget(Tag: string): any?
			if (tick() - DisableUpdateClosest) <= 2 or _ENV[Tag] then
				return ClosestEnemie
			end
	NewConnection(Stepped, function()
		local Character = Player.Character
		if IsAlive(Character) then
			UpdateVelocityOnStepped(Character)
			NoClipOnStepped(Character)
		end
		
		local function UpdateClosests()
			local SmoothUpdateCooldown = if Settings.SmoothMode then 0.5 else 0.25
			local time = tick()
			
			if ClosestEnemie and not ClosestEnemie.Parent then
				ClosestEnemie.Parent = nil
			end
			
			if (time - DisableUpdateClosest) <= 2 or (time - UpdateClosestsDebounce) <= SmoothUpdateCooldown then
				return nil
			else
				UpdateClosestsDebounce = time
			end
			
			local MyCharacter = Player.Character
			local Equipped = MyCharacter and MyCharacter:FindFirstChildOfClass("Tool")
	end)
	
	return BodyVelocity
end)()

Module.RunModules = (function()
	local Modules = {}
	
	local function NewModule(Name, Module)
		Modules[Name] = Module
	end
	
	local ErrorSignal = Module.Services.GoodSignal.Signals.Error
	
	NewModule("FarmQueue", function(Options)
		NewConnection(ErrorSignal, function(Message)
			_ENV.loadedFarm = nil
			_ENV.OnFarm = false

			if Equipped and Equipped.ToolTip and MyCharacter.Humanoid.RootPart then
				local ClosestDistance = if Equipped.ToolTip == "Gun" then 180 else 900
				
				local MyPosition = MyCharacter.Humanoid.RootPart.Position
				local _Characters = Characters:GetChildren()
				local _Enemies = Enemies:GetChildren()
				
				for i = 1, #_Characters do
					local Character = _Characters[i]
					if Character == MyCharacter or not CheckPlayerAlly(Character) then continue end
					local Humanoid = Character:FindFirstChildOfClass("Humanoid")
					local Hitbox = GetRandomHitboxLimb(Character)
			return error(Message, 2)
		end)
		
		ErrorSignal:Fire(select(2, pcall(function()
			local function GetQueue()
				for _, Option in Options do
					Settings.RunningOption = Option.Name
					local Method = Option.Function()

					if Hitbox and IsAlive(_, Humanoid) and Humanoid.RootPart then
						local Magnitude = (Humanoid.RootPart.Position - MyPosition).Magnitude
						
						if Magnitude <= ClosestDistance then
							ClosestEnemie, ClosestDistance = Hitbox, Magnitude
					if Method then
						if type(Method) == "string" then
							Settings.RunningMethod = Method
						end
						return Method
					end
				end

				for i = 1, (if Settings.NoAimMobs then 0 else #_Enemies) do
					local Mob = _Enemies[i]
					local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
					local Hitbox = GetRandomHitboxLimb(Mob)
					
					if Hitbox and IsAlive(_, Humanoid) and Humanoid.RootPart then
						local Magnitude = (Humanoid.RootPart.Position - MyPosition).Magnitude
						
						if Magnitude <= ClosestDistance then
							ClosestEnemie, ClosestDistance = Hitbox, Magnitude
						end
					end
				end
				Settings.RunningOption, Settings.RunningMethod = nil, nil
			end
		end
		
		local function hook_newindex()
			if _ENV.rz_enabled_bypass or not HIDDEN_SETTINGS.WALKSPEED_BYPASS_ENABLED then return end
			_ENV.rz_enabled_bypass = true

			local HookProperty = HookManager.HookProperty
			
			local old_newindex;
			old_newindex = hookmetamethod(Player, "__newindex", function(self, index, value)
				if index == "WalkSpeed" and self.Name == "Humanoid" then
					HookProperty(self, index, value)
					return old_newindex(self, "WalkSpeed", _ENV.WalkSpeedBypass or value)
			while task.wait(Settings.SmoothMode and 0.25 or 0) do
				if _ENV.teleporting then
					_ENV.OnFarm = true
				elseif Settings.IgnoreErrors then
					local Success, Response = pcall(GetQueue)
					
					_ENV.OnFarm = (not Success and _ENV.OnFarm) or Response
				else
					return old_newindex(self, index, value)
					_ENV.OnFarm = if GetQueue() then true else false
				end
			end)
		end
			end
		end)))
	end)
	
	NewModule("Translator", function(Window, Translation)
		local MakeTab = Window.MakeTab

		local function hook_namecall()
			if not HIDDEN_SETTINGS.SILENT_AIM_ENABLED then return end
			if _ENV.rz_original_namecall then return end
			
			table.insert(Connections, Stepped:Connect(UpdateClosests))
		Window.MakeTab = function(self, Configs)
			if Translation[ Configs[1] ] then
				Configs[1] = Translation[ Configs[1] ]
			end

			local Events = {
				["RE/ShootGunEvent"] = function(...)
					local Position, Enemies = ...
					
					if typeof(Position) == "Vector3" and type(Enemies) == "table" and #Enemies ~= 0 then
						local ClosestMob = _GetCurrentTarget("AimBot_Gun")
						
						if ClosestMob then
							return ClosestMob.Position, { ClosestMob }
						end
					end
					
					return ...
				end,
				["RemoteEvent"] = function(...)
					local param1, param2 = ...
					
					if typeof(param1) == "Vector3" and not param2 then
						local Target = _GetCurrentTarget("AimBot_Skills")
						
						if Target then
							return Target.Position
						end
					elseif param1 == "TAP" and typeof(v2) == "Vector3" then
						local Target = _GetCurrentTarget("AimBot_Tap")
						
						if Target then
							return "TAP", Target.Position
						end
					end
					
					return ...
				end
			}
			local Tab = MakeTab(self, Configs)
			local NewTab = {}

			local OriginalIndex = HookManager.OriginalIndex
			local string_lower = string.lower
			function NewTab:AddSection(Name)
				return Tab:AddSection(Translation[Name] or Name)
			end

			local old_namecall;
			old_namecall = hookmetamethod(game, "__namecall", function(self, ...)
				local Event = Events[OriginalIndex(self, "Name")]
			function NewTab:AddButton(Configs)
				local Translator = Translation[ Configs[1] ]

				if Event and string_lower(getnamecallmethod()) == "fireserver" then
					return old_namecall(self, Event(...))
				else
					return old_namecall(self, ...)
				if Translator then
					Configs[1] = type(Translator) == "string" and Translator or Translator[1]
					Configs.Desc = type(Translator) ~= "string" and Translator[2]
				end
			end)
				
				return Tab:AddButton(Configs)
			end

			_ENV.rz_original_namecall = old_namecall
		end
		
		Module.HookGame = function()
			task.delay(1, hook_newindex)
			task.delay(1, hook_namecall)
		end
		
		function Hooking:SetTarget(RootPart: BasePart): (nil)
			ClosestEnemie, DisableUpdateClosest = GetRandomHitboxLimb(RootPart.Parent) or RootPart, tick()
		end
		
		return Hooking
	end)()
	
	-- task.defer(function()
	-- 	local DeathEffect = require(WaitChilds(ReplicatedStorage, "Effect", "Container", "Death"))
	-- 	local CameraShaker = require(WaitChilds(ReplicatedStorage, "Util", "CameraShaker"))
	-- 	
	-- 	if CameraShaker then
	-- 		CameraShaker:Stop()
	-- 	end
	-- 	if hookfunction then
	-- 		hookfunction(DeathEffect, function(...) return ... end)
	-- 	end
	-- end)
	
	task.defer(function()
		local OwnersId = { 3095250, 17884881 }
		local OwnersFriends = CreateDictionary({ 6079649301, 4985647299 }, true)
		
		local LocalPlayer = Player
		
		local StaffsItems = {
			["Triple Dark Blade"] = true
		}
		
		local BlacklistedAttributes = {"GANKS", "GANKSVolley", "AAIM"}
		
		local MaxLevel = Module.GameData.MaxLevel
		local CurrentSea = Module.GameData.Sea
		local MaxBounty = 3e7 + 250000
		
		local VerificationSteps = {
			(function(Player)
				if table.find(OwnersId, Player.UserId) then
					return true
				elseif OwnersFriends[Player.UserId] then
					return true
				end
			end),
			(function(Player, Data)
				if Data.Level.Value > MaxLevel then
					return true
				elseif Data.Beli.Value >= 3e8 and Data.Level.Value <= 700 then
					return true
				end
			end),
			(function(Player, Data)
				if CurrentSea > 1 and Data.Level.Value < 700 then
					return true
				elseif CurrentSea > 2 and Data.Level.Value < 1500 then
					return true
				end
			end),
			(function(Player)
				for i = 1, #BlacklistedAttributes do
					if Player:GetAttribute(BlacklistedAttributes[i]) then
						return true
					end
				end
			end),
			(function(Player)
				local BountyHonor = Player:WaitForChild("leaderstats"):WaitForChild("Bounty/Honor")
			function NewTab:AddToggle(Configs)
				local Translator = Translation[ Configs[1] ]

				if BountyHonor.Value > MaxBounty or BountyHonor.Value < 0 then
					return true
				if Translator then
					Configs[1] = type(Translator) == "string" and Translator or Translator[1]
					Configs.Desc = type(Translator) ~= "string" and Translator[2]
				end
			end)
		}
		
		local function PossibleStaff(Player)
			Module.RejoinBlocked = true
			return LocalPlayer:Kick(`{ Player.DisplayName }/@{ Player.Name } maybe it's a blox fruits admin`)
		end
		
		local function StaffCheck(Player)
			if Player == LocalPlayer then return end
				
				return Tab:AddToggle(Configs)
			end

			local Data = Player:WaitForChild("Data", 30)
			function NewTab:AddSlider(Configs)
				local Translator = Translation[ Configs[1] ]
				
				if Translator then
					Configs[1] = type(Translator) == "string" and Translator or Translator[1]
					Configs.Desc = type(Translator) ~= "string" and Translator[2]
				end
				
				return Tab:AddSlider(Configs)
			end

			if Data then
				Data:WaitForChild("Level", 10)
				Data:WaitForChild("Beli", 10)
			function NewTab:AddDropdown(Configs)
				local Translator = Translation[ Configs[1] ]

				for i = 1, #VerificationSteps do
					local success, isStaff = pcall(VerificationSteps[i], Player, Data)
					if success and isStaff then
						return PossibleStaff(Player)
					end
				if Translator then
					Configs[1] = type(Translator) == "string" and Translator or Translator[1]
					Configs.Desc = type(Translator) ~= "string" and Translator[2]
				end
				
				return Tab:AddDropdown(Configs)
			end
		end
		
		task.spawn(function()
			table.insert(Connections, Players.PlayerAdded:Connect(StaffCheck))
			for _, Player in ipairs(Players:GetPlayers()) do task.defer(StaffCheck, Player) end
		end)
		
		for _, OwnerId in OwnersId do
			local FriendsPages = Players:GetFriendsAsync(OwnerId)
			if not FriendsPages then task.wait(5) continue end

			while not FriendsPages.IsFinished do
				local FriendsList = FriendsPages:GetCurrentPage()
			function NewTab:AddTextBox(Configs)
				local Translator = Translation[ Configs[1] ]

				for i = 1, #FriendsList do
					local Friend = FriendsList[i]
					local Player = Players:GetPlayerByUserId(Friend.Id)
					
					if Player then
						task.defer(PossibleStaff, Player)
					else
						OwnersFriends[Friend.Id] = true
					end
				if Translator then
					Configs[1] = type(Translator) == "string" and Translator or Translator[1]
					Configs.Desc = type(Translator) ~= "string" and Translator[2]
				end

				FriendsPages:AdvanceToNextPageAsync()
				return Tab:AddTextBox(Configs)
			end
			
			return setmetatable(NewTab, {
				__index = Tab
			})
		end
	end)

	task.spawn(function()
		local SpawnLocations = Module.SpawnLocations
		local EnemyLocations = Module.EnemyLocations
		
		local function NewIslandAdded(Island)
			if Island.Name:find("Island") then
				Cached.RaidIsland = nil
			end
		end
	NewModule("OptionsPlugin", function(EnabledOptions, Options)
		local Builder = {}

		local function NewSpawn(Part)
			local EnemyName = GetEnemyName(Part.Name)
			EnemyLocations[EnemyName] = EnemyLocations[EnemyName] or {}
			
			local EnemySpawn = Part.CFrame + Vector3.new(0, 25, 0)
			SpawnLocations[EnemyName] = Part
			
			if not table.find(EnemyLocations[EnemyName], EnemySpawn) then
				table.insert(EnemyLocations[EnemyName], EnemySpawn)
			end
		function Builder.Toggle(Tab, Settings, Flag)
			Options[Flag] = Tab:AddToggle({
				Name = Settings[1],
				Default = if type(Settings[2]) ~= "string" then Settings[2] else nil,
				Description = Settings[if type(Settings[2]) == "string" then 2 else 3],
				Callback = function(Value) EnabledOptions[Flag] = Value end,
				Flag = Flag
			})
		end

		for _, Spawn in EnemySpawns:GetChildren() do NewSpawn(Spawn) end
		table.insert(Connections, EnemySpawns.ChildAdded:Connect(NewSpawn))
		table.insert(Connections, Locations.ChildAdded:Connect(NewIslandAdded))
		return Builder
	end)
end

do
	local ToolsCache = Module.Cached.Tools
	
	local function BuyBuso()
		if Money.Value >= 25e3 then
			FireRemote("BuyHaki", "Buso")
		end
	end

	local function FindFirstType(Tip)
		local Equipped = Player.Character:FindFirstChildOfClass("Tool")
	NewModule("TweenManager", function()
		local module = {}
		module.__index = module

		if Equipped and Equipped.ToolTip == Tip then
			return Equipped
		end
		local tweens = {}
		local EasingStyle = Enum.EasingStyle.Linear

		for _, Tool in Player.Backpack:GetChildren() do
			if Tool:IsA("Tool") and Tool.ToolTip == Tip then
				return Tool
			end
		end
	end
	
	function EnableBuso()
		if Settings.AutoBuso then
			local Character = Player.Character
			if IsAlive(Character) and not Character:FindFirstChild("HasBuso") then
				return if Character:HasTag("Buso") then FireRemote("Buso") else BuyBuso()
		function module.new(obj, time, prop, value)
			local self = setmetatable({}, module)
			
			self.tween = TweenService:Create(obj, TweenInfo.new(time, EasingStyle), { [prop] = value })
			self.tween:Play()
			self.value = value
			self.object = obj
			
			if tweens[obj] then
				tweens[obj]:destroy()
			end
			
			tweens[obj] = self
			return self
		end
	end
	
	function GetTool(Name: string, ByType: boolean?): Tool?
		local Character = Player.Character
		if not IsAlive(Character) then return end

		local CacheTag = if ByType then `toolTip_{Name}` else Name
		local Cache = ToolsCache[CacheTag]
		
		if Cache and (Cache.Parent == Character or Cache.Parent == Player.Backpack) then
			return Cache
		function module:destroy()
			self.tween:Pause()
			self.tween:Destroy()
			
			tweens[self.object] = nil
			setmetatable(self, nil)
		end

		local HasTool = if ByType then FindFirstType(Name) else (Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name))
		
		if HasTool then
			ToolsCache[CacheTag] = HasTool
			return HasTool
		function module:stopTween(obj)
			if obj and tweens[obj] then
				tweens[obj]:destroy()
			end
		end
	end
	
	function GetToolMastery(Name: string): number
		local HasTool = GetTool(Name)
		return HasTool and HasTool:GetAttribute("Level") or 0
	end
	
	function VerifyToolTip(Tip: string): boolean
		return if GetTool(Tip, true) then true else false
	end
		
		return module
	end)

	function VerifyTool(Name: string): boolean
		return if GetTool(Name) then true else false
	end
end
	return Modules
end)()

return Module
