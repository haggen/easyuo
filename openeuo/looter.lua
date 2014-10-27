------------------------------------
-- Script Name: Corpse Looter
-- Author: Brian G with functions from Kal In Ex!
-- Version: 1.00
-- Client Tested with: 7.0.10.3
-- EUO version tested with: OpenEUO 0.91.0022
-- Shard OSI / FS: FS
-- Revision Date: 6/30/11
-- Public Release: N/A
-- Purpose: An Automatic Corpse Looter  
-- Instructions: Set Config below as per comments. Run script and target container to drop loot in.
--               You can also hit CTRL Z to manually loot items =)  
--BETA CHANGES IN TESTING--
 
--------------------------------------
--CONFIG SETTINGS BELOW! PLEASE READ COMMENTS!--------------------------------
autoLootCorpse = true --when true it will auto loot corpses withing range, set to false to only use hotkey looting
wt = 270 --this is the wait time in milliseconds between certain actions, increase if your missing cuts or drops
UO.CliNr = 1 --change this to change which client it's run on.
lootBlues = false --make this true if you want to loot blue corpses
cutCorpse = true --set to false to not cut corpses, this won't cut humans up!
autoShearSheep = true -- set to false if you dont wanna shear sheep automatically
waitBeforeLoot = 300
------------------------------------------------
--END OF CONFIG SETTINGS
--DO NOT EDIT ANYTHING BELOW THIS LINE!
 
--DEFINITIONS AND CALLS-----------------------------------------
dofile(getinstalldir().."scripts/Kal In Ex/FindItems.lua") --Includes Kal In Ex FindItem, awesome function!
dofile(getinstalldir().."scripts/Kal In Ex/journal.lua")  
corpseType = {8198}
IT = {}
ITT = {7933,5398,5899,3966,7585,3850,5905,7133,5199,7586,5200,5198,7034,2600,5112,7583,7124}
j = journal:new()
scissorType = {3999}
hideType = {4216,4217}
cutterType = {3921, 3922, 5118, 5119, 5184, 5185, 5045, 5046, 5047, 5048, 5049, 5050}
sheepType = {207}
--FUNCTIONS--------------------------------------------------------
function CheckForMovement(nStartX, nStartY, nTolerance) --this function checks for movement with a definable tolerance
   nTolerance = nTolerance or 0  --if no tolerance is defined there is a tolerance of 1 as default
   nStartX = nStartX or UO.CharPosX
   nStartY = nStartY or UO.CharPosY --if you don't specify position it uses current position
   for x=nTolerance * -1, nTolerance do --this formula will start at negative nTolerance and go to nTolerance
      if UO.CharPosX==nStartX+x then --if your position is any of these x numbers
         for y=nTolerance * -1, nTolerance do  --then start checking Y as well
            if UO.CharPosY ==nStartY+y then --if your on one
               return false --RETURN FALSE! YOU DIDNT MOVE OUT OF THE TOLERANCE!
            end
         end
      end
   end
   return true --Otherwise you DID move out of the tolerance! Return True!
end
 
function OpenContainer(nContID) --opens any container and checks for messages
   local j = journal:new() --sets a new journal instance
   WaitForNoTarget() --waits for no target
   local timerEnd = getticks() + 3000 --sets timer to 3 seconds
   repeat
      UO.LObjectID = nContID --set last object to the container you want to open
      UO.Macro(17,0) --use last object
      wait(150) --wait a bit for messages
      local jResult = j:find("criminal","locked","too far","reach that","recharge","access") --check for all these possibilities
      if jResult == 1 then return "blue" --this means its a blue corpse!
      elseif jResult == 2 then return "locked" --this means it's locked!
      elseif jResult == 3 or jResult == 4 then return "too far" --this means its too far away!
      elseif jResult == 5 then return "recharge"
      elseif jResult == 6 then return "access" end
   until UO.ContID == nContID or getticks() > timerEnd  --this will keep trying to open it until it opens or 3 seconds passes
   return true --if it gets through it all with no issue return true!
end
 
