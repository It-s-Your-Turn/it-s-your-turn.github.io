# It's Your Turn · Festival Compa

Pagină web pentru telefon, pentru adolescenții de la Festival Compa. Alegi unul din cele 5 domenii (Serve, See, Encourage, Speak, Pray), tragi o carte și primești o provocare pentru săptămâna asta.

- **Live:** https://it-s-your-turn.github.io/
- **Repo:** https://github.com/It-s-Your-Turn/it-s-your-turn.github.io

## Structură

Nu există build, framework sau dependențe. Totul e într-un singur fișier.

| Fișier | Ce e |
|---|---|
| `index.html` | Toată pagina: HTML, CSS și JavaScript inline |
| `share.png` | Imaginea de previzualizare la share (Open Graph), 1200×630 |
| `.nojekyll` | Oprește procesarea Jekyll pe GitHub Pages |

## Rulare locală

```bash
python3 -m http.server 8000
```

Apoi deschide http://localhost:8000 pe telefon sau în modul mobil al browserului.

## Publicare

Site-ul e servit de GitHub Pages din ramura `main`, rădăcina repo-ului. Orice push pe `main` ajunge live în 1–2 minute.

## Unde se schimbă lucrurile în `index.html`

- **`DOMAINS`**: cele 5 domenii, cu nume, motto și cele 5 provocări ale fiecăruia. Aici se editează textele cărților.
- **`ICONS`**: iconițele SVG ale domeniilor.
- **`STATES`**: ce butoane apar pentru fiecare stare a cărții (trasă, bifată, domeniu terminat) și textul lor.
- **`ACT`**: ce face fiecare buton (bifează, trage următoarea carte, scoate bifa, ia-o de la capăt).
- **`KEY`**: cheia din `localStorage` unde se salvează progresul utilizatorului (`its-your-turn-compa-v1`). Dacă se schimbă structura datelor salvate, cheia trebuie mărită la `v2`, altfel utilizatorii vechi pot avea date incompatibile.
- Funcțiile principale: `renderHome`, `openDomain`, `draw`, `fillChallenge`, `fillComplete`, `goHome`.

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
