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
                    - [ ] Custom Markdown
                        - [ ] `[[PAGE ID]]`
                        - [ ] `![[FILE ID]]`

            - [ ] File Management (not started — only `pfp_image`/`workspace_image` Active Storage uploads exist)
                - [ ] File
                    - [ ] Workspace ID (User Reference)
                    - [ ] File ID      (App Admin)

                    - [ ] Preview
                    - [ ] Download button
                    - [ ] Types
                        - [ ] Image
                        - [ ] CSV
                        - [ ] PDF
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
    - [~] Markdown - Page (editor + live preview + sanitized render done; custom links/embeds + encryption missing)
    - [x] Pages
        - [x] Simple editor (autosave/rename via shared PATCH `save_file`)
        - [x] File Explorer for workspace (root folder tree, Turbo frames/streams)
        - [x] Live markdown preview (Stimulus `markdown` controller)
        - [x] Sanitized HTML output (tag/attribute allowlists, safe URLs, style scrub)
        - [x] Delete / rename flows
        - [ ] Download Button
    - [ ] Files
