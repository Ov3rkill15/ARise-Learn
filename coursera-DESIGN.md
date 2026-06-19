---
version: alpha
name: Coursera
description: "Coursera Blue (#0056D2) on white — a platform that must earn institutional credibility from universities while engaging individual learners. Complex content hierarchy (courses → modules → lessons), progress systems, and a video player UI that never competes with the lecture itself."

colors:
  primary: "#0056D2"
  on-primary: "#FFFFFF"
  primary-hover: "#004BB5"
  ink: "#1F1F1F"
  ink-muted: "#5C5C5C"
  ink-subdued: "#8C8C8C"
  canvas: "#FFFFFF"
  canvas-subdued: "#F5F7F9"
  surface-1: "#FFFFFF"
  surface-2: "#F5F7F9"
  border: "#D6DBDF"
  border-subtle: "#EEF0F2"
  progress-fill: "#0056D2"
  progress-track: "#D6DBDF"
  certificate-gold: "#F5AF02"
  streak-orange: "#F68A1E"
  grade-pass: "#1FA15F"
  grade-fail: "#D9534F"
  partner-badge: "#0056D2"

typography:
  display:
    fontFamily: "Source Sans Pro, system-ui, -apple-system, sans-serif"
    fontSize: 32px
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: -0.01em
  body:
    fontFamily: "Source Sans Pro, system-ui, -apple-system, sans-serif"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.7
    letterSpacing: 0em

spacing:
  base: 8px
  scale: [4, 8, 12, 16, 24, 32, 48, 64, 96, 128]

radius:
  sm: 4px
  md: 8px
  lg: 16px
  pill: 9999px

shadows:
  card: "0 2px 8px rgba(0,0,0,0.08)"
  elevated: "0 4px 20px rgba(0,0,0,0.12)"
  modal: "0 8px 40px rgba(0,0,0,0.18)"

motion:
  duration-fast: 150ms
  duration-base: 250ms
  easing: cubic-bezier(0.4, 0, 0.2, 1)
---

## Rationale

