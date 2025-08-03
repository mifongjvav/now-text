#!/bin/bash

source NOWENGINE.sh || {
    echo "错误：无法正确引入引擎库" >&2
    exit 1
}

# 确保 levels 和 playerlevels 目录存在
mkdir -p ./levels ./playerlevels

# 检查 progress.cfg 文件是否存在，如果不存在则创建
touch ./levels/progress.cfg

# 设置一个陷阱，在脚本退出时自动删除所有临时文件
trap 'rm -f ./levels/temp.*' EXIT

# 主循环
main