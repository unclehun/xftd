--[[
  clarkewanglei@gmail.com
--]]


require("fileopt")

function transferDatabase(mysqlbase,sdb,shost,sroot,sport,spwd,spath,tdb,thost,troot,tport,tpwd,nocsb)
    print"transfer database."
    --从smysql中导出sdb数据库整库到文件
    if(fileExists(spath)) then 
       --cs = 'rm -rf '..spath
       --print(cs)
       --local t1 = io.popen(cs)
       --local a1 = t1:read("*all")
       --print(a1)；
        os.remove(spath)
        os.remove(spath..".m")
    else
       print ("not found "..spath.."")
       --return
    end

    local cs = ' --column-statistics=0'
    --if(true == nocsb) then
    if(nocsb) then
      cs = ''
    end
    local dpc = mysqlbase..'/mysqldump -h'..shost..' -P'..sport..' -u'..sroot..' -p'..spwd..' '..sdb..' > '..spath..' --quick'.. cs
    print(dpc)
    local t = io.popen(dpc)
    local a = t:read("*all")
    print(a);
    
    -- 增加建库命令到文件开头,形成新文件.m
    local cpp = "reset master;\nDROP DATABASE IF EXISTS `"..tdb.."`;\nCREATE DATABASE `"..tdb.."`;\nUSE `"..tdb.."`;\n"..readfile(spath);
    
    --print(cpp);
    local mfn = spath..".m";
    
    writefile(mfn,cpp)
    
    -- 数据导入目标库
    ipc = mysqlbase..'/mysql -h'..thost..' -P'..tport..' -u'..troot..' -p'..tpwd..' -f < '..mfn
    print(ipc)
    local t1= io.popen(ipc)
    local a1 = t1:read("*all")
    print(a1);
    
end