**Dual trust targets** — Coursera must be trusted by two very different audiences simultaneously. Universities (Yale, Stanford, Google, IBM) consider whether their brand is well represented on this platform — they require institutional seriousness, clean typography, and conservative visual restraint. Individual learners need to feel that progress is rewarding, that content is approachable, and that completing a course matters. Coursera Blue (#0056D2) threads this needle: professional enough for the university audience, direct and confident enough to feel like a modern learning platform rather than a stuffy LMS.

**Progress as motivational architecture** — Learning is not a single session — it is a habit sustained over weeks or months. Coursera's design system treats progress visualization as a core product function, not a cosmetic feature. Completion percentages, module progress bars, streak counters, and certificate progress indicators are deliberately prominent. The design ensures that every time a learner opens the platform, they can immediately assess how far they've come and how close they are to their next milestone. This visibility is motivationally essential.

**The video player is the primary interaction surface** — In most Coursera courses, the lecture video is the primary content format. Everything else — readings, assignments, quizzes — supplements the video. The platform UI is therefore engineered to serve the video, not compete with it. The player is full-width, the UI chrome collapses when video is playing, and post-video content (discussion, next item) appears below without demanding attention during playback.

**Long reading sessions demand legibility** — Source Sans Pro at 16px with 1.7 line height reflects the reality that learners often read long assignment briefs, peer review rubrics, and discussion forum posts within the platform. The generous line height and humanist letterforms reduce fatigue across sustained reading. This is a deliberate departure from the dense-table conventions of enterprise software — education is a reading-heavy domain.

## 1. Visual Theme & Atmosphere
Coursera presents a bright, academic environment. White content surfaces, very light gray (#F5F7F9) page backgrounds, and ample white space communicate that this is a place to think and learn, not to manage tasks. The tone is optimistic and approachable — course cards use the university or organization's own brand photography, giving each course a distinct visual identity within the consistent blue-and-white shell.

The interface is structured into a clear hierarchy: platform nav (top bar), course nav (left sidebar during a course), and content area. Learners spend most of their time in the content area; the navigation is there when needed but recedes when not.

## 2. Color System
**Canvas**:
- Page background: #F5F7F9 — very light cool gray, reduces harsh white on long sessions
- Content surface: #FFFFFF — lecture pages, assignment areas, discussion threads
- Border: #D6DBDF — structural edges, card outlines
- Border subtle: #EEF0F2 — internal dividers, table rows

**Primary**:
- Coursera Blue: #0056D2 — primary buttons, active navigation, progress fills, links
- Hover: #004BB5 — deeper blue on interaction

**Text**:
- Default: #1F1F1F — near-black for all content
- Muted: #5C5C5C — secondary labels, metadata, timestamps
- Subdued: #8C8C8C — very secondary information, captions, footnotes

**Progress & achievement**:
- Progress fill: #0056D2 — progress bars use the primary brand blue
- Certificate gold: #F5AF02 — course certificate completions, achievement unlocks
- Streak orange: #F68A1E — streak counter badge, learning streak fire icon

**Grade / assessment**:
- Pass: #1FA15F green — passing grade, quiz correct answers
- Fail: #D9534F red — failing grade, incorrect answers, missed deadlines

## 3. Typography
Source Sans Pro (designed by Paul Hunt for Adobe, released open source) is optimized for user interface reading, particularly in screen-reading scenarios that require sustained attention. Its wide proportions and open apertures at 16px body produce comfortable reading across the mix of short labels and long-form text that Coursera content requires.

Display text (course titles, module headings): 32px down to 24px, weight 700, tight letter-spacing. These headings are curriculum signposts — learners scan them to navigate a course's structure and understand what they're about to study.

Body text (reading materials, assignment instructions, discussion posts): 16px, weight 400, 1.7 line height. The 1.7 line height is higher than typical UI text defaults — it's tuned for paragraphs, not single-line labels.

Assessment question text: 16px weight 600 for the question stem, 15px weight 400 for answer options. The weight differential signals what is the question and what is the response.

## 4. Components & Patterns
**Course card**:
- Course thumbnail image (16:9), course title, institution logo, difficulty badge, duration
- Rating (star score + count), enrollment count for social proof
- "Enroll" CTA or progress bar if already enrolled
- Partner badge: small institution logo in the card corner

**Course content sidebar**:
- Collapsible module list with week labels (Week 1, Week 2, etc.)
- Each module: lesson items with completion checkmarks
- Completed items: checkmark icon in #1FA15F; current item: blue dot; upcoming: empty circle
- Progress bar beneath each module showing x/n items completed

**Video lecture player**:
- Full-width ratio (16:9), playback controls at bottom
- Closed captions toggle, quality selector, playback speed (0.75×–2×)
- Notes panel can expand on the right (for taking timestamped notes)
- "Next item" button appears after video completion — slides in from right

**Progress bar component**:
- Thin (8px height) horizontal bar, #0056D2 fill on #D6DBDF track
- Percentage label shown at right end
- Used in: course cards, module headers, certificate progress, weekly goal tracker

**Assessment quiz**:
- Question number indicator at top ("Question 2 of 10")
- Multiple choice: radio buttons with clear answer option text
- Submission: blue "Submit" button; after: shows correct/incorrect state with explanation
- Score summary at end: grade badge (Pass/Fail with percentage)

**Discussion forum thread**:
- Post: avatar, display name, timestamp, content (rich text support)
- Upvote count, reply count
- Mentor / Staff badges on authorized responders
- Thread expansion to show replies

**Certificate of completion**:
- Rendered as a formal document: Coursera logo, institution logo, learner name, course name, completion date
- Gold accent elements (#F5AF02)
- Shareable link, downloadable PDF, LinkedIn add button

## 5. Spacing & Layout
Coursera uses an 8px base grid. Course catalog pages: 24px page gutters, 24px card gap in a 3-column or 4-column grid. Course content pages: 240px left sidebar, fluid main content area capped at 820px for optimal reading line length (70–80 characters).

Video player: full width of the content area. Below the video: tabs (Notes, Discussion, Resources) with 24px padding. Assignment pages: same 820px max-width, 32px top padding.

Mobile: single-column layout, sidebar collapses to a top progress indicator strip, bottom tab bar for navigation.

## 6. Motion & Interaction
Progress bar fill animations use 400ms ease-out when a new item is completed — a moment of visual reward for the learner. Checkmarks on completed items use a brief scale animation (100ms) to make the completion feel registered.

Video player controls fade in on hover (150ms) and fade out after 3 seconds of inactivity — the standard pattern for video platforms, keeping playback immersive.

Certificate reveal uses a longer motion sequence (600ms) — the one place in the interface where theatrical motion is appropriate and earns its keep as a reward moment.

Page transitions between course items are instant (no animation) to keep the learning flow snappy.

## Accessibility

### Contrast Ratios
- **#1F1F1F on #FFFFFF**: 18.7:1 — passes AAA
- **#5C5C5C on #FFFFFF**: 7.4:1 — passes AAA
- **#8C8C8C on #FFFFFF**: 3.9:1 — fails AA for body text; use only at 18px+ for decorative text
- **#FFFFFF on #0056D2 primary button**: 7.0:1 — passes AAA
- **#FFFFFF on #1FA15F pass grade**: 4.6:1 — passes AA
- **#FFFFFF on #D9534F fail grade**: 4.8:1 — passes AA
- **#1F1F1F on #F5F7F9 page background**: 17.5:1 — passes AAA

### Minimum Requirements
- **Video captions**: closed captions required for all video content — WCAG 1.2.2; Coursera displays captions by default
- **Assessment feedback**: correct/incorrect states use color + icon + text label — never color-only
- **Touch targets**: 44×44px minimum; critical for mobile learners
- **Focus indicator**: 2px solid #0056D2 outline with 2px offset on all interactive elements
- **Skip navigation**: "Skip to content" link at the top of course pages for screen reader users to bypass the course sidebar

### Motion
- Respects `prefers-reduced-motion`: yes — progress bar fill animation, completion checkmark scale, certificate reveal all suppressed
- Video autoplay (next item) should be disabled under reduced-motion preferences

### Notes
- #8C8C8C on white (3.9:1) fails AA for body text — it should only be used for non-essential captions and decorative text at large sizes
- Certificate gold (#F5AF02) on white achieves only 2.3:1 — it is never used as text on white; it is a decorative/illustrative color only
- Discussion forums with user-generated content must maintain a minimum 14px font size enforced by the rendering layer — prevent user CSS from reducing text below readable thresholds
