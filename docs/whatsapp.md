# הקמת וואטסאפ (משימה B1)

המטרה בסוף השבוע: אפליקציה ב־Meta עם מספר בדיקה, הודעת בדיקה שהגיעה לטלפון שלך, ותבנית תזכורת שהוגשה לאישור.

## 1. חשבון עסקי

1. נכנסים ל־business.facebook.com עם חשבון פייסבוק אישי ופותחים Business Portfolio בשם הפרויקט.
2. ב־Settings → People מוסיפים את האח השני כ־Admin.

## 2. אפליקציה

1. נכנסים ל־developers.facebook.com → My Apps → Create App.
2. בוחרים את סוג האפליקציה של עסק, ומחברים אותה ל־Business Portfolio מהשלב הקודם.
3. בדף האפליקציה מוסיפים את המוצר **WhatsApp**.
4. ב־WhatsApp → API Setup מופיעים:
   - **מספר בדיקה** ש־Meta נותנת בחינם
   - **Phone number ID**: זה הערך של `WA_PHONE_NUMBER_ID`
   - **טוקן זמני** ל־24 שעות, לבדיקות בלבד
5. תחת "To" מוסיפים את מספרי הטלפון של שניכם, עד 5 מספרים, ומאשרים כל אחד בקוד שמגיע בוואטסאפ.
6. לוחצים על Send message. אמורה להגיע לטלפון הודעת `hello_world`. אם היא הגיעה, החיבור עובד.

## 3. תבנית התזכורת

ב־WhatsApp Manager → Message templates → Create template:

| שדה      | ערך                    |
| -------- | ---------------------- |
| Category | **Utility**            |
| Name     | `appointment_reminder` |
| Language | Hebrew                 |

**גוף ההודעה** (מעתיקים כמו שהוא):

```
שלום {{1}}, תזכורת לתור שלך אצל {{2}} מחר ב־{{3}}.
לביטול או שינוי: {{4}}
לשאלות לעסק: {{5}}
נתראה!
```

**ערכים לדוגמה** ש־Meta מבקשת לכל משתנה:

| משתנה   | דוגמה                              |
| ------- | ---------------------------------- |
| `{{1}}` | יוסי                               |
| `{{2}}` | דני הספר                           |
| `{{3}}` | 10:00                              |
| `{{4}}` | https://tori.vercel.app/c/8f3k2a9d |
| `{{5}}` | 050-1234567                        |

השורה "נתראה!" נמצאת שם בכוונה: Meta דוחה תבניות שמסתיימות במשתנה.

**הקטגוריה חשובה.** אם Meta משנה את הקטגוריה ל־Marketing, המחיר להודעה עולה. בתבנית אסור שיהיו מבצעים, הנחות או הזמנה לחזור. רק פרטי התור.

אישור לוקח בדרך כלל בין דקות לשעות. אם התבנית נדחתה, הסיבה מופיעה ליד שם התבנית.

## 4. טוקן קבוע (אפשר בשבוע 3)

הטוקן הזמני פג אחרי 24 שעות. לשימוש קבוע:

1. ב־Business Settings → Users → System users יוצרים System User עם הרשאת Admin.
2. מוסיפים לו את האפליקציה תחת Assign assets.
3. לוחצים Generate token, בוחרים את האפליקציה ואת ההרשאות `whatsapp_business_messaging` ו־`whatsapp_business_management`.
4. שומרים את הטוקן ב־`.env.local` כ־`WA_TOKEN`, ובהגדרות של Vercel. אף פעם לא בגיט.

## 5. מספר אמיתי (שבוע 4, משימה S5)

- צריך מספר שלא מחובר לאפליקציית וואטסאפ. למשל סים נטען חדש, או מספר שמוחקים ממנו את וואטסאפ קודם.
- ב־API Setup → Add phone number, מאמתים ב־SMS או בשיחה.
- שם התצוגה שבוחרים יופיע אצל הלקוחות, ו־Meta מאשרת אותו.
- מוסיפים אמצעי תשלום ב־Business Settings → Billing. בלי זה תבניות לא יוצאות למספרים שלא אושרו כמספרי בדיקה.
- בלי אימות עסקי מלא אפשר לשלוח ל־250 אנשים שונים ביום. זה מספיק לשלב הזה.

## שליחה מהקוד (משימה B6, שבוע 3)

```ts
await fetch(`https://graph.facebook.com/v23.0/${process.env.WA_PHONE_NUMBER_ID}/messages`, {
  method: "POST",
  headers: {
    Authorization: `Bearer ${process.env.WA_TOKEN}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    messaging_product: "whatsapp",
    to: "972501234567",
    type: "template",
    template: {
      name: process.env.WA_TEMPLATE_NAME,
      language: { code: "he" },
      components: [
        {
          type: "body",
          parameters: [clientName, businessName, time, cancelUrl, businessPhone].map((text) => ({
            type: "text",
            text,
          })),
        },
      ],
    },
  }),
});
```

את גרסת ה־API בכתובת (`v23.0`) בודקים מול התיעוד של Meta כשמתחילים.
