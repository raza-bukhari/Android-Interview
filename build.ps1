<#
  Builds two targets from src/*.html:

    index.html          Artifact fragment. No <head> — the Claude Artifact
                        platform supplies the document wrapper and renders
                        mermaid natively. Unminified, easy to diff.

    public/index.html   Standalone document for static hosting (Vercel).
                        Full <head>, minified, and a lazy mermaid loader
                        because a plain host has no mermaid runtime.
#>

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'src'
$root = $PSScriptRoot

# ---------------------------------------------------------------- assemble
$order = @('00-head.html', '01-front.html')
1..35 | ForEach-Object { $order += ('p{0:d2}.html' -f $_) }
$order += '99-tail.html'

$sb = New-Object System.Text.StringBuilder
$missing = @()
foreach ($f in $order) {
    $p = Join-Path $src $f
    if (Test-Path $p) { [void]$sb.AppendLine((Get-Content -Raw -Encoding UTF8 $p)) }
    else { $missing += $f }
}
$fragment = $sb.ToString()

$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText((Join-Path $root 'index.html'), $fragment, $utf8)

# ---------------------------------------------------------------- helpers
function Protect-Regions {
    param([string]$html, [ref]$storeRef)
    $store = @()
    # <pre> and <script> are whitespace/newline significant — never minify them.
    $rx = [regex]'(?s)<pre\b.*?</pre>|<script\b.*?</script>'
    $out = $rx.Replace($html, {
        param($m)
        $script:tmp = $m.Value
        $i = $script:protectIndex
        $script:protected += , $m.Value
        $script:protectIndex++
        "`u{E000}$i`u{E001}"
    })
    return $out
}

function Compress-Css {
    param([string]$css)
    $css = [regex]::Replace($css, '(?s)/\*.*?\*/', '')          # comments
    $css = [regex]::Replace($css, '\s*\r?\n\s*', ' ')            # line breaks + indent
    $css = [regex]::Replace($css, '\s{2,}', ' ')                 # runs of spaces
    $css = [regex]::Replace($css, '\s*([{};,])\s*', '$1')        # around delimiters
    $css = [regex]::Replace($css, ';}', '}')                     # trailing semicolons
    return $css.Trim()
}

# ---------------------------------------------------------------- split head/body
$styleEnd = $fragment.IndexOf('</style>')
if ($styleEnd -lt 0) { throw 'could not locate </style> in the assembled fragment' }
$headPart = $fragment.Substring(0, $styleEnd + 8)
$bodyPart = $fragment.Substring($styleEnd + 8)

$titleRx = [regex]'(?s)<title>(.*?)</title>'
$title = $titleRx.Match($headPart).Groups[1].Value
$headPart = $titleRx.Replace($headPart, '', 1)

# minify the stylesheet
$headPart = [regex]::Replace($headPart, '(?s)(<style>)(.*?)(</style>)', {
    param($m) $m.Groups[1].Value + (Compress-Css $m.Groups[2].Value) + $m.Groups[3].Value
})

# ---------------------------------------------------------------- minify body
$script:protected = @()
$script:protectIndex = 0
$bodyMin = Protect-Regions $bodyPart ([ref]$script:protected)
$bodyMin = [regex]::Replace($bodyMin, '(?m)^[ \t]+', '')      # leading indentation
$bodyMin = [regex]::Replace($bodyMin, '(?m)^\s*\r?\n', '')    # blank lines
for ($i = $script:protected.Count - 1; $i -ge 0; $i--) {
    $bodyMin = $bodyMin.Replace("`u{E000}$i`u{E001}", $script:protected[$i])
}

# same treatment for the head fragment (outside <style>, which is already done)
$script:protected = @()
$script:protectIndex = 0
$headMin = Protect-Regions $headPart ([ref]$script:protected)
$headMin = [regex]::Replace($headMin, '(?m)^[ \t]+', '')
$headMin = [regex]::Replace($headMin, '(?m)^\s*\r?\n', '')
for ($i = $script:protected.Count - 1; $i -ge 0; $i--) {
    $headMin = $headMin.Replace("`u{E000}$i`u{E001}", $script:protected[$i])
}

