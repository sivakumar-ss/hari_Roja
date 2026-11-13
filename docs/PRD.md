# Product Requirements Document (PRD)
# AI-Powered Personal Finance Advisor for Indian Users

**Version:** 1.0
**Status:** Approved
**Primary Source of Truth:** This document

---

## 1. Product Overview

**Name:** AI-Powered Personal Finance Advisor

**Tagline:** A trustworthy, India-focused personal finance companion that helps users
understand, manage, and improve their financial health using deterministic finance
engines, machine learning forecasts, and a safety-grounded AI chatbot.

**Target Users:** Indian individuals and households managing income, expenses, savings,
loans/EMIs, investments, goals, and retirement planning. Supports English and Hindi.

**Platforms:** Mobile (Android first, iOS-ready), built with Flutter.

**Backend:** InsForge (PostgreSQL, auth, storage, edge functions, AI gateway).

---

## 2. Problem Statement

Indian users lack an accessible, trustworthy, privacy-respecting tool that combines
day-to-day financial tracking with explainable financial health scoring, goal planning,
risk assessment, inflation-aware projections, scheme guidance, and safe AI assistance.
Existing tools either expose data insecurely, fabricate numbers via LLMs, or lack
India-specific context (city tiers, government schemes, rupee formatting).

## 3. Goals

- Provide secure, user-specific financial tracking (income, expense, savings, loans,
  EMI, investments).
- Compute a deterministic 0-100 financial health score with explainable components.
- Forecast expenses/savings/shortfall for 3-6 months using Linear Regression and
  Random Forest, with honest cold-start fallback.
- Deliver personalized, data-grounded recommendations and alerts.
- Provide a safety-grounded AI chatbot that never invents financial data.
- Guide users to government schemes with deterministic eligibility + official links.
- Assess financial risk deterministically.
- Adjust goals for inflation (nominal vs real).
- Support English/Hindi, simple-language mode, and optional voice I/O.
- Provide anonymized multi-tier (Tier 1/2/3 city) pattern comparisons.
- Enforce privacy, consent, data export/deletion, and user data isolation.

## 4. Non-Goals

- Not a licensed financial advisor; all guidance is informational.
- No guaranteed investment returns.
- No real-money transactions or payment processing in v1.
- No real-time market data integration in v1.

## 5. User Personas

- **Priya (28, Tier 1, salaried):** tracks expenses, saves for a house, needs alerts.
- **Ramesh (45, Tier 2, self-employed):** loans/EMI, retirement readiness, schemes.
- **Anita (22, Tier 3, student):** simple language, low income, first savings goal.

## 6. Functional Requirements

### P0 (Must Have)

FR-001 Registration, login, logout, session persistence, protected routes.
FR-002 Onboarding collecting name, age, education, occupation, income, city, city tier,
        financial goals, language, consent.
FR-003 Deterministic city-tier mapping (Tier 1/2/3) stored and used by analytics.
FR-004 Income CRUD (amount, category, date, description).
FR-005 Expense CRUD (amount, category, date, description).
FR-006 Savings tracking (current savings, entries, savings rate).
FR-007 Loans & EMI tracking (principal, outstanding, interest, tenure, EMI, due date).
FR-008 Investments tracking (type, amount, date).
FR-009 Financial health score 0-100 across savings, spending, debt, emergency fund,
        investments, retirement readiness; with reasons and suggestions.
FR-010 Financial goals (emergency fund, education, house, vehicle, retirement, custom)
        with progress, required contribution, on-track status.
FR-011 Dashboard with monthly income, expenses, savings, savings rate, score, goal
        progress, alerts, predictions, recommendations, risk level + charts.
FR-012 Alerts (overspending, high EMI, low savings, low emergency fund, goal deviation)
        with severity, reason, triggering data, read/unread, dismiss, mute.
FR-013 ML predictions: Linear Regression + Random Forest; expense/savings/shortfall
        forecast 3-6 months; model selection by validation error; metadata tracked.
