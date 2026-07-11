# Design

Visual system for KYCFlow AI (Flutter, mobile-first). Mood: "signing papers at a private bank — oxblood leather ledger, crisp white paper, a brass pen."

## Color

Strategy: **Committed**. Oxblood wine carries the brand moments (welcome, verdict, app bars on brand screens); task screens are pure white paper; camera screens are near-black. Semantic status colors are never decoration.

All values composed in OKLCH, shipped as sRGB hex in `lib/theme/palette.dart`.

| Role | OKLCH | Hex | Use |
|---|---|---|---|
| primary | oklch(0.45 0.155 355) | #92225A | Brand fills, primary buttons, active states |
| primaryDeep | oklch(0.34 0.115 355) | #62153B | Drenched welcome/verdict surfaces, pressed |
| primaryText | oklch(0.42 0.15 355) | #861A51 | Brand-colored text on white/tint |
| primaryTint | oklch(0.955 0.015 355) | #F9ECF0 | Selected fills, brand chips |
| bg | oklch(1 0 0) | #FFFFFF | Task screen background (pure white, no tint) |
| surface | oklch(0.972 0.004 355) | #F8F5F6 | Cards, panels, grouped fields |
| ink | oklch(0.21 0.015 355) | #1E1619 | Body text (17.7:1 on bg) |
| muted | oklch(0.47 0.02 355) | #65565B | Secondary text (6.9:1 on bg) |
| border | oklch(0.9 0.006 355) | #E1DCDE | Hairlines, field borders |
| brass | oklch(0.58 0.115 75) | #A26F17 | Accent icons, large accents only |
| brassText | oklch(0.52 0.11 75) | #8D5E00 | Brass text ≥4.5:1 (5.6:1 on white) |
| brassTint | oklch(0.955 0.025 85) | #F8EFDE | Escalated/review badges |
| success / successText / successTint | — | #2C7F44 / #126630 / #E3F6E6 | Approvals, passed checks |
| warning / warningText / warningTint | — | #B26E1B / #8F5300 / #FFF1DA | Medium risk, attention |
| danger / dangerText / dangerTint | — | #BC2826 / #AA1F1F / #FDEBE9 | Rejection, high risk |
| inkSurface / inkSurfaceHi | — | #140D10 / #251C20 | Camera & liveness screens |
| onDarkMuted | — | #ADA1A5 | Secondary text on dark (7.7:1) |

Rules: white text on primary/deep fills (8.1:1). On tint fills, always the matching `*Text` shade. Status chips always pair icon + label (never color alone).

## Typography

Two families, bundled as assets (no runtime fetching):

- **Instrument Sans** — the entire UI: headings, labels, buttons, body, data. Weights 400/500/600/700.
- **Instrument Serif** — the wordmark and verdict display lines only. Never in labels, buttons, or body.

Fixed rem-style scale (ratio ~1.2): display 34, title 24, heading 20, subtitle 17, body 15, label 13, caption 12. Tabular figures for scores and IDs.

## Components

- Buttons: filled primary (white on #92225A), tonal (primaryTint), outlined, text. Radius 14, height 52, full-width on mobile forms. Every control has disabled + loading states.
- Text fields: filled `surface` with 1px `border`, 12 radius, floating labels off; label above field.
- Status chips: tint fill + `*Text` foreground + leading icon, radius 999.
- Cards: white on `surface` screens or `surface` on white, 1px border, radius 16, no drop shadows heavier than 8% opacity.
- Progress pipeline: vertical stepper naming each agent check; completed = success check, active = animated pulse, pending = muted.
- Skeletons for loading lists; empty states explain what will appear and how.

## Layout

- Screen padding 20–24; section gaps 28–36; related items 8–12. 48dp minimum touch targets.
- One primary action per screen, pinned at the bottom on flow screens.
- Manager dashboard: list → detail; density is welcome, evidence grouped by check category.

## Motion

150–250 ms, ease-out cubic. Motion conveys state only: step completion ticks, chip transitions, verdict reveal (scale 0.94→1 + fade). No page-load choreography. When `MediaQuery.disableAnimations` is true, all transitions become fades or instant.
