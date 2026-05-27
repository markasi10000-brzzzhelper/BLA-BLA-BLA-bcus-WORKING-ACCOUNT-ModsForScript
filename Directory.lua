--[[
    1/18/2026
    Directory.lua
    Purpose:
        Provide a one-stop area for setting up the directories for NiggaHack. Additional directories can be created easily here.

    Author: @.yxyv
    Dependencies:
        None
]]
local Directory = {};
local TableConcat = table.concat;

function Directory:Format(Name, ...)
    local Format = TableConcat({ ... }, "/");
    Directory[Name] = Format;
    return Format
end;

local function mkdir(Directory)
    if not isfolder(Directory) then
        makefolder(Directory);
    end;
end;

local Main = "Niggahack";
local Configs = Directory:Format("Configs", Main, "configs");
local Icons = Directory:Format("Icons", Main, "icons");
local Images = Directory:Format("Images", Main, "images");
local Cache = Directory:Format("Cache", Main, "cache");
local Fonts = Directory:Format("Fonts", Main, "fonts");
local Sound = Directory:Format("Sound", Main, "sound");
local MovementHelper = Directory:Format("MovementHelper", Main, "movementhelper");
local RecordedMovements = Directory:Format("RecordedMovements", MovementHelper, "RecordedMovements");

mkdir(Main);
mkdir(Configs);
mkdir(Icons);
mkdir(Images);
mkdir(Cache);
mkdir(Fonts);
mkdir(Sound);
mkdir(MovementHelper);
mkdir(RecordedMovements);

_G.Directory = Directory;
return Directory;