function LootContainer(nGetContID,nDropContID, tIgnoreTypeTable, nStartX, nStartY) --Ah the looting function
   nStartX = nStartX or UO.CharPosX
   nStartY = nStartY or UO.CharPosY --if you dont specify a starting position it uses your current position
   if CheckForMovement(nStartX, nStartY) then return "moved" end
   local item = ScanItems(true,{ContID=nGetContID},{Type=tIgnoreTypeTable}) --find all items besides ones you pass on the ignore table
   for x=1, #item do --for each item found in the container
      local attempts = 0 --sets new journal and attempts to 0
      repeat
         if UO.Weight >= UO.MaxWeight then return "overweight" end --if your overweight stop and return overweight
         CheckForDragging() --make sure user isnt dragging an item
         print("Dragging: " .. item[x].Name)
         if CheckForMovement(nStartX, nStartY) then return "moved" end --if you move stop and return moved
         UO.LObjectID = nGetContID
         UO.Macro(17,0)
         local result = DragDrop(item[x].ID,item[x].Stack,"C",nDropContID)
         wait(350)
         if result == "too far" then return "moved" end
         if result == "access" then return "access" end
         if result == "cannot see" then return "cannot see" end
         if result == "not found" then
            print("item not found, skipping it!")
            break
         end
         if result == "cannot hold" then  
            CutHides()
            print("Couldn't grab item: " .. item[x].Name .. ".  Container too full!")
            break
         end
         attempts = attempts + 1  --add 1 attempt
         itemCheck =ScanItems(true,{ID=item[x].ID, ContID=nGetContID}) --check if the item is still in the original container
      until #itemCheck == 0 or attempts > 2 --keep trying until the item is out of the container or you've tried 3 times
   end
   return "success" --returns success even if some items failed 3 drag attempts, some items are only for specific characters and cannot be moved
end
 
function CheckForDragging()  --simple function pauses while the user drags anything
   while UO.LLiftedKind == 1 do wait(1) end
end
 
