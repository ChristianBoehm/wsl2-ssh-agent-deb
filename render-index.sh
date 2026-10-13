#!/usr/bin/env bash
# Render README.md to a standalone index.html for GitHub Pages (via GitHub's markdown API),
# optionally appending a file listing of the apt repository.
# Usage: ./render-index.sh README.md [repo-dir] > index.html      (needs gh, authenticated)
set -euo pipefail

README="${1:?README.md}"
REPO_DIR="${2:-}"
CONTEXT="${GITHUB_REPOSITORY:-ChristianBoehm/wsl2-ssh-agent-deb}"

human() { numfmt --to=iec-i --suffix=B --format='%.1f' "$1"; }

body=$(gh api markdown -f text="$(cat "$README")" -f mode=gfm -f context="$CONTEXT")

files=""
if [ -n "$REPO_DIR" ]; then
  rows=""
  while IFS= read -r f; do
    rel="${f#"$REPO_DIR"/}"
    rows+="<tr><td><a href=\"$rel\">$(basename "$rel")</a></td><td>$(human "$(stat -c %s "$f")")</td><td>$(date -u -r "$f" +%F)</td></tr>"$'\n'
  done < <(find "$REPO_DIR/pool" -name '*.deb' | sort -V -r)
  files="<h2>Files</h2>
<table><thead><tr><th>Package</th><th>Size</th><th>Date</th></tr></thead><tbody>
$rows</tbody></table>
<p><a href=\"dists/stable/InRelease\">InRelease</a> ·
<a href=\"dists/stable/main/binary-amd64/Packages\">Packages (amd64)</a> ·
<a href=\"dists/stable/main/binary-arm64/Packages\">Packages (arm64)</a> ·
<a href=\"KEY.asc\">KEY.asc</a> ·
<a href=\"install.sh\">install.sh</a></p>"
fi

cat <<EOF
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>wsl2-ssh-agent — Debian / Ubuntu packages</title>
<style>
  :root { color-scheme: light dark; --fg:#1f2328; --bg:#fff; --muted:#59636e; --border:#d1d9e0; --code:#f6f8fa; --link:#0969da; }
  @media (prefers-color-scheme: dark) { :root { --fg:#e6edf3; --bg:#0d1117; --muted:#9198a1; --border:#3d444d; --code:#151b23; --link:#4493f8; } }
  body { margin:0; background:var(--bg); color:var(--fg); font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif; }
  main { max-width:860px; margin:0 auto; padding:32px 20px 64px; }
  a { color:var(--link); text-decoration:none; } a:hover { text-decoration:underline; }
  h1,h2 { border-bottom:1px solid var(--border); padding-bottom:.3em; } h1 { margin-top:0; }
  code { background:var(--code); padding:.2em .4em; border-radius:6px; font-size:85%; }
  pre { background:var(--code); padding:16px; border-radius:6px; overflow:auto; }
  pre code { background:none; padding:0; font-size:85%; }
  table { border-collapse:collapse; width:100%; margin:16px 0; display:block; overflow:auto; }
  th,td { border:1px solid var(--border); padding:6px 13px; text-align:left; }
  details { margin:16px 0; } summary { cursor:pointer; font-weight:600; }
  img { max-width:100%; vertical-align:middle; }
  .markdown-heading .anchor { display:none; }
  footer { color:var(--muted); font-size:14px; margin-top:48px; }
</style>
</head>
<body>
<main>
$body
$files
<footer>Source: <a href="https://github.com/$CONTEXT">github.com/$CONTEXT</a></footer>
</main>
</body>
</html>
EOF
