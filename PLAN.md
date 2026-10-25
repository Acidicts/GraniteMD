# Plan

Legend: `[x]` done, `[~]` partial, `[ ]` todo.

### Hierarchy

- [~] Useful stuff
    - [~] Email Sending (only password-reset mailer + `ApplicationHelper#send_email` queue via `EmailMailer` done)
        - [ ] Codes
        - [ ] Workspace limits
        - [ ] Billing
            - [ ] Yearly renewal
            - [ ] Payment Failed

    - [ ] Plans (only `Workspace.feature_set` enum `personal/education/business` + select in form exists; no enforcement, billing, or renewal)
        - [ ] Free
            - Cost Free
            - 50MB of Storage (`User::DEFAULT_STORAGE`, tracked via `get_storage_use`/`used_storage` + usage bar, not enforced)
        - [ ] Education
            - [ ] Proof of student status
                - [ ] Yearly renewal
            - Cost $2.50/month
            - 1GB of storage
            - Encrypted Pages
        - [ ] Paid
            - Cost $5/month
            - 3GB Storage
            - Encrypted Pages (not done — only user PII `first_name`/`last_name`/`email_address` uses `encrypts`; page bodies are plaintext)

- [ ] Management
    - [ ] Users
        - [ ] Stats
            - [ ] Active Users
                - [ ] In Given Time
            - [ ] Inactive Users - 7 Days

    - [~] Storage (per-workspace usage computed via `pg_column_size(pages)` and shown on workspace page; no admin set-limit/trend UI)
        - [ ] Set Limit
        - [x] Usage
            - [ ] Trend

    - [ ] Stats
        - [ ] Organisations
        - [ ] Workspaces

- [~] Organisation (basic model + `workspaces.organisation_id` optional + member picker partial done; teams/roles/inheritance not done)
    - [~] Applications (apply form + `OrganisationApplication` lifecycle `pending → approved → queued → created` via `QueueOrgJob` + model specs done; no approval UI — `edit`/`update`/`destroy` are stubs, transitions via console)
    - [ ] Teams
        - [ ] Users
            - [ ] Premade User accounts with password change request

    - [x] Workspace - Optional Organisation
        - [~] Users (membership via `organisations_users` / `users_workspaces` join tables + access checks; no inherited-users logic)
            - [ ] Inherited Users
        - [ ] Roles
            - [ ] Admin / Owner
            - [ ] Custom
        - [x] Folder (single-root design via `ensure_root_folder`, nested `parent_id`, Turbo create)
            - [x] Pages (CRUD: create/rename/autosave/delete with Turbo Streams + membership access control)
                - [~] Markdown + HTML support (custom JS `markdown_controller.js` converter + live preview + tag/attribute sanitizer allowlist; task lists, fences, quotes, tables done)
                    - [~] Custom Markdown
                        - [x] `[[PAGE ID]]` (Obsidian-style wikilinks with alias, folder-qualified and case-insensitive resolution via `Workspace#page_link_map` + JS mirror; autocomplete suggestions)
                        - [x] `![[FILE ID]]` (embeds with file autocomplete; CSV embeds render as tables)
                    - [x] Table of contents (spinning-wheel TOC with heading slugs and smooth scroll)

            - [x] Roadmaps (CRUD: create/open/rename-autosave/delete + categories + items with assignee picker + drag-drop reorder via Turbo Streams/JSON; model + request specs)
            - [~] File Management (`WorkspaceFile` + Active Storage upload, explorer item, preview partial, specs; no storage-limit enforcement, no video preview, no inline download button for previewable types)
                - [~] File
                    - [x] Workspace ID (User Reference)
                    - [ ] File ID      (App Admin)

                    - [x] Preview
                    - [~] Download button (only shown in fallback/CSV notes, not on image/PDF previews)
                    - [~] Types
                        - [x] Image (png/jpg/jpeg/webp)
                        - [x] CSV (table preview + truncation)
                        - [x] PDF
                        - [ ] Video

### Order of Development

- [x] User Signups / Login
    - [x] Signup with live username/email availability + password strength checks
    - [x] Login/logout with `has_secure_token` sessions, idle timeout, rate limits
    - [x] Password reset via emailed token link (15-min TTL)
    - [x] Profile view/edit + avatar upload (vips variants, type/size validation)
    - [x] Roles enum (`user`/`admin`/`superadmin`) + PII encryption
    - [x] Landing/marketing pages (home, about, faq, roadmap, team)
    - [x] Dashboard shell + collapsible sidebar nav
