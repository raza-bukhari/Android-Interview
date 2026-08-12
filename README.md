# The Staff Android Interview

A book-length interview preparation guide for **Staff, Senior Staff, Principal and Mobile Architect**
level Android engineers — 30 parts, 179 chapters, 18 mobile system designs, ~400 rapid-fire questions,
12 mock interview loops, and roughly 120 good-vs-bad code comparisons.

It is a single self-contained static page: no build tooling, no dependencies, no tracking.

## Repository layout

```
src/            Source fragments — one file per part, plus shell and scripts
  00-head.html    <title>, theme bootstrap, stylesheet, sidebar markup
  01-front.html   Contents, competency matrix, study roadmap
  p01..p30.html   Parts I–XXX
  99-tail.html    All runtime JavaScript
build.ps1       Assembles both build targets
serve.ps1       Tiny local static server for previewing (http://localhost:8099)
public/         Build output — the directory Vercel serves
index.html      Build output — Claude Artifact fragment (no <head> wrapper)
vercel.json     Hosting config: caching and security headers
```

**Edit `src/`, never the generated files.** Both outputs are overwritten on every build.

## Build

```bash
powershell -File build.ps1
```

Produces two targets from the same source:

| Target | Purpose |
|---|---|
| `public/index.html` | Standalone document for static hosting. Full `<head>`, minified, lazy mermaid loader. |
| `index.html` | Fragment for the Claude Artifact platform, which supplies its own `<head>` and renders mermaid natively. |

## Local preview

```bash
powershell -File serve.ps1
```

Then open <http://localhost:8099/public/index.html>.

## Deploying to Vercel

The project is static with no build step Vercel needs to run.

1. Push this repository to GitHub.
2. In Vercel, **Add New → Project** and import the repository.
3. Framework preset: **Other**. Build command: leave empty. Output directory: `public`
   (already set in `vercel.json`, so the defaults should be correct).
4. Deploy.

Re-deploys happen automatically on push. Because `public/index.html` is generated,
**run the build and commit the output before pushing** — Vercel does not run PowerShell.

## Design notes

**Why one file.** The whole book ships in a single ~636 KB document (~206 KB gzipped, less over
Brotli). That is a deliberate trade: one request, then every one of the 179 chapters is instant and
works offline, with no navigation waterfall. Splitting into per-part files would cut first load to
roughly 15 KB but add a network round trip to every chapter and break offline reading. If the site
is ever used primarily on slow connections for a single chapter at a time, that trade flips.

**Runtime work is deferred.** Syntax highlighting decorates the visible page first and fills in the
remaining 32 pages during `requestIdleCallback`. The search index is built on first use rather than
at load.

**Syntax highlighting** is a small inlined tokeniser using Android Studio's own token colours —
Darcula in dark, IntelliJ Light in light. There is no highlighting library. Language is detected per
block (Kotlin, XML, shell, JSON) and can be forced with `data-lang` on the `<pre>`.

**The one external request** is mermaid, loaded from jsDelivr only on the six pages that contain a
diagram, and only in the hosted build. If the CDN is unreachable the diagrams stay readable as text.
To remove the dependency entirely, pre-render the diagrams to inline SVG and drop the loader.

**Accessibility.** Semantics carry the meaning: visible focus rings, `prefers-reduced-motion`
honoured, both colour schemes designed rather than inverted, and tables that stack instead of
scrolling on narrow screens.

## Keyboard

| Key | Action |
|---|---|
| `/` | Focus search |
| `↑` `↓` | Move through results |
| `Enter` | Open the selected result |
| `Esc` | Clear search |
