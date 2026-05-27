local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MathMax = math.max
local MathMin = math.min
local MathTan = math.tan
local MathRad = math.rad
local MathClamp = math.clamp
local MathFloor = math.floor
local WhiteColor = Color3.fromRGB(255, 255, 255)
local BlackColor = Color3.fromRGB(0, 0, 0)
local FriendlyStatusColor = Color3.fromRGB(0, 255, 0)
local HostileStatusColor = Color3.fromRGB(255, 70, 70)
local ManipulatedHighlightColor = Color3.fromRGB(255, 123, 8)
local PlayerNeonColor = Color3.fromRGB(121, 166, 184)
local PlayerHighlightColor = Color3.fromRGB(121, 214, 255)
local PlayerHighlightFillTransparency = 0.25
local PlayerHighlightOutlineTransparency = 0
local WeaponFallbackColor = Color3.fromRGB(255, 220, 150)
local HealthLowFallback = Color3.fromRGB(255, 70, 70)
local HealthMidFallback = Color3.fromRGB(255, 210, 90)
local HealthHighFallback = Color3.fromRGB(90, 255, 100)
local AmmoFallbackBase = Color3.fromRGB(89, 122, 255)
local AmmoFallbackFade = Color3.fromRGB(180, 210, 255)
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local istestinggame = Workspace:FindFirstChild("HealthRigJolt")

pcall(function()
    setfflag("AdornShadingAPI", "true")
end)

local function GetItemsModule()
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    local Items = Modules and Modules:FindFirstChild("Items")
    if not Items then
        return {}
    end

    local Success, Result = pcall(require, Items)
    if Success and type(Result) == "table" then
        return Result
    end

    return {}
end

local MainCache = {}
local Cache = MainCache
local MiscCache = {}

local Entities = {
    Main = {
        Cache = MainCache,
        Functions = {},
    },

    Misc = {
        Cache = MiscCache,
        Functions = {},
    },

    Global = {
        ItemsModule = GetItemsModule(),
        IconsCache = {},
    },

    Flags = {},
    WeaponImages = {},
    CanRender = true,
    Camera = Camera,
    FontSize = 10,
    Font = nil,
    SmallFont = nil,
}

Entities.__index = Entities
Entities.Main.Functions.__index = Entities.Main.Functions
Entities.Misc.Functions.__index = Entities.Misc.Functions

local Library = _G.Library or (Modules and Modules.Library)
local Flags = (Library and Library.Flags) or (_G.Flags or {})

local function ResolvePlayerlistStatus(Player)
    if not (Player and typeof(Player) == "Instance" and Player:IsA("Player")) then
        return nil
    end

    local Playerlist = _G.Modules and _G.Modules.Playerlist
    local Entry = Playerlist and Playerlist.Players and Playerlist.Players[Player.Name]
    if type(Entry) == "table" then
        return Entry.Status
    end

    return nil
end

local function ResolveFonts()
    local CurrentLibrary = _G.Library or Library
    local FontCache = (_G.Fonts and _G.Fonts.Cache) or {}
    local Fallback = (CurrentLibrary and CurrentLibrary.Font)

    if typeof(Fallback) ~= "Font" then
        Fallback = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold)
    end

    local MainFont = FontCache.Minecraftia or FontCache.Minecraft or Fallback
    local SmallFont = FontCache.SmallestPixel or FontCache.SmallestPixel7 or FontCache.Minecraftia or Fallback

    Entities.Font = (typeof(MainFont) == "Font" and MainFont) or Fallback
    Entities.SmallFont = (typeof(SmallFont) == "Font" and SmallFont) or Fallback
end

local function ApplyLabelFont(Label, IsFlag)
    if not Entities.Font or not Entities.SmallFont then
        ResolveFonts()
    end
    local Chosen = IsFlag and Entities.SmallFont or Entities.Font

    if typeof(Chosen) == "Font" then
        Label.FontFace = Chosen
    else
        Label.Font = Enum.Font.SourceSansBold
    end
end

ResolveFonts()

local PartRefreshFallback = 0.5
local ChamsRefreshFallback = 0.2

local function Set(Object, Property, Value)
    if Object and Object[Property] ~= Value then
        Object[Property] = Value
    end
end

local LabelMeasureCache = setmetatable({}, { __mode = "k" })

local function InvalidateLabelMeasure(Label)
    if Label then
        local CacheEntry = LabelMeasureCache[Label]
        if CacheEntry then
            CacheEntry.Dirty = true
        else
            LabelMeasureCache[Label] = { Dirty = true, Width = 0, Height = 0 }
        end
    end
end

local function MeasureTextLabel(Label)
    if not Label then
        return 0, 0
    end

    local CacheEntry = LabelMeasureCache[Label]
    if not CacheEntry then
        CacheEntry = { Dirty = true, Width = 0, Height = 0 }
        LabelMeasureCache[Label] = CacheEntry
    end

    if CacheEntry.Dirty then
        local Bounds = Label.TextBounds
        CacheEntry.Width = Bounds.X
        CacheEntry.Height = Bounds.Y
        CacheEntry.Dirty = false
    end

    return CacheEntry.Width or 0, CacheEntry.Height or 0
end

local function ColorsMatch(a, b)
    return a == b
end

local function GetActiveFlags()
    local CurrentLibrary = _G.Library or Library
    return (CurrentLibrary and CurrentLibrary.Flags) or Flags or {}
end

local _buildFlagsCache = nil
local function FlagEntry(Name)
    local Entry = (_buildFlagsCache or GetActiveFlags())[Name]
    return Entry
end

local function FlagValue(Name, Default)
    local Entry = FlagEntry(Name)
    if type(Entry) == "table" and Entry.Value ~= nil then
        return Entry.Value
    end
    if type(Entry) == "table" and Entry.Toggled ~= nil then
        return Entry.Toggled
    end
    if Entry ~= nil and type(Entry) ~= "table" then
        return Entry
    end
    return Default
end

local function FlagAlpha(Name, Default)
    local Entry = FlagEntry(Name)
    if type(Entry) == "table" then
        if Entry.Transparency ~= nil then
            return Entry.Transparency
        end
        if Entry.Alpha ~= nil then
            return Entry.Alpha
        end
    end
    return Default
end

local function FlagData(Name)
    local Entry = FlagEntry(Name)
    if type(Entry) == "table" then
        return Entry
    end
    return {}
end

local function BuildRenderSettings()
    local Settings = {}
    _buildFlagsCache = GetActiveFlags()
    Settings.Enabled = FlagValue("ESPEnabled", false)
    Settings.TargetFPS = tonumber(FlagValue("ESPFrames", 60)) or 60
    Settings.DistanceFramesEnabled = FlagValue("ESPDistanceFrames", false)
    Settings.DistanceFramesThreshold = tonumber(FlagValue("ESPDistanceFramesThreshold", 500)) or 500
    Settings.DistanceFramesHz = tonumber(FlagValue("ESPDistanceFramesHz", 15)) or 15
    Settings.IncludeAI = FlagValue("ESPIncludeAI", false)
    Settings.Teamcheck = FlagValue("ESPTeamcheck", false)
    Settings.Friendcheck = FlagValue("ESPFriendcheck", false)
    Settings.PartRefreshFallback = tonumber(FlagValue("ESPPartRefreshFallback", PartRefreshFallback)) or
        PartRefreshFallback
    Settings.MaxDistance = tonumber(FlagValue("ESPMaxDistance", 3000)) or 3000
    Settings.BoxStyle = FlagValue("ESPBoxStyling", "Corner")
    Settings.BoxEnabled = FlagValue("ESPBoundingBox", false)
    Settings.BoxFilled = FlagValue("ESPBoxFilled", false)
    Settings.BoxGradientRotation = tonumber(FlagValue("ESPBoxFilledGradientRotation", 90)) or 90
    Settings.HealthEnabled = FlagValue("ESPHealthbar", false)
    Settings.HealthThickness = tonumber(FlagValue("ESPHealthThickness", 1)) or 1
    Settings.HealthPos = "Left"
    Settings.HealthText = FlagValue("ESPHealthText", false)
    Settings.HealthTextFollowBar = FlagValue("ESPHealthTextFollowBar", false)
    Settings.AmmoEnabled = FlagValue("ESPAmmobar", false)
    Settings.AmmoThickness = tonumber(FlagValue("ESPAmmoThickness", 1)) or 1
    Settings.AmmoPos = "Bottom"
    Settings.AmmoText = FlagValue("ESPAmmoText", false)
    Settings.AmmoTextFollowBar = FlagValue("ESPAmmoTextFollowBar", false)
    Settings.AmmoRequireWeapon = FlagValue("ESPAmmoRequireWeapon", true)
    Settings.AmmoHideEmpty = FlagValue("ESPAmmoHideEmpty", true)
    Settings.VisibleColor = FlagData("ESPVisibleColor").Color
    Settings.ManipulatedColor = FlagData("ESPManipulatedColor")
    Settings.HitscanColor = FlagData("ESPHitscanColor")
    Settings.BoxColor = FlagData("ESPBoxColor")
    Settings.BoxOutlineColor = FlagData("ESPBoxOutlineColor")
    Settings.ChamsEnabled = FlagValue("ESPChams", false)
    Settings.ChamsStyle = FlagValue("ESPChamsStyle", "Glow")
    Settings.ChamsHiddenColor = FlagData("ESPChamsHiddenColor")
    Settings.ChamsVisibleColor = FlagData("ESPChamsVisibleColor")
    Settings.ChamsRefreshFallback = tonumber(FlagValue("ESPChamsRefreshFallback", ChamsRefreshFallback)) or
        ChamsRefreshFallback
    Settings.FillOne = FlagData("ESPBoxFilledGradientOne")
    Settings.FillTwo = FlagData("ESPBoxFilledGradientTwo")
    Settings.Nametags = FlagValue("ESPNametags", false)
    Settings.NameColor = FlagData("ESPNameColor")
    Settings.PreferDisplayNames = FlagValue("ESPPreferDisplayNames", false)
    Settings.NamePosition = "Top"
    Settings.Distance = FlagValue("ESPDistance", false)
    Settings.DistanceColor = FlagData("ESPDistanceColor")
    Settings.DistancePosition = "Bottom"
    Settings.Weapon = FlagValue("ESPWeapon", false)
    Settings.WeaponColor = FlagData("ESPWeaponColor")
    Settings.WeaponPosition = "Bottom"
    Settings.WeaponIcon = FlagValue("ESPWeaponIcon", false)
    Settings.WeaponIconPosition = "Bottom"
    Settings.HealthGradientLow = FlagData("ESPHealthGradientLow")
    Settings.HealthGradientMid = FlagData("ESPHealthGradientMid")
    Settings.HealthGradientHigh = FlagData("ESPHealthGradientHigh")
    Settings.HealthTextColor = FlagData("ESPHealthTextColor")
    Settings.AmmoColor = FlagData("ESPAmmoColor")
    Settings.AmmoTextColor = FlagData("ESPAmmoTextColor")
    Settings.FlagsEnabled = FlagValue("ESPFlags", false)
    Settings.Units = FlagValue("ESPUnits", "Studs")
    Settings.FlagSide = "Right"
    Settings.BoxSizing = FlagValue("ESPBoxSizing", "Static")
    Settings.HasOverlayElements = Settings.BoxEnabled
        or Settings.HealthEnabled
        or Settings.AmmoEnabled
        or Settings.Nametags
        or Settings.Distance
        or Settings.Weapon
        or Settings.WeaponIcon
        or Settings.FlagsEnabled
    Settings.NeedsVisibleCheck = Settings.VisibleColor ~= nil and Settings.HasOverlayElements
    Settings.NeedsPartRefresh = Settings.NeedsVisibleCheck or Settings.ChamsEnabled
    Settings.HasAnyWork = Settings.HasOverlayElements or Settings.ChamsEnabled
    Settings.CloseUpdateInterval = Settings.TargetFPS > 0 and (1 / Settings.TargetFPS) or 0
    _buildFlagsCache = nil
    return Settings
end