--My first function designed to be a function from the start.
--Has error checking/reporting and multiple return options based on the outcome
--Usage: DragDrop(nItemID, nItemStack, sDropType, nDropContID,nX,nY,nZ
--       nItemID - this is the ID of the item to drag
--       nItemStack - this is the amount of the item stack you want to drag, use the entire stack to drag all
--       sDropType - this is a string, can be PD for paperdoll drop, C for container drop, G for ground drop
--       nDropContID - this is the drop container ID, you can set this to anything if your not dropping into a container
--                     It can also be ignored if dropping to PD, but needs a value for ground dropping, I use nil but anything works its ignored
--       nX - this is the X coord to drop on the ground, ignored in C and PD drops
--       nY - this is the Y coord to drop on the ground, ignored in C and PD drops
--       nZ - this is the Z coord to drop on the ground, defaults to UO.CharPosZ if nil
--Return possibilities:
--                     too far - returns if it tries to drag an item and it gets the too far message
--                     access - returns when you get the cannot acces message
--                     cannot hold - returns when you get the container cannot hold message
--                     cannot see - returns when tries to drag and get the message cannot see
function DragDrop(nItemID, nItemStack, sDropType, nDropContID,nX,nY,nZ) -- sDropType can be PD, C, G. PD will drop on paperdoll/C on the ContID/ G on nX,nY  
    local j = journal:new()
    if nZ == nil then nZ = UO.CharPosZ end
    local test = ScanItems(true, {ID=nItemID})
    if #test == 0 then return "not found" end
    UO.Drag(nItemID, nItemStack) --drag the whole item stack
    wait(50)
    local jResult = j:find("too far", "access", "cannot see")
    if jResult == 1 then return "too far" end
    if jResult == 2 then return "access" end
    if jResult == 3 then return "cannot see" end
    if sDropType == "PD" then UO.DropPD()
    elseif sDropType == "C" then
       if nDropContID == nil then
          print("Drop Container ID not set in DragDrop Function!")
          print("Please make sure to pass nDropContID as the fourth parameter!")
          return "error"
       end
       UO.DropC(nDropContID)
    elseif sDropType == "G" then
       if nX == nil or nY == nil then
          print("nX or nY not set in DragDrop Function!")
          print("Please set nX, nY as the fifth/sixth parameter!")
          return "error"
       end
       UO.DropG(nX,nY,nZ)
    else
      print("Invalid sDropType: " .. tostring(sDropType) .. " in function DragDrop")
      print("Valid Options are: PD, C, G")
      return "error"
    end
    wait(50)
    local jResult = j:find("cannot hold") --this skips any items that may be too heavy
    if jResult == 1 then return "cannot hold" end
end
 
function FindAndUseOn(nItemTypeToFind, nObjectToTarget, nTargetKind) --Ah the find and use on function
   nTargetKind = nTargetKind or 1 --If you don't pass this a target kind it uses 1 as the default
   item = ScanItems(true,{Type=nItemTypeToFind, ContID={UO.BackpackID, UO.CharID}}) --look in backpack and paperdoll for item
   if #item == 0 then
      print("FindAndUseOn:Couldn't find item type: " .. nItemTypeToFind .. " in Backpack or PD")
          print("FindAndUseOn:Returning false")
      return false --if not found return false, were done now
   else itemID = item[1].ID end --otherwise store the item id
   UO.LObjectID = itemID --set that item to last object
   WaitForNoTarget() --make sure theres no target already up from some user action
   UO.Macro(17,0)   --use the last object macro
   UO.LTargetID = nObjectToTarget  --now set last target to the item you want to target
   local timerEnd = getticks() + 2000 --set a timer for 2 seconds
   while not UO.TargCurs do
      if getticks() > timerEnd then
             print("FindAndUseOn:Target never showed up using ID: " .. item[1].ID)
                 print("FindAndUseOn:Returning error")
                 return "error"
          end
      wait(1)
   end --wait for the target cursor/ timeout of 2 seconds
   UO.LTargetKind = nTargetKind --set the target kind
   local j = journal:new()
   UO.Macro(22,0) --use last target macro
   print("Used: " .. item[1].Name .. " on: " .. nObjectToTarget)
   timerEnd = getticks() + 2000
   repeat --This repeat loop waits for a confirmation message or the Timer
      local jResult = j:find("meat","feathers","hides","wool","cut","useful","on that","too far","cannot see","scissor")
      if jResult == 1 or jResult == 2 or jResult == 3 or jResult == 4 or jResult == 5 then return "success"
      elseif jResult == 6 then return "empty"
      elseif jResult == 7 then return "invalid"
      elseif jResult == 8 or jResult == 9 then return "moved"
      elseif item[1].Name == "Scissors" then return "scissors" end
      if getticks() > timerEnd then
         print("FindAndUseOn: No confirmation message received")
         print("FindAndUseOn: Returning error")
         return "error"
      end
   until jResult ~= nil
end
 
function CombineTables(tMainTable, tAddTables) --This function combines 2 tables into 1. I was gonna use it for filter what I wanted
   for x=1, #tAddTables do                     -- instead I just made an ignore table and I loot everything else
      for y=1, #tAddTables[x] do               --figured I'd leave it in here in case
         table.insert(tMainTable,tAddTables[x][y])
      end
   end
   return tMainTable
end
 
function UserSetVar(sMessage)  --This functions is one of my favorites/ lets users click on stuff with an exmsg appearing
   UO.ExMsg(UO.CharID,sMessage)
   UO.TargCurs=true --set cursor to target
   while UO.TargCurs do
      wait(1)
      if getkey("ESC") then return false end --if esc is hit it returns false
   end
   return UO.LTargetID  --returns the ID of whatever was clicked!
end
 
function ScanForCorpse(nMaxDist) --returns all IDs in table if found, empty table if not.
   local distanceTable, corpseIDTable, corpseStackTable, corpseNameTable, zTable = {},{},{},{},{UO.CharPosZ - 1, UO.CharPosZ, UO.CharPosZ + 1} --initializes all 4 tables
   for x=0, nMaxDist do --creates a table of MaxDist for use with ScanItem like Dist={0,1}
      distanceTable[x+1] = x
   end
   corpsesInRange = ScanItems(true, {Type=corpseType, Dist=distanceTable, Z=zTable}, {ID=IT}) --filters out IDs in the table IT
   for x=1, #corpsesInRange do --for all corpses in range
      print(corpsesInRange[x].ID .. " Found!" )--if it finds a corpse
      corpseIDTable[x] = corpsesInRange[x].ID --store IDs
      corpseStackTable[x] = corpsesInRange[x].Stack --store Stacks
      --corpseNameTable[x] = corpsesInRange[x].Name
   end
   return corpseIDTable, corpseStackTable, corpseNameTable --return our newly created tables!
end
 
function WaitForNoTarget() --this simple function pauses the script until the cursor is not a target
   while UO.TargCurs do wait(1) end
end
 
function FindAndShearSheep() --Finds and shears sheep, no return here just a dumb function
   local sheep = ScanItems(true, {Type=sheepType, Dist={1,2}}) --finds sheep within 2 tiles
   for x=1, #sheep do --for all the sheep
      print("Sheep found! Shearin' dat mofo!")
      FindAndUseOn(cutterType, sheep[x].ID) --use any cutter on it
   end
end    
 
function CutHides()
   local hides= ScanItems(true,{Type=hideType, ContID={UO.BackpackID, dropContID}}) --find some hides in pack
   for x=1, #hides do    --for all the hides you find
      FindAndUseOn(scissorType, hides[x].ID) --use scissors on em
   end
end
 
function ManualLooter()
   local getContID=UserSetVar("Target Container to loot!") --sets container to loot
   if not getContID then return false end  --if esc is hit then quit the function and return false
   local result = OpenContainer(getContID) --otherwise open it and save the result
   if result == "locked" then --if its locked then let the player know
      UO.ExMsg(UO.CharID,"Container Locked!")
   elseif result == "too far" then --same if it's too far
      UO.ExMsg(UO.CharID,"Too Far!")
   else --otherwise loot it all!
      LootContainer(getContID,dropContID) --otherwise loot it all! notice no blue check or ignore table!
   end
end
 
function StabilityCheck(nTimeToWait, nStartTime, nStartX, nStartY)
    print("Running Stability Check for " .. nTimeToWait .. "ms")
    nStartX = nStartX or UO.CharPosX
    nStartY = nStartY or UO.CharPosY
    nStartTime = nStartTime or getticks()
    local timerEnd = nStartTime + nTimeToWait
    while timerEnd > getticks() do
       if CheckForMovement(nStartX, nStartY,0) then
          print("Stability check failed!")
          return false
       end --if you moved return false
       wait(1)
    end
    print("Stability check passed!")
    return true --if you didnt move the whole time return true
end
 
function UserMoved()
   UO.ExMsg(UO.CharID,"You Moved!") --tell the player!
   UO.DropC(UO.BackpackID) --drop anything your holding in the backpack
   print("Character moved!") --and tell the scripter too
end
 
--MAIN SCRIPT--------------------------------------------------------------------------------------------
dropContID=UserSetVar("Target container to drop loot in.")
if not dropContID then
   UO.ExMsg(UO.CharID,"Esc Hit! Looter Stopped!")
   stop()
end
--MAIN LOOP----------------------------------------------------------------------------------------------
while true do
   CutHides()  --first lets cut any heavy hides you got
   if autoShearSheep then FindAndShearSheep() end --then lets check for some sheep to shear
   if getkey("CTRL") and getkey("Z") then ManualLooter() end --then watch for the hotkey to manually loot
----BEGIN AUTO-LOOTING CORPSE CODE!----------------------------------------------------------------------
   if autoLootCorpse then --Skips this entire section if auto-loot is off. Works great as a hot key looter!
      corpseID, corpseStack = ScanForCorpse(2) --Scans for corpses within 1 tile, stores the ID and Stack as a table (I use stack to determine if it's a human corpse)  
      if #corpseID > 0 then
         local startX, startY, startTime = UO.CharPosX, UO.CharPosY, getticks() --remember when and where you found it
         for x=1, #corpseID do  --for every corpse you've found
            if not StabilityCheck(waitBeforeLoot, startTime, startX, startY) then break end
            local result = OpenContainer(corpseID[x]) --Opens corpse and sets dontloot
            if result == "blue"  and not lootBlues then --if it's blue
               UO.ExMsg(UO.CharID,"Blue Corpse!")  --tell the player
               print("Blue Corpse! Ignoring it!") --tell the scripter
               table.insert(IT,corpseID[x]) --ignore that corpse
               break
            elseif result == "moved" then
               UserMoved()
               break
            end  --if corpse isnt blue and you didnt move
            OpenContainer(dropContID) --otherwise open your looting container (not sure if necessary)
            if cutCorpse and corpseStack[x] ~= 400 and corpseStack[x] ~= 401 then
               local result = FindAndUseOn(cutterType, corpseID[x]) --stack 400/401 is for humans
               if result == "moved" then
                  UserMoved()
                  break
               elseif result == "empty" then
                  print("Corpse had nothing to cut on it!")
               elseif result == "success" then
                  print("Corpse successfully cut!")
                  wait(300) --waits for items to show on corpse!
               elseif result == "error" then
                  print("FindAndUseOn returned an error!")
                  break
               else
                  print("Something went very wrong with FindAndUseOn!")
                  break
               end
            end
            result = LootContainer(corpseID[x],dropContID, ITT, startX, startY)
            if result == "moved" then UserMoved() --If actions based on LootContainer Result
            elseif result == "overweight" then --if you got too much on ya
               print("Overweight! Checking status bar and cutting hides!")
            if UO.MaxWeight == 0 then UO.StatBar(UO.CharID) end --then make sure the stat bar is open
               CutHides() --cut any heavy hides in your pack
               if UO.Weight >= UO.MaxWeight then UO.ExMsg(UO.CharID,"Overweight Please Unload") end --if your still overweight let the player know
               repeat CutHides() until UO.Weight < UO.MaxWeight --and pause the script until you can carry more
            elseif result == "success" then --if you havent moved and arent overweight and are done looting then
               table.insert(IT,corpseID[x]) --ignore that corpse,
               print("Successfully looted: " .. corpseID[x])
            else
               print("Unknown return: " .. tostring(result) .. " from LootContainer!")
            end  
         end
      end
   end
-------END OF AUTO LOOTING CODE!--------------------------------------------------------------------
   wait(1) --drastically reduces CPU usage!
end