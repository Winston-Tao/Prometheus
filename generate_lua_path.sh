#!/bin/bash

# 定义输出文件
output_file="allpath.conf"

# 初始化已有配置
default_paths=(
    "root..\"service/?.lua;\""
    "root..\"test/?.lua;\""
    "root..\"slg_server/service/?.lua;\""
    "root..\"test/?/init.lua;\""
)

# 初始化配置写入
echo "luaservice = " > "$output_file"

# 写入已有的目录
for path in "${default_paths[@]}"; do
    echo -n "$path" >> "$output_file"
done

# 扫描当前目录及子目录并格式化为 Lua 格式路径
find "$(pwd)" -type d | while read -r dir; do
    # 获取相对路径
    relative_path=$(realpath --relative-to="$(pwd)" "$dir")
    # 将目录转换为 Lua 格式路径
    lua_path="root..\"$relative_path/?.lua;\""
    echo -n "$lua_path" >> "$output_file"
done

# 去掉最后的多余分号
sed -i '' 's/;$//g' "$output_file"

# 输出完成信息
echo "生成完成：$output_file"