# ---------------------------------------------------------------- standalone document
$desc = 'A book-length interview preparation guide for Staff, Principal and Mobile Architect level Android engineers: 31 parts, 190 chapters, 18 mobile system designs, graded answers, mock loops and an Android best-practice catalogue.'
$icon = 'data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 100 100%27%3E%3Ctext y=%27.9em%27 font-size=%2790%27%3E%F0%9F%A4%96%3C/text%3E%3C/svg%3E'

$mermaidLoader = @'
<script>
/* The artifact platform renders mermaid natively; a static host does not.
   Loaded on demand, only for pages that actually contain a diagram. */
(function () {
  var lib = null;
  function theme() {
    var a = document.documentElement.getAttribute('data-theme');
    if (!a) a = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    return a === 'dark' ? 'dark' : 'neutral';
  }
  function render() {
    var nodes = [].slice.call(document.querySelectorAll('.page.on pre.mermaid'))
      .filter(function (n) { return !n.dataset.rendered; });
    if (!nodes.length) return;
    nodes.forEach(function (n) { if (!n.dataset.src) n.dataset.src = n.textContent; });
    var go = function (m) {
      lib = m;
      m.initialize({ startOnLoad: false, securityLevel: 'strict', theme: theme() });
      nodes.forEach(function (n) { n.dataset.rendered = '1'; });
      try { m.run({ nodes: nodes }); } catch (e) {}
    };
    if (lib) { go(lib); return; }
    import('https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs')
      .then(function (mod) { go(mod.default); })
      .catch(function () { /* diagrams stay readable as text */ });
  }
  function reset() {
    document.querySelectorAll('pre.mermaid[data-rendered]').forEach(function (n) {
      n.removeAttribute('data-rendered');
      n.removeAttribute('data-processed');
      if (n.dataset.src) n.textContent = n.dataset.src;
    });
    render();
  }
  window.addEventListener('hashchange', function () { setTimeout(render, 60); });
  document.addEventListener('click', function (e) {
    if (e.target.closest && e.target.closest('[data-p]')) setTimeout(render, 60);
    if (e.target.id === 'themebtn') setTimeout(reset, 60);
  });
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', reset);
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', render);
  else render();
})();
</script>
'@

$standalone = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<meta name="description" content="$desc">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#F3F4F8" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#0D131E" media="(prefers-color-scheme: dark)">
<link rel="icon" href="$icon">
<meta property="og:type" content="website">
<meta property="og:title" content="$title">
<meta property="og:description" content="$desc">
<meta name="twitter:card" content="summary">
$headMin
</head>
<body>
$bodyMin
$mermaidLoader
</body>
</html>
"@

$pub = Join-Path $root 'public'
New-Item -ItemType Directory -Force -Path $pub | Out-Null
[System.IO.File]::WriteAllText((Join-Path $pub 'index.html'), $standalone, $utf8)

# ---------------------------------------------------------------- report
function Get-GzipSize($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $ms = New-Object System.IO.MemoryStream
    $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionLevel]::Optimal, $true)
    $gz.Write($bytes, 0, $bytes.Length); $gz.Dispose()
    $len = $ms.Length; $ms.Dispose(); return $len
}
$a = (Get-Item (Join-Path $root 'index.html')).Length
$b = (Get-Item (Join-Path $pub 'index.html')).Length
$bg = Get-GzipSize (Join-Path $pub 'index.html')
Write-Output ("artifact  index.html        {0,7:N1} KB" -f ($a / 1KB))
Write-Output ("web       public/index.html {0,7:N1} KB   gzip {1,6:N1} KB" -f ($b / 1KB), ($bg / 1KB))
if ($missing.Count -gt 0) { Write-Output ("missing: " + ($missing -join ', ')) }
