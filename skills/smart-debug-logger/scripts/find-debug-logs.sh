#!/bin/bash

# 查找所有调试日志脚本

echo "🔍 查找项目中的所有调试日志..."
echo "================================"
echo ""

# 检查是否在项目目录中
if [ ! -d "src" ] && [ ! -d "lib" ] && [ ! -d "app" ]; then
    echo "⚠️  警告: 未找到常见的源代码目录 (src/lib/app)"
    echo "当前目录: $(pwd)"
    echo ""
    read -p "是否继续在当前目录搜索？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# 搜索目录（优先搜索常见的源码目录）
SEARCH_DIRS=()
[ -d "src" ] && SEARCH_DIRS+=("src")
[ -d "lib" ] && SEARCH_DIRS+=("lib")
[ -d "app" ] && SEARCH_DIRS+=("app")
[ -d "components" ] && SEARCH_DIRS+=("components")
[ -d "pages" ] && SEARCH_DIRS+=("pages")

# 如果没有找到常见目录，搜索当前目录
if [ ${#SEARCH_DIRS[@]} -eq 0 ]; then
    SEARCH_DIRS=(".")
fi

echo "搜索目录: ${SEARCH_DIRS[*]}"
echo ""

# 统计变量
total_logs=0
total_files=0

# JavaScript/TypeScript 日志
echo "📝 JavaScript/TypeScript 日志:"
echo "--------------------------------"
js_pattern="console\.(log|debug|info|warn|error)\(['\"][[][A-Z]+-[A-Z]+[]]"

for dir in "${SEARCH_DIRS[@]}"; do
    while IFS= read -r line; do
        echo "  $line"
        ((total_logs++))
    done < <(grep -rn --color=always -E "$js_pattern" "$dir" 2>/dev/null | grep -v node_modules | grep -v ".git")
done

# 统计文件数
js_files=$(grep -rl -E "$js_pattern" "${SEARCH_DIRS[@]}" 2>/dev/null | grep -v node_modules | grep -v ".git" | wc -l)
total_files=$((total_files + js_files))

echo ""

# Python 日志
if grep -rq "print.*\[.*-.*\]" "${SEARCH_DIRS[@]}" 2>/dev/null; then
    echo "🐍 Python 日志:"
    echo "--------------------------------"
    py_pattern="print.*[[(]['\"][[][A-Z]+-[A-Z]+[]]"

    for dir in "${SEARCH_DIRS[@]}"; do
        while IFS= read -r line; do
            echo "  $line"
            ((total_logs++))
        done < <(grep -rn --color=always -E "$py_pattern" "$dir" 2>/dev/null | grep -v ".git")
    done

    py_files=$(grep -rl -E "$py_pattern" "${SEARCH_DIRS[@]}" 2>/dev/null | grep -v ".git" | wc -l)
    total_files=$((total_files + py_files))
    echo ""
fi

# Java 日志
if grep -rq "System\.out\.println.*\[.*-.*\]" "${SEARCH_DIRS[@]}" 2>/dev/null; then
    echo "☕ Java 日志:"
    echo "--------------------------------"
    java_pattern="System\.out\.println.*[[(]['\"][[][A-Z]+-[A-Z]+[]]"

    for dir in "${SEARCH_DIRS[@]}"; do
        while IFS= read -r line; do
            echo "  $line"
            ((total_logs++))
        done < <(grep -rn --color=always -E "$java_pattern" "$dir" 2>/dev/null | grep -v ".git")
    done

    java_files=$(grep -rl -E "$java_pattern" "${SEARCH_DIRS[@]}" 2>/dev/null | grep -v ".git" | wc -l)
    total_files=$((total_files + java_files))
    echo ""
fi

# 汇总
echo "================================"
echo "📊 汇总统计:"
echo "  共找到 $total_logs 条调试日志"
echo "  涉及 $total_files 个文件"
echo ""

# 按前缀分类统计
echo "🏷️  前缀分类:"
echo "--------------------------------"

for dir in "${SEARCH_DIRS[@]}"; do
    grep -roh -E "\[[A-Z]+-[A-Z]+\]" "$dir" 2>/dev/null | sort | uniq -c | sort -rn | while read count prefix; do
        printf "  %-20s %3d 次\n" "$prefix" "$count"
    done
done

echo ""
echo "💡 提示："
echo "  - 使用 ./scripts/remove-debug-logs.sh 清理所有调试日志"
echo "  - 或告诉 Claude: '请清理所有调试日志'"
