# CRM Business v1.1.0

## الهدف
ربط المكونات الأساسية في رحلة تشغيل واحدة، وإضافة اختبار تكاملي قابل للتشغيل ضد API حي.

## رحلة الاختبار
1. Health
2. Register Company A
3. Login / Me
4. Create Customer
5. Create Opportunity
6. Create Task
7. Dashboard
8. Pipeline
9. Analytics Dashboard
10. Subscription
11. Register Company B
12. Verify Company B cannot access Company A customer (expected 404/403).

## التشغيل
```bash
cd backend
npm install
JWT_SECRET="ضع-سرًا-قويًا-هنا-32-حرفًا-على-الأقل" npm run start:dev
```
ثم في نافذة أخرى:
```bash
cd backend
API_BASE_URL=http://localhost:3000/api npm run test:journey
```

> الاختبار يستخدم Node 22 native fetch ولا يحتاج مكتبة HTTP إضافية.

## ملاحظة Android
التطبيق يستخدم `API_BASE_URL` وقت البناء، ويدعم الآن حفظ access/refresh token وتجديد access token عند انتهاء صلاحيته.
