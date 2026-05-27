--[[
    3/31/2026
    Env.lua
    Purpose:
        Environment functions and references for all NH things

    Author: @.yxyv
    Dependencies:
        None
    Note:
        Please use this whenever application
]]

Env = {
    -- Custom Functions
    CustomFloor             = function(Num) return Num - Num % 1; end,
    CustomConcat            = function(t, sep, i, j)
        sep = sep or ""; i = i or 1; j = j or #t; local ConcatReturn = ""; for _i = i, #t do
            if _i == #t then
                ConcatReturn =
                    ConcatReturn .. t[_i]
            else
                ConcatReturn = ConcatReturn .. t[_i] .. sep;
            end;
        end; return ConcatReturn;
    end,
    CustomInsert            = function(t, v) t[#t + 1] = v; end,
    Fallen                  = {},
    ProjectDelta            = {},
    Disconnect              = function(Connection)
        if Connection then
            Connection:Disconnect();
        end;
        return nil;
    end,
    IgnorePreviewDescendant = function(Descendant, Viewmodel)
        if not Descendant then
            return false;
        end;
        if Descendant == Viewmodel then
            return false;
        end;
        if Descendant:GetAttribute("PDIgnorePreview") == true
            or Descendant:GetAttribute("PDIgnoreChams") == true
        then
            return true;
        end;
        local Name = string.lower(Descendant.Name or "");
        return Name:find("lagcham", 1, true) ~= nil
            or Name:find("fakecham", 1, true) ~= nil
            or Name:find("createfakechams", 1, true) ~= nil
            or Name:find("ignoreme", 1, true) ~= nil;
    end,
    HidePreviewDescendant   = function(Descendant)
        if not Descendant then
            return;
        end;
        if Descendant:IsA("Model") or Descendant:IsA("BasePart") then
            Descendant:SetAttribute("PDIgnoreChams", true);
        end;
        if Descendant:IsA("BasePart") then
            Descendant.LocalTransparencyModifier = 1;
            Descendant.Transparency = 1;
        elseif Descendant:IsA("Decal") or Descendant:IsA("Texture") then
            Descendant.Transparency = 1;
        elseif Descendant:IsA("Highlight") then
            Descendant.Enabled = false;
        end;
    end,
    RefreshPreviewViewport  = function(Viewport, Viewmodel)
        if not (Viewport and Viewmodel) then
            return;
        end;
        for _, Descendant in ipairs(Viewport:GetDescendants()) do
            if Env.IgnorePreviewDescendant(Descendant, Viewmodel) then
                Env.HidePreviewDescendant(Descendant);
            end;
        end;
    end,
    ResolvePreviewParts     = function(Holder)
        if not Holder then
            return nil, nil, nil;
        end;
        for _, Descendant in ipairs(Holder:GetDescendants()) do
            if Descendant:IsA("ViewportFrame") then
                local Background = Descendant.Parent;
                if Background and Background:IsA("GuiObject") then
                    return Background, Descendant, Descendant:FindFirstChild("Viewmodel");
                end;
            end;
        end;
        return nil, nil, nil;
    end,
    CreateVMOption          = function(Section, Library, Name, Materials)
        local Toggle = Section:Toggle({
            Name = Name,
            Flag = Name .. "Enabled",
        });
        Toggle:Colorpicker({
            Name = Name .. "Color",
            Flag = Name .. "Color",
            Default = Library.Theme.Accent,
            Alpha = 0.5,
        });
        local Settings = Toggle:Settings();
        Settings:Dropdown({
            Name = "Material",
            Flag = Name .. "Material",
            Items = Materials or { "SmoothPlastic", "ForceField", "Neon", "Glass" },
            Default = "ForceField",
        });
        Settings:Slider({
            Name = "Reflectance",
            Flag = Name .. "Reflectance",
            Min = 0,
            Max = 5,
            Decimals = 0.001,
            Default = 0,
        });
        return Toggle;
    end,
    CreateSkinOption        = function(SettingsSection, SkinTypes, WeaponName)
        local Dropdown;
        local SkinItems = SkinTypes[WeaponName] or { "Default" };
        local DefaultSkin = SkinItems[1] or "Default";
        SettingsSection:Toggle({
            Name = WeaponName,
            Flag = "EnableSkin_" .. WeaponName,
            Callback = function(Value)
                if Dropdown then
                    Dropdown:SetVisibility(Value);
                end;
            end,
        });
        Dropdown = SettingsSection:Dropdown({
            Name = "Skin",
            Flag = "Skin_" .. WeaponName,
            Items = SkinItems,
            Default = DefaultSkin,
        });
        Dropdown:SetVisibility(false);
        return Dropdown;
    end,
    UpsertEntity            = function(IndexTable, Factory, Key, Data)
        local Existing = IndexTable[Key];
        if Existing then
            for Name, Value in next, Data do
                Existing[Name] = Value;
            end;
            return Existing;
        end;
        Data.Pointer = Data.Pointer or Key;
        local Entity = Factory(Data);
        IndexTable[Key] = Entity;
        return Entity;
    end,
    RemoveEntity            = function(IndexTable, CacheTable, Key)
        local Entity = IndexTable[Key];
        if not Entity then
            return;
        end;
        if Entity.Components and Entity.Components.Holder then
            Entity.Components.Holder.Visible = false;
            Entity.Components.Holder:Destroy();
        end;
        if Entity.Pointer then
            CacheTable[Entity.Pointer] = nil;
        end;
        if Entity.Instance then
            CacheTable[Entity.Instance] = nil;
        end;
        IndexTable[Key] = nil;
    end,

    -- Debug Menu
    GetConstants            = debug.getconstants,
    GetRegistry             = debug.getregistry,
    GetUpvalues             = debug.getupvalues,
    GetConstant             = debug.getconstant,
    SetConstant             = debug.setconstant,
    GetUpvalue              = debug.getupvalue,
    ValidLevel              = debug.validlevel,
    LoadModule              = debug.loadmodule,
    SetUpvalue              = debug.setupvalue,
    GetProtos               = debug.getprotos,
    GetLocals               = debug.getlocals,
    Traceback               = debug.traceback,
    SetStack                = debug.setstack,
    GetLocal                = debug.getlocal,
    DumpHeap                = debug.dumpheap,
    GetProto                = debug.getproto,
    SetLocal                = debug.setlocal,
    GetStack                = debug.getstack,
    GetFenv                 = debug.getfenv,
    GetInfo                 = debug.getinfo,
    Info                    = debug.info,

    -- Math Menu
    Floor                   = math.floor,
    RandomSeed              = math.randomseed,
    Random                  = math.random,
    Frexp                   = math.frexp,
    Atan2                   = math.atan2,
    Log10                   = math.log10,
    Noise                   = math.noise,
    Round                   = math.round,
    Ldexp                   = math.ldexp,
    Clamp                   = math.clamp,
    Sinh                    = math.sinh,
    Sign                    = math.sign,
    Asin                    = math.asin,
    Acos                    = math.acos,
    Fmod                    = math.fmod,
    Huge                    = math.huge,
    Tanh                    = math.tanh,
    Sqrt                    = math.sqrt,
    Atan                    = math.atan,
    Modf                    = math.modf,
    Ceil                    = math.ceil,
    Cosh                    = math.cosh,
    Deg                     = math.deg,
    Min                     = math.min,
    Log                     = math.log,
    Cos                     = math.cos,
    Exp                     = math.exp,
    Max                     = math.max,
    Rad                     = math.rad,
    Abs                     = math.abs,
    Pow                     = math.pow,
    Sin                     = math.sin,
    Tan                     = math.tan,
    Pi                      = math.pi,

    -- String Menu
    PackSize                = string.packsize,
    Reverse                 = string.reverse,
    Unpack                  = string.unpack,
    Gmatch                  = string.gmatch,
    Format                  = string.format,
    Lower                   = string.lower,
    Split                   = string.split,
    Match                   = string.match,
    Upper                   = string.upper,
    Byte                    = string.byte,
    Char                    = string.char,
    Pack                    = string.pack,
    Gsub                    = string.gsub,
    Find                    = string.find,
    Rep                     = string.rep,
    Sub                     = string.sub,
    Len                     = string.len,

    -- Table Menu
    Unpack                  = table.unpack,
    Move                    = table.move,
    Pack                    = table.pack,
    Sort                    = table.sort,
    Find                    = table.find,
    Clear                   = table.clear,
    Maxn                    = table.maxn,
    Remove                  = table.remove,
    Sort                    = table.sort,
    Insert                  = table.insert,
    Concat                  = table.concat,
    Clone                   = table.clone,
    Foreach                 = table.foreach,

    -- Coroutines Menu
    Resume                  = coroutine.resume,
    Running                 = coroutine.running,
    Status                  = coroutine.status,
    Wrap                    = coroutine.wrap,
    Yield                   = coroutine.yield,
    Create                  = coroutine.create,
    Isyieldable             = coroutine.isyieldable,

    -- Task Menu
    Delay                   = task.delay,
    Wait                    = task.wait,
    Spawn                   = task.spawn,
    Defer                   = task.defer,
    Sleep                   = task.sleep,

    -- Color Menu
    RGB                     = Color3.fromRGB,
    Hex                     = Color3.fromHex,
    HSV                     = Color3.fromHSV,
    New                     = Color3.new,

    -- Position Spaces
    Vector2new              = Vector2.new,
    Vector3new              = Vector3.new,
    CFramenew               = CFrame.new,
    CFrameAngles            = CFrame.Angles,
    Vector2zero             = Vector2.zero,
    Vector3zero             = Vector3.zero,
    UDim2new                = UDim2.new,
    UDimnew                 = UDim.new,
    UDim2offset             = UDim2.fromOffset,

    -- Locals Library
    Locals                  = {
        ProjectDelta = {
            Knives = {
                AnarchyTomahawk = {
                    weaponOffSet = CFrame.new(-0.15, -1.51, 0.2),
                    sprintOffSet = Vector3.new(0, 0, -0.4),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://10905772228",
                            Idle = "rbxassetid://10905775438",
                            Use = "rbxassetid://10905779171",
                            UseAlt = "rbxassetid://10905777783",
                            Stab = "rbxassetid://10905780539",
                            Inspect = "rbxassetid://10905776735"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://10989619410",
                            Idle = "rbxassetid://10989624543",
                            Use = "rbxassetid://10989646536",
                            UseAlt = "rbxassetid://10989640707",
                            Stab = "rbxassetid://10989574087",
                            Inspect = "rbxassetid://10989633266"
                        }
                    },
                },
                DV2 = {
                    weaponOffSet = CFrame.new(0.05, -1.3, 1),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://8982799578",
                            Idle = "rbxassetid://7963518001",
                            Use = "rbxassetid://7963516952",
                            UseAlt = "rbxassetid://7963600020",
                            Stab = "rbxassetid://7963980103",
                            Inspect = "rbxassetid://7963613236"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861"
                        }
                    },
                },
                GoldenDV2 = {
                    weaponOffSet = CFrame.new(0.05, -1.3, 1),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://8982799578",
                            Idle = "rbxassetid://7963518001",
                            Use = "rbxassetid://7963516952",
                            UseAlt = "rbxassetid://7963600020",
                            Stab = "rbxassetid://7963980103",
                            Inspect = "rbxassetid://7963613236"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861"
                        }
                    },
                },
                IceAxe = {
                    weaponOffSet = CFrame.new(-0.15, -1.51, 0.2),
                    sprintOffSet = Vector3.new(0, 0, -0.4),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://10905772228",
                            Idle = "rbxassetid://10905775438",
                            Use = "rbxassetid://10905779171",
                            UseAlt = "rbxassetid://10905777783",
                            Stab = "rbxassetid://10905780539",
                            Inspect = "rbxassetid://10905776735"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://10989619410",
                            Idle = "rbxassetid://10989624543",
                            Use = "rbxassetid://10989646536",
                            UseAlt = "rbxassetid://10989640707",
                            Stab = "rbxassetid://10989574087",
                            Inspect = "rbxassetid://10989633266"
                        }
                    },
                },
                PlasmaNinjato = {
                    weaponOffSet = CFrame.new(0.1, -1.4, 0.1),
                    sprintOffSet = Vector3.new(1, -1, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://9602813265",
                            Idle = "rbxassetid://9602814995",
                            Use = "rbxassetid://9602882117",
                            UseAlt = "rbxassetid://9602837643",
                            Stab = "rbxassetid://9602895599",
                            Inspect = "rbxassetid://9602906201"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://11305769153",
                            Idle = "rbxassetid://11305800944",
                            Sprint = "rbxassetid://11305866272",
                            Use = "rbxassetid://11305837531",
                            UseAlt = "rbxassetid://11305821864",
                            Stab = "rbxassetid://11305793672",
                            Inspect = "rbxassetid://8219716861"
                        }
                    },
                },
                IceDagger = {
                    weaponOffSet = CFrame.new(0.05, -1.3, 1),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://8982799578",
                            Idle = "rbxassetid://7963518001",
                            Use = "rbxassetid://7963516952",
                            UseAlt = "rbxassetid://7963600020",
                            Stab = "rbxassetid://7963980103",
                            Inspect = "rbxassetid://7963613236"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861"
                        }
                    },
                },
                Karambit = {
                    weaponOffSet = CFrame.new(0, -1.4500000476837158, 0.44999998807907104),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://13660199419",
                            Idle = "rbxassetid://13660201544",
                            Use = "rbxassetid://13660212475",
                            UseAlt = "rbxassetid://13660218031",
                            Stab = "rbxassetid://13660208464",
                            Inspect = "rbxassetid://13660189579"
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861"
                        }
                    },
                },
                M9Fade = {
                    weaponOffSet = CFrame.new(0.05, -1.3, 1),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://8982799578",
                            Idle = "rbxassetid://7963518001",
                            Use = "rbxassetid://7963516952",
                            UseAlt = "rbxassetid://7963600020",
                            Stab = "rbxassetid://7963980103",
                            Inspect = "rbxassetid://7963613236",
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861",
                        },
                    },
                },
                Longsword = {
                    weaponOffSet = CFrame.new(0.05, -1.3, 1),
                    sprintOffSet = Vector3.new(0, 0, 1),
                    AimInSpeed = 0.4,
                    AimOutSpeed = 0.4,
                    swayMult = 1,
                    useDof = true,
                    allowAiming = false,
                    useModuleName = "MeleeWeaponDefault",
                    WeldHand = "UpperTorso",
                    FireMode = "Melee",
                    Scope = nil,
                    EquipTValue = 0,
                    AimWhileActing = true,
                    MaximumKickBack = 1,
                    MaxRecoil = 4,
                    ReductionStartTime = 15,
                    RecoilReductionMax = 1,
                    RecoilTValueMax = 5,
                    IdleSwayModifier = 8,
                    WalkSwayModifer = 1,
                    SprintSwayModifer = 1,
                    ItemLength = 3.1,
                    TouchWallPosY = -2.8,
                    TouchWallPosZ = 2,
                    TouchWallRotX = 40,
                    TouchWallRotY = -9,
                    FireModes = { "Melee" },
                    Animations = {
                        FirstPerson = {
                            Equip = "rbxassetid://8982799578",
                            Idle = "rbxassetid://7963518001",
                            Use = "rbxassetid://7963516952",
                            UseAlt = "rbxassetid://7963600020",
                            Stab = "rbxassetid://7963980103",
                            Inspect = "rbxassetid://7963613236",
                        },
                        ThirdPerson = {
                            Equip = "rbxassetid://8384325184",
                            Idle = "rbxassetid://8219701028",
                            Use = "rbxassetid://8219689820",
                            UseAlt = "rbxassetid://8219699063",
                            Stab = "rbxassetid://8219745355",
                            Inspect = "rbxassetid://8219716861",
                        },
                    },
                },
                Greatsword = {
                    ['TouchWallRotY'] = -9,
                    ['Animations'] = {
                        ['ThirdPerson'] = {
                            ['Idle'] = 'rbxassetid://8219701028',
                            ['Stab'] = 'rbxassetid://14376493027',
                            ['Equip'] = 'rbxassetid://14376499349',
                            ['Inspect'] = 'rbxassetid://8219716861',
                            ['UseAlt'] = 'rbxassetid://8219699063',
                            ['Use'] = 'rbxassetid://8219689820'
                        },
                        ['FirstPerson'] = {
                            ['Idle'] = 'rbxassetid://7963518001',
                            ['Stab'] = 'rbxassetid://14326935050',
                            ['Equip'] = 'rbxassetid://14326929299',
                            ['Inspect'] = 'rbxassetid://7963613236',
                            ['UseAlt'] = 'rbxassetid://7963600020',
                            ['Use'] = 'rbxassetid://7963516952'
                        },
                    },
                    ['WeldHand'] = 'UpperTorso',
                    ['MaximumKickBack'] = 1,
                    ['ReductionStartTime'] = 15,
                    ['TouchWallPosY'] = -2.8,
                    ['AimWhileActing'] = true,
                    ['TouchWallRotX'] = 40,
                    ['FireModes'] = { [1] = 'Melee' },
                    ['AimOutSpeed'] = 0.4,
                    ['ItemLength'] = 3.1,
                    ['WalkSwayModifer'] = 1,
                    ['useDof'] = true,
                    ['AimInSpeed'] = 0.4,
                    ['EquipTValue'] = 0,
                    ['IdleSwayModifier'] = 8,
                    ['FireMode'] = 'Melee',
                    ['allowAiming'] = false,
                    ['MaxRecoil'] = 4,
                    ['TouchWallPosZ'] = 2,
                    ['useModuleName'] = 'MeleeWeaponDefault',
                    ['RecoilReductionMax'] = 1,
                    sprintOffSet = Vector3.new(0, 0, 1),
                    weaponOffSet = CFrame.new(0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    --['weaponOffSet'] = '0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1',
                    ['swayMult'] = 1,
                    ['RecoilTValueMax'] = 5,
                    ['SprintSwayModifer'] = 1
                },
                Cutlass = {
                    ['TouchWallRotY'] = -9,
                    ['Animations'] = {
                        ['ThirdPerson'] = {
                            ['Idle'] = 'rbxassetid://8219701028',
                            ['Stab'] = 'rbxassetid://14376493027',
                            ['Equip'] = 'rbxassetid://14376499349',
                            ['Inspect'] = 'rbxassetid://8219716861',
                            ['UseAlt'] = 'rbxassetid://8219699063',
                            ['Use'] = 'rbxassetid://8219689820'
                        },
                        ['FirstPerson'] = {
                            ['Idle'] = 'rbxassetid://7963518001',
                            ['Stab'] = 'rbxassetid://14326935050',
                            ['Equip'] = 'rbxassetid://14326929299',
                            ['Inspect'] = 'rbxassetid://7963613236',
                            ['UseAlt'] = 'rbxassetid://7963600020',
                            ['Use'] = 'rbxassetid://7963516952'
                        },
                    },
                    ['WeldHand'] = 'UpperTorso',
                    ['MaximumKickBack'] = 1,
                    ['ReductionStartTime'] = 15,
                    ['TouchWallPosY'] = -2.8,
                    ['AimWhileActing'] = true,
                    ['TouchWallRotX'] = 40,
                    ['FireModes'] = { [1] = 'Melee' },
                    ['AimOutSpeed'] = 0.4,
                    ['ItemLength'] = 3.1,
                    ['WalkSwayModifer'] = 1,
                    ['useDof'] = true,
                    ['AimInSpeed'] = 0.4,
                    ['EquipTValue'] = 0,
                    ['IdleSwayModifier'] = 8,
                    ['FireMode'] = 'Melee',
                    ['allowAiming'] = false,
                    ['MaxRecoil'] = 4,
                    ['TouchWallPosZ'] = 2,
                    ['useModuleName'] = 'MeleeWeaponDefault',
                    ['RecoilReductionMax'] = 1,
                    sprintOffSet = Vector3.new(0, 0, 1),
                    weaponOffSet = CFrame.new(0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    --['weaponOffSet'] = '0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1',
                    ['swayMult'] = 1,
                    ['RecoilTValueMax'] = 5,
                    ['SprintSwayModifer'] = 1
                },
                Kukri = {
                    ['TouchWallRotY'] = -9,
                    ['Animations'] = {
                        ['ThirdPerson'] = {
                            ['Idle'] = 'rbxassetid://8219701028',
                            ['Stab'] = 'rbxassetid://14376493027',
                            ['Equip'] = 'rbxassetid://14376499349',
                            ['Inspect'] = 'rbxassetid://8219716861',
                            ['UseAlt'] = 'rbxassetid://8219699063',
                            ['Use'] = 'rbxassetid://8219689820'
                        },
                        ['FirstPerson'] = {
                            ['Idle'] = 'rbxassetid://7963518001',
                            ['Stab'] = 'rbxassetid://14326935050',
                            ['Equip'] = 'rbxassetid://14326929299',
                            ['Inspect'] = 'rbxassetid://7963613236',
                            ['UseAlt'] = 'rbxassetid://7963600020',
                            ['Use'] = 'rbxassetid://7963516952'
                        },
                    },
                    ['WeldHand'] = 'UpperTorso',
                    ['MaximumKickBack'] = 1,
                    ['ReductionStartTime'] = 15,
                    ['TouchWallPosY'] = -2.8,
                    ['AimWhileActing'] = true,
                    ['TouchWallRotX'] = 40,
                    ['FireModes'] = { [1] = 'Melee' },
                    ['AimOutSpeed'] = 0.4,
                    ['ItemLength'] = 3.1,
                    ['WalkSwayModifer'] = 1,
                    ['useDof'] = true,
                    ['AimInSpeed'] = 0.4,
                    ['EquipTValue'] = 0,
                    ['IdleSwayModifier'] = 8,
                    ['FireMode'] = 'Melee',
                    ['allowAiming'] = false,
                    ['MaxRecoil'] = 4,
                    ['TouchWallPosZ'] = 2,
                    ['useModuleName'] = 'MeleeWeaponDefault',
                    ['RecoilReductionMax'] = 1,
                    sprintOffSet = Vector3.new(0, 0, 1),
                    weaponOffSet = CFrame.new(0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    --['weaponOffSet'] = '0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1',
                    ['swayMult'] = 1,
                    ['RecoilTValueMax'] = 5,
                    ['SprintSwayModifer'] = 1
                },
                Scythe = {
                    ['TouchWallRotY'] = -9,
                    ['Animations'] = {
                        ['ThirdPerson'] = {
                            ['Idle'] = 'rbxassetid://8219701028',
                            ['Stab'] = 'rbxassetid://14376493027',
                            ['Equip'] = 'rbxassetid://14376499349',
                            ['Inspect'] = 'rbxassetid://8219716861',
                            ['UseAlt'] = 'rbxassetid://8219699063',
                            ['Use'] = 'rbxassetid://8219689820'
                        },
                        ['FirstPerson'] = {
                            ['Idle'] = 'rbxassetid://108826235918261',
                            ['Stab'] = 'rbxassetid://102473178386306',
                            ['Equip'] = 'rbxassetid://71883306304472',
                            ['Inspect'] = 'rbxassetid://136564315157406',
                            ['UseAlt'] = 'rbxassetid://85381554988687',
                            ['Use'] = 'rbxassetid://134759007970462'
                        },
                    },
                    ['WeldHand'] = 'UpperTorso',
                    ['MaximumKickBack'] = 1,
                    ['ReductionStartTime'] = 15,
                    ['TouchWallPosY'] = -2.8,
                    ['AimWhileActing'] = true,
                    ['TouchWallRotX'] = 40,
                    ['FireModes'] = { [1] = 'Melee' },
                    ['AimOutSpeed'] = 0.4,
                    ['ItemLength'] = 3.1,
                    ['WalkSwayModifer'] = 1,
                    ['useDof'] = true,
                    ['AimInSpeed'] = 0.4,
                    ['EquipTValue'] = 0,
                    ['IdleSwayModifier'] = 8,
                    ['FireMode'] = 'Melee',
                    ['allowAiming'] = false,
                    ['MaxRecoil'] = 4,
                    ['TouchWallPosZ'] = 2,
                    ['useModuleName'] = 'MeleeWeaponDefault',
                    ['RecoilReductionMax'] = 1,
                    sprintOffSet = Vector3.new(0, 0, 1),
                    weaponOffSet = CFrame.new(0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
                    --['weaponOffSet'] = '0.0500000007, -1.29999995, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1',
                    ['swayMult'] = 1,
                    ['RecoilTValueMax'] = 5,
                    ['SprintSwayModifer'] = 1
                },
            },
        },
        Fallen = {},
        Visuals = {
            Skyboxes = {
                ["Pink Daylight"] = {
                    SkyboxBk = "rbxassetid://600830446",
                    SkyboxDn = "rbxassetid://600831635",
                    SkyboxFt = "rbxassetid://600832720",
                    SkyboxLf = "rbxassetid://600886090",
                    SkyboxRt = "rbxassetid://600833862",
                    SkyboxUp = "rbxassetid://600835177",
                },
                ["Purple Night"] = {
                    SkyboxBk = "http://www.roblox.com/asset/?id=433274085",
                    SkyboxDn = "http://www.roblox.com/asset/?id=433274194",
                    SkyboxFt = "http://www.roblox.com/asset/?id=433274131",
                    SkyboxLf = "http://www.roblox.com/asset/?id=433274370",
                    SkyboxRt = "http://www.roblox.com/asset/?id=433274429",
                    SkyboxUp = "http://www.roblox.com/asset/?id=433274285",
                },
                ["Galaxy"] = {
                    SkyboxBk = "rbxassetid://159454299",
                    SkyboxDn = "rbxassetid://159454296",
                    SkyboxFt = "rbxassetid://159454293",
                    SkyboxLf = "rbxassetid://159454286",
                    SkyboxRt = "rbxassetid://159454300",
                    SkyboxUp = "rbxassetid://159454288",
                },
                ["Better Night"] = {
                    SkyboxBk = "rbxassetid://271042516",
                    SkyboxDn = "rbxassetid://271077243",
                    SkyboxFt = "rbxassetid://271042556",
                    SkyboxLf = "rbxassetid://271042310",
                    SkyboxRt = "rbxassetid://271042467",
                    SkyboxUp = "rbxassetid://271077958",
                },
                ["Blue Nebula"] = {
                    SkyboxBk = "http://www.roblox.com/asset?id=159454299",
                    SkyboxDn = "http://www.roblox.com/asset?id=159454296",
                    SkyboxFt = "http://www.roblox.com/asset?id=159454293",
                    SkyboxLf = "http://www.roblox.com/asset?id=159454286",
                    SkyboxRt = "http://www.roblox.com/asset?id=159454300",
                    SkyboxUp = "http://www.roblox.com/asset?id=159454288",
                },
            },
        },
        -- Chatspam = tick(),
        Assets = {
            Textures = {
                ["Web"] = "rbxassetid://301464986",
                ["Swirl"] = "rbxassetid://8133639623",
                ["Checkers"] = "rbxassetid://5790215150",
                ["CandyCane"] = "rbxassetid://6853532738",
                ["Dots"] = "rbxassetid://5830615971",
                ["Scanning"] = "rbxassetid://5843010904",
                ["Bubbles"] = "rbxassetid://1461576423",
                ["Player FF Texture"] = "rbxassetid://4494641460",
                ["Shield Forcefield"] = "rbxassetid://361073795",
                ["Water"] = "rbxasset://textures/water/normal_21.dds",
                ["America"] = "rbxassetid://936775406",
                ["Rainbow"] = "rbxassetid://252684207",
                ["Akatsuki"] = "rbxassetid://10913193650",
                ["None"] = "",
            },
            Shaders = {
                ["Galaxy"] = "rbxassetid://13726625670",
                ["Universe"] = "rbxassetid://16666870788",
                ["Groovy"] = "rbxassetid://17672592862",
                ["Liquid"] = "rbxassetid://17253872107",
                ["Israel"] = "rbxassetid://964998527",
                ["Troll"] = "rbxassetid://17673708830",
                ["Russia"] = "rbxassetid://12257572118",
                ["Belarus"] = "rbxassetid://13567566609",
                ["Zelensky"] = "rbxassetid://14671159559",
            },
            ShaderAnimatedTextures = {},
        },
    },
};

