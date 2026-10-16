# Tori — project rules for AI assistants

Read by Cursor directly and by Claude Code through `CLAUDE.md`.
Two developers work on this project in parallel. Follow these rules exactly.

## What we are building

A simple appointment booking tool for solo freelancers in Israel (barbers,
cosmeticians, yoga teachers). Version 1 serves 2–3 businesses for free.

- A client opens `/{slug}`, picks a service, a day and a free time, and books
  with name and phone. No client accounts.
- A daily job at 18:00 Israel time sends a WhatsApp reminder for tomorrow's
  bookings, with a cancel link `/c/{token}`.
- The business owner signs in with an email magic link and manages the
  calendar at `/dashboard`.

Out of scope for now: payments, self sign-up, logos/branding, multiple staff,
waitlists, Google Calendar sync. Do not build these unless the task says so.

## Stack

- Next.js (App Router) + TypeScript + Tailwind CSS
- Supabase (Postgres, Auth, RLS) via `@supabase/ssr` and `@supabase/supabase-js`
- Hosted on Vercel
- WhatsApp Cloud API (Meta) for reminders
- npm only. Node version is in `.nvmrc`.

## Commands

- `npm run dev` — local dev server
- `npm run lint` — ESLint
- `npx prettier --write .` — format

Run lint and format before every commit.

## Who owns what

Stay inside your folders. Touching another person's folder needs a heads-up
in the pull request description.

| Path                                                                           | Owner                   |
| ------------------------------------------------------------------------------ | ----------------------- |
| `app/[slug]/`, `app/c/`, `app/api/cron/`, `lib/availability/`, `lib/whatsapp/` | B (client side)         |
| `app/login/`, `app/dashboard/`, `lib/auth/`                                    | A (business owner side) |
| `lib/db/`, `lib/phone.ts`, `components/ui/`, `supabase/`                       | shared                  |

## Data model

See `supabase/migrations/`. Key terms:

- **appointment** = a time slot in a business calendar, with `capacity`.
  A haircut is capacity 1, a yoga class is capacity 10.
- **booking** = one client registered to an appointment.
- `appointments_no_overlap` prevents overlapping scheduled appointments per
  business. Never work around it; handle its error (code `23P01`) and show
  "השעה הזו נתפסה, בחרו שעה אחרת".

## Rules

1. **UI is Hebrew and right-to-left.** All user-facing text in Hebrew.
   Use logical CSS (`ms-`, `me-`, `ps-`, `pe-`, `start`, `end`), never
   `left`/`right`. Mobile first: design for a 375px wide phone.
2. **Code is English.** Identifiers, comments, commit messages.
3. **Time.** Store `timestamptz` (UTC). Display and calculate in
   `Asia/Jerusalem` (from `businesses.timezone`). Working hours in
   `availability_rules` are local times. Be careful around DST changes.
   `weekday` 0 = Sunday.
4. **Phones** are stored as `972XXXXXXXXX`. Always use `normalizeIsraeliPhone`
   and `formatIsraeliPhone` from `lib/phone.ts`.
5. **Prices** are whole shekels in `price_ils`.
6. **Database changes** only through a new file in `supabase/migrations/`
   (`supabase migration new <name>`). Never edit a migration that was already
   pushed. Never change tables in the Supabase dashboard.
7. **Security.**
   - Anonymous users may only read. Public writes (create booking, cancel by
     token) go through `security definer` Postgres functions called with RPC.
   - `SUPABASE_SERVICE_ROLE_KEY` is used only in server code (cron job), never
     in a file that runs in the browser or starts with `NEXT_PUBLIC_`.
   - Never commit `.env.local` or any key.
8. **Privacy.** Collect only name and phone from clients. The booking form has
   a consent checkbox with a short explanation of who sees the data.
9. **Keep it small.** Do only what the task asks. No new dependencies without
   saying why in the pull request. Prefer server components and server actions
   over client-side fetching.
10. **Git.** Work on a branch named `a/<task>` or `b/<task>`, open a pull
    request, never push to `main`.

## Next.js version notes

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->
