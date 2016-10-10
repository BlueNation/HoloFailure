--imports
local unicode = require('unicode')
local event = require('event')
local term = require('term')
local fs = require('filesystem')
local component = require("component")
local keyboard =  require("keyboard")

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
            if      v.posX==mMachine.posX and --can align if similar
                    v.posY==mMachine.posY and --double indent when doing long conditionals plz
                    v.posZ==mMachine.posZ then
                return false
            end
        end
        self.machines[#self.machines+1]=mMachine--yeah put the machine there
        return true
    end
    
    function meta.machineArray:del(mMachine)
        for i=#self.machines,1,-1 do
            if      self.machines[i].posX==mMachine.posX and --can align if similar
                    self.machines[i].posY==mMachine.posY and --double indent when doing long conditionals plz
                    self.machines[i].posZ==mMachine.posZ then
                --table.remove(self.machines,i)
                self.machines[i]=-999
                return true
            end
        end
        return false
    end
    
    function meta.machineArray:update(mFrame)
        for i=#self.machines,1,-1 do
            if self.machines[i]==-999 then
                mFrame:set(self.machines[i].posX,self.machines[i].posY,
                           self.machines[i].posZ,self.mFrame.default)
                table.remove(self.machines,i)
            else
                mFrame:set(self.machines[i].posX,self.machines[i].posY,
                           self.machines[i].posZ,self.machines[i].state)
            end
        end
    end
end  
do meta.machine={}          meta.machine.typeName="machine"
    function meta.machine:new(x,y,z,state)
        local o={--using o like u know object
            ["posX"]=x,
            ["posY"]=y,
            ["posZ"]=z,
            ["state"]=state}
        setmetatable(o,self)
        self.__index=self
        return o
    end
    
    function meta.machine:set(mState)
        self.state=mState
    end
end
do meta.frame={}            meta.frame.typeName="frame"
    function meta.frame:new(mDefault)--default should be "\0" - "\3"
        local o={
            ["default"]=mDefault}
        setmetatable(o,self)
        self.__index=self
        self["voxels"]={}
        self["pallete"]={}
        
        local tDefault={}--seting default value metatable
        tDefault.__index=function() return mDefault end
        setmetatable(self.voxels,tDefault)
        
        setmetatable(self.pallete,const.tDefaultPallete)--no custom default palletes
        return o
    end 
    
    function meta.frame:set(x,y,z,mState)--states are normal numbers
        local index=func.xyzToPosition(x,y,z)
        if mState~=self.default then
            self.voxels[index]=tostring(mState)
            return true
        else
            if self.voxels[index] then
                table.remove(self.voxels,index)
                return true
            end
            return false 
        end
    end
    
    function meta.frame:setPalette(tPallete)
        return self.pallete=func.iDup(tPallete)
    end
    
    function meta.frame:sendPallete(cHolo)
        return cHolo.setPalleteColor(1,self.pallete[1]),
               cHolo.setPalleteColor(2,self.pallete[2]),
               cHolo.setPalleteColor(3,self.pallete[3])
    end
    
    function meta.frame:sendVoxels(cHolo)
        return cHolo.setRaw(self:toString())
    end
    
    function meta.frame:toString()
        local str=""
        for i=0,const.resolutionMaxSize do
            str=str..self.voxels[i]
        end
        return str
    end
    
    function meta.frame:setFromString(str)
        self.voxels=setmetatable({},getmetatable(self.voxels))--if table has metatable must be constructed like so, it forwards metatable back to the object/table
        for i=1,#str do
            if str:sub(i,i)~=self.default then
                self.voxels[i-1]=str:sub(i,i)
            end
        end
        return self.voxels
    end
end

local func={}--functions
do --table test/duplication
    function func.isTable(tab)
        return type(tab)=="table"
    end

    function func.iDup(tab)--iterable TABLE DUPLICATOR
        local t={}
        for k,v in ipairs(tab) do
            t[k]=v
        end
        return t
    end
    
    function func.pDup(tab)--non-iterable TABLE DUPLICATOR
        local t={}
        for k,v in pairs(tab) do
            t[k]=v
        end
        return t
    end
    
    function func.oDup(tab)--used to duplicate objects
        local t=setmetatable({},getmetatable(tab))--reuse metatables
        for k,v in pairs(tab) do
            if func.isTable(v) then
                t[k]=func.oDup(v)--function is dumb will halt the process on looped table
            else
                t[k]=v
            end
        end
    return t
    end
end
do --instance of functions 
    function func.instanceOf(tab,mTab)--checks if the object (tab) is instance of the thing
        return getmetatable(tab)==mTab
        --func.instanceOf(someMachine,meta.machine) should give true
    end
    
    function func.getTypeName(tab)--gets obj type name
        return getmetatable(tab).typeName
    end
    
    function func.getObjTypeFromName(str)
        for k,v in pairs(meta) do
            if v.typeName==str then 
                return v
            end
        end
    end
end
do --translations of coordinates
    --yes our coord system starts from 0 !!! so if u make a iteration over pixels do:
    --for i=0,const.resolutionMaxSize do
    function func.xyzToPosition(x,y,z)
        return x+48*y+1536*z -- y is shifted by xMax, z is shifted by (xMax)*(yMax)
    end
    
    function func.positionToXYZ(pos)--i am avoiding use of that
        local Z=math.floor(pos/1536)-- full multiples of 1536 OK
        local X=math.fmod(pos,48)-- 0-47 modulus gets the beggining OK
        return X,math.floor((pos-Z-X)/48),Z --calculate Y as the remaining thing
    end
end
do --other util funtions (single functions without groups)
    function func.cyclicRandom(actual,minimum,maximum)--a random function for generating integer in range but different from previous one
        if minimum>maximum then minimum,maximum=maximum,minimum end
        local range=maximum-minimum
        local randomNumber=actual+math.random(1,range-1)
        if randomNumber>maximum then randomNumber=randomNumber-range end
        return randomNumber
    end
end

local const={}--Constants, NEVER UNDER ANY CIRCUMSTANCES WRITE NEW VALUES TO THINGS DEFINED HERE!!! (if u need to, move them out of that table)
do --resolution constants
    const.resolutionMax={48,32,48}-- x,y,z max size
    
    const.resolutionMaxSize=73728 -- 48*48*32
    
    const.tDefaultPallete={}
    const.tDefaultPallete.__index=const.tDefaultPallete
    const.tDefaultPallete[1]=0x0000ff--R
    const.tDefaultPallete[2]=0x00ff00--G
    const.tDefaultPallete[3]=0xff0000--B
end

--VARIABLES
local holo = component.hologram

local colours = {--HSV 30deg shifr iirc
    {0x000040,0x000080,0x0000ff},
    {0x0075a2,0x00cfc1,0x2af5ff}, 
    {0xe9ce2c,0xef8a17,0xc84c09}} 
    
local rPallet = 1

--Objects
local machineArray1=meta.machineArray:new()
local frame1=meta.frame:new("\0")

--do once

holo.clear()
holo.setScale(.3)


while true do--main loop
    rPallet=func.cyclicRandom(rPallet,1,3)
    
    frame1:setPalette(colours[rPallet])
    frame1:sendPallete(holo)

    --Define 3D frame
    local newmachine1=meta.machine:new(math.random(0,48),math.random(0,32),math.random(0,48),math.random(1,3))--creating new machine
    machineArray1:add(newmachine1)--adding to machine array
    machineArray1:update(frame1)--updating frame content
    frame1:sendVoxels(holo)--
    
    os.sleep(5)
end