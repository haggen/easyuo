
dofile("normalize.lua")
                               
local containers = {3706, 3702, 3701, 2474, 3651, 3645, 3705}

local mover = {}

mover.recipient = player.backpack

mover.start = function()
  local target = 'item'
   
  cursor.target = true
  
  while cursor.target do
    if getkey("T") then
      if target == 'item' then
        target = 'recipient'
      else
        target = 'item'
      end

      exmessage(player.id, 2, 108, 'Targeting: ' .. target)
      
      wait(50)  
    end
    
    if getkey("ESCAPE") then
      return exmessage(player.id, 2, 108, 'Abort')
    end
    
    wait(50)
  end

  if target == 'item' then
    local target = items.scan(lasttarget.id)[1]
    
    if table.has(containers, target.type) then
      items.use(target.id)
      
      wait(750)
      
      local query = function(i) return i.container == target.id end
      local items = items.scan(query)
      local fn = function(_, item) mover.move(item.id, 500) end
      table.each(items, fn)
    else
      mover.move(lasttarget.id)
    end            
  else
    exmessage(player.id, 2, 108, 'Targeting: item')
    mover.recipient = lasttarget.id
    mover.start()
  end
end

mover.move = function(id, delay)
  items.drag(id)
  wait(50)
  items.drop(mover.recipient)
  wait(delay or 50)
end

mover.listen = function()
  while true do
    if getkey('CTRL') and getkey('Z') then
      mover.start()
    end
    
    wait(100)
  end
end

mover.listen()