# xftd
1、xftd是什么
xftd是一个lua编写的,实现根据配置文件，从git拉取代码->编译->生成docker镜像->生成docker-compose文件->docker容器启停管理的工具.
初衷是为了解决多个项目部署到一个docker中，能快速拉代码，打包镜像，方便管理依赖关系和服务的启停，以及后续的新版代码部署到docker,不用
花太多时间去了解熟悉docker用法,并对项目代码无侵入(无需考虑编写dockfile).
一个搭建环境常用的，数据库间导数据的工具(mysql).
一个可以把编译的线上环境包,发布上线的工具(非docker部署环境).
作者把它用在测试环境(已经实施)和生产环境中(尚未实施),实现系统的快速部署和更新.
初学lua的练手之作,比较粗糙.

2、为什么不用jekins等CI/CD工具
技术人员偏向于自己动手发明"轮子",除非已经有知名的很好用的轮子;
对于commandline工具的偏爱(偏执);
作者对jekins上开发和配置不熟悉,也没有动力去深入研究;
作者认知范围内的工具实现不了想要的功能;

3、支持哪些类型代码工程
java maven/springboot jar;
java gradle/springboot jar;
支持用npm/yarn编译的前端项目,作者前端开发知识有限;
其它项目类型需要修改代码增加编译支持,和docker镜像打包支持;

4、使用简介
仅支持linux和mac os

USAGE--
[help]

[create]      [systemconfigfile] [--udi(directly use docker image,no git clone source and no compile)]
创建:创建一个项目,根据配合文件，拉取代码，编译，生成docker image，生成docker-compose文件;
参数说明:
systemconfigfile: 项目配置文件
--udi(use docker image): 如果使用这个参数,将使用以前打包的镜像，不会执行(拉取代码，编译，生成docker image)

[update]      [systemconfigfile]
更新:停止并删除全部docker容器(不会删除docker映射到容器外的文件,比如配合文件,mysql数据文件等),重新拉代码,编译，生成docker image，生成docker-compose文件并启动docker容器，通常用于部署新版本;
参数说明:
systemconfigfile: 项目配置文件

[updatem]     [systemconfigfile] [modulename1,modulename2,...]]
更新其中某一个工程:同上,但操作的对象是指定的工程;
参数说明:
systemconfigfile: 项目配置文件
modulename1,modulename2,...: 工程模块名称(项目配置文件中指定module.name)

[del]         [systemname]
删除:停止并删除项目的全部工程的docker容器和镜像,并删除项目的相关数据文件;
参数说明:
systemname: 项目配置文件中的系统名称sysname

[start]       [systemname] [modulename(no specify will start whole system)]
启动:启动docker容器
参数说明:
systemname: 项目配置文件中的系统名称sysname
modulename: 工程模块名称(项目配置文件中指定module.name),未指定该参数将启动整个系统

[restart]     [systemname] [modulename(no specify will restart whole system)]
重启:重新启动docker容器
参数说明:
systemname: 项目配置文件中的系统名称sysname
modulename: 工程模块名称(项目配置文件中指定module.name),未指定该参数将重新启动整个系统

[stop]        [systemname] [modulename(no specify will stop whole system)]
停止:停止docker容器
参数说明:
systemname: 项目配置文件中的系统名称sysname
modulename: 工程模块名称(项目配置文件中指定module.name),未指定该参数将停止整个系统

[initdb]      [systemconfigfile] [sourcedb:database1,database2...] [targetdb] [nocs(with nocs means do not set --column-statistics=0 when mysqldump)]
初始化数据库:导数据工具,把sourcedb数据库实例中的database1,database2数据库导入到targetdb数据库实例中
参数说明:
systemconfigfile: 项目配置文件
sourcedb:database1,database2...: 源数据库实例名:数据库名1,数据库名2(源数据库实例名->项目配置文件中的dbs.db.name)
targetdb:目标数据库实例名(项目配置文件中的dbs.db.name)


