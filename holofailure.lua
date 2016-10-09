--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {A,B,C} Layer 3 {Red 0-255, Green 0-255, Blue 0-255,}
local xMax,yMax,zMax=10,10,10--size goes here

local colours = {--HSV 30deg shifr iirc
	{{  0,  0, 64},{  0,  0,128},{  0,  0,255}},
	{{  0, 16, 64},{  0, 32,128},{  0, 64,255}}, 
	{{  0, 32, 64},{  0, 64,128},{  0,128,255}}} 

function EZMEMECONCAT(tab)
    local txt=""
    for i=1,xMax do
        for j=1,yMax do
            for k=1,zMax do
				pcall(function() txt=txt..tab[i][j][k] end)
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
mFrame.__index=function() return "\0" end--dont init the mFrame again... using the local keyword

for i = 1,48 do
	for j = 1,32 do
		setmetatable(tFrame[i][j],mFrame)
	end
end




holo.setRaw(EZCONCAT(tFrame))