local vectors = {
    Vector3.new(0.5, 0, 0),
    Vector3.new(-0.5, 0, 0),
    Vector3.new(0, 0, 0.5),
    Vector3.new(0, 0, -0.5),
    Vector3.new(0, 0.5, 0),
    Vector3.new(0, -0.5, 0),

    Vector3.new(0.5, 0.5, 0),
    Vector3.new(0.5, -0.5, 0),
    Vector3.new(-0.5, 0.5, 0),
    Vector3.new(-0.5, -0.5, 0),
    Vector3.new(0, 0.5, 0.5),
    Vector3.new(0, -0.5, 0.5),
    Vector3.new(0, 0.5, -0.5),
    Vector3.new(0, -0.5, -0.5),

    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
    Vector3.new(0, 1, 0),
    Vector3.new(0, -1, 0),
}
local GetScaledVectors = LPH_NO_VIRTUALIZE(function(distance)
    local out = table.create(#vectors)
    for i = 1, #vectors do
        out[i] = vectors[i] * distance
    end
    return out
end)

local IsPartVisible = LPH_NO_VIRTUALIZE(function(Part, Origin)
    if not Part then
        return false
    end

    local LocalChar = Client.Character
    if not LocalChar then
        local cm = _G.Deadline and _G.Deadline._CharacterMap
        LocalChar = cm and cm[Client]
    end
    local Head = LocalChar and (LocalChar:FindFirstChild("Head") or LocalChar:FindFirstChild("head"))
    if not Head then
        return false
    end

    Origin = Origin or Head.CFrame.Position
    local to = Part.CFrame.Position
    local dir = (to - Origin)
    local RayResult = workspace:Raycast(Origin, dir, Fallen.RaycastParams)
    if not RayResult then
        return true
    end
    local inst = RayResult.Instance
    return inst and inst:IsDescendantOf(Part.Parent) or false
end)

function Env.Fallen:Init(Dependencies)
    Dependencies                = Dependencies or {};

    local Fallen                = self;
    local Directory             = Dependencies.Directory;
    local Items                 = Dependencies.Items;
    local Client                = Dependencies.Client;
    local Cache                 = Dependencies.Cache;
    local Visuals               = Dependencies.Visuals;
    local VMs                   = Dependencies.VMs;
    local Library               = Dependencies.Library;
    local Flags                 = Dependencies.Flags;
    local PlayHitSound          = Dependencies.PlayHitSound;
    local RayModule             = Dependencies.RayModule;
    local ToolInfo              = Dependencies.ToolInfo;
    local Trees                 = Dependencies.Trees;
    local LPH_NO_VIRTUALIZE     = Dependencies.LPH_NO_VIRTUALIZE or function(Function)
        return Function
    end;

    Fallen.__index              = Fallen;
    Fallen.IconsCache           = {};
    Fallen.ArmorCache           = {};
    Fallen.StackFuncs           = {};
    Fallen.TouchCollisions      = {};
    Fallen.DamageParts          = {};
    Fallen.FireParts            = {};
    Fallen.XRayParts            = {};
    Fallen.NoclipParts          = {};
    Fallen.RoofNoclipState      = {
        Character = nil,
        CFrame = nil,
        Velocity = nil,
    };
    Fallen.AllowedBuildings     = {
        "Wall",
        "Half Wall",
        "Low Wall",
        "Doorway",
        "Window",
        "Foundation",
        "Floor",
        "Triangle Floor",
        "Wall Frame",
        "Floor Frame",
        "Triangle Floor Frame",
        "L-Shaped Stairs",
        "U-Shaped Stairs",
        "Foundation Steps",
        "Foundation",
        "Triangle Foundation",
    };
    Fallen.BGrade               = {
        ["Wood"] = 1,
        ["Stone"] = 2,
        ["Metal"] = 3,
        ["Steel"] = 4,
    };
    Fallen.MaxArmorResistance   = 105;
    Fallen.DrawnIconDirectory   = ((Directory and Directory.Icons) or "Niggahack/icons") .. "/Drawn";
    Fallen.AimPart              = nil;
    Fallen.BarrelPart           = nil;
    Fallen.BarrelCrosshairPoint = nil;
    Fallen.CrosshairRotation    = 0;
    Fallen.WorldState           = {
        RocketWalls = workspace:FindFirstChild("RocketFactoryPinkCardInvisWalls"),
        Viewmodel = nil,
        Weapon = nil,
        Attachments = nil,
        Barrel = nil,
    };
    Fallen.PenetrationState     = {
        Filters = {},
        Dirty = true,
    };
    Fallen.WeaponState          = {
        Character = nil,
        ViewmodelController = nil,
        EquippedWeapon = nil,
        EquippedSlot = nil,
        Speed = nil,
        NextRefreshAt = 0,
    };
    Fallen.GhostPeekState       = {
        Active = false,
        StartPos = nil,
        GroundPos = nil,
        Character = nil,
        Ring = nil,
        StartTick = tick(),
        SpinOffset = Env.Rad(Env.Random(0, 360)),
    };
    Fallen.ReloadState          = {
        NetworkPointer = nil,
        LastReloadAt = 0,
        LastController = nil,
        NextScanAt = 0,
    };
    Fallen.KillAuraState        = {
        Part = nil,
        Attachment = nil,
        Ring = nil,
        LastSwing = 0,
    };
    Fallen.FarmAuraState        = {
        Part = nil,
        Attachment = nil,
        Ring = nil,
        LastSwing = 0,
    };
    Fallen.AutoFarmState        = {
        Controls = nil,
        LastTarget = nil,
        LastTargetAt = 0,
        Active = false,
    };
    Fallen.DebugCameraState     = {
        Active = false,
        Character = nil,
        Root = nil,
        OriginalCFrame = nil,
        OriginalType = nil,
        OriginalSubject = nil,
    };
    Fallen.SkinState            = {
        SkinnableWeapons = {},
        SkinTypes = {},
        SkinLookup = {},
        FetchHook = nil,
    };
    Fallen.DrawnItemNames       = {
        ["Crossbow"] = true,
        ["Steel Axe"] = true,
        ["Small Medkit"] = true,
        ["Salvaged Pump Action"] = true,
        ["Salvaged AK47"] = true,
        ["Salvaged AK74u"] = true,
        ["Military Barrett"] = true,
        ["Wooden Spear"] = true,
        ["Salvaged P250"] = true,
        ["Salvaged M14"] = true,
        ["Military Grenade"] = true,
        ["Salvaged Python"] = true,
        ["Pumpkin Launcher"] = true,
        ["Bruno's M4A1"] = true,
        ["Salvaged Pipe Rifle"] = true,
        ["Salvaged RPG"] = true,
        ["Salvaged SMG"] = true,
        ["Nail Gun"] = true,
        ["Military USP"] = true,
        ["Salvaged Sniper"] = true,
        ["Military MP7"] = true,
        ["Steel Pickaxe"] = true,
        ["Military PKM"] = true,
        ["Mining Drill"] = true,
        ["Chainsaw"] = true,
        ["Wooden Bow"] = true,
        ["Stone Spear"] = true,
        ["Salvaged Break Action"] = true,
        ["Military M4A1"] = true,
        ["Salvaged Skorpion"] = true,
    };
    Fallen.OtherDrawnItemNames  = {
        ["Nail Gun"] = "Salvaged Nailgun",
        ["Salvaged Sniper Scope"] = "Salvaged Sniper",
    };

    local function GetIcon(Name)
        if type(Name) ~= "string" or Name == "" then
            return nil
        end;
        local AssetName = Fallen.OtherDrawnItemNames[Name] or Name;
        if not Fallen.DrawnItemNames[Name] and not Fallen.DrawnItemNames[AssetName] then
            return nil
        end;

        local CacheKey = "Drawn:" .. Name;
        if Fallen.IconsCache[CacheKey] ~= nil then
            return Fallen.IconsCache[CacheKey]
        end;

        if makefolder and not isfolder(Fallen.DrawnIconDirectory) then
            makefolder(Fallen.DrawnIconDirectory);
        end;

        local LocalPath = Fallen.DrawnIconDirectory .. "/" .. AssetName .. ".png";
        if isfile and isfile(LocalPath) and getcustomasset then
            local Asset = getcustomasset(LocalPath);
            Fallen.IconsCache[CacheKey] = Asset;
            return Asset
        end;

        if request and writefile and getcustomasset then
            local Url = ("https://raw.githubusercontent.com/Ethereal58/iridescent/refs/heads/main/%s.png"):format(
                AssetName:gsub(" ", "%%20"));
            local Ok, Response = pcall(request, {
                Url = Url,
                Method = "GET",
                Headers = {
                    ["content-type"] = "application/json",
                },
            });
            if Ok and type(Response) == "table" and Response.StatusCode == 200 and type(Response.Body) == "string" then
                writefile(LocalPath, Response.Body);
                local Asset = getcustomasset(LocalPath);
                Fallen.IconsCache[CacheKey] = Asset;
                return Asset
            end;
        end;

        Fallen.IconsCache[CacheKey] = false;
        return nil
    end;

    local function UsesDrawnIcon(Name)
        if type(Name) ~= "string" or Name == "" then
            return false
        end;

        local AssetName = Fallen.OtherDrawnItemNames[Name] or Name;
        return Fallen.DrawnItemNames[Name] == true or Fallen.DrawnItemNames[AssetName] == true
    end;

    local function ResolveArmorResistance(Name)
        if type(Name) ~= "string" then
            return false
        end;

        local ArmorId = Name:match("^Armor_(%d+)");
        if not ArmorId then
            return false
        end;

        ArmorId = tonumber(ArmorId);
        if Fallen.ArmorCache[ArmorId] ~= nil then
            return Fallen.ArmorCache[ArmorId]
        end;

        local Item = Items and Items[ArmorId];
        local ItemName = Item and Item.Name;
        if Item
            and Item.Type == "Armor"
            and type(Item.Resistances) == "table"
            and Item.MaxDurability
            and type(ItemName) == "string"
            and (
                ItemName:find("Chestplate")
                or ItemName:find("Leggings")
                or ItemName:find("Helmet")
                or ItemName:find("Hazmat")
            )
        then
            local Legs = Item.Resistances.Legs;
            local Chest = Item.Resistances.Chest;
            local Head = Item.Resistances.Head;
            local Resistance = 0;

            Resistance = Resistance + (Legs and Legs.Bullet) or 0;
            Resistance = Resistance + (Chest and Chest.Bullet) or 0;
            Resistance = Resistance + (Head and Head.Bullet) or 0;

            Fallen.ArmorCache[ArmorId] = Resistance;
            return Resistance
        end;

        Fallen.ArmorCache[ArmorId] = false;
        return false
    end;

    function Fallen:GetArmorResistance(Character)
        Character = Character or Client.Character;
        if not Character then
            return 0
        end;

        local Seen = {};
        local TotalResistance = 0;
        for _, Child in next, Character:GetChildren() do
            if not Seen[Child.Name] then
                local Resistance = ResolveArmorResistance(Child.Name);
                if Resistance then
                    Seen[Child.Name] = true;
                    TotalResistance = TotalResistance + Resistance;
                end;
            end;
        end;

        return TotalResistance
    end;

    function Fallen:IsReloading()
        local LocalCharacter = Client.Character;
        local ViewmodelController = LocalCharacter and LocalCharacter:FindFirstChild("ViewmodelController");
        if not ViewmodelController then
            return false
        end;
        if ViewmodelController:GetAttribute("Reloading") == true
            or ViewmodelController:GetAttribute("IsReloading") == true
        then
            return true
        end;
        return (tick() - (Fallen.ReloadState.LastReloadAt or 0)) <= 0.2
    end;

    function Fallen:ReloadGun()
        local ReloadState = self.ReloadState;
        if not ReloadState or type(ReloadState.NetworkPointer) ~= "function" then
            return false
        end;

        local LocalCharacter = Client.Character;
        local ViewmodelController = LocalCharacter and LocalCharacter:FindFirstChild("ViewmodelController");
        local InventoryController = LocalCharacter and LocalCharacter:FindFirstChild("InventoryController");
        if not (LocalCharacter and ViewmodelController and InventoryController and InventoryController:FindFirstChild("Fetch")) then
            return false
        end;

        local Success, InventoryData = pcall(function()
            return InventoryController.Fetch:Invoke();
        end);
        if not Success or type(InventoryData) ~= "table" or type(InventoryData.Toolbar) ~= "table" then
            return false
        end;

        local EquippedIndex = ViewmodelController:GetAttribute("Equipped");
        local EquippedSlot = EquippedIndex and InventoryData.Toolbar[EquippedIndex];
        if not EquippedSlot or EquippedSlot == 0 then
            return false
        end;

        local WeaponData = Items and Items[EquippedSlot.ID];
        local AmmoType = WeaponData and WeaponData.AmmoType;
        if type(AmmoType) ~= "string" or AmmoType == "" then
            return false
        end;

        local AmmoId = "None";
        for _, ContainerName in ipairs({ "Inventory", "Toolbar" }) do
            local Container = InventoryData[ContainerName];
            if type(Container) ~= "table" then
                for _, ItemData in next, Container do
                    if ItemData ~= 0 and type(ItemData) == "table" and (tonumber(ItemData.Amount) or 0) > 0 then
                        local Definition = Items and Items[ItemData.ID];
                        if Definition
                            and type(Definition.Type) == "string"
                            and Definition.Type:find("Ammo")
                            and Definition.AmmoType == AmmoType
                        then
                            AmmoId = ItemData.ID;
                            break
                        end;
                    end;
                end;
                if AmmoId ~= "None" then
                    break
                end;
            end;
        end;

        if AmmoId == "None" then
            return false
        end;

        ReloadState.LastReloadAt = tick();
        ReloadState.NetworkPointer(
            "Fire",
            "d\147e\001R\169#o\249,9\133\153`B4q^W\006",
            "\197s5m:\246\237\135\220Hr\235\001\239\214\\\209\212\219\219",
            workspace:GetServerTimeNow(),
            AmmoId
        );
        return true
    end;

    function Fallen:MeleeHit(AttackCFrame, HitInstance, WeaponName)
        local ReloadState = self.ReloadState;
        if not ReloadState or type(ReloadState.NetworkPointer) ~= "function" then
            return false
        end;
        if typeof(HitInstance) ~= "Instance" or type(WeaponName) ~= "string" then
            return false
        end;

        local ServerTime = workspace:GetServerTimeNow();
        local Seed = ServerTime * 10000;
        local RoundedSeed = Env.Round(Seed);
        local RandomCode1 = Random.new(RoundedSeed):NextInteger(1, 1000000000);
        local RandomCode2 = Random.new(RoundedSeed):NextInteger(1, 10000000000);
        local HitCharacter = HitInstance.Parent;
        if typeof(HitCharacter) ~= "Instance" then
            return false
        end;

        local Params = RaycastParams.new();
        Params.FilterType = Enum.RaycastFilterType.Include;
        Params.FilterDescendantsInstances = { HitCharacter };

        local AttackOrigin = AttackCFrame.Position;
        local RaycastResult = workspace:Raycast(AttackOrigin, HitInstance.Position - AttackOrigin, Params);
        if not RaycastResult then
            return false
        end;

        ReloadState.NetworkPointer(
            "Fire",
            "d\147e\001R\169#o\249,9\133\153`B4q^W\006",
            "#\250)\215\028\001U\143\237}\154\218\231Cl-\015H\001\147",
            ServerTime,
            WeaponName
        );

        Env.Wait();

        ReloadState.NetworkPointer(
            "Fire",
            "d\147e\001R\169#o\249,9\133\153`B4q^W\006",
            "\160\029\229\248\031\016pJ\140]\137-\250\171Z_\001\135\223#",
            RandomCode2,
            RandomCode1,
            RaycastResult.Material.Name,
            RaycastResult.Normal,
            HitInstance.CFrame:PointToObjectSpace(RaycastResult.Position),
            HitInstance,
            CFrame.new(AttackOrigin, HitInstance.Position),
            3
        );

        return true
    end;

    function Fallen:KAHits(Hit, Position)
        if typeof(Hit) ~= "Instance" then
            return
        end;

        if Flags["HitEffects"] and typeof(Position) == "Vector3" then
            Env.Spawn(function()
                local HitEffectColor = Flags["HitEffectsColor"];
                local EffectColor = (typeof(HitEffectColor) == "table" and HitEffectColor.Color) or HitEffectColor;
                if typeof(EffectColor) ~= "Color3" then
                    EffectColor = Library.Theme.Accent;
                end;
                if setthreadidentity then
                    setthreadidentity(8);
                end;
                Visuals:CreateHitEffect(
                    Cache.Workspace:FindFirstChild("NoCollision") or VMs or Cache.Workspace,
                    Flags["HitEffectType"] or "Sparks",
                    EffectColor,
                    Position,
                    tonumber(Flags["HitEffectLifetime"]) or 1,
                    tonumber(Flags["HitEffectSize"]) or 1
                );
                if setthreadidentity then
                    setthreadidentity(2);
                end;
            end);
        end;

        if Flags["HitNotifications"] then
            Env.Spawn(function()
                local HitCharacter = Hit:FindFirstAncestorOfClass("Model");
                local HitPlayer = HitCharacter and Cache.Players:GetPlayerFromCharacter(HitCharacter) or nil;
                local LocalCharacter = Client.Character;
                local LocalRoot = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart");
                local TargetName = HitPlayer and HitPlayer.Name
                    or (HitCharacter and (HitCharacter:GetAttribute("DisplayName") or HitCharacter.Name))
                    or "Unknown";
                local HitPartName = Hit.Name;
                local HitDistance = (LocalRoot and Hit:IsA("BasePart"))
                    and Env.Floor((((LocalRoot.Position - Hit.Position).Magnitude / 3) * 10) + 0.5) / 10
                    or nil;
                if HitPartName == "FaceHitBox" then
                    HitPartName = "Head";
                elseif HitPartName:sub(-6) == "HitBox" and #HitPartName > 6 then
                    HitPartName = HitPartName:sub(1, -7);
                end;
                if setthreadidentity then
                    setthreadidentity(8);
                end;
                Library:Notification(
                    HitDistance
                    and Env.Format("Hit %s (%s) [%.1fm]", TargetName, HitPartName, HitDistance)
                    or Env.Format("Hit %s (%s)", TargetName, HitPartName),
                    tonumber(Flags["HitNotificationLifetime"]) or 1,
                    Library.Theme.Accent
                );
                if setthreadidentity then
                    setthreadidentity(2);
                end;
            end);
        end;
        PlayHitSound();
    end;

    function Fallen:ExtraChams(player, color, transparency, lifetime, useSmoothPlastic)
        if (not player or not player.Character) then return; end;
        local character = player.Character;
        local partColor = color or Env.New(1, 1, 1);
        local alpha = (transparency ~= nil) and transparency or 0;
        local timeToLive = lifetime or 1.5;
        local material = useSmoothPlastic and Enum.Material.SmoothPlastic or Enum.Material.ForceField;
        for _, child in character:GetChildren() do
            local isRenderablePart =
                ((child:IsA('MeshPart') and child.Transparency ~= 1) or child.Name == 'Head')
            if (isRenderablePart and child:IsA('BasePart')) then
                local clone = Instance.new(child.ClassName);
                clone.CFrame = child.CFrame;
                clone.Size = (child.Name == 'Head') and Vector3.new(1.18, 1.18, 1.18) or child.Size;
                clone.Color = partColor;
                clone.Material = material;
                clone.CanCollide = false;
                clone.Anchored = true;
                clone.Transparency = alpha;
                clone.Name = "FakeLagCham"
                clone:SetAttribute("IgnoreChams", true)
                clone:SetAttribute("IgnorePreview", true)
                clone.Parent = character;
                if (hasProperty(clone, 'TextureID')) then
                    clone.TextureID = '';
                end;
                if (hasProperty(clone, 'UsePartColor')) then
                    clone.UsePartColor = true;
                end;
                if hasProperty(clone, 'Adornee') then
                    clone.Adornee = nil;
                end
                Cache.Debris:AddItem(clone, timeToLive);
                if (material == Enum.Material.ForceField) then
                    local tween = Cache.TweenService:Create(clone, TweenInfo.new(timeToLive), { Transparency = 1 });
                    tween:Play();
                end;
            end;
        end;
    end;

    function Fallen:Prediction()
        return 0
    end;

    local HitscanAngles = RayModule.HitscanAngles or {};

    function Fallen:RaycastRow(tbl)
        if type(tbl) ~= "table" then
            return
        end;
        for Index = 1, (#tbl - 3) do
            local A = tbl[Index];
            local B = tbl[Index + 1];
            local C = tbl[Index + 2];
            local D = tbl[Index + 3];
            if typeof(A) == "Instance"
                and A:IsA("BasePart")
                and typeof(B) == "Vector3"
                and typeof(C) == "Vector3"
                and typeof(D) == "EnumItem"
                and D.EnumType == Enum.Material
            then
                return Index, Index + 1, Index + 2, Index + 3, Index + 4
            end;
        end;
    end;

    function Fallen:GetHitscanVectors(Distance)
        local Output = table.create(#HitscanAngles);
        for Index = 1, #HitscanAngles do
            Output[Index] = HitscanAngles[Index] * Distance;
        end;
        return Output
    end;

    function Fallen:HitscanPos(originCF, targetPart)
        if typeof(originCF) == "Vector3" then
            originCF = CFrame.new(originCF);
        end;
        if typeof(originCF) ~= "CFrame" or not targetPart then
            return nil
        end;

        local ScanDistance = tonumber(Flags["AimAssistHitscanDistance"]) or 7.5;
        local ScanVectors = self:GetHitscanVectors(ScanDistance);
        for Index = 1, #ScanVectors do
            local SurfaceCF = targetPart.CFrame * CFrame.new(ScanVectors[Index]);
            local SurfaceVisible = self.CombatRay:IsPartVisible(SurfaceCF.Position, targetPart, targetPart.Parent);
            local OriginHit = self.CombatRay:Send(originCF.Position, SurfaceCF.Position);
            if SurfaceVisible and not OriginHit then
                return SurfaceCF.Position
            end;
        end;
        return nil
    end;

    local IsPartVisible = LPH_NO_VIRTUALIZE(function(Part, Origin)
        if not Part then
            return false
        end

        local LocalChar = Client.Character
        if not LocalChar then
            local cm = _G.Deadline and _G.Deadline._CharacterMap
            LocalChar = cm and cm[Client]
        end
        local Head = LocalChar and (LocalChar:FindFirstChild("Head") or LocalChar:FindFirstChild("head"))
        if not Head then
            return false
        end

        Origin = Origin or Head.CFrame.Position
        local to = Part.CFrame.Position
        local dir = (to - Origin)
        local RayResult = workspace:Raycast(Origin, dir, Fallen.RaycastParams)
        if not RayResult then
            return true
        end
        local inst = RayResult.Instance
        return inst and inst:IsDescendantOf(Part.Parent) or false
    end)

    Fallen.FindVisiblePosition = LPH_NO_VIRTUALIZE(function(self, originCF, targetPart)
        if not (originCF and targetPart) then
            return
        end

        if typeof(originCF) ~= "CFrame" then
            originCF = CFrame.new(originCF)
        end

        local basePos = originCF.Position
        local maxDist = Flags.AimAssistManipulationDistance or 6
        local doHitScan = Flags.AimAssistHitscan == true

        local scaledVectors = GetScaledVectors(maxDist)

        for i = 1, #scaledVectors do
            local pos = basePos + scaledVectors[i]

            if IsPartVisible(targetPart, pos) then
                return pos
            elseif doHitScan then
                local hs = Fallen:HitscanPos(CFrame.new(pos), targetPart)
                if hs then
                    return pos, hs
                end
            end
        end
        return
    end)

    function Fallen:GetItemImage(Item)
        local Name = type(Item) == "string" and Item
            or (type(Item) == "table" and Item.Name)
            or (typeof(Item) == "Instance" and Item.Name)
            or nil;
        if type(Name) ~= "string" or Name == "" then
            return false
        end;

        local DrawnIcon = GetIcon(Name);
        if DrawnIcon then
            return DrawnIcon
        elseif UsesDrawnIcon(Name) then
            return false
        elseif Fallen.IconsCache[Name] ~= nil then
            return Fallen.IconsCache[Name]
        end;

        for _, item in next, (Items or {}) do
            if item.Name == Name then
                local image
                if type(item.Image) == "table" then
                    image = item.Image.Default
                else
                    image = item.Image
                end;
                Fallen.IconsCache[Name] = image
                return image
            end;
        end;

        Fallen.IconsCache[Name] = false;
        return false
    end;

    function Fallen:GetFarmWeaponData()
        local WorldState = Fallen.WorldState or {};
        local Weapon = WorldState.Viewmodel
            or (Cache
                and Cache.Workspace
                and Cache.Workspace:FindFirstChild("VFX")
                and Cache.Workspace.VFX:FindFirstChild("VMs")
                and Cache.Workspace.VFX.VMs:FindFirstChildOfClass("Model"));
        local WeaponData = Weapon and ToolInfo and ToolInfo[Weapon.Name];
        if Weapon
            and WeaponData
            and rawget(WeaponData, "Weapon")
            and rawget(WeaponData, "Melee")
            and rawget(WeaponData.Weapon, "Cooldown")
        then
            return Weapon, WeaponData
        end;
        return nil, nil
    end;

    function Fallen:GetAutoFarmTarget(Root)
        local AutoFarmState = self.AutoFarmState;
        local TargetMode = Flags["AutoFarmTargets"];
        local NodesFolder = workspace:FindFirstChild("Nodes");

        if not (Root and NodesFolder and type(TargetMode) == "string" and TargetMode ~= "") then
            AutoFarmState.LastTarget = nil;
            return nil
        end;

        if ((time() - (AutoFarmState.LastTargetAt or 0)) >= 0.35)
            or (not AutoFarmState.LastTarget or not AutoFarmState.LastTarget:IsDescendantOf(workspace))
            or (TargetMode ~= AutoFarmState.LastTarget.Name:gsub("_Node$", ""))
        then
            local Best, BestDistance = nil, math.huge;
            for _, Node in next, NodesFolder:GetChildren() do
                if Node and Node:IsDescendantOf(workspace) and TargetMode == Node.Name:gsub("_Node$", "") then
                    local Main = Node:FindFirstChild("Main");
                    if Main then
                        local Distance = (Root.Position - Main.Position).Magnitude;
                        if Distance < BestDistance then
                            BestDistance = Distance;
                            Best = Node;
                        end;
                    end;
                end;
            end;
            AutoFarmState.LastTarget = Best;
            AutoFarmState.LastTargetAt = time();
        end;

        return AutoFarmState.LastTarget
    end;

    function Fallen:GetAuraFarmTarget(Radius, Root)
        if not (Root and Radius) then
            return nil
        end;

        local AutoFarmTarget, BestDistance = nil, Radius;
        for _, Folder in { workspace:FindFirstChild("Nodes"), Trees } do
            if Folder and Folder:IsA("Folder") then
                for _, Inst in Folder:GetChildren() do
                    if Inst:IsA("Model") then
                        local Target = Inst:FindFirstChild("NodeSpark") or Inst:FindFirstChild("TreeX") or Inst;
                        local Part = (Target:IsA("Model") and (Target.PrimaryPart or Target:FindFirstChild("Main")))
                            or (Target:IsA("BasePart") and Target)
                            or nil;
                        if Part then
                            local Distance = (Part.Position - Root.Position).Magnitude;
                            if Distance < BestDistance then
                                BestDistance = Distance;
                                AutoFarmTarget = Part;
                            end;
                        end;
                    end;
                end;
            end;
        end;

        return AutoFarmTarget
    end;

    return Fallen;
end;

Env.Deadline = {
    FindVisiblePosition = LPH_NO_VIRTUALIZE(function(self, originCF, targetPart)
        if not (originCF and targetPart) then
            return
        end

        if typeof(originCF) ~= "CFrame" then
            originCF = CFrame.new(originCF)
        end

        local basePos = originCF.Position
        local maxDist = Flags.AimAssistManipulationDistance or 6
        local doHitScan = Flags.AimAssistHitscan == true

        local scaledVectors = GetScaledVectors(maxDist)

        for i = 1, #scaledVectors do
            local pos = basePos + scaledVectors[i]

            if IsPartVisible(targetPart, pos) then
                return pos
            elseif doHitScan then
                local hs = Fallen:HitscanPos(CFrame.new(pos), targetPart)
                if hs then
                    return pos, hs
                end
            end
        end
        return
    end),
    HitscanPos = LPH_NO_VIRTUALIZE(function(self, originCF, targetPart)
        if typeof(originCF) == "Vector3" then
            originCF = CFrame.new(originCF);
        end;
        if typeof(originCF) ~= "CFrame" or not targetPart then
            return nil
        end;

        local ScanDistance = tonumber(Flags["AimAssistHitscanDistance"]) or 7.5;
        local ScanVectors = self:GetHitscanVectors(ScanDistance);
        for Index = 1, #ScanVectors do
            local SurfaceCF = targetPart.CFrame * CFrame.new(ScanVectors[Index]);
            local SurfaceVisible = self.CombatRay:IsPartVisible(SurfaceCF.Position, targetPart, targetPart.Parent);
            local OriginHit = self.CombatRay:Send(originCF.Position, SurfaceCF.Position);
            if SurfaceVisible and not OriginHit then
                return SurfaceCF.Position
            end;
        end;
        return nil
    end);
} 

_G.Env = Env;
return Env;
