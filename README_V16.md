# CRM Business v1.6.0 — First Real Launch

هذه النسخة تركز على الانتقال من "جاهز للنشر" إلى "قابل للتشغيل والتحقق".

## مسار التشغيل من الهاتف

1. ارفع المشروع إلى GitHub.
2. شغّل workflow `CI` وانتظر نجاح اختبارات Backend وFlutter.
3. من `Android Release Build` شغّل `workflow_dispatch` لبناء APK/AAB.
4. في بناء التطبيق استخدم `--dart-define=API_BASE_URL=https://YOUR-DOMAIN/api`.
5. على خادم الإنتاج انسخ `.env.production.example` إلى `.env.production` وضع القيم السرية الحقيقية خارج Git.
6. جهّز شهادات TLS داخل `deploy/nginx/certs/` أو استخدم reverse proxy مُدارًا للشهادات.
7. شغّل `docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build`.
8. تحقق من `https://YOUR-DOMAIN/api/health` و`https://YOUR-DOMAIN/api/health/ready`.
9. افتح التطبيق من الهاتف، أنشئ الشركة الأولى، ثم أنشئ شركة اختبار ثانية.
10. تحقق أن بيانات الشركة الأولى لا تظهر للشركة الثانية.

## أسرار مطلوبة
- `JWT_SECRET` قوي.
- `POSTGRES_PASSWORD` قوي.
- `DATABASE_URL` صحيح.
- `CORS_ORIGINS` مضبوط على النطاقات المسموح بها.
- أسرار توقيع Android فقط في GitHub Secrets.

لا تضع أيًا منها داخل المستودع.

## اختبار قبول الإطلاق
- Health + DB
- Register/Login/Auth Me
- Customer + Opportunity + Pipeline
- Task + Analytics + Subscription
- Cross-tenant access blocked
- Refresh rotation
- Flutter analyze/test
- APK/AAB build

## ملاحظة
لم يتم تضمين مفاتيح حقيقية أو شهادة TLS أو بيانات إنتاج في المشروع.