local CachedRenderSettings = nil
local CachedRenderSettingsNextUpdate = 0
local CachedFlagRenderSettings = {}
local CachedEnabledFlagNames = {}
local function GetRenderSettings(Now)
    if CachedRenderSettings and Now < CachedRenderSettingsNextUpdate then
        return CachedRenderSettings
    end

    local Settings = BuildRenderSettings()
    CachedRenderSettings = Settings
    CachedRenderSettingsNextUpdate = Now + 0.12

    local FlagSettings = {}
    local EnabledFlagNames = {}
    if Settings.FlagsEnabled then
        for Name in next, Entities.Flags do
            local ColorData = FlagData(Name .. "Color")
            local ToggleValue = FlagValue("ESPFlag" .. Name, nil)
            local Enabled = ToggleValue == nil and true or ToggleValue
            FlagSettings[Name] = {
                Enabled = Enabled,
                Color = ColorData.Color or WhiteColor,
                Transparency = ColorData.Transparency or 0,
            }
            if Enabled then
                EnabledFlagNames[#EnabledFlagNames + 1] = Name
            end
        end
    end
    CachedFlagRenderSettings = FlagSettings
    CachedEnabledFlagNames = EnabledFlagNames

    return Settings
end

local ManipulationOffsets = {
    CFrame.new(3, 0, 0), CFrame.new(-3, 0, 0), CFrame.new(-6, 0, 0),
    CFrame.new(6, 0, 0), CFrame.new(3, 2, 0), CFrame.new(-3, 2, 0),
    CFrame.new(-6, 2, 0), CFrame.new(6, 2, 0), CFrame.new(4, 0, 0),
    CFrame.new(-4, 2, 0), CFrame.new(-4, 0, 0), CFrame.new(4, 2, 0),
    CFrame.new(7, 0, 0), CFrame.new(-7, 2, 0), CFrame.new(-7, 0, 0),
    CFrame.new(7, 2, 0), CFrame.new(0.2, 3.9, 0), CFrame.new(1.8, 4.1, 1),
    CFrame.new(2.1, 4.4, 1.1), CFrame.new(0.15, 5.2, 0.1), CFrame.new(-1.8, 5.4, -0.2),
    CFrame.new(-2.3, 6.35, -0.4), CFrame.new(0.1, 7.5, 0), CFrame.new(0.1, 8, 0),
    CFrame.new(0.1, 8, 0),
}

local UndergroundOffsets = {
    CFrame.new(3, -2, 0), CFrame.new(-3, -2, 0),
    CFrame.new(6, -3, 0), CFrame.new(-6, -3, 0),
    CFrame.new(4, -2, 2), CFrame.new(-4, -2, -2),
    CFrame.new(7, -5, 0), CFrame.new(-7, -5, 0),
    CFrame.new(5, -6, 3), CFrame.new(-5, -6, -3),
    CFrame.new(2, -7, 0), CFrame.new(-2, -7, 0),
    CFrame.new(0, -6, 0), CFrame.new(0, -8, 0),
    CFrame.new(0, -8, 0), CFrame.new(0, -5, 0),
    CFrame.new(3, -9, 2), CFrame.new(-3, -9, -2),
    CFrame.new(6, -10, 0), CFrame.new(-6, -10, 0),
    CFrame.new(4, -8, 4), CFrame.new(-4, -8, -4),
    CFrame.new(1, -10, 3), CFrame.new(-1, -10, -3),
}

Entities.Ray = Entities.Ray or {}
Entities.Ray.Filter = Entities.Ray.Filter or { Camera, LocalPlayer.Character }
Entities.Ray.FilterType = Entities.Ray.FilterType or Enum.RaycastFilterType.Exclude
Entities.Ray.IgnoreWater = true

local EmptyFilter = {}
local function BuildRaycastParams(self)
    local Params = rawget(self, "_params")
    if not Params then
        Params = RaycastParams.new()
        rawset(self, "_params", Params)
    end
    Params.FilterType = self.FilterType or Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = self.Filter or EmptyFilter
    Params.IgnoreWater = self.IgnoreWater ~= false
    return Params
end

function Entities.Ray:SetFilter(Filter)
    self.Filter = Filter or {}
end

function Entities.Ray:SetFilterType(FilterType)
    self.FilterType = FilterType or Enum.RaycastFilterType.Exclude
end

function Entities.Ray:SetIgnoreWater(State)
    self.IgnoreWater = State ~= false
end

function Entities.Ray:Send(Origin, Destination)
    if not Origin or not Destination then
        return nil
    end
    local Delta = Destination - Origin
    if Delta.X == 0 and Delta.Y == 0 and Delta.Z == 0 then
        return nil
    end
    return Workspace:Raycast(Origin, Delta, BuildRaycastParams(self))
end

function Entities.Ray:SendToDirection(Origin, Direction, Distance)
    if not Origin or not Direction then
        return nil
    end
    if Direction.X == 0 and Direction.Y == 0 and Direction.Z == 0 then
        return nil
    end
    local Length = (tonumber(Distance) or 0) + 7.5
    return Workspace:Raycast(Origin, Direction.Unit * Length, BuildRaycastParams(self))
end

function Entities.Ray:IsPartVisible(Origin, Part, Model)
    if not Origin or not Part then
        return false
    end
    local Result = self:Send(Origin, Part.CFrame.Position)
    if not Result or not Result.Instance then
        return false
    end
    if Model and Result.Instance:IsDescendantOf(Model) then
        return true, Origin, Part
    end
    if Result.Instance == Part then
        return true, Origin, Part
    end
    return false
end

function Entities.Ray:FindVisiblePositionOnModel(Origin, Model, PartsList)
    local Results = {}
    if not Origin or not Model or type(PartsList) ~= "table" then
        return Results
    end

    local Parts = {}
    for _, PartName in ipairs(PartsList) do
        local Part = Model:FindFirstChild(PartName)
        if Part then
            Parts[#Parts + 1] = Part
        end
    end
    if #Parts == 0 then
        return Results
    end

    for _, Offset in ipairs(ManipulationOffsets) do
        local WorldPosition = (Origin * Offset).Position
        for _, Part in ipairs(Parts) do
            if self:IsPartVisible(WorldPosition, Part) then
                Results[#Results + 1] = {
                    Part = Part,
                    NewOrigin = WorldPosition,
                    OldOrigin = Origin,
                }
            end
        end
    end
    return Results
end

function Entities.Ray:FindVisiblePositionOnPart(Origin, Part)
    if not Origin or not Part then
        return {}
    end
    for _, Offset in ipairs(ManipulationOffsets) do
        local WorldPosition = (Origin * Offset).Position
        if self:IsPartVisible(WorldPosition, Part) then
            return { {
                Part = Part,
                NewOrigin = WorldPosition,
                OldOrigin = Origin,
            } }
        end
    end
    return {}
end

function Entities.Ray:FindUndergroundVisiblePositionOnModel(Origin, Model, PartsList)
    local Results = {}
    if not Origin or not Model or type(PartsList) ~= "table" then
        return Results
    end

    local Parts = {}
    for _, PartName in ipairs(PartsList) do
        local Part = Model:FindFirstChild(PartName)
        if Part then
            Parts[#Parts + 1] = Part
        end
    end
    if #Parts == 0 then
        return Results
    end

    for _, Offset in ipairs(UndergroundOffsets) do
        local WorldPosition = (Origin * Offset).Position
        for _, Part in ipairs(Parts) do
            if self:IsPartVisible(WorldPosition, Part) then
                Results[#Results + 1] = {
                    Part = Part,
                    NewOrigin = WorldPosition,
                    OldOrigin = Origin,
                }
            end
        end
    end
    return Results
end

function Entities.Ray:FindUndergroundVisiblePositionOnPart(Origin, Part)
    if not Origin or not Part then
        return {}
    end
    for _, Offset in ipairs(UndergroundOffsets) do
        local WorldPosition = (Origin * Offset).Position
        if self:IsPartVisible(WorldPosition, Part) then
            return { {
                Part = Part,
                NewOrigin = WorldPosition,
                OldOrigin = Origin,
            } }
        end
    end
    return {}
end

local MaterialMap = {
    Forcefield = Enum.Material.ForceField,
    ForceField = Enum.Material.ForceField,
    Neon = Enum.Material.Neon,
    Glass = Enum.Material.Glass,
    SmoothPlastic = Enum.Material.SmoothPlastic,
}

Entities.Main.Functions.StoreOriginals = function(self, instance)
    if not instance:GetAttribute("OriginalMaterial") and instance:IsA("BasePart") then
        instance:SetAttribute("OriginalMaterial", instance.Material)
        instance:SetAttribute("OriginalColor", instance.Color)
        instance:SetAttribute("OriginalReflectance", instance.Reflectance)
        instance:SetAttribute("OriginalTransparency", instance.Transparency)
        if instance:IsA("MeshPart") then
            instance:SetAttribute("OriginalTextureId", instance.TextureID)
        end
    elseif (
            instance:IsA("SurfaceAppearance")
            or instance:IsA("SpecialMesh")
            or instance:IsA("Decal")
            or instance:IsA("Texture")
            or instance:IsA("Shirt")
            or instance:IsA("Pants")
            or instance:IsA("ShirtGraphic")
            or instance:IsA("CharacterMesh")
            or instance:IsA("BodyColors")
        ) and not self.SurfaceAppearances[instance] then
        self.SurfaceAppearances[instance] = instance.Parent
    end
end

local function ResolveRequestedMaterial(RequestedMaterial, DefaultMaterial)
    if typeof(RequestedMaterial) == "EnumItem" then
        return RequestedMaterial
    end
    return MaterialMap[RequestedMaterial] or DefaultMaterial
end

local function DestroyAdornmentCache(AdornmentCache)
    if type(AdornmentCache) ~= "table" then
        return
    end

    for Part, Adornments in next, AdornmentCache do
        if type(Adornments) == "table" then
            for _, Adornment in next, Adornments do
                if typeof(Adornment) == "Instance" then
                    Adornment:Destroy()
                end
            end
        end
        AdornmentCache[Part] = nil
    end
end

local function DestroyCharacterChams(self)
    DestroyAdornmentCache(self.Adornments)
    self.Adornments = {}
end

local function RemoveAdorns(Part)
    if not Part then
        return
    end

    for _, Child in next, Part:GetChildren() do
        if Child.Name == "Chams" or Child.Name == "Glow" then
            Child:Destroy()
        end
    end
end

local function CreateAdornment(Part, Type, Color, Transparency, ZIndex, SizeOffset, Extra)
    Extra = Extra or {}

    local Adornment
    if Type == "Cylinder" then
        Adornment = Instance.new("CylinderHandleAdornment")
        Adornment.Height = Part.Size.Y + (Extra.HeightOffset or 0)
        Adornment.Radius = (Part.Size.X * 0.5) + (Extra.RadiusOffset or 0)
        Adornment.CFrame = CFrame.new(Vector3.new(), Vector3.new(0, 1, 0))
    elseif Type == "Box" then
        Adornment = Instance.new("BoxHandleAdornment")
        Adornment.Size = Part.Size + (SizeOffset or Vector3.new())
    else
        return nil
    end

    Adornment.Name = "Chams"
    Adornment.AlwaysOnTop = true
    Adornment.ZIndex = ZIndex
    Adornment.Adornee = Part
    Adornment.Color3 = Color
    Adornment.Transparency = Transparency or 0

    if Extra.Shading then
        pcall(function()
            Adornment.Shading = Extra.Shading
        end)
    end

    Adornment.Parent = Part
    return Adornment
end

local function ApplyCharacterChams(self, Settings)
    local Character = self.Character
    if not Character or self.IsPreview then
        DestroyCharacterChams(self)
        return
    end

    local BodyParts = self.BodyParts or {}
    local MainColor = Settings.ChamsHiddenColor.Color or Color3.fromRGB(152, 188, 255)
    local GlowColor = Settings.ChamsVisibleColor.Color or Color3.fromRGB(152, 188, 255)
    local MainTransparency = Settings.ChamsHiddenColor.Transparency or 0.5

    self.Adornments = self.Adornments or {}
    local SeenParts = {}

    for _, Part in next, BodyParts do
        if Part and Part.Parent == Character and Part:IsA("BasePart") and Part.Transparency < 1 then
            SeenParts[Part] = true
            local IsHead = (Part.Name == "Head") or (Part.Name == "FakeHead")
            local GlowTargetColor = Color3.new(GlowColor.R * 5, GlowColor.G * 5, GlowColor.B * 5)

            local Existing = self.Adornments[Part]
            local GlowAdornment = Existing and Existing[1]
            local MainAdornment = Existing and Existing[2]

            if typeof(GlowAdornment) ~= "Instance" or GlowAdornment.Parent ~= Part then
                RemoveAdorns(Part)
                GlowAdornment = CreateAdornment(
                    Part,
                    "Box",
                    GlowTargetColor,
                    -1,
                    IsHead and 10 or 9,
                    Vector3.new(0.03, 0.03, 0.03),
                    { Shading = Enum.AdornShading.XRayShaded }
                )
            end

            if typeof(MainAdornment) ~= "Instance" or MainAdornment.Parent ~= Part then
                MainAdornment = CreateAdornment(
                    Part,
                    "Box",
                    MainColor,
                    MainTransparency,
                    10,
                    Vector3.new(0.02, 0.02, 0.02)
                )
            end

            if GlowAdornment then
                Set(GlowAdornment, "Adornee", Part)
                Set(GlowAdornment, "AlwaysOnTop", true)
                Set(GlowAdornment, "ZIndex", IsHead and 10 or 9)
                Set(GlowAdornment, "Color3", GlowTargetColor)
                Set(GlowAdornment, "Transparency", -1)
                if GlowAdornment:IsA("BoxHandleAdornment") then
                    Set(GlowAdornment, "Size", Part.Size + Vector3.new(0.03, 0.03, 0.03))
                end
            end

            if MainAdornment then
                Set(MainAdornment, "Adornee", Part)
                Set(MainAdornment, "AlwaysOnTop", true)
                Set(MainAdornment, "ZIndex", 10)
                Set(MainAdornment, "Color3", MainColor)
                Set(MainAdornment, "Transparency", MainTransparency)
                if MainAdornment:IsA("BoxHandleAdornment") then
                    Set(MainAdornment, "Size", Part.Size + Vector3.new(0.02, 0.02, 0.02))
                end
            end

            self.Adornments[Part] = { GlowAdornment, MainAdornment }
        elseif Part then
            local Existing = self.Adornments[Part]
            if Existing then
                for _, Adornment in next, Existing do
                    if typeof(Adornment) == "Instance" then
                        Adornment:Destroy()
                    end
                end
                self.Adornments[Part] = nil
            end
        end
    end

    for Part, Existing in next, self.Adornments do
        if not SeenParts[Part] then
            for _, Adornment in next, Existing do
                if typeof(Adornment) == "Instance" then
                    Adornment:Destroy()
                end
            end
            self.Adornments[Part] = nil
        end
    end
end

local function ApplyPartVisualState(StateCache, Instance, Color, Reflectance, Material, TextureId, Transparency)
    local State = StateCache[Instance]
    if not State then
        State = {}
        StateCache[Instance] = State
    end

    if not ColorsMatch(State.Color, Color) then
        Instance.Color = Color
        State.Color = Color
    end
    if State.Reflectance ~= Reflectance then
        Instance.Reflectance = Reflectance
        State.Reflectance = Reflectance
    end
    if State.Material ~= Material then
        Instance.Material = Material
        State.Material = Material
    end
    if Transparency ~= nil and State.Transparency ~= Transparency then
        Instance.Transparency = Transparency
        State.Transparency = Transparency
    end
    if Instance:IsA("MeshPart") and State.TextureID ~= TextureId then
        Instance.TextureID = TextureId
        State.TextureID = TextureId
    end
end

local function ApplySurfaceAppearanceState(StateCache, Instance, Parent)
    local State = StateCache[Instance]
    if not State then
        State = {}
        StateCache[Instance] = State
    end

    if State.Parent ~= Parent then
        Instance.Parent = Parent
        State.Parent = Parent
    end
end

local function EnsureCharacterHighlight(self)
    if self.IsPreview then
        return nil
    end

    local Character = self.Character
    if not Character then
        return nil
    end

    local Highlight = self.CharacterHighlight
    if Highlight and Highlight.Parent ~= Character then
        Highlight:Destroy()
        Highlight = nil
        self.CharacterHighlight = nil
    end

    if not Highlight then
        Highlight = Instance.new("Highlight")
        Highlight.Name = "ESPHighlight"
        Highlight.Adornee = Character
        Highlight.Enabled = false
        Highlight.Parent = Character
        self.CharacterHighlight = Highlight
    end

    if Highlight.Adornee ~= Character then
        Highlight.Adornee = Character
    end

    return Highlight
end

local function HasExternalCharacterHighlight(self)
    local Character = self.Character
    if not Character then
        return false
    end

    local OwnHighlight = self.CharacterHighlight
    for _, Child in next, Character:GetChildren() do
        if Child:IsA("Highlight") and Child ~= OwnHighlight then
            return true
        end
    end

    return false
end

local function UpdateCharacterHighlightCache(self)
    local HasExternal = HasExternalCharacterHighlight(self)
    self._hasExternalHighlight = HasExternal

    if HasExternal and self.CharacterHighlight then
        Set(self.CharacterHighlight, "Enabled", false)
    end

    return HasExternal
end

Entities.Main.Functions.ApplyArmorVisuals = function(self, Instance)
    if Instance:IsA("SurfaceAppearance") or Instance:IsA("SpecialMesh") then
        self:StoreOriginals(Instance)
        Instance.Parent = self.SurfaceAppearances[Instance]
        return
    end

    if Instance:IsA("BasePart") and Instance.Transparency ~= 1 then
        self:StoreOriginals(Instance)
        Instance.Color = Instance:GetAttribute("OriginalColor")
        Instance.Material = Instance:GetAttribute("OriginalMaterial")
        Instance.Reflectance = Instance:GetAttribute("OriginalReflectance")
        Instance.Transparency = Instance:GetAttribute("OriginalTransparency")

        if Instance:IsA("MeshPart") then
            Instance.TextureID = Instance:GetAttribute("OriginalTextureId")
        end
    end
end

Entities.Main.Functions.ApplySandboxing = function(self, Instance)
    if Instance:IsA("BasePart") and Instance.Transparency ~= 1 then
        self:StoreOriginals(Instance)
        Instance.Color = Instance:GetAttribute("OriginalColor")
        Instance.Material = Instance:GetAttribute("OriginalMaterial")
        Instance.Reflectance = Instance:GetAttribute("OriginalReflectance")
        Instance.Transparency = Instance:GetAttribute("OriginalTransparency")

        if Instance:IsA("MeshPart") then
            Instance.TextureID = Instance:GetAttribute("OriginalTextureId")
        end
    end
end

local Holder = Instance.new("ScreenGui")
Holder.Name = "\0"
Holder.DisplayOrder = -100
Holder.ZIndexBehavior = Enum.ZIndexBehavior.Global
Holder.IgnoreGuiInset = true
Holder.ResetOnSpawn = false
Holder.Parent = gethui()


function Entities.Misc.New(_, Data)
    if type(Data) ~= "table" then
        return nil
    end

    local Pointer = Data.Pointer or Data.Instance
    if not Pointer then
        return nil
    end

    local Existing = MiscCache[Pointer]
    if Existing then
        return Existing
    end

    local Entity = setmetatable({
        Flag = Data.Flag or "Misc",
        ClassType = Data.ClassType or Data.Flag or "Misc",
        Pointer = Pointer,
        Instance = Data.Instance,
        GetName = Data.GetName or function()
            return Data.Name or tostring(Data.Flag or "Misc")
        end,
        GetPosition = Data.GetPosition or function()
            return Data.Position
        end,
        GetColor = Data.GetColor or function(self)
            local Entry = self.ColorFlag and FlagData(self.ColorFlag) or {}
            return Entry.Color or WhiteColor
        end,
        Validate = Data.Validate or function()
            return true
        end,
        SetCustoms = Data.SetCustoms or function()
        end,
        IsEnabled = Data.IsEnabled,
        GetMaxDistance = Data.GetMaxDistance,
        GetSandboxEnabled = Data.GetSandboxEnabled,
        GetSandboxColor = Data.GetSandboxColor,
        GetSandboxMaterial = Data.GetSandboxMaterial,
        GetSandboxReflectance = Data.GetSandboxReflectance,
        GetSandboxReflectanceMultiplier = Data.GetSandboxReflectanceMultiplier,
        GetAlpha = Data.GetAlpha,
        ColorFlag = Data.ColorFlag,
        DistanceFlag = Data.DistanceFlag,
        SandboxFlag = Data.SandboxFlag,
        SandboxColorFlag = Data.SandboxColorFlag,
        SandboxMaterialFlag = Data.SandboxMaterialFlag,
        SandboxReflectanceFlag = Data.SandboxReflectanceFlag,
        SandboxReflectanceMultiplierFlag = Data.SandboxReflectanceMultiplierFlag,
        SurfaceAppearances = setmetatable({}, { __mode = "k" }),
        VisualState = setmetatable({}, { __mode = "k" }),
        SurfaceVisualState = setmetatable({}, { __mode = "k" }),
        LastRefresh = 0,
        _LastSandboxState = nil,
        _LastTransparency = nil,
    }, Entities.Misc.Functions)

    local Components = {}
    local Frame = Instance.new("Frame")
    Frame.Name = "MiscHolder"
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundTransparency = 1
    Frame.Size = UDim2.fromOffset(220, 18)
    Frame.Visible = false
    Frame.Parent = Holder
    Components.Holder = Frame

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 0)
    Layout.FillDirection = Enum.FillDirection.Vertical
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Frame

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "Name"
    NameLabel.BackgroundTransparency = 1
    NameLabel.AutomaticSize = Enum.AutomaticSize.XY
    NameLabel.Size = UDim2.fromOffset(0, 0)
    NameLabel.Text = ""
    NameLabel.TextSize = 10
    NameLabel.RichText = true
    NameLabel.TextStrokeTransparency = 0
    NameLabel.TextXAlignment = Enum.TextXAlignment.Center
    NameLabel.TextYAlignment = Enum.TextYAlignment.Top
    ApplyLabelFont(NameLabel, false)
    NameLabel.Parent = Frame
    Components.Name = NameLabel

    Entity.Components = Data.Components or Components
    MiscCache[Pointer] = Entity
    if Entity.Instance and Entity.Instance ~= Pointer then
        MiscCache[Entity.Instance] = Entity
    end
    return Entity
end

function Entities.Misc.Functions.SetTransparency(self, Transparency)
    local Components = self.Components
    local HolderObject = Components and Components.Holder
    if not HolderObject then
        return
    end

    if self._LastTransparency == Transparency then
        return
    end
    self._LastTransparency = Transparency

    local Targets = self._TransparencyTargets
    if not Targets then
        Targets = {
            Text = {},
            Image = {},
            Frame = {},
            Stroke = {},
        }

        for _, Descendant in ipairs(HolderObject:GetDescendants()) do
            if Descendant:IsA("TextLabel") then
                Targets.Text[#Targets.Text + 1] = Descendant
            elseif Descendant:IsA("ImageLabel") then
                Targets.Image[#Targets.Image + 1] = Descendant
            elseif Descendant:IsA("Frame") and Descendant ~= HolderObject then
                Targets.Frame[#Targets.Frame + 1] = Descendant
            elseif Descendant:IsA("UIStroke") then
                Targets.Stroke[#Targets.Stroke + 1] = Descendant
            end
        end

        self._TransparencyTargets = Targets
    end

    for _, Descendant in ipairs(Targets.Text) do
        if Descendant.Parent then
            Set(Descendant, "TextTransparency", Transparency)
            Set(Descendant, "TextStrokeTransparency", Transparency)
        end
    end

    for _, Descendant in ipairs(Targets.Image) do
        if Descendant.Parent then
            Set(Descendant, "ImageTransparency", Transparency)
        end
    end

    for _, Descendant in ipairs(Targets.Frame) do
        if Descendant.Parent then
            Set(Descendant, "BackgroundTransparency", Transparency)
        end
    end

    for _, Descendant in ipairs(Targets.Stroke) do
        if Descendant.Parent then
            Set(Descendant, "Transparency", Transparency)
        end
    end
end

function Entities.Misc.Functions.StoreOriginals(self, Instance)
    if not Instance:GetAttribute("OriginalMaterial") and Instance:IsA("BasePart") then
        Instance:SetAttribute("OriginalMaterial", Instance.Material)
        Instance:SetAttribute("OriginalColor", Instance.Color)
        Instance:SetAttribute("OriginalReflectance", Instance.Reflectance)
        if Instance:IsA("MeshPart") then
            Instance:SetAttribute("OriginalTextureId", Instance.TextureID)
        end
    elseif (Instance:IsA("SurfaceAppearance") and not self.SurfaceAppearances[Instance])
        or (Instance:IsA("SpecialMesh") and not self.SurfaceAppearances[Instance])
    then
        self.SurfaceAppearances[Instance] = Instance.Parent
    end
end

function Entities.Misc.Functions.ApplyVisuals(self, Instance)
    if not Instance then
        return
    end

    local SandboxEnabled = self.GetSandboxEnabled and self:GetSandboxEnabled()
    if SandboxEnabled == nil then
        SandboxEnabled = self.SandboxFlag and FlagValue(self.SandboxFlag, false) or false
    end

    if Instance:IsA("SurfaceAppearance") then
        self:StoreOriginals(Instance)
        local DesiredParent = SandboxEnabled and nil or self.SurfaceAppearances[Instance]
        ApplySurfaceAppearanceState(self.SurfaceVisualState, Instance, DesiredParent)
        return
    end

    if not Instance:IsA("BasePart") or Instance.Transparency == 1 then
        return
    end

    self:StoreOriginals(Instance)
    if SandboxEnabled then
        local SandboxColorData = self.GetSandboxColor and self:GetSandboxColor()
        if type(SandboxColorData) ~= "table" then
            SandboxColorData = self.SandboxColorFlag and FlagData(self.SandboxColorFlag) or {}
        end

        local Color = SandboxColorData.Color or Instance:GetAttribute("OriginalColor") or Instance.Color
        local Reflectance = self.GetSandboxReflectance and self:GetSandboxReflectance()
        if Reflectance == nil then
            Reflectance = self.SandboxReflectanceFlag and FlagValue(self.SandboxReflectanceFlag, 0) or 0
        end
        local ReflectanceMul = self.GetSandboxReflectanceMultiplier and self:GetSandboxReflectanceMultiplier()
        if ReflectanceMul == nil then
            ReflectanceMul = self.SandboxReflectanceMultiplierFlag
                and FlagValue(self.SandboxReflectanceMultiplierFlag, 1)
                or 1
        end

        local RequestedMaterial = self.GetSandboxMaterial and self:GetSandboxMaterial()
        if RequestedMaterial == nil then
            RequestedMaterial = self.SandboxMaterialFlag and FlagValue(self.SandboxMaterialFlag, "ForceField")
                or "ForceField"
        end

        local Material = ResolveRequestedMaterial(RequestedMaterial,
            Instance:GetAttribute("OriginalMaterial") or Instance.Material)
        local TextureId = nil
        if Instance:IsA("MeshPart") then
            TextureId = Material == Enum.Material.ForceField and "rbxassetid://10913193650" or ""
        end

        ApplyPartVisualState(
            self.VisualState,
            Instance,
            Color,
            (Reflectance or 0) * (ReflectanceMul or 1),
            Material,
            TextureId
        )
    else
        ApplyPartVisualState(
            self.VisualState,
            Instance,
            Instance:GetAttribute("OriginalColor"),
            Instance:GetAttribute("OriginalReflectance"),
            Instance:GetAttribute("OriginalMaterial"),
            Instance:IsA("MeshPart") and Instance:GetAttribute("OriginalTextureId") or nil
        )
    end
end

function Entities.Misc.Functions.Update(self, Now)
    local Components = self.Components
    local HolderObject = Components and Components.Holder
    if not HolderObject then
        return
    end

    Now = Now or os.clock()
    Set(HolderObject, "Visible", false)

    local InstanceObject = self.Instance
    local SandboxEnabled = self.GetSandboxEnabled and self:GetSandboxEnabled()
    if SandboxEnabled == nil then
        SandboxEnabled = self.SandboxFlag and FlagValue(self.SandboxFlag, false) or false
    end

    if InstanceObject and InstanceObject.Parent and (self._LastSandboxState ~= SandboxEnabled or (Now - self.LastRefresh) >= 0.4) then
        self.LastRefresh = Now
        self._LastSandboxState = SandboxEnabled
        self:ApplyVisuals(InstanceObject)
        for _, Descendant in ipairs(InstanceObject:GetDescendants()) do
            self:ApplyVisuals(Descendant)
        end
    end

    local Enabled = self.IsEnabled and self:IsEnabled()
    if Enabled == nil then
        Enabled = FlagValue("Misc" .. tostring(self.Flag), false)
    end
    if FlagValue("CombatHide", false) or not Enabled then
        Set(HolderObject, "Visible", false)
        return "no"
    end

    local Position = self:GetPosition()
    if typeof(Position) ~= "Vector3" then
        Set(HolderObject, "Visible", false)
        return
    end

    local CameraObject = Entities.Camera
    if not CameraObject then
        Set(HolderObject, "Visible", false)
        return
    end

    local ScreenPosition, IsOnScreen = CameraObject:WorldToViewportPoint(Position)
    if not IsOnScreen or ScreenPosition.Z <= 0 then
        Set(HolderObject, "Visible", false)
        return
    end

    local CameraPosition = self._FrameCameraPosition or CameraObject.CFrame.Position
    local DistanceStuds = (Position - CameraPosition).Magnitude
    local Distance = MathFloor(DistanceStuds)
    self.Distance = Distance
    self.DistanceStuds = Distance

    local MaxDistance = self.GetMaxDistance and self:GetMaxDistance()
    if MaxDistance == nil then
        MaxDistance = self.DistanceFlag and FlagValue(self.DistanceFlag, math.huge)
            or FlagValue("Misc" .. tostring(self.Flag) .. "Distance", math.huge)
    end

    local Valid = self:Validate()
    if not Valid or Distance > MaxDistance then
        Set(HolderObject, "Visible", false)
        return
    end

    Set(HolderObject, "Visible", true)

    local MousePosition = self._FrameMousePosition or UserInputService:GetMouseLocation()
    local MouseDelta = Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MousePosition
    local Deviation = MouseDelta.Magnitude
    local Transparency = 0
    if self.GetAlpha then
        Transparency = self:GetAlpha(ScreenPosition, Position) or 0
    elseif FlagValue("FOVBased", false) then
        local RadiusDegrees = tonumber(FlagValue("FOVBasedRadius", 20)) or 20
        local Viewport = self._FrameViewportSize or (CameraObject and CameraObject.ViewportSize) or Vector2.zero
        local FullScreenRadius = Viewport.Magnitude
        local Radius = FullScreenRadius * MathClamp(RadiusDegrees / 360, 0, 1)
        Transparency = Radius > 0 and (Deviation <= Radius and MathClamp(Deviation / Radius, 0, 1) or 1) or 1
    else
        Transparency = 0
    end

    self:SetTransparency(Transparency)
    Set(HolderObject, "Position", UDim2.fromOffset(MathFloor(ScreenPosition.X), MathFloor(ScreenPosition.Y)))
    self.Expand = Deviation <= (tonumber(FlagValue("ExpandTextRadius", 150)) or 150)

    self:SetCustoms()

    if Components.Name then
        local Text = self:GetName()
        local Color = self:GetColor() or WhiteColor
        Set(Components.Name, "RichText", true)
        Set(Components.Name, "Text", Text)
        Set(Components.Name, "TextColor3", Color)
    end
end

local function ProjectToScreen(ProjectionCamera, ViewportSize, WorldPosition)
    if not ProjectionCamera then
        return nil, false
    end

    if not ViewportSize then
        local Point, OnScreen = ProjectionCamera:WorldToViewportPoint(WorldPosition)
        return Point, OnScreen and Point.Z > 0
    end

    local Relative = ProjectionCamera.CFrame:PointToObjectSpace(WorldPosition)
    local Depth = -Relative.Z
    if Depth <= 0 then
        return nil, false
    end

    local Width = MathMax(ViewportSize.X, 1)
    local Height = MathMax(ViewportSize.Y, 1)
    local Aspect = Width / Height
    local TanHalfFov = MathTan(MathRad(ProjectionCamera.FieldOfView) * 0.5)
    if TanHalfFov <= 0 then
        return nil, false
    end

    local NormalizedX = (Relative.X / Depth) / (TanHalfFov * Aspect)
    local NormalizedY = (Relative.Y / Depth) / TanHalfFov
    local ScreenX = (NormalizedX * 0.5 + 0.5) * Width
    local ScreenY = (-NormalizedY * 0.5 + 0.5) * Height
    local OnScreen = ScreenX >= 0 and ScreenX <= Width and ScreenY >= 0 and ScreenY <= Height
    return Vector3.new(ScreenX, ScreenY, Depth), OnScreen
end

local function GetDynamicBoxBounds(model, root, BodyParts)
    local Parts = BodyParts or (model and model:GetChildren())
    if not Parts or not root then
        return nil, nil
    end

    local Orientation = root.CFrame
    local Inf = math.huge
    local MinX, MinY, MinZ = Inf, Inf, Inf
    local MaxX, MaxY, MaxZ = -Inf, -Inf, -Inf

    for _, Part in next, Parts do
        if Part and Part:IsA("BasePart") and Part.Parent then
            local IgnorePart = false
            if not BodyParts then
                local Name = string.lower(Part.Name or "")
                IgnorePart = Part:GetAttribute("PDIgnoreChams") == true
                    or Name == "ignoreme"
                    or Name == "pdserverpositionclone"
                    or Name:find("lagcham", 1, true) ~= nil
                    or Name:find("fakecham", 1, true) ~= nil
                    or Name:find("createfakechams", 1, true) ~= nil
            end

            if IgnorePart then
                continue
            end

            local Cf = Orientation:ToObjectSpace(Part.CFrame)
            local Sx, Sy, Sz = Part.Size.X, Part.Size.Y, Part.Size.Z
            local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = Cf:components()

            local Wsx = 0.5 * (math.abs(R00) * Sx + math.abs(R01) * Sy + math.abs(R02) * Sz)
            local Wsy = 0.5 * (math.abs(R10) * Sx + math.abs(R11) * Sy + math.abs(R12) * Sz)
            local Wsz = 0.5 * (math.abs(R20) * Sx + math.abs(R21) * Sy + math.abs(R22) * Sz)

            MinX = MathMin(MinX, X - Wsx)
            MinY = MathMin(MinY, Y - Wsy)
            MinZ = MathMin(MinZ, Z - Wsz)
            MaxX = MathMax(MaxX, X + Wsx)
            MaxY = MathMax(MaxY, Y + Wsy)
            MaxZ = MathMax(MaxZ, Z + Wsz)
        end
    end

    if MinX == Inf then
        return nil, nil
    end

    local MinVec = Vector3.new(MinX, MinY, MinZ)
    local MaxVec = Vector3.new(MaxX, MaxY, MaxZ)
    local Middle = (MaxVec + MinVec) * 0.5
    local Cf = Orientation - Orientation.Position + Orientation:PointToWorldSpace(Middle)
    local Size = MaxVec - MinVec
    local HalfSize = Size * 0.5

    local ClampedSize = Vector3.new(
        MathMin(HalfSize.X, 5) * 2,
        MathMin(HalfSize.Y, 10) * 2,
        MathMin(HalfSize.Z, 5) * 2
    )

    return Cf, ClampedSize
end

local function IsIgnoredBodyPart(Instance)
    if not (Instance and Instance:IsA("BasePart")) then
        return true
    end

    if Instance.Name == "HumanoidRootPart" then
        return true
    end

    local Name = string.lower(Instance.Name or "")
    return Instance:GetAttribute("PDIgnoreChams") == true
        or Name == "ignoreme"
        or Name == "pdserverpositionclone"
        or Name == "facehitbox"
        or Name == "headtophitbox"
        or Name:find("lagcham", 1, true) ~= nil
        or Name:find("fakecham", 1, true) ~= nil
        or Name:find("createfakechams", 1, true) ~= nil
end

local function BoxMath(model, ProjectionCamera, ViewportSize, BodyParts, RootPart)
    if not model then
        return nil, nil, false
    end

    ProjectionCamera = ProjectionCamera or Camera

    local root = RootPart
    if not (root and root.Parent == model) then
        root = model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChildWhichIsA("BasePart")
    end
    if not root then
        return nil, nil, false
    end

    local headPos, footPos, hrpPos
    local Torso = root
    local Cf = Torso.CFrame
    local Pos = Torso.Position
    local VTop = Pos + (Cf.UpVector * 2)
    local VBottom = Pos - (Cf.UpVector * 2.8)

    local TopProjected, TopVisible = ProjectToScreen(ProjectionCamera, ViewportSize, VTop)
    local BottomProjected, BottomVisible = ProjectToScreen(ProjectionCamera, ViewportSize, VBottom)
    if (not TopVisible and not BottomVisible) or not TopProjected or not BottomProjected then
        return nil, nil, false
    end

    local Height = math.abs(BottomProjected.Y - TopProjected.Y)
    if Height <= 0 then
        return nil, nil, false
    end

    local Width = Height / 1.5
    local boxPos = Vector2.new(
        MathFloor(((TopProjected.X + BottomProjected.X) * 0.5) - (Width * 0.5)),
        MathMin(TopProjected.Y, BottomProjected.Y)
    )
    local boxSize = Vector2.new(Width, Height)
    local width, height = boxSize.X, boxSize.Y
    if width <= 0 or height <= 0 then
        return nil, nil, false
    end

    return boxPos, boxSize, true, width, height
end

local function resolveGun(itemOrName)
    local ItemImageMap = Entities.Global.ItemImageMap
    if not ItemImageMap then
        ItemImageMap = {}
        for _, item in next, Entities.Global.ItemsModule do
            local image = type(item.Image) == "table" and item.Image.Default or item.Image
            ItemImageMap[item.Name] = image or false
        end
        Entities.Global.ItemImageMap = ItemImageMap
    end

    local ValueType = typeof(itemOrName)
    local Item = ValueType == "Instance" and itemOrName or nil
    local Name = Item and Item.Name or (ValueType == "table" and itemOrName.Name) or itemOrName
    if type(Name) ~= "string" or Name == "" then
        return false
    end

    local Skin = Item and (Item:GetAttribute("Skin") or "Default") or "Default"
    local CachePrefix = Item and "item::" or "name::"
    local CacheKey = CachePrefix .. Name .. "::" .. Skin

    local Cached = Entities.Global.IconsCache[CacheKey]
    if Cached ~= nil then
        return Cached
    end

    local Resolver = Entities.Global.GetItemImage
    if Resolver then
        local Success, Image = pcall(Resolver, itemOrName)
        if Success then
            if Image then
                Entities.Global.IconsCache[CacheKey] = Image
                return Image
            end
            -- Cache explicit miss so we don't call custom resolver every frame.
            Entities.Global.IconsCache[CacheKey] = false
            return false
        end
    end

    local Image = ItemImageMap[Name]
    if Image ~= nil then
        Entities.Global.IconsCache[CacheKey] = Image
        return Image
    end

    Entities.Global.IconsCache[CacheKey] = false
    return false
end

local ItemCache = {}
function Entities.GetWeapon(plr)
    return ItemCache[plr]
end

function Entities.GetHealth(plr, hum)
    if hum then
        return hum.Health, hum.MaxHealth
    end
    return 0, 0
end

function Entities.SetGameSupport(Handlers)
    if type(Handlers) ~= "table" then
        return
    end

    for Name, Callback in next, Handlers do
        if type(Callback) == "function" then
            Entities.Main.Functions[Name] = Callback
        end
    end
end

function Entities.Main.Functions.GetCharacter(self)
    if self.IsPreview then
        return self.Character or self.Pointer
    end

    local Pointer = self.Pointer
    if typeof(Pointer) == "Instance" and Pointer:IsA("Player") then
        local CurrentCharacter = Pointer.Character
        if CurrentCharacter and CurrentCharacter.Parent then
            return CurrentCharacter
        end
        return nil
    end

    if self.Character and self.Character.Parent then
        return self.Character
    end

    return Pointer
end

function Entities.Main.Functions.GetRoot(self, Character)
    Character = Character or self:GetCharacter()
    return Character and (Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChildWhichIsA("BasePart")) or
        nil
end

function Entities.Main.Functions.GetHumanoid(self, Character)
    Character = Character or self:GetCharacter()
    return Character and Character:FindFirstChildOfClass("Humanoid") or nil
end

function Entities.Main.Functions.IsBodyPart(self, Instance)
    return not IsIgnoredBodyPart(Instance)
end

function Entities.Main.Functions.IsArmorContainer(self, Instance)
    if typeof(Instance) ~= "Instance" then
        return false
    end

    if Instance:IsA("Humanoid") then
        return false
    end

    if Instance:IsA("BasePart") then
        return not self:IsBodyPart(Instance)
    end

    if not (Instance:IsA("Model") or Instance:IsA("Accessory") or Instance:IsA("Folder")) then
        return false
    end

    return resolveGun(Instance) == false
end

function Entities.Main.Functions.RefreshParts(self, Character)
    Character = Character or self:GetCharacter()
    local Parts = {}

    if Character then
        for _, Child in next, Character:GetChildren() do
            if self:IsBodyPart(Child) then
                Parts[Child.Name] = Child
            end
        end
    end

    self.BodyParts = Parts
    self.Root = self:GetRoot(Character)
    self.Humanoid = self:GetHumanoid(Character)
    return Parts
end

function Entities.Main.Functions.GetHealth(self, Humanoid)
    return Entities.GetHealth(self.Pointer, Humanoid, self)
end

function Entities.Main.Functions.GetVisiblePart(self, Character)
    local Parts = self.BodyParts
    local Head = Parts and Parts.Head
    if Head and Head.Parent then
        return Head
    end

    return self:GetRoot(Character)
end

function Entities.Main.Functions.ShouldBindCharacter(self, Character)
    if not Character then
        return false
    end

    if not self.IsPlayer then
        return true
    end

    return Players:GetPlayerFromCharacter(Character) == self.Pointer
end

local function UpdateWeaponVisuals(data, weapon)
    if not data then
        return
    end

    local WeaponLabel = data.Labels and data.Labels.Weapon
    local WeaponName = weapon and weapon.Name or "None"
    local WeaponIcon = weapon and resolveGun(weapon) or false

    if WeaponLabel then
        WeaponLabel.Text = WeaponName
    end

    if data.WeaponIcon then
        data.WeaponIcon.Image = WeaponIcon or ""
    end
end

local DefaultESPFlags = {}

for Name, FlagData in next, DefaultESPFlags do
    Entities.Flags[Name] = FlagData
end

function Entities.Main.Functions.AddFlag(_, Data)
    if not Data or not Data.Name then
        return nil
    end

    Entities.Flags[Data.Name] = Data
    return Entities.Flags[Data.Name]
end

local SoldierClassType = {
    Brutus = "Bosses",
    Bruno = "Bosses",
    BTR = "Bosses",
    Boris = "Bosses",
    Soldier = "Soldiers",
    Bot = "Soldiers",
}

local function ComputeStableOffset(Value)
    local Source = tostring(Value or "")
    local Hash = 0
    for Index = 1, #Source do
        Hash = (Hash * 33 + string.byte(Source, Index)) % 1000
    end
    return Hash / 1000
end

local function Espify(plr)
    if plr == LocalPlayer or Cache[plr] then
        return Cache[plr]
    end
    --
    local frame = Instance.new("Frame")
    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BorderColor3 = Color3.new()
    frame.BorderSizePixel = 0
    frame.Position = UDim2.fromScale(0.44166, 0.300347)
    frame.Size = UDim2.fromOffset(298, 459)
    frame.Visible = false

    local uIGradient = Instance.new("UIGradient")
    uIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 100)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
    })
    uIGradient.Rotation = 27
    uIGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    uIGradient.Parent = frame

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.Size = UDim2.fromScale(1, 1)

    local mainOutline = Instance.new("Frame")
    mainOutline.BackgroundTransparency = 1
    mainOutline.Size = UDim2.fromScale(1, 1)

    local uIStroke = Instance.new("UIStroke")
    uIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke.LineJoinMode = Enum.LineJoinMode.Miter
    uIStroke.Thickness = 3
    uIStroke.Parent = mainOutline

    mainOutline.Parent = box

    local mainBox = Instance.new("Frame")
    mainBox.BackgroundTransparency = 1
    mainBox.Size = UDim2.fromScale(1, 1)

    local uIStroke1 = Instance.new("UIStroke")
    uIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke1.Color = Color3.new(1, 1, 1)
    uIStroke1.LineJoinMode = Enum.LineJoinMode.Miter
    uIStroke1.Thickness = 2
    uIStroke1.Parent = mainBox

    mainBox.Parent = box

    local innerOutline = Instance.new("Frame")
    innerOutline.BackgroundTransparency = 1
    innerOutline.Size = UDim2.fromScale(1, 1)

    local uIStroke2 = Instance.new("UIStroke")
    uIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke2.LineJoinMode = Enum.LineJoinMode.Miter
    uIStroke2.Parent = innerOutline

    innerOutline.Parent = box

    box.Parent = frame

    local cornerHolder = Instance.new("Frame")
    cornerHolder.Size = UDim2.new(1, 0, 1, 0)
    cornerHolder.BackgroundTransparency = 1
    cornerHolder.Visible = false
    cornerHolder.ZIndex = 1
    cornerHolder.Parent = frame

    local Corner = {}
    for _, pos in next, { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } } do
        local len = 15
        local thick = 1

        local horiz = Instance.new("Frame")
        horiz.AnchorPoint = Vector2.new(pos[1], pos[2])
        horiz.Position = UDim2.new(pos[1], 0, pos[2], 0)
        horiz.Size = UDim2.new(0, len, 0, thick)
        horiz.BorderSizePixel = 0
        horiz.ZIndex = 2
        horiz.Parent = cornerHolder

        local horizoutline = Instance.new("Frame")
        horizoutline.BackgroundColor3 = Color3.new()
        horizoutline.Size = UDim2.new(1, 2, 1, 2)
        horizoutline.Position = UDim2.new(0, -1, 0, -1)
        horizoutline.BorderSizePixel = 0
        horizoutline.ZIndex = -999
        horizoutline.Parent = horiz

        local vert = Instance.new("Frame")
        vert.AnchorPoint = Vector2.new(pos[1], pos[2])
        vert.Position = UDim2.new(pos[1], 0, pos[2], 0)
        vert.Size = UDim2.new(0, thick, 0, len)
        vert.BorderSizePixel = 0
        vert.ZIndex = 2
        vert.Parent = cornerHolder

        local vertoutline = Instance.new("Frame")
        vertoutline.BackgroundColor3 = Color3.new()
        vertoutline.Size = UDim2.new(1, 2, 1, 2)
        vertoutline.Position = UDim2.new(0, -1, 0, -1)
        vertoutline.BorderSizePixel = 0
        vertoutline.ZIndex = -999
        vertoutline.Parent = vert

        Corner[#Corner + 1] = { horiz, vertoutline }
        Corner[#Corner + 1] = { vert, horizoutline }
    end

    local sides = Instance.new("Frame")
    sides.BackgroundTransparency = 1
    sides.Size = UDim2.fromScale(1, 1)

    local bottom = Instance.new("Frame")
    bottom.AutomaticSize = Enum.AutomaticSize.Y
    bottom.BackgroundTransparency = 1
    bottom.Position = UDim2.new(0, 0, 1, 3)
    bottom.Size = UDim2.new(1, 0, 0, 0)

    bottom.Parent = sides

    local right = Instance.new("Frame")
    right.BackgroundTransparency = 1
    right.Position = UDim2.new(1, 8, 0, 0)
    right.Size = UDim2.fromScale(1, 1)

    local healthbar = Instance.new("Frame")
    healthbar.BackgroundColor3 = Color3.new(1, 1, 1)
    healthbar.BorderColor3 = Color3.new()
    healthbar.BorderSizePixel = 0
    healthbar.LayoutOrder = -100
    healthbar.AnchorPoint = Vector2.new(0, 0)
    healthbar.Size = UDim2.new(0, 2, 1, 1)

    local uIGradient1 = Instance.new("UIGradient")
    uIGradient1.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0)),
    })
    uIGradient1.Rotation = -90
    uIGradient1.Parent = healthbar

    local uIStroke3 = Instance.new("UIStroke")
    uIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke3.Parent = healthbar

    local healthbarOutline = Instance.new("Frame")
    healthbarOutline.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    healthbarOutline.BorderColor3 = Color3.new()
    healthbarOutline.BorderSizePixel = 0
    healthbarOutline.Size = UDim2.fromScale(1, 0.31)
    healthbarOutline.Parent = healthbar

    healthbar.Parent = right

    local ammobar = Instance.new("Frame")
    ammobar.BackgroundColor3 = Color3.fromRGB(89, 122, 255)
    ammobar.BorderColor3 = Color3.new()
    ammobar.BorderSizePixel = 0
    ammobar.LayoutOrder = -90
    ammobar.AnchorPoint = Vector2.new(0, 0)
    ammobar.Size = UDim2.new(0, 2, 1, 1)

    local uIGradientAmmo1 = Instance.new("UIGradient")
    uIGradientAmmo1.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(89, 122, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 170, 255)),
    })
    uIGradientAmmo1.Rotation = -90
    uIGradientAmmo1.Parent = ammobar

    local uIStrokeAmmo1 = Instance.new("UIStroke")
    uIStrokeAmmo1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStrokeAmmo1.Parent = ammobar

    local ammobarOutline = Instance.new("Frame")
    ammobarOutline.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    ammobarOutline.BorderColor3 = Color3.new()
    ammobarOutline.BorderSizePixel = 0
    ammobarOutline.Size = UDim2.fromScale(1, 0.31)
    ammobarOutline.Parent = ammobar

    ammobar.Parent = right

    right.Parent = sides

    local top = Instance.new("Frame")
    top.AutomaticSize = Enum.AutomaticSize.Y
    top.AnchorPoint = Vector2.new(0, 1)
    top.BackgroundTransparency = 1
    top.Position = UDim2.fromOffset(0, -3)
    top.Size = UDim2.new(1, 0, 0, 0)

    local horizontalHealthBar = Instance.new("Frame")
    horizontalHealthBar.BackgroundColor3 = Color3.new(1, 1, 1)
    horizontalHealthBar.BorderColor3 = Color3.new()
    horizontalHealthBar.BorderSizePixel = 0
    horizontalHealthBar.LayoutOrder = -100
    horizontalHealthBar.AnchorPoint = Vector2.new(0, 0)
    horizontalHealthBar.Size = UDim2.new(1, 0, 0, 2)

    local uIGradient2 = Instance.new("UIGradient")
    uIGradient2.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0)),
    })
    uIGradient2.Rotation = 180
    uIGradient2.Parent = horizontalHealthBar

    local stupidshit = Instance.new("Frame")
    stupidshit.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    stupidshit.BorderColor3 = Color3.new()
    stupidshit.BorderSizePixel = 0
    stupidshit.Position = UDim2.new(0, 0, 0, -1)
    stupidshit.Size = UDim2.new(1, 2, 1, 2)
    stupidshit.ZIndex = -10
    stupidshit.Parent = horizontalHealthBar

    local healthbarOutline1 = Instance.new("Frame")
    healthbarOutline1.AnchorPoint = Vector2.new(1, 0)
    healthbarOutline1.BackgroundColor3 = Color3.fromRGB()
    healthbarOutline1.BorderColor3 = Color3.new()
    healthbarOutline1.BorderSizePixel = 0
    healthbarOutline1.Position = UDim2.fromScale(1, 0)
    healthbarOutline1.ZIndex = 2
    healthbarOutline1.Position = UDim2.new(1, 0, 0, 0)
    healthbarOutline1.Parent = horizontalHealthBar

    local uIStroke4 = Instance.new("UIStroke")
    uIStroke4.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStroke4.Parent = horizontalHealthBar

    horizontalHealthBar.Parent = top

    local horizontalAmmoBar = Instance.new("Frame")
    horizontalAmmoBar.BackgroundColor3 = Color3.fromRGB(89, 122, 255)
    horizontalAmmoBar.BorderColor3 = Color3.new()
    horizontalAmmoBar.BorderSizePixel = 0
    horizontalAmmoBar.LayoutOrder = -90
    horizontalAmmoBar.AnchorPoint = Vector2.new(0, 0)
    horizontalAmmoBar.Size = UDim2.new(1, 0, 0, 2)

    local uIGradientAmmo2 = Instance.new("UIGradient")
    uIGradientAmmo2.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(89, 122, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 170, 255)),
    })
    uIGradientAmmo2.Rotation = 0
    uIGradientAmmo2.Parent = horizontalAmmoBar

    local ammoBackdrop = Instance.new("Frame")
    ammoBackdrop.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    ammoBackdrop.BorderColor3 = Color3.new()
    ammoBackdrop.BorderSizePixel = 0
    ammoBackdrop.Position = UDim2.new(0, 0, 0, -1)
    ammoBackdrop.Size = UDim2.new(1, 2, 1, 2)
    ammoBackdrop.ZIndex = -10
    ammoBackdrop.Parent = horizontalAmmoBar

    local ammoBarOutline1 = Instance.new("Frame")
    ammoBarOutline1.AnchorPoint = Vector2.new(1, 0)
    ammoBarOutline1.BackgroundColor3 = Color3.fromRGB()
    ammoBarOutline1.BorderColor3 = Color3.new()
    ammoBarOutline1.BorderSizePixel = 0
    ammoBarOutline1.Position = UDim2.new(1, 0, 0, 0)
    ammoBarOutline1.ZIndex = 2
    ammoBarOutline1.Parent = horizontalAmmoBar

    local uIStrokeAmmo2 = Instance.new("UIStroke")
    uIStrokeAmmo2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uIStrokeAmmo2.Parent = horizontalAmmoBar

    horizontalAmmoBar.Parent = top

    top.Parent = sides

    local left = Instance.new("Frame")
    left.AnchorPoint = Vector2.new(1, 0)
    left.BackgroundTransparency = 1
    left.Position = UDim2.fromOffset(-8, 0)
    left.Size = UDim2.fromScale(1, 1)

    left.Parent = sides

    local weaponIcon = Instance.new("ImageLabel")
    weaponIcon.AnchorPoint = Vector2.new(0.5, 0)
    weaponIcon.BackgroundTransparency = 1
    weaponIcon.Image = ""
    weaponIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    weaponIcon.Position = UDim2.new(0.5, 0, 1, 0)
    weaponIcon.ScaleType = Enum.ScaleType.Fit
    weaponIcon.Size = UDim2.new(0, 25, 0, 25)
    weaponIcon.ZIndex = 1
    weaponIcon.Visible = false
    weaponIcon.Parent = frame

    sides.Parent = frame
    --
    local function makelabel(IsFlag)
        local t = Instance.new("TextLabel")
        t.AutomaticSize = Enum.AutomaticSize.XY
        t.BackgroundTransparency = 1
        ApplyLabelFont(t, IsFlag)
        t.Text = "None"
        t.TextSize = 10
        t.TextStrokeTransparency = 0
        t.Visible = false
        t.ZIndex = 3
        t.Parent = frame

        return t
    end

    local function makeBarLabel()
        local t = makelabel(true)
        t.AnchorPoint = Vector2.new(0, 0)
        t.TextSize = 9
        t.Visible = false
        t.Parent = frame
        return t
    end

    local IsPlayer = plr:IsA("Player")
    local Class = ""
    if IsPlayer or plr.Name:find("Rig") then
        Class = "Players"
    elseif SoldierClassType[plr.Name] then
        Class = SoldierClassType[plr.Name]
    end

    local data = setmetatable({
        Name = plr.Name,
        Pointer = plr,
        Character = IsPlayer and plr.Character or plr,
        Frame = frame,
        Class = Class,
        ClassType = Class,
        IsPreview = false,
        IsPlayer = IsPlayer,
        CachedItem = nil,
        CachedArmor = {},
        ItemHistory = {},
        CachedAttachments = {},
        CanRender = true,
        _refreshOffset = ComputeStableOffset(IsPlayer and plr.UserId or plr:GetDebugId()),
        _layoutDirty = true,
        LastChamsRefresh = 0,
        Ammo = 0,
        MaxAmmo = 0,
        BodyParts = {},
        Adornments = {},
        SurfaceAppearances = setmetatable({}, { __mode = "k" }),
        Box = box,
        BoxGradient = uIGradient,
        WeaponIcon = weaponIcon,
        Corner = Corner,
        CornerHolder = cornerHolder,
        Strokes = {
            Outer = uIStroke,
            Main = uIStroke1,
            Inner = uIStroke2,
        },
        Sides = {
            Top = {
                Frame = top,
                HB = horizontalHealthBar,
                HBFill = healthbarOutline1,
                Grad = uIGradient2,
                AB = horizontalAmmoBar,
                ABFill = ammoBarOutline1,
                ABGrad = uIGradientAmmo2,
            },
            Bottom = {
                Frame = bottom,
                HB = horizontalHealthBar,
                HBFill = healthbarOutline1,
                Grad = uIGradient2,
                AB = horizontalAmmoBar,
                ABFill = ammoBarOutline1,
                ABGrad = uIGradientAmmo2,
            },
            Left = {
                Frame = left,
                HB = healthbar,
                HBFill = healthbarOutline,
                Grad = uIGradient1,
                AB = ammobar,
                ABFill = ammobarOutline,
                ABGrad = uIGradientAmmo1,
            },
            Right = {
                Frame = right,
                HB = healthbar,
                HBFill = healthbarOutline,
                Grad = uIGradient1,
                AB = ammobar,
                ABFill = ammobarOutline,
                ABGrad = uIGradientAmmo1,
            },
        },

        Labels = {
            Name = makelabel(false),
            Distance = makelabel(false),
            Weapon = makelabel(false),
        },
        BarLabels = {
            Health = makeBarLabel(),
            Ammo = makeBarLabel(),
        },
        CharacterHighlight = nil,
    }, Entities.Main.Functions)

    for key in Entities.Flags do
        data.Labels[key] = makelabel(true)
    end

    data.Frame.Parent = Holder
    Cache[plr] = data

    local function bindChar(char)
        if not char then
            return
        end
        local data = Cache[plr]
        if not data then
            return
        end
        data.Character = char
        data.CharacterOwner = Players:GetPlayerFromCharacter(char)
        data.Root = data:GetRoot(char)
        data.Humanoid = data:GetHumanoid(char)

        if data._connections then
            for _, Connection in next, data._connections do
                if typeof(Connection) == "RBXScriptConnection" then
                    Connection:Disconnect()
                end
            end
        end
        data.BodyParts = {}
        DestroyCharacterChams(data)
        data.SurfaceAppearances = setmetatable({}, { __mode = "k" })
        data.LastPartRefresh = 0
        data.LastChamsRefresh = 0
        data.NextVisibleCheck = nil
        data._layoutDirty = true
        data._layoutWidth = nil
        data._layoutHeight = nil
        data._layoutAmmoEnabled = nil
        data._layoutAmmoThickness = nil
        data._layoutCanShowAmmo = nil
        data._weaponIconVisible = nil
        data._isHidden = true
        data._hasExternalHighlight = false
        data._partsDirty = true
        data._connections = {}
        if data.CharacterHighlight then
            data.CharacterHighlight:Destroy()
            data.CharacterHighlight = nil
        end

        data:RefreshParts(char)
        UpdateCharacterHighlightCache(data)

        for _, p in next, char:GetChildren() do
            if p:IsA("Humanoid") then
                data.Humanoid = p
            elseif p:IsA("Model") then
                local icon = resolveGun(p)
                if icon then
                    data.CurrentWeapon = p
                    ItemCache[plr] = p
                end
            end
        end

        data._connections["ChildAdded"] = char.ChildAdded:Connect(function(c)
            if c:IsA("Highlight") and c ~= data.CharacterHighlight then
                data._hasExternalHighlight = true
                if data.CharacterHighlight then
                    Set(data.CharacterHighlight, "Enabled", false)
                end
            elseif data:IsBodyPart(c) then
                data.BodyParts[c.Name] = c
                data._partsDirty = true
            elseif c:IsA("Humanoid") then
                data.Humanoid = c
            elseif c:IsA("Model") then
                local icon = resolveGun(c)
                if icon then
                    data.CurrentWeapon = c
                    ItemCache[plr] = c
                end
            end
        end)

        data._connections["ChildRemoved"] = char.ChildRemoved:Connect(function(c)
            if c:IsA("Highlight") then
                if c == data.CharacterHighlight then
                    data.CharacterHighlight = nil
                end
                UpdateCharacterHighlightCache(data)
            elseif c:IsA("BasePart") then
                if data.BodyParts then
                    data.BodyParts[c.Name] = nil
                end
                data._partsDirty = true
            elseif c:IsA("Humanoid") and data.Humanoid == c then
                data.Humanoid = nil
            elseif c == data.CurrentWeapon then
                data.CurrentWeapon = nil
                ItemCache[plr] = nil
            end
        end)

        if not IsPlayer then
            return
        end

        if not data:ShouldBindCharacter(char) then
            return
        end

        if data._characterRemovingConnection then
            data._characterRemovingConnection:Disconnect()
        end

        data._characterRemovingConnection = plr.CharacterRemoving:Connect(function()
            if not data then
                return
            end
            for _, conn in next, data._connections do
                if typeof(conn) == "RBXScriptConnection" then
                    conn:Disconnect()
                end
            end
            data._connections = {}
            data.BodyParts = {}
            DestroyCharacterChams(data)
            data.SurfaceAppearances = setmetatable({}, { __mode = "k" })
            data.LastPartRefresh = 0
            data.LastChamsRefresh = 0
            data.NextVisibleCheck = nil
            data._layoutDirty = true
            data._layoutWidth = nil
            data._layoutHeight = nil
            data._layoutAmmoEnabled = nil
            data._layoutAmmoThickness = nil
            data._layoutCanShowAmmo = nil
            data._weaponIconVisible = nil
            data._partsDirty = true
            data.CurrentWeapon = nil
            ItemCache[plr] = nil
            if data.CharacterHighlight then
                data.CharacterHighlight:Destroy()
                data.CharacterHighlight = nil
            end
        end)
    end

    data.OnCharacterAdded = function(_, char)
        bindChar(char)
    end

    data.Components = {
        Frame = data.Frame,
        Box = data.Box,
        BoxOutline = data.Frame,
        WeaponIcon = data.WeaponIcon,
        Sides = data.Sides,
        Labels = data.Labels,
        BarLabels = data.BarLabels,
    }

    bindChar(IsPlayer and plr.Character or plr)
    if not IsPlayer then
        return data
    end
    plr.CharacterAdded:Connect(bindChar)
    return data
