--imports
local unicode = require('unicode')
local event = require('event')
local term = require('term')
local fs = require('filesystem')
local component = require("component")
local keyboard =  require("keyboard")

local const={}--Constants, NEVER UNDER ANY CIRCUMSTANCES WRITE NEW VALUES TO THINGS DEFINED HERE!!! (if u need to, move them out of that table)
do --resolution constants
    const.removeCode=-999

    const.resolutionMax={48,32,48}-- x,y,z max size
    
    const.resolutionMaxSize=73728 -- 48*48*32
    
    const.tDefaultPallete={}
    const.tDefaultPallete[1]=0x00ffff--C - cos i hate red
    const.tDefaultPallete[2]=0x00ff00--G
    const.tDefaultPallete[3]=0x0000ff--B
    const.tDefaultPallete.__index=const.tDefaultPallete
end

local meta={}--main meta table holding obj definitions (meta tables and meta methods)
do meta.machineArray={}     meta.machineArray.typeName="machineArray"
    function meta.machineArray:new()
        local o={}
        setmetatable(o,self)
        self.__index=self
        self["machines"]={}
        return o
    end
    
    function meta.machineArray:add(mMachine)
        for k,v in ipairs(self.machines) do
            if v.pos==mMachine.pos then
                return false
            end
        end
        table.insert(self.machines,mMachine)--yeah put the machine there
        return true
    end
    
    function meta.machineArray:del(mMachine)
        for i=#self.machines,1,-1 do
            if self.machines[i].pos==mMachine.pos then
                --table.remove(self.machines,i)
                self.machines[i].state=const.removeCode
                return true
            end
        end
        return false
    end
    
    function meta.machineArray:update(mFrame)
        for i=#self.machines,1,-1 do
            if self.machines[i].state==const.removeCode then
                mFrame:set(self.machines[i].position,mFrame.default)
                table.remove(self.machines,i)
            else
                mFrame:set(self.machines[i].position,self.machines[i].state)
            end
        end
    end
end  
do meta.machine={}          meta.machine.typeName="machine"
    function meta.machine:new(position,state)
        local o={--using o like u know object
            ["pos"]=position,
            ["state"]=state}
        setmetatable(o,self)
        self.__index=self
        --self["check"]={}
        return o
    end
    
    function meta.machine:newFromXYZ(x,y,z,state)
        return this:new(func:xyzToPosition(x,y,z),state)
    end
    
    function meta.machine:set(mState)
        self.state=mState
    end
end
do meta.frame={}            meta.frame.typeName="frame"
    function meta.frame:new(mDefault)--default should be 0 - 3
        local o={
            ["default"]=mDefault or 0}
        setmetatable(o,self)
        self.__index=self
        self["voxels"]={}
        self["Palette"]={}
        
        local tDefault={}--seting default value metatable
        tDefault.__index=function() return self.default end
        setmetatable(self.voxels,tDefault)
        
        setmetatable(self.Palette,const.tDefaultPallete)--no custom default palletes
        return o
    end 
    
    function meta.frame:setPosition(index,mState)--states are normal numbers
        if mState~=self.default then
            self.voxels[index]=mState
            return true
        else
            if self.voxels[index] then
                table.remove(self.voxels,index)
                return true
            end
            return false 
        end
    end
    
    function meta.frame:set(x,y,z,mState)--states are normal numbers
        return self:setPosition(func:xyzToPosition(x,y,z),mState)
    end
    
    function meta.frame:setPalette(tPallete)
        self.Palette=func:iDup(tPallete)
        return self.Palette
    end
    
    function meta.frame:sendPallete(cHolo)
        return cHolo.setPaletteColor(1,self.Palette[1]),
               cHolo.setPaletteColor(2,self.Palette[2]),
               cHolo.setPaletteColor(3,self.Palette[3])
    end
    
    function meta.frame:sendVoxels(cHolo)
        return cHolo.setRaw(self:toString())
    end
    
    function meta.frame:toString()
        local str
        local char=string.char
        for i=1,const.resolutionMaxSize do
            str=str..char(self.voxels[i])
        end
        return str
    end
    
    function meta.frame:setFromString(str)
        self.voxels=func:tClean(self.voxels)--if table has metatable must be constructed like so, it forwards metatable to the object/table
        for i=1,#str do
            if str:byte(i)~=self.default then ---48 changes string byte to number if it is a single digit 
                self.voxels[i]=str:byte(i)
            end
        end
        return self.voxels
    end
    
    function meta.frame:toCompact()
        local char=string.char
        local str=char(self.default)..
                  func:formatColor(self.Palette[1])..
                  func:formatColor(self.Palette[2])..
                  func:formatColor(self.Palette[3])
        for i=1,const.resolutionMaxSize,4 do
            str=str..char(
                self.voxels[i]*64+
                self.voxels[i+1]*16+
                self.voxels[i+2]*4+
                self.voxels[i+3])
        end
        return str
    end
    
    function meta.frame:setFromCompact(str)
        self.default=str:byte(1)
        local tDefault={}--seting default value metatable
        tDefault.__index=function() return self.default end
        setmetatable(self.voxels,tDefault)
        
        self.Palette[1]=func:readColor(str,2)
        self.Palette[2]=func:readColor(str,5)
        self.Palette[3]=func:readColor(str,8)
        
        self.voxels=func:tClean(self.voxels)
        local band=bit32.band
        local rshift=bit32.rshift
        local insert=table.insert
        local b
        for i=11,#str do
            insert(self.voxels,rshift(band(colorNumber,0xC0),6))
            insert(self.voxels,rshift(band(colorNumber,0x30),4))
            insert(self.voxels,rshift(band(colorNumber,0x0C),2))
            insert(self.voxels,band(colorNumber,0x03))
        end
        return self.voxels
    end
