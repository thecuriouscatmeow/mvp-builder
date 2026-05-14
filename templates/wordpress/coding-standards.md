# Coding Standards

## PHP

- Escape all output using `esc_html()` for plain text, `esc_attr()` for HTML attributes, and `esc_url()` for URLs.
- Use `wp_kses_post()` for user-generated rich-text content.
- Use gettext functions (`__()`, `_e()`, `_x()`) for all user-facing strings; set text domain in `style.css`.
- Write HTML in template files, not in PHP functions. Functions return data; templates handle markup.
- Follow PSR-12 coding style (indentation, naming, formatting).
- Do not include closing `?>` tag at end of file.

## CSS

- Mobile-first approach: use `min-width` media queries to layer complexity, not `max-width`.
- Use CSS custom properties for design tokens (colors, spacing, typography); define in `:root`.
- Do not nest selectors more than one level deep (flat BEM-ish style).
- Avoid `!important` unless strictly necessary; if used, document the reason in a comment.
- Use consistent naming: component names, element suffixes (e.g., `.button__icon`), modifier prefixes (e.g., `.button--primary`).

## JavaScript

- Use vanilla ES modules; no jQuery.
- Defer-load scripts by default (`async` or `defer` attributes on enqueue).
- Never inline `<script>` tags in templates; use `wp_enqueue_script()` in `functions.php`.
- Prefer modern DOM APIs (`querySelector`, `addEventListener`, `fetch`).
- Use IIFE or modules to avoid global scope pollution.

## Theme Files

- **style.css**: Include complete WordPress theme header (Theme Name, Author, Version, Text Domain, etc.).
- **functions.php**: Keep thin; use only for enqueueing scripts, styles, and registering hooks. No closing tag.
- **Template parts**: Store reusable markup snippets in `template-parts/` subdirectory.
- **Block templates**: Store in `templates/` directory (block-based theme structure); use `template-parts/` for classic fallbacks if needed.
- Prefer block templates for new components; classic templates only if block isn't viable.

## Accessibility

- Use semantic HTML: `<button>`, `<nav>`, `<main>`, `<header>`, `<footer>`, etc.
- Enforce one `<h1>` per page; use `<h2>`–`<h6>` for subsections in hierarchical order.
- Include `alt` text on every image (`alt=""` only if decorative and hidden from screen readers).
- Include visible focus indicators on all interactive elements (min 2px, contrast ≥ 3:1 against background).
- Maintain color contrast ≥ 4.5:1 for body text, ≥ 3:1 for large text (18px+ or 14px+ bold).
