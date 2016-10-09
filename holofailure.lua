--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {hex,hex,hex}

local colours = {--HSV 30deg shifr iirc
    {0x000040,0x000080,0x0000ff},
    {0x0075a2,0x00cfc1,0x2af5ff}, 
    {0xe9ce2c,0xef8a17,0xc84c09}} 

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
    if rPallet>#colours then rPallet=rPallet-#colours end

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