end

Entities.Global.New = function(_, Object, Data)
    if not Object then
        return nil
    end

    local Entity = Cache[Object] or Espify(Object)
    if not Entity then
        return nil
    end

    Data = Data or {}

    if Data.Name ~= nil then
        Entity.Name = Data.Name
    end
    if Data.Class ~= nil then
        Entity.Class = Data.Class
    end
    if Data.ClassType ~= nil then
        Entity.ClassType = Data.ClassType
    end

    Entity.IsPreview = Data.IsPreview == true
    Entity.Character = Data.Character or (Object:IsA("Player") and Object.Character or Object)
    Entity.CharacterOwner = Entity.Character and Players:GetPlayerFromCharacter(Entity.Character) or nil
    Entity.Pointer = Object

    if Entity.IsPreview then
        if Entity.CharacterHighlight then
            Entity.CharacterHighlight:Destroy()
            Entity.CharacterHighlight = nil
        end
        -- DestroyCharacterChams(Entity)
    end

    if not Entity.Components then
        Entity.Components = {
            Frame = Entity.Frame,
            Box = Entity.Box,
            BoxOutline = Entity.Frame,
            WeaponIcon = Entity.WeaponIcon,
            Sides = Entity.Sides,
            Labels = Entity.Labels,
        }
    end

    return Entity
