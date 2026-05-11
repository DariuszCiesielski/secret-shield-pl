# Secret Shield PL

**Polska tarcza dla Twojego kodu na GitHubie.** Blokuje przypadkowe wysłanie haseł, kluczy API i polskich danych wrażliwych (PESEL, NIP, REGON, IBAN) zanim trafią na serwer.

> Snapshot v1.0 · maj 2026 · MIT License · Stack: [gitleaks](https://github.com/gitleaks/gitleaks) + pre-push hook

---

## Po co Ci to

Jeśli budujesz albo zlecasz aplikacje korzystające z AI (ChatGPT, Claude, Gemini, ElevenLabs, automatyzacje Make.com / n8n / Zapier), Twój kod zawiera **klucze API** — to praktycznie hasła do usług, za które płacisz Ty.

Trzy klasyczne sytuacje w których klucz przypadkiem trafia na GitHub:

1. **Aplikacja budowana z AI** — programista (albo Ty z Claude Code / Cursor) commituje plik `.env` z kluczami. GitHub indeksuje, boty go odnajdą w kilka minut. Pojawia się rachunek na 500–5000 USD od OpenAI lub Anthropic.
2. **Kod od freelancera / wspólnika / agenta AI** — przekazują Ci ZIP albo robią pull request z kluczami w środku, "bo tak im było wygodniej".
3. **Wyeksportowany scenariusz Make.com / n8n** — wysyłasz znajomemu lub publikujesz jako przykład, a w środku Twój klucz Stripe / ElevenLabs / Supabase.

**Secret Shield PL skanuje każdy push** i blokuje wysłanie jeśli wykryje coś co wygląda jak sekret.

## Co konkretnie wyłapuje

**Klucze AI / LLM:**
- OpenAI (`sk-proj-...`, `sk-...`)
- Anthropic (`sk-ant-...`)
- ElevenLabs (`xi-api-key`)

**Klucze platform:**
- Supabase service_role (JWT z claim `service_role`)
- Wbudowane reguły gitleaks: AWS, Google Cloud, Stripe, GitHub PAT, Slack, Twilio, SendGrid i ~150 innych

**Polskie dane wrażliwe (RODO):**
- PESEL (11 cyfr z kontekstem słowa "pesel")
- NIP w formacie `XXX-XXX-XX-XX` lub `XXXXXXXXXX` z kontekstem
- REGON (9 lub 14 cyfr z kontekstem)
- Numery kont bankowych (IBAN PL z prefiksem lub bez)

## Jak włączyć w 5 minut

### Krok 1. Zainstaluj gitleaks (silnik skanujący)

**macOS:**
```bash
brew install gitleaks
```

**Linux / Windows:** zobacz [gitleaks/gitleaks#installing](https://github.com/gitleaks/gitleaks#installing)

### Krok 2. Zainstaluj Secret Shield PL

Z roota Twojego projektu (czyli z katalogu w którym jest folder `.git`):

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/DariuszCiesielski/secret-shield-pl@main/install.sh | bash
```

> Alternatywnie (bezpośrednio z GitHub raw — wolniejsza propagacja CDN, do ~5 min cache TTL):  
> `curl -fsSL https://raw.githubusercontent.com/DariuszCiesielski/secret-shield-pl/main/install.sh | bash`

Instalator:
- Pobiera `.gitleaks.toml` (konfigurację) do roota repo
- Pobiera `pre-push` hook do `.git/hooks/`
- Sprawdza czy nic nie nadpisuje (pyta o backup gdyby tak było)

### Krok 3. Sprawdź czy działa

```bash
# Utwórz testowy plik z fake kluczem (skopiuj ten format, podstaw dowolne 40 znaków po sk-proj-)
echo 'const KEY = "sk-proj-..."' > test-leak.js
git add test-leak.js
git commit -m "test"
git push   # ← powinno zostać ZABLOKOWANE z komunikatem po polsku

# Cofnij test
rm test-leak.js
git reset --hard HEAD~1
```

Jeśli push został zablokowany — działa. Jeśli przeszedł — sprawdź czy gitleaks jest zainstalowany (`gitleaks version`) i czy `.gitleaks.toml` istnieje w roocie repo.

## Co zrobić gdy Secret Shield zablokuje push

Hook wyświetli który plik i którą linię zakwestionował. Trzy scenariusze:

**1. To realny sekret który nie powinien tam być:**
- Usuń sekret z kodu (zastąp wczytywaniem z `.env` lub Vault)
- Jeśli był wcześniej commitowany — przepisz historię (`git rebase -i` lub [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/))
- **ZROTUJ KLUCZ** — jeśli trafił chociaż chwilowo na GitHub, traktuj go jako spalony

**2. To fałszywy alarm (testowy klucz, fixture, przykład w dokumentacji):**

Dodaj wzorzec do sekcji `[allowlist]` w `.gitleaks.toml`:

```toml
[allowlist]
regexes = [
  '''twój-konkretny-wzorzec-tutaj''',
]
```

Lub wyklucz cały plik / katalog:
```toml
[allowlist]
paths = [
  '''docs/examples/.*''',
  '''fixtures/test-data\.json''',
]
```

**3. Awaryjnie chcę pominąć skan dla tego pushu** (nie zalecane):
```bash
git push --no-verify
```

## Dla kogo to jest

✅ **Polskie firmy** używające AI w aplikacjach — szczególnie chronisz PESEL/NIP klientów  
✅ **Solo developerzy / agencje** pracujące z Claude Code, Cursor, Copilot — model AI nie wie kiedy `.env` ma `.gitignore`  
✅ **Zespoły z freelancerami** — chroni przed kluczami w cudzym kodzie  
✅ **Mniejsze projekty SaaS** w fazie MVP — kiedy szybkość developmentu wygrywa nad rygorem  

❌ Nie zastępuje pełnego DLP w korporacji (SIEM, secrets manager, vault)  
❌ Nie chroni przed sekretami które JUŻ są w historii repo (do tego trzeba BFG / git-filter-repo)  

## Co to NIE robi

- **Nie skanuje serwerów** — to tylko hook po stronie developera, przy push
- **Nie chroni przed atakiem człowieka z dostępem do repo** — chroni przed *pomyłką*, nie złośliwością
- **Nie szyfruje** — gitleaks tylko wykrywa wzorce, nie ukrywa danych

## Czy jest sens to mieć skoro mam już .gitignore?

Tak. `.gitignore` chroni przed **dodaniem pliku do gita**. Sekret może trafić na GitHub na 10 innych sposobów:
- Wklejony bezpośrednio w kod (`const KEY = "sk-..."`)
- W komentarzu z poprzedniej sesji ("// TODO: usunąć ten klucz po teście")
- W pliku konfiguracyjnym którego ktoś zapomniał w `.gitignore`
- W pliku migracji bazy danych z testowymi danymi z PESELami
- W exportcie scenariusza Make.com załączonym do issue na GitHubie
- W historii commitów po dawnym `.env` (nawet jeśli usunąłeś, jest w historii)

Secret Shield skanuje **kod w commitach** — tam gdzie `.gitignore` już Cię nie chroni.

## Stack techniczny

- **Silnik:** [gitleaks](https://github.com/gitleaks/gitleaks) 8.x (open source, MIT)
- **Reguły:** built-in (`useDefault = true`) + 9 reguł polskich/AI specyficznych
- **Integracja:** pre-push hook (lokalny, per-developer)
- **Język komunikatów:** polski

## Aktualizacje

To jest **snapshot v1.0** — opublikowany w maju 2026. Świat sekretów się zmienia (nowe usługi, nowe formaty kluczy), więc okresowo (co ~pół roku) odśwież sobie konfigurację:

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/DariuszCiesielski/secret-shield-pl@main/.gitleaks.toml -o .gitleaks.toml
```

Plus po większych zmianach zobacz [CHANGELOG.md](CHANGELOG.md).

## Licencja

MIT — używaj jak chcesz, modyfikuj, redystrybuuj. Bez gwarancji (jak każde narzędzie security — to **warstwa** ochrony, nie tarcza absolutna).

## Kontakt / problemy

Issue na GitHubie: https://github.com/DariuszCiesielski/secret-shield-pl/issues

---

*Autor: [Dariusz Ciesielski](https://github.com/DariuszCiesielski) · AI w Biznesie · 2026*
