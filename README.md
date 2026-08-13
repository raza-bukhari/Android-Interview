# The Staff Android Interview

A book-length interview preparation guide for **Staff, Senior Staff, Principal and Mobile Architect**
level Android engineers — 35 parts, 241 chapters, 18 mobile system designs, ~400 rapid-fire questions,
60 graded greenfield build tasks, 120+ rapid-recall definitions, 12 mock interview loops, and 117
good-vs-bad code comparisons.

It is a single self-contained static page: no build tooling, no dependencies, no tracking.

**[Live Site](https://android-interview.vercel.app)** | **[GitHub Repository](https://github.com/raza-bukhari/Android-Interview)**

## Repository layout

```
src/            Source fragments — one file per part, plus shell and scripts
  00-head.html    <title>, theme bootstrap, stylesheet, sidebar markup
  01-front.html   Contents, competency matrix, study roadmap
  p01..p35.html   Parts I–XXXV
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

## Deployment

The site is deployed to Vercel and live at **[android-interview.vercel.app](https://android-interview.vercel.app)**.

### Automatic re-deploys

Re-deploys happen automatically on every push to the main branch.

### Before pushing changes

Because `public/index.html` is generated from `src/`, **always run the build and commit the output before pushing**:

```bash
powershell -File build.ps1
git add public/ index.html
git commit -m "Rebuild site"
git push
```

Vercel does not run PowerShell, so it cannot build the site itself.

## Design notes

**Why one file.** The whole book ships in a single ~868 KB document (~276 KB gzipped, less over
Brotli). That is a deliberate trade: one request, then every one of the 241 chapters is instant and
works offline, with no navigation waterfall. Splitting into per-part files would cut first load to
roughly 15 KB but add a network round trip to every chapter and break offline reading. If the site
is ever used primarily on slow connections for a single chapter at a time, that trade flips.

**Runtime work is deferred.** Syntax highlighting decorates the visible page first and fills in the
remaining 37 pages during `requestIdleCallback`. The search index is built on first use rather than
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
