--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {A,B,C} Layer 3 {Red 0-255, Green 0-255, Blue 0-255,}

local colours = {
    {{0,0,255},{0,0,255},{0,0,255}},
    {{0,0,255},{0,0,255},{0,0,255}}, 
    {{0,0,255},{0,0,255},{0,0,255}}} 

function EZCONCAT(tab)
    local txt--=""
    for i=1,xMax do
        for j=1,yMax do
            for k=1,zMax do
                txt..tab[i][j][k]
    end end end
    return txt
end

--Load Basics

local component = require("component")
local keyboard =  require("keyboard")
local holo = component.hologram
holo.clear()
--Define 3D frame

local frame, mFrame = {{{"/0"}}}, {}
local mFrame.__index=function() return "\0" end
setmetatable(frame,mFrame)




holo.setRaw(EZCONCAT(frame))
