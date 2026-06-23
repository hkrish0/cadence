# Cadence: AI Content Generation Pipeline
<!-- This plan is also committed to the repo at docs/pipeline-plan.md for cloud review via ultraplan -->

## Context

The creator model is shifting from human uploads to an AI pipeline. Instead of recruiting creators, custom "AI Personas" generate Tracks automatically using Claude (script), ElevenLabs (voiceover), DALL-E 3 (scene images), and FFmpeg (video assembly). Personas are fully dynamic DB rows — anyone with pipeline access can create a new persona with any name, domain, and personality. The pipeline runs asynchronously on a developer's machine, writes pre-rendered `.mp4` files to Supabase Storage, and inserts metadata into the existing Supabase DB. The Flutter app is unaffected except for three small model/filter changes.

---

## Part 1: Supabase Schema Migration

New file: `pipeline/migrations/001_add_personas_and_track_status.sql`

```sql
CREATE TABLE IF NOT EXISTS personas (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  slug          TEXT UNIQUE NOT NULL,   -- url-safe identifier, e.g. 'atlas', 'cricket_coach'
  name          TEXT NOT NULL,          -- display name, e.g. 'Atlas'
  subject       TEXT NOT NULL,          -- domain label, e.g. 'History'
  system_prompt TEXT NOT NULL,          -- full Claude system prompt for this persona
  voice_id      TEXT NOT NULL,          -- ElevenLabs voice ID
  avatar_url    TEXT,                   -- optional static image
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- No seed data — personas are created dynamically via the pipeline CLI.
-- The system supports unlimited custom personas on any topic.

ALTER TABLE tracks
  ADD COLUMN IF NOT EXISTS persona_id UUID REFERENCES personas(id),
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'generating', 'ready', 'failed'));

ALTER TABLE videos
  ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

ALTER TABLE personas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public can view personas" ON personas FOR SELECT USING (true);
```

Key: `creator_id` on `tracks` is already nullable (no NOT NULL in original DDL). AI tracks set `creator_id = null, persona_id = <uuid>`.

Also: Create a Supabase Storage bucket named `cadence-videos` with public access (done in dashboard, not SQL).

---

## Part 2: Python Pipeline

### Project Structure

```
pipeline/
├── .env.example
├── .env                      # gitignored
├── .gitignore
├── requirements.txt
├── run.py                    # CLI entry point (argparse)
├── config.py                 # load_config() → Config dataclass
├── personas.py               # PersonaDef dataclass + DB CRUD (create, list, fetch by slug)
├── models.py                 # EpisodeScript, EpisodeAssets, TrackSpec, SceneImage
├── pipeline.py               # Orchestrator: runs all 6 steps for one track
├── steps/
│   ├── s1_script.py          # Claude API → EpisodeScript (JSON)
│   ├── s2_voiceover.py       # ElevenLabs → .mp3
│   ├── s3_images.py          # DALL-E 3 → PNGs (async, concurrent)
│   ├── s4_video.py           # FFmpeg → .mp4 (slideshow + audio)
│   ├── s5_upload.py          # Supabase Storage → public URL
│   └── s6_db_write.py        # INSERT videos, UPDATE track status
└── migrations/
    └── 001_add_personas_and_track_status.sql
```

### requirements.txt

```
anthropic>=0.40.0
elevenlabs>=1.9.0
openai>=1.50.0
ffmpeg-python>=0.2.0
supabase>=2.9.0
python-dotenv>=1.0.0
aiohttp>=3.10.0
Pillow>=10.4.0
```

FFmpeg binary also required: `brew install ffmpeg`

### .env.example

```
ANTHROPIC_API_KEY=
ELEVENLABS_API_KEY=
ELEVENLABS_VOICE_ID=
OPENAI_API_KEY=
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=   # NOT the anon key — service role bypasses RLS
SUPABASE_BUCKET=cadence-videos
```

### Data Models (`models.py`)

```python
@dataclass
class TrackSpec:
    persona_slug: str
    title: str
    category: str
    description: str
    episode_count: int          # 3, 4, or 5
    topic_brief: str            # free-text topic context for Claude

@dataclass
class SceneImage:
    index: int
    description: str
    local_path: str

@dataclass
class EpisodeScript:
    episode_number: int
    title: str
    script_text: str            # ~300 words, plain prose
    scene_descriptions: list[str]   # 4-6 items → DALL-E prompts
    quiz_question: str
    quiz_options: list[str]     # exactly 4
    correct_option_index: int

@dataclass
class EpisodeAssets:
    episode_number: int
    script: EpisodeScript
    audio_path: str
    images: list[SceneImage]
    video_path: str
    video_url: str              # Supabase Storage public URL
    thumbnail_url: str          # first scene image URL
```

