# שבוע 1: הקמה

המדריך הזה מוביל את שניכם מאפס ועד פרויקט שרץ, עם מסד נתונים, נתוני דוגמה ומשימות בלוח. שלבים 1–2 כל אחד עושה לבד. משלב 3 עד 9 עושים ביחד, בערב אחד: אחד מקליד ומשתף מסך, והשני עוקב.

## מה יש בתיקייה הזו

| קובץ                                                    | מה הוא                                                 |
| ------------------------------------------------------- | ------------------------------------------------------ |
| `supabase/migrations/20261015000000_initial_schema.sql` | כל הטבלאות, ההגנה מפני תורים כפולים והרשאות (RLS)      |
| `supabase/seed.sql`                                     | שני עסקים לדוגמה: דני הספר וסטודיו נועה יוגה, עם תורים |
| `AGENTS.md`                                             | כללי הפרויקט. Cursor קורא אותו ישירות                  |
| `CLAUDE.md`                                             | שורה אחת שמפנה ל־`AGENTS.md`, בשביל Claude Code        |
| `.env.example`                                          | שמות משתני הסביבה, בלי ערכים                           |
| `.nvmrc`, `.prettierrc`, `.prettierignore`              | גרסת Node ועיצוב קוד אחיד                              |
| `lib/phone.ts`                                          | המרת טלפונים לפורמט `972...` ובחזרה                    |
| `.github/pull_request_template.md`                      | תבנית לכל בקשת מיזוג                                   |
| `scripts/create-issues.sh`                              | יוצר את כל 18 המשימות ב־GitHub                         |
| `docs/whatsapp.md`                                      | הקמה ב־Meta, למשימה B1                                 |
| `docs/github.md`                                        | איך עובדים עם GitHub במקביל, צעד אחר צעד               |

---

## 1. חשבונות (פעם אחת)

- [ ] **GitHub:** אחד יוצר Organization חינמי (github.com/organizations/plan) ומזמין את השני כ־Owner.
- [ ] **Supabase:** אחד יוצר Organization ב־supabase.com ומזמין את השני. בתוכו יוצרים פרויקט בשם `tori-dev`, באזור `Central EU (Frankfurt)`, הכי קרוב לישראל. את סיסמת המסד שומרים במקום בטוח.
- [ ] **Vercel:** מי שיוצר את Supabase נרשם גם ל־vercel.com עם חשבון ה־GitHub שלו.
- [ ] **Meta:** אח ב׳, לפי `docs/whatsapp.md`.

## 2. התקנות (כל אחד על המחשב שלו)

