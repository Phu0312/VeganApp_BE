# VeggiePal Backend Implementation Roadmap

## Basis and Decision Principles

This roadmap is based on a code-level review of the four current Maven projects, their controllers, services, entities, repositories, security configuration, properties, Gateway routes, OpenAPI configuration, storage code, Docker Compose file, and tests, compared with the complete functional and data-model content of `VeganApp.docx`.

The document is the functional-requirement source; the repository is the implementation source. The data model in the document is treated as intent rather than a schema to copy literally because it contains cross-domain foreign keys and UUID identifiers that conflict with the existing microservice databases and `Long` identifiers. Final ownership below deliberately avoids cross-service database foreign keys.

The proposed sequence is dependency-driven. It preserves completed code, establishes canonical food data before personalization, establishes health inputs before meal generation, and establishes a reusable AI boundary before AI-dependent features. It does not create one service per feature.

# Current Backend Assessment

| Feature / Domain | Current Service | Status | Existing Implementation | Missing Work |
|---|---|---|---|---|
| API routing and aggregated OpenAPI | `api-gateway` | PARTIALLY IMPLEMENTED | Routes identity, nutrition, blogs, categories, comments; aggregated Swagger UI; local CORS | Routes for all future domains; environment-based upstream URLs; route tests; deployable configuration |
| Registration and password login | `identity-service` | PARTIALLY IMPLEMENTED | Email normalization, BCrypt, duplicate check, access JWT with user/role claims | Enforce account status/verification at login; email verification; password reset; refresh/revocation; optional Google sign-in |
| JWT authentication | `identity-service`, all resource services | NEEDS REFACTOR / ARCHITECTURE REVIEW | HS256 issuer and matching decoders; stateless resource-server security; structured 401/403 responses | Central key/issuer policy, rotation strategy, audience/issuer validation, refresh-token lifecycle, immediate suspension/revocation behavior |
| Roles and authorization | `identity-service`, `blog-service` | PARTIALLY IMPLEMENTED | `USER`/`ADMIN`; admin category methods; owner/admin checks for blogs/comments | Requirements call member/admin semantics; admin user APIs; comprehensive method authorization; disabled-account handling |
| User profile | `identity-service` | PARTIALLY IMPLEMENTED | Name, phone, birth date, avatar upload, password change, public batch lookup | Gender, activity level, region and other meal-planning inputs; clarify height ownership; profile completion validation |
| File/object storage | `identity-service`, `blog-service` | PARTIALLY IMPLEMENTED | S3-compatible upload/delete, magic-byte validation, avatar and blog thumbnail buckets configured | Compose does not create buckets/policies; no service containers; video/recipe media policy; production credentials and private/public access decision |
| User administration | None beyond identity persistence | NOT IMPLEMENTED | Admin role can be present in JWT | List/filter accounts, suspend/reactivate, inspect account/content relation via APIs, audit admin actions |
| Health records and BMI | `nutrition-service` | PARTIALLY IMPLEMENTED | Height/weight history, server-side BMI, ownership filtering, pagination, latest/update APIs | TDEE, activity inputs, health goal, target calories, deletion/retention decision, meal-planner snapshot contract |
| Allergies | `nutrition-service` | PARTIALLY IMPLEMENTED | Seeded allergen catalog and replace-all user allergy API | Canonical relationship to ingredients; severity if retained from document; validation contract with recipe catalog |
| Pantry / ingredients owned by user | None | NOT IMPLEMENTED | None | User pantry associations, quantities/availability if required, ingredient validation |
| Canonical ingredients and nutrition facts | None | NOT IMPLEMENTED | Allergens are a separate limited catalog only | Ingredient catalog, nutrients, allergen flags, images, indexes, admin CRUD, stable API contract |
| Recipes, steps, recipe ingredients | None | NOT IMPLEMENTED | None | Complete recipe aggregate, moderation/status, media, authoring, public search/read APIs |
| Categories | `blog-service` | COMPLETE for current scope | Two-level typed tree; admin CRUD; active state; uniqueness; public reads | Contract for recipe use and video use; deletion checks must include external consumers without cross-DB FKs |
| Blogs | `blog-service` | COMPLETE for current scope | Draft/submit/publish flow, public/owner reads, keyword/category/sort, related blogs, thumbnails, views, owner/admin deletion | Admin listing/filter/review APIs; recipe link if desired; real moderation replaces auto-approval |
| Comments and replies | `blog-service` | PARTIALLY IMPLEMENTED | Blog comments, one-level replies, tombstones, owner/admin delete, pagination | Enable video target after videos exist; admin moderation queues; real AI moderation |
| Votes | `blog-service` | PARTIALLY IMPLEMENTED | Blog votes, toggle/switch/removal, batch current-user lookup, atomic score updates | Enable equivalent video APIs and target validation |
| Videos | None; extension points in `blog-service` | NOT IMPLEMENTED | `TargetType.VIDEO` and compatible comment/vote schema already exist | Video entity, provider/upload metadata, author/admin CRUD, search/read/view APIs, media integration |
| Public content search | `blog-service` | PARTIALLY IMPLEMENTED | Public blog keyword/category search and same-category related blogs | Video and recipe search; unified result contract; cross-service discovery/recommendations |
| Content recommendations | `blog-service` | PARTIALLY IMPLEMENTED | Five related blogs from same category | Related videos/recipes, ranking, personalization, AI validation |
| AI nutrition chatbot | None | NOT IMPLEMENTED | None | Provider abstraction, conversations/messages, safety/grounding, member limits, persistence |
| Guest chatbot trial | None | NOT IMPLEMENTED | None | Guest session key, hashed abuse signals, atomic quota, rate limiting and upgrade response |
| Personalized weekly meal plans | None | NOT IMPLEMENTED | BMI and allergies provide partial inputs | Goals/TDEE/pantry; generation; recipe validation; seven-day persistence; replacement; save/view history |
| Seasonal/regional meal suitability | None | NOT IMPLEMENTED | None | Ingredient seasonality/region data and ranking constraints |
| Restaurant / vegan shop search | None | NOT IMPLEMENTED | None | Place-provider integration, geospatial query/cache, details, dish relevance, privacy/quotas |
| Content moderation | `blog-service` | NEEDS REFACTOR / ARCHITECTURE REVIEW | Good `ContentModerationService` seam and pending/rejected states | Current implementation auto-approves everything; moderation cases, provider integration, admin decisions and audit |
| AI operations monitoring | None | NOT IMPLEMENTED | None | AI service registry/config, request logs/metrics, alerts, admin controls and safe redaction |
| Video recipe summarization | None | NOT IMPLEMENTED | None | Audio/STT workflow, summarization, asynchronous status, persisted validated result |
| Ingredient recognition from photos | None | NOT IMPLEMENTED | None | Image upload, CV provider, confidence/freshness handling, canonical ingredient matching and user confirmation |
| Wearable / health app integration | None | OPTIONAL | Explicitly optional in the requirements | Consent, provider adapters, encrypted tokens, sync, reconciliation, deletion and failure recovery |
| Social login, OTP and refresh-token tables described in DOC | None | PARTIALLY IMPLEMENTED | Password registration/login and short-lived access identity exist | Decide MVP scope; email OTP/reset and refresh are needed for production auth; Google login can be post-MVP |
| Database lifecycle | All persistence services | NEEDS REFACTOR / ARCHITECTURE REVIEW | Separate schemas; useful indexes; Hibernate creates/updates tables; allergen seed script | Versioned migrations, repeatable reference-data seed, test profiles/containers, documented ownership |
| Automated tests | All services | PARTIALLY IMPLEMENTED | 52 identity, 42 nutrition, 158 blog, and 1 Gateway `@Test`; controller/service/security coverage; real MySQL blog integration test | Gateway route tests, identity/nutrition DB integration tests, cross-service contract tests, external-provider fakes, end-to-end Docker validation |

# Existing Microservices

## api-gateway

### Current responsibility

Single public entry point, local CORS handling, path routing, and aggregation of service OpenAPI documents.

### Existing features

- Spring Cloud Gateway Server WebMVC on port 8080.
- Routes `/api/auth/**` and `/api/users/**` to identity, `/api/nutrition/**` to nutrition, and `/api/blogs/**`, `/api/categories/**`, `/api/comments/**` to blog.
- Uses `StripPrefix=1`; service controllers intentionally omit `/api`.
- Combined Swagger UI at `/swagger-ui.html`.

### Important entities

None. The Gateway must not own domain data.

### Existing APIs

It exposes the routed paths above and service documentation paths. It has no business controller.

### External dependencies

