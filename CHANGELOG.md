# Changelog

## [1.0.0] — 2026-05-11

Pierwsza publiczna wersja. Snapshot stanu po pilotażu w Project Master + 6 projektach ekosystemu.

### Reguły wykrywania

- **AI / LLM keys:** OpenAI (`sk-proj-`, legacy `sk-`), Anthropic (`sk-ant-`), ElevenLabs (`xi-api-key`)
- **Platforms:** Supabase `service_role` JWT
- **Polish PII (RODO):** PESEL, NIP (formatted i context-based), REGON, IBAN PL (z prefiksem i bez)
- **Built-in gitleaks rules:** `useDefault = true` (~150 wzorców: AWS, GCP, Stripe, GitHub PAT, Slack, Twilio, SendGrid, …)

### Allowlist (defaults)

Pliki: obrazy, PDF, ZIP, fonty, lock files, `node_modules/`, `.next/`, `dist/`, `build/`, `docs/examples`  
Wzorce: `AKIAIOSFODNN7EXAMPLE`, `sk-test-`, `sk-dummy`, `example*key`, `fake*token`  
Stopwords: `example`, `fixture`, `dummy`, `placeholder`

### Hook pre-push

- Skanuje zakres `remote_sha..local_sha` (tylko nowe commity, nie cała historia)
- Komunikaty po polsku
- Pomija jeśli gitleaks nie jest zainstalowany (z ostrzeżeniem)
- Pomija jeśli `.gitleaks.toml` nie istnieje (z ostrzeżeniem)

### Instalator

- Curl-able z `raw.githubusercontent.com`
- Pyta przed nadpisaniem istniejącego `.gitleaks.toml`
- Backup istniejącego `pre-push` jako `.backup`
- Wymaga gitleaks (z hintem jak zainstalować)

### Znane ograniczenia

- Sekrety **już w historii repo** wymagają BFG / git-filter-repo — Secret Shield ich nie czyści, tylko blokuje **nowe** wysłanie
- Hook lokalny — każdy developer musi go zainstalować osobno (nie chroni przed kimś bez hooka)
- Brak wsparcia dla Windows w smoke testach pilota (zgłoszenia mile widziane)
