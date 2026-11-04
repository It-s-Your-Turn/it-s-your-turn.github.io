# It's Your Turn · Festival Compa

Pagină web pentru telefon, pentru adolescenții de la Festival Compa. Alegi unul din cele 5 domenii (Serve, See, Encourage, Speak, Pray), tragi o carte și primești o provocare pentru săptămâna asta.

- **Live:** https://it-s-your-turn.github.io/
- **Repo:** https://github.com/It-s-Your-Turn/it-s-your-turn.github.io

## Structură

Nu există build sau framework. Toată pagina e într-un singur fișier. Singura dependență e clientul Supabase pentru contorul comun și comenzile din magazin, încărcat doar după ce contorul e configurat.

| Fișier | Ce e |
|---|---|
| `index.html` | Toată pagina: HTML, CSS și JavaScript inline |
| `share.png` | Imaginea de previzualizare la share (Open Graph), 1200×630 |
| `.nojekyll` | Oprește procesarea Jekyll pe GitHub Pages |
| `manifest.json` | Numele, culorile și iconițele pentru ecranul principal al telefonului |
| `icon-180.png`, `icon-192.png`, `icon-512.png` | Iconițele pentru ecranul principal |
| `supabase.sql` | Tabelele și regulile contorului comun. Se rulează o singură dată în Supabase |
| `supabase-store.sql` | Tabelele și regulile comenzilor din magazin. Se rulează în Supabase înainte să se publice magazinul |
| `store/` | Pozele produselor |

## Rulare locală

```bash
python3 -m http.server 8000
```

Apoi deschide http://localhost:8000 pe telefon sau în modul mobil al browserului.

## Contorul comun („1000 de fapte bune”)

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

## Magazinul

Magazinul se deschide de pe prima pagină sau direct de la `/#magazin` (coșul: `/#cos`). Plata nu se face pe site: omul trimite comanda cu nume și număr de telefon, iar voi îl contactați.

### Activare

Rulează `supabase-store.sql` în SQL Editor. Până atunci, „Cumpără” arată o eroare și coșul rămâne salvat. Scriptul se poate rula din nou fără să piardă comenzi.

### Cum gestionezi comenzile

Totul se face din Supabase, nu din site:

1. **Table Editor > `store_orders`**: o linie pentru fiecare comandă. Numărul din coloana `id` e cel pe care îl vede cumpărătorul („Comanda #12”).
2. Schimbă `status` pe măsură ce avansează: `noua` → `confirmata` → `platita` → `predata`, sau `anulata`. În `note` poți scrie orice observație.
3. **Table Editor > `store_totals`**: câte bucăți trebuie, pe produs și mărime, fără comenzile anulate. De aici iei cantitățile pentru tipografie.
4. Pentru listă în Excel, folosește exportul CSV din Table Editor.

Comenzile conțin date personale, iar mulți cumpărători sunt minori. Dă acces la proiectul Supabase doar celor care chiar lucrează cu comenzile și șterge comenzile când nu mai ai nevoie de ele:

```sql
delete from public.store_orders where status in ('predata','anulata');
```

Ștergerea nu se poate anula și scoate liniile respective și din `store_totals`. Numerotarea continuă de unde a rămas.

Site-ul poate doar să adauge comenzi, prin funcția `store_place_order`. Nu poate citi sau modifica nimic, deci numele și numerele nu sunt vizibile public. Comenzile nu păstrează codul anonim al telefonului, ca să nu poată fi legate de provocările bifate. Cine vrea poate trimite comenzi false, pentru că nu există cont sau plată. De aceea confirmați fiecare comandă la telefon.

### Schimbări la produse

În `SHOP_ITEMS` (în `index.html`):

- **Preț:** completează `price`, în lei. Cât timp e `null`, prețul nu apare. Dacă toate produsele din coș au preț, apare și totalul. Prețul e doar afișat și nu se salvează în comandă.
- **Produs nou:** adaugă-l în `SHOP_ITEMS`, cu poza în `store/`, și rulează în SQL Editor:

```sql
insert into public.store_products(id) values ('id-ul-produsului');
```

- **Mărimi:** se schimbă în `SIZES` și în lista din `store_place_order` și `store_totals` (`supabase-store.sql`), apoi se rulează din nou scriptul.

Coșul e salvat pe telefon sub cheia `its-your-turn-cart-v1`, separat de progres. Numele și numărul de telefon nu se salvează pe telefon.

## Butonul „Salvează pe ecranul principal”

Pe Android deschide fereastra de instalare a browserului, dacă browserul o oferă. Altfel, și mereu pe iPhone, arată pașii de urmat. Butonul nu apare dacă site-ul e deja deschis de pe ecranul principal sau pe desktop.

Pe iPhone, versiunea de pe ecranul principal poate avea altă memorie decât Safari, deci alt progres și alt cod anonim. De aceea e bine ca participanții să o adauge înainte de prima carte.

## Butonul „Înapoi”

Fiecare pagină are o adresă proprie (`#see`, `#progres`, `#magazin`, `#cos`, iar prima pagină n-are nimic după `#`) și o intrare în istoricul browserului. Înapoi de pe telefon și butoanele de pe pagină fac același lucru. O pagină nouă se deschide cu `navigate`, butoanele de pe pagină merg înapoi cu `goUp`, iar `showRoute` afișează pagina potrivită pentru adresa curentă. O pagină nouă trebuie adăugată în `showRoute` și `showOnly`.

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
- Funcțiile principale: `renderHome`, `openDomain`, `draw`, `fillChallenge`, `fillComplete`, `goHome`, `markDone`, `renderProgress`, `openProgress`, `showUnlocked`, `downloadBadge`, `renderCommunity`, `syncCommunity`, `connectCommunity`, `renderShop`, `addToCart`, `renderCart`, `placeOrder`.
- **`SHOP_ITEMS`**, **`SIZES`**, **`MAX_QTY`**: produsele, mărimile și cantitatea maximă pe linie (aceeași limită e și în `store_place_order`).

## Identitate vizuală

- Fonturi Google: Anton (titluri), Oswald (etichete), Jost (text).
- Bleumarin `#0F2A45`, portocaliu `#E8693A`.
- Culorile domeniilor: Serve `#E8693A`, See `#3FA690`, Encourage `#7BA6E2`, Speak `#E8748A`, Pray `#A77BDD`.

## Reguli pentru texte

- Româna trebuie să sune natural, vorbit, la persoana a II-a („tu”). Nu traduceri cuvânt cu cuvânt din engleză.
- Diacriticele se scriu cu virgulă dedesubt: ș, ț (nu ş, ţ cu sedilă).
- În engleză rămân doar: „It's your turn”, „to love like Jesus”, numele celor 5 domenii, „Festival Compa”, „Compa Shop” și numele produselor, pentru că așa sunt tipărite pe ele.

## Atenție la adresă

Toate materialele tipărite (afișe, roll-up-uri, stickere) au un cod QR care duce la https://it-s-your-turn.github.io/. Dacă se mută site-ul pe alt domeniu sau se redenumește organizația GitHub, codurile QR deja tipărite nu mai funcționează. Atunci trebuie pusă o redirecționare de la adresa veche.