end

for _, p in next, Players:GetPlayers() do
    Espify(p)
end
Players.PlayerAdded:Connect(Espify)
Players.PlayerRemoving:Connect(function(plr)
    local data = Cache[plr]
    if data then
        if data._characterRemovingConnection then
            data._characterRemovingConnection:Disconnect()
            data._characterRemovingConnection = nil
        end

        if data._connections then
            for _, Connection in next, data._connections do
                if typeof(Connection) == "RBXScriptConnection" then
                    Connection:Disconnect()
                end
            end
        end
        if data.CharacterHighlight then
            data.CharacterHighlight:Destroy()
            data.CharacterHighlight = nil
        end
        -- DestroyCharacterChams(data)
        -- ClearViewportModel(data)

        data.Frame:Destroy()
        Cache[plr] = nil
    end
end)

local Events = workspace:FindFirstChild("Events")
if Events then
    for _, BTR in Events:GetChildren() do
        if BTR.Name == "BTR" then
            Espify(BTR)
        end
    end

    Events.ChildAdded:Connect(function(BTR)
        task.wait(1)
        if BTR.Name == "BTR" then
            Espify(BTR)
        end
    end)
end

local Military = workspace:FindFirstChild("Military")
if Military then
    for _, Folder in Military:GetChildren() do
        for _, Soldier in Folder:GetChildren() do
            if Soldier:IsA("Model") then
                Espify(Soldier)
            end
        end

        Folder.ChildAdded:Connect(function(Soldier)
            task.wait(1)
            if Soldier:IsA("Model") then
                Espify(Soldier)
            end
        end)
    end
