# aapanel-6.8.37-backup

使用方法：

安装/install：

     wget  https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/install.sh && bash install.sh && rm -rf install.sh


# 纯官方版，无任何改动,可以放心使用，里面除了修改下载脚本为github连接以外没修改任何文件，一个字母都没动过，脚本里面的多余端口删除了，下面有说明，我自己也在用，因为这个是最后一个6开头的版本了，下一个版本就是7开头的了，破解难度加大了


删除默认添加的以下端口

            ufw allow 20/tcp
            ufw allow 21/tcp
            ufw allow 22/tcp
            ufw allow 888/tcp
            ufw allow 39000:40000/tcp

默认只添加80,443,ssh端口和面板端口

# nginx安装
文件是基于 debian 12 编写的兼容ubuntu系统
注意：所有ModSecurity-nginx.sh除ubuntu/debian系统外其他系统未安装相应依赖
# nginx1.26 ModSecurity brotli http3版
ModSecurity-nginx-http3.sh基于BT官方文件修改了一下，文件里面有详细解释，主要是以优化和加强安全为主，添加了brotli模块，修改响应的头信息server字段值，从nginx修改成OWASP WAF和去除nginx版本号
ModSecurity-nginx-http3.sh是新版，最高支持1.26，默认开启http3，并且脚本已经升级lua到最新版（2024-9-29）默认安装1.26，下面还有个旧版，默认不开启http3最该支持1.24

ModSecurity-nginx-http3.sh 使用方法：

```
 rm -f /www/server/panel/install/nginx.sh && wget -O  /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity-nginx-http3.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.26
 ```


# ModSecurity防火墙开启脚本
```
wget -O /tmp/enable.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/enable.sh && bash /tmp/enable.sh && rm -rf /tmp/enable.sh
```
脚本运行完成以后在宝塔后台nginx配置文件`worker_rlimit_nofile 51200;`下面添加
```
load_module /www/server/nginx/modules/ngx_http_modsecurity_module.so;
```
在`http`块里面添加
```
modsecurity on;
```
在网站配置文件里面添加
```
    # Enable ModSecurity
    modsecurity on;
    modsecurity_rules_file /www/server/nginx/owasp/conf/main.conf;
```
这样你的网站已经初步开启owasp防火墙了，然后就是后面的调试工作，遇到403错误就查看网站日志文件进行规则调试
<br>

# 1.24版本 brotli版
nginx.sh 基于BT官方文件修改了一下，文件里面有详细解释，主要是以优化和加强安全为主，添加了brotli模块，修改响应的头信息server字段值，从nginx修改成OWASP WAF和去除nginx版本号
nginx.sh 使用方法：

     rm -f /www/server/panel/install/nginx.sh && wget -O /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24

注意修改命令尾部的版本号，默认安装 nginx 1.24
<br><br>

# 1.24版本 brotli和ModSecurity版

ModSecurity-nginx.sh是旧版最高支持1.24，默认安装1.24


ModSecurity-nginx.sh 使用方法：
```
     rm -f /www/server/panel/install/nginx.sh && wget -O  /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/ModSecurity-nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24
```

ModSecurity-nginx.sh 基于nginx.sh添加了ModSecurity防火墙（ OWASP CRS ），根据官方文档添加

修复/www/server/nginx/src里面的未知用户文件夹

添加对于wordpress一些常用拒绝规则的配置文件，存放路径：/www/server/nginx/owasp/conf/nginx-wordpress.conf

删除弃用的ipv6

删除自带的webdav模块 ${ENABLE_WEBDAV}

添加优化参数 --with-threads --with-file-aio  --with-cc-opt='-O2 -fPIE --param=ssp-buffer-size=4 -fstack-protector -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-E -Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now'

添加ngx_brotli模块 --add-module=/www/server/nginx/src/ngx_brotli

添加ModSecurity-nginx动态模块--add-dynamic-module=/www/server/nginx/owasp/ModSecurity-nginx 动态模块需要根据官方文档引入.so文件，方便后期更新维护 如果需要编译成动态模块修改成  --add-module=/www/server/nginx/owasp/ModSecurity-nginx 根据官方文档尽量编译成动态模块，这样后期更新很方便，方便维护，请详细观看下面的使用说明


ModSecurity存放路径：/www/server/nginx/owasp/ModSecurity

下载地址：https://github.com/SpiderLabs/ModSecurity

ModSecurity-nginx这个是nginx连接器

存放路径：/www/server/nginx/owasp/ModSecurity-nginx

下载地址：https://github.com/SpiderLabs/ModSecurity-nginx

OWASP CRS rules 规则文件默认下载的最版

存放文件在 /www/server/nginx/owasp/owasp-rules

下载地址：https://github.com/coreruleset/coreruleset/releases

####使用说明####

根据<a href="https://www.netnea.com/cms/nginx-tutorial-6_embedding-modsecurity/"  target="_blank">官方文档</a>步骤五在nginx.conf文件添加引入。将以下代码添加在worker_rlimit_nofile 51200;下面即可引入

     load_module /www/server/nginx/modules/ngx_http_modsecurity_module.so;

根据<a href="https://www.netnea.com/cms/nginx-tutorial-6_embedding-modsecurity/"  target="_blank">官方文档</a>骤5建议在http模块内添加以下代码全局开启

     modsecurity on;


编辑规则全局引入文件。这里面可以引入你需要的规则
文件路径： /www/server/nginx/owasp/conf/main.conf

在你的网站配置文件内添加以下代码

     modsecurity on;
     modsecurity_rules_file /www/server/nginx/owasp/conf/main.conf;

然后编辑/www/server/nginx/owasp/conf/main.conf文件在里面引入你需要的规则文件即可

所有国则文件都在/www/server/nginx/owasp/owasp-rules/rules里面

/www/server/nginx/owasp/conf/nginx-wordpress.conf文件是针对wordpress程序的一些常用拒绝规则，需要在网站的nginx配置文件里面引入


注意修改命令尾部的版本号，默认安装 nginx 1.24


# 关于降级
不建议高版本降级低版本，如果你真想降级，备份/www目录然后删除他重新安装即可

# 关于错误
这个脚本测试过很多次，保证没有错误，如果安装过程中出现错误或者后台出现错误大部分原因是因为宝塔服务器出现了问题，请过20分钟到一小时后重新安装即可
