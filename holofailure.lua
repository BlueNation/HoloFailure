--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {hex,hex,hex}

local colours = {--HSV 30deg shifr iirc
    {0x000040,0x000080,0x0000ff},
    {0x001040,0x002080,0x0040ff}, 
    {0x002040,0x004080,0x0080ff}} 

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

local rPallet= 1

while true do

    rPallet=rPallet+math.random(1,#colours-1)--"cyclic range" randomness with the same object exclusion
    if rPallet>3 then rPallet=rPallet-#colours end

    for i=1,3 do
        holo.setPaletteColor(i, colours[rPallet][i])
    end

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
    os.sleep(5)
end