end

if istestinggame then
    for _, p in next, workspace:GetChildren() do
        if p:IsA("Model") and p:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(p) then
            Espify(p)
        end
    end

    workspace.ChildAdded:Connect(function(c)
        if c:IsA("Model") and c:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(c) then
            Espify(c)
        end
    end)
end
local function DrawText(data, key, sideKey, text, color, tr)
    local IsFlag = Entities.Flags[key] ~= nil
    local TargetSize = IsFlag and 9 or 10
    local lbl = data.Labels[key]
    local LayoutChanged = false
    if not lbl then
        lbl = Instance.new("TextLabel")
        lbl.AutomaticSize = Enum.AutomaticSize.XY
        lbl.BackgroundTransparency = 1
        ApplyLabelFont(lbl, IsFlag)
        lbl.Text = "None"
        lbl.TextSize = TargetSize
        lbl.TextStrokeTransparency = 0
        lbl.Visible = false
        lbl.ZIndex = 3
        InvalidateLabelMeasure(lbl)
        lbl.Parent = data.Frame
        data.Labels[key] = lbl
        LayoutChanged = true
    end

    if text and lbl.Text ~= text then
        Set(lbl, "Text", text)
        InvalidateLabelMeasure(lbl)
        LayoutChanged = true
    end
    if lbl.Visible ~= true then
        LayoutChanged = true
    end
    Set(lbl, "TextColor3", color)
    Set(lbl, "TextTransparency", tr)
    Set(lbl, "TextStrokeTransparency", tr)
    Set(lbl, "Visible", true)
    if LayoutChanged then
        data._layoutDirty = true
    end
