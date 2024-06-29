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

ModSecurity-nginx.sh除ubuntu/debian系统外其他系统未安装相应依赖



nginx.sh 使用方法：

     wget -O /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24


ModSecurity-nginx.sh 基于nginx.sh添加了ModSecurity防火墙（ OWASP CRS ），根据官方文档添加，模块是直接编译进去的非动态模块

文件路径：/www/server/nginx/owasp

无需重复加载加载 Nginx ModSecurity 连接器，默认已经加载模块

ModSecurity-nginx.sh 使用方法：

     wget -O  /www/server/panel/install/nginx.sh https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/main/ModSecurity-nginx.sh -T 20 && bash /www/server/panel/install/nginx.sh install 1.24


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
