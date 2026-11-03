# It's Your Turn · Festival Compa

Pagină web pentru telefon, pentru adolescenții de la Festival Compa. Alegi unul din cele 5 domenii (Serve, See, Encourage, Speak, Pray), tragi o carte și primești o provocare pentru săptămâna asta.

- **Live:** https://it-s-your-turn.github.io/
- **Repo:** https://github.com/It-s-Your-Turn/it-s-your-turn.github.io

## Structură

Nu există build sau framework. Toată pagina e într-un singur fișier. Singura dependență e clientul Supabase pentru contorul comun, încărcat doar după ce contorul e configurat.

| Fișier | Ce e |
|---|---|
| `index.html` | Toată pagina: HTML, CSS și JavaScript inline |
| `share.png` | Imaginea de previzualizare la share (Open Graph), 1200×630 |
| `.nojekyll` | Oprește procesarea Jekyll pe GitHub Pages |
| `supabase.sql` | Tabelele și regulile contorului comun. Se rulează o singură dată în Supabase |

## Rulare locală

```bash
python3 -m http.server 8000
```

Apoi deschide http://localhost:8000 pe telefon sau în modul mobil al browserului.

## Contorul comun („1.000 de fapte de iubire”)

Cât timp valorile Supabase din `COMMUNITY` (în `index.html`) sunt goale, contorul apare pe pagină fără număr („– / 1.000”).

Pentru activare:

1. Creează un proiect Supabase.
2. Activează **Anonymous Sign-ins** la Authentication > Providers.
3. Rulează `supabase.sql` în SQL Editor.
4. Completează `supabaseUrl` și `supabaseKey` în `COMMUNITY`, cu cheia publică (publishable/anon). Nu pune niciodată cheia `service_role` în site.
5. Verifică limita de autentificări anonime pe IP la Authentication > Rate Limits. La festival, mulți participanți pot ieși pe același IP.

Fiecare telefon primește un cod anonim, iar o provocare se numără o singură dată pentru fiecare cod. Bifările sunt pe încredere, nu dovezi: cine își șterge datele din browser primește un cod nou. Progresul personal rămâne pe telefon, iar site-ul trimite la server doar ce lipsește. Dacă serverul nu răspunde, contorul rămâne la ultimul număr primit sau fără număr, iar cărțile merg în continuare. „Scoate bifa” scade din total, „Ia-o de la capăt” nu. După 1.000 contorul se oprește, dar progresul personal continuă.

### Resetarea contorului

Contorul se pune la zero doar din Supabase, nu din site. În SQL Editor, rulează:

```sql
select public.mission_reset('its-your-turn-1000');
```

Comanda șterge toate bifările din baza de date și nu se poate anula. Progresul personal de pe telefoane rămâne, dar cărțile deja bifate nu se mai numără în noua rundă. Se numără doar provocările bifate după resetare. Telefoanele deschise văd noul total în cel mult 15 secunde.

## Publicare

Site-ul e servit de GitHub Pages din ramura `main`, rădăcina repo-ului. Orice push pe `main` ajunge live în 1–2 minute.

## Unde se schimbă lucrurile în `index.html`

- **`DOMAINS`**: cele 5 domenii, cu nume, motto și cele 5 provocări ale fiecăruia. Aici se editează textele cărților.
- **`ICONS`**: iconițele SVG ale domeniilor.
- **`STATES`**: ce butoane apar pentru fiecare stare a cărții (trasă, bifată, domeniu terminat) și textul lor.
- **`ACT`**: ce face fiecare buton (bifează, trage următoarea carte, scoate bifa, ia-o de la capăt).
- **`BADGES`**: insignele, cu numele, pragul (`min`, din totalul de 25 de provocări), simbolul și culoarea.
- **`XP`**: câte puncte primește utilizatorul pentru fiecare provocare făcută. Textul de pe butonul din fereastra de confirmare (`#confirm-ok`) se schimbă separat.
- **`KEY`**: cheia din `localStorage` unde se salvează progresul utilizatorului (`its-your-turn-compa-v1`). Dacă se schimbă structura datelor salvate, cheia trebuie mărită la `v2`, altfel utilizatorii vechi pot avea date incompatibile.
- Funcțiile principale: `renderHome`, `openDomain`, `draw`, `fillChallenge`, `fillComplete`, `goHome`, `markDone`, `renderProgress`, `openProgress`, `showUnlocked`, `downloadBadge`, `renderCommunity`, `syncCommunity`, `connectCommunity`.

## Identitate vizuală

- Fonturi Google: Anton (titluri), Oswald (etichete), Jost (text).
- Bleumarin `#0F2A45`, portocaliu `#E8693A`.
- Culorile domeniilor: Serve `#E8693A`, See `#3FA690`, Encourage `#7BA6E2`, Speak `#E8748A`, Pray `#A77BDD`.

## Reguli pentru texte

- Româna trebuie să sune natural, vorbit, la persoana a II-a („tu”). Nu traduceri cuvânt cu cuvânt din engleză.
- Diacriticele se scriu cu virgulă dedesubt: ș, ț (nu ş, ţ cu sedilă).
- În engleză rămân doar: „It's your turn”, „to love like Jesus”, numele celor 5 domenii și „Festival Compa”.

## Atenție la adresă

Toate materialele tipărite (afișe, roll-up-uri, stickere) au un cod QR care duce la https://it-s-your-turn.github.io/. Dacă se mută site-ul pe alt domeniu sau se redenumește organizația GitHub, codurile QR deja tipărite nu mai funcționează. Atunci trebuie pusă o redirecționare de la adresa veche.
