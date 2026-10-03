# Lộ trình triển khai Backend VeggiePal

> Bản tiếng Việt của [IMPLEMENTATION_PHASES.md](IMPLEMENTATION_PHASES.md). Khi cập nhật roadmap, phải đồng bộ cả hai bản.

## Cơ sở phân tích và nguyên tắc quyết định

Roadmap này được xây dựng từ việc đọc mã nguồn thực tế của bốn Maven project hiện có, bao gồm controller, service, entity, repository, DTO, security/JWT, exception, cấu hình, OpenAPI, S3/MinIO, Gateway, Docker Compose và test; sau đó đối chiếu với toàn bộ yêu cầu trong `VeganApp.docx`.

Tài liệu DOC là nguồn yêu cầu chức năng. Mã nguồn là nguồn sự thật về trạng thái triển khai. Mô hình dữ liệu trong DOC được xem là ý định nghiệp vụ, không phải schema phải sao chép nguyên trạng, vì tài liệu dùng UUID và nhiều foreign key xuyên domain trong khi code hiện dùng `Long` và database riêng cho từng service.

Thứ tự phase được quyết định theo dependency kỹ thuật:

- Ổn định bảo mật, schema và môi trường trước khi mở rộng domain.
- Có ingredient/recipe chuẩn trước pantry, allergy, recommendation và meal plan.
- Có dữ liệu sức khỏe đầy đủ trước khi sinh thực đơn.
- Có AI runtime dùng chung trước chatbot, moderation, summarization và computer vision.
- Không tạo một microservice cho mỗi tính năng.
- Ưu tiên mở rộng service hiện có khi boundary vẫn hợp lý.

# Đánh giá Backend hiện tại

