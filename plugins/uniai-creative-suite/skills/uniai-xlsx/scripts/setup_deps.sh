#!/usr/bin/env bash
# setup_deps.sh — 在工作目录建 node_modules 软链,让 build 脚本能 `import "<lib>"`（ESM 不认 NODE_PATH）。
# 解析顺序:UNIAI_NODE_LIBS(打包态注入的库目录) → dev 仓库 pnpm store。
#
# 用法:  bash setup_deps.sh <work-dir> <lib>      (lib 如 docx / pptxgenjs / exceljs)
set -euo pipefail

WORKDIR="${1:?用法: setup_deps.sh <work-dir> <lib>}"
LIB="${2:?需指定库名,如 docx}"
mkdir -p "$WORKDIR"

# 候选:打包态把库铺在 UNIAI_NODE_LIBS;dev 在仓库 .pnpm/<lib>@*/node_modules(内含该库 + 其依赖)。
NM=""
if [ -n "${UNIAI_NODE_LIBS:-}" ]; then
  # UNIAI_NODE_LIBS 已注入(打包态 / 已跑 fetch-node-libs.sh 的 dev) = 权威库目录,库必须在此;不回退
  # 仓库扫描——避免注入失效时误扫他处缓存 node_modules(正是 creative-suite 要根除的「满盘找库」行为)。
  if [ -d "${UNIAI_NODE_LIBS}/$LIB" ]; then
    NM="$UNIAI_NODE_LIBS"
  else
    echo "ERROR: UNIAI_NODE_LIBS 已设($UNIAI_NODE_LIBS)但其中无 '$LIB';拒绝回退满盘扫描。请重打包或重跑 scripts/fetch-node-libs.sh。" >&2
    exit 2
  fi
else
  # UNIAI_NODE_LIBS 未注入(dev 未跑 fetch) → 回退仓库 pnpm store。
  for root in "$HOME/Ai/uniai-all" "$(cd "$(dirname "$0")/../../../../../../../.." 2>/dev/null && pwd)"; do
    cand="$(ls -d "$root"/node_modules/.pnpm/"$LIB"@*/node_modules 2>/dev/null | head -1)"
    [ -n "$cand" ] && { NM="$cand"; break; }
  done
fi

[ -z "$NM" ] && { echo "ERROR: 找不到 JS 库 '$LIB'。设 UNIAI_NODE_LIBS 指向含 $LIB 的库目录,或在 dev 仓库内运行。" >&2; exit 2; }

ln -sfn "$NM" "$WORKDIR/node_modules"
echo "linked: $WORKDIR/node_modules -> $NM"
[ -d "$WORKDIR/node_modules/$LIB" ] && echo "ok: import \"$LIB\" 可解析" || { echo "WARN: $WORKDIR/node_modules/$LIB 不存在" >&2; exit 3; }
