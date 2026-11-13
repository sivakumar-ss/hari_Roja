-- Initial schema for AI-Powered Personal Finance Advisor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Cities (global reference)
CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  state TEXT,
  tier TEXT NOT NULL CHECK (tier IN ('Tier 1','Tier 2','Tier 3')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Profiles
CREATE TABLE IF NOT EXISTS profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  age INT CHECK (age IS NULL OR (age >= 0 AND age <= 120)),
  education TEXT,
  occupation TEXT,
  monthly_income NUMERIC(14,2) DEFAULT 0,
  city_id UUID REFERENCES cities(id),
  city_tier TEXT CHECK (city_tier IS NULL OR city_tier IN ('Tier 1','Tier 2','Tier 3')),
  preferred_language TEXT NOT NULL DEFAULT 'en' CHECK (preferred_language IN ('en','hi')),
  simple_language_mode BOOLEAN NOT NULL DEFAULT false,
  voice_enabled BOOLEAN NOT NULL DEFAULT false,
  onboarding_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Income entries
CREATE TABLE IF NOT EXISTS income_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  category TEXT NOT NULL,
  source TEXT,
  entry_date DATE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_income_user_date ON income_entries(user_id, entry_date);

-- Expense entries
CREATE TABLE IF NOT EXISTS expense_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  category TEXT NOT NULL,
  entry_date DATE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_expense_user_date ON expense_entries(user_id, entry_date);

-- Savings entries
CREATE TABLE IF NOT EXISTS savings_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(14,2) NOT NULL,
  entry_date DATE NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_savings_user_date ON savings_entries(user_id, entry_date);

-- Loans
CREATE TABLE IF NOT EXISTS loans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  principal NUMERIC(14,2) NOT NULL CHECK (principal >= 0),
  outstanding NUMERIC(14,2) NOT NULL CHECK (outstanding >= 0),
  interest_rate NUMERIC(6,3) NOT NULL CHECK (interest_rate >= 0),
  tenure_months INT NOT NULL CHECK (tenure_months > 0),
  emi NUMERIC(14,2) NOT NULL CHECK (emi >= 0),
  start_date DATE,
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_loans_user ON loans(user_id);

-- Investments
CREATE TABLE IF NOT EXISTS investments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  name TEXT,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  invested_on DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_investments_user ON investments(user_id);

-- Financial goals
CREATE TABLE IF NOT EXISTS financial_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  goal_type TEXT NOT NULL CHECK (goal_type IN ('emergency_fund','education','house','vehicle','retirement','custom')),
  target_amount NUMERIC(14,2) NOT NULL CHECK (target_amount > 0),
  current_amount NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
  target_date DATE,
  monthly_contribution NUMERIC(14,2) DEFAULT 0,
  inflation_rate NUMERIC(5,4) DEFAULT 0.06,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','completed','paused','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_goals_user ON financial_goals(user_id);

-- Financial scores
CREATE TABLE IF NOT EXISTS financial_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  overall_score NUMERIC(5,2) NOT NULL CHECK (overall_score >= 0 AND overall_score <= 100),
  savings_score NUMERIC(5,2) NOT NULL,
  spending_score NUMERIC(5,2) NOT NULL,
  debt_score NUMERIC(5,2) NOT NULL,
  emergency_score NUMERIC(5,2) NOT NULL,
  investment_score NUMERIC(5,2) NOT NULL,
  retirement_score NUMERIC(5,2) NOT NULL,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  inputs JSONB
);
CREATE INDEX IF NOT EXISTS idx_scores_user_time ON financial_scores(user_id, computed_at DESC);

-- Financial risks
CREATE TABLE IF NOT EXISTS financial_risks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  risk_level TEXT NOT NULL CHECK (risk_level IN ('LOW','MEDIUM','HIGH')),
  factors JSONB NOT NULL DEFAULT '[]'::jsonb,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_risks_user_time ON financial_risks(user_id, computed_at DESC);

-- Predictions
CREATE TABLE IF NOT EXISTS predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  model_type TEXT NOT NULL CHECK (model_type IN ('linear_regression','random_forest','tier_average')),
  model_version TEXT NOT NULL,
  target TEXT NOT NULL CHECK (target IN ('expense','savings','shortfall')),
  horizon_months INT NOT NULL CHECK (horizon_months BETWEEN 1 AND 12),
  values JSONB NOT NULL,
  confidence TEXT NOT NULL CHECK (confidence IN ('LOW','MEDIUM','HIGH')),
  validation_metric NUMERIC(12,6),
  trained_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_predictions_user ON predictions(user_id, created_at DESC);

-- Recommendations
CREATE TABLE IF NOT EXISTS recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  reason TEXT NOT NULL,
  supporting_data JSONB,
  recommended_action TEXT NOT NULL,
  expected_impact TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','dismissed','done')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_recs_user ON recommendations(user_id, status);

-- Alerts
CREATE TABLE IF NOT EXISTS alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('info','warning','critical')),
  triggering_data JSONB,
  is_read BOOLEAN NOT NULL DEFAULT false,
  is_dismissed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_alerts_user ON alerts(user_id, created_at DESC);

-- Alert preferences
CREATE TABLE IF NOT EXISTS alert_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  muted_categories JSONB NOT NULL DEFAULT '[]'::jsonb,
  enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Government schemes (global)
CREATE TABLE IF NOT EXISTS government_schemes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  eligibility TEXT NOT NULL,
  conditions TEXT,
  official_url TEXT NOT NULL,
  last_reviewed DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Chat sessions
CREATE TABLE IF NOT EXISTS chat_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user ON chat_sessions(user_id, updated_at DESC);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('user','assistant','system')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id, created_at);

