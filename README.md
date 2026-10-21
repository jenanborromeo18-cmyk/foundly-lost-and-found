# Foundly — Lost & Found

A Flutter app backed by Supabase for reporting lost and found items, searching community listings, and safely reviewing claim requests.

## Features

- Email and password sign up and sign in
- Lost and found reports with category, description, location, date, and an optional photo
- Browse and search open listings, with lost/found and category filters
- Personal listing management, including status changes and deletion
- Claim requests with private owner review, approval or decline, and an optional coordination message
- Supabase Row Level Security for profiles, listings, claims, and uploaded photos
- Responsive Material 3 interface for Android, iOS, and web

## Project structure

```text
lib/
  app/                 App root and theme
  core/                Shared theme, formatting, and widgets
  features/
    auth/              Authentication gate and sign-in flow
    home/              Main navigation and recent listings
    items/             Listing data, repository, browse, report, and detail flows
    profile/           User activity, own listings, and claim tracking
    setup/             Supabase configuration screen
supabase/
  schema.sql           Tables, triggers, RLS policies, RPC, and storage setup
```

## Supabase setup

1. Create a Supabase project.
2. Open the Supabase SQL Editor and run [`supabase/schema.sql`](supabase/schema.sql).
3. In **Authentication → Providers → Email**, enable email/password sign-in. For quick local development you may disable email confirmation; keep confirmation enabled for a public deployment.
4. Copy `env.example.json` to `.env.json` and set the project URL and **publishable** key from **Project Settings → API Keys**. The legacy anon key is also accepted by the app. Never put a service role or secret key in the app.
5. Run Flutter:

   ```sh
   flutter pub get
   flutter run --dart-define-from-file=.env.json
   ```

For a release build, pass the same compile-time values with `--dart-define-from-file=.env.json` to `flutter build apk`, `flutter build ios`, or `flutter build web`.

## Notes

- New users are added to `public.profiles` by a database trigger using the name entered at sign up.
- Public listing photos are stored in the `item-photos` bucket. Uploads are restricted to an authenticated user's own folder and limited to 5 MB.
- Claim messages are visible to the claimant and the listing owner. Owner coordination messages are only exposed through the claim row.
- If email confirmation is enabled, a newly registered user must confirm their email before signing in.
