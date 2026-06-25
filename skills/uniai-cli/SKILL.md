---
name: uniai-cli
description: Call UniAI platform AI features from the terminal with the `uniai` CLI — text chat, image generation & editing, video generation, text-to-speech (TTS) and speech recognition (STT), OCR, web search, code generation, and credit-balance checks. Use whenever the user wants to create an image or video, synthesize or transcribe speech, read text out of an image, search the web for current information, generate code, chat with a model, or check their UniAI credits — and the `uniai` command is available on PATH.
---

# UniAI CLI

The `uniai` command calls UniAI platform AI features directly from the terminal. Every command
accepts `--json` and returns a structured envelope, so prefer `--json` and read the fields
(`ok`, `text`, `url`, `credits`, `error`) instead of scraping prose.

## When to use this skill

Reach for `uniai` when the user wants any of: an image, a video, speech audio (TTS), a transcript
of audio (STT), text read out of an image (OCR), a web search for up-to-date information, generated
code, a quick model chat, or their credit balance — and `uniai` is installed.

## Prerequisites

- `uniai --version` must succeed. If it is missing, install with `npm i -g @uniai/cli` (npm only;
  do not use pnpm/yarn for this), or have the user read the package's `install.md`.
- Auth: needs a UniAI Personal Access Token (PAT, starts with `uap_`). Probe with `uniai auth status`
  (prints a masked token). If it is not configured, handle login **right here in the conversation** —
  do not send the user off to a separate terminal: (1) tell them to create a PAT at
  <https://www.uniai.ai> → Personal Center → Security tab → Personal Access Tokens → Generate; (2) ask them to paste it into the chat;
  (3) run `uniai auth login --token <pasted_pat>` yourself via your shell/terminal tool. Security:
  never echo the token back in your prose replies — confirm success only with the masked value from
  `uniai auth status`.
- Before a paid generation (image/video/speech), you may check budget first with
  `uniai usage --json` and read `credits.total`.

## Commands

```bash
uniai chat "<message>" --json
uniai image generate "<prompt>" [--size 1024x1024|1280x720|720x1280] [--download out.png] --json
uniai image edit --image <url> [--output-format png|jpg|webp] [--download out.png] --json
uniai video generate "<prompt>" [--aspect-ratio 16:9|9:16|1:1] [--duration 5|10] [--download out.mp4] --json
uniai speech synthesize "<text>" [--voice <id>] [--format mp3|wav] [--download out.mp3] --json
uniai speech recognize <audio: path|url> [--language auto|zh|en|ja|ko] --json
uniai ocr <image: path|url> --json
uniai search "<query>" [--limit 1-20] --json
uniai code "<description>" --language <python|typescript|...> --json
uniai usage --json            # credit balance (alias: uniai quota)
```

For media commands, pass `--download <file>` to save the result locally; report the saved path to
the user. Run `uniai <command> --help` for the full options of any single command.

## Output contract

- success: `{"ok":true,"text":"...","url":"<media url, when applicable>"}`
- failure: `{"ok":false,"error":"..."}`
- exit codes: `0` success · `1` runtime / auth / network error · `2` invalid usage

On `out of credits`, tell the user to top up in the UniAI web console. On an auth failure, have them
re-run `uniai auth login --token uap_...`. On a forbidden/scope error for `usage`, the PAT needs the
`read:credits` scope.
