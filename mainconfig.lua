--[[
  clarkewanglei@gmail.com
--]]

require("lfs")
require("fileopt")
require("commonutils")


xftd_root=string.gsub(lfs.currentdir(),"/lua",'')

--tools config
java_base=xftd_root..'/jdk1.8/bin'
sources_base=xftd_root..'/sourcesbase'
mvn_base=xftd_root..'/mvn/bin'
gradle_base=xftd_root..'/gradle-5.5/bin'
node_base=xftd_root..'/node-v10.16.3-darwin-x64/bin'
mysqlclient_base=xftd_root..'/mysqlbin'
git_dir = '/usr/bin/'

local gcf = readfile('../gitconfig.config')
git_user = gcf:split('\n')[1]
git_user_pwd = gcf:split('\n')[2]
print(git_user, git_user_pwd)

--config
docker_mappingbase=xftd_root..'/dockermpbase' --docker内容器映射到外面的文件储存目录
config_his_base=xftd_root..'/confighis'
config_release_base=xftd_root..'/release'
tmp_base=xftd_root..'/tmp'