[initdbuser]  [systemconfigfile] [dbname]
初始化用户:为数据库创建用户，并授权(默认会授权全库,全功能,全位置访问)
参数说明:
systemconfigfile: 项目配置文件
dbname: 项目配置文件中的dbs.db.name,并根据createusers.user的配合来设置用户名和密码

[status]      [systemname]
状态:查看项目的状态,包括docker运行的状态
参数说明:
systemname: 项目配置文件中的系统名称sysname

[reconfig]    [systemconfigfile]
重新配置:根据项目配置文件重新生成docker-compose文件,通常用于docker-compose文件损坏或者丢失
参数说明:
systemconfigfile: 项目配置文件

[ol]          [systemconfigfile] [r(release)/rb(rollback)/s(start)/st(stop)/rs(restart)/sts(status)] [modulename] [version(rollback need specify)]
发布:将编译好的包发布到线上环境(非docker环境).
参数说明:
systemconfigfile: 项目配置文件
operation:
r(release) 发布上线
rb(rollback) 回滚,需配合version参数
s(start) 启动
st(stop) 停止
rs(restart) 重启
sts(status) 查看状态
modulename: 工程模块名称(项目配置文件中的nodes.node.modules.module.name,需和business.module.name相同)

5、配置文件说明

xftdconfig_sample.xml