- [~] Workspaces (Obsidian Vaults equivalent)
    - [x] Workspace CRUD (dashboard, owner auto-assign, access control, specs)
    - [~] Markdown - Page (editor + live preview + sanitized render + wikilinks/embeds done; encryption missing)
    - [x] Pages
        - [x] Simple editor (autosave/rename via shared PATCH `save_file`)
        - [x] File Explorer for workspace (root folder tree, Turbo frames/streams)
        - [x] Live markdown preview (Stimulus `markdown` controller)
        - [x] Sanitized HTML output (tag/attribute allowlists, safe URLs, style scrub)
        - [x] Delete / rename flows
        - [ ] Download Button
        - [x] Quick switcher (Ctrl+K / Cmd+K: fuzzy title match in the browser over the pages and the workspace files + Postgres full-text search over the bodies)
    - [x] Roadmaps (workspace editor: categories, items, assignee picker, drag-drop move; Turbo + JSON; specs)
    - [~] Files (upload, preview, CSV/`![[ ]]` embeds done; video, download button, quota enforcement outstanding)

### Feature Backlog (suggested)

Ordered roughly by value for effort. Items marked with a dependency need it first.

#### Navigation and knowledge graph
- [x] Quick switcher / command palette (Ctrl+K / Cmd+K, fuzzy page titles over `page_link_map` / `pagesMap()`, workspace files next to the pages, opens the page in the editor frame)
- [x] Full-text search (Postgres `tsvector` generated column + GIN index on `pages.name`/`pages.body`, `GET /workspace/:id/pages/search`)
- [ ] Backlinks panel (`page_links(source_id, target_id)` refreshed in `save_file`)
    - [ ] Unlinked mentions
    - [ ] Orphan / broken-link detection
- [ ] Graph view (depends on backlinks)
- [ ] Recent pages + reopen last-viewed page
- [ ] Pinned / favourite pages
- [ ] Tags (`#tag`) and YAML front matter (properties)

#### Markdown and editor
- [ ] Code block syntax highlighting
- [ ] Callouts (`> [!note]`)
- [ ] Footnotes
- [ ] `==highlight==`
- [ ] Math (KaTeX)
- [ ] Mermaid diagrams
- [ ] Image embeds via `![[image.png]]` and paste / drag-drop image upload
- [ ] Editor toolbar + shortcuts (bold, link, list continuation)
- [ ] Split / live / reading view toggle
- [ ] Word count and "saved" indicator
- [ ] Page templates + daily notes

#### Data safety and collaboration
- [ ] Page version history (`page_versions`, throttled snapshots, diff + restore)
- [ ] Trash / soft delete (`deleted_at`, 30-day recovery; `delete_file` is currently permanent)
- [ ] Edit conflict detection (lock version / `updated_at` check on `save_file`)
    - [ ] Real-time collaboration (ActionCable + CRDT, e.g. Yjs)
- [ ] Comments and @mentions on pages
    - [ ] In-app / email notifications (reuse `EmailMailer`)
- [ ] Public read-only share links (revocable token)

#### Workspace organisation
- [ ] Per-workspace roles (viewer / editor / admin) on `users_workspaces`
- [ ] Explorer drag-and-drop move, duplicate, multi-select / bulk actions
- [ ] Import (Obsidian vault) and export (ZIP of `.md`, per-page PDF, page Download button)
- [ ] Roadmap upgrades
    - [ ] Due dates, priority, labels
    - [ ] Filter by assignee
    - [ ] Calendar / timeline view
    - [ ] Link tasks to pages with `[[ ]]`
    - [ ] Task comments

#### Platform and business
- [ ] Billing + plan enforcement (Stripe, storage quotas; see Plans above)
- [ ] Encrypted page bodies on paid plans (`ACTIVE_RECORD_ENCRYPTION_*` keys already in `.env.example`)
- [ ] Offline / PWA (manifest + service worker exist; add page caching and queued edits)
- [ ] 2FA (TOTP)
- [ ] Active sessions page / sign out other sessions (`sessions` table supports it)
- [ ] Organisation audit log
- [ ] SSO (Google / Microsoft) for education and business
- [ ] Public API + personal access tokens + webhooks
- [ ] Theme toggle (light/dark) and custom CSS
- [ ] Accessibility audit (TOC wheel keyboard / screen-reader support)
- [ ] AI assistant (summaries, link suggestions, workspace Q&A) — after search + backlinks
