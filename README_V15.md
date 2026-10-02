# CRM Business v1.6.0 — Launch Readiness

هذه النسخة تنقل المشروع من "Production Baseline" إلى **Launch Readiness**: ملفات النشر، migration حقيقية، CI تكاملية، واستعادة جلسة Android.

## 1. تشغيل الإنتاج

انسخ:

```bash
cp .env.production.example .env.production
```

ثم استبدل جميع القيم التجريبية، خصوصًا `JWT_SECRET` و`POSTGRES_PASSWORD` و`DATABASE_URL` و`CORS_ORIGINS`.

شغّل:

```bash
docker compose --env-file .env.production -f docker-compose.prod.yml up -d --build
```

الحاوية `api` تطبق `prisma migrate deploy` تلقائيًا قبل تشغيل NestJS.

## 2. HTTPS

ضع شهادة TLS ومفتاحها في `deploy/nginx/certs/` أو استخدم طبقة TLS مُدارة أمام Nginx. غيّر `server_name` من `_` إلى النطاق الفعلي.

## 3. Android

لبيئة الإنتاج، ابنِ التطبيق مع:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com/api
```

لا تضع رابط الإنتاج داخل الأسرار؛ الرابط ليس سرًا، لكنه يجب أن يكون ثابتًا ومقصودًا لكل build.

## 4. CI

الـ workflow `ci.yml` يشغل PostgreSQL، يطبق migration، يشغل API، ثم ينفذ رحلة تسجيل شركتين واختبار عزل الـ tenant.

## 5. Backup

استخدم:

```bash
scripts/backup-postgres.sh
```

اضبط `BACKUP_DIR` واحتفظ بنسخ خارج الخادم أيضًا. النسخة المحلية وحدها ليست استراتيجية تعافٍ كافية.

## 6. أول تشغيل فعلي

1. إنشاء الخادم وقاعدة البيانات.
2. ضبط `.env.production`.
3. تشغيل Docker.
4. فحص `/api/health/ready`.
5. إنشاء أول شركة من Android.
6. اختبار عميل وفرصة ومهمة.
7. إنشاء Platform Admin فقط بإجراء قاعدة بيانات محكوم.
8. إعداد DNS/TLS.
9. إنشاء AAB موقّع من GitHub Actions.
10. رفع AAB إلى Google Play Console وإجراء Internal Testing قبل الإنتاج.

## 7. ملاحظة

لم يتم تضمين أي مفاتيح أو حسابات حقيقية في المشروع. بناء AAB موقّع فعليًا يحتاج أسرار التوقيع داخل GitHub Secrets أو جهاز نشر آمن.
