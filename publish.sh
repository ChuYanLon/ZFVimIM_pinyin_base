#!/bin/bash
set -e
git pull
script_dir=$(dirname "$(readlink -f "$0")")
cache_dir="$script_dir/.cache"

mkdir -p "$cache_dir"

rm -f "$cache_dir"/old_sorted.txt "$cache_dir"/new_sorted.txt "$cache_dir"/temp_diff.txt

old_file="misc/pinyin.txt"
new_file="new_pinyin.txt"

if [ ! -f "$old_file" ]; then
  echo "错误: 文件 '$old_file' 不存在"
  exit 1
fi

if [ ! -f "$new_file" ]; then
  echo "错误: 文件 '$new_file' 不存在"
  exit 1
fi

OS=$(uname -s)
if [ "$OS" = "Linux" ]; then
  sed -i "s/\r//" "$new_file"
elif [ "$OS" = "Darwin" ]; then
  sed -i '' "s/\r//" "$new_file"
else
  echo "$OS 暂不支持.."
fi

timestamp=$(date +"%Y%m%d_%H%M%S")
output_file="$script_dir/diff_$timestamp.txt"

sort "$old_file" | grep -v '^$' >"$cache_dir"/old_sorted.txt
sort "$new_file" | grep -v '^$' >"$cache_dir"/new_sorted.txt

comm -13 "$cache_dir"/old_sorted.txt "$cache_dir"/new_sorted.txt >"$cache_dir"/temp_diff.txt

if [ -f "$cache_dir"/temp_diff.txt ] && [ -s "$cache_dir"/temp_diff.txt ]; then
  cp "$cache_dir"/temp_diff.txt "$output_file"
  diff_count=$(wc -l <"$output_file" | tr -d ' ')
  echo "新旧词库共 ${diff_count} 行差异内容"
  cat "$output_file" >>"$old_file"
  echo "词库更新完成"
  rm -f "$output_file"
  echo "缓存文件清除完成"
  git add ./misc/pinyin.txt
  git commit -m "update 词库"
  git push
  git checkout ./new_pinyin.txt
  git pull
else
  echo "两个文件内容相同，没有差异"
fi

rm -f "$cache_dir"/old_sorted.txt "$cache_dir"/new_sorted.txt "$cache_dir"/temp_diff.txt
