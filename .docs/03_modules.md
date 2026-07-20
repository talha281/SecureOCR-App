# Product Module Bifurcation

**Project Name:** SecureCode OCR *(Working Title)*

**Version:** 1.0

**Document Owner:** Product Team

**Status:** Draft

**Last Updated:** July 2026

---

## Purpose

This document breaks SecureCode OCR into self-contained, independently implementable modules.
Each module maps to specific PRD Functional Requirements (FR) and KPI targets so that the team can plan, build, test, and validate the product incrementally without building everything at once.

---

## Implementation Order

The modules are ordered by dependency. A later module may only begin once all modules it depends on are marked **complete**.

```
MOD-01  App Shell & Navigation
    └── MOD-02  Image Acquisition
            └── MOD-03  Image Enhancement
                    └── MOD-04  OCR Engine
                            ├── MOD-05  Language & Framework Detection
                            │       └── MOD-06  Code Cleanup & Post-Processing
                            │               └── MOD-07  Code Editor
                            │                       └── MOD-08  Sharing
                            └── MOD-09  Security & Session Management  ← runs alongside all modules
```

---

## Module Index

| # | Module | PRD FR Coverage | Priority |
|---|--------|-----------------|----------|
| MOD-01 | [App Shell & Navigation](#mod-01-app-shell--navigation) | — | 🔴 Critical |
| MOD-02 | [Image Acquisition](#mod-02-image-acquisition) | FR-001, FR-002 | 🔴 Critical |
| MOD-03 | [Image Enhancement](#mod-03-image-enhancement) | FR-003 | 🟠 High |
| MOD-04 | [OCR Engine](#mod-04-ocr-engine) | FR-004 | 🔴 Critical |
| MOD-05 | [Language & Framework Detection](#mod-05-language--framework-detection) | FR-005, FR-006 | 🔴 Critical |
| MOD-06 | [Code Cleanup & Post-Processing](#mod-06-code-cleanup--post-processing) | FR-007, FR-008 | 🟠 High |
| MOD-07 | [Code Editor](#mod-07-code-editor) | FR-009 | 🔴 Critical |
| MOD-08 | [Sharing](#mod-08-sharing) | FR-010 | 🔴 Critical |
| MOD-09 | [Security & Session Management](#mod-09-security--session-management) | FR-011, FR-012 | 🔴 Critical |

---

## MOD-01  App Shell & Navigation

### Description

The foundational layer of the application. Provides the app entry point, screen routing, navigation structure, global theme (dark/light mode), and the startup experience. All other modules are rendered within this shell.

### PRD References

- PRD §10 — Core Principles
- PRD §13 — Performance Requirements (App Startup < 2 sec)
- PRD §18 — Constraints (Flutter, Android only)

### KPI Targets

| KPI | Target |
|-----|--------|
| App Startup Time | < 2 seconds |
| Crash-Free Session Rate | ≥ 99.5% |
| ANR Rate | < 0.5% |

### Deliverables

- [ ] Flutter app project scaffolding
- [ ] Navigation router (screens: Home, Preview, Processing, Editor)
- [ ] Global theme system — dark mode & light mode
- [ ] Splash screen / startup animation
- [ ] Error boundary / global crash handler
- [ ] App startup performance baseline measurement

### Acceptance Criteria

- App launches and reaches the Home screen in < 2 seconds on a mid-range Android device
- Dark mode and light mode toggle correctly
- Navigation between all screens is smooth with no jank

### Dependencies

None — this is the root module.

---

## MOD-02  Image Acquisition

### Description

Handles how the user brings an image into the application. Two entry paths: live camera capture and gallery import. The image must be available immediately after capture or selection with no permanent storage.

### PRD References

- FR-001 — Capture Image (camera)
- FR-002 — Import Image (gallery, no permanent storage)
- PRD §14 — Supported Inputs

### KPI Targets

| KPI | Target |
|-----|--------|
| Camera vs. Gallery Import Ratio | Informational baseline |
| Extraction Completion Rate | > 90% |
| Average Extraction Time (User Perceived) | < 5 seconds total |

### Deliverables

- [ ] Camera capture screen with real-time viewfinder
- [ ] Gallery image picker (single image selection)
- [ ] Permission request flows (camera, storage)
- [ ] Permission denied graceful fallback UI
- [ ] Image handoff to MOD-03 (Enhancement) or MOD-04 (OCR) pipeline
- [ ] No permanent image write to device storage

### Acceptance Criteria

- Camera capture produces an image available immediately within the session
- Gallery picker returns a selected image without permanent copy
- Camera and gallery permissions are requested before use and handled gracefully if denied
- Image is not written permanently to device storage

### Dependencies

- MOD-01 App Shell & Navigation

---

## MOD-03  Image Enhancement

### Description

Pre-processes the captured or imported image to maximize OCR accuracy. Operations include geometric corrections and visual adjustments. All processing is local with no network calls.

### PRD References

- FR-003 — Image Enhancement
  - Rotation
  - Cropping
  - Perspective correction
  - Contrast adjustment
  - Brightness adjustment
  - Noise reduction

### KPI Targets

| KPI | Target |
|-----|--------|
| OCR Processing Time | < 3 seconds (total pipeline including enhancement) |
| Overall OCR Character Accuracy | > 95% (enhancement directly affects this) |
| Memory Usage | Within mid-range Android budget |

### Deliverables

- [ ] Manual rotation control (90° increments + free rotation)
- [ ] Cropping tool with drag handles
- [ ] Perspective / keystone correction
- [ ] Auto-contrast and brightness adjustment
- [ ] Noise reduction filter
- [ ] Preview of enhanced image before sending to OCR
- [ ] "Use Original" option to skip enhancement
- [ ] Enhanced image held in encrypted temp storage (see MOD-09)

### Acceptance Criteria

- User can rotate, crop, and adjust contrast/brightness before processing
- Perspective correction visibly straightens skewed code images
- Enhancement operations do not permanently modify the original gallery image
- Enhanced image is stored encrypted in temporary session storage

### Dependencies

- MOD-01 App Shell & Navigation
- MOD-02 Image Acquisition
- MOD-09 Security & Session Management (for encrypted temp storage)

---

## MOD-04  OCR Engine

### Description

The core recognition engine. Runs entirely on-device. Accepts the (optionally enhanced) image and outputs raw extracted text with per-character confidence scores. Zero internet connectivity is required or used.

### PRD References

- FR-004 — Offline OCR
- PRD §12 — Security Requirements (no cloud OCR)
- PRD §13 — Performance Requirements (OCR < 3 sec)

### KPI Targets

| KPI | Target |
|-----|--------|
| Overall OCR Character Accuracy | > 95% |
| OCR Processing Time | < 3 seconds |
| Zero Cloud OCR Calls | 0 |
| OCR Engine Failure Rate | < 1% |
| Extraction Completion Rate | > 90% |

### Deliverables

- [ ] Integration of on-device OCR model (e.g., ML Kit Text Recognition v2 or Tesseract)
- [ ] Raw text extraction with per-character confidence scores
- [ ] Confidence score output passed to MOD-06 (Cleanup)
- [ ] Progress indicator during OCR processing
- [ ] Error handling for unrecognized or blank images
- [ ] OCR performance benchmarks against a labeled test image set
- [ ] Strict no-network-call enforcement (lint rule / test)

### Acceptance Criteria

- OCR completes in < 3 seconds on a mid-range Android device
- No network calls are made during OCR processing
- Character accuracy exceeds 95% on the benchmark test set
- OCR fails gracefully with a user-visible error for completely unreadable images

### Dependencies

- MOD-01 App Shell & Navigation
- MOD-02 Image Acquisition
- MOD-03 Image Enhancement

---

## MOD-05  Language & Framework Detection

### Description

Analyzes the raw OCR text output and classifies the programming language and, where applicable, the framework or artifact type. Detection runs in < 1 second immediately after OCR completes.

### PRD References

- FR-005 — Programming Language Detection
  - C#, JavaScript, TypeScript, HTML, SQL, React, Angular, .NET
- FR-006 — Framework Detection
  - ASP.NET, Angular, React, .NET Framework, JSON, YAML, XML, Stack Traces, Logs

### KPI Targets

| KPI | Target |
|-----|--------|
| Programming Language Detection Accuracy | > 90% |
| Framework Detection Accuracy | > 85% |
| Language Detection Time | < 1 second |
| Framework Detection Time | < 1 second |

### Supported Targets (v1.0)

| Language / Framework | Status |
|----------------------|--------|
| C# | ✓ v1.0 |
| JavaScript | ✓ v1.0 |
| TypeScript | ✓ v1.0 |
| HTML | ✓ v1.0 |
| SQL | ✓ v1.0 |
| React (JSX/TSX) | ✓ v1.0 |
| Angular (templates) | ✓ v1.0 |
| .NET / ASP.NET | ✓ v1.0 |
| JSON / YAML / XML | ✓ v1.0 |
| Stack Traces / Logs | ✓ v1.0 |

### Deliverables

- [ ] Rule-based or ML classifier for language detection
- [ ] Framework sub-classifier (activated after language identification)
- [ ] Confidence score for detected language and framework
- [ ] "Unknown / Plain Text" fallback for unrecognized content
- [ ] Detection result displayed as a label in the editor (e.g., "C# · ASP.NET")
- [ ] Extensible detection architecture for future language additions
- [ ] Accuracy test suite covering all 10 supported language/framework targets

### Acceptance Criteria

- Language is correctly identified in > 90% of labeled test cases
- Framework is correctly identified in > 85% of labeled test cases
- Detection completes in < 1 second after OCR output is available
- Unknown languages fall back gracefully to "Plain Text" without crashing

### Dependencies

- MOD-04 OCR Engine

---

## MOD-06  Code Cleanup & Post-Processing

### Description

Takes the raw OCR output and applies intelligent cleanup before presenting it to the user in the editor. Removes IDE artifacts (line numbers, gutter icons, toolbar text) and highlights low-confidence characters so the user can quickly correct them.

### PRD References

- FR-007 — Automatic Cleanup
  - Remove line numbers
  - Remove IDE artifacts
  - Remove toolbar text
  - Remove noise / OCR mistakes
- FR-008 — Confidence Highlighting
  - Highlight uncertain characters
  - Allow quick editing

### KPI Targets

| KPI | Target |
|-----|--------|
| Automatic Cleanup Success Rate | > 90% |
| Confidence Highlight Coverage | > 95% of uncertain characters flagged |
| Average Edit Duration | Trend downward (cleanup reduces manual fixes) |

### Deliverables

- [ ] Line number strip filter
- [ ] IDE gutter / toolbar artifact remover
- [ ] Noise / stray character filter
- [ ] Low-confidence character annotator (passes annotations to MOD-07 editor)
- [ ] "Review highlights" mode — user can jump between flagged characters
- [ ] Configurable cleanup sensitivity (optional for v1.0)

### Acceptance Criteria

- IDE-generated line numbers are stripped in > 90% of test cases
- Gutter icons and toolbar text are not present in editor output
- Characters with confidence below threshold are visually highlighted in the editor
- Cleanup completes in < 500 ms (part of the overall < 3 sec OCR pipeline)

### Dependencies

- MOD-04 OCR Engine
- MOD-05 Language & Framework Detection (informs cleanup rules per language)

---

## MOD-07  Code Editor

### Description

A lightweight, developer-friendly code editor that displays the cleaned-up extracted code with syntax highlighting. Supports editing, navigation, and interaction before sharing. Must open in < 500 ms.

### PRD References

- FR-009 — Editor
  - Syntax highlighting
  - Undo / Redo
  - Search
  - Selection
  - Copy
  - Share
  - Line numbers
  - Dark mode
  - Light mode

### KPI Targets

| KPI | Target |
|-----|--------|
| Editor Open Time | < 500 milliseconds |
| Editor Load Failure Rate | < 0.5% |
| Average Edit Duration | Baseline in Month 1 |
| User Satisfaction Score | > 4.0 / 5.0 |

### Deliverables

- [ ] Code editor widget with monospaced font
- [ ] Syntax highlighting per detected language (from MOD-05)
- [ ] Confidence highlight rendering (from MOD-06)
- [ ] Line numbers display
- [ ] Undo / Redo stack
- [ ] In-editor Search (find text, highlight matches)
- [ ] Text selection with copy action
- [ ] Dark mode and light mode theme switching
- [ ] Share button triggering MOD-08
- [ ] Word wrap toggle
- [ ] Keyboard toolbar (tab, indent, common symbols)

### Acceptance Criteria

- Editor opens with syntax-highlighted code in < 500 ms after extraction
- Undo and redo work correctly for all edit operations
- Search finds and highlights all matching text
- Copied text is plain text only (no formatting metadata)
- Editor renders correctly in both dark and light mode

### Dependencies

- MOD-01 App Shell & Navigation
- MOD-05 Language & Framework Detection (syntax highlighting language)
- MOD-06 Code Cleanup & Post-Processing (cleaned text + confidence annotations)

---

## MOD-08  Sharing

### Description

Allows the user to share the extracted and edited code through the Android Share Sheet as plain text only. Sharing is always explicitly initiated by the user — never automatic. No source code metadata is included in the shared payload.

### PRD References

- FR-010 — Sharing
  - Android Share Sheet
  - Plain text only
  - User initiated
- PRD §12 — Security Requirements
  - Sharing only after explicit user action
  - Metadata removed from shared output

### KPI Targets

| KPI | Target |
|-----|--------|
| Share Completion Rate | Baseline in Month 1 |
| Share Triggered Only by User Action | 100% |
| Metadata Stripped from Shared Output | 100% |

### Deliverables

- [ ] Share button in editor (MOD-07)
- [ ] Android Share Sheet integration
- [ ] Payload builder — plain text only, no metadata
- [ ] Share confirmation / preview (optional for v1.0)
- [ ] Share event instrumentation (privacy-safe, no code content)
- [ ] Audit: verify payload contains no image data, no language tags, no file paths

### Acceptance Criteria

- Tapping Share opens Android Share Sheet with the extracted code as plain text
- Shared payload contains only the extracted/edited text — no metadata, image bytes, or language identifiers
- Share is never triggered automatically; always requires explicit user action
- Share action is available only from within the editor (not automatically after extraction)

### Dependencies

- MOD-07 Code Editor

---

## MOD-09  Security & Session Management

### Description

A cross-cutting module that enforces the privacy-first and offline-first principles throughout the entire data lifecycle. Manages encrypted temporary storage, session lifecycle, and automatic cleanup on session end. This module runs **alongside** all other modules.

### PRD References

- FR-011 — Temporary Image Storage
  - Images remain only during active session
  - Automatically deleted
- FR-012 — Session Cleanup
  - Delete temporary images
  - Delete temporary OCR cache
  - Delete temporary enhancement files
- PRD §12 — Security Requirements
  - Everything processed locally
  - No cloud OCR, no cloud analytics containing source code
  - Encrypted local storage
  - Temporary files encrypted
  - Metadata removed
  - Images never permanently stored by default

### KPI Targets

| KPI | Target |
|-----|--------|
| Temporary Image Auto-Deletion Rate | 100% |
| Encrypted Temporary File Compliance | 100% |
| Session Cleanup Success Rate | 100% |
| Zero Unauthorized Data Transmissions | 0 |
| Zero Cloud OCR Calls | 0 |
| No Source Code in Analytics/Telemetry | 0 violations |

### Deliverables

- [ ] Encrypted temp file system (AES-256 or platform equivalent)
- [ ] Session lifecycle manager (session start → session end hook)
- [ ] Automatic cleanup on app background / close / session end
- [ ] Cleanup verification (log confirming all temp files deleted)
- [ ] Network policy enforcement — block outbound calls for OCR/code data
- [ ] Security audit checklist (static analysis + manual review)
- [ ] Crash-safe cleanup: cleanup executes even if app crashes mid-session

### Acceptance Criteria

- All temporary files (images, OCR cache, enhancement files) are encrypted at rest
- All temporary files are deleted at session end — verified by file system audit
- No outbound network calls occur that contain source code or image data
- Cleanup runs even if the app crashes (exception-safe lifecycle hook)
- App passes a network traffic audit showing zero cloud OCR or cloud AI calls

### Dependencies

- MOD-01 App Shell & Navigation (session lifecycle)
- Runs alongside: MOD-02, MOD-03, MOD-04, MOD-05, MOD-06, MOD-07, MOD-08

---

## Build Sequence Summary

The recommended implementation order balances dependencies and value delivery:

| Sprint | Module | Goal |
|--------|--------|------|
| Sprint 1 | MOD-01 + MOD-09 skeleton | Working app shell with session/security foundation |
| Sprint 2 | MOD-02 | Image capture and gallery import functional |
| Sprint 3 | MOD-03 | Image enhancement tools available |
| Sprint 4 | MOD-04 | On-device OCR producing raw text |
| Sprint 5 | MOD-05 | Language and framework detection working |
| Sprint 6 | MOD-06 | Cleanup + confidence highlights applied |
| Sprint 7 | MOD-07 | Full code editor with syntax highlighting |
| Sprint 8 | MOD-08 + MOD-09 full | Sharing complete + full security audit |

---

## Module ↔ KPI Coverage Matrix

| KPI | MOD-01 | MOD-02 | MOD-03 | MOD-04 | MOD-05 | MOD-06 | MOD-07 | MOD-08 | MOD-09 |
|-----|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|:------:|
| App Startup Time < 2s | ✓ | | | | | | | | |
| OCR Processing Time < 3s | | | ✓ | ✓ | | | | | |
| Language Detection < 1s | | | | | ✓ | | | | |
| Framework Detection < 1s | | | | | ✓ | | | | |
| Editor Open Time < 500ms | | | | | | | ✓ | | |
| Zero Cloud OCR Calls | | | | ✓ | | | | | ✓ |
| Temp Image Auto-Deletion 100% | | | | | | | | | ✓ |
| Encrypted Temp Files 100% | | | ✓ | | | | | | ✓ |
| Share User-Initiated 100% | | | | | | | ✓ | ✓ | |
| OCR Character Accuracy > 95% | | | ✓ | ✓ | | | | | |
| Language Detection > 90% | | | | | ✓ | | | | |
| Framework Detection > 85% | | | | | ✓ | | | | |
| Cleanup Success Rate > 90% | | | | | | ✓ | | | |
| Confidence Highlight > 95% | | | | | | ✓ | ✓ | | |
| Crash-Free Rate ≥ 99.5% | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Session Cleanup 100% | | | | | | | | | ✓ |

---

## PRD Acceptance Criteria ↔ Module Mapping

| PRD §22 Acceptance Criterion | Responsible Module(s) |
|------------------------------|----------------------|
| Images processed locally | MOD-04, MOD-09 |
| No cloud dependency | MOD-04, MOD-09 |
| Supported languages recognized | MOD-05 |
| Framework detection functions correctly | MOD-05 |
| Extracted code is editable | MOD-07 |
| Sharing works through Android Share Sheet | MOD-08 |
| Temporary images deleted after session | MOD-09 |
| No source code transmitted without user action | MOD-08, MOD-09 |
| Performance targets met | MOD-01, MOD-03, MOD-04, MOD-05, MOD-07 |
| Security requirements satisfied | MOD-09 (all) |

---

*This document should be updated as modules are completed and as new requirements emerge.*
