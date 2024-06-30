# aapanel-6.8.37-backup

使用方法：

安装/install：

     wget  https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/install.sh && bash install.sh


纯官方版，无任何改动


删除默认添加的以下端口

            ufw allow 20/tcp
            ufw allow 21/tcp
            ufw allow 22/tcp
            ufw allow 888/tcp
            ufw allow 39000:40000/tcp

默认只添加80,443,ssh端口和面板端口

# nginx.sh 文件


nginx.sh 基于BT官方文件修改了一下，文件里面有详细解释，主要是以优化和加强安全为主，添加了brotli模块，修改响应的头信息server字段值，从nginx修改成OWASP WAF和去除nginx版本号

文件是基于 debian 12 编写的兼容ubuntu系统




nginx.sh 使用方法：

     rm -f /www/server/panel/install/nginx.sh && wget -O /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24

注意修改命令尾部的版本号，默认安装 nginx 1.24

支持版本：

tengine='3.1.0'

nginx_108='1.8.1'

nginx_112='1.12.2'

nginx_114='1.14.2'

nginx_115='1.15.10'

nginx_116='1.16.1'

nginx_117='1.17.10'

nginx_118='1.18.0'

nginx_119='1.19.8'

nginx_120='1.20.2'

nginx_121='1.21.4'

nginx_122='1.22.1'

nginx_123='1.23.4'

nginx_124='1.24.0'

nginx_125='1.25.5' # 未测试是否可用

nginx_126='1.26.1' # 未测试是否可用

openresty='1.25.3.1'



<br><br><br>

# ModSecurity-nginx.sh

ModSecurity-nginx.sh 基于nginx.sh添加了ModSecurity防火墙（ OWASP CRS ），根据官方文档添加

注意：ModSecurity-nginx.sh除ubuntu/debian系统外其他系统未安装相应依赖

ModSecurity-nginx.sh 使用方法：

     rm -f /www/server/panel/install/nginx.sh && wget -O  /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/ModSecurity-nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24


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


注意修改命令尾部的版本号，默认安装 nginx 1.24

支持版本：

tengine='3.1.0'

nginx_108='1.8.1'

nginx_112='1.12.2'

nginx_114='1.14.2'

nginx_115='1.15.10'

nginx_116='1.16.1'

nginx_117='1.17.10'

nginx_118='1.18.0'

nginx_119='1.19.8'

nginx_120='1.20.2'

nginx_121='1.21.4'

nginx_122='1.22.1'

nginx_123='1.23.4'

nginx_124='1.24.0'

nginx_125='1.25.5' # 未测试是否可用

nginx_126='1.26.1' # 未测试是否可用

openresty='1.25.3.1'

# 关于降级
不建议高版本降级低版本，如果你真想降级，备份/www目录然后删除他重新安装即可

# 关于错误
这个脚本测试过很多次，保证没有错误，如果安装过程中出现错误或者后台出现错误大部分原因是因为宝塔服务器出现了问题，请过20分钟到一小时后重新安装即可