end

local func={}--functions
do --table test/duplication
    function func:isTable(tab)
        return type(tab)=="table"
    end

    function func:iDup(tab)--iterable TABLE DUPLICATOR
        local t={}
        for k,v in ipairs(tab) do
            t[k]=v
        end
        return t
    end
    
    function func:pDup(tab)--non-iterable TABLE DUPLICATOR
        local t={}
        for k,v in pairs(tab) do
            t[k]=v
        end
        return t
    end
    
    function func:oDup(object)--used to duplicate objects
        local obj=setmetatable({},getmetatable(object))--reuse metatables
        for k,v in pairs(object) do
            if func:isTable(v) then
                obj[k]=func:oDup(v)--function is dumb will halt the process on looped table
            else
                obj[k]=v
            end
        end
        return obj--reference to new table
    end
    
    function func:tClean(tab)--cleans the table keeping metatable
        return setmetatable({},getmetatable(tab))--cheeky scrubness, result shuld be put into the variable
    end
end
do --instanceof and obj helper functions 
    function func:instanceOf(tab,mTab)--checks if the object (tab) is instance of the thing
        return getmetatable(tab)==mTab
        --func:instanceOf(someMachine,meta.machine) should give true
    end
    
    function func:getTypeName(tab)--gets obj type name
        return getmetatable(tab).typeName
    end
    
    function func:getObjTypeFromName(str)
        for k,v in pairs(meta) do
            if v.typeName==str then 
                return v
            end
        end
    end
end
do --translations of coordinates
    --x ,y ,z starts from 0
    --positions start from 1

    function func:xyzToPosition(x,y,z)
        return 1+x+48*y+1536*z -- y is shifted by xMax, z is shifted by (xMax)*(yMax)
    end
    
    function func:positionToXYZ(pos)
        pos=pos-1
        local Z=math.floor(pos/1536)-- full multiples of 1536 OK
        local X=math.fmod(pos,48)-- 0-47 modulus gets the beggining OK
        return X,math.floor((pos-Z*1536)/48),Z --calculate Y as the remaining thing
    end
end
do --other util funtions (single functions without groups)
    function func:cyclicRandom(actual,minimum,maximum)--a random function for generating integer in range but different from previous one
        if minimum>maximum then minimum,maximum=maximum,minimum end
        local range=maximum-minimum
        local randomNumber=actual+math.random(1,range-1)
        if randomNumber>maximum then randomNumber=randomNumber-range end
        return randomNumber
    end
end
do --color formating
    function func:formatColor(colorNumber)--no alpha
        local band=bit32.band
        local rshift=bit32.rshift
        local char=string.char
        local r=rshift(band(colorNumber,0xFF0000),16)
        local g=rshift(band(colorNumber,0x00FF00),8)
        local b=band(colorNumber,0x0000FF)
        return char(r)..char(g)..char(b)
    end
    
    function func:readColor(str,startPos)
        return str:byte(startPos)*65536+
               str:byte(startPos+1)*256+
               str:byte(startPos+2)
    end
end
setmetatable(func,func)
func.__index=func

--VARIABLES
local holo = component.hologram

local colours = {--Layer 1 Norm, Fail, Crit Layer 2 Primary, Secondary, Highlight
    {0x090c9b,0x3d52d5,0x3d52d5},
    {0x0b5563,0x58a4b0,0x2de1fc}, 
    {0xff8811,0xf4d06f,0xefc700}} 
    
local rPallet = 1

--Objects
local machineArray1=meta.machineArray:new()
local frame1=meta.frame:new(0)

--do once

holo.clear()
holo.setScale(.3)


while true do--main loop
    rPallet=func:cyclicRandom(rPallet,1,3)
    
    frame1:setPalette(colours[rPallet])
    frame1:sendPallete(holo)

    --Define 3D frame
    local newmachine1=meta.machine:new(math.random(0,47),math.random(0,31),math.random(0,47),math.random(1,3))--creating new machine
    machineArray1:add(newmachine1)--adding to machine array
    machineArray1:update(frame1)--updating frame content
    frame1:sendVoxels(holo)--
    
    os.sleep(5)
end