--
-- Normalize v1.0.5 2014-10-27T20:59:10-02:00
-- more on github.com/haggen/openeuo
--

--
-- Extend standard library
--

-- Execute fn with index and value of each element found in the table t.
function table.each(t, fn)
  return for k, v in pairs(t) do fn(k, v) end
end

-- Execute fn with index and value of each element found in the table t,
-- and returns the first evaluation that gets a truthy value.
function table.any(t, fn, k)
  local nk, v = next(t, k)
  return nk ~= nil and fn(k, v) or table.any(t, fn, nk)
end

-- Tells if the table t has the value n.
function table.has(t, n)
  return table.any(t, function(k, v) return v == n end)
end

--
-- Normalize UO API
--

keystroke    = UO.Key
macro        = UO.Macro
message      = UO.Msg
exmessage    = UO.ExMsg
sysmessage   = UO.SysMessage
getjournal   = UO.GetJournal
getitem      = UO.GetItem
getskill     = UO.GetSkill
getpixel     = UO.GetPix
getgump      = UO.GetCont
scanitems    = UO.ScanItems
scanjournal  = UO.ScanJournal
hideitem     = UO.HideItem
contextmenu  = UO.Popup
renamepet    = UO.RenamePet
statusbar    = UO.StatBar
property     = UO.Property

--
-- Helper functions
--

-- Reckons the practical distance between two coordinates.
function distance(xa, ya, xb, yb)
  return math.max(math.abs(xa - xb), math.abs(ya - yb))
end

--
-- Last target API, provides read and write access to last target's information.
--

lasttarget = {}
setmetatable(lasttarget, lasttarget)

lasttarget.__index = function(t, k)
  if     k == 'id'   then return UO.LTargetID
  elseif k == 'kind' then return UO.LTargetKind
  elseif k == 'tile' then return UO.LTargetTile
  elseif k == 'x'    then return UO.LTargetX
  elseif k == 'y'    then return UO.LTargetY
  elseif k == 'z'    then return UO.LTargetZ
  else                    return nil
  end
end

lasttarget.__newindex = function(t, k, value)
  if     k == 'id'   then UO.LTargetID   = value
  elseif k == 'kind' then UO.LTargetKind = value
  elseif k == 'tile' then UO.LTargetTile = value
  elseif k == 'x'    then UO.LTargetX    = value
  elseif k == 'y'    then UO.LTargetY    = value
  elseif k == 'z'    then UO.LTargetZ    = value
  end
end

--
-- Last item API, akin to last object
--

lastitem = {}
setmetatable(lastitem, lastitem)

lastitem.__index = function(t, k)
  if     k == 'id'   then return UO.LObjectID
  elseif k == 'type' then return UO.LObjectType
  else                    return nil
  end
end

lastitem.__newindex = function(t, k, v)
  if k == 'id' then UO.LObjectID = v end
end

--
-- Player API, provides read access to your character's information
-- and also commands that affect your character directly.
--

player = {}
setmetatable(player, player)

player.__index = function(t, k)
  if     k == 'armor'        then return UO.AR
  elseif k == 'backpack'     then return UO.BackpackID
  elseif k == 'direction'    then return UO.CharDir
  elseif k == 'id'           then return UO.CharID
  elseif k == 'name'         then return UO.CharName
  elseif k == 'x'            then return UO.CharPosX
  elseif k == 'y'            then return UO.CharPosY
  elseif k == 'z'            then return UO.CharPosZ
  elseif k == 'status'       then return UO.CharStatus
  elseif k == 'type'         then return UO.CharType
  elseif k == 'strength'     then return UO.Str
  elseif k == 'dexterity'    then return UO.Dex
  elseif k == 'intellect'    then return UO.Int
  elseif k == 'maxstats'     then return UO.MaxStats
  elseif k == 'mindamage'    then return UO.MinDmg
  elseif k == 'maxdamage'    then return UO.MaxDmg
  elseif k == 'hits'         then return UO.Hits
  elseif k == 'maxhits'      then return UO.MaxHits
  elseif k == 'mana'         then return UO.Mana
  elseif k == 'maxmana'      then return UO.MaxMana
  elseif k == 'stamina'      then return UO.Stamina
  elseif k == 'maxstamina'   then return UO.MaxStam
  elseif k == 'energyresist' then return UO.ER
  elseif k == 'fireresist'   then return UO.FR
  elseif k == 'poisonresist' then return UO.PR
  elseif k == 'tithing'      then return UO.TP
  elseif k == 'luck'         then return UO.Luck
  elseif k == 'gold'         then return UO.Gold
  elseif k == 'followers'    then return UO.Followers
  elseif k == 'maxfollowers' then return UO.MaxFol
  elseif k == 'weight'       then return UO.Weight
  elseif k == 'maxweight'    then return UO.MaxWeight
  elseif k == 'sex'          then return UO.Sex
  elseif k == 'lefthand'     then return UO.LHandID
  elseif k == 'righthand'    then return UO.RHandID
  elseif k == 'move'         then return UO.Move
  elseif k == 'equip'        then return UO.Equip
  elseif k == 'pathfind'     then return UO.Pathfind
  elseif k == 'lockstat'     then return UO.StatLock
  elseif k == 'lockskill'    then return UO.SkillLock
  else                            return nil
  end