Hardcoded HTTP connections to `localhost:8081`, `:8082`, and `:8083`.

### Problems / incomplete areas

- No JWT enforcement or rate limiting at the edge; resource services enforce security individually.
- Upstream URLs are not environment-driven and will fail between containers.
- No routes for recipes, videos, AI/chat, search/recommendations, or locations.
- Only a context-load test; route, CORS, and Swagger aggregation behavior are untested.

### Should this service remain as-is?

Keep the boundary, but not the configuration as-is. It should stay a thin edge/router and must not acquire domain orchestration or data ownership.

## identity-service

### Current responsibility

Account registration/login, JWT issuance/validation, current-user profile, password/avatar management, and limited public author lookup.

### Existing features

- BCrypt registration and login with normalized emails.
- HS256 access tokens containing `userId` and `role`, valid for 24 hours.
- Profile get/patch, password change, and validated S3-compatible avatar upload.
- Public batch lookup of up to 50 active authors without exposing email.
- Consistent response envelope, validation errors, and security errors.

### Important entities

- `User`: email, password hash, full name, phone, avatar, birth date, role, status, verification flag, timestamps.

### Existing APIs

- `POST /auth/register`
- `POST /auth/login`
- `GET|PATCH /users/me`
- `PUT /users/me/password`
- `POST /users/me/avatar`
- `GET /users/batch?ids=...`

### External dependencies

MySQL schema `veggiepal_identity`; S3-compatible storage/MinIO; the shared JWT secret used by resource services.

### Problems / incomplete areas

- Registration creates `PENDING`/unverified users, but login does not reject unverified or blocked/inactive users.
- No verification, OTP, reset-password, refresh/logout/revocation, social login, or admin account APIs.
- Current code uses `Long`, `USER`, and embedded profile fields while the DOC sketches UUIDs, `MEMBER`, and a separate profile table. This needs an explicit compatibility decision, not a blind schema copy.
- Default database/storage credentials and JWT secret are present in properties.
- Identity database is not auto-created by current Compose or URL.

### Should this service remain as-is?

Yes as the sole account and credential owner. Extend it; do not copy users or credentials into other services. Other services should store immutable `userId` references from JWT/API contracts only.

## nutrition-service

### Current responsibility

User-owned health history and allergy selections.

### Existing features

- Create/list/latest/update health records scoped to the JWT user.
- Server-side BMI calculation rounded half-up to one decimal.
- Seeded vegan-relevant allergen catalog and transactional replace-all selection.
- Security, OpenAPI, error envelope, mapping, repository and service/controller tests.

### Important entities

- `HealthRecord`: external `userId`, height, weight, BMI, recorded/created/updated times.
- `Allergen`: code, name, category.
- `UserAllergy`: external `userId` plus local allergen relation.

### Existing APIs

- `GET /nutrition/allergens`
- `GET|PUT /nutrition/me/allergies`
- `POST|GET /nutrition/me/health-records`
- `GET /nutrition/me/health-records/latest`
- `PUT /nutrition/me/health-records/{id}`

### External dependencies

MySQL schema `veggiepal_nutrition`; JWT secret compatible with identity. It makes no service-to-service calls today.

### Problems / incomplete areas

- Health data lacks goal, activity level, TDEE, target calories, and region needed by meal planning.
- The local allergen catalog duplicates the future canonical ingredient concern and does not represent document severity.
- No pantry/user-ingredient model or meal-plan persistence.
- No database-backed integration test comparable to blog-service.

### Should this service remain as-is?

Keep and expand it as the owner of personal nutrition inputs and persisted meal plans. Canonical ingredient/recipe data must live elsewhere; nutrition stores external IDs and snapshots, never cross-database foreign keys.

## blog-service

### Current responsibility

Community blog content, category taxonomy, comments, votes, thumbnails, and a moderation seam.

### Existing features

- Blog draft/create/edit/submit/delete, thumbnail upload, public search/read, view counts, owner listings and related blogs.
- Admin-aware takedown behavior and admin-only category CRUD.
- Two-level active category tree.
- One-level comment replies with deletion tombstones.
- Transactional blog vote toggle/switch/remove and denormalized score maintenance.
- Polymorphic comment/vote storage already includes `VIDEO` enum support.
- Extensive unit/slice/security tests plus a real-MySQL integration suite.

### Important entities

- `Blog`, `Category`, `Comment`, `ContentVote`.

### Existing APIs

- `GET|POST /blogs`, `GET /blogs/me`, `GET|PUT|DELETE /blogs/{id}`
- `POST /blogs/{id}/submit`, `POST /blogs/{id}/thumbnail`
- `GET /blogs/{id}/related`
- `POST|DELETE /blogs/{id}/vote`, `GET /blogs/me/votes`
- `GET|POST /categories`, `GET|PUT|DELETE /categories/{id}`
- `GET|POST /comments`, `GET /comments/{id}/replies`, `PUT|DELETE /comments/{id}`

### External dependencies

MySQL schema `veggiepal_blog`; S3-compatible thumbnail storage; shared JWT secret. Clients currently resolve authors through identity `/users/batch`; blog-service does not call identity.

### Problems / incomplete areas

- `AutoApproveContentModerationService` approves all content, so moderation is not actually implemented.
- There is no video entity/API even though comment/vote types anticipate it.
- No admin queue/list/review endpoints for content.
- Category deletion knows only local blog references; future recipe consumers require an explicit usage contract.
- Media bucket provisioning is absent from the actual Compose file.

### Should this service remain as-is?

Keep it and broaden its responsibility to community content (blogs and videos). Do not create a separate video service for the current scale: authorship, categories, moderation, comments, votes, storage, and search behavior are shared, and the schema already anticipates video targets.

# Proposed Final Microservice Architecture

## api-gateway

Status: EXISTING

### Responsibility

Public routing, CORS, documentation aggregation, and optional edge controls such as coarse rate limits.

### Owned Data

None.

### Related Features

All public APIs and Swagger access.

### Depends On

Service endpoints configured by environment or container DNS.

### Exposes APIs To

Web/mobile/admin clients.

### Architecture Notes

Keep business logic out. Add one API route and one docs route for every new service; synchronize OpenAPI server prefixes.

## identity-service

Status: EXISTING

### Responsibility

Accounts, credentials, roles/status, verification/recovery, refresh sessions, public user summaries, and admin account actions.

### Owned Data

Users, profile identity fields, OTP/verification records, refresh sessions, optional social account links, account/admin audit records.

### Related Features

Authentication, authorization claims, profile, member management.

### Depends On

Mail/OTP provider and object storage; no domain-service database.

### Exposes APIs To

Clients and bounded public/internal identity lookups.

### Architecture Notes

Remain the only issuer of user identity and tokens. Prefer asymmetric signing or a managed issuer before production; if HS256 remains for the demo, require one environment secret and issuer/audience validation everywhere.

## nutrition-service

Status: EXISTING

### Responsibility

Personal health/nutrition inputs, BMI/TDEE/goals, allergy and pantry selections, and persisted meal plans.

### Owned Data

Health records, nutrition preference/profile, user allergy ingredient IDs, pantry entries, meal plans/days/items and generation snapshots.

### Related Features

BMI/TDEE, allergies, available ingredients, goals, weekly menus, meal replacement, optional health synchronization.

### Depends On

`recipe-service` for ingredient/recipe validation and nutrition data; `ai-service` for generated candidates; identity only through JWT claims or a narrow explicit API when unavoidable.

### Exposes APIs To

Clients and bounded personalization context to `ai-service`.

### Architecture Notes

Store external recipe/ingredient IDs as plain values plus immutable snapshots. No JPA relation or database FK may point into another service.

## blog-service

Status: EXISTING

### Responsibility

Community content: blogs, videos, shared categories, comments, votes, content state, media metadata, and admin content operations.

### Owned Data

Blogs, videos, category tree, comments, votes, view/vote counters, content-side moderation state.

### Related Features

Public content, author management, video upload/linking, interaction, category administration, content search.

### Depends On

Object/video storage or provider; `ai-service` moderation and video-summary APIs; optional recipe references validated through `recipe-service`.

### Exposes APIs To

Clients, `ai-service` discovery/moderation orchestration, and `recipe-service` only through explicit contracts where needed.

### Architecture Notes

The name remains for compatibility, but the boundary becomes community content. Keep the existing polymorphic comment/vote model and working blog APIs.

## recipe-service

Status: NEW

### Responsibility

Canonical vegan ingredient catalog and recipe aggregates, including steps, quantities, nutrients, statuses and seasonality metadata.

### Owned Data