| Tính năng / Domain | Service hiện tại | Trạng thái | Phần đã có | Phần còn thiếu |
|---|---|---|---|---|
| API routing và Swagger tổng hợp | `api-gateway` | ĐÃ TRIỂN KHAI MỘT PHẦN | Route identity, nutrition, blogs, categories, comments; CORS; Swagger UI | Route cho domain mới, URL theo môi trường, route test, cấu hình deploy |
| Đăng ký/đăng nhập | `identity-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Chuẩn hóa email, BCrypt, chống trùng email, cấp access JWT | Chặn account không hợp lệ, xác minh email, reset password, refresh/revoke, Google login tùy chọn |
| JWT authentication | identity và các resource service | CẦN REVIEW KIẾN TRÚC | HS256, claim `userId`/`role`, stateless resource server, JSON 401/403 | Issuer/audience, rotation, refresh, revoke và xử lý khóa account ngay lập tức |
| Role/authorization | identity, blog | ĐÃ TRIỂN KHAI MỘT PHẦN | `USER`/`ADMIN`, admin category, owner/admin checks | Admin user API, chuẩn hóa MEMBER/USER, kiểm tra đầy đủ mọi trạng thái account |
| Hồ sơ người dùng | `identity-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Họ tên, điện thoại, ngày sinh, avatar, đổi mật khẩu, public user lookup | Gender, activity level, region và input phục vụ meal plan; phân định ownership của height |
| File/object storage | identity, blog | ĐÃ TRIỂN KHAI MỘT PHẦN | S3-compatible upload/delete, kiểm MIME + magic bytes | Compose chưa tạo bucket/policy; chưa có media cho video/recipe; policy production |
| Quản trị user | Chưa có | CHƯA TRIỂN KHAI | JWT có thể mang role admin | List/filter/detail, suspend/reactivate, audit admin |
| Health record và BMI | `nutrition-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Lịch sử height/weight, BMI phía server, pagination, latest/update | TDEE, activity, goal, target calories, contract snapshot cho meal plan |
| Dị ứng | `nutrition-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Allergen catalog seed và replace-all allergy | Liên kết ingredient chuẩn, severity nếu giữ theo DOC, API validation với recipe catalog |
| Pantry/nguyên liệu của user | Chưa có | CHƯA TRIỂN KHAI | Không | Association user-ingredient và validation |
| Ingredient chuẩn và dinh dưỡng | Chưa có | CHƯA TRIỂN KHAI | Chỉ có allergen catalog giới hạn | Ingredient catalog, nutrients, allergen flag, ảnh, admin CRUD, search/index |
| Recipe, step, recipe ingredient | Chưa có | CHƯA TRIỂN KHAI | Không | Toàn bộ recipe aggregate và public/author/admin API |
| Category | `blog-service` | HOÀN THÀNH TRONG PHẠM VI HIỆN TẠI | Cây hai cấp, typed category, admin CRUD, active state, unique name | Contract dùng chung cho recipe/video; kiểm tra external usage khi xóa |
| Blog | `blog-service` | HOÀN THÀNH TRONG PHẠM VI HIỆN TẠI | Draft/submit/publish, public/owner reads, search/filter/sort, related, thumbnail, views, vote | Admin listing/review đầy đủ, recipe link tùy chọn, moderation thật |
| Comment/reply | `blog-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Comment blog, reply một cấp, tombstone, owner/admin delete | Bật VIDEO target, moderation queue, AI moderation thật |
| Vote | `blog-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Vote blog, toggle/switch/remove, atomic score, batch my-votes | API tương đương cho video |
| Video | Chưa có; blog đã có extension point | CHƯA TRIỂN KHAI | `TargetType.VIDEO` đã tồn tại | Entity/API, provider/upload, author/admin CRUD, search/read/view |
| Search nội dung công khai | `blog-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Search blog theo keyword/category | Search recipe/video, unified result, recommendation đa domain |
| Recommendation | `blog-service` | ĐÃ TRIỂN KHAI MỘT PHẦN | Related blogs cùng category | Related recipe/video, ranking và personalization |
| AI nutrition chatbot | Chưa có | CHƯA TRIỂN KHAI | Không | Provider abstraction, conversation/message, grounding, safety, persistence |
| Guest chatbot trial | Chưa có | CHƯA TRIỂN KHAI | Không | Session, quota atomic, abuse protection, rate limit |
| Weekly meal plan cá nhân | Chưa có | CHƯA TRIỂN KHAI | BMI/allergy là input một phần | Goal/TDEE/pantry, AI generation, validation, persistence, replace/save |
| Seasonal/regional | Chưa có | CHƯA TRIỂN KHAI | Không | Seasonality data và ranking constraint |
| Nhà hàng/cửa hàng chay | Chưa có | CHƯA TRIỂN KHAI | Không | Place provider, geospatial cache/search, detail, dish relevance |
| Content moderation | `blog-service` | CẦN REVIEW KIẾN TRÚC | Có interface tốt và status pending/rejected | Implementation hiện auto-approve; cần moderation case, AI và admin decision |
| AI monitoring | Chưa có | CHƯA TRIỂN KHAI | Không | Model config, request log, metric, alert, admin control |
| Tóm tắt recipe từ video | Chưa có | CHƯA TRIỂN KHAI | Không | STT, async workflow, summary, validate và lưu kết quả |
| Nhận diện ingredient từ ảnh | Chưa có | CHƯA TRIỂN KHAI | Không | Upload, CV, confidence/freshness, canonical matching, user confirmation |
| Wearable/Health App | Chưa có | TÙY CHỌN | DOC ghi rõ optional | Consent, adapter, encrypted token, sync/reconcile/delete |
| Database lifecycle | Tất cả service có persistence | CẦN REVIEW KIẾN TRÚC | Schema tách riêng, index, Hibernate update, seed allergen | Versioned migrations, isolated integration tests, ownership rõ ràng |
| Automated tests | Tất cả service | ĐÃ TRIỂN KHAI MỘT PHẦN | Identity 52, nutrition 42, blog 158, Gateway 1 test; blog có real-MySQL integration | Gateway route test, DB integration cho identity/nutrition, contract/E2E/provider fake |

# Các Microservice hiện có

## api-gateway

### Trách nhiệm hiện tại

Điểm vào công khai, CORS, routing theo path và tổng hợp OpenAPI.

### Tính năng đã có

- Spring Cloud Gateway Server WebMVC, port 8080.
- Route `/api/auth/**`, `/api/users/**` sang identity; `/api/nutrition/**` sang nutrition; `/api/blogs/**`, `/api/categories/**`, `/api/comments/**` sang blog.
- Dùng `StripPrefix=1`.
- Swagger UI tổng hợp tại `/swagger-ui.html`.

### Entity quan trọng

Không có. Gateway không được sở hữu domain data.

### API hiện có

Các route và docs route nêu trên; không có business controller.

### Dependency bên ngoài

HTTP đến `localhost:8081`, `:8082`, `:8083` đang hardcode.

### Vấn đề / phần chưa hoàn thiện

- URL upstream không chạy được giữa container.
- Chưa có route cho recipe, video, AI/chat/search/recommendation/location.
- Chỉ có context-load test; chưa test route, CORS, upload hoặc Swagger aggregation.

### Có nên giữ nguyên service boundary?

Có. Giữ Gateway mỏng, chỉ routing/edge concern; không đưa orchestration nghiệp vụ hoặc data vào đây.

## identity-service

### Trách nhiệm hiện tại

Account, password login, JWT, current-user profile, password/avatar và public author lookup.

### Tính năng đã có

- BCrypt và normalize email.
- Access JWT HS256, 24 giờ, có `userId` và `role`.
- Get/patch profile, đổi password, avatar S3/MinIO có kiểm file.
- Public batch lookup tối đa 50 active user, không lộ email.
- Response/error/security envelope nhất quán.

### Entity quan trọng

- `User`: email, password hash, full name, phone, avatar, birth date, role, status, email verification và timestamp.

### API hiện có

- `POST /auth/register`, `POST /auth/login`
- `GET|PATCH /users/me`
- `PUT /users/me/password`
- `POST /users/me/avatar`
- `GET /users/batch?ids=...`

### Dependency bên ngoài

MySQL `veggiepal_identity`, S3/MinIO và JWT secret dùng chung.

### Vấn đề / phần chưa hoàn thiện

- Register tạo `PENDING` và `emailVerified=false`, nhưng login chỉ kiểm email/password.
- Không có verify/reset/refresh/logout/revoke/social login/admin user API.
- Code dùng `Long`, `USER`, profile gộp trong users; DOC dùng UUID, `MEMBER`, bảng profile riêng. Cần quyết định tương thích, không copy schema mù quáng.
- Properties có credential/secret mặc định; identity schema chưa được Compose tự tạo.

### Có nên giữ nguyên service boundary?

Có. Đây phải là nơi duy nhất sở hữu account và credential. Service khác chỉ dùng `userId` qua JWT/API.

## nutrition-service

### Trách nhiệm hiện tại

Health history và allergy selection thuộc user.

### Tính năng đã có

- Create/list/latest/update health record theo JWT user.
- BMI tính phía server, làm tròn half-up một chữ số.
- Allergen catalog seed và replace-all allergy transactional.
- Security, OpenAPI, mapper, exception và test tương đối đầy đủ.

### Entity quan trọng

- `HealthRecord`, `Allergen`, `UserAllergy`.

### API hiện có

- `GET /nutrition/allergens`
- `GET|PUT /nutrition/me/allergies`
- `POST|GET /nutrition/me/health-records`
- `GET /nutrition/me/health-records/latest`
- `PUT /nutrition/me/health-records/{id}`

### Dependency bên ngoài

MySQL `veggiepal_nutrition`, JWT secret; hiện chưa gọi service khác.

### Vấn đề / phần chưa hoàn thiện

- Thiếu goal, activity, TDEE, target calories và region.
- Allergen catalog sẽ chồng ownership với canonical ingredients nếu không thiết kế lại.
- Chưa có pantry và meal plan.
- Chưa có DB integration suite tương đương blog.

### Có nên giữ nguyên service boundary?

Có. Mở rộng thành owner của nutrition inputs và persisted meal plans. Ingredient/recipe chuẩn thuộc recipe-service; nutrition chỉ lưu external ID/snapshot.

## blog-service

### Trách nhiệm hiện tại

Blog cộng đồng, category, comment, vote, thumbnail và moderation seam.

### Tính năng đã có

- Blog draft/create/edit/submit/delete, thumbnail, public search/read, view, owner listing và related.
- Admin-aware takedown; admin-only category CRUD.
- Category tree hai cấp.
- Reply một cấp và tombstone.
- Vote transactional, toggle/switch/remove và atomic score.
- Comment/vote polymorphic đã chuẩn bị `VIDEO`.
- Test unit/slice/security rộng và real-MySQL integration suite.

### Entity quan trọng

- `Blog`, `Category`, `Comment`, `ContentVote`.

### API hiện có

- `/blogs/**`, `/categories/**`, `/comments/**`
- Vote tại `/blogs/{id}/vote`

### Dependency bên ngoài

MySQL `veggiepal_blog`, S3/MinIO, JWT secret. Client tự resolve author qua identity.

### Vấn đề / phần chưa hoàn thiện

- Moderation implementation auto-approve mọi nội dung.
- Chưa có video entity/API và admin queue/review đầy đủ.
- Category deletion chỉ thấy local blog usage.
- Compose thực tế chưa tạo bucket/policy.

### Có nên giữ nguyên service boundary?

Có, nhưng mở rộng thành community content gồm blog và video. Không cần video-service riêng vì chúng dùng chung author, category, moderation, comment, vote, storage và search.

# Kiến trúc Microservice đích đề xuất

## api-gateway

Trạng thái: HIỆN CÓ

### Trách nhiệm

Routing công khai, CORS, Swagger aggregation và edge control mức cơ bản.

### Dữ liệu sở hữu

Không có.

### Tính năng liên quan

Toàn bộ public API.

### Phụ thuộc vào

Endpoint service cấu hình qua environment/container DNS.

### Cung cấp API cho

Web/mobile/admin client.

### Ghi chú kiến trúc

Không chứa business logic. Service mới luôn cần API route, docs route và Swagger entry.

## identity-service

Trạng thái: HIỆN CÓ

### Trách nhiệm

Account, credential, role/status, verification/recovery, refresh session, public user summary và admin account action.

### Dữ liệu sở hữu

Users, identity profile fields, OTP, refresh sessions, optional social links, admin/account audit.

### Tính năng liên quan

Authentication, authorization claims, profile, member management.

### Phụ thuộc vào

Mail/OTP provider và object storage.

### Cung cấp API cho

Client và lookup identity có giới hạn.

### Ghi chú kiến trúc

Là nơi duy nhất phát hành identity/token. Production nên cân nhắc asymmetric signing hoặc managed issuer.

## nutrition-service

Trạng thái: HIỆN CÓ

### Trách nhiệm

Health/nutrition inputs cá nhân, BMI/TDEE/goal, allergy, pantry và persisted meal plans.

### Dữ liệu sở hữu

Health records, nutrition preference, user allergy ingredient IDs, pantry, meal plans/days/items và snapshot.

### Tính năng liên quan

BMI/TDEE, allergy, available ingredient, weekly menu, replacement, wearable tùy chọn.

### Phụ thuộc vào

`recipe-service` để validate ingredient/recipe; `ai-service` để sinh candidate.

### Cung cấp API cho

Client và personalization context giới hạn cho AI.

### Ghi chú kiến trúc

External recipe/ingredient ID chỉ là scalar kèm snapshot; tuyệt đối không dùng JPA relation/FK xuyên database.

## blog-service

Trạng thái: HIỆN CÓ

### Trách nhiệm

Community content gồm blog/video, shared category, comment, vote, content status, media metadata và admin content operation.

### Dữ liệu sở hữu

Blogs, videos, categories, comments, votes, counters và content-side moderation state.

### Tính năng liên quan

Public content, author management, interaction, category administration và content search.

### Phụ thuộc vào

Object/video storage, `ai-service` cho moderation/summary, `recipe-service` khi validate optional recipe link.

### Cung cấp API cho

Client và AI discovery/moderation orchestration.

### Ghi chú kiến trúc

Giữ tên để tương thích. Tái sử dụng mô hình comment/vote polymorphic hiện có.

## recipe-service

Trạng thái: MỚI

### Trách nhiệm

Canonical ingredient catalog và recipe aggregate: steps, quantities, nutrients, status, seasonality.

### Dữ liệu sở hữu

Ingredients, nutrients/allergen metadata, seasonality, recipes, recipe ingredients, recipe steps và recipe media metadata.

### Tính năng liên quan

Recipe authoring/search, ingredient lookup, nutrition calculation, meal plan validation, pantry/allergy reference.

### Phụ thuộc vào

Category contract từ blog-service, object storage, JWT; AI moderation ở phase sau.

### Cung cấp API cho

Client, nutrition-service, ai-service và location-service.

### Ghi chú kiến trúc

Đây là core service mới cần thiết để tránh duplicate ingredient/recipe ownership. `categoryId` là external scalar thuộc blog-service.

## ai-service

Trạng thái: MỚI

### Trách nhiệm

Provider-neutral AI runtime, chatbot, guest quota, discovery/recommendation orchestration, moderation case, video summary và AI telemetry.

### Dữ liệu sở hữu

Chat conversations/messages, guest usage, moderation cases, AI configuration reference, request logs/alerts, summary/recognition outputs.

### Tính năng liên quan

Chatbot, meal generation, related ranking, moderation, monitoring, summarization và CV.

### Phụ thuộc vào

External LLM/STT/CV và explicit API từ nutrition/recipe/blog/identity/location.

### Cung cấp API cho

Client và internal API được xác thực cho domain service.

### Ghi chú kiến trúc

AI không sở hữu recipe, health, video hoặc meal plan. Mọi ID do AI trả về phải validate với owner trước khi lưu.

## location-service

Trạng thái: MỚI

### Trách nhiệm

Tìm restaurant/shop chay, tích hợp place provider, cache có giới hạn, geospatial filtering và dish relevance.

### Dữ liệu sở hữu

Cached places, provider IDs, location/detail, expiry và optional observed dish association.

### Tính năng liên quan

Nearby vegan place, place detail, suggestion theo món.

### Phụ thuộc vào

Map/place provider, recipe-service và optional ai-service ranking.

### Cung cấp API cho

Client và recommendation orchestration.

### Ghi chú kiến trúc

Service riêng hợp lý vì có quota provider, geospatial cache và location privacy; chỉ tạo sau khi core food contract ổn định.

# Phase 1 — Nền tảng an toàn và tái lập được

## Mục tiêu

Ổn định hệ thống hiện có về account security, schema migration, environment configuration, admin account control và local deployment.

## Vì sao phase này ở đây

Mọi service sau đều tin JWT và convention hiện tại. Nếu tiếp tục trên schema không version, secret mặc định và login bỏ qua account status, chi phí sửa sẽ tăng theo số service.

## Microservice liên quan

- `api-gateway` [HIỆN CÓ]
- `identity-service` [HIỆN CÓ]
- `nutrition-service` [HIỆN CÓ]
- `blog-service` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Toàn bộ endpoint và response envelope hiện tại.
- BCrypt, JWT claims, public author lookup và JSON security errors.
- Database tách riêng, dữ liệu hiện có, Swagger và test hiện có.

## Công việc triển khai

- [ ] Chốt contract API/error/JWT dùng chung.
- [ ] Quyết định terminology `USER` và `MEMBER` không làm hỏng token consumer.
- [ ] Chặn login/refresh cho pending, inactive, blocked hoặc chưa verify.
- [ ] Thêm email verification và password-reset OTP có expiry, one-time use và hash.
- [ ] Thêm refresh-token rotation, logout/revoke và revoke khi đổi password.
- [ ] Thêm admin list/detail/status user và audit.
- [ ] Chốt cách vô hiệu access token đã cấp sau khi suspend.
- [ ] Baseline và đưa Flyway/Liquibase vào từng schema hiện có.
- [ ] Đưa DB/JWT/storage credential và upstream URL sang environment bắt buộc ngoài local profile.
- [ ] Thêm Dockerfile và Compose service definitions.
- [ ] Tự động tạo MinIO bucket/policy cho avatar/thumbnail.
- [ ] Thay Gateway localhost URI bằng URL cấu hình được.
- [ ] Thêm health/readiness, correlation ID và structured log không lộ secret.
- [ ] Bổ sung Gateway route test và DB integration test cho identity/nutrition.

## API bị ảnh hưởng

Giữ API hiện có; `POST /api/auth/login` phải kiểm account eligibility. Thêm:

- `/api/auth/verify-email`, `/resend-verification`
- `/api/auth/forgot-password`, `/reset-password`
- `/api/auth/refresh`, `/logout`
- `GET /api/users`, `GET /api/users/{id}`, `PATCH /api/users/{id}/status` cho admin

## Công việc database

- Tái sử dụng `users`; thêm OTP, refresh session và admin audit.
- Index expiry/token hash/user status/search.
- Baseline ba schema; không dùng `ddl-auto=update` ngoài môi trường disposable.
- Giữ numeric ID để tương thích trừ khi có migration riêng được phê duyệt.

## Dependency liên service

```text
identity-service --identity contract--> mọi protected service
api-gateway      --routing-----------> các service hiện có
```

## Yêu cầu kiểm thử

- Unit test OTP, refresh rotation, status transition, revoke.
- Repository/migration integration test.
- API/security test cho role và account status.
- Gateway route/CORS/Swagger test.
- Docker test từ volume rỗng và database hiện có.
- Kiểm tra Swagger qua port 8080.

## Tiêu chí nghiệm thu

- [ ] API hiện tại tương thích, trừ việc chủ động từ chối account không hợp lệ.
- [ ] Bốn project build và toàn bộ test pass.
- [ ] Clean Compose start không cần thao tác DB/bucket thủ công.
- [ ] Không còn credential thật/default dùng được trong production profile.
- [ ] Migration tái tạo schema và giữ dữ liệu hiện có.
- [ ] Admin action được authorize và audit.

## Ngoài phạm vi

Recipe, video, AI, chatbot, meal plan, restaurant, social login và rewrite blog đang hoạt động.

# Phase 2 — Domain Ingredient và Recipe chuẩn

## Mục tiêu

Tạo nguồn dữ liệu chuẩn cho ingredient và recipe để pantry, allergy, search, recommendation và meal plan dùng chung.

## Vì sao phase này ở đây

Meal plan và AI không thể dựa trên tên món/nguyên liệu tự do hoặc các bảng ingredient trùng lặp.

## Microservice liên quan

- `recipe-service` [MỚI]
- `blog-service` [HIỆN CÓ]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Category CRUD/tree và ID của blog-service.
- JWT/response conventions và pattern validate file S3 hiện có.

## Công việc triển khai

- [ ] Tạo recipe-service theo convention hiện có.
- [ ] Ingredient CRUD với nutrients, allergen marker, vegan validation và ảnh.
- [ ] Recipe aggregate CRUD với author/category, serving/time/difficulty/nutrition/status/image.
- [ ] Ordered recipe steps và unique `(recipe_id, step_no)`.
- [ ] Recipe ingredients với quantity/unit/optional/note.
- [ ] Tính nutrition từ ingredient; quy định rõ unknown unit.
- [ ] Public list/detail/search/filter và author draft/list APIs.
- [ ] Submit/publish/reject state để sẵn sàng moderation.
- [ ] Admin ingredient/recipe APIs.
- [ ] Category validation/usage API ở blog-service; không share table.
- [ ] Chặn xóa category đang được recipe dùng và xử lý timeout rõ ràng.
- [ ] Recipe media storage và Gateway/docs routes.

## API bị ảnh hưởng

Giữ `/api/categories/**`; thêm `/api/ingredients/**`, `/api/recipes/**`, `/api/recipes/me`, submit, image, related và bounded category usage API.

## Công việc database

- Bảng mới: `ingredients`, `recipes`, `recipe_ingredients`, `recipe_steps`.
- Index search/status/category/author; unique normalized ingredient name và step number.
- `category_id`, `author_id` chỉ là external scalar.
- Dùng migration ngay từ đầu.

## Dependency liên service

```text
recipe-service --> blog-service category API
recipe-service --> object storage
api-gateway    --> recipe-service
```

## Yêu cầu kiểm thử

- Unit test nutrition calculation, state, order, authorization.
- Repository/search/constraint test.
- API test public/member/admin và upload.
- Contract test category API gồm timeout/unavailable.
- Migration, Swagger và Docker validation.

## Tiêu chí nghiệm thu

- [ ] Member tạo/sửa/submit recipe nhiều bước với canonical ingredient.
- [ ] Guest chỉ xem/search recipe published.
- [ ] Invalid category/ingredient không được lưu.
- [ ] Xóa category không tạo orphan recipe.
- [ ] API hoạt động qua Gateway và Swagger tổng hợp.

## Ngoài phạm vi

Pantry/allergy migration, meal generation, AI recommendation, seasonality, photo recognition và restaurant.

# Phase 3 — Hoàn thiện Community Content với Video và Admin

## Mục tiêu

Thêm video vào blog-service và hoàn thiện quản trị nội dung cần thiết cho MVP.

## Vì sao phase này ở đây

Blog/comment/vote/category đã có nền tảng tốt; recipe/category contract đã ổn định. Video tạo corpus cho search, recommendation và summarization sau này.

## Microservice liên quan

- `blog-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `identity-service` [HIỆN CÓ]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Mọi blog/category/comment/vote API và business rule.
- `TargetType.VIDEO`, tombstone, atomic vote và owner/admin behavior.

## Công việc triển khai

- [ ] Thêm `Video` entity/service/repository/controller trong blog-service.
- [ ] Hỗ trợ provider URL hợp lệ và/hoặc controlled upload.
- [ ] Member draft/edit/submit/delete; public search/detail/view.
- [ ] Validate optional `recipeId` qua recipe-service, không FK.
- [ ] Bật comment cho published video.
- [ ] Tái sử dụng vote storage/algorithm cho video.
- [ ] Thêm owned video/comment listing.
- [ ] Admin list/filter/review/takedown blog/video/comment.
- [ ] Audit admin actions và mở rộng category usage check.
- [ ] Thêm Gateway `/api/videos/**` và docs.

## API bị ảnh hưởng

Giữ API hiện tại; thêm `/api/videos/**`, `/api/videos/me`, submit/media, video vote và admin filters. Generic comment nhận `targetType=VIDEO` chỉ khi target published.

## Công việc database

- Thêm `videos`; tái sử dụng categories/comments/content_votes.
- Index status/published/category/author/search.
- `recipe_id` là external scalar; enum thay đổi qua migration.

## Dependency liên service

```text
blog-service --> recipe-service (optional recipe validation)
blog-service --> object/video provider
```

## Yêu cầu kiểm thử

- Unit/controller/security test tương đương blog.
- Real-MySQL test cho video search, view và vote concurrency.
- Contract test recipe validation và media security test.
- Swagger/Docker validation.

## Tiêu chí nghiệm thu

- [ ] Guest search/xem published blog, video và recipe.
- [ ] Member quản lý nội dung của mình và tương tác nội dung người khác.
- [ ] Admin quản lý nội dung với audit.
- [ ] Blog behavior/test hiện có không regression.

## Ngoài phạm vi

AI moderation thật, AI ranking, STT/video summary và meal planning.

# Phase 4 — Hoàn thiện dữ liệu dinh dưỡng cá nhân

## Mục tiêu

Tạo personalization context đầy đủ: goal, activity/TDEE, region, canonical allergies và pantry.

## Vì sao phase này ở đây

Ingredient ID phải tồn tại trước khi lưu pantry/allergy; các input này phải ổn định trước AI meal planner.

## Microservice liên quan

- `nutrition-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `identity-service` [HIỆN CÓ]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Health record URLs, BMI formula/history và ownership.
- Allergy API hiện tại trong compatibility window.
- Identity profile/JWT user ID.

## Công việc triển khai

- [ ] Chốt field ownership giữa identity và nutrition.
- [ ] Thêm activity, goal, region và target constraints.
- [ ] Tính TDEE với formula/version/rounding rõ ràng.
- [ ] Lưu TDEE/goal snapshot theo cách tương thích response cũ.
- [ ] Thêm user pantry với canonical ingredient ID.
- [ ] Chuyển allergy dần sang canonical ingredient ID.
- [ ] Mapping/retirement plan cho bảng `allergens`; không tạo nguồn ingredient thứ hai.
- [ ] Batch validate ID qua recipe-service.
- [ ] Thêm internal personalization-context API tối thiểu.
- [ ] Áp dụng privacy/consent cho health data và log.

## API bị ảnh hưởng

Giữ nutrition API hiện có; thêm `/nutrition/me/preferences`, `/summary`, `/pantry`, versioned allergy payload và internal context endpoint.

## Công việc database

- Tái sử dụng health records; thêm preference/activity/goal/region/TDEE/formula version.
- Thêm `user_ingredients`/pantry.
- Migrate allergy có backfill; external ingredient ID không FK.
- Unique `(user_id, ingredient_id)` và index history.

## Dependency liên service

```text
nutrition-service --> recipe-service (batch ingredient validation)
nutrition-service <-- userId từ identity JWT
```

## Yêu cầu kiểm thử

- Boundary/property tests cho BMI/TDEE.
- Migration/uniqueness tests.
- Contract tests cho ingredient API và outage.
- Security tests chống đọc health/pantry của user khác.
- Swagger/Docker và privacy log review.

## Tiêu chí nghiệm thu

- [ ] Member quản lý đủ input cho meal plan flow trong DOC.
- [ ] BMI/TDEE/goal deterministic và có tài liệu.
- [ ] Mọi allergy/pantry ingredient ID resolve được.
- [ ] Client cũ có lộ trình tương thích.
- [ ] Không có cross-service FK.

## Ngoài phạm vi

AI generation, meal plan persistence, wearable và photo recognition.

# Phase 5 — AI Runtime và Nutrition Chatbot

## Mục tiêu

Tạo một AI boundary có kiểm soát và triển khai member chatbot cùng guest trial giới hạn.

## Vì sao phase này ở đây

Identity, nutrition và ingredient contract đã đủ để grounding. Runtime chung tránh lặp provider/telemetry ở nhiều service.

## Microservice liên quan

- `ai-service` [MỚI]
- `nutrition-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `identity-service` [HIỆN CÓ]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Public/member distinction, health privacy và canonical IDs.

## Công việc triển khai

- [ ] Provider-neutral AI client và một provider implementation.
- [ ] Structured schema, prompt version và output validation.
- [ ] Timeout, bounded retry, circuit breaker, quota và stable error mapping.
- [ ] Persist conversation/message có pagination/delete rules.
- [ ] Guest session key khó đoán, hashed abuse signals, atomic quota/expiry.
- [ ] Ground answer bằng health summary và canonical facts khi user cho phép.
- [ ] Safety rule và cảnh báo không phải chẩn đoán y tế.
- [ ] Log latency/token/status không lộ secret/private content.
- [ ] Rate limit guest/member và thêm Gateway/docs routes.

## API bị ảnh hưởng

Thêm `/api/ai/chat/conversations/**` và `/api/ai/chat/guest/sessions/**` cho create/list/message/delete/usage.

## Công việc database

- `chat_conversations`, `chat_messages`, `guest_ai_usage`, basic `ai_request_logs`.
- `user_id` nullable hoặc guest ownership; không identity FK.
- Index owner/time, conversation/time, session hash/quota.
- Retention và deletion/anonymization policy.

## Dependency liên service

```text
ai-service --> nutrition-service (authorized summary)
ai-service --> recipe-service (facts/ID validation)
ai-service --> external AI provider
```

## Yêu cầu kiểm thử

- Unit test quota atomic, ownership, prompt và response parser.
- Provider fake contract; CI không gọi live provider.
- Security/rate-limit tests.
- Timeout, malformed JSON, hallucinated ID và quota-error tests.
- Migration/Docker/Gateway/Swagger validation.

## Tiêu chí nghiệm thu

- [ ] Member có conversation nhiều message được lưu.
- [ ] Guest bị giới hạn đúng và nhận prompt đăng ký khi hết lượt.
- [ ] Invalid AI output không được persist.
- [ ] Telemetry không lộ credential/private context.
- [ ] Chat chạy qua Gateway và có docs.

## Ngoài phạm vi

Meal plan, moderation, summary, photo recognition và wearable.

# Phase 6 — Weekly Meal Plan và Discovery đa nội dung

## Mục tiêu

Triển khai weekly menu cá nhân, replace/save và search/recommendation qua recipe/blog/video.

## Vì sao phase này ở đây

Phụ thuộc recipe/ingredient, video/content, complete health/allergy/pantry và AI runtime từ Phase 2–5.

## Microservice liên quan

- `nutrition-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `blog-service` [HIỆN CÓ]
- `ai-service` [MỚI]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Domain search endpoints, content visibility, nutrition ownership và AI validation.

## Công việc triển khai

- [ ] Thiết kế seven-day plan aggregate và generation states.
- [ ] Snapshot BMI/TDEE/goal/allergy/pantry/region/version.
- [ ] Hard-filter allergen trước AI ranking.
- [ ] Chỉ cung cấp candidate IDs hợp lệ cho AI.
- [ ] Validate mọi recipe ID, calories, duplicate rule và daily target.
- [ ] Persist days/items transactionally sau validation.
- [ ] Replace một item với cùng hard constraints và audit.
- [ ] List/detail/save/delete/regenerate có idempotency.
- [ ] Cross-domain search orchestration qua explicit APIs.
- [ ] Deterministic related ranking trước optional AI reranking.
- [ ] Dùng async job/polling nếu latency dài.

## API bị ảnh hưởng

Thêm `/nutrition/me/meal-plans/**`, generation job, item replacement, `/api/search` và `/api/recommendations/content`.

## Công việc database

- Nutrition sở hữu `meal_plans`, `meal_plan_days`, `meal_plan_items` và audit generation/replacement.
- External recipe ID + immutable display/nutrition snapshots, không FK.
- Unique plan/day và day/meal-slot; owner/week indexes.

## Dependency liên service

```text
nutrition-service --> recipe-service (candidate/final validation)
nutrition-service --> ai-service (generation/replacement)
ai-service search  --> recipe-service + blog-service
```

Allergy và hard nutrition rule được code domain enforce, không tin prompt.

## Yêu cầu kiểm thử

- Calorie tolerance, allergen, snapshot và replacement unit tests.
- Cross-service contract tests với AI fake.
- Hallucinated ID, empty candidates, timeout và duplicate request tests.
- Transaction rollback và search ranking/pagination tests.
- E2E Docker qua Gateway với deterministic fake AI.

## Tiêu chí nghiệm thu

- [ ] Member generate, xem, replace và save plan bảy ngày.
- [ ] Không item nào vi phạm allergy hoặc trỏ recipe không hợp lệ.
- [ ] Historical plan vẫn hiểu được khi recipe thay đổi.
- [ ] Search trả typed result recipe/blog/video.
- [ ] Failure không để lại partial-ready plan.

## Ngoài phạm vi

Seasonal optimization, restaurant, video summary, photo recognition và wearable.

# Phase 7 — Tìm nhà hàng và cửa hàng chay gần đây

## Mục tiêu

Tìm place chay theo vị trí, xem chi tiết và gợi ý theo món qua external provider có kiểm soát.

## Vì sao phase này ở đây

Đây là must-have nhưng cần recipe/ingredient và recommendation contract ổn định; tách sau core để cô lập quota và location privacy.

## Microservice liên quan

- `location-service` [MỚI]
- `recipe-service` [MỚI]
- `ai-service` [MỚI]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Canonical IDs, AI validation/telemetry và Gateway conventions.

## Công việc triển khai

- [ ] Chọn place provider và ghi rõ license/attribution/cache/quota.
- [ ] Nearby search theo lat/lng/radius và vegan constraint.
- [ ] Detail lookup và normalize response.
- [ ] Cache đúng policy provider, có expiry và unique external ID.
- [ ] Match dish keyword với recipe/ingredient; deterministic trước AI rerank.
- [ ] Validate coordinate/radius; không lưu location history mặc định.
- [ ] Redact tọa độ khỏi log; thêm rate limit/timeout/retry/circuit breaker/stale cache.
- [ ] Thêm Gateway/docs và provider health metrics.

## API bị ảnh hưởng

- `GET /api/places/vegan`
- `GET /api/places/{externalPlaceId}`
- `GET /api/places/recommendations`

## Công việc database

- Location sở hữu places/restaurants cache và optional restaurant dishes.
- External recipe/ingredient ID là scalar.
- Unique external ID, expiry và geospatial indexes.

## Dependency liên service

```text
location-service --> place provider
location-service --> recipe-service
location-service --> ai-service (optional ranking)
```

## Yêu cầu kiểm thử

- Provider fake/fixture contract tests.
- Coordinate/radius/privacy/cache tests.
- Timeout/quota/invalid payload/stale-cache tests.
- Gateway/Swagger và manual mobile-location test.

## Tiêu chí nghiệm thu

- [ ] Member tìm được place chay gần vị trí và xem detail chuẩn hóa.
- [ ] Dish query không sinh provider ID giả.
- [ ] Provider outage/quota degrade dự đoán được.
- [ ] Location và credential không lộ trong log/history.

## Ngoài phạm vi

Reservation, payment, delivery, review, navigation và sở hữu restaurant menu truth.

# Phase 8 — Trust, Moderation và AI Operations

## Mục tiêu

Thay auto-approve bằng AI-assisted moderation có audit và cung cấp monitoring/intervention cho admin.

## Vì sao phase này ở đây

Phải có content corpus và AI runtime trước. Phase này thay đổi publication behavior nên đặt sau MVP; manual admin takedown vẫn dùng được trong demo.

## Microservice liên quan

- `ai-service` [MỚI]
- `blog-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `identity-service` [HIỆN CÓ]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- `ContentModerationService`, content states, owner/admin authorization và audit/telemetry groundwork.

## Công việc triển khai

- [ ] Moderation API có label/score/reason/provider/model version.
- [ ] Thay auto-approve bằng resilient client và fail-closed/pending policy.
- [ ] Áp dụng cho blog/video/comment/recipe.
- [ ] Persist moderation case theo external target type/ID.
- [ ] Admin queue/detail/approve/reject/takedown/re-review.
- [ ] Admin decision gọi owning-service API, không ghi database service khác.
- [ ] Immutable audit log và evidence access control.
- [ ] AI service config, latency/error/quota metrics, alerts và safe enable/disable.
- [ ] Redact prompt/content mặc định, retention rõ ràng.
- [ ] Fallback cho provider outage và delayed callback.

## API bị ảnh hưởng

Giữ content APIs; thêm internal moderation evaluation và `/api/admin/moderation/**`, `/api/admin/ai/**`.

## Công việc database

- AI sở hữu `moderation_cases`, `ai_services`, expanded logs và alerts.
- External target/reviewer IDs là scalar.
- Index queue/status/time, service/status/time và unresolved alerts.
- Domain service vẫn sở hữu content status.

## Dependency liên service

```text
blog/recipe --> ai-service moderation
admin decision --> owning service status API
identity JWT --> admin authorization
```

## Yêu cầu kiểm thử

- Decision matrix/confidence threshold tests.
- Target contract và idempotent callback tests.
- Admin security/evidence tests.
- Provider outage và fail-closed tests.
- Audit immutability/telemetry redaction/E2E flagged-content tests.

## Tiêu chí nghiệm thu

- [ ] Production không dùng auto-approve placeholder.
- [ ] Flagged/uncertain content không public trước decision.
- [ ] Admin decision cập nhật đúng owner và có audit.
- [ ] Monitoring không lộ secret/private data.

## Ngoài phạm vi

Custom model training, autonomous permanent deletion, video transcription và ingredient vision.

# Phase 9 — Tóm tắt Video thành Recipe

## Mục tiêu

Chuyển cooking video được hỗ trợ thành bản tóm tắt từng bước qua async pipeline có review.

## Vì sao phase này ở đây

Phụ thuộc video, recipe steps, AI runtime, monitoring và moderation. STT latency không phù hợp với synchronous video CRUD.

## Microservice liên quan

- `ai-service` [MỚI]
- `blog-service` [HIỆN CÓ]
- `recipe-service` [MỚI]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Video access/media, recipe step model và AI telemetry.

## Công việc triển khai

- [ ] Chốt source/size/duration/language/copyright rules.
- [ ] Idempotent async jobs và state transitions.
- [ ] Lấy audio qua đường dẫn được provider cho phép.
- [ ] STT với transcript retention tối thiểu.
- [ ] Structured ordered summary và optional ingredient candidates.
- [ ] Validate mọi domain ID, loại/flag hallucinated IDs.
- [ ] Author/admin review/correction trước khi tạo/link recipe draft.
- [ ] Retry/cancel/expiry và cost limits.

## API bị ảnh hưởng

Thêm video AI summary create/get/approve, summary job status và optional create-recipe-draft.

## Công việc database

- AI sở hữu summary jobs/results với external video ID và model/prompt version.
- Recipe draft thuộc recipe-service; video link thuộc blog-service.
- Index video/status/time và unique idempotency key.

## Dependency liên service

```text
ai-service --> blog-service (video metadata/source)
ai-service --> STT + LLM providers
ai-service --> recipe-service (validation/draft command)
```

## Yêu cầu kiểm thử

- Job state/idempotency/provider fake tests.
- Summary schema/hallucinated ID tests.
- Long video/unsupported source/timeout/cancel tests.
- Authorization và E2E polling/draft creation.

## Tiêu chí nghiệm thu

- [ ] Video hợp lệ tạo được ordered summary bất đồng bộ.
- [ ] Failure retry được, không duplicate job/recipe.
- [ ] Không lưu unvalidated AI ID.
- [ ] User review trước khi output thành authoritative recipe.

## Ngoài phạm vi

Video editing, bypass copyright, live stream và ingredient photo recognition.

# Phase 10 — Seasonal/Regional và Ingredient Photo Intelligence

## Mục tiêu

Nâng recommendation bằng seasonality/region và ingredient recognition có user confirmation.

## Vì sao phase này ở đây

Cần ingredient catalog trưởng thành, meal plan, AI validation/monitoring và dữ liệu sử dụng thực tế; không cần để chứng minh MVP core.

## Microservice liên quan

- `recipe-service` [MỚI]
- `nutrition-service` [HIỆN CÓ]
- `ai-service` [MỚI]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Canonical ingredients, pantry, region, meal validation và AI controls.

## Công việc triển khai

- [ ] Admin-managed ingredient availability theo region/month/provenance.
- [ ] Deterministic seasonal score cho recipe.
- [ ] Seasonality là soft preference, không override allergy/nutrition.
- [ ] Secure temporary image upload và CV adapter.
- [ ] Candidate + confidence; freshness chỉ là hint.
- [ ] Match canonical ingredient và bắt buộc user confirm trước pantry update.
- [ ] Xử lý unknown/low-confidence, không tuyên bố food safety.
- [ ] Opt-in correction metrics và short image retention.

## API bị ảnh hưởng

Thêm seasonality admin APIs, recognition job APIs, pantry confirmation và explanation fields.

## Công việc database

- Recipe sở hữu `ingredient_seasonality`.
- AI sở hữu short-lived recognition jobs/results.
- Nutrition sở hữu confirmed pantry changes và provenance.

## Dependency liên service

```text
ai-service --> CV provider --> recipe-service matching
user confirm ----------------> nutrition-service pantry
recipe seasonality ----------> meal ranking
```

## Yêu cầu kiểm thử

- Month/region/ranking tests.
- CV fake/confidence/unknown tests.
- File security/retention cleanup tests.
- Không pantry mutation trước confirmation.
- Allergy luôn ưu tiên hơn seasonality.

## Tiêu chí nghiệm thu

- [ ] Meal suggestion giải thích được seasonal/regional preference.
- [ ] Ảnh trả canonical candidates kèm confidence.
- [ ] User phải confirm trước khi lưu pantry.
- [ ] Freshness không được trình bày như bảo đảm an toàn.

## Ngoài phạm vi

Food safety certification, grocery purchase, custom CV training và wearable.

# Phase 11 — Tích hợp Health/Wearable tùy chọn

## Mục tiêu

Đồng bộ health/activity data có consent và so sánh với meal plan mà không phá manual flow hoặc privacy.

## Vì sao phase này ở đây

DOC đánh dấu optional; có compliance/provider/mobile complexity cao và chỉ hữu ích khi health/meal plan đã ổn định.

## Microservice liên quan

- `nutrition-service` [HIỆN CÓ]
- `identity-service` [HIỆN CÓ]
- `ai-service` [MỚI]
- `api-gateway` [HIỆN CÓ]

## Chức năng hiện có cần giữ

- Manual health entry, privacy, meal snapshot và AI validation.

## Công việc triển khai

- [ ] Chọn provider sau feasibility/consent review.
- [ ] OAuth/mobile handoff, scope, consent, revoke và delete.
- [ ] Encrypt provider tokens; không log/trả API.
- [ ] Idempotent incremental sync có provenance/conflict rules.
- [ ] Tách observed data khỏi manual measurements.
- [ ] So sánh với saved plan và tạo bounded explainable adjustment.
- [ ] Sync status/retry/disconnect/delete APIs.
- [ ] Privacy/security/provider compliance review.

## API bị ảnh hưởng

Thêm `/api/nutrition/me/health-connections/{provider}` cho connect/status/sync/disconnect.

## Công việc database

- Nutrition sở hữu health connections, encrypted token references, cursor, consent history và imported records.
- Không đặt wearable credential trong users.
- Unique user/provider và sync/time indexes; retention/delete migrations.

## Dependency liên service

```text
nutrition-service --> approved health provider
nutrition-service --> ai-service (optional explanation)
identity JWT      --> user consent ownership
```

## Yêu cầu kiểm thử

- Sandbox/fake provider contract tests.
- Token encryption/scope/consent/revoke/delete tests.
- Duplicate/out-of-order/conflict tests.
- Outage/backoff/partial sync recovery.
- Security/privacy/manual device validation.

## Tiêu chí nghiệm thu

- [ ] User connect, xem status, sync, disconnect và delete data được.
- [ ] Manual flow vẫn hoạt động độc lập.
- [ ] Sync idempotent và có provenance.
- [ ] Recommendation adjustment được validate và giải thích.

## Ngoài phạm vi

Clinical diagnosis, emergency alert, scraping device không hỗ trợ và bắt buộc dùng wearable.

# Ma trận Yêu cầu theo Phase

| Yêu cầu | Trạng thái hiện tại | Service sở hữu | Phase dự kiến | Dependency |
|---|---|---|---|---|
| Register/login | Một phần | identity-service | Phase 1 | Không |
| Verify/reset/refresh | Chưa có | identity-service | Phase 1 | Auth hiện có |
| Google/social login | Tùy chọn/chưa có | identity-service | Post-MVP sau Phase 1 | Provider decision |
| Role/status authorization | Một phần | identity + resource services | Phase 1 | Auth contract |
| Profile/avatar | Một phần | identity-service | Phase 1 và 4 | Field ownership |
| Admin member management | Chưa có | identity-service | Phase 1 | Role/audit |
| BMI/health history | Một phần | nutrition-service | Phase 4 | Phase 1 migrations |
| TDEE/goal/activity | Chưa có | nutrition-service | Phase 4 | Profile ownership |
| Allergy | Một phần | nutrition-service | Phase 4 | Phase 2 ingredients |
| Pantry | Chưa có | nutrition-service | Phase 4 | Phase 2 ingredients |
| Ingredient catalog | Chưa có | recipe-service | Phase 2 | Phase 1 |
| Recipe/step/ingredient | Chưa có | recipe-service | Phase 2 | Ingredients/categories |
| Category | Hoàn thành phạm vi hiện tại | blog-service | Giữ; tích hợp Phase 2–3 | Usage API |
| Blog | Hoàn thành phạm vi hiện tại | blog-service | Giữ; admin Phase 3 | Audit |
| Video | Chưa có | blog-service | Phase 3 | Category/media |
| Comment/reply | Một phần | blog-service | Phase 3 video; Phase 8 moderation | Video/AI |
| Vote | Một phần | blog-service | Phase 3 video | Video |
| Public content | Một phần | blog-service | Phase 3 | Video |
| Cross-content search | Một phần | AI orchestration + domain indexes | Phase 6 | Phase 2–5 |
| Recommendation | Một phần | ai-service + domain APIs | Phase 6 | Content corpus |
| Weekly meal plan | Chưa có | nutrition-service | Phase 6 | Phase 2, 4, 5 |
| Replace/save plan | Chưa có | nutrition-service | Phase 6 | Validated plan |
| Member chatbot | Chưa có | ai-service | Phase 5 | Phase 1, 2, 4 |
| Guest chatbot trial | Chưa có | ai-service | Phase 5 | Quota/rate limit |
| Nearby restaurant/shop | Chưa có | location-service | Phase 7 | Provider/recipe context |
| Restaurant suggestion theo món | Chưa có | location + optional AI | Phase 7 | Nearby search/catalog |
| AI moderation | Placeholder | AI quyết định; domain enforce | Phase 8 | Phase 3, 5 |
| Admin content review | Một phần | domain + AI cases | Phase 3 và 8 | Role/audit/content |
| AI metrics/alerts/intervention | Chưa có | ai-service | Phase 8 | Phase 5 telemetry |
| Video summarization | Chưa có | ai-service | Phase 9 | Phase 2, 3, 5, 8 |
| Seasonal/regional | Chưa có | recipe + nutrition | Phase 10 | Recipe/region/meal plan |
| Ingredient photo/freshness | Chưa có | AI + nutrition confirmation | Phase 10 | Catalog/pantry |
| Wearable/Health App | Tùy chọn | nutrition-service | Phase 11 | Health/meal plan/consent |
| Cross-service FK trong DOC | Cần review | Từng domain owner | Khi bảng được tạo | Phải đổi thành scalar ID + API |
| Presentation/navigation frontend | Không phải backend | Client | Không có backend phase | Backend chỉ cung cấp API |

# Ranh giới MVP

## Bắt buộc cho MVP / Demo

Phase 1 đến Phase 7:

- Phase 1: nền tảng account, schema, admin và deployment đáng tin cậy.
- Phase 2: core recipe/ingredient còn thiếu.
- Phase 3: blog/video/comment/vote/admin content theo must-have.
- Phase 4: BMI/TDEE/goal/allergy/pantry.
- Phase 5: member chatbot và limited guest chatbot.
- Phase 6: weekly plan, replace/save và cross-content discovery.
- Phase 7: nearby vegan places theo danh sách must-have của DOC.

Demo có thể dùng deterministic sandbox adapter cho AI/place provider, nhưng validation, quota, persistence và failure behavior phải thật. Auto-approve phải được công bố là giới hạn demo, không được mô tả như AI moderation hoàn chỉnh.

## Sau MVP

- Phase 8: AI moderation và AI/admin operations production-grade.
- Phase 9: STT và video recipe summarization.
- Phase 10: seasonal/regional optimization và ingredient vision.
- Google/social login có thể làm sau Phase 1 nếu product owner không nâng mức ưu tiên.

## Tùy chọn / Nâng cao

- Phase 11 wearable/health app là optional theo DOC.
- Freshness estimation và AI reranking chỉ mang tính tư vấn.
- Custom model training, clinical advice, delivery/reservation và irreversible autonomous moderation nằm ngoài scope.

# Rủi ro kiến trúc và Technical Debt

| Mức độ | Service ảnh hưởng | Vấn đề thực tế | Phase xử lý |
|---|---|---|---|
| CAO | identity | Login bỏ qua `PENDING`, inactive/blocked và `emailVerified=false`, vẫn cấp JWT | Phase 1 |
| CAO | Các persistence service | `ddl-auto=update`, không có versioned migration; MySQL enum không tự cập nhật đáng tin cậy | Phase 1 |
| CAO | Tất cả service | Properties có default DB/MinIO/JWT credential; default HS256 key có thể làm lộ toàn hệ thống | Phase 1 |
| CAO | blog | Moderation hiện auto-approve mọi nội dung | Phase 8; công bố rõ trước đó |
| CAO | Compose/toàn hệ thống | Compose chỉ chạy MySQL/MinIO; không Dockerfile, service container, identity DB init hay bucket init | Phase 1 |
| CAO | AI tương lai | Chưa có output validation; AI có thể sinh ID giả | Nền Phase 5; enforce Phase 6/9/10 |
| TRUNG BÌNH | JWT toàn hệ thống | Config copy, shared HS256 secret, không issuer/audience/rotation/revoke tức thời | Phase 1 |
| TRUNG BÌNH | Gateway | Upstream URI hardcode localhost | Phase 1 |
| TRUNG BÌNH | nutrition/recipe | Allergen hiện tại và ingredient tương lai dễ trùng ownership | Phase 2, 4 |
| TRUNG BÌNH | blog/recipe | Category do blog sở hữu nhưng recipe dùng; local JPA không biết external usage | Phase 2, 3 |
| TRUNG BÌNH | identity so với DOC | Khác ID/role/status/profile model; migrate mù sẽ phá compatibility | Phase 1 |
| TRUNG BÌNH | Tất cả service | Shared conventions được copy, có nguy cơ drift; shared binary library lại có nguy cơ coupling release | Phase 1 contract tests/templates |
| TRUNG BÌNH | identity/nutrition tests | Integration coverage không đồng đều, phụ thuộc local MySQL | Phase 1 |
| TRUNG BÌNH | Gateway tests | Chỉ context-load; routing/prefix/upload/CORS/Swagger có thể regression | Phase 1 |
| TRUNG BÌNH | Storage | Compose không tạo bucket/policy; public URL policy chưa rõ | Phase 1, xem lại Phase 3 |
| TRUNG BÌNH | Service calls tương lai | Chưa có timeout/retry/circuit breaker/contract infrastructure | Bắt đầu Phase 2, chuẩn hóa Phase 5 |
| THẤP | Gateway | CORS `http://localhost:*` phù hợp local nhưng không production | Phase 1 |
| THẤP | identity | `/auth/test` nằm trong public list nhưng không có controller | Phase 1 |
| THẤP | Repository | `target/` artifact hiện diện có thể gây nhiễu inspection | Phase 1 housekeeping |

# Thứ tự thực thi khuyến nghị

```text
Phase 1: Nền tảng an toàn/tái lập
   |
   +--> Phase 2: Recipe + ingredient
   |       |
   |       +--> Phase 4: Nutrition inputs
   |       |       |
   |       |       +-------------------+
   |       |                           |
   |       +--> Phase 3: Video/content  |
   |                   |               |
   +--> Phase 5: AI runtime/chatbot <---+
               |
        +------+----------------+
        |                       |
        v                       v
Phase 6: Meal plan/search    Phase 8: Moderation/AI ops
        |                       |
        +--> Phase 7: Place     +--> Phase 9: Video summary
        |
        +--> Phase 10: Seasonal/vision
                 |
                 +--> Phase 11: Wearable tùy chọn
```

Phase 3 và Phase 4 có thể chạy song song sau Phase 2. Phase 5 có thể khởi động sau Phase 1, nhưng personalized grounding chỉ nghiệm thu khi Phase 2 và 4 xong. Phase 6 là điểm hội tụ recipe, content, nutrition và AI. Phase 7 có thể song song với Phase 8 sau khi contract Phase 6 ổn định. Phase 9 và 10 là hai nhánh nâng cao độc lập theo dependency; Phase 11 cuối cùng vì optional và compliance-heavy.

# Quy tắc cho Codex khi triển khai từng Phase

1. Chỉ triển khai phase được yêu cầu.
2. Kiểm tra các service liên quan trước khi sửa.
3. Giữ nguyên chức năng đang hoạt động.
4. Không viết lại code đã hoàn thành nếu không có lý do kỹ thuật cụ thể.
5. Không triển khai sớm chức năng của phase tương lai.
6. Duy trì backward compatibility khi thực tế cho phép.
7. Tuân theo package và naming convention hiện có.
8. Không tạo entity trùng lặp nếu không có lý do rõ ràng.
9. Không tạo foreign key xuyên database/service.
10. Giao tiếp service-to-service phải qua API rõ ràng.
11. Build các service bị ảnh hưởng sau thay đổi có ý nghĩa.
12. Chạy test sau thay đổi có ý nghĩa.
13. Xác minh API bằng Swagger hoặc automated tests.
14. Giữ API Gateway routes đồng bộ.
15. Ghi tài liệu cho mọi biến môi trường mới.
16. Không bao giờ commit secret, password, API key hoặc token.
17. Validate response từ external API và AI trước khi lưu.
18. ID do AI sinh phải được kiểm tra với domain data thật.
19. Cập nhật roadmap sau khi hoàn thành một phase.
20. Dừng sau khi hoàn thành phase được yêu cầu.