end

player.distance = function(x, y)
  return distance(player.x, player.y, x, y)
end

--
-- Cursor API
--

cursor = {}
setmetatable(cursor, cursor)

cursor.__index = function(t, k)
  if     k == 'x'      then return UO.CursX
  elseif k == 'y'      then return UO.CursY
  elseif k == 'kind'   then return UO.CursKind
  elseif k == 'click'  then return UO.Click
  elseif k == 'target' then return UO.TargCurs
  else                    return nil
  end
end

cursor.__newindex = function(t, k, v)
  if k == 'target' then UO.TargCurs = v end
end

--
-- Client API
--

client = {}

setmetatable(client, client)

client.__index = function(t, k)
  if     k == 'id'       then return UO.CliCnt
  elseif k == 'shard'    then return UO.Shard
  elseif k == 'language' then return UO.CliLang
  elseif k == 'x'        then return UO.CliLeft
  elseif k == 'y'        then return UO.CliTop
  elseif k == 'logged'   then return UO.CliLogged
  elseif k == 'index'    then return UO.CliNr
  elseif k == 'title'    then return UO.CliTitle
  elseif k == 'version'  then return UO.CliVer
  elseif k == 'width'    then return UO.CliXRes
  elseif k == 'height'   then return UO.CliYRes
  else                        return nil
  end
end

--
-- Item API
--

item = {}

item.lastquery = nil
item.lastscan = nil

item.get = function(...)
  local t = {}

  t.id, t.type, t.kind, t.container, t.x, t.y, t.z, t.stack, t.reputation, t.color = getitem(...)

  t.distance = function(x, y)
    return distance(t.x, t.y, x, y)
  end

  t.__index = function(t, k)
    if (k == 'name') or (k == 'properties') then
      t.name, t.properties = itemproperty(t.id)
    end

    return t[k]
  end

  return setmetatable(t, t)
end

item.parsequery = function(query)
  if type(query) == 'number' then
    return function(item) return item.id == query end
  elseif type(query) == 'table' then
    return function(item) return table.has(query, item.type) end
  elseif type(query) == 'string' then
    return function(item) return dostring(query) end
  elseif type(query) == 'function' then
    return query
  else
    return function() return true end
  end
end

item.scan = function(query, visibleonly)
  local query, t = item.parsequery(query), {}

  -- if query == item.lastquery then return item.lastscan end

  item.lastquery = query

  for index = 0, scanitems(visibleonly or false) - 1 do
    local item = item.get(index)
    if query(item) then table.insert(t, item) end
  end

  item.lastscan = t

  return t
end

item.drag = function(query, amount)
  if type(query) == 'number' then
    local id = query
  else
    local id = item.scan(query)[1].id
  end

  return UO.Drag(id, amount or 65535)
end

item.drop = function(...)
  local args = {...}

  if n == 0 then
    return UO.DropPD()
  elseif n >= 2 then
    return UO.DropG(...)
  else
    if type(args[1]) ~= 'number' then
      args[1] = item.scan(args[1])[1].id
    end

    return UO.DropC(...)
  end
end

item.use = function(query)
  if type(query) == 'number' then
    local id = query
  else
    local id = item.scan(query)[1].id
  end

  lastitem.id = id
  return macro(17, 0)
end

item.target = function(query)
  if type(query) == 'number' then
    local id = query
  else
    local id = item.scan(query)[1].id
  end

  lasttarget.id = id
  return macro(22, 0)
end
