#!/usr/bin/env bash
# 从 Polly/Config/Secrets.xcconfig 生成 Polly/Config/Generated.xcconfig。
#
# 为什么需要这一步：
#   Secrets.xcconfig 既要能被 shell `source` 加载到 Python/CLI 环境（用于
#   预处理脚本调用 Anthropic 网关），也要能被 Xcode build 系统读取注入 Info.plist。
#   两种格式不兼容：
#     - shell:    export KEY=VALUE     URL 直接含 //
#     - xcconfig: KEY = VALUE          URL 必须把 // 写成 /$()/  避免被当注释
#
#   本脚本读取 shell/xcconfig 任一格式，规整成 xcconfig 格式写到 Generated.xcconfig，
#   Xcode 通过 configFiles 引用后者。
#
# 用法：
#   ./scripts/sync-secrets.sh
#   修改 Secrets.xcconfig 后重新跑一次。
#   再 xcodegen generate（或 Xcode 直接 build）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/.."
SRC="$ROOT/Polly/Config/Secrets.xcconfig"
DST="$ROOT/Polly/Config/Generated.xcconfig"

if [ ! -f "$SRC" ]; then
  echo "ERROR: $SRC not found" >&2
  exit 1
fi

{
  echo "// Auto-generated from Secrets.xcconfig by scripts/sync-secrets.sh"
  echo "// DO NOT EDIT. Re-run sync-secrets.sh after changing Secrets.xcconfig."
  echo ""

  while IFS= read -r raw || [ -n "$raw" ]; do
    # 去掉前后空白
    line="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

    # 跳过空行 / // 注释 / # 注释
    [ -z "$line" ] && continue
    case "$line" in
      //*|\#*) continue ;;
    esac

    # 去掉 export 前缀
    case "$line" in
      "export "*) line="${line#export }" ;;
    esac

    # 必须包含 =
    case "$line" in
      *=*) ;;
      *) continue ;;
    esac

    key="$(printf '%s' "${line%%=*}" | sed -E 's/[[:space:]]+$//')"
    value="$(printf '%s' "${line#*=}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"

    # 去掉值两端引号（若有）
    case "$value" in
      \"*\"|\'*\')
        value="${value#?}"
        value="${value%?}"
        ;;
    esac

    # 把 // 替换成 /$()/  防止 xcconfig 把后续当注释
    value="$(printf '%s' "$value" | sed 's|//|/$()/|g')"

    printf '%s = %s\n' "$key" "$value"
  done < "$SRC"
} > "$DST"

echo "✓ Generated $DST"
