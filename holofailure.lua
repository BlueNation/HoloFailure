--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {A,B,C} Layer 3 {Red 0-255, Green 0-255, Blue 0-255,}

local colours = {--HSV 30deg shifr iirc
    {{  0,  0, 64},{  0,  0,128},{  0,  0,255}},
    {{  0, 16, 64},{  0, 32,128},{  0, 64,255}}, 
    {{  0, 32, 64},{  0, 64,128},{  0,128,255}}} 

function EZCONCAT(tab)
    local txt=""
    for i=1,48 do
        for j=1,32 do
            for k=1,48 do
                txt=txt..tab[i][j][k]
    end end end
    return txt
end

--Load Basics

local component = require("component")
local keyboard =  require("keyboard")
local holo = component.hologram
holo.clear()
--Define 3D frame

local tFrame, mFrame = {}, {}
mFrame.__index=function() return tostring(math.random(0,3)) end--dont init the mFrame again... using the local keyword

for i = 1,48 do
    tFrame[i]={}
    for j = 1,32 do
        tFrame[i][j]={}
        setmetatable(tFrame[i][j],mFrame)
    end
end




holo.setRaw(EZCONCAT(tFrame))
