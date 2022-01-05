--[[
  clarkewanglei@gmail.com
--]]

sqlite3 = require "luasql.sqlite3"  
require("map")
require("fileopt")

function enumSimpleTable(t)  
         print"-------------------"  
         for k,v in pairs(t) do  
           print(k, " = ", v)  
         end  
         print"-------------------\n"  
end  
  
function rows(cur)  
         return function(cur)  
                   local t = {}  
                   if(nil~= cur:fetch(t, 'a')) then return t  
                   else return nil end  
         end,cur  
end  

--判断表是否存在
function isTableExisted(dbname,tname)
    --db = assert(env:connect('/Users/wanglei/Documents/test.db')) 
    env = assert(sqlite3.sqlite3()) 
    db = assert(env:connect(dbname)) 
    local len = -1
    local sql = "select count(*) from sqlite_master where type = 'table' and name = '"..tname.."'";
    --print("sql:", sql)
    res = assert(db:execute(sql))
    for r in rows(res) do  
        for k,v in pairs(r) do  
            --print(k, " = ", v)  
            len = v;
        end 
    end
    db:close()  
    env:close() 
    --print("is table existed:", len)  
    return len;
end

--新建表
function createTable(dbname,sql)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)
   --print("sql:", sql)

   res = assert(db:execute(sql))  
   assert(db:commit()) 

   db:close()
   env:close() 
end

--删除表
function dropTable(dbname,tname)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)
   local sql = "drop table "..tname;
   --print("sql:", sql)
   res = assert(db:execute(sql))
   
   assert(db:commit()) 
  
   db:close()
   env:close() 
end

--判断表中是否有指定数据
function querySpecData(env,db,sql)
   print("sql:", sql)
   len = -1;
   res = assert(db:execute(sql))
   for r in rows(res) do  
       for k,v in pairs(r) do  
           --print(k, " = ", v)  
           len = v;
       end 
   end
   --print("is spec data existed:", len)

   return len
end


local xftd_db_name = 'xftd.db';

local sys_status_creating = 'creating'
local sys_status_created = 'created'
local sys_status_running = 'running'
local sys_status_stopped = 'stopped'

local module_type_business = 'biz'
local module_type_base = 'base'

--系统存储初始化
function sysinit(dbpath) 
  dbfile = dbpath..'/'..xftd_db_name
  delFile(dbfile)

  local file = io.open(dbfile,"w")
  file:close()
  
  createTable(dbfile,'CREATE TABLE lsystem(sys_name text, status text, create_time datetime)')
  
  createTable(dbfile,'CREATE TABLE lsystem_modules(sys_name text, module_name text, type text, src text, path text, upt_time datetime)')
  
end

function createSys(dbname, sysname)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)
   len = querySpecData(env,db, "SELECT COUNT(*) FROM lsystem WHERE sys_name='"..sysname.."'")
   print("len=",len)
   if(len > 0) then 
     print(sysname.." is already existed!")
     return
   end

   sql = "INSERT INTO lsystem VALUES('"..sysname.."', '"..sys_status_creating.."', "..os.time()..")"
   --print(sql)
   -- 查询时间用:select datetime(create_time, 'unixepoch', 'localtime') from lsystem;
   res = assert(db:execute(sql))
   
   assert(db:commit()) 
  
   db:close()
   env:close() 
end

function createSysModules(dbname, sysname, bizmodules, basemodules)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)

   for k,v in pairs(basemodules) do
     if("count" ~= k) then
       --print(k,v[1],v[2])
       imagever = getImageversion(v[2])
       --print(imagever)

       len = querySpecData(env,db, "SELECT COUNT(*) FROM lsystem_modules WHERE sys_name='"..sysname.."' AND module_name='"..k.."'")
       print("len=",len)
       if(len > 0) then 
         print(k.." is already existed!")
         return
       end

       sql = "INSERT INTO lsystem_modules VALUES('"..sysname.."', '"..k.."', '"..module_type_base.."', '"..imagever.."','', "..os.time()..")"
       print(sql)
       res = assert(db:execute(sql))
     end
   end
   
   for k,v in pairs(bizmodules) do
     if("count" ~= k) then
       print(k,v[1],v[2],v[3])
       sql = "INSERT INTO lsystem_modules VALUES('"..sysname.."', '"..k.."', '"..module_type_business.."', '"..v[2].."', '"..v[3].."',"..os.time()..")"
       print(sql)
       res = assert(db:execute(sql))
     end
   end   
   
   assert(db:commit()) 
  
   db:close()
   env:close() 
end

function setSysStatus(dbname, sysname, status)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)
   sql = "UPDATE lsystem SET status='"..status.."' WHERE sys_name='"..sysname.."'"
   print(sql)
   res = assert(db:execute(sql))
   
   assert(db:commit()) 
  
   db:close()
   env:close()   
end

function setSysCreated(dbname, sysname)
  setSysStatus(dbname, sysname, sys_status_created)
end

function setSysRunning(dbname, sysname)
  setSysStatus(dbname, sysname, sys_status_running)
end

function setSysStopped(dbname, sysname)
  setSysStatus(dbname, sysname, sys_status_stooped)
end


function destroySys(dbname, sysname)
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 

   db:setautocommit(false)
   sql2 = "DELETE FROM lsystem_modules WHERE sys_name='"..sysname.."'"
   print(sql2)
   res = assert(db:execute(sql2))
   sql1 = "DELETE FROM lsystem WHERE sys_name='"..sysname.."'"
   print(sql1)
   res = assert(db:execute(sql1))
   
   assert(db:commit()) 
  
   db:close()
   env:close()  
end


--根据imagetmpl获取imageversion
function getImageversion(imagetmpl)
  n = 0
  for l in io.lines('docker_image_config/'..imagetmpl..'.dic') do
    --print(n, l)
    if n == 0 then
      if(nil ~= l) then 
        sv = string.gsub(l,"%s+","")..''
        --print(sv)
        for s in string.gmatch(sv, ":.+") do
          return string.sub(s,2)..''
        end
      else
        return nil
      end 
    end
    n = n + 1
  end

end

--查询module信息
function getModuleinfo(dbname, sysname, modulename) 
   env = assert(sqlite3.sqlite3()) 
   db = assert(env:connect(dbname)) 
   
   rslt = map:new()
   sql ="SELECT * FROM lsystem_modules WHERE sys_name='"..sysname.."' AND module_name='"..modulename.."'"
   res = assert(db:execute(sql))
   for r in rows(res) do
     for k,v in pairs(r) do  
       --print(k, " = ", v) 
       rslt:insert(k,v)
     end   
   end

  return rslt
end

--[[ 
   colnames = res:getcolnames()  
  
   coltypes = res:getcoltypes()  
  
   enumSimpleTable(colnames)  
  
   enumSimpleTable(coltypes)  
  
   for r in rows(res) do  
     enumSimpleTable(r)  
   end
  
   res:close()

   db:close()  
   env:close() 
--]] 