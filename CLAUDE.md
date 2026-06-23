Project Cadence - AI Context & Rules

1. Project Overview

Cadence is a short-form video platform for serialized micro-learning. It is the antidote to the random, disjointed "infinite scroll" of TikTok/Reels. Creators upload "Tracks" (3-5 sequential videos on ONE specific topic). Learners consume them using Spaced Repetition and Intentional Scarcity to ensure real retention.

Any topic is allowed (History, Science, Mechanics, Art), but the videos MUST be consumed in sequence.

2. Core Mechanics (MVP)

Scarcity (The Vault): When a user enrolls in a track, only Video 1 is unlocked. Video 2 unlocks 24 hours after Video 1 is completed. Bingeing is impossible.
Spaced Repetition (Comprehension Gate): To unlock the next video at the 24h mark, the user must pass a text-based multiple-choice quiz about the previous video.
NO Infinite Scroll: The app has a directory of tracks. No algorithmic, random feed. 3. Tech Stack & Architecture

Framework: Flutter (Dart)
State Management: Riverpod (use flutter_riverpod)
Backend/DB/Auth: Supabase
Routing: GoRouter
Notifications: flutter_local_notifications (Local only for MVP) 4. Database Schema (Supabase Postgres)

profiles: id (uuid, references auth.users), display_name.
tracks: id (uuid), creator_id (uuid), title (text), category (text), description (text), created_at.
videos: id (uuid), track_id (uuid), order_index (int), video_url (text), title (text), quiz_question (text), quiz_options (jsonb), correct_option_index (int).
enrollments: id (uuid), user_id (uuid), track_id (uuid), enrolled_at (timestamptz), current_unlock_index (int, default 1), last_unlocked_at (timestamptz). 5. Strict MVP Scope (DO NOT BUILD THESE)

NO random/algorithmic "For You" vertical feed.
NO learner selfie-video recording.
NO social features (comments, likes, follows).
NO payments, paywalls, or Stripe integration.
NO remote push notifications (only local scheduled notifications). 6. Coding Standards

Keep widgets small and composable.
Use Riverpod for all state (do not use setState for business logic).
Handle loading, error, and empty states in the UI.
Write clean, modular Supabase service classes.