FR-014 Cold-start fallback: tier-based averages with LOW CONFIDENCE label.
FR-015 Personalized recommendations with reason, supporting data, action, impact,
        dismiss, mark-done.
FR-016 AI chatbot grounded in verified user data; disclaimer; chat history; user-scoped.
FR-017 Government schemes (PMJDY, PMJJBY, PMSBY, APY, PPF, SSY) deterministic
        eligibility + official links + indicative label.
FR-018 Risk assessment (LOW/MEDIUM/HIGH) with factors and actions.
FR-019 Inflation analysis (assumption input; nominal vs real; required contribution).
FR-020 Simple-language mode toggle.
FR-021 English/Hindi localization via Flutter l10n.
FR-022 Voice input/output (speech-to-text, text-to-speech), optional, graceful fallback.
FR-023 Multi-tier pattern analysis (anonymized aggregates by city tier).
FR-024 Privacy: consent, data export, data deletion, isolation, secure storage.

### P1

FR-025 Alert preferences.
FR-026 Chat session management.
FR-027 Prediction model versioning & metrics display.
FR-028 Recommendation lifecycle (dismiss/done).
FR-029 Performance optimization (dashboard < 3s on mid-range).

### P2

FR-030 Multi-tier pattern analysis (P2 feature, implemented).
FR-031 Additional Indian languages extensibility.

## 7. Non-Functional Requirements

NFR-001 Security: RLS on all user tables; no cross-user access.
NFR-002 Privacy: minimal logging; no PII in logs; consent recorded.
NFR-003 Performance: dashboard loads < 3s; app usable on low-end phones.
NFR-004 Reliability: graceful degradation when AI/ML/voice unavailable.
NFR-005 Accessibility: readable text, contrast, tap targets.
NFR-006 Offline handling: useful messages, no crashes, no fake success.
NFR-007 Test coverage: unit, widget, integration, security tests.
NFR-008 Maintainability: clean architecture, documented.

## 8. AI/ML Architecture

- Deterministic engine owns all calculations, scores, risk, eligibility, inflation,
  alerts, goal status.
- ML owns forecasting & pattern detection only.
- LLM owns conversational explanation only, grounded in verified context.
- Chatbot must never invent numbers; backend computes, AI explains.
- Chatbot disclaimer required.

## 9. Data Model (High-Level)

profiles, cities, income_entries, expense_entries, savings_entries, loans, emis,
investments, financial_goals, financial_scores, financial_score_components,
financial_risks, predictions, prediction_models, recommendations, alerts,
alert_preferences, government_schemes, chat_sessions, chat_messages, user_settings,
consents, pattern_aggregates.

## 10. Security & Privacy

- User-level data isolation via RLS (auth.uid()).
- Secrets never committed; keys in .env.local / .insforge/project.json.
- Consent recorded with timestamp.
- Data export and deletion endpoints.
- Minimal logging; no sensitive data in logs.

## 11. Localization

English (en) and Hindi (hi) via Flutter gen-l10n. Extensible to more Indian languages.

## 12. Voice

Speech-to-text and text-to-speech optional; graceful fallback; en/hi where supported.

## 13. Release Phases

Phase 0 architecture -> ... -> Phase 24 documentation/release.

## 14. Risks & Assumptions

- AI provider requires API key (provided: Groq key gsk_...). If unavailable, chatbot
  returns structured deterministic answer without LLM prose.
- ML runs in-app (Dart) for v1; backend Python optional future.
- Legal compliance claims require legal review.

## 15. Acceptance Criteria (Sample)

- User can register, log in, complete onboarding, add income/expense, see dashboard
  with real data, score, goals, alerts, predictions, recommendations, chatbot reply,
  scheme eligibility, risk, inflation projection, toggle language/voice/simple mode.
- No cross-user data access (tested).
- No fabricated numbers in chatbot (tested with grounding).
- Cold-start shows LOW CONFIDENCE.

---

*End of PRD*
