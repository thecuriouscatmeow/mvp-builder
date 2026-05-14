# Known Issues (WordPress)

Issues that the system carries between projects. Per-project issues live in `<project>/docs/99-known-issues.md`.

## MEDIUM — theme unit test data import skipped (Subplan 0.2)

**Symptom:** `setup-wordpress-env.sh` downloads `themeunittestdata.wordpress.xml` to `./tmp/` on the host, but `wp-env run cli wp import` runs inside the container where `./tmp/` isn't mounted. The import step silently no-ops with a yellow warning.

**Impact:** wp-env comes up with an empty WordPress install. Pages/posts/users from the standard theme-unit-test fixture are absent.

**Workaround:** Manual import per project — `docker cp tmp/themeunittestdata.wordpress.xml <container>:/tmp/ && wp-env run cli wp import /tmp/themeunittestdata.wordpress.xml --authors=create`.

**Real fix (deferred):** add `./tmp` to `.wp-env.json` mappings, OR have the script `docker cp` the file in before invoking `wp-env run cli`. Defer until a stage actually needs the fixture content — currently the build pipeline writes its own content, so fixture data is decorative.

**Severity rationale:** MEDIUM per §10 — does not block the pipeline; logged and noted.