### Step Specifications

**s1_script.py** — `generate_episode_script(spec, persona, ep_num, track_context) → EpisodeScript`
- Model: `claude-sonnet-4-5`, `max_tokens=1500`
- System prompt = `persona.system_prompt`
- User prompt: structured JSON request with episode number, title, brief, prior-episode context
- Parses `json.loads()` on raw response; retries up to 3× on parse failure
- Claude must return ONLY valid JSON (no markdown fences)

**s2_voiceover.py** — `generate_voiceover(script_text, voice_id, output_path) → str`
- `ElevenLabs.text_to_speech.convert()` with `model_id="eleven_multilingual_v2"`
- Streams audio bytes to disk (chunk-by-chunk) to avoid memory bloat

**s3_images.py** — `async generate_all_scene_images(scene_descriptions, output_dir, ep_num) → list[SceneImage]`
- `AsyncOpenAI.images.generate()`, DALL-E 3, `size='1792x1024'`, `quality='standard'`
- All scenes run concurrently via `asyncio.gather()` (~5 scenes: 50s sequential → 12s concurrent)
- Downloads PNG immediately after generation (URL only valid ~1 hour)
- Each prompt prefixed: `"Cinematic educational illustration, warm palette. "`

**s4_video.py** — `assemble_video(images, audio_path, output_path, fps=24) → str`
- `ffmpeg.probe()` to get audio duration
- Equal display time per image = `audio_duration / len(images)`
- `filter_complex` with chained `xfade=transition=fade:duration=0.5` between images
- Encode: `libx264`, `crf=23`, `aac 128kbps`, `-movflags +faststart` (streaming-ready)
- Built via `ffmpeg-python` API (no shell string construction — no injection risk)

**s5_upload.py** — `upload_episode_video(mp4_path, persona_slug, track_id, ep_num) → str`
- `supabase.storage.from_(bucket).upload(path, data)`
- Storage path format: `{persona_slug}/{track_id}/ep{N:02d}.mp4`
- Returns `.get_public_url(path)`
- Also: `upload_thumbnail(png_path, ...) → str` for `images[0]`
- Uses service role key (required for Storage writes)

**s6_db_write.py** — Three functions:
- `insert_track(spec, persona) → str` — INSERT with `status='generating'`, returns `track_id`
- `insert_video(track_id, assets) → str` — INSERT one `videos` row
- `mark_track_ready(track_id)` / `mark_track_failed(track_id, error)` — UPDATE status

### Orchestrator (`pipeline.py`)

```
run_pipeline(spec: TrackSpec) → str:
  1. persona = get_persona(spec.persona_slug)
  2. track_id = insert_track(spec, persona)   # status='generating'
  3. try:
       track_context = ""
       for ep in range(1, spec.episode_count + 1):
         script   = s1_script.generate_episode_script(spec, persona, ep, track_context)
         audio    = s2_voiceover.generate_voiceover(script.script_text, persona.voice_id, ...)
         images   = asyncio.run(s3_images.generate_all_scene_images(script.scene_descriptions, ...))
         video    = s4_video.assemble_video(images, audio, ...)
         vid_url  = s5_upload.upload_episode_video(video, ...)
         thumb    = s5_upload.upload_thumbnail(images[0].local_path, ...)
         all_assets.append(EpisodeAssets(...))
         track_context += f"Ep {ep}: {script.title}. "
       for assets in all_assets:
         insert_video(track_id, assets)        # all DB writes at end (no partial tracks)
       mark_track_ready(track_id)
       return track_id
     except:
       mark_track_failed(track_id, str(e))
       raise
     finally:
       shutil.rmtree(work_dir)                 # always clean up temp files
```

Key design choices:
- All DB video inserts happen **after** all episodes succeed → no partial tracks ever visible
- `track_context` string fed to each subsequent episode → Claude maintains narrative continuity
- `status='generating'` before any API calls → crash-safe, Flutter never shows incomplete tracks

### Personas (`personas.py`)

`PersonaDef` is a Python dataclass mirroring the DB row. All persona data lives in Supabase — there are no hardcoded definitions in code.

