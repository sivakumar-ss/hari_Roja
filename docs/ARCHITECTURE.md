# Architecture

## Overview
Flutter mobile app + InsForge backend (PostgreSQL, auth, edge functions).

## Layers
- UI (features/*_screen.dart)
- State (Riverpod providers)
- Repositories (finance_repository, auth_repository)
- Services (InsforgeService, ScoreEngine, RiskEngine, MlForecast, etc.)
- Backend (InsForge: DB tables with RLS, edge function `chat`)

## Data flow
UI -> Provider -> Repository -> InsForge SDK -> Backend

## Security
RLS policies per user_id using auth.uid(). Secrets in InsForge, not client.
