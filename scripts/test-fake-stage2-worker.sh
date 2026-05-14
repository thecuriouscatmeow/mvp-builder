#!/bin/bash
# test-fake-stage2-worker.sh — test fake for stage 2 (wireframe) worker
#
# Usage: test-fake-stage2-worker.sh <project-dir> <page-slug>
#
# Writes a minimal valid HTML file with "Lorem ipsum" to
# <project-dir>/docs/02-wireframes/<page-slug>.html and exits 0.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: test-fake-stage2-worker.sh <project-dir> <page-slug>" >&2
  exit 1
fi

project_dir="$1"
page_slug="$2"

# Ensure docs/02-wireframes dir exists
mkdir -p "$project_dir/docs/02-wireframes"

# Write minimal HTML with Lorem ipsum
output_file="$project_dir/docs/02-wireframes/${page_slug}.html"
cat > "$output_file" <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Lorem ipsum</title>
  <style>
    body { margin: 0; font-family: sans-serif; }
    main { max-width: 1200px; margin: 0 auto; padding: 24px; }
    section { margin: 48px 0; }
  </style>
</head>
<body>
  <header>
    <nav>
      <a href="#">Lorem ipsum</a>
    </nav>
  </header>
  <main>
    <section>
      <h1>Lorem ipsum dolor sit amet</h1>
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
    </section>
  </main>
  <footer>
    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
  </footer>
</body>
</html>
EOF

exit 0
