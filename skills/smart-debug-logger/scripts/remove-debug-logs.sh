#!/bin/bash

# 移除指定前缀的调试日志（带备份）
# 用法: ./scripts/remove-debug-logs.sh <PREFIX>
# 示例: ./scripts/remove-debug-logs.sh DEBUG-LOGIN

PREFIX="$1"

if [ -z "$PREFIX" ]; then
    echo "❌ 必须指定要清理的前缀"
    echo ""
    echo "用法: $0 <PREFIX>"
    echo "示例: $0 DEBUG-LOGIN"
    echo ""
    echo "💡 使用 ./scripts/find-debug-logs.sh 查看所有前缀"
    exit 1
fi

echo "🗑️  移除 [$PREFIX] 调试日志"
echo "================================"
echo ""

# 搜索目录
SEARCH_DIRS=()
[ -d "src" ] && SEARCH_DIRS+=("src")
[ -d "lib" ] && SEARCH_DIRS+=("lib")
[ -d "app" ] && SEARCH_DIRS+=("app")
[ -d "components" ] && SEARCH_DIRS+=("components")
[ -d "pages" ] && SEARCH_DIRS+=("pages")

if [ ${#SEARCH_DIRS[@]} -eq 0 ]; then
    SEARCH_DIRS=(".")
fi

echo "搜索目录: ${SEARCH_DIRS[*]}"
echo "目标前缀: [$PREFIX]"
echo ""

# 查找包含该前缀日志的文件
affected_files=()

for dir in "${SEARCH_DIRS[@]}"; do
    while IFS= read -r file; do
        [ -n "$file" ] && affected_files+=("$file")
    done < <(grep -rl "\[$PREFIX\]" "$dir" 2>/dev/null | grep -v node_modules | grep -v ".git")
done

# 去重
affected_files=($(printf '%s\n' "${affected_files[@]}" | sort -u))

if [ ${#affected_files[@]} -eq 0 ]; then
    echo "✅ 未找到任何 [$PREFIX] 调试日志"
    exit 0
fi

# 统计日志行数
total_logs=0
for file in "${affected_files[@]}"; do
    count=$(grep -c "\[$PREFIX\]" "$file" 2>/dev/null)
    total_logs=$((total_logs + count))
done

echo "📋 将要处理的文件 (${#affected_files[@]} 个, 共 $total_logs 条日志):"
for file in "${affected_files[@]}"; do
    count=$(grep -c "\[$PREFIX\]" "$file" 2>/dev/null)
    echo "  $file ($count 条)"
done
echo ""

# 确认
read -p "⚠️  确认删除 [$PREFIX] 日志吗？(y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 已取消"
    exit 0
fi

# 创建备份
backup_dir=".debug-logs-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

echo ""
echo "📦 创建备份到: $backup_dir"

for file in "${affected_files[@]}"; do
    backup_path="$backup_dir/$file"
    mkdir -p "$(dirname "$backup_path")"
    cp "$file" "$backup_path"
done

echo "✅ 备份完成"
echo ""

# 删除指定前缀的日志
echo "🔧 正在移除 [$PREFIX] 日志..."

removed_count=0

for file in "${affected_files[@]}"; do
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "/\[$PREFIX\]/d" "$file" 2>/dev/null
    else
        sed -i "/\[$PREFIX\]/d" "$file" 2>/dev/null
    fi

    echo "  ✓ $file"
    ((removed_count++))
done

echo ""
echo "================================"
echo "✅ 清理完成！"
echo ""
echo "📊 统计："
echo "  - 前缀: [$PREFIX]"
echo "  - 处理文件: $removed_count 个"
echo "  - 移除日志: $total_logs 条"
echo "  - 备份位置: $backup_dir"
echo ""
echo "💡 如需恢复，可以从备份目录复制文件"
echo ""

# 询问是否删除备份
read -p "是否保留备份文件？(Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    rm -rf "$backup_dir"
    echo "🗑️  已删除备份"
else
    echo "📦 备份已保留在: $backup_dir"
fi
