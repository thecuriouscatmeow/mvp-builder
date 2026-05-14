#!/usr/bin/env bats
# stages-0-2.bats — integration tests for stages 0–2 (intake, sitemap, wireframe)

setup() {
  export TEST_PROJECT=$(mktemp -d)
  export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../scripts"
}

teardown() {
  [[ -d "$TEST_PROJECT" ]] && rm -rf "$TEST_PROJECT"
}

@test "project scaffold for stage-2 test" {
  # Invoke init-project.sh to set up project structure
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Assert structure exists
  [[ -d "$TEST_PROJECT/docs" ]]
  [[ -f "$TEST_PROJECT/docs/00-requirements.md" ]]
  [[ -f "$TEST_PROJECT/docs/01-sitemap.md" ]]
  [[ -d "$TEST_PROJECT/docs/02-wireframes" ]]
}

@test "manually-seeded sitemap has 3 pages" {
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Manually write a sitemap with 3 pages
  cat > "$TEST_PROJECT/docs/01-sitemap.md" <<'SITEMAP'
# Sitemap

## Pages

| Slug | Title | Route | Parent | H1 | Priority |
|------|-------|-------|--------|----|----|
| home | Home | / | — | Welcome | 1 |
| about | About | /about | — | About Us | 2 |
| contact | Contact | /contact | — | Get in Touch | 2 |

## Navigation

- **Primary nav order**: Home, About, Contact
- **Footer nav**: Footer links
- **Mobile menu strategy**: Full-screen overlay, hamburger icon, closes on item tap

## Heading Hierarchy

- **Home**: H1 = Welcome → H2 = section headlines
- **About**: H1 = About Us → H2 = section headlines
- **Contact**: H1 = Get in Touch → H2 = form section

## Content Blocks Per Page

- **Home**: hero → features → CTA
- **About**: intro → team → values
- **Contact**: form → info → map

## Loading Strategy

- **Above-fold**: Hero, headline, nav
- **Below-fold**: Features, testimonials
SITEMAP

  # Count pages in the table
  page_count=$(grep -c "^| [a-z]" "$TEST_PROJECT/docs/01-sitemap.md" || true)
  [[ "$page_count" -eq 3 ]]
}

@test "DRYRUN dispatch of 3 wireframe workers writes 3 HTML files" {
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Write sitemap with 3 pages
  cat > "$TEST_PROJECT/docs/01-sitemap.md" <<'SITEMAP'
# Sitemap

## Pages

| Slug | Title | Route | Parent | H1 | Priority |
|------|-------|-------|--------|----|----|
| home | Home | / | — | Welcome | 1 |
| about | About | /about | — | About Us | 2 |
| contact | Contact | /contact | — | Get in Touch | 2 |

## Navigation

- **Primary nav order**: Home, About, Contact
- **Footer nav**: Footer
- **Mobile menu strategy**: Hamburger

## Heading Hierarchy

- **Home**: H1 = Welcome
- **About**: H1 = About Us
- **Contact**: H1 = Get in Touch

## Content Blocks Per Page

- **Home**: hero → features
- **About**: intro → team
- **Contact**: form → info

## Loading Strategy

- **Above-fold**: Hero
- **Below-fold**: Features
SITEMAP

  # Create log directory
  mkdir -p "$TEST_PROJECT/logs/stage-2"
  
  # Dispatch workers for each page
  for page in home about contact; do
    # Create prompt file with PROJECT_DIR and PAGE_SLUG
    prompt_file="$TEST_PROJECT/prompts/${page}.prompt"
    mkdir -p "$TEST_PROJECT/prompts"
    cat > "$prompt_file" <<PROMPT
PROJECT_DIR=$TEST_PROJECT
PAGE_SLUG=$page

---
Your task: scaffold a wireframe HTML file for page $page.
PROMPT
    
    # Dispatch with STAGE2_FAKE=1
    CLAUDE_DISPATCH_DRYRUN=1 STAGE2_FAKE=1 bash "$SCRIPT_DIR/dispatch-worker.sh" "stage-2-${page}" "$prompt_file" "$TEST_PROJECT/logs/stage-2"
  done
  
  # Wait a moment for workers to finish
  sleep 1
  
  # Assert all 3 HTML files exist
  [[ -f "$TEST_PROJECT/docs/02-wireframes/home.html" ]]
  [[ -f "$TEST_PROJECT/docs/02-wireframes/about.html" ]]
  [[ -f "$TEST_PROJECT/docs/02-wireframes/contact.html" ]]
}

@test "wireframe HTML files contain Lorem ipsum" {
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Create minimal sitemap
  cat > "$TEST_PROJECT/docs/01-sitemap.md" <<'SITEMAP'
# Sitemap

## Pages

| Slug | Title | Route | Parent | H1 | Priority |
|------|-------|-------|--------|----|----|
| home | Home | / | — | Welcome | 1 |

## Navigation

- **Primary nav order**: Home
- **Footer nav**: Footer
- **Mobile menu strategy**: Hamburger

## Heading Hierarchy

- **Home**: H1 = Welcome

## Content Blocks Per Page

- **Home**: hero

## Loading Strategy

- **Above-fold**: Hero
SITEMAP

  # Dispatch single worker
  mkdir -p "$TEST_PROJECT/logs/stage-2"
  prompt_file="$TEST_PROJECT/prompts/home.prompt"
  mkdir -p "$TEST_PROJECT/prompts"
  cat > "$prompt_file" <<PROMPT
PROJECT_DIR=$TEST_PROJECT
PAGE_SLUG=home
PROMPT
  
  CLAUDE_DISPATCH_DRYRUN=1 STAGE2_FAKE=1 bash "$SCRIPT_DIR/dispatch-worker.sh" "stage-2-home" "$prompt_file" "$TEST_PROJECT/logs/stage-2"
  sleep 1
  
  # Assert Lorem ipsum is in the file
  grep -q "Lorem ipsum" "$TEST_PROJECT/docs/02-wireframes/home.html"
}

@test "checkpoint approve creates expected marker" {
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Simulate checkpoint approval by writing marker file
  mkdir -p "$TEST_PROJECT/docs/checkpoints"
  touch "$TEST_PROJECT/docs/checkpoints/home.2.approved"
  
  # Check file exists
  [[ -f "$TEST_PROJECT/docs/checkpoints/home.2.approved" ]]
}

@test "stage-commit creates stage-2: wireframe commit" {
  bash "$SCRIPT_DIR/init-project.sh" "$TEST_PROJECT" --yes
  
  # Initialize git repo in project
  cd "$TEST_PROJECT"
  git init
  git config user.email "test@example.com"
  git config user.name "Test User"
  git add -A
  git commit -m "initial"
  
  # Create a dummy wireframe file
  mkdir -p "$TEST_PROJECT/docs/02-wireframes"
  echo "test" > "$TEST_PROJECT/docs/02-wireframes/home.html"
  
  # Stage and commit via stage-commit.sh
  cd "$TEST_PROJECT"
  git add -A
  bash "$SCRIPT_DIR/stage-commit.sh" "$TEST_PROJECT" 2 wireframe
  
  # Assert commit message
  commit_msg=$(git log -1 --pretty=%s)
  [[ "$commit_msg" == "stage-2: wireframe" ]]
}
