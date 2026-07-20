# Key Performance Indicators (KPI)

**Project Name:** SecureCode OCR *(Working Title)*

**Version:** 1.0

**Document Owner:** Product Team

**Status:** Draft

**Last Updated:** July 2026

---

## Overview

This document defines the Key Performance Indicators (KPIs) for SecureCode OCR. These KPIs are derived directly from the Product Vision and Product Requirements Document (PRD) and are organized around the five core product principles: **Privacy First**, **Offline First**, **Developer Centric**, **Enterprise Ready**, and **Simple User Experience**.

Each KPI includes a definition, target threshold, measurement method, and priority tier.

---

## KPI Categories

1. [Technical Performance KPIs](#1-technical-performance-kpis)
2. [Privacy & Security KPIs](#2-privacy--security-kpis)
3. [OCR Accuracy KPIs](#3-ocr-accuracy-kpis)
4. [User Engagement KPIs](#4-user-engagement-kpis)
5. [Reliability & Stability KPIs](#5-reliability--stability-kpis)
6. [Product Adoption KPIs](#6-product-adoption-kpis)

---

## 1. Technical Performance KPIs

> Derived from PRD Section 13 — Performance Requirements

These KPIs measure how fast and efficiently the application performs on mid-range Android devices without internet connectivity.

| KPI | Target | Priority | Measurement Method |
|-----|--------|----------|--------------------|
| **App Startup Time** | < 2 seconds | 🔴 Critical | Time from app launch to Home Screen ready state |
| **OCR Processing Time** | < 3 seconds | 🔴 Critical | Time from image submission to extracted text display |
| **Language Detection Time** | < 1 second | 🟠 High | Time from OCR output to language label displayed |
| **Framework Detection Time** | < 1 second | 🟠 High | Time from OCR output to framework label displayed |
| **Editor Open Time** | < 500 milliseconds | 🟠 High | Time from extraction complete to editor fully loaded |
| **Memory Usage** | Within mid-range Android budget | 🟡 Medium | Peak memory during OCR processing session |
| **App Install Size** | Minimized (local OCR model included) | 🟡 Medium | APK size at release |

---

## 2. Privacy & Security KPIs

> Derived from PRD Section 12 — Security Requirements and Product Vision — Privacy First Principle

These KPIs validate that the application meets its core privacy commitment: **nothing leaves the device unless the user explicitly chooses to share it**.

| KPI | Target | Priority | Measurement Method |
|-----|--------|----------|--------------------|
| **Zero Unauthorized Data Transmissions** | 0 incidents | 🔴 Critical | Network traffic audit; no outbound requests containing source code |
| **Zero Cloud OCR Calls** | 0 calls | 🔴 Critical | Static code analysis + network audit |
| **Temporary Image Auto-Deletion Rate** | 100% | 🔴 Critical | Session-end file system audit confirming no residual images |
| **Encrypted Temporary File Compliance** | 100% | 🔴 Critical | Storage audit confirming all temp files use encryption |
| **Metadata Stripped from Shared Output** | 100% | 🟠 High | Inspection of share payload — must contain plain text only |
| **Share Triggered Only by User Action** | 100% | 🔴 Critical | UX audit verifying no auto-sharing behavior |
| **No Source Code in Analytics/Telemetry** | 0 violations | 🟠 High | Analytics payload inspection |

---

## 3. OCR Accuracy KPIs

> Derived from PRD Section 8 — Success Metrics and Functional Requirements FR-004, FR-005, FR-006, FR-007, FR-008

These KPIs measure how accurately the application recognizes and understands programming code from images.

| KPI | Target | Priority | Measurement Method |
|-----|--------|----------|--------------------|
| **Overall OCR Character Accuracy** | > 95% | 🔴 Critical | Character Error Rate (CER) on benchmark image set |
| **Programming Language Detection Accuracy** | > 90% | 🔴 Critical | Correct language label / total extractions on labeled test set |
| **Framework Detection Accuracy** | > 85% | 🟠 High | Correct framework label / total detections on labeled test set |
| **Automatic Cleanup Success Rate** | > 90% | 🟠 High | % of sessions with line numbers, IDE artifacts, and noise removed correctly |
| **Confidence Highlight Coverage** | > 95% | 🟡 Medium | % of uncertain characters flagged for user review |
| **Supported Language Coverage** | C#, JS, TS, HTML, SQL, React, Angular, .NET | 🔴 Critical | Feature acceptance test across all supported languages |

### Supported Language Targets (v1.0)

| Language / Framework | Detection Target |
|----------------------|-----------------|
| C# | ✓ Supported |
| JavaScript | ✓ Supported |
| TypeScript | ✓ Supported |
| HTML | ✓ Supported |
| SQL | ✓ Supported |
| React | ✓ Supported |
| Angular | ✓ Supported |
| .NET / ASP.NET | ✓ Supported |
| JSON / YAML / XML | ✓ Supported |
| Stack Traces / Logs | ✓ Supported |

---

## 4. User Engagement KPIs

> Derived from PRD Section 8 — Success Metrics (Product) and the Product Vision — Success Definition

These KPIs measure how effectively users are completing the core extraction workflow: **Capture → Extract → Edit → Share**.

| KPI | Definition | Target | Priority |
|-----|------------|--------|----------|
| **Daily Active Users (DAU)** | Unique users performing at least one extraction per day | Grow month-over-month | 🟠 High |
| **Weekly Active Users (WAU)** | Unique users performing at least one extraction per week | Grow month-over-month | 🟠 High |
| **DAU / WAU Ratio** | Stickiness indicator | > 30% | 🟡 Medium |
| **Extraction Completion Rate** | % of sessions where OCR extraction completes successfully | > 90% | 🔴 Critical |
| **Average Extraction Time (User Perceived)** | Time from image selection to result displayed in editor | < 5 seconds total | 🟠 High |
| **Average Edit Duration** | Time users spend in the editor after extraction | Baseline in Month 1; trend downward over time | 🟡 Medium |
| **Share Completion Rate** | % of extraction sessions that result in a share action | Baseline in Month 1 | 🟡 Medium |
| **Camera vs. Gallery Import Ratio** | Usage split between camera capture and gallery import | Informational baseline | 🟡 Medium |
| **User Satisfaction Score (CSAT / NPS)** | User rating of the extraction experience | > 4.0 / 5.0 or NPS > 40 | 🟠 High |

---

## 5. Reliability & Stability KPIs

> Derived from PRD Section 8 — Success Metrics (Technical) and Section 13 — Performance Requirements

These KPIs ensure the application is stable across supported Android devices and usage scenarios.

| KPI | Target | Priority | Measurement Method |
|-----|--------|----------|--------------------|
| **Crash-Free Session Rate** | ≥ 99.5% | 🔴 Critical | Crash reporting (device-local or privacy-compliant analytics) |
| **ANR (App Not Responding) Rate** | < 0.5% | 🔴 Critical | Android Vitals monitoring |
| **OCR Engine Failure Rate** | < 1% | 🔴 Critical | % of sessions where OCR fails to return a result |
| **Session Cleanup Success Rate** | 100% | 🔴 Critical | % of sessions with all temp files deleted at session end |
| **Editor Load Failure Rate** | < 0.5% | 🟠 High | % of extractions where editor fails to open |

---

## 6. Product Adoption KPIs

> Derived from the Product Vision — Target Users and PRD Section 6 — Target Users

These KPIs measure growth, adoption, and enterprise reach.

| KPI | Definition | Target | Priority |
|-----|------------|--------|----------|
| **New Installs (Monthly)** | New unique installs per month | Grow month-over-month | 🟠 High |
| **30-Day Retention Rate** | % of new users still active 30 days after first install | > 40% | 🟠 High |
| **7-Day Retention Rate** | % of new users still active 7 days after first install | > 60% | 🟠 High |
| **Enterprise Sector Penetration** | % of users from Banking, Finance, Insurance, Government, Healthcare | Track segment growth | 🟡 Medium |
| **Google Play Store Rating** | Average star rating on Play Store | ≥ 4.3 / 5.0 | 🟠 High |
| **Privacy-Positive Reviews** | % of reviews positively mentioning privacy or offline capability | Positive trend | 🟡 Medium |

---

## KPI Priority Legend

| Symbol | Priority | Description |
|--------|----------|-------------|
| 🔴 Critical | Must meet at launch | Launch blocker if not achieved |
| 🟠 High | Target within first 30 days | Core product health |
| 🟡 Medium | Informational baseline | Long-term tracking and optimization |

---

## Acceptance Criteria Alignment

The following KPIs directly map to the formal acceptance criteria defined in PRD Section 22:

| Acceptance Criterion | Mapped KPI |
|----------------------|------------|
| Images processed locally | Zero Unauthorized Data Transmissions |
| No cloud dependency | Zero Cloud OCR Calls |
| Supported languages recognized | OCR Language Detection Accuracy > 90% |
| Framework detection functions correctly | Framework Detection Accuracy > 85% |
| Extracted code is editable | Editor Load Failure Rate < 0.5% |
| Sharing works through Android Share Sheet | Share Completion Rate (baseline) |
| Temporary images deleted after session | Session Cleanup Success Rate 100% |
| No source code transmitted without user action | Share Triggered Only by User Action 100% |
| Performance targets met | All Technical Performance KPIs |
| Security requirements satisfied | All Privacy & Security KPIs |

---

## Review Cadence

| Frequency | KPI Group |
|-----------|-----------|
| **Every Release** | Technical Performance, Privacy & Security, OCR Accuracy, Reliability |
| **Monthly** | User Engagement, Product Adoption |
| **Quarterly** | All KPIs — full review and target revision |

---

*This document should be reviewed and updated with each product version release.*