Ingredients, ingredient nutrients/allergen attributes, ingredient seasonality, recipes, recipe ingredients, recipe steps, recipe media metadata.

### Related Features

Recipe authoring/search, ingredient lookup, nutrition calculation, meal-plan validation, pantry/allergy references, seasonal suitability.

### Depends On

`blog-service` category contract if the existing shared taxonomy is reused; object storage; JWT identity claims; optional `ai-service` moderation.

### Exposes APIs To

Clients, `nutrition-service`, `ai-service`, and `location-service` through versioned REST contracts.

### Architecture Notes

This is the one necessary new core domain boundary. It prevents ingredients/recipes from being duplicated across nutrition, meal planning, AI and location. Category IDs remain owned by blog-service initially; cache names only as display snapshots where needed.

## ai-service

Status: NEW

### Responsibility

Provider-neutral AI execution and validation, nutrition chat, guest quotas, cross-domain discovery/recommendation orchestration, moderation cases, video summarization jobs, and AI operational telemetry.

### Owned Data

Chat conversations/messages, guest usage, moderation cases/decisions, AI service configuration references, request logs/alerts, summary/recognition job outputs. It does not own recipes, user health, videos, or meal plans.

### Related Features

Chatbot, meal-plan candidate generation, related-content ranking, moderation, monitoring, video summaries, image recognition.

### Depends On

External LLM/STT/CV providers and explicit APIs from nutrition, recipe, blog, identity (minimal display/admin validation), and location as appropriate.

### Exposes APIs To

Clients for chat/search/recommendations and internal authenticated APIs to domain services.

### Architecture Notes

Use structured schemas and validate every returned ID against owning services before persistence. Provider timeouts, retries, circuit breaking, redaction and cost limits belong here. This is one AI platform service, not one service per model.

## location-service

Status: NEW

### Responsibility

Vegan restaurant/shop discovery, external place-provider integration, bounded caching, geospatial filtering and dish-to-place relevance.

### Owned Data

Cached places, provider IDs, geolocation/details, cache expiry, and optional observed dish associations. It must not own recipes or ingredients.

### Related Features

Nearby vegan places, place details, food-related place suggestions.

### Depends On

External map/place provider; `recipe-service` for canonical dish/ingredient context; optional `ai-service` ranking.

### Exposes APIs To

Clients and recommendation orchestration.

### Architecture Notes

This boundary is justified by external-provider quotas, geospatial caching and location privacy. It is not needed until the core content/food data contracts are stable.

# Phase 1 — Secure and Reproducible Platform Baseline

## Goal

Make the existing system safe and reproducible enough to extend: close account-state gaps, establish versioned schemas/configuration, provide basic admin account control, and make local deployment describe the real architecture.

## Why This Phase Comes Here

Every later service trusts JWT identity and relies on stable database/API conventions. Adding domains on top of unversioned schemas, default secrets, non-container-safe URLs, and login that accepts pending/blocked users would multiply rework.

## Related Microservices

- `api-gateway` [EXISTING]
- `identity-service` [EXISTING]
- `nutrition-service` [EXISTING]
- `blog-service` [EXISTING]

## Existing Functionality to Preserve

- All current URLs and response envelopes.
- BCrypt password behavior, current access-token claims, public author batch lookup.
- Resource-service JWT validation and structured 401/403 responses.
- Separate service databases, current data and all current tests.
- Existing aggregated Swagger UI and local CORS behavior.

## Implementation Tasks

- [ ] Record API/error/JWT conventions as explicit cross-service contracts.
- [ ] Decide and document `USER` versus `MEMBER` terminology without breaking existing JWT consumers.
- [ ] Reject login/token refresh for pending, inactive or blocked users.
- [ ] Implement email verification and password-reset OTP lifecycle with expiry, one-time use and hashed codes/tokens.
- [ ] Implement hashed refresh-token rotation, logout/revocation and password-change revocation.
- [ ] Add admin-only account list/detail/status-transition APIs and audit entries.
- [ ] Define how already-issued access tokens are handled after suspension; use short access TTL plus status/version validation where necessary.
- [ ] Introduce Flyway/Liquibase migrations for each existing schema by baselining current tables safely.
- [ ] Move database credentials, JWT secret, storage credentials and upstream URLs to required environment configuration outside local-only profiles.
- [ ] Add Dockerfiles for current services and Compose service definitions without removing MySQL/MinIO volumes.
- [ ] Add deterministic MinIO bucket/policy initialization for existing avatar and thumbnail buckets.
- [ ] Replace Gateway `localhost` upstreams with configurable values that work both locally and in Compose.
- [ ] Add health/readiness endpoints and correlation IDs with secret-safe structured logs.
- [ ] Add Gateway route/CORS/Swagger tests and database integration coverage for identity and nutrition.

## APIs Affected

Preserve all current endpoints. Modify `POST /api/auth/login` to enforce status/verification. Add expected endpoints under existing conventions:

