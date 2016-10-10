--Variables and functions
--Layer 1 {OK, Fault, Crit} Layer 2 {hex,hex,hex}
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
    function meta.frame:new(mDefault)
        local o={
            ["default"]=mDefault}
        setmetatable(o,self)
        self.__index=self
        self["voxels"]={}--to do later code that handles checking machine state
        
        local tDefaulter={}
        tDefaulter.__index=function() return mDefault end
        setmetatable(self.voxels,tDefaulter)
        return o
    end 
    
    function meta.frame:set(x,y,z,mState)
        local index=x+y*48+z*48*32
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
    
    function meta.frame:render(cHolo)
        local str=""
        for i=1,48*32*48 do
            str=str..self.voxels[i]
        end
        cHolo.setRaw(str)
        return str
    end
end

local func={}
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
    function func.xyzToPosition(x,y,z)
        return x+48*y+1536*z -- y is shifted by xMax+1, z is shifted by (xMax+1)*(yMax+1)
                             --yes our coord system starts from 0 !!!
    end
    
    function func.positionToXYZ(pos)
        local Z=math.floor(pos/1536)--48*32 full multiples of 1536 OK
        local X=math.fmod(pos,48)--0-47 OK
        return X,math.floor((pos-Z-X)/48),Z --calculate Y as the remaining thing
    end
end
--INIT END

local colours = {--HSV 30deg shifr iirc
    {0x000040,0x000080,0x0000ff},
    {0x0075a2,0x00cfc1,0x2af5ff}, 
    {0xe9ce2c,0xef8a17,0xc84c09}} 

--Load Basics

local component = require("component")
local keyboard =  require("keyboard")
local holo = component.hologram
holo.clear()
holo.setScale(.3)

local rPallet = 1

local machineArray1=meta.machineArray:new()
local frame1=meta.frame:new("\0")

while true do

    rPallet=rPallet+math.random(1,#colours-1)--"cyclic range" randomness with the same object exclusion
    if rPallet>#colours then rPallet=rPallet-#colours end

    for i=1,3 do
        holo.setPaletteColor(i, colours[rPallet][i])
    end

    --Define 3D frame
    local newmachine1=meta.machine:new(math.random(0,48),math.random(0,32),math.random(0,48),math.random(1,3))--creating new machine
    machineArray1:add(newmachine1)--adding to machine array
    machineArray1:update(frame1)--updating frame content
    frame1:render(holo)--
    
    os.sleep(5)
end