end

local function EnsureBarLabel(data, key)
    data.BarLabels = data.BarLabels or {}
    local Label = data.BarLabels[key]
    if Label then
        return Label
    end

    Label = Instance.new("TextLabel")
    Label.AutomaticSize = Enum.AutomaticSize.XY
    Label.BackgroundTransparency = 1
    Label.AnchorPoint = Vector2.new(0, 0)
    Label.TextSize = 9
    Label.TextStrokeTransparency = 0
    Label.ZIndex = 4
    ApplyLabelFont(Label, true)
    InvalidateLabelMeasure(Label)
    Label.Parent = data.Frame
    data.BarLabels[key] = Label
    return Label
end

local function DrawBarText(data, key, BarObject, Side, Text, Color, Transparency, FollowBar, FillRatio)
    if not (data and data.Frame and BarObject and Side) then
        return
    end

    local Label = EnsureBarLabel(data, key)
    local LayoutChanged = false
    if Label.Text ~= Text then
        LayoutChanged = true
        InvalidateLabelMeasure(Label)
    end
    Set(Label, "Text", Text)
    Set(Label, "TextColor3", Color)
    Set(Label, "TextTransparency", Transparency)
    Set(Label, "TextStrokeTransparency", Transparency)
    if Label.Parent ~= data.Frame then
        Label.Parent = data.Frame
        LayoutChanged = true
    end

    local FramePosition = data.Frame.AbsolutePosition
    local BarPosition = BarObject.AbsolutePosition - FramePosition
    local BarSize = BarObject.AbsoluteSize
    local BoundsX, BoundsY = MeasureTextLabel(Label)
    local X, Y

    if FollowBar then
        if Side == "Left" or Side == "Right" then
            X = BarPosition.X + ((BarSize.X - BoundsX) * 0.5)
            Y = BarPosition.Y + BarSize.Y - (BarSize.Y * FillRatio) - (BoundsY * 0.5)
        else
            X = BarPosition.X + (BarSize.X * FillRatio) - (BoundsX * 0.5)
            Y = BarPosition.Y + ((BarSize.Y - BoundsY) * 0.5)
        end
    elseif Side == "Left" then
        X = BarPosition.X - BoundsX - 4
        Y = -6
    elseif Side == "Right" then
        X = BarPosition.X + BarSize.X + 4
        Y = -6
    elseif Side == "Top" then
        X = BarPosition.X + BarSize.X - BoundsX
        Y = BarPosition.Y - BoundsY - 4
    else
        X = BarPosition.X + BarSize.X - BoundsX
        Y = BarPosition.Y + BarSize.Y + 4
    end

    Set(Label, "Position", UDim2.fromOffset(MathFloor(X + 0.5), MathFloor(Y + 0.5)))
    if Label.Visible ~= true then
        LayoutChanged = true
    end
    Set(Label, "Visible", true)
    if LayoutChanged then
        data._layoutDirty = true
    end
end

local function HideBarText(data, key)
    local Labels = data and data.BarLabels
    local Label = Labels and Labels[key]
    if not Label then
        return
    end

    if Label.Visible then
        data._layoutDirty = true
    end
    Set(Label, "Visible", false)
end

local function HideText(data, key)
    local lbl = data.Labels[key]
    if not lbl then
        return
    end

    if lbl.Visible then
        data._layoutDirty = true
    end
    Set(lbl, "Visible", false)
end

local function MeasureOverlayObject(Object)
    if not Object then
        return 0, 0
    end

    if Object:IsA("TextLabel") then
        return MeasureTextLabel(Object)
    end

    return Object.AbsoluteSize.X, Object.AbsoluteSize.Y
end

local function PositionOverlayObject(Object, X, Y)
    if Object then
        Set(Object, "Position", UDim2.fromOffset(MathFloor(X + 0.5), MathFloor(Y + 0.5)))
    end
end

local function LayoutBottomStack(data, Width, StartY)
    local Y = StartY
    local TextSpacing = 2

    for _, Object in ipairs({ data.Labels.Distance, data.Labels.Weapon }) do
        if Object and Object.Visible then
            local ObjectWidth, ObjectHeight = MeasureOverlayObject(Object)
            PositionOverlayObject(Object, (Width - ObjectWidth) * 0.5, Y)
            Y = Y + ObjectHeight + TextSpacing
        end
    end

    local WeaponIcon = data.WeaponIcon
    if WeaponIcon and WeaponIcon.Visible then
        if not (data.Labels and data.Labels.Weapon and data.Labels.Weapon.Visible) then
            Y = Y - 4
        end
        Set(WeaponIcon, "Position", UDim2.new(0.5, 0, 0, MathFloor(Y + 0.5)))
    end
end

local function LayoutRightFlags(data, Width)
    local X = Width + 4
    local Y = 0
    for key in next, Entities.Flags do
        local Label = data.Labels[key]
        if Label and Label.Visible then
            local _, LabelHeight = MeasureOverlayObject(Label)
            PositionOverlayObject(Label, X, Y)
            Y = Y + LabelHeight + 2
        end
    end
end

local function LayoutOverlayObjects(data, Width, Height, AmmoEnabled, AmmoThickness, CanShowAmmo)
    local NameLabel = data.Labels.Name
    if NameLabel and NameLabel.Visible then
        local LabelWidth, LabelHeight = MeasureOverlayObject(NameLabel)
        PositionOverlayObject(NameLabel, (Width - LabelWidth) * 0.5, -LabelHeight - 3)
    end

    local BottomY = Height + 3
    if AmmoEnabled and CanShowAmmo then
        BottomY = BottomY + AmmoThickness + 4
    end
    LayoutBottomStack(data, Width, BottomY)
    LayoutRightFlags(data, Width)
end

-- local clanController = istestinggame and {} or getsenv(LocalPlayer.PlayerScripts:WaitForChild("ClanController"))
-- local clanControllerShared = clanController and clanController.shared

-- local isTeam = function(player)
-- 	if typeof(player) ~= "Instance" or not player:IsA("Player") then
-- 		return false
-- 	end
-- 	local teamCache = clanControllerShared and clanControllerShared.cachedTeamModels

-- 	return teamCache and teamCache[player.UserId]
-- end

local hideESP = function(data)
    if data._isHidden then
        return
    end

    data._isHidden = true
    data._lastVisibleFrame = nil
    data._layoutDirty = true
    Set(data.Frame, "Visible", false)
    Set(data.Box, "Visible", false)
    Set(data.CornerHolder, "Visible", false)
    if data.WeaponIcon then
        Set(data.WeaponIcon, "Visible", false)
    end
    for _, side in next, data.Sides or {} do
        if side.HB then
            Set(side.HB, "Visible", false)
        end
        if side.HBFill then
            Set(side.HBFill, "Visible", false)
        end
        if side.AB then
            Set(side.AB, "Visible", false)
        end
        if side.ABFill then
            Set(side.ABFill, "Visible", false)
        end
    end
    for key in next, data.Labels or {} do
        HideText(data, key)
    end
    for key in next, data.BarLabels or {} do
        HideBarText(data, key)
    end
    HideBarText(data, "Health")
    HideBarText(data, "Ammo")
    if data.CharacterHighlight then
        Set(data.CharacterHighlight, "Enabled", false)
    end
    DestroyCharacterChams(data)
end

local FriendCache = {}
local FriendCacheTTL = 30
local VisibleCheckInterval = 0.15

local function IsTimeToRun(Now, NextRun, Interval, Offset)
    local NextValue = NextRun
    if not NextValue then
        NextValue = Now + ((Offset or 0) * Interval)
    end
    return Now >= NextValue, NextValue
end

local function HideEntityNow(data)
    hideESP(data)
    data._isHidden = true
    data._nextEntityUpdate = 0
    data._lastVisualUpdate = nil
    data._lastVisibleFrame = nil
    data._lastSnapshotFrame = nil
end

local function EntityPoop(data, Snapshot, Settings)
    local width = Snapshot.Width
    local height = Snapshot.Height
    local FrameX = Snapshot.FrameX
    local FrameY = Snapshot.FrameY
    local BoxStyle = Settings.BoxStyle
    local HealthEnabled = Settings.HealthEnabled
    local HealthThickness = Settings.HealthThickness
    local AmmoEnabled = Settings.AmmoEnabled
    local AmmoThickness = Settings.AmmoThickness
    local SideStackThickness = HealthEnabled and HealthThickness or 0
    local pad = MathMax(MathFloor(MathClamp(width * 0.05, 2, 6) + 0.5),
        ((BoxStyle == 'Full' and data.Strokes.Main.Thickness or 1) + MathMax(1, SideStackThickness) + 3)) - 2

    Set(data.Sides.Right.Frame, 'Position', UDim2.new(1, pad, 0, 0))
    Set(data.Sides.Left.Frame, 'Position', UDim2.new(0, -pad, 0, 0))
    Set(data.Frame, 'Position', UDim2.fromOffset(FrameX, FrameY))
    Set(data.Frame, 'Size', UDim2.fromOffset(Snapshot.Size.X, Snapshot.Size.Y))

    if Settings.BoxEnabled then
        if BoxStyle == 'Full' then
            Set(data.Box, 'Visible', true)
            Set(data.CornerHolder, 'Visible', false)
        else
            Set(data.Box, 'Visible', false)
            Set(data.CornerHolder, 'Visible', true)

            local c = data.Corner
            local thick = 1
            local minwh = MathMin(width, height) / 2
            local horiz = minwh * 0.8
            local vert = horiz
            if data._cornerWidth ~= width or data._cornerHeight ~= height or data._cornerHoriz ~= horiz or data._cornerVert ~= vert then
                data._cornerWidth = width
                data._cornerHeight = height
                data._cornerHoriz = horiz
                data._cornerVert = vert
                Set(c[1][1], 'Size', UDim2.new(0, horiz, 0, thick))
                Set(c[1][1], 'Position', UDim2.fromOffset(0, 0))
                Set(c[2][1], 'Size', UDim2.new(0, thick, 0, vert))
                Set(c[2][1], 'Position', UDim2.fromOffset(0, 0))
                Set(c[3][1], 'Size', UDim2.new(0, horiz, 0, thick))
                Set(c[3][1], 'Position', UDim2.fromOffset(width, 0))
                Set(c[4][1], 'Size', UDim2.new(0, thick, 0, vert))
                Set(c[4][1], 'Position', UDim2.fromOffset(width, 0))
                Set(c[5][1], 'Size', UDim2.new(0, horiz, 0, thick))
                Set(c[5][1], 'Position', UDim2.fromOffset(0, height))
                Set(c[6][1], 'Size', UDim2.new(0, thick, 0, vert))
                Set(c[6][1], 'Position', UDim2.fromOffset(0, height))
                Set(c[7][1], 'Size', UDim2.new(0, horiz, 0, thick))
                Set(c[7][1], 'Position', UDim2.fromOffset(width, height))
                Set(c[8][1], 'Size', UDim2.new(0, thick, 0, vert))
                Set(c[8][1], 'Position', UDim2.fromOffset(width, height))
            end
        end
    else
        Set(data.CornerHolder, 'Visible', false)
        Set(data.Box, 'Visible', false)
    end

    local HasWeapon = Snapshot.IsPreview or (Snapshot.CurrentWeapon ~= nil) or (data.CachedItem ~= nil)
    local MaxAmmo = tonumber(data.MaxAmmo) or 0
    local CanShowAmmo = (not Settings.AmmoRequireWeapon or HasWeapon) and (MaxAmmo > 0 or not Settings.AmmoHideEmpty)
    if data._layoutWidth ~= width or data._layoutHeight ~= height or data._layoutAmmoEnabled ~= AmmoEnabled or data._layoutAmmoThickness ~= AmmoThickness or data._layoutCanShowAmmo ~= CanShowAmmo or data._layoutDirty then
        data._layoutWidth = width
        data._layoutHeight = height
        data._layoutAmmoEnabled = AmmoEnabled
        data._layoutAmmoThickness = AmmoThickness
        data._layoutCanShowAmmo = CanShowAmmo
        data._layoutDirty = false
        LayoutOverlayObjects(data, width, height, AmmoEnabled, AmmoThickness, CanShowAmmo)
    end

    Set(data.Frame, 'Visible', true)
    data._isHidden = false
    data._lastVisibleFrame = Snapshot.Now or os.clock()
end

local function FastBoxFallback(Root, ProjectionCamera, ViewportSize)
    local ScreenPoint, OnScreen = ProjectToScreen(ProjectionCamera or Camera, ViewportSize, Root.Position)
    if not ScreenPoint or not OnScreen or ScreenPoint.Z <= 0 then
        return nil, nil, false, 0, 0
    end

    local Depth = ScreenPoint.Z
    local Height = MathClamp(2600 / MathMax(Depth, 1), 18, 140)
    local Width = Height / 1.35
    local X = ScreenPoint.X - (Width * 0.5)
    local Y = ScreenPoint.Y - (Height * 0.5)

    return Vector2.new(X, Y), Vector2.new(Width, Height), true, Width, Height
end

local function SmoothTowards(Current, Target, Speed)
    Current = Current or Target
    local Delta = Target - Current
    if Delta > -0.001 and Delta < 0.001 then
        return Target
    end
    return Current + (Delta * Speed)
end

local function ShouldRenderEntity(plr, data, Settings, Now, FriendCache, FriendCacheTTL)
    local IsPreview = data.IsPreview == true
    local IsPlayerPointer = data.IsPlayer == true
    local IsPlayerClass = data.Class == "Players" or data.Class == "Player"

    if not IsPreview and not IsPlayerClass and not Settings.IncludeAI then
        return false
    end

    if not IsPreview and IsPlayerClass and IsPlayerPointer then
        if Settings.Teamcheck then
            local dl = _G.Deadline
            local IsTeammate = dl and dl._IsTeammate
            if IsTeammate then
                if IsTeammate(plr) then return false end
            else
                local LocalTeam  = LocalPlayer.Team
                local PlayerTeam = plr.Team
                if LocalTeam and PlayerTeam and LocalTeam == PlayerTeam then
                    return false
                end
            end
        end

        if Settings.Friendcheck and plr ~= LocalPlayer then
            local FriendEntry = FriendCache[plr.UserId]
            if not FriendEntry or (Now - FriendEntry.Timestamp) > FriendCacheTTL then
                local Success, IsFriend = pcall(function()
                    return LocalPlayer:IsFriendsWith(plr.UserId)
                end)
                FriendEntry = {
                    Value = Success and IsFriend or false,
                    Timestamp = Now,
                }
                FriendCache[plr.UserId] = FriendEntry
            end

            if FriendEntry.Value then
                return false
            end
        end
    end

    return true, IsPreview, IsPlayerPointer, IsPlayerClass
end