- `POST /api/auth/verify-email`
- `POST /api/auth/resend-verification`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/users` and `GET /api/users/{id}` (admin)
- `PATCH /api/users/{id}/status` (admin)

## Database Work

- Reuse `users`; add versioned OTP, refresh-session and admin-audit tables.
- Add indexes for OTP expiry, refresh token hash/user, and user status/search.
- Baseline current identity, nutrition and blog schemas; stop relying on `ddl-auto=update` outside disposable development.
- Keep numeric IDs for compatibility unless a separately approved migration proves UUID conversion worth the system-wide cost.

## Inter-Service Dependencies

```text
identity-service --issues identity contract--> all protected services
api-gateway      --routes only--------------> existing services
```

No service receives direct access to the identity database.

## Testing Requirements

- Unit tests for OTP expiry, refresh rotation, status transitions and revocation.
- Repository/integration tests for migrations and token uniqueness.
- API/security tests for role gates and pending/blocked users.
- Gateway route, CORS and aggregated Swagger tests.
- Docker validation from an empty volume and from a baselined current database.
- Manual Swagger validation through port 8080.

## Acceptance Criteria

- [ ] Existing APIs remain backward compatible except the intentional rejection of ineligible accounts.
- [ ] All four projects compile and all existing/new tests pass.
- [ ] A clean Compose start provisions databases, buckets and all current services without manual steps.
- [ ] No production profile has a committed usable secret/password.
- [ ] Migrations reproduce all existing schemas and preserve existing data.
- [ ] Admin account actions are authorized and audited.

## Out of Scope

Recipes, videos, AI providers, chatbot, meal plans, restaurants, social login, and any redesign of working blog behavior.

# Phase 2 — Canonical Ingredient and Recipe Domain

## Goal

Create the authoritative food catalog and usable recipe domain on which pantry, allergies, search, recommendations and meal plans can depend.

## Why This Phase Comes Here

The DOC calls recipes a core function. Meal plans, ingredient recognition, seasonality, restaurant dish matching and cross-content search cannot safely use AI-generated names or duplicated ingredient tables as their source of truth.

## Related Microservices

- `recipe-service` [NEW]
- `blog-service` [EXISTING]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Blog-service category CRUD/tree and category IDs.
- Existing identity JWT claim conventions and API response envelope.
- Existing S3-compatible storage validation patterns.

## Implementation Tasks

- [ ] Define recipe-service REST/OpenAPI/error conventions consistent with existing services.
- [ ] Implement ingredient catalog CRUD with nutrient values, allergen marker, vegan validation and image metadata.
- [ ] Implement recipe aggregate CRUD with author, category ID, description, servings, time, difficulty, calculated nutrition, status and image.
- [ ] Implement ordered recipe steps with unique `(recipe_id, step_no)`.
- [ ] Implement recipe ingredients with quantity, unit, optional flag and note.
- [ ] Calculate recipe nutrition from canonical ingredient values and quantities; define behavior for unknown units.
- [ ] Implement public recipe list/detail/search/category filtering and author-owned draft/list APIs.
- [ ] Implement submit/publish/reject state model compatible with later moderation.
- [ ] Add admin ingredient and recipe management APIs.
- [ ] Add a blog-service internal/public category-existence and usage contract; do not share its category table.
- [ ] Prevent category deletion when recipe-service reports active use, with timeout/failure behavior defined.
- [ ] Add recipe media storage configuration and safe content validation.
- [ ] Add Gateway API/docs routes and Swagger aggregation.

## APIs Affected

Preserve `/api/categories/**`. Add:

- `GET|POST /api/ingredients`, `GET|PUT|DELETE /api/ingredients/{id}`
- `GET|POST /api/recipes`, `GET|PUT|DELETE /api/recipes/{id}`
- `GET /api/recipes/me`
- `POST /api/recipes/{id}/submit`
- `POST /api/recipes/{id}/image`
- `GET /api/recipes/{id}/related`
- A bounded category usage/validation endpoint for service-to-service use

## Database Work

- New recipe-owned tables: `ingredients`, `recipes`, `recipe_ingredients`, `recipe_steps`; reserve versioned seasonality fields/table but populate them in Phase 10.
- Add search/status/category/author indexes and uniqueness on ingredient normalized name and recipe step number.
- `category_id` and `author_id` are external scalar IDs, not foreign keys.
- Use migrations from the first commit; no Hibernate-managed production evolution.

## Inter-Service Dependencies

```text
recipe-service
   +--> blog-service category validation/usage API
   +--> object storage

api-gateway --> recipe-service
```

The recipe service owns food data even when other services display a cached name or nutrition snapshot.

## Testing Requirements

- Unit tests for nutrition calculation, status transitions, ordering and authorization.
- Repository tests for aggregate constraints, indexes and search queries.
- API tests for public/member/admin behavior and upload validation.
- Contract tests against category validation/usage responses, including timeout/unavailable cases.
- Migration, Swagger and Docker validation.

## Acceptance Criteria

- [ ] A member can create, edit, submit and view a multi-step recipe with canonical ingredients.
- [ ] Guests can search/view only published recipes.
- [ ] Ingredient and recipe IDs are stable and usable through explicit APIs.
- [ ] Invalid category/ingredient IDs cannot be persisted.
- [ ] Category deletion cannot silently orphan recipes.
- [ ] All APIs work through the Gateway and appear in aggregated Swagger.

## Out of Scope

User pantry/allergy migration, meal generation, AI recommendations, seasonality ranking, photo recognition and restaurant matching.

# Phase 3 — Complete Community Content with Video and Admin Operations

## Goal

Finish the required non-AI community surface by adding videos to the existing content boundary and completing practical admin content management.

## Why This Phase Comes Here

The blog/category/comment/vote foundation already works, and recipe/category contracts are now stable. Completing video creates the content corpus required by discovery, recommendations and later summarization.

## Related Microservices

- `blog-service` [EXISTING]
- `recipe-service` [NEW]
- `identity-service` [EXISTING]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Every existing blog/category/comment/vote endpoint and business rule.
- `TargetType.VIDEO` schema compatibility.
- Owner/admin deletion distinction, comment tombstones, vote atomicity and public endpoint matching.

## Implementation Tasks

- [ ] Add `Video` entity/service/repository/controller inside blog-service, not a new service.
- [ ] Support approved provider URLs and/or controlled object upload with provider, duration and thumbnail metadata.
- [ ] Implement member draft/edit/submit/delete and public list/search/detail/view-count APIs.
- [ ] Implement optional scalar `recipeId` validation through recipe-service without a DB foreign key.
- [ ] Enable existing comments for `VIDEO` after verifying target existence and publish status.
- [ ] Reuse vote storage and score algorithm for video vote endpoints.
- [ ] Add member-owned video/comment listings needed for “manage own content.”
- [ ] Add admin list/filter/detail, publish/reject/takedown/restore-as-allowed APIs for blogs, videos and comments.
- [ ] Add admin content actions to the audit contract from Phase 1.
- [ ] Extend category usage checks to videos and preserve recipe usage checks.
- [ ] Add Gateway `/api/videos/**` and docs coverage.

## APIs Affected

Preserve all current blog/category/comment APIs. Modify generic comments so `targetType=VIDEO` is accepted only for published videos. Add:

- `GET|POST /api/videos`, `GET|PUT|DELETE /api/videos/{id}`
- `GET /api/videos/me`, `POST /api/videos/{id}/submit`
- `POST /api/videos/{id}/media` or a provider-link validation endpoint
- `POST|DELETE /api/videos/{id}/vote`, `GET /api/videos/me/votes`
- Admin-filter variants under `/api/blogs`, `/api/videos`, and `/api/comments` using explicit admin authorization

## Database Work

- Add blog-owned `videos`; reuse `categories`, `comments`, and `content_votes`.
- Add status/published/category/author/search indexes.
- Store optional external `recipe_id` as a scalar only.
- Add any enum expansion through a migration, never by assuming `ddl-auto` updates MySQL enums.

## Inter-Service Dependencies

```text
blog-service
   +--> recipe-service (optional recipe validation)
   +--> identity-service (only if admin/member detail cannot be client-composed)
   +--> object/video provider
```

Video comment/vote validation stays internal to blog-service.

## Testing Requirements

- Unit/controller/security tests mirroring mature blog coverage.
- Real-MySQL integration tests for video search, lazy relations, views and vote concurrency.
- Contract tests for recipe validation.
- Media/provider validation and malicious-file tests.
- Manual Swagger and full Docker validation.

## Acceptance Criteria

- [ ] Guests can search and view published blogs, videos and recipes.
- [ ] Members can manage their own blogs, videos and comments.
- [ ] Members can comment/vote on other users’ published blogs and videos.
- [ ] Admins can manage all community content with audited actions.
- [ ] Existing blog behavior and tests remain intact.

## Out of Scope

Real AI moderation, AI related-content ranking, video speech-to-text/summarization and meal planning.

# Phase 4 — Complete Personal Nutrition Inputs

## Goal

Provide a coherent, validated personalization context: health goal, activity/TDEE, region, canonical allergies and ingredients currently available.

## Why This Phase Comes Here

Recipe and ingredient IDs must exist before user allergy/pantry associations can be correct. These inputs must be stable before an AI meal planner can generate or replace meals.

## Related Microservices

- `nutrition-service` [EXISTING]
- `recipe-service` [NEW]
- `identity-service` [EXISTING]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Existing health-record URLs, BMI formula/history behavior and ownership filtering.
- Existing `/nutrition/allergens` and `/nutrition/me/allergies` behavior during a documented compatibility window.
- Identity profile and JWT user ID ownership.

## Implementation Tasks

- [ ] Decide one owner for each field: identity owns identity/profile presentation; nutrition owns activity, health goal, region and meal-planning measurements.
- [ ] Add nutrition preference/profile APIs for activity level, goal, region and target constraints.
- [ ] Add TDEE calculation with documented formula, inputs, rounding and version.
- [ ] Store goal/TDEE snapshots on health records or a companion profile while preserving old response fields.
- [ ] Implement user pantry associations to canonical ingredient IDs; define quantity/unit only if required by meal generation.
- [ ] Migrate allergy selection toward canonical recipe ingredient IDs without breaking current allergen clients.
- [ ] Define mapping or retirement plan for the seeded `allergens` table; do not silently duplicate canonical ingredients.
- [ ] Validate ingredient IDs in bounded batches through recipe-service and cache only reference data, not ownership.
- [ ] Add internal personalization-context API returning only data necessary for meal planning/chat grounding.
- [ ] Add consent/privacy rules for health data and logs.

## APIs Affected

Preserve current nutrition APIs. Extend responses additively and add:

- `GET|PUT /api/nutrition/me/preferences`
- `GET /api/nutrition/me/summary` (latest BMI/TDEE/goal)
- `GET|PUT /api/nutrition/me/pantry`
- Versioned allergy payload accepting canonical `ingredientIds`, with compatibility for current `allergenIds`
- An internal authenticated personalization-context endpoint

## Database Work

- Reuse `health_records`; add versioned columns/tables for activity, goal, region, TDEE and formula version.
- Add `user_ingredients`/pantry table owned by nutrition.
- Change allergy associations through explicit migrations and backfill/mapping; store external ingredient IDs without FKs.
- Add unique `(user_id, ingredient_id)` and user/history indexes.

## Inter-Service Dependencies

```text
nutrition-service --> recipe-service (batch ingredient validation/details)
nutrition-service <-- identity JWT userId
```

Calls need timeouts and bounded batches; a recipe outage must not corrupt existing user selections.

## Testing Requirements

- Unit/property tests for BMI/TDEE formulas and boundary values.
- Repository tests for uniqueness and migration/backfill.
- Contract tests for ingredient validation and partial/unavailable responses.
- API/security tests proving one user cannot read another’s health/pantry data.
- Docker/Swagger validation and privacy-focused log review.

## Acceptance Criteria

- [ ] A member can maintain all inputs required by the DOC’s meal-planning flow.
- [ ] BMI/TDEE/goal are deterministic, documented and returned through the Gateway.
- [ ] Every allergy/pantry ingredient ID resolves to recipe-service.
- [ ] Existing health and allergy consumers have a documented compatible transition.
- [ ] No cross-service database FK is introduced.

## Out of Scope

AI generation, meal-plan persistence, wearable synchronization and photo recognition.

# Phase 5 — AI Runtime and Nutrition Chatbot

## Goal

Create one controlled AI boundary and deliver the required member chatbot plus limited guest trial.

## Why This Phase Comes Here

The identity/security baseline and reliable nutrition/ingredient APIs provide safe grounding. Building this reusable runtime before meal planning, moderation and summarization avoids provider logic and telemetry being duplicated in domain services.

## Related Microservices

- `ai-service` [NEW]
- `nutrition-service` [EXISTING]
- `recipe-service` [NEW]
- `identity-service` [EXISTING]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Identity access tokens and public/member distinction.
- Nutrition ownership/privacy rules.
- Canonical recipe/ingredient IDs and data.

## Implementation Tasks

- [ ] Create a provider-neutral AI client interface and one configured provider implementation.
- [ ] Define structured request/response schemas, prompt versions and output validation.
- [ ] Add strict connect/read timeouts, bounded retries, circuit breaking, quotas and provider error mapping.
- [ ] Persist member conversations/messages with pagination and deletion rules.
- [ ] Implement guest sessions with unguessable keys, hashed IP/device abuse signals, atomic limited usage and expiry.
- [ ] Ground nutrition answers in validated health summary and canonical ingredient/recipe facts when the user authorizes it.
- [ ] Add safety rules and clear non-medical-advice handling; do not diagnose disease.
- [ ] Record latency/token/status telemetry without raw secrets or unnecessary health/chat content.
- [ ] Add rate limits for both authenticated and guest APIs.
- [ ] Add Gateway API/docs routes.

## APIs Affected

Add:

- `POST|GET /api/ai/chat/conversations`
- `GET|DELETE /api/ai/chat/conversations/{id}`
- `POST /api/ai/chat/conversations/{id}/messages`
- `POST /api/ai/chat/guest/sessions`
- `POST /api/ai/chat/guest/sessions/{sessionKey}/messages`
- `GET /api/ai/chat/guest/sessions/{sessionKey}/usage`

## Database Work

- New AI-owned `chat_conversations`, `chat_messages`, `guest_ai_usage` and basic `ai_request_logs`.
- Use nullable scalar `user_id` or guest session ownership, never an identity FK.
- Index conversation owner/time, message conversation/time, session hash and quota timestamps.
- Define retention and deletion/anonymization migrations.

## Inter-Service Dependencies

```text
ai-service
   +--> nutrition-service (authorized summary only)
   +--> recipe-service (facts and ID validation)
   +--> external AI provider
```

Guest calls receive no personal context.

## Testing Requirements

- Unit tests for quota atomics, ownership, prompt construction and response parsing.
- Provider contract tests using deterministic fakes; no live provider in normal CI.
- API/security/rate-limit tests for guest/member/admin separation.
- Failure tests for timeout, malformed JSON, hallucinated IDs and provider quota errors.
- Migration, Docker, Gateway and Swagger validation.

## Acceptance Criteria

- [ ] Members can hold persistent multi-message nutrition conversations.
- [ ] Guests receive only the configured limited number of calls and an explicit registration prompt after exhaustion.
- [ ] Provider failures produce stable errors without persisting invalid assistant output.
- [ ] Logs expose latency/status/token metrics without leaking credentials or private context.
- [ ] Chat works through the Gateway and is documented.

## Out of Scope

Meal-plan generation, moderation decisions, video summaries, photo recognition and wearable data.

# Phase 6 — Weekly Meal Planning and Cross-Content Discovery

## Goal

Deliver the central personalized weekly menu flow and complete search/recommendation across recipes, blogs and videos.

## Why This Phase Comes Here

This phase depends on stable recipes/ingredients (Phase 2), videos/content (Phase 3), complete health/allergy/pantry context (Phase 4), and a validated AI runtime (Phase 5).

## Related Microservices

- `nutrition-service` [EXISTING]
- `recipe-service` [NEW]
- `blog-service` [EXISTING]
- `ai-service` [NEW]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Existing domain search endpoints and public result rules.
- Nutrition data ownership and recipe/blog/video canonical IDs.
- AI timeout/validation/telemetry policies.

## Implementation Tasks

- [ ] Define a seven-day meal-plan aggregate and generation state (`DRAFT`, `GENERATING`, `READY`, `FAILED`, `SAVED` or equivalent).
- [ ] Snapshot BMI, TDEE, goal, allergies, pantry and region/version at generation time.
- [ ] Query eligible published recipes and hard-filter allergens before AI ranking.
- [ ] Ask AI for structured meal slots using only supplied candidate IDs.
- [ ] Validate every returned recipe ID, calories, duplication rule and daily target before persistence.
- [ ] Persist days/items transactionally after validation; retain generated dish text only as a snapshot/fallback.
- [ ] Implement replace-one-item with the same hard constraints and an audit of replacements.
- [ ] Implement list/detail/save/delete/regenerate behavior with idempotency for generation requests.
- [ ] Add cross-domain search orchestration in ai-service (or a non-AI module within it) using explicit recipe/blog/video APIs.
- [ ] Add deterministic related-content ranking first, with optional AI reranking only after validation.
- [ ] Add async job/polling behavior if generation cannot meet normal HTTP latency.

## APIs Affected

Preserve domain-specific searches. Add:

- `POST /api/nutrition/me/meal-plans/generations`
- `GET /api/nutrition/me/meal-plans/generations/{jobId}` if asynchronous
- `GET /api/nutrition/me/meal-plans`
- `GET|DELETE /api/nutrition/me/meal-plans/{id}`
- `POST /api/nutrition/me/meal-plans/{id}/save`
- `POST /api/nutrition/me/meal-plans/{id}/items/{itemId}/replace`
- `GET /api/search?q=...&types=RECIPE,BLOG,VIDEO`
- `GET /api/recommendations/content?...`

## Database Work

- Nutrition-owned `meal_plans`, `meal_plan_days`, `meal_plan_items`, plus generation/replacement audit fields.
- Store external recipe IDs and immutable display/nutrition snapshots without FKs.
- Add unique plan/day and day/meal-slot constraints plus owner/week indexes.
- AI service owns orchestration logs, not meal-plan rows.

## Inter-Service Dependencies

```text
nutrition-service
   +--> recipe-service (eligible recipes and final validation)
   +--> ai-service (structured plan/replacement generation)

ai-service discovery
   +--> recipe-service (recipes)
   +--> blog-service   (blogs/videos)
```

Hard dietary rules are enforced by nutrition/recipe code, not trusted to prompts.

## Testing Requirements

- Unit tests for calorie tolerances, allergen exclusion, snapshots and replacement rules.
- Service/contract tests across nutrition, recipe and AI fakes.
- Tests for invalid/hallucinated IDs, empty candidate sets, timeouts and duplicate generation requests.
- Repository tests for the complete seven-day aggregate and transaction rollback.
- Search pagination/deduplication/ranking tests.
- End-to-end Docker test through Gateway with a deterministic fake AI provider.

## Acceptance Criteria

- [ ] A member with complete inputs can generate, review, replace and save a seven-day plan.
- [ ] No saved item violates declared allergies or references a nonexistent/unpublished recipe.
- [ ] Historical plans retain understandable snapshots if recipes later change.
- [ ] Public search returns typed recipe/blog/video results and related suggestions.
- [ ] Failures are recoverable and do not leave partially ready plans.

## Out of Scope

Seasonal optimization beyond stored region snapshot, restaurants, video summarization, photo recognition and wearables.

# Phase 7 — Nearby Vegan Restaurant and Shop Discovery

## Goal

Provide nearby vegan place search, details and food-related place suggestions using a controlled external place provider.

## Why This Phase Comes Here

The feature is marked must-have, but its dish relevance benefits from the stable recipe/ingredient and recommendation contracts created earlier. It is isolated after the core food experience to contain provider quota and geolocation complexity.

## Related Microservices

- `location-service` [NEW]
- `recipe-service` [NEW]
- `ai-service` [NEW]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Canonical recipe/ingredient IDs.
- AI validation/telemetry conventions and Gateway routing pattern.

## Implementation Tasks

- [ ] Select one maps/place provider and document license, attribution, caching and quota rules.
- [ ] Implement nearby search with latitude, longitude, radius and vegan/category constraints.
- [ ] Implement place detail lookup and normalize provider response fields.
- [ ] Cache only provider-permitted fields with expiry and external place ID uniqueness.
- [ ] Implement food/dish keyword relevance using canonical recipe/ingredient context; use deterministic matching before optional AI reranking.
- [ ] Validate coordinates/radius, round or avoid persistent precise user location, and redact it from logs.
- [ ] Add rate limiting, timeout/retry/circuit breaker and stale-cache behavior.
- [ ] Add Gateway API/docs routes and provider health metrics.

## APIs Affected

Add:

- `GET /api/places/vegan?lat=...&lng=...&radius=...&q=...`
- `GET /api/places/{externalPlaceId}`
- `GET /api/places/recommendations?lat=...&lng=...&dish=...`

## Database Work

- Location-owned `restaurants`/`places` cache and optional `restaurant_dishes` observations.
- Store external recipe/ingredient IDs as nullable scalars without FKs.
- Add external ID uniqueness, cache expiry and geospatial/latitude-longitude indexes appropriate to MySQL.
- Do not persist a user location history by default.

## Inter-Service Dependencies

```text
location-service
   +--> external place provider
   +--> recipe-service (dish/ingredient normalization)
   +--> ai-service (optional validated reranking)
```

## Testing Requirements

- Provider adapter contract tests with recorded/synthetic fixtures permitted by provider terms.
- Coordinate/radius/privacy and cache-expiry tests.
- Timeout, quota, invalid payload and stale-cache tests.
- API/Gateway/Swagger tests and a manual mobile-location scenario.
- Docker validation without requiring a live provider in CI.

## Acceptance Criteria

- [ ] Members can find nearby vegan places and inspect normalized details.
- [ ] A dish query can produce relevant place suggestions without inventing provider IDs.
- [ ] Provider outages and quota exhaustion degrade predictably.
- [ ] Precise user locations and provider credentials do not appear in logs or persisted history.

## Out of Scope

Reservations, payments, delivery, user place reviews, route navigation and ownership of restaurant menu truth.

# Phase 8 — Trust, Moderation, and AI Operations

## Goal

Replace auto-approval with auditable AI-assisted moderation and give admins safe operational visibility and intervention controls.

## Why This Phase Comes Here

The content corpus and AI runtime must exist first. This phase changes publication behavior and therefore follows the MVP/demo boundary, where current manual admin takedown remains available but auto-approval is explicitly non-production.

## Related Microservices

- `ai-service` [NEW]
- `blog-service` [EXISTING]
- `recipe-service` [NEW]
- `identity-service` [EXISTING]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- `ContentModerationService` interface and existing content states.
- Owner/admin authorization, terminal takedowns, audit groundwork and AI telemetry.
- Existing APIs should not be rewritten; publication may become pending when confidence requires review.

## Implementation Tasks

- [ ] Implement ai-service moderation API with versioned labels, score, reason and provider/model metadata.
- [ ] Replace blog-service auto-approval bean with a resilient client adapter and fail-closed/pending policy.
- [ ] Extend moderation to videos, comments and recipes using domain callbacks.
- [ ] Persist moderation cases for flagged/uncertain content using external target type/ID.
- [ ] Add admin queue, case detail, approve/reject/takedown and appeal/re-review behavior.
- [ ] Make admin decisions update content through explicit owning-service APIs, not database writes.
- [ ] Persist complete admin audit records and protect them from ordinary edits.
- [ ] Add AI service/model configuration, request metrics, error/latency/quota alerts and safe enable/disable controls.
- [ ] Redact prompts/content in telemetry by default; keep evidence only under an explicit retention policy.
- [ ] Define fallback behavior for moderation provider outages and delayed callbacks.

## APIs Affected

Preserve content creation APIs. Add internal moderation contracts and admin APIs such as:

- `POST /internal/ai/moderation/evaluations`
- `GET /api/admin/moderation/cases`
- `GET /api/admin/moderation/cases/{id}`
- `POST /api/admin/moderation/cases/{id}/decision`
- `GET /api/admin/ai/services`, `PATCH /api/admin/ai/services/{id}`
- `GET /api/admin/ai/metrics`, `GET /api/admin/ai/alerts`

## Database Work

- AI-owned `moderation_cases`, `ai_services`, expanded `ai_request_logs`, `ai_alerts`.
- Store target service/type/ID and reviewer user ID as scalars; no cross-service FKs.
- Add queue status/time, service/time/status and unresolved-alert indexes.
- Domain services retain authoritative content status.

## Inter-Service Dependencies

```text
blog-service / recipe-service --> ai-service moderation
admin decision in ai-service  --> owning service status API
identity-service JWT          --> admin authorization
```

Use idempotent decision/callback contracts to survive retries.

## Testing Requirements

- Moderation decision matrix and confidence-threshold unit tests.
- Contract tests for every supported target type and idempotent callbacks.
- Security tests proving only admins can view evidence or decide cases.
- Outage/timeout/retry tests and fail-closed publication tests.
- Audit immutability and telemetry redaction tests.
- End-to-end flagged-content workflow through Gateway.

## Acceptance Criteria

- [ ] The auto-approve placeholder is not active in production configuration.
- [ ] Flagged/uncertain content is not publicly exposed before the configured decision.
- [ ] Admin decisions reliably update the authoritative content service and are audited.
- [ ] Admins can observe error/latency/quota indicators without seeing secrets or unnecessary personal data.

## Out of Scope

Training custom models, fully autonomous permanent deletion, video transcription and computer-vision ingredient recognition.

# Phase 9 — Video-to-Recipe Summarization

## Goal

Convert supported cooking videos into reviewable, persisted step-by-step recipe summaries through an asynchronous pipeline.

## Why This Phase Comes Here

It depends on videos, canonical recipe/step structures, the AI runtime, operational monitoring and moderation/safety controls. Speech-to-text latency and provider failures make it inappropriate to hide inside synchronous video CRUD.

## Related Microservices

- `ai-service` [NEW]
- `blog-service` [EXISTING]
- `recipe-service` [NEW]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Video metadata/storage and access rules.
- Recipe step model and AI telemetry/provider policy.

## Implementation Tasks

- [ ] Define supported video sources, size/duration/language limits and copyright/consent rules.
- [ ] Create idempotent asynchronous summary jobs and status transitions.
- [ ] Obtain audio through an approved provider/storage path; do not bypass platform terms.
- [ ] Run STT and retain transcript only as long as required.
- [ ] Produce a structured summary with ordered steps and optional ingredient candidates.
- [ ] Validate referenced ingredient/recipe IDs against recipe-service and drop/flag hallucinated IDs.
- [ ] Allow author/admin review and correction before optionally creating/linking a recipe draft.
- [ ] Add retry/cancel/expired-input behavior and cost/length limits.

## APIs Affected

Add:

- `POST /api/videos/{id}/ai-summary`
- `GET /api/videos/{id}/ai-summary`
- `GET /api/ai/summary-jobs/{jobId}`
- `POST /api/videos/{id}/ai-summary/approve` (authorized author/admin)
- Optional `POST /api/videos/{id}/ai-summary/create-recipe-draft`

## Database Work

- AI-owned `video_ai_summaries`/jobs with external video ID, status, model/prompt version, summary and lifecycle timestamps.
- Recipe draft remains owned by recipe-service; video link remains owned by blog-service.
- Index by video/status/time and enforce one active idempotency key per request.

## Inter-Service Dependencies

```text
ai-service --> blog-service   (authorized video metadata/source)
ai-service --> STT + LLM providers
ai-service --> recipe-service (ID validation / optional draft command)
```

## Testing Requirements

- Job state/idempotency tests and provider fake contracts.
- Transcript/summary schema and hallucinated-ID validation tests.
- Long video, unsupported source, timeout, retry and cancellation tests.
- Authorization tests for private/draft videos.
- End-to-end job polling and optional recipe-draft creation.

## Acceptance Criteria

- [ ] A supported published/authorized cooking video can produce a concise ordered summary asynchronously.
- [ ] Failures are visible and retryable without duplicate jobs or recipes.
- [ ] No unvalidated AI-generated ID is persisted as a domain reference.
- [ ] Users can review AI output before it becomes an authoritative recipe.

## Out of Scope

General video editing, arbitrary copyrighted downloads, live streaming and ingredient photo recognition.

# Phase 10 — Seasonal/Regional and Ingredient-Photo Intelligence

## Goal

Enhance personalization with seasonality/region data and user-confirmed ingredient recognition/freshness hints.

## Why This Phase Comes Here

Both features require a mature ingredient catalog, real usage data, meal planning, AI validation and monitoring. They improve recommendations but are not needed to prove the must-have core.

## Related Microservices

- `recipe-service` [NEW]
- `nutrition-service` [EXISTING]
- `ai-service` [NEW]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Canonical ingredients, pantry API, region preference, meal-plan validation and AI provider controls.

## Implementation Tasks

- [ ] Add admin-managed ingredient availability by region/month with provenance and notes.
- [ ] Add deterministic seasonal/regional scores to recipe eligibility/ranking.
- [ ] Include seasonality as a soft preference in generation; never override allergies or nutrition constraints.
- [ ] Add secure temporary image upload and a CV provider adapter.
- [ ] Return recognition candidates with confidence and freshness as a non-authoritative hint.
- [ ] Match candidates to canonical ingredients; require user confirmation before pantry changes.
- [ ] Handle unknown/low-confidence items and avoid unsupported food-safety claims.
- [ ] Measure opt-in correction feedback and provider accuracy without retaining images indefinitely.

## APIs Affected

Add:

- Admin CRUD for `/api/ingredients/{id}/seasonality`
- `POST /api/ai/ingredients/recognitions`
- `GET /api/ai/ingredients/recognitions/{jobId}`
- `POST /api/nutrition/me/pantry/confirm-recognition`
- Additive seasonal explanation fields on recommendation/meal-plan responses

## Database Work

- Recipe-owned `ingredient_seasonality` with unique ingredient/region periods and indexes.
- AI-owned recognition jobs/results with short retention.
- Nutrition pantry changes remain nutrition-owned and record confirmation provenance.

## Inter-Service Dependencies

```text
ai-service --> CV provider --> recipe-service ingredient matching
user confirmation ---------> nutrition-service pantry
recipe-service seasonality -> nutrition-service meal ranking
```

## Testing Requirements

- Month/region boundary and deterministic ranking tests.
- CV provider fake, confidence threshold and unknown-item tests.
- Security/file validation and retention cleanup tests.
- Tests proving no pantry mutation occurs before confirmation.
- Regression tests proving allergies outrank seasonal preference.

## Acceptance Criteria

- [ ] Meal suggestions can explain a seasonal/regional preference from maintained data.
- [ ] Ingredient photos return canonical candidates with confidence.
- [ ] Users explicitly confirm candidates before pantry persistence.
- [ ] Freshness output is labeled as uncertain and never presented as a safety guarantee.

## Out of Scope

Medical food-safety certification, automated grocery purchasing, custom CV model training and wearable synchronization.

# Phase 11 — Optional Health and Wearable Integration

## Goal

Optionally synchronize consented health/activity data and compare it with saved meal plans without weakening privacy or the manual flow.

## Why This Phase Comes Here

The DOC explicitly marks this optional. It has high compliance, provider-review and mobile-platform complexity, and only creates value once health history and meal plans are stable.

## Related Microservices

- `nutrition-service` [EXISTING]
- `identity-service` [EXISTING]
- `ai-service` [NEW]
- `api-gateway` [EXISTING]

## Existing Functionality to Preserve

- Manual health entry must remain fully usable.
- Health privacy, meal-plan snapshots and AI validation rules.

## Implementation Tasks

- [ ] Choose supported platform(s) only after feasibility and consent review.
- [ ] Define OAuth/mobile handoff, explicit scopes, consent, revocation and data deletion.
- [ ] Encrypt provider tokens and keep them outside logs and ordinary API responses.
- [ ] Implement idempotent incremental sync with provenance and conflict rules.
- [ ] Separate observed activity/intake from manually entered measurements.
- [ ] Compare actual data with saved plans and generate bounded, explainable adjustments.
- [ ] Add sync status, retry, disconnect and data-deletion APIs.
- [ ] Complete privacy/security review and provider compliance checklist.

## APIs Affected

Provider-specific endpoints should sit under:

- `POST /api/nutrition/me/health-connections/{provider}`
- `GET|DELETE /api/nutrition/me/health-connections/{provider}`
- `POST /api/nutrition/me/health-connections/{provider}/sync`
- `GET /api/nutrition/me/health-connections/{provider}/status`

## Database Work

- Nutrition-owned health connections, encrypted token references, sync cursors, consent history and imported records with provider provenance.
- Never place wearable credentials in identity user rows.
- Add unique user/provider, sync-status and observed-time indexes plus retention/deletion migrations.

## Inter-Service Dependencies

```text
nutrition-service --> approved health provider
nutrition-service --> ai-service (optional bounded adjustment explanation)
identity JWT      --> consented user ownership
```

## Testing Requirements

- Adapter contract tests with sandbox/fakes.
- Token encryption, scope, consent, revocation and deletion tests.
- Duplicate/out-of-order sync and conflict tests.
- Provider outage/backoff and partial-sync recovery tests.
- Security/privacy review and manual device integration validation.

## Acceptance Criteria

- [ ] Users can connect, view status, sync, disconnect and delete imported data.
- [ ] Manual health entry continues to work without a provider.
- [ ] Sync is idempotent and records provenance.
- [ ] Any recommendation adjustment remains validated and explainable.

## Out of Scope

Clinical diagnosis, emergency alerts, unsupported device scraping and making a wearable mandatory.

# Requirement-to-Phase Matrix

| Requirement | Current Status | Owning Service | Planned Phase | Dependencies |
|---|---|---|---|---|
| Register/login | PARTIALLY IMPLEMENTED | identity-service | Phase 1 | None |
| Email verification/password reset/refresh | NOT IMPLEMENTED | identity-service | Phase 1 | Existing auth |
| Google/social account | OPTIONAL / NOT IMPLEMENTED | identity-service | Post-MVP backlog after Phase 1 | Provider decision |
| Role/status authorization | PARTIALLY IMPLEMENTED | identity-service + resource services | Phase 1 | Auth contract |
| User profile/avatar | PARTIALLY IMPLEMENTED | identity-service | Phase 1 (security), Phase 4 (nutrition fields) | Field ownership decision |
| Admin member management | NOT IMPLEMENTED | identity-service | Phase 1 | Roles/audit |
| BMI/health history | PARTIALLY IMPLEMENTED | nutrition-service | Phase 4 | Phase 1 migrations |
| TDEE/health goals/activity | NOT IMPLEMENTED | nutrition-service | Phase 4 | Profile field ownership |
| Allergies | PARTIALLY IMPLEMENTED | nutrition-service | Phase 4 | Phase 2 ingredients |
| User-owned ingredients/pantry | NOT IMPLEMENTED | nutrition-service | Phase 4 | Phase 2 ingredients |
| Ingredient catalog/nutrients | NOT IMPLEMENTED | recipe-service | Phase 2 | Phase 1 baseline |
| Recipes/steps/recipe ingredients | NOT IMPLEMENTED | recipe-service | Phase 2 | Ingredients/categories |
| Category tree/admin CRUD | COMPLETE for current scope | blog-service | Preserve; integrate Phases 2–3 | Explicit usage API |
| Blog authoring/search/view | COMPLETE for current scope | blog-service | Preserve; admin completion Phase 3 | Phase 1 audit |
| Videos upload/search/view/manage | NOT IMPLEMENTED | blog-service | Phase 3 | Categories/media |
| Comments/replies | PARTIALLY IMPLEMENTED | blog-service | Phase 3 for video; Phase 8 moderation | Videos, AI moderation |
| Votes | PARTIALLY IMPLEMENTED | blog-service | Phase 3 for video | Videos |
| Guest public blog/video viewing | PARTIALLY IMPLEMENTED | blog-service | Phase 3 | Videos |
| Cross recipe/blog/video search | PARTIALLY IMPLEMENTED | ai-service orchestration; domains own indexes | Phase 6 | Phases 2–5 |
| Related content recommendations | PARTIALLY IMPLEMENTED | ai-service with domain APIs | Phase 6 | Stable content corpus |
| Personalized weekly meal plan | NOT IMPLEMENTED | nutrition-service | Phase 6 | Phases 2, 4, 5 |
| Replace and save meal item/plan | NOT IMPLEMENTED | nutrition-service | Phase 6 | Generated plan validation |
| AI nutrition chatbot | NOT IMPLEMENTED | ai-service | Phase 5 | Phases 1, 2, 4 |
| Guest chatbot limited trial | NOT IMPLEMENTED | ai-service | Phase 5 | Guest quota/rate limit |
| Nearby vegan restaurants/shops | NOT IMPLEMENTED | location-service | Phase 7 | Recipe context/provider |
| Food-related restaurant suggestions | NOT IMPLEMENTED | location-service + ai-service optional ranking | Phase 7 | Nearby search, recipe catalog |
| AI content moderation | PLACEHOLDER / ARCHITECTURE REVIEW | ai-service decision; content services enforce state | Phase 8 | Phases 3, 5 |
| Admin content review | PARTIALLY IMPLEMENTED | blog-service/recipe-service + ai-service cases | Phase 3 manual, Phase 8 AI queue | Roles/audit/content |
| AI logs, metrics, alerts/intervention | NOT IMPLEMENTED | ai-service | Phase 8 | Phase 5 telemetry |
| Video recipe summarization | NOT IMPLEMENTED | ai-service | Phase 9 | Phases 2, 3, 5, 8 |
| Seasonal/regional recommendations | NOT IMPLEMENTED | recipe-service data; nutrition ranking | Phase 10 | Recipes, region, meal plans |
| Ingredient recognition/freshness photo | NOT IMPLEMENTED | ai-service; confirmation in nutrition | Phase 10 | Ingredient catalog/pantry |
| Wearable/Health App integration | OPTIONAL | nutrition-service | Phase 11 | Stable health/meal plans, consent |
| Data tables in DOC with cross-service FKs | NEEDS REFACTOR / ARCHITECTURE REVIEW | Respective domain owner | Phases 1–11 as introduced | Must use scalar IDs/APIs, not cross-DB FKs |
| Frontend-only presentation/navigation | Not a backend requirement | Client | No backend phase | Backend only supplies documented APIs |

# MVP Boundary

## Required for MVP / Demo

Phases 1 through 7 form the MVP boundary:

- Phase 1 makes authentication, account eligibility, admin access, schemas and deployment dependable.
- Phase 2 provides the missing core recipe/ingredient domain.
- Phase 3 completes the DOC’s required blogs/videos/comments/votes/admin content surface.
- Phase 4 supplies BMI/TDEE/goals/allergies/pantry inputs.
- Phase 5 delivers member and limited guest chatbot use.
- Phase 6 demonstrates personalized weekly plans, replacement/save and content discovery.
- Phase 7 delivers the explicitly must-have nearby vegan place experience.

For a time-boxed classroom demo, external AI and place providers may use deterministic sandbox adapters, but the API validation, quota, persistence and failure behavior must be real. The current auto-approve moderation must be labeled a demo limitation and cannot be presented as completed AI moderation.

## Post-MVP

- Phase 8: production-grade AI moderation and AI/admin operations.
- Phase 9: video speech-to-text and recipe summarization.
- Phase 10: seasonal/regional optimization and ingredient-photo recognition.
- Optional Google/social login can be scheduled after Phase 1 without blocking the MVP unless the product owner promotes it.

## Optional / Advanced

- Phase 11 wearable/health-app synchronization is explicitly optional in the DOC.
- Freshness estimation and AI reranking are advanced/uncertain outputs and must remain advisory.
- Custom model training, clinical guidance, delivery/reservations and autonomous irreversible moderation are outside the current requirements.

# Architecture Risks and Technical Debt

| Severity | Affected Service(s) | Issue / Evidence | Recommended Phase |
|---|---|---|---|
| HIGH | identity-service | Registration creates `PENDING` and `emailVerified=false`, but login checks only email/password and still issues a token. Blocked/inactive status is also not checked. | Phase 1 |
| HIGH | all persistence services | `spring.jpa.hibernate.ddl-auto=update` is the schema strategy; there are no migrations. MySQL enum changes have already required manual intervention according to repository guidance. | Phase 1 |
| HIGH | all services | Default database, MinIO and JWT credentials are committed as property fallbacks; a known default HS256 key would compromise all services if used beyond local development. | Phase 1 |
| HIGH | blog-service | `AutoApproveContentModerationService` approves every blog/comment, despite the requirement that AI flags content before publication. | Phase 8; explicitly disclose until then |
| HIGH | all services / Compose | Actual Compose starts only MySQL and MinIO. There are no Dockerfiles, service containers, database initialization for identity, or MinIO bucket/policy initializer. | Phase 1 |
| HIGH | future AI features | No provider response validation exists yet. Meal plans, summaries and recognition could persist hallucinated IDs unless owning services validate structured results. | Phase 5 foundation; enforce Phases 6, 9, 10 |
| MEDIUM | identity-service and resource services | JWT config is copied across services and depends on one shared HS256 secret. There is no issuer/audience validation, rotation or immediate revocation. | Phase 1 |
| MEDIUM | api-gateway | All upstream URIs are hardcoded to localhost; they will not work in Compose/deployed networking. | Phase 1 |
| MEDIUM | nutrition-service / future recipe-service | Current allergens are a local catalog, while the DOC models allergies against ingredients. Adding a second ingredient truth would duplicate ownership. | Phases 2 and 4 |
| MEDIUM | blog-service / future recipe-service | Categories are owned by blog-service but required by recipes and videos. Local JPA deletion checks cannot see external usage. | Phase 2 contract, Phase 3 extension |
| MEDIUM | identity-service vs DOC | Code uses `Long`, role `USER`, statuses `PENDING/ACTIVE/INACTIVE/BLOCKED`, and embedded profile fields; DOC sketches UUID, `MEMBER`, `SUSPENDED/DELETED`, and separate profile. Blind conformance would break all existing references. | Phase 1 decision/migrations |
| MEDIUM | all services | `ApiResponse`, exceptions, JWT extraction, storage code and security patterns are copied. They are currently similar but can drift; a shared binary library could also tightly couple releases. | Phase 1: contract tests/templates, not premature shared library |
| MEDIUM | all persistence services | Integration coverage is uneven: blog has real-MySQL behavior tests; identity/nutrition context tests use local MySQL and lack isolated test profiles/containers. | Phase 1 |
| MEDIUM | api-gateway | Only one context-load test; route prefixing, public paths, uploads, CORS and Swagger aggregation can regress unnoticed. | Phase 1 |
| MEDIUM | identity/blog storage | S3 objects are served from configured public URLs; Compose does not provision buckets/policies, and privacy/access policy is not explicit for future media. | Phase 1, revisit Phase 3 |
| MEDIUM | synchronous future service calls | No HTTP client timeout/retry/circuit-breaker/contract infrastructure exists because services currently do not call each other. Recipe/category/AI dependencies could cascade failures. | Introduce Phase 2; standardize Phase 5 |
| MEDIUM | all services | Error envelopes share a shape but implementations/error ranges are duplicated and not verified by cross-service contract tests. | Phase 1 |
| LOW | api-gateway | CORS allows every `http://localhost:*`; correct for local work but needs explicit deployed origins. | Phase 1 |
| LOW | identity-service | `/auth/test` is listed as public although no matching controller exists, indicating configuration drift. | Phase 1 |
| LOW | repository | Generated `target/` artifacts are present in service trees and can obscure source/config inspection if not consistently ignored/cleaned. | Phase 1 housekeeping |

# Recommended Execution Order

```text
Phase 1: Secure/reproducible baseline
   |
   +--> Phase 2: Recipe + ingredient domain
   |       |
   |       +--> Phase 4: Personal nutrition inputs
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
Phase 6: Meal plans/search   Phase 8: Moderation/AI ops
        |                       |
        +--> Phase 7: Places    +--> Phase 9: Video summary
        |
        +--> Phase 10: Seasonal/vision
                 |
                 +--> Phase 11: Optional wearables
```

Phase 3 and Phase 4 can proceed in parallel after Phase 2 because one extends community content while the other builds user nutrition inputs. Phase 5 can begin after Phase 1 once its contracts are defined, but personalized grounding cannot be accepted until Phases 2 and 4 are available. Phase 6 is the convergence point for recipes, content, nutrition and AI. Phase 7 can be developed alongside Phase 8 after Phase 6 contracts stabilize. Phases 9 and 10 are independent advanced tracks after their stated dependencies; Phase 11 remains last because it is optional and compliance-heavy.

# Rules for Codex During Phase Implementation

1. Implement only the requested phase.
2. Inspect the related services before editing.
3. Preserve working functionality.
4. Do not rewrite completed code without a concrete technical reason.
5. Do not implement future-phase functionality early.
6. Maintain backward compatibility where practical.
7. Follow existing package and naming conventions.
8. Do not create duplicate entities without justification.
9. Do not create cross-service database foreign keys.
10. Service-to-service communication must use explicit APIs.
11. Build affected services after meaningful changes.
12. Run tests after meaningful changes.
13. Verify APIs through Swagger or automated tests.
14. Keep API Gateway routes synchronized.
15. Document new environment variables.
16. Never commit secrets, passwords, API keys, or tokens.
17. Validate external API and AI responses before saving them.
18. AI-generated IDs must be validated against actual domain data.
19. Update this roadmap after completing a phase.
20. Stop after completing the requested phase.
