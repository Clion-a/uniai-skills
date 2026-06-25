#!/usr/bin/env bash
# render.sh — 把 .docx/.pptx/.xlsx/.pdf 渲染成 PDF + 逐页 PNG,供「render→看图→改→重渲」视觉验证。
#   有 pdftoppm(poppler)→ 逐页 PNG(page-1.png…);否则退回 LibreOffice 首页 PNG(单页/快速自查)。
#
# 用法:  bash render.sh <input-file> [out-dir]
set -euo pipefail

IN="${1:?用法: render.sh <input-file> [out-dir]}"
OUTDIR="${2:-$(cd "$(dirname "$IN")" && pwd)/_render}"
BASE="$(basename "${IN%.*}")"

resolve_soffice() {
  if [ -n "${UNIAI_SOFFICE_BIN:-}" ] && [ -x "${UNIAI_SOFFICE_BIN}" ]; then echo "$UNIAI_SOFFICE_BIN"; return; fi
  command -v soffice >/dev/null 2>&1 && { command -v soffice; return; }
  for c in \
    "$(dirname "$0")/../../../../../../../desktop/src-tauri/libreoffice/LibreOffice.app/Contents/MacOS/soffice" \
    "$HOME/Ai/uniai-all/codex-app/desktop/src-tauri/libreoffice/LibreOffice.app/Contents/MacOS/soffice" \
    "/Applications/LibreOffice.app/Contents/MacOS/soffice"; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  return 1
}

mkdir -p "$OUTDIR"
OUTDIR="$(cd "$OUTDIR" && pwd)"   # 转绝对路径:相对 outdir 会让 -env:UserInstallation=file://$PROFILE 成为非法相对 URL → soffice 卡死
PROFILE="$OUTDIR/.louser"; mkdir -p "$PROFILE"

# 1) → PDF(最终视觉验证以 PDF 为准,任意页数)。输入若已是 PDF 则直接用。
if [ "${IN##*.}" = "pdf" ]; then
  PDF="$IN"
else
  SOFFICE="$(resolve_soffice)" || { echo "ERROR: 找不到 LibreOffice(soffice);请设 UNIAI_SOFFICE_BIN。" >&2; exit 2; }
  "$SOFFICE" --headless "-env:UserInstallation=file://$PROFILE" --convert-to pdf --outdir "$OUTDIR" "$IN" >/dev/null 2>&1
  PDF="$OUTDIR/$BASE.pdf"
fi

# 2) → 逐页 PNG:优先 pdftoppm(poppler),否则 LibreOffice 首页 PNG。
PDFTOPPM="${UNIAI_POPPLER_BIN:-}"; [ -z "$PDFTOPPM" ] && PDFTOPPM="$(command -v pdftoppm || true)"
if [ -n "$PDFTOPPM" ] && [ -f "$PDF" ]; then
  "$PDFTOPPM" -png -r 110 "$PDF" "$OUTDIR/page" >/dev/null 2>&1 || true
  echo "已渲染: $PDF + 逐页 PNG($OUTDIR/page-*.png)"
else
  SOFFICE="${SOFFICE:-$(resolve_soffice || true)}"
  [ -n "$SOFFICE" ] && "$SOFFICE" --headless "-env:UserInstallation=file://$PROFILE" --convert-to png --outdir "$OUTDIR" "$IN" >/dev/null 2>&1 || true
  echo "已渲染: $PDF + 首页 PNG(多页逐页 PNG 需 poppler/pdftoppm;否则用 PDF 做全文/全 deck 视觉验证)"
fi
ls -1 "$OUTDIR"/*.pdf "$OUTDIR"/*.png "$OUTDIR"/page-*.png 2>/dev/null | sort -u || true