local function BuildSnapshot(plr, data, Settings, Now, ResolvedCharacter, LocalViewOrigin)
    local CanRender, IsPreview, IsPlayerPointer = ShouldRenderEntity(plr, data, Settings, Now, FriendCache,
        FriendCacheTTL)
    if not CanRender then
        return nil
    end

    local Character = ResolvedCharacter or data.Character or data:GetCharacter()
    if Character and data.Character ~= Character then
        data:OnCharacterAdded(Character)
        Character = data.Character
    end
    if not Character or (not IsPreview and not Character.Parent) then
        return nil
    end

    if data.Character ~= Character then
        data.Character = Character
        data.CharacterOwner = Players:GetPlayerFromCharacter(Character)
        data.Root = nil
        data.Humanoid = nil
        data._partsDirty = true
    end

    local Root = data.Root
    if not Root or Root.Parent ~= Character then
        Root = Character:FindFirstChild('HumanoidRootPart') or Character:FindFirstChild('humanoid_root_part') or Character:FindFirstChildWhichIsA('BasePart')
        data.Root = Root
    end
    if not Root then
        return nil
    end

    local DistanceCamera = (IsPreview and data.PreviewCamera) or Camera
    local RawDistance = (DistanceCamera.CFrame.Position - Root.Position).Magnitude
    local Distance = RawDistance
    if (not IsPreview) and Distance > Settings.MaxDistance then
        return nil
    end

    local Snapshot = data._snapshot
    if not Snapshot then
        Snapshot = {}
        data._snapshot = Snapshot
    end

    local UpdateInterval
    -- local UseCheapBox = false
    local AllowVisibleCheck = false
    local AllowStateChecks = false

    if IsPreview then
        UpdateInterval = 0
        AllowVisibleCheck = false
        AllowStateChecks = false
    elseif Settings.DistanceFramesEnabled and Distance > Settings.DistanceFramesThreshold then
        UpdateInterval = 1 / Settings.DistanceFramesHz
        AllowVisibleCheck = Settings.VisibleColor ~= nil
        AllowStateChecks = true
    else
        UpdateInterval = Settings.CloseUpdateInterval
        AllowVisibleCheck = Settings.VisibleColor ~= nil
        AllowStateChecks = true
    end

    local Humanoid = data.Humanoid
    if not IsPreview then
        if not Humanoid or Humanoid.Parent ~= Character then
            Humanoid = Character:FindFirstChildOfClass('Humanoid')
            data.Humanoid = Humanoid
        end
    end

    if Settings.NeedsPartRefresh and (data._partsDirty or (Now - (data.LastPartRefresh or 0)) >= Settings.PartRefreshFallback) then
        data:RefreshParts(Character)
        data.LastPartRefresh = Now
        data._partsDirty = false
        Root = data.Root or Root
        Humanoid = data.Humanoid or Humanoid
    end

    local Health, MaxHealth = data:GetHealth(Humanoid)
    if IsPreview then
        Health, MaxHealth = 100, 100
    end
    if not IsPreview and ((not Root) or Health <= 0) then
        return nil
    end

    local PreviewCamera = IsPreview and data.PreviewCamera or nil
    local PreviewViewport = IsPreview and data.PreviewViewport or nil
    local ViewportSize = PreviewViewport and PreviewViewport.AbsoluteSize or nil

    local Position, Size, Visible, Width, Height
    -- if UseCheapBox then
    --     Position, Size, Visible, Width, Height = FastBoxFallback(Root, PreviewCamera, ViewportSize)
    -- else
    Position, Size, Visible, Width, Height = BoxMath(Character, PreviewCamera, ViewportSize, data.BodyParts, Root)
    -- end
    if not Visible or not Position or not Size then
        return nil
    end

    local FrameX, FrameY = Position.X, Position.Y
    if IsPreview and PreviewViewport and data.Frame.Parent and data.Frame.Parent:IsA('GuiObject') then
        local ParentPosition = data.Frame.Parent.AbsolutePosition
        local ViewportPosition = PreviewViewport.AbsolutePosition
        FrameX = FrameX + (ViewportPosition.X - ParentPosition.X)
        FrameY = FrameY + (ViewportPosition.Y - ParentPosition.Y)
    end

    local VisibleColor = Settings.VisibleColor
    local UseVisibleColor = false
    if (not IsPreview) and AllowVisibleCheck and VisibleColor then
        local Interval = Distance > 900 and 0.28 or Distance > 450 and 0.18 or VisibleCheckInterval
        local ShouldRunVisibleCheck, NextVisibleCheck = IsTimeToRun(Now, data.NextVisibleCheck, Interval,
            data._refreshOffset)
        if not data.NextVisibleCheck then
            data.NextVisibleCheck = NextVisibleCheck
        end
        if ShouldRunVisibleCheck then
            data.NextVisibleCheck = NextVisibleCheck + Interval
            data.LastVisibleCheck = Now
            local VisiblePart = data:GetVisiblePart(Character)
            if VisiblePart and Camera then
                local Origin = LocalViewOrigin or Camera.CFrame.Position
                data.LastVisibleResult = select(1, Entities.Ray:IsPartVisible(Origin, VisiblePart, Character)) or false
            else
                data.LastVisibleResult = false
            end
        end
        UseVisibleColor = data.LastVisibleResult == true
    else
        data.LastVisibleResult = false
    end

    local VisibleBlendTarget = UseVisibleColor and 1 or 0
    data.VisibleBlend = SmoothTowards(data.VisibleBlend, VisibleBlendTarget, 0.2)

    local ManipulatedTarget = 0
    if (not IsPreview) and AllowStateChecks and data.IsManipulated then
        ManipulatedTarget = data:IsManipulated(Character) and 1 or 0
    end
    data.ManipulatedBlend = SmoothTowards(data.ManipulatedBlend, ManipulatedTarget, 0.2)

    local HitscanTarget = 0
    if (not IsPreview) and AllowStateChecks and data.IsHitscanning then
        HitscanTarget = data:IsHitscanning(Character) and 1 or 0
    end
    data.HitscanBlend = SmoothTowards(data.HitscanBlend, HitscanTarget, 0.2)

    local ManipulatedBlend = data.ManipulatedBlend or 0
    local HitscanBlend = data.HitscanBlend or 0
    local PlayerlistStatus = (not IsPreview) and IsPlayerPointer and ResolvePlayerlistStatus(plr) or nil

    local HighlightColor = nil
    local HighlightBlend = 0
    if PlayerlistStatus == 'Friendly' then
        HighlightColor = FriendlyStatusColor
        HighlightBlend = 1
    elseif PlayerlistStatus == 'Priority' or PlayerlistStatus == 'Enemy' then
        HighlightColor = HostileStatusColor
        HighlightBlend = 1
    elseif HitscanBlend > 0.001 then
        HighlightColor = Settings.HitscanColor.Color or Color3.fromRGB(112, 255, 247)
        HighlightBlend = HitscanBlend
    elseif ManipulatedBlend > 0.001 then
        HighlightColor = Settings.ManipulatedColor.Color or ManipulatedHighlightColor
        HighlightBlend = ManipulatedBlend
    else
        HighlightColor = VisibleColor
        HighlightBlend = data.VisibleBlend or 0
    end

    local CurrentWeapon
    if IsPreview then
        CurrentWeapon = data.CachedItem and
            ((data.CachedItem.Actual and data.CachedItem.Actual.Name and data.CachedItem.Actual) or data.CachedItem)
    elseif IsPlayerPointer then
        CurrentWeapon = Entities.GetWeapon(plr)
    else
        CurrentWeapon = data.CurrentWeapon
    end

    Snapshot.Player = plr
    Snapshot.Now = Now
    Snapshot.Character = Character
    Snapshot.CharacterOwner = data.CharacterOwner
    Snapshot.IsPreview = IsPreview
    Snapshot.IsPlayerPointer = IsPlayerPointer
    Snapshot.Root = Root
    Snapshot.Humanoid = Humanoid
    Snapshot.Health = Health
    Snapshot.MaxHealth = MaxHealth
    Snapshot.Position = Position
    Snapshot.Size = Size
    Snapshot.Width = Width
    Snapshot.Height = Height
    Snapshot.FrameX = FrameX
    Snapshot.FrameY = FrameY
    Snapshot.Distance = Distance
    Snapshot.RawDistance = RawDistance
    Snapshot.PreviewViewport = PreviewViewport
    Snapshot.PreviewCamera = PreviewCamera
    Snapshot.VisibleColor = VisibleColor
    Snapshot.HighlightColor = HighlightColor
    Snapshot.HighlightBlend = HighlightBlend
    Snapshot.PlayerlistStatus = PlayerlistStatus
    Snapshot.CurrentWeapon = CurrentWeapon
    Snapshot.UpdateInterval = UpdateInterval
    -- Snapshot.UseCheapBox = UseCheapBox

    data._lastSnapshotFrame = Now
    return Snapshot
end