```python
@dataclass
class PersonaDef:
    id: str
    slug: str
    name: str
    subject: str
    system_prompt: str
    voice_id: str
    avatar_url: str | None

def create_persona(slug, name, subject, system_prompt, voice_id, avatar_url=None) -> PersonaDef:
    """INSERTs into personas table, returns the created PersonaDef with its DB-assigned UUID."""

def fetch_persona(slug: str) -> PersonaDef:
    """Fetches one persona by slug from DB. Raises ValueError if not found."""

def list_personas() -> list[PersonaDef]:
    """Returns all personas from DB, ordered by created_at."""
```

The pipeline never embeds persona system prompts in Python source — they live in the DB and can be updated, refined, or extended without touching code. Any slug is valid as long as it exists in the `personas` table.

### CLI (`run.py`)

```bash
# Create a new persona (stored in DB — can be done anytime, any topic)
python run.py create-persona \
  --slug atlas \
  --name "Atlas" \
  --subject "History" \
  --voice-id "<elevenlabs-voice-id>" \
  --system-prompt "You are Atlas, a world-weary historian who speaks with gravitas..."

# List all personas in the DB
python run.py list-personas
# Output:
#   atlas           Atlas (History)          created 2026-06-23
#   newton          Newton (Science)         created 2026-06-23
#   loopy           Loopy (Programming)      created 2026-06-23

# Generate a track (--persona references a slug already in the DB)
python run.py generate \
  --persona atlas \
  --title "The Fall of the Roman Republic" \
  --category "History" \
  --description "Julius Caesar, civil war, and the death of the Republic" \
  --episodes 4 \
  --brief "Late Republic crisis, Marian reforms, First Triumvirate, Caesar's Rubicon"

# Clean up a stuck 'generating' or 'failed' track
python run.py cleanup-draft --track-id <uuid>
```

The `--persona` flag on `generate` accepts any slug that exists in the DB. The pipeline calls `fetch_persona(slug)` and raises a clear error if the slug doesn't exist yet.

---

## Part 3: Flutter Changes (3 files only)

### `lib/models/track.dart`

- `creatorId`: `String` → `String?` (null cast crash on AI tracks)
- Add `personaId`: `String?`
- Add `status`: `String` with default `'ready'` (defensive for old rows)

### `lib/services/track_service.dart`

Add `.eq('status', 'ready')` to `fetchAllTracks()` query only. `fetchTrack(id)` unchanged.

### `lib/models/video.dart`

Add `thumbnailUrl`: `String?` (additive, nullable — used later for track card previews).

No changes to providers, router, screens, or any other file.

---

## Verification

### Per-step isolation tests (run from `pipeline/`)

```bash
# s1 — Claude script
python -c "
from steps.s1_script import generate_episode_script
from models import TrackSpec
from personas import get_persona
spec = TrackSpec('newton','Photosynthesis','Science','How plants make food',1,'chlorophyll, light reactions')
r = generate_episode_script(spec, get_persona('newton'), 1, '')
print(r.title, len(r.script_text), len(r.scene_descriptions))
"

# s2 — ElevenLabs voiceover
python -c "
from steps.s2_voiceover import generate_voiceover
from personas import get_persona
import os
p = generate_voiceover('Hello, this is a test.', get_persona('atlas').voice_id, '/tmp/test.mp3')
print('Size:', os.path.getsize(p))
"

# s4 — FFmpeg assembly (requires two PNG test images and an MP3)
python -c "
from steps.s4_video import assemble_video
from models import SceneImage
imgs = [SceneImage(0,'','/tmp/img0.png'), SceneImage(1,'','/tmp/img1.png')]
print(assemble_video(imgs, '/tmp/test.mp3', '/tmp/out.mp4'))
"
```

### End-to-end smoke test (1 episode to minimize cost ~$0.25)

```bash
python run.py generate \
  --persona loopy \
  --title "What is a Variable?" \
  --category "Programming" \
  --description "Variables explained for beginners" \
  --episodes 1 \
  --brief "Explain a variable using the labeled-box metaphor"
```

### Flutter verification

Hot-restart the app → Track Directory → the new track appears → enroll → video plays → quiz answers match the generated `quiz_options`.

### Cost estimate per track (B-Roll approach)

| Item | Cost per video | × 4 episodes |
|---|---|---|
| Claude (script ~1000 tokens) | ~$0.003 | ~$0.012 |
| ElevenLabs (~60s audio) | ~$0.05 | ~$0.20 |
| DALL-E 3 (5 images × $0.04) | ~$0.20 | ~$0.80 |
| **Total** | **~$0.25** | **~$1.00** |
