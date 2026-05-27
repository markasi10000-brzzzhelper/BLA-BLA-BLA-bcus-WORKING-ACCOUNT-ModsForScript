--[[
    1/18/2026
    Raycast.lua
    Purpose:
        Easily usable raycasting module to speed up work and prevent redundancy
        Contains several presets and contains builders for those presets.
    Author: @.yxyv
    Dependencies:
        None
]]

local Workspace = cloneref(game.GetService(game, "Workspace"));
local Players = cloneref(game.GetService(game, "Players"));
local Client = Players.LocalPlayer;
local Mouse = Client:GetMouse();

local RaycastModule = {
    Instances = {};
};

local function FindFallenIgnoredInstances()
    local Ignore = {};
    local Character = Client.Character;
    if Character then
        Ignore[#Ignore + 1] = Character;
    end

    local WorldVFX = Workspace:FindFirstChild("VFX");
    if WorldVFX then
        Ignore[#Ignore + 1] = WorldVFX;

        local VMs = WorldVFX:FindFirstChild("VMs");
        if VMs then
            Ignore[#Ignore + 1] = VMs;
        end
    end

    return Ignore
end

local function ShouldUseFallenFilter(Self)
    return Self.Name == "FallenCombatRay" or Self.Name == "FallenVisibilityRay"
end

local function ApplyDynamicFilter(Self)
    if not ShouldUseFallenFilter(Self) then
        return Self.RaycastParams
    end

    Self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    Self.RaycastParams.FilterDescendantsInstances = FindFallenIgnoredInstances()
    return Self.RaycastParams
end

local ManipulationOffsets = {
    CFrame.new(3, 0, 0),         CFrame.new(-3, 0, 0),      CFrame.new(-6, 0, 0),
    CFrame.new(6, 0, 0),         CFrame.new(3, 2, 0),       CFrame.new(-3, 2, 0),
    CFrame.new(-6, 2, 0),        CFrame.new(6, 2, 0),       CFrame.new(4, 0, 0),
    CFrame.new(-4, 2, 0),        CFrame.new(-4, 0, 0),      CFrame.new(4, 2, 0),
    CFrame.new(7, 0, 0),         CFrame.new(-7, 2, 0),      CFrame.new(-7, 0, 0),
    CFrame.new(7, 2, 0),         CFrame.new(0.2, 3.9, 0),   CFrame.new(1.8, 4.1, 1),
    CFrame.new(2.1, 4.4, 1.1),   CFrame.new(0.15, 5.2, 0.1),CFrame.new(-1.8, 5.4, -0.2),
    CFrame.new(-2.3, 6.35, -0.4),CFrame.new(0.1, 7.5, 0),   CFrame.new(0.1, 8, 0),
    CFrame.new(0.1, 8, 0),
};
RaycastModule.ManipulationOffsets = ManipulationOffsets;

local UndergroundOffsets = {
    CFrame.new( 0, -8,  0),
    CFrame.new( 3, -8,  0),  CFrame.new(-3, -8,  0),
    CFrame.new( 6, -8,  0),  CFrame.new(-6, -8,  0),
    CFrame.new( 4, -8,  2),  CFrame.new(-4, -8, -2),
    CFrame.new( 4, -8,  4),  CFrame.new(-4, -8, -4),
    CFrame.new( 1, -8,  3),  CFrame.new(-1, -8, -3),

    CFrame.new( 0, -10,  0),
    CFrame.new( 3, -10,  0),  CFrame.new(-3, -10,  0),
    CFrame.new( 6, -10,  0),  CFrame.new(-6, -10,  0),
    CFrame.new( 5, -10,  3),  CFrame.new(-5, -10, -3),
    CFrame.new( 2, -10,  0),  CFrame.new(-2, -10,  0),

    CFrame.new( 0, -12,  0),
    CFrame.new( 3, -12,  0),  CFrame.new(-3, -12,  0),
    CFrame.new( 6, -12,  0),  CFrame.new(-6, -12,  0),
    CFrame.new( 4, -12,  2),  CFrame.new(-4, -12, -2),
    CFrame.new( 7, -12,  0),  CFrame.new(-7, -12,  0),
}
RaycastModule.UndergroundOffsets = UndergroundOffsets;

local HitscanAngles = { -- prefer small
	Vector3.new(1 / 2, 0, 0), -- small right
	Vector3.new(-1 / 2, 0, 0), -- small left
	Vector3.new(0, 0, 1 / 2), -- small forward
	Vector3.new(0, 0, -1 / 2), -- small backward
	Vector3.new(0, 1 / 2, 0), -- small up
	Vector3.new(0, -1 / 2, 0), -- small down

	Vector3.new(1 / 2, 1 / 2, 0), -- small right up
	Vector3.new(1 / 2, -1 / 2, 0), -- small right down
	Vector3.new(-1 / 2, 1 / 2, 0), -- small left up
	Vector3.new(-1 / 2, -1 / 2, 0), -- small left down
	Vector3.new(0, 1 / 2, 1 / 2), -- small forward up
	Vector3.new(0, -1 / 2, 1 / 2), -- small forward down
	Vector3.new(0, 1 / 2, -1 / 2), -- small backward up
	Vector3.new(0, -1 / 2, -1 / 2), -- small backward down

	Vector3.new(1, 0, 0), -- big right
	Vector3.new(-1, 0, 0), -- big left
	Vector3.new(0, 0, 1), -- big forward
	Vector3.new(0, 0, -1), -- big backward
	Vector3.new(0, 1, 0), -- big up
	Vector3.new(0, -1, 0), -- big down
}
RaycastModule.HitscanAngles = HitscanAngles;

RaycastModule.__index = RaycastModule

--// initial class builder
function RaycastModule:New(Name: string)
    local CurrentTick = tick()
    local NewRaycastBuilder = setmetatable({
        Name = Name,
        IgnoreWater = true,
        RaycastParams = RaycastParams.new(),
        CreatedAt = CurrentTick,
        LastUsed = CurrentTick,
    }, RaycastModule)

    RaycastModule.Instances[Name] = NewRaycastBuilder
    return NewRaycastBuilder
end

--// Parameter setting
function RaycastModule:SetParams(Data: table)
    for Index, Value in Data do
        self.RaycastParams[Index] = Value
    end
end

function RaycastModule:SetFilterType(FilterType: EnumItem)
    self.RaycastParams.FilterType = FilterType
end

function RaycastModule:SetFilter(Filter: table)
    self.RaycastParams.FilterDescendantsInstances = Filter
end

function RaycastModule:AppendToFilter(Object: Instance)
    local Filter = self.RaycastParams.FilterDescendantsInstances
    Filter[#Filter + 1] = Object
end

function RaycastModule:SetIgnoreWater(State: boolean)
    self.RaycastParams.IgnoreWater = State
end

--// Presets
function RaycastModule:Send(Origin: Vector3, Destination: Vector3)
    local Delta = (Destination - Origin)
    if Delta.Magnitude == 0 then
        return nil
    end
    local Direction = Delta.Unit
    local Distance = Delta.Magnitude
    local Result = Workspace:Raycast(Origin, Direction * Distance, ApplyDynamicFilter(self))
    return Result
end

--// Useful if you already have direction
function RaycastModule:SendToDirection(Origin: Vector3, Direction: Vector3, Distance: number)
    if Direction.Magnitude == 0 then
        return nil
    end
    local NormalizedDir = Direction.Unit
    local Result = Workspace:Raycast(Origin, NormalizedDir * (Distance + 7.5), ApplyDynamicFilter(self))
    return Result
end

--// Useful for basic visible checks
function RaycastModule:IsPartVisible(Origin: Vector3, Part: Instance, Model)
    local Result = self:Send(Origin, Part.CFrame.Position)

    if Result and Result.Instance and Model and Result.Instance:IsDescendantOf(Model) then
        return true, Origin, Part
    end;

    if Result and Result.Instance == Part then
        return true, Origin, Part
    end
    return false
end

--// Useful for model wide visible checks
function RaycastModule:IsModelVisible(Origin: Vector3, Destination: Vector3, Model: Instance)
    local Result = self:Send(Origin, Destination)
    if Result and Result.Instance and (Result.Instance:IsDescendantOf(Model) or Result.Instance == Model) then
        return true, Origin, Destination
    end
    return false, nil, nil
end

--// Preset for mouse raycasting
function RaycastModule:MouseRaycast(Distance: number)
    local Direction = Mouse.UnitRay.Direction.Unit
    local Result = Workspace:Raycast(Mouse.UnitRay.Origin, Direction * (Distance + 7.5), ApplyDynamicFilter(self))
    return Result
end

--// Multi-scan manipulation
function RaycastModule:FindVisiblePositionOnModel(Origin: CFrame, Model: Instance, PartsList: table)
    local Results = {}
    for _, Offset in ManipulationOffsets do
        local WorldPosition = (Origin * Offset).Position
        for _, PartName in PartsList do
            local Part = Model:FindFirstChild(PartName)
            if not Part then continue end
            local IsVisible = self:IsPartVisible(WorldPosition, Part)
            if IsVisible then
                Results[#Results + 1] = {
                    ["Part"] = Part,
                    ["NewOrigin"] = WorldPosition,
                    ["OldOrigin"] = Origin
                }
            end
        end
    end
    return Results
end;

--// Single-scan manipulation
function RaycastModule:FindVisiblePositionOnPart(Origin: CFrame, Part: Instance)
    for _, Offset in ManipulationOffsets do
        local WorldPosition = (Origin * Offset).Position
        if self:IsPartVisible(WorldPosition, Part) then
            return {
                ["Part"] = Part,
                ["NewOrigin"] = WorldPosition,
                ["OldOrigin"] = Origin
            }
        end
    end
    return nil
end;

--// Multi-scan manipulation (underground)
function RaycastModule:FindUndergroundVisiblePositionOnModel(Origin: CFrame, Model: Instance, PartsList: table)
    local Results = {}
    for _, Offset in UndergroundOffsets do
        local WorldPosition = (Origin * Offset).Position
        for _, PartName in PartsList do
            local Part = Model:FindFirstChild(PartName)
            if not Part then continue end
            local IsVisible = self:IsPartVisible(WorldPosition, Part)
            if IsVisible then
                Results[#Results + 1] = {
                    ["Part"] = Part,
                    ["NewOrigin"] = WorldPosition,
                    ["OldOrigin"] = Origin
                }
            end
        end
    end
    return Results
end;

--// Single-scan manipulation (underground)
function RaycastModule:FindUndergroundVisiblePositionOnPart(Origin: CFrame, Part: Instance)
    for _, Offset in UndergroundOffsets do
        local WorldPosition = (Origin * Offset).Position
        if self:IsPartVisible(WorldPosition, Part) then
            return {
                ["Part"] = Part,
                ["NewOrigin"] = WorldPosition,
                ["OldOrigin"] = Origin
            }
        end
    end
    return nil
end;


--// Fallen trajectory simulation
function RaycastModule:SimulateFallenTrajectory(Origin: Vector3, Destination: Vector3, Stats: table)
    local Speed = Stats.Speed
    local GravityScale = Stats.Gravity or 1
    local Step = Stats.Step or (1/60)
    local MaxTime = Stats.MaxTime or 5

    local Gravity = Vector3.new(0, 196.2 * GravityScale, 0)
    local Direction = Destination - Origin
    if Direction.Magnitude == 0 then return {Origin} end

    local Velocity = Direction.Unit * Speed
    local Position = Origin
    local Points = {Position}
    local Time = 0

    while Time < MaxTime do
        local NextPosition = Position + Velocity * Step
        Points[#Points + 1] = NextPosition

        Velocity -= Gravity * Step
        Position = NextPosition
        Time += Step

        if Position.Y <= Destination.Y and Velocity.Y < 0 then break end
    end

    return Points
end

_G.RaycastModule = RaycastModule;
return RaycastModule