ב־Mac, עם [Homebrew](https://brew.sh):

```bash
brew install node@24 git gh supabase/tap/supabase
```

```bash
gh auth login
```

```bash
supabase login
```

ובנוסף: Cursor למי שעובד איתו, ו־Claude Code (באפליקציית Claude) למי שעובד איתו. עורך קוד כמו VS Code לא חובה למי שעובד ב־Claude Code. הוא נוח לקריאת קוד ולפתרון קונפליקטים, ואפשר להתקין אותו בחינם כשצריך.

בדיקה שהכל מותקן:

```bash
node -v && git -v && gh --version && supabase --version
```

`node -v` צריך להתחיל ב־`v24`.

## 3. יצירת הפרויקט (משימה S1)

```bash
npx create-next-app@latest tori --ts --tailwind --eslint --app --no-src-dir --import-alias "@/*" --use-npm
```

```bash
cd tori
```

```bash
npm install @supabase/supabase-js @supabase/ssr
```

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

## 4. העתקת הקבצים מהתיקייה הזו

מעתיקים לתוך `tori/` את כל מה שבתיקייה הזו, **חוץ מ־`SETUP.md`** (אפשר להעתיק גם אותו, לא יזיק). שימו לב לקבצים שמתחילים בנקודה: `.env.example`, `.nvmrc`, `.prettierrc`, `.prettierignore`, `.github/`. ב־Finder מציגים אותם עם `Cmd+Shift+.`.

**שני תיקונים בקבצים ש־create-next-app יצר:**

1. ב־`.gitignore` מופיעה השורה `.env*`, והיא מסתירה גם את `.env.example`. מוסיפים מתחתיה:
   ```
   !.env.example
   ```
2. ב־`app/layout.tsx` משנים את `<html lang="en">` ל:
   ```tsx
   <html lang="he" dir="rtl">
   ```
   ובאותו קובץ משנים את `title` ב־`metadata` לשם של המוצר.

ומוסיפים ל־`package.json`, בתוך `scripts`:

```json
"format": "prettier --write ."
```

## 5. מסד הנתונים (משימות S2–S3)

לפני שדוחפים, **קוראים יחד את קובץ ה־migration**. ההערות בו מסבירות כל טבלה. אם רוצים לשנות משהו, זה הזמן, לפני הדחיפה הראשונה.

```bash
supabase init
```

אם הוא שואל על הגדרות של VS Code או Deno, עונים `N`. הוא יוצר `supabase/config.toml` ולא נוגע ב־migration שהעתקתם.

את ה־Reference ID של הפרויקט מוצאים ב־Supabase → Project Settings → General:

```bash
supabase link --project-ref YOUR_PROJECT_REF
```

```bash
supabase db push
```

**נתוני הדוגמה:** ב־Supabase פותחים SQL Editor, מדביקים את כל התוכן של `supabase/seed.sql` ולוחצים Run. בדיקה: ב־Table Editor, בטבלה `businesses`, מופיעים שני עסקים.

כל פעם שרוצים לאפס את נתוני הדוגמה, מריצים את הקובץ שוב.

## 6. משתני סביבה

```bash
cp .env.example .env.local
```

ממלאים את שלושת הערכים של Supabase מ־Project Settings → API (או Data API / API Keys בגרסאות חדשות של הממשק):

- `NEXT_PUBLIC_SUPABASE_URL`: ה־Project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: המפתח הציבורי (anon או publishable)
- `SUPABASE_SERVICE_ROLE_KEY`: המפתח הסודי (service_role או secret). **לא לשתף אותו בשום מקום ציבורי.**

את הקובץ שולחים לשני פעם אחת, בהודעה פרטית, ומוחקים את ההודעה אחרי שהוא העתיק.

## 7. הרצה ראשונה

```bash
npm run dev
```

פותחים http://localhost:3000. העמוד צריך להיות מיושר לימין.

```bash
npm run lint && npm run format
```

## 8. GitHub

ב־github.com יוצרים repository חדש **בתוך ה־Organization**, בשם `tori`, Private, ריק (בלי README).

```bash
git add -A && git commit -m "Initial project setup with schema and seed data"
```

```bash
git remote add origin https://github.com/YOUR_ORG/tori.git
```

```bash
git push -u origin main
```

**הגנה על main:** ב־repository → Settings → Branches → Add rule → Branch name `main` → מסמנים "Require a pull request before merging" ו־"Require approvals: 1". מעכשיו אף אחד לא דוחף ישירות ל־main.

> שימו לב: ב־repository פרטי של Organization חינמי, GitHub לא תמיד אוכף את הכלל הזה. אם זה המצב, פשוט שומרים עליו בעצמכם.

**המשימות:**

```bash
chmod +x scripts/create-issues.sh && ./scripts/create-issues.sh YOUR_ORG/tori
```

ואז ב־Organization → Projects → New project → Board. משנים את שמות העמודות ל"לעשות", "בעבודה", "לבדיקה", "הושלם". בתחתית הלוח: Add item → בוחרים את ה־repository ומוסיפים את כל המשימות.

## 9. Vercel

ב־vercel.com → Add New → Project → Import את `tori` מה־Organization. ב־Environment Variables מוסיפים את שלושת משתני Supabase ואת `NEXT_PUBLIC_SITE_URL` (הכתובת ש־Vercel ייתן, למשל `https://tori.vercel.app`). לוחצים Deploy.

מעכשיו כל מיזוג ל־main עולה לאוויר, וכל בקשת מיזוג מקבלת כתובת תצוגה משלה.

## 10. הגדרות התחברות (לפני A1)

ב־Supabase → Authentication → URL Configuration:

- **Site URL:** כתובת ה־Vercel
- **Redirect URLs:** מוסיפים `http://localhost:3000/**` ו־`https://*.vercel.app/**`

ב־Authentication → Sign In / Providers מוודאים ש־Email פעיל.

> שירות המייל המובנה של Supabase מוגבל לכמה מיילים בשעה. לפיתוח זה מספיק. לפני שעסקים אמיתיים נכנסים (שבוע 4), מחברים SMTP של Resend בחינם.

---

## בסוף השבוע, הכל מסומן?

- [ ] `npm run dev` רץ אצל שניכם
- [ ] האתר באוויר ב־Vercel
- [ ] במסד יש 8 טבלאות ושני עסקים לדוגמה
- [ ] 18 משימות בלוח
- [ ] אח א׳ סיים את A1: נכנס עם מייל ורואה את "דני הספר" (אחרי פקודת השיוך שבראש `seed.sql`)
- [ ] אח ב׳ סיים את B1: הודעת בדיקה הגיעה, והתבנית הוגשה
- [ ] שניכם קראתם את `AGENTS.md`
