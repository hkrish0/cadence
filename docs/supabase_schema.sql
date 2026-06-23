-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tracks (The Serialized Series)
CREATE TABLE tracks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  creator_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  category TEXT, -- e.g., 'History', 'Science', 'Art', 'Tech'
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Videos (The sequential episodes inside a Track)
CREATE TABLE videos (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  track_id UUID REFERENCES tracks(id) ON DELETE CASCADE,
  order_index INT NOT NULL,
  title TEXT NOT NULL,
  video_url TEXT NOT NULL,
  quiz_question TEXT NOT NULL,
  quiz_options JSONB NOT NULL, -- e.g., ["Option A", "Option B", "Option C"]
  correct_option_index INT NOT NULL -- 0-indexed
);

-- Enrollments (The Learner's Progress & Scarcity State)
CREATE TABLE enrollments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  track_id UUID REFERENCES tracks(id),
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  current_unlock_index INT DEFAULT 1, -- Which video they are allowed to watch next
  last_unlocked_at TIMESTAMPTZ DEFAULT NOW(), -- Timestamp for the 24h scarcity timer
  UNIQUE(user_id, track_id)
);

-- Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies
CREATE POLICY "Public can view tracks" ON tracks FOR SELECT USING (true);
CREATE POLICY "Public can view videos" ON videos FOR SELECT USING (true);
CREATE POLICY "Users can view own enrollments" ON enrollments FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can insert own enrollments" ON enrollments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update own enrollments" ON enrollments FOR UPDATE USING (user_id = auth.uid());