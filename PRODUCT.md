# Product

## Register

product

## Users

Two audiences, one app:

1. **Bank customers** opening an account. They're on their phone, often first-time users, mildly anxious (they're handing over an ID and their face). Context: at home or at a branch desk, daylight, one-handed use. Job: finish identity verification quickly and feel the process is legitimate.
2. **Branch managers** reviewing escalated applications. Context: at a desk, working through a queue. Job: see why an application was escalated, inspect the evidence (document, checks, risk score), and approve or reject with confidence.

## Product Purpose

KYCFlow AI automates Know Your Customer verification end-to-end: a Flutter app captures personal details, a government ID, and a liveness-checked selfie; a FastAPI agent pipeline (OCR, face match, AML/sanctions/PEP screening, risk scoring) decides automatically or escalates to a human. Success = a customer completes verification in under three minutes and trusts the outcome; a manager resolves an escalation in under one.

## Brand Personality

Assured, precise, discreet. The register of a private bank, not a startup: oxblood crimson, crisp white paper, brass details. The mood phrase: "signing papers at a private bank — oxblood leather ledger, crisp white paper, a brass pen."

## Anti-references

- Generic fintech gradients (purple-to-blue), glassmorphism, neon-on-dark "crypto" styling.
- Government-portal blandness: gray forms, dense legalese, no hierarchy.
- Startup-cute: playful illustrations and joke copy are wrong for a flow where users submit identity documents.

## Design Principles

1. **Ceremony where it counts.** The welcome and the verdict are brand moments (committed crimson surfaces); the task screens between them are calm white paper. Color signals importance.
2. **Show the machine working.** The agent pipeline is the product's differentiator; the processing screen names each check as it completes instead of hiding behind a spinner.
3. **Never surprise someone holding their passport.** Every step says what happens next and why data is needed. Errors state the fix, not the failure code.
4. **The manager sees evidence, not logs.** Dashboard detail views translate agent context into human judgments: what was checked, what it found, what it recommends.

## Accessibility & Inclusion

- WCAG AA minimum: body text ≥4.5:1, large text ≥3:1; status never conveyed by color alone (icons + labels on every chip).
- Respect `MediaQuery.disableAnimations` (reduced motion): replace movement with crossfades.
- Camera flows give text instructions for every gesture prompt; touch targets ≥48dp.