-- User settings
CREATE TABLE IF NOT EXISTS user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  theme TEXT DEFAULT 'system',
  notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  simple_language_mode BOOLEAN NOT NULL DEFAULT false,
  voice_enabled BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Consents
CREATE TABLE IF NOT EXISTS consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  consent_type TEXT NOT NULL,
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_consents_user ON consents(user_id);

-- Pattern aggregates (anonymized, global read)
CREATE TABLE IF NOT EXISTS pattern_aggregates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_tier TEXT NOT NULL CHECK (city_tier IN ('Tier 1','Tier 2','Tier 3')),
  category TEXT NOT NULL,
  metric TEXT NOT NULL,
  avg_value NUMERIC(14,4) NOT NULL,
  sample_size INT NOT NULL DEFAULT 0,
  period TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (city_tier, category, metric, period)
);

-- RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE income_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE savings_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_risks ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE consents ENABLE ROW LEVEL SECURITY;

-- Cities readable by authenticated
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE government_schemes ENABLE ROW LEVEL SECURITY;
ALTER TABLE pattern_aggregates ENABLE ROW LEVEL SECURITY;

-- Policies: user owns own rows
CREATE POLICY profiles_owner ON profiles FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY income_owner ON income_entries FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY expense_owner ON expense_entries FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY savings_owner ON savings_entries FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY loans_owner ON loans FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY investments_owner ON investments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY goals_owner ON financial_goals FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY scores_owner ON financial_scores FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY risks_owner ON financial_risks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY predictions_owner ON predictions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY recs_owner ON recommendations FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY alerts_owner ON alerts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY alertprefs_owner ON alert_preferences FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY chatsessions_owner ON chat_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY chatmessages_owner ON chat_messages FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY usersettings_owner ON user_settings FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY consents_owner ON consents FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Global read policies
CREATE POLICY cities_read ON cities FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY schemes_read ON government_schemes FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY patterns_read ON pattern_aggregates FOR SELECT USING (auth.uid() IS NOT NULL);

-- Seed cities (sample Indian cities with tiers)
INSERT INTO cities (name, state, tier) VALUES
 ('Mumbai','Maharashtra','Tier 1'),
 ('Delhi','Delhi','Tier 1'),
 ('Bengaluru','Karnataka','Tier 1'),
 ('Chennai','Tamil Nadu','Tier 1'),
 ('Kolkata','West Bengal','Tier 1'),
 ('Hyderabad','Telangana','Tier 1'),
 ('Pune','Maharashtra','Tier 1'),
 ('Ahmedabad','Gujarat','Tier 1'),
 ('Jaipur','Rajasthan','Tier 2'),
 ('Lucknow','Uttar Pradesh','Tier 2'),
 ('Chandigarh','Punjab','Tier 2'),
 ('Kochi','Kerala','Tier 2'),
 ('Indore','Madhya Pradesh','Tier 2'),
 ('Coimbatore','Tamil Nadu','Tier 2'),
 ('Nagpur','Maharashtra','Tier 2'),
 ('Patna','Bihar','Tier 3'),
 ('Bhubaneswar','Odisha','Tier 3'),
 ('Guwahati','Assam','Tier 3'),
 ('Ranchi','Jharkhand','Tier 3'),
 ('Mysuru','Karnataka','Tier 3')
ON CONFLICT (name) DO NOTHING;

-- Seed government schemes
INSERT INTO government_schemes (code, name, description, eligibility, conditions, official_url) VALUES
 ('PMJDY','Pradhan Mantri Jan Dhan Yojana','Basic savings bank account with zero balance and RuPay debit card.','Indian citizens 10+ years.','One account per person; Aadhaar preferred.','https://pmjdy.gov.in/'),
 ('PMJJBY','Pradhan Mantri Jeevan Jyoti Bima Yojana','Life insurance cover of Rs. 2 lakh.','Age 18-50 with bank account.','Annual premium auto-debited.','https://jansuraksha.gov.in/'),
 ('PMSBY','Pradhan Mantri Suraksha Bima Yojana','Accidental insurance cover Rs. 2 lakh (death) / Rs. 1 lakh (disability).','Age 18-70 with bank account.','Annual premium auto-debited.','https://jansuraksha.gov.in/'),
 ('APY','Atal Pension Yojana','Guaranteed pension Rs. 1000-5000/month from age 60.','Age 18-40, bank account, Aadhaar.','Minimum contribution period.','https://npscra.nsdl.co.in/'),
 ('PPF','Public Provident Fund','Long-term savings with tax benefits under 80C.','Any Indian resident.','15-year lock-in; min Rs. 500/year.','https://www.indiapost.gov.in/'),
 ('SSY','Sukanya Samriddhi Yojana','Savings scheme for girl child.','Girl child below 10 years; guardian.','Account till 21 years; tax benefits.','https://www.indiapost.gov.in/')
ON CONFLICT (code) DO NOTHING;

-- Seed pattern aggregates (sample anonymized)
INSERT INTO pattern_aggregates (city_tier, category, metric, avg_value, sample_size, period) VALUES
 ('Tier 1','food','monthly_spend', 8500, 1200, '2026'),
 ('Tier 1','rent','monthly_spend', 18000, 1200, '2026'),
 ('Tier 1','transport','monthly_spend', 4200, 1200, '2026'),
 ('Tier 2','food','monthly_spend', 5200, 900, '2026'),
 ('Tier 2','rent','monthly_spend', 9500, 900, '2026'),
 ('Tier 2','transport','monthly_spend', 2800, 900, '2026'),
 ('Tier 3','food','monthly_spend', 3800, 700, '2026'),
 ('Tier 3','rent','monthly_spend', 5500, 700, '2026'),
 ('Tier 3','transport','monthly_spend', 1900, 700, '2026')
ON CONFLICT (city_tier, category, metric, period) DO NOTHING;