local function EntitySnapshot(data, Snapshot, Settings)
    local plr = Snapshot.Player
    local IsPreview = Snapshot.IsPreview
    local IsPlayerPointer = Snapshot.IsPlayerPointer
    local health = Snapshot.Health
    local maxHealth = Snapshot.MaxHealth
    local width = Snapshot.Width
    local height = Snapshot.Height
    local FrameX = Snapshot.FrameX
    local FrameY = Snapshot.FrameY
    local dist = Snapshot.Distance
    local VisibleColor = Snapshot.VisibleColor
    local HighlightColor = Snapshot.HighlightColor or VisibleColor
    local HighlightBlend = Snapshot.HighlightBlend or data.VisibleBlend
    local CurrentWeapon = Snapshot.CurrentWeapon
    local Now = Snapshot.Now or os.clock()

    local BoxStyle = Settings.BoxStyle
    local HealthEnabled = Settings.HealthEnabled
    local HealthThickness = Settings.HealthThickness
    local HealthPos = 'Left'
    local AmmoEnabled = Settings.AmmoEnabled
    local AmmoThickness = Settings.AmmoThickness
    local AmmoPos = 'Bottom'
    EntityPoop(data, Snapshot, Settings)

    local BoxEnabled = Settings.BoxEnabled
    local BoxColor = Settings.BoxColor
    local BoxOutlineColor = Settings.BoxOutlineColor
    if BoxEnabled then
        if BoxStyle == 'Full' then
            Set(data.Strokes.Main, 'Color',
                (BoxColor.Color or WhiteColor):Lerp(HighlightColor or (BoxColor.Color or WhiteColor), HighlightBlend))
            Set(data.Strokes.Main, 'Transparency', BoxColor.Transparency or 0)
            Set(data.Strokes.Outer, 'Color', BoxOutlineColor.Color or BlackColor)
            Set(data.Strokes.Outer, 'Transparency', BoxOutlineColor.Transparency or 0.15)
            Set(data.Strokes.Inner, 'Color', BoxOutlineColor.Color or BlackColor)
            Set(data.Strokes.Inner, 'Transparency', BoxOutlineColor.Transparency or 0.15)
            Set(data.Box, 'Visible', true)
            Set(data.CornerHolder, 'Visible', false)
        else
            Set(data.Box, 'Visible', false)
            Set(data.CornerHolder, 'Visible', true)

            local c = data.Corner
            local CornerColor = (BoxColor.Color or WhiteColor):Lerp(HighlightColor or (BoxColor.Color or WhiteColor),
                HighlightBlend)
            local CornerAlpha = BoxColor.Transparency or 0
            local OutlineColor = BoxOutlineColor.Color or BlackColor
            local OutlineAlpha = BoxOutlineColor.Transparency or 0.15

            for _, corner in next, data.Corner do
                Set(corner[1], 'BackgroundColor3', CornerColor)
                Set(corner[1], 'BackgroundTransparency', CornerAlpha)
                Set(corner[2], 'BackgroundColor3', OutlineColor)
                Set(corner[2], 'BackgroundTransparency', OutlineAlpha)
            end
        end
    else
        Set(data.CornerHolder, 'Visible', false)
        Set(data.Box, 'Visible', false)
    end

    local FillOne = Settings.FillOne
    local FillTwo = Settings.FillTwo
    local FillOneColor = FillOne.Color or Color3.fromRGB(0, 0, 0)
    local FillTwoColor = FillTwo.Color or Color3.fromRGB(0, 0, 0)
    local FillOneTransparency = BoxEnabled and Settings.BoxFilled and (FillOne.Transparency or 1) or 1
    local FillTwoTransparency = BoxEnabled and Settings.BoxFilled and (FillTwo.Transparency or 0.8) or 1

    if not ColorsMatch(data._boxGradColorA, FillOneColor) or not ColorsMatch(data._boxGradColorB, FillTwoColor) then
        data._boxGradColorA = FillOneColor
        data._boxGradColorB = FillTwoColor
        data.BoxGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, FillOneColor), ColorSequenceKeypoint
            .new(1, FillTwoColor) })
    end
    if data._boxGradAlphaA ~= FillOneTransparency or data._boxGradAlphaB ~= FillTwoTransparency then
        data._boxGradAlphaA = FillOneTransparency
        data._boxGradAlphaB = FillTwoTransparency
        data.BoxGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, FillOneTransparency),
            NumberSequenceKeypoint.new(1, FillTwoTransparency) })
    end
    Set(data.BoxGradient, 'Rotation', Settings.BoxGradientRotation)

    if data.CharacterHighlight then
        Set(data.CharacterHighlight, 'Enabled', false)
    end

    if Settings.ChamsEnabled then
        if data._partsDirty or (Now - (data.LastChamsRefresh or 0)) >= Settings.ChamsRefreshFallback then
            ApplyCharacterChams(data, Settings)
            data.LastChamsRefresh = Now
        end
    else
        DestroyCharacterChams(data)
    end

    if Settings.Nametags then
        local NameColor = Settings.NameColor
        local text = IsPreview and (data.Name or 'Preview') or
            ((Settings.PreferDisplayNames and IsPlayerPointer and plr.DisplayName) or plr.Name)
        DrawText(data, 'Name', Settings.NamePosition, text,
            (NameColor.Color or WhiteColor):Lerp(HighlightColor or (NameColor.Color or WhiteColor), HighlightBlend),
            NameColor.Transparency or 0)
        data.Labels.Name.TextSize = 10
    elseif data.Labels.Name then
        HideText(data, 'Name')
    end

    if Settings.Distance then
        local DistanceColor = Settings.DistanceColor
        local DistanceText = ''

        if Settings.Units == 'Studs' then
            DistanceText = tostring(MathFloor(dist)) .. ' studs'
        else
            DistanceText = tostring(MathFloor(dist * 0.28)) .. ' meters'
        end

        DrawText(data, 'Distance', Settings.DistancePosition, DistanceText,
            (DistanceColor.Color or WhiteColor):Lerp(HighlightColor or (DistanceColor.Color or WhiteColor),
                HighlightBlend), DistanceColor.Transparency or 0)
    elseif data.Labels.Distance then
        HideText(data, 'Distance')
    end

    if Settings.Weapon then
        local WeaponColor = Settings.WeaponColor
        local Cached = data.CachedItem
        local weaponName = IsPreview and ((Cached and Cached.Name) or 'None') or
            (CurrentWeapon and CurrentWeapon.Name or 'None')
        DrawText(data, 'Weapon', Settings.WeaponPosition, weaponName,
            (WeaponColor.Color or WeaponFallbackColor):Lerp(HighlightColor or (WeaponColor.Color or WeaponFallbackColor),
                HighlightBlend), WeaponColor.Transparency or 0)
    elseif data.Labels.Weapon then
        HideText(data, 'Weapon')
    end

    if data._lastWeaponVisual ~= CurrentWeapon then
        data._lastWeaponVisual = CurrentWeapon
        UpdateWeaponVisuals(data, CurrentWeapon)
        data._layoutDirty = true
    end

    local WeaponIconVisible = Settings.WeaponIcon and data.WeaponIcon.Image ~= ''
    if data._weaponIconVisible ~= WeaponIconVisible then
        data._weaponIconVisible = WeaponIconVisible
        data._layoutDirty = true
    end
    Set(data.WeaponIcon, 'Visible', WeaponIconVisible)

    for _, side in next, data.Sides do
        if side.HB then
            Set(side.HB, 'Visible', false)
            Set(side.HBFill, 'Visible', false)
        end
        if side.AB then
            Set(side.AB, 'Visible', false)
            Set(side.ABFill, 'Visible', false)
        end
    end

    if HealthEnabled then
        local pos = HealthPos
        local side = data.Sides[pos]
        if side and side.HB then
            local pct = MathClamp(health / MathMax(1, maxHealth), 0, 1)
            local bar = side.HB
            local HBFill = side.HBFill
            local grad = side.Grad
            local LowColor = Settings.HealthGradientLow
            local MidColor = Settings.HealthGradientMid
            local HighColor = Settings.HealthGradientHigh
            local thick = HealthThickness
            local HealthLow = LowColor.Color or HealthLowFallback
            local HealthMid = MidColor.Color or HealthMidFallback
            local HealthHigh = HighColor.Color or HealthHighFallback

            if not ColorsMatch(data._healthGradLow, HealthLow) or not ColorsMatch(data._healthGradMid, HealthMid) or not ColorsMatch(data._healthGradHigh, HealthHigh) then
                data._healthGradLow = HealthLow
                data._healthGradMid = HealthMid
                data._healthGradHigh = HealthHigh
                grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, HealthLow), ColorSequenceKeypoint.new(0.5,
                    HealthMid), ColorSequenceKeypoint.new(1, HealthHigh) })
            end

            data.lasthealth = data.lasthealth or pct
            data.lasthealth = data.lasthealth + (pct - data.lasthealth) * 0.15
            pct = data.lasthealth

            if pos == 'Top' then
                if data._healthBarPos ~= pos or data._healthBarThickness ~= thick then
                    data._healthBarPos = pos
                    data._healthBarThickness = thick
                    Set(bar, 'LayoutOrder', 100)
                    Set(bar, 'Size', UDim2.new(1, 0, 0, thick))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(HBFill, 'AnchorPoint', Vector2.new(0, 0))
                    Set(HBFill, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(grad, 'Rotation', 0)
                end
                Set(HBFill, 'Size', UDim2.new(1 - pct, 0, 1, 0))
            elseif pos == 'Bottom' then
                if data._healthBarPos ~= pos or data._healthBarThickness ~= thick then
                    data._healthBarPos = pos
                    data._healthBarThickness = thick
                    Set(bar, 'LayoutOrder', -100)
                    Set(bar, 'Size', UDim2.new(1, 0, 0, thick))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(HBFill, 'AnchorPoint', Vector2.new(1, 0))
                    Set(HBFill, 'Position', UDim2.new(1, 1, 0, 0))
                    Set(grad, 'Rotation', 0)
                end
                Set(HBFill, 'Size', UDim2.new(1 - pct, 0, 1, 0))
            elseif pos == 'Left' then
                if data._healthBarPos ~= pos or data._healthBarThickness ~= thick then
                    data._healthBarPos = pos
                    data._healthBarThickness = thick
                    Set(bar, 'Size', UDim2.new(0, thick, 1, 0))
                    Set(bar, 'LayoutOrder', 100)
                    Set(bar, 'Position', UDim2.new(1, -thick, 0, 0))
                    Set(grad, 'Rotation', -90)
                end
                Set(HBFill, 'Size', UDim2.new(1, 0, 1 - pct, 0))
            else
                if data._healthBarPos ~= pos or data._healthBarThickness ~= thick then
                    data._healthBarPos = pos
                    data._healthBarThickness = thick
                    Set(bar, 'LayoutOrder', -100)
                    Set(bar, 'Size', UDim2.new(0, thick, 1, 0))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(grad, 'Rotation', -90)
                end
                Set(HBFill, 'Size', UDim2.new(1, 0, 1 - pct, 0))
            end

            if bar.Parent ~= side.Frame then
                bar.Parent = side.Frame
            end
            Set(bar, 'Visible', true)
            Set(HBFill, 'Visible', true)
        end
    end

    local DisplayedHealthRatio = MathClamp(data.lasthealth or (health / MathMax(1, maxHealth)), 0, 1)
    if Settings.HealthText and DisplayedHealthRatio < 0.999 then
        local HealthTextColor = Settings.HealthTextColor
        local side = data.Sides[HealthPos]
        local bar = side and side.HB
        if HealthEnabled and bar then
            DrawBarText(data, 'Health', bar, HealthPos, tostring(MathFloor(health + 0.5)),
                (HealthTextColor.Color or WhiteColor):Lerp(HighlightColor or (HealthTextColor.Color or WhiteColor),
                    HighlightBlend), HealthTextColor.Transparency or 0, Settings.HealthTextFollowBar == true,
                DisplayedHealthRatio)
        else
            HideBarText(data, 'Health')
        end
    else
        HideBarText(data, 'Health')
    end

    local Ammo = tonumber(data.Ammo) or 0
    local MaxAmmo = tonumber(data.MaxAmmo) or 0
    local HasWeapon = IsPreview or (CurrentWeapon ~= nil) or (data.CachedItem ~= nil)
    if IsPreview and MaxAmmo <= 0 then
        Ammo, MaxAmmo = 15, 30
    end

    local CanShowAmmo = (not Settings.AmmoRequireWeapon or HasWeapon) and (MaxAmmo > 0 or not Settings.AmmoHideEmpty)
    if AmmoEnabled and CanShowAmmo then
        if MaxAmmo <= 0 then
            MaxAmmo = 1
        end

        local pos = AmmoPos
        local side = data.Sides[pos]
        if side and side.AB then
            local bar = side.AB
            local ABFill = side.ABFill
            local grad = side.ABGrad
            local thick = AmmoThickness
            local AmmoColor = Settings.AmmoColor
            local BaseColor = AmmoColor.Color or AmmoFallbackBase
            local FadeColor = BaseColor:Lerp(AmmoFallbackFade, 0.35)
            local Alpha = AmmoColor.Transparency or 0
            local pct = MathClamp(Ammo / MathMax(1, MaxAmmo), 0, 1)
            local StackedWithHealth = HealthEnabled and (HealthPos == pos)

            data.lastammo = data.lastammo or pct
            data.lastammo = data.lastammo + (pct - data.lastammo) * 0.2
            pct = data.lastammo

            if not ColorsMatch(data._ammoGradBase, BaseColor) or not ColorsMatch(data._ammoGradFade, FadeColor) then
                data._ammoGradBase = BaseColor
                data._ammoGradFade = FadeColor
                grad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, BaseColor), ColorSequenceKeypoint.new(1,
                    FadeColor) })
            end

            Set(bar, 'BackgroundColor3', BaseColor)
            Set(bar, 'BackgroundTransparency', Alpha)

            if pos == 'Top' then
                local LayoutOrder = StackedWithHealth and 110 or 100
                if data._ammoBarPos ~= pos or data._ammoBarThickness ~= thick or data._ammoBarOrder ~= LayoutOrder then
                    data._ammoBarPos = pos
                    data._ammoBarThickness = thick
                    data._ammoBarOrder = LayoutOrder
                    Set(bar, 'LayoutOrder', LayoutOrder)
                    Set(bar, 'Size', UDim2.new(1, 0, 0, thick))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(ABFill, 'AnchorPoint', Vector2.new(0, 0))
                    Set(ABFill, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(grad, 'Rotation', 0)
                end
                Set(ABFill, 'Size', UDim2.new(1 - pct, 0, 1, 0))
            elseif pos == 'Bottom' then
                local LayoutOrder = StackedWithHealth and -90 or -100
                if data._ammoBarPos ~= pos or data._ammoBarThickness ~= thick or data._ammoBarOrder ~= LayoutOrder then
                    data._ammoBarPos = pos
                    data._ammoBarThickness = thick
                    data._ammoBarOrder = LayoutOrder
                    Set(bar, 'LayoutOrder', LayoutOrder)
                    Set(bar, 'Size', UDim2.new(1, 0, 0, thick))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(ABFill, 'AnchorPoint', Vector2.new(1, 0))
                    Set(ABFill, 'Position', UDim2.new(1, 1, 0, 0))
                    Set(grad, 'Rotation', 0)
                end
                Set(ABFill, 'Size', UDim2.new(1 - pct, 0, 1, 0))
            elseif pos == 'Left' then
                local LayoutOrder = StackedWithHealth and 90 or 100
                if data._ammoBarPos ~= pos or data._ammoBarThickness ~= thick or data._ammoBarOrder ~= LayoutOrder then
                    data._ammoBarPos = pos
                    data._ammoBarThickness = thick
                    data._ammoBarOrder = LayoutOrder
                    Set(bar, 'LayoutOrder', LayoutOrder)
                    Set(bar, 'Size', UDim2.new(0, thick, 1, 0))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(grad, 'Rotation', -90)
                end
                Set(ABFill, 'Size', UDim2.new(1, 0, 1 - pct, 0))
            else
                local LayoutOrder = StackedWithHealth and -90 or -100
                if data._ammoBarPos ~= pos or data._ammoBarThickness ~= thick or data._ammoBarOrder ~= LayoutOrder then
                    data._ammoBarPos = pos
                    data._ammoBarThickness = thick
                    data._ammoBarOrder = LayoutOrder
                    Set(bar, 'LayoutOrder', LayoutOrder)
                    Set(bar, 'Size', UDim2.new(0, thick, 1, 0))
                    Set(bar, 'Position', UDim2.new(0, 0, 0, 0))
                    Set(grad, 'Rotation', -90)
                end
                Set(ABFill, 'Size', UDim2.new(1, 0, 1 - pct, 0))
            end

            if bar.Parent ~= side.Frame then
                bar.Parent = side.Frame
            end
            Set(bar, 'Visible', true)
            Set(ABFill, 'Visible', true)
        end
    end

    local DisplayedAmmoRatio = MathClamp(data.lastammo or (Ammo / MathMax(1, MaxAmmo > 0 and MaxAmmo or 1)), 0, 1)
    if Settings.AmmoText and CanShowAmmo and DisplayedAmmoRatio < 0.999 then
        local AmmoTextColor = Settings.AmmoTextColor
        local side = data.Sides[AmmoPos]
        local bar = side and side.AB
        if AmmoEnabled and bar then
            DrawBarText(data, 'Ammo', bar, AmmoPos, tostring(MathFloor(Ammo + 0.5)),
                (AmmoTextColor.Color or WhiteColor):Lerp(HighlightColor or (AmmoTextColor.Color or WhiteColor),
                    HighlightBlend), AmmoTextColor.Transparency or 0, Settings.AmmoTextFollowBar == true,
                DisplayedAmmoRatio)
        else
            HideBarText(data, 'Ammo')
        end
    else
        HideBarText(data, 'Ammo')
    end

    data._partsDirty = false

    if Settings.FlagsEnabled then
        local FlagSide = Settings.FlagSide
        local ActiveFlags = data._activeFlags or {}
        local NextActiveFlags = {}
        for _, key in ipairs(CachedEnabledFlagNames) do
            local flagsdata = Entities.Flags[key]
            local CachedFlag = CachedFlagRenderSettings[key]
            if flagsdata and CachedFlag and (flagsdata.Allow(plr) or plr.Name == 'Rig') then
                local FlagColor = CachedFlag.Color
                if type(flagsdata.Color) == 'function' then
                    FlagColor = flagsdata.Color(plr, FlagColor) or FlagColor
                else
                    FlagColor = CachedFlag.Color:Lerp(HighlightColor or CachedFlag.Color, HighlightBlend)
                end
                DrawText(data, key, FlagSide, flagsdata.Text(plr), FlagColor, CachedFlag.Transparency)
                NextActiveFlags[key] = true
            elseif data.Labels[key] then
                HideText(data, key)
            end
        end
        for key in next, ActiveFlags do
            if not NextActiveFlags[key] and data.Labels[key] then
                HideText(data, key)
            end
        end
        data._activeFlags = NextActiveFlags
    else
        for key in next, data._activeFlags or {} do
            if data.Labels[key] then
                HideText(data, key)
            end
        end
        data._activeFlags = {}
    end

    data._lastVisualUpdate = Now
end

local LastEntityFrame = 0
local EntityFrameRate = 1 / 60
local SeenCharacters = {}
local FrameCameraPosition = nil
local FrameMousePosition = Vector2.zero
local FrameViewportSize = Vector2.zero
local MinVisualUpdateInterval = 1 / 30

local conn = RunService.RenderStepped:Connect(function()
    debug.profilebegin('EntityUpdate')
    local Now = os.clock()
    if (Now - LastEntityFrame) < EntityFrameRate then
        debug.profileend()
        return
    end
    LastEntityFrame = Now

    local Settings = GetRenderSettings(Now)
    EntityFrameRate = Settings.CloseUpdateInterval > 0 and Settings.CloseUpdateInterval or (1 / 60)
    FrameCameraPosition = Camera and Camera.CFrame.Position or nil
    FrameMousePosition = UserInputService:GetMouseLocation()
    FrameViewportSize = Camera and Camera.ViewportSize or Vector2.zero

    for Pointer, Entity in next, MiscCache do
        if Pointer == Entity.Pointer then
            Entity._FrameCameraPosition = FrameCameraPosition
            Entity._FrameMousePosition = FrameMousePosition
            Entity._FrameViewportSize = FrameViewportSize
            Entity:Update(Now)
        end
    end

    if not Settings.Enabled or not Settings.HasAnyWork then
        for _, data in next, Cache do
            if not data._isHidden then
                HideEntityNow(data)
            end
        end
        debug.profileend()
        return
    end

    local LPChar = LocalPlayer.Character
    local LPHead = LPChar and (LPChar:FindFirstChild('head') or LPChar:FindFirstChild('Head'))
    local LocalViewOrigin = (LPHead and LPHead.Position) or Camera.CFrame.Position
    table.clear(SeenCharacters)

    for plr, data in next, Cache do
        if not data.IsPreview and data.IsPlayer and typeof(plr) == 'Instance' and plr:IsA('Player') then
            local LiveCharacter = plr.Character or data:GetCharacter()
            if LiveCharacter ~= data.Character then
                data._nextEntityUpdate = 0
                data._partsDirty = true
                if not LiveCharacter then
                    if not data._isHidden then
                        HideEntityNow(data)
                    end
                    continue
                end
            end
        end

        local ResolvedCharacter = data:GetCharacter()

        if not data.IsPreview and ResolvedCharacter then
            if SeenCharacters[ResolvedCharacter] then
                if not data._isHidden then
                    HideEntityNow(data)
                end
                data._nextEntityUpdate = Now + 0.08
                continue
            end
            SeenCharacters[ResolvedCharacter] = true
        end

        if not data.IsPreview and ((not ResolvedCharacter) or (not ResolvedCharacter.Parent)) then
            if not data._isHidden then
                HideEntityNow(data)
            end
            data._nextEntityUpdate = 0
            continue
        end

        local NextUpdate = data._nextEntityUpdate or 0
        if Now < NextUpdate then
            if data._lastVisibleFrame and (Now - data._lastVisibleFrame) <= 0.22 and data._snapshot and data._snapshot.Size then
                Set(data.Frame, 'Visible', true)
                data._isHidden = false
            elseif not data._isHidden then
                HideEntityNow(data)
            end
            continue
        end

        local Snapshot = BuildSnapshot(plr, data, Settings, Now, ResolvedCharacter, LocalViewOrigin)
        if not Snapshot then
            if not data._isHidden then
                HideEntityNow(data)
            end
            data._nextEntityUpdate = Now + 0.08
            continue
        end

        local UpdateInterval = Snapshot.UpdateInterval or 0
        local VisualInterval = UpdateInterval > 0 and MathMax(UpdateInterval, MinVisualUpdateInterval) or
            MinVisualUpdateInterval
        local NeedsVisualRefresh = data._isHidden
            or data._layoutDirty
            or not data._lastVisualUpdate
            or (Now - data._lastVisualUpdate) >= VisualInterval

        if NeedsVisualRefresh then
            EntitySnapshot(data, Snapshot, Settings)
        else
            EntityPoop(data, Snapshot, Settings)
        end

        data._nextEntityUpdate = UpdateInterval > 0 and (Now + UpdateInterval) or Now

        if data._lastVisibleFrame and (Now - data._lastVisibleFrame) > 0.35 then
            HideEntityNow(data)
        end
    end

    debug.profileend()
end)
_G.Entities = Entities;
return Entities