<xml>
	<sysname>test_system</sysname> //项目名称,用于命令行的systemname
	<buildprod>true</buildprod>    //编译的时候是否同时把线上环境的包也打出来,false只编译测试环境的包,如要使用ol命令发布上线,此配置需要设置为true
	                               //为什么要打两个包?作者认为测试的就是上线的,除了配置不同,不应该在上线时候再去编译打包
	                               //而且对于很多团队来说,送测编译生成物,而不是源代码是个好主意
		
		<base> // base为基础镜像,非代码编译打包出的镜像
		  <modules>
			  <module>
				  <name>mysqlerp</name> // 模块名称,全局唯一
				  <cname>mysqlerp_c</cname> // docker镜像名称,全局唯一
				  <imagetmpl>mysql5.7.22</imagetmpl> // 镜像模板名称,对应lua/docker_image_config/中的dic文件,mysql5.7.22->mysql5.7.22.dic
			  </module>

			  <module>
				  <name>cacheerp</name>
				  <cname>cacheerp_c</cname>
				  <imagetmpl>redis</imagetmpl>
			  </module>
        </modules>
        </base>
    <business> // business为非基础镜像,需要代码编译打包
		<modules>
			
			<module>
			  <name>config</name>
			  <cname>config_c</cname>
				<depends>
					<depend>eureka</depend> // 此镜像运行需要依赖eureka镜像
				</depends>				  
			  <rels>
				  <rel>eureka</rel> // 此镜像需要在eureka镜像启动再启动,系统在docker容器启动时候会检查并等待eureka容器先启动,通过配置entrypoint和dtsh/entrypoint.sh实现
			  </rels>					  		  
			  <src>git clone --depth 1 -b dev-alliance http://1.1.1.1:8899/xf/xf.git</src>
			  // 拉取代码命令
			  <path>homeins-config-service</path> //此配置用于多个代码工程在一个git目录下的情况,指定模块代码相对根目录的路径
			  <buildcmd><![CDATA[gradle -p $srcpath :homeins-config-service:clean build --exclude-task test -Dprofile=test]]></buildcmd>
			  // 编译测试环境包gradle
        <buildcmdpd><![CDATA[gradle -p $srcpath :homeins-config-service:clean build --exclude-task test -Dprofile=product]]></buildcmdpd>
        // 编译线上环境包gradle
			  <imagetmpl>springboot_midload</imagetmpl>
			</module>	
	
			<module>
			  <name>eureka</name>
			  <cname>eureka_c</cname>		  
			  <src>git clone --depth 1 -b dev-alliance http://1.1.1.1:8899/homeins/homeins.git</src>
			  <path>homeins-eureka-service</path>
			  <buildcmd><![CDATA[gradle -p $srcpath :homeins-eureka-service:clean build --exclude-task test -Dprofile=test]]></buildcmd>
			  <buildcmdpd><![CDATA[gradle -p $srcpath :homeins-eureka-service:clean build --exclude-task test -Dprofile=product]]></buildcmdpd>
			  <imagetmpl>springboot_reg</imagetmpl>
			</module>
			
			<module>
			  <name>erp-service</name>
			  <cname>erp-service_c</cname>
				<depends>
					<depend>mysqlerp</depend>
					<depend>cacheerp</depend>
					<depend>config</depend>
				</depends>				  
			  <rels>
				  <rel>mysqlerp</rel>
				  <rel>cacheerp</rel>
				  <rel>config</rel>
			  </rels>			  
			  <src>git clone --depth 1 -b dev-alliance confighttp://1.1.1.1:8899/xf/xf.git</src>
			  <path>homeins-zinsurance/homeins-erp-service</path>
			  <buildcmd><![CDATA[gradle -p $srcpath :homeins-zinsurance:homeins-erp-service:clean build --exclude-task test -Dprofile=test;ejarloc .]]></buildcmd>
        <buildcmdpd><![CDATA[gradle -p $srcpath :homeins-zinsurance:homeins-erp-service:clean build --exclude-task test -Dprofile=product;ejarloc .]]></buildcmdpd>			  
			  <imagetmpl>springboot_highload</imagetmpl>
			</module>			
			
			<module>
			  <name>allianceh5</name>
			  <cname>allianceh5_c</cname>
			  <src>git clone --depth 1 -b dev-mobile http://1.1.1.1:8899/xf/xf.git</src>
			  <buildcmd><![CDATA[yarn --cwd $srcpath install;yarn --cwd $srcpath run build:docker]]></buildcmd>
			  //编译vue项目yarn
			  <buildcmdpd><![CDATA[yarn --cwd $srcpath install;yarn --cwd $srcpath run build:dev]]></buildcmdpd>
			  <imagetmpl>vuepkg_aph5</imagetmpl>
			</module>				
		
			<module>
			  <name>allianceweb</name>
			  <cname>allianceweb_c</cname>
			  <src>git clone --depth 1 -b pc-1.7.0-20210929 http://1.1.1.1:8899/xf/xf.git</src>
			  <buildcmd><![CDATA[yarn --cwd $srcpath install;yarn --cwd $srcpath run build:docker]]></buildcmd>
			  <buildcmdpd>SAME</buildcmdpd>
			  //SAME的意思是buildcmdpd和buildcmd配置相同
			  <imagetmpl>vuepkg_apweb</imagetmpl>
			</module>	

			<module>
			  <name>configap</name>
			  <cname>configap_c</cname>
				<depends>
					<depend>eureka</depend>
				</depends>				  
			  <rels>
				  <rel>eureka</rel>
			  </rels>					  		  
			  <src>git clone --depth 1 -b config-20210915-test http://1.1.1.1:8899/xf/xf.git</src>
			  <buildcmd><![CDATA[mvn -f $srcpath -s $setting clean package -Dmaven.test.skip=true -Dmaven.repo.local=mvn_repon_temp -Pdocker;ejarloc earth-api]]></buildcmd>
			  // mvn编译, ejarloc somepath:编译出来的包,相对代码根目录的位置,举例,一个工程分dto,api,service几个目录,编译出来的包位于api中,somepath应设置为api, . 代表在代码根目录
			  <buildcmdpd><![CDATA[mvn -f $srcpath -s $setting clean package -Dmaven.test.skip=true -Dmaven.repo.local=mvn_repon_temp -Pproduct;ejarloc earth-api]]></buildcmdpd>
			  <imagetmpl>springboot_midload</imagetmpl>
			</module>	

			<module>
			  <name>venus-service</name>
			  <cname>venus_c</cname>
				<depends>
					<depend>eureka</depend>
					<depend>mysqlerp</depend>
					<depend>cacheerp</depend>	
					<depend>configap</depend>					
				</depends>				  
			  <rels>
				  <rel>eureka</rel>
				  <rel>mysqlerp</rel>
				  <rel>cacheerp</rel>
				  <rel>configap</rel>			
			  </rels>					  		  
			  <src>git clone --depth 1 -b venus-20210915-test http://1.1.1.1:8899/xf/xf.git</src>
			  <buildcmd><![CDATA[mvn -f $srcpath -s $setting clean package install -Dmaven.test.skip=true -Dmaven.repo.local=mvn_repon_temp -Pdocker;ejarloc venus-api]]></buildcmd>
			  <buildcmdpd><![CDATA[mvn -f $srcpath -s $setting clean package install -Dmaven.test.skip=true -Dmaven.repo.local=mvn_repon_temp -Pproduct;ejarloc venus-api]]></buildcmdpd>
			  <imagetmpl>springboot_midload</imagetmpl>
			</module>	
	</modules>

	</business>
       <dbtransfer> // 数据库迁移配置
  	<dbs>
  	  <db>
  		  <name>mysql_remote</name> //数据库实例名称
  		  <host>xxx.mysql.xxx.com</host>
  		  <port>3306</port>
  		  <root>dev_root</root> // 这里要给root账号,要有localhost和%的权限
  		  <pwd><![CDATA[xxxx]]></pwd>  		  
  	  </db>
  	  <db>
  		  <name>mysql_docker</name>
  		  <host>127.0.0.1</host>
  		  <port>3307</port>
  		  <root>root</root>
  		  <pwd><![CDATA[123456]]></pwd>
  		  <createusers> // 要在这个库上创建的用户
  		  	<user>
  		  		<acc>dev_root9</acc>
  		  		<pwd><![CDATA[123hod\!@#]]></pwd>
  		  		<gdb>alliance</gdb> // 给这个账号授权哪些库
  		  	</user>		  	
  		  </createusers>  		  
  	  </db>
  	</dbs>
        </dbtransfer>
        <goonline> //上线发布配置
  	<transpath>/opt/release/</transpath> // 上线用的临时目录,需提前创建
  	<prodpath>/opt/onlineproduct/</prodpath> // 线上包存放目录,需提前创建
  	<bkpath>/opt/onlinebk/</bkpath> // 历史线上包存放目录,需提前创建
  	<logroot>/opt/onlinelogs/</logroot> // 日志存放路径,需提前创建

  	<stop> // 服务停止脚本模板
  		<cmd>
  			<name>springboot</name> // 服务的类型,不同类型的脚本不同
  			<sp> 
  			<![CDATA[
  		      echo "========== stop module ${module}... =========="
            pid=`ps -ef | grep ${module} | awk '{if($8=="'java'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              kill -9 ${pid}
              echo "========== ${module} stopped =========="
            else
              echo "===========not found ${module} pid =========="
            fi  			
  			]]>
  			</sp>
  		</cmd>
  		<cmd>
  			<name>vue</name>
  			<sp>
  		  <![CDATA[
  		      source /etc/profile
  		      echo "========== stop module ${module}... =========="
            pid=`ps -ef | grep nginx | awk '{if($9=="'master'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              nginx -s stop
              echo "========== ${module} stopped =========="
            else
              echo "===========not found ${module} pid =========="
            fi 
  			]]>
  			</sp>
  		</cmd>
  	</stop>
  	<start> //启动服务脚本模板
  		<cmd>
  			<name>springboot</name>
  			<sp>
  			<![CDATA[
  			    source /etc/profile
  		      echo "========== start module ${module}... =========="
            pid=`ps -ef | grep ${module} | awk '{if($8=="'java'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              echo "========== ${module} has already started =========="
            else
              echo "===========not found ${module} pid =========="
              echo "========== start module ${modulef}...=========="
  			      nohup java -Xmx512m -Xss64m -Xss8m -XX:ParallelGCThreads=2 -jar ${modulef} --spring.profiles.active=local > /dev/null 2>&1 &
  			      echo "========== ${modulef} started =========="
  			      exit
            fi 
  			]]>
  			</sp>
  		</cmd>
  		<cmd>
  			<name>vue</name>
  			<sp>
  				<![CDATA[
  			    source /etc/profile
  		      echo "========== start module ${module}... =========="
            pid=`ps -ef | grep nginx | awk '{if($9=="'master'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              echo "========== ${module} has already started =========="
            else
              echo "===========not found ${module} pid =========="
              echo "========== start module ${modulef}...=========="
  			      nginx -c /usr/local/nginx/conf/nginx.conf
  			      echo "========== ${modulef} started =========="
  			      exit
            fi 
  				]]>
  		</sp>
  		</cmd>
    </start>
  	<restart> // 重启服务脚本模板
  		<cmd>
  			<name>springboot</name>
  			<sp>
  			<![CDATA[
  				  source /etc/profile
  		      echo "========== stop module ${module}... =========="
            pid=`ps -ef | grep ${module} | awk '{if($8=="'java'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              kill -9 ${pid}
              echo "========== ${module} stopped =========="
            else
              echo "===========not found ${module} pid =========="
            fi 

  			    echo "========== start module ${modulef}...=========="
  			    nohup java -Xmx512m -Xss64m -Xss8m -XX:ParallelGCThreads=2 -jar ${modulef} --spring.profiles.active=local > /dev/null 2>&1 &
  			    echo "========== ${modulef} started =========="
  			    exit              				
  			]]>
  			</sp>
  		</cmd>  		
  		<cmd>
  			<name>vue</name>
  			<sp>
  			<![CDATA[
  				  source /etc/profile
  		      echo "========== stop module ${module}... =========="
            pid=`ps -ef | grep nginx | awk '{if($9=="'master'"){print $2}}'`
            if [[ ${pid}  =~ ^[0-9]+$ ]]
            then
              echo "========== found ${module},PID->${pid} =========="
              nginx -s stop
              echo "========== ${module} stopped =========="
            else
              echo "===========not found ${module} pid =========="
            fi 

  			    echo "========== start module ${modulef}...=========="
  			    nginx -c /usr/local/nginx/conf/nginx.conf
  			    echo "========== ${modulef} started =========="
  			    exit  				
  			]]>
  			</sp>
  		</cmd> 
  	</restart>

    <nodes> // 线上机器节点列表
  	  <node>
  		  <host>2.2.2.2</host>
  		  <port>234</port> // ssh port
  		  <user>root</user> // ssh user
  		  <modules> // 这台机器上部署了哪些项目
  			  <module>
  				  <name>eureka</name>  // 和上面的module.name必须一致
  				  <type>sb</type> // 模块类型,不同类型上线流程有些不同,目前有sb(java springboot项目)和vu1(vue 前端项目)两种,区别就是vue部署在了nginx配置的路径,java部署在了上面配置的prodpath
  				  <start>springboot</start> // 启动用什么类型脚本
  				  <stop>springboot</stop>  // 停止用什么类型脚本
  				  <restart>springboot</restart>  // 重启用什么类型脚本
  				  <logpath>${logroot}/eureka-server/eureka-server.log</logpath> // 日志位置
  		    </module>
  			  <module>
  				  <name>config</name>
  				  <type>sb</type>
  				  <start>springboot</start>
  				  <stop>springboot</stop>
  				  <restart>springboot</restart>
  				  <logpath>${logroot}/config-service/config-server.log</logpath>
  		    </module>
  			  <module>
  				  <name>erp-service</name>
  				  <type>sb</type>
  				  <start>springboot</start>
  				  <stop>springboot</stop>
  				  <restart>springboot</restart>
  				  <logpath>${logroot}/erp-service/erp-service.log</logpath>
  		    </module> 		  
  	    </modules>
  	  </node>

  	  <node>
  		  <host>3.3.3.3</host>
  		  <port>234</port>
  		  <user>root</user>
  		  <modules>
  			  <module>
  				  <name>eureka</name>
  				  <type>sb</type>
  				  <start>springboot</start>
  				  <stop>springboot</stop>
  				  <restart>springboot</restart>
  				  <logpath>${logroot}/eureka-server/eureka-server.log</logpath>
  		    </module>
  			  <module>
  				  <name>config</name>
  				  <type>sb</type>
  				  <start>springboot</start>
  				  <stop>springboot</stop>
  				  <restart>springboot</restart>
  				  <logpath>${logroot}/config-service/config-server.log</logpath>
  		    </module>
  			  <module>
  				  <name>erp-service</name>
  				  <type>sb</type>
  				  <start>springboot</start>
  				  <stop>springboot</stop>
  				  <restart>springboot</restart>
  				  <logpath>${logroot}/erp-service/erp-service.log</logpath>
  		    </module>		  
  	    </modules>  	  	
  	  </node>
  	  
  	  <node>
  		  <host>4.4.4.4</host>
  		  <port>234</port>
  		  <user>root</user>
  		  <modules>
  			  <module>
  				  <name>allianceh5</name>
  				  <type>vu1</type>
  				  <start>vue</start>
  				  <stop>vue</stop>
  				  <restart>vue</restart>
  				  <logpath>/usr/local/nginx/logs/gateway.log</logpath>
  				  <depolypath>/opt/www/alliance.ui/dist/</depolypath> // 编译包要部署在哪里,有些类型的项目需要指定,比如这个vu1(vue前端项目)
  		    </module>		  
  	    </modules>  	  	
  	  </node>  	  	
    </nodes>
    </goonline>
    </xml>

6、关于imagetmpl(docker compose模板)的配置
位于lua/docker_image_config中的模板文件，如果要在项目配置中使用新的docker镜像类型，比如redis,kafka需要先配置模板，模板的格式遵循docker compose
的配置文件规范,注意其中的空格和缩进！！！！！;
其中的$links，$depends，$drdir,$imagename,$cname,$dependdt 运行时将被替换成具体的值,不支持除此以外的其它通配符;
springboot项目和vue项目的模板已经配置好,请不要修改;
nginx镜像,内置了配置文件,位于dtsh目录下;

7、系统依赖和配置
位于mainconfig.lua中，根据实际情况修改

java_base=xftd_root..'/jdk1.8/bin' // jdk所在目录
sources_base=xftd_root..'/sourcesbase' // 代码存储目录
mvn_base=xftd_root..'/mvn/bin' // maven所在目录
gradle_base=xftd_root..'/gradle-5.5/bin' //gradle所在目录
node_base=xftd_root..'/node-v10.16.3-darwin-x64/bin' //// node(npm,yarn)所在目录
mysqlclient_base=xftd_root..'/mysqlbin' // mysqlclient所在目录
git_dir = '/usr/bin/' // git所在目录

在lua目录下建立gitconfig.config文件,第一行git账号,第二行git密码,行间回车分割
local gcf = readfile('gitconfig.config')
git_user = gcf:split('\n')[1]
git_user_pwd = gcf:split('\n')[2]
print(git_user, git_user_pwd)


需要预先建立好的目录
config_his_base=xftd_root..'/confighis'
config_release_base=xftd_root..'/release'
tmp_base=xftd_root..'/tmp'

8、运行环境安装

lua安装(以mac os 为例)
curl -R -O http://www.lua.org/ftp/lua-5.4.3.tar.gz
tar zxf lua-5.4.3.tar.gz
cd lua-5.4.3
make macosx test
make install

docker&docker compose安装(以centos 为例)
https://docs.docker.com/engine/install/centos/
https://docs.docker.com/compose/install/


lfs(一个文件操作库)安装(以mac os 为例)
Wget https://github.com/keplerproject/luafilesystem/archive/refs/tags/v1_8_0.zip
unzip v1_8_0.zip
cd luafilesystem-1_8_0
gcc -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings -pedantic -I/usr/local/include -I/usr/include/lua5.1 -I/usr/include/lua/5.1 -I/opt/lua-5.4.3/src  -c -o src/lfs.o src/lfs.c
编译完成后将lfs.o拷贝到lua目录下

mysqlclient安装(以centos 为例)
https://www.cnblogs.com/buxizhizhoum/p/11725588.html

shasum
要运行shasum -a 256 file 命令校验签名,需安装shasum


