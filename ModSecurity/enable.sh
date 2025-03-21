#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: 请以以root用户运行."
  exit 1
fi

# 创建目标文件夹（如果不存在）
#mkdir -p /www/server/nginx/owasp/owasp-rules/plugins

echo "Downloading WordPress 规则排除插件"
# 下载 wordpress-rule-exclusions-before.conf 和 wordpress-rule-exclusions-config.conf 文件
wget -q -O /www/server/nginx/owasp/owasp-rules/plugins/wordpress-rule-exclusions-before.conf "https://raw.githubusercontent.com/coreruleset/wordpress-rule-exclusions-plugin/refs/heads/master/plugins/wordpress-rule-exclusions-before.conf"
wget -q -O /www/server/nginx/owasp/owasp-rules/plugins/wordpress-rule-exclusions-config.conf "https://raw.githubusercontent.com/coreruleset/wordpress-rule-exclusions-plugin/refs/heads/master/plugins/wordpress-rule-exclusions-config.conf"

# 下载 crs-setup.conf 文件并备份旧文件（如果存在）
echo "Downloading crs-setup.conf..."
if [ -f /www/server/nginx/owasp/owasp-rules/crs-setup.conf ]; then
  mv /www/server/nginx/owasp/owasp-rules/crs-setup.conf /www/server/nginx/owasp/owasp-rules/crs-setup.conf.bak  # 备份旧文件
fi
wget -q -O /www/server/nginx/owasp/owasp-rules/crs-setup.conf "https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/crs-setup.conf"

#
mv /www/server/nginx/owasp/owasp-rules/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example /www/server/nginx/owasp/owasp-rules/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
mv /www/server/nginx/owasp/owasp-rules/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example /www/server/nginx/owasp/owasp-rules/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# 下载 modsecurity.conf 文件并备份旧文件（如果存在）
echo "Downloading modsecurity.conf..."
if [ -f /www/server/nginx/owasp/ModSecurity/modsecurity.conf ]; then
  mv /www/server/nginx/owasp/ModSecurity/modsecurity.conf /www/server/nginx/owasp/ModSecurity/modsecurity.conf.bak  # 备份旧文件
fi
wget -q -O /www/server/nginx/owasp/ModSecurity/modsecurity.conf "https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/modsecurity.conf"

# 下载 hosts.deny 文件并备份旧文件（如果存在）
echo "Downloading modsecurity.conf..."
if [ -f /www/server/nginx/owasp/conf/hosts.deny ]; then
  mv /www/server/nginx/owasp/conf/hosts.deny /www/server/nginx/owasp/conf/hosts.deny.bak  # 备份旧文件
fi
wget -q -O /www/server/nginx/owasp/conf/hosts.deny "https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/hosts.deny"

# 下载 hosts.deny 文件并备份旧文件（如果存在）
echo "Downloading hosts.allow..."
if [ -f /www/server/nginx/owasp/conf/hosts.allow ]; then
  mv /www/server/nginx/owasp/conf/hosts.allow /www/server/nginx/owasp/conf/hosts.allow.bak  # 备份旧文件
fi
wget -q -O /www/server/nginx/owasp/conf/hosts.allow "https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/hosts.allow"

# 下载 hosts.deny 文件并备份旧文件（如果存在）
echo "Downloading main.conf..."
if [ -f /www/server/nginx/owasp/conf/main.conf ]; then
  mv /www/server/nginx/owasp/conf/main.conf /www/server/nginx/owasp/conf/main.conf.bak  # 备份旧文件
fi
wget -q -O /www/server/nginx/owasp/conf/main.conf "https://raw.githubusercontent.com/mzwrt/aapanel-6.8.37-backup/refs/heads/main/ModSecurity/main.conf"

echo " 规范文件权限"
chown -R root:root /www/server/nginx/owasp/conf/*.conf
chown -R root:root /www/server/nginx/owasp/owasp-rules/plugins/*.conf
chown -R root:root /www/server/nginx/owasp/owasp-rules/crs-setup.conf
chown -R root:root /www/server/nginx/owasp/ModSecurity/modsecurity.conf
chown -R root:root /www/server/nginx/owasp/conf/hosts.allow
chown -R root:root /www/server/nginx/owasp/conf/hosts.deny

chmod 600 /www/server/nginx/owasp/conf/*.conf
chmod 600 /www/server/nginx/owasp/owasp-rules/plugins/*.conf
chmod 600 /www/server/nginx/owasp/owasp-rules/crs-setup.conf
chmod 600 /www/server/nginx/owasp/ModSecurity/modsecurity.conf
chmod 600 /www/server/nginx/owasp/owasp-rules/crs-setup.conf.bak
chmod 600 /www/server/nginx/owasp/ModSecurity/modsecurity.conf.bak
chmod 600 /www/server/nginx/owasp/conf/main.conf.bak
chmod 600 /www/server/nginx/owasp/conf/hosts.allow
chmod 600 /www/server/nginx/owasp/conf/hosts.deny

# 完成
echo "============================================================================================="
echo "Downloading WordPress 规则排除插件"
echo "WordPress 规则排除插件，默认：不启用"
echo "可以修改/www/server/nginx/owasp/conf/main.conf文件最底部删除wordpress-rule-exclusions-before.conf和wordpress-rule-exclusions-config.conf文件前面的#号"
echo "文件路径：/www/server/nginx/owasp/owasp-rules/plugins/wordpress-rule-exclusions-before.conf"
echo "文件路径：/www/server/nginx/owasp/owasp-rules/plugins/wordpress-rule-exclusions-config.conf"
echo "仓库地址：https://github.com/coreruleset/wordpress-rule-exclusions-plugin"
echo "============================================================================================="

echo "默认级别：3 清修改级别后再用，建议使用2减少误报，3是生产环境最安全级别，但是误报风险增加"
echo "默认阻拦响应代码为：403"
echo "crs-setup.conf是规则控制文件。里面包含控制规则一些设置，就是防火墙规则配置的主要文件"
echo "文件路径：/www/server/nginx/owasp/owasp-rules/crs-setup.conf"
echo "仓库地址：https://github.com/coreruleset/coreruleset/releases"
echo "============================================================================================="

echo "这个可以不用修改，默认日志文件路径/www/wwwlogs/owasp/"
echo "文件路径：/www/server/nginx/owasp/ModSecurity/modsecurity.conf"
echo "============================================================================================="

echo "hosts.deny是设置黑名单IP的文件里面有详细解释，请仔细阅读"
echo "文件路径：/www/server/nginx/owasp/conf/hosts.deny"
echo "============================================================================================="

echo "hosts.deny是设置白名单IP的文件里面有详细解释，请仔细阅读"
echo "文件路径：/www/server/nginx/owasp/conf/hosts.allow"
echo "============================================================================================="

echo "main.conf是引入modsecurity规则集的文件，就是/www/server/nginx/owasp/owasp-rules里面的规则和插件"
echo "main.conf里面有详细解释请仔细阅读"
echo "【注意】默认WordPress 规则排除插件是注释掉的，在最底部。如果使用请删除注释"
echo "文件路径：/www/server/nginx/owasp/conf/main.conf"
echo "============================================================================================="
echo "【注意】默认有文件会备份上面所有的文件为XXX.bak防止误操作"
echo "如果你搭配我的ModSecurity-nginx.sh脚本会生成crs-setup.conf.bak main.conf.bak crs-setup.conf.bak 这三个文件可以删除"
echo "============================================================================================="
