# Nutrition Service - Tài liệu kiến trúc và giải thích mã nguồn

## 1. Vai trò của service

`nutrition-service` quản lý dữ liệu dinh dưỡng/sức khỏe thuộc về từng user:

- Lịch sử chiều cao, cân nặng và BMI.
- Bản ghi sức khỏe mới nhất.
- Danh mục dị ứng dùng chung.
- Danh sách dị ứng của từng user.

Service không lưu entity `User`, không gọi đồng bộ sang identity service và không có foreign key tới database identity. Nó lấy `userId` từ JWT rồi lưu con số đó trong database riêng.

```text
Client -> Gateway :8080 -> Nutrition :8082 -> veggiepal_nutrition
                JWT ----------------------> claim userId
```

## 2. Công nghệ và cấu trúc

Service dùng Java 21, Spring Boot 4.1.1, MVC, JPA/Hibernate, MySQL, Spring Security Resource Server, Jakarta Validation, MapStruct, Lombok và Springdoc.

```text
nutrition-service/src/main
├── java/com/veggiepal/nutrition
│   ├── configuration   JWT, security, OpenAPI
│   ├── controller      HTTP endpoints, CurrentUser
│   ├── dto             request/response contract
│   ├── entity          bảng database
│   ├── enums           nhóm allergen
│   ├── exception       error model/handler
│   ├── mapper          MapStruct mapping
│   ├── repository      Spring Data queries
│   └── service         business logic
└── resources
    ├── application.properties
    └── data.sql
```

Luồng phụ thuộc:

```text
Controller -> Service -> Repository -> MySQL
                  |
                  +-> Mapper -> Response DTO
```

## 3. Khởi động và cấu hình

`NutritionServiceApplication` có `@SpringBootApplication`, khởi động web server tại port `8082` và quét toàn bộ package con.

### Database

```properties
spring.datasource.url=jdbc:mysql://localhost:3307/veggiepal_nutrition?createDatabaseIfNotExist=true
spring.jpa.hibernate.ddl-auto=update
spring.jpa.open-in-view=false
```

- Database được tự tạo nếu chưa có.
- Hibernate cập nhật schema theo entity.
- `open-in-view=false` tránh lazy query ngoài tầng persistence/service.
- SQL được show và format trong log để hỗ trợ phát triển.

Production nên dùng migration Flyway/Liquibase thay `ddl-auto=update`.

### Seed allergen

```properties
spring.jpa.defer-datasource-initialization=true
spring.sql.init.mode=always
spring.sql.init.encoding=UTF-8
```

Hibernate tạo/cập nhật bảng trước, sau đó chạy `data.sql`. File seed dùng `INSERT IGNORE` và `code` unique, vì vậy chạy lại không tạo bản ghi trùng.

Danh mục cố ý chỉ gồm nhóm phù hợp nền tảng thuần chay; không seed sữa, trứng hay hải sản.

### JWT

```properties
jwt.secret=${JWT_SECRET:veggiepal-secret-key-must-be-at-least-32-characters}
```

Secret và thuật toán HS256 phải giống identity service. Nutrition chỉ decode token, không phát token.

## 4. API

Tất cả API business hiện đều cần bearer JWT.

| Method | URL qua gateway | Chức năng |
|---|---|---|
| GET | `/api/nutrition/allergens` | Danh mục allergen |
| GET | `/api/nutrition/me/allergies` | Dị ứng của user hiện tại |
| PUT | `/api/nutrition/me/allergies` | Thay toàn bộ danh sách dị ứng |
| POST | `/api/nutrition/me/health-records` | Tạo bản ghi chiều cao/cân nặng |
| GET | `/api/nutrition/me/health-records` | Lịch sử có phân trang |
| GET | `/api/nutrition/me/health-records/latest` | Bản ghi mới nhất |
| PUT | `/api/nutrition/me/health-records/{id}` | Sửa một bản ghi thuộc user |

Gateway bỏ `/api`, nên service nhận URL bắt đầu bằng `/nutrition`.

## 5. Security và user hiện tại

`SecurityConfig` chỉ public Swagger/OpenAPI; mọi endpoint khác dùng `.authenticated()`.

Service stateless:

```java
session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
```

JWT decoder dùng shared secret và khóa cứng HS256. Claim `role` được ánh xạ thành `ROLE_USER`/`ROLE_ADMIN`, dù hiện controller chưa dùng role authorization.

`CurrentUser.id(jwt)` đọc claim `userId` dưới dạng bất kỳ `Number` rồi chuyển sang `Long`. Thiếu/sai kiểu claim sẽ thành `UNAUTHENTICATED`.

Controller không nhận user ID từ request. Vì vậy user không thể đổi path/body để đọc hoặc sửa dữ liệu của người khác.

`SecurityExceptionHandler` xử lý lỗi trước controller:

- JWT thiếu/sai/hết hạn -> HTTP 401, code 1008.
- Đã xác thực nhưng thiếu quyền -> HTTP 403, code 1009.

## 6. Mô hình database

### `HealthRecord`

Ánh xạ bảng `health_records`:

| Field | Cột | Ý nghĩa |
|---|---|---|
| `id` | `id` | Primary key tự tăng |
| `userId` | `user_id` | ID từ JWT, không FK chéo service |
| `heightCm` | `height_cm DECIMAL(4,1)` | Chiều cao cm |
| `weightKg` | `weight_kg DECIMAL(4,1)` | Cân nặng kg |
| `bmi` | `bmi DECIMAL(5,1)` | BMI do server tính |
| `recordedAt` | `recorded_at` | Thời điểm phép đo, giữ nguyên khi sửa |
| `createdAt` | `created_at` | Thời điểm tạo row |
| `updatedAt` | `updated_at` | Thời điểm update |

Index `(user_id, recorded_at)` phục vụ lịch sử và bản ghi mới nhất của một user.

`@PrePersist` gán `createdAt/updatedAt`; `@PreUpdate` đổi `updatedAt`.

### `Allergen`

Bảng danh mục `allergens` gồm:

- `id` tự tăng.
- `code` unique, ổn định cho seed/integration.
- `name` hiển thị.
- `category` lưu enum dạng string.

`AllergenCategory` có thứ tự khai báo cũng là thứ tự nhóm hiển thị:

```text
GRAIN -> LEGUME -> NUT_SEED -> VEGETABLE
-> FRUIT -> MUSHROOM -> SPICE -> ADDITIVE
```

### `UserAllergy`

Bảng nối `user_allergies` gồm `user_id`, `allergen_id`, `created_at`.

Unique constraint `(user_id, allergen_id)` bảo đảm một user không có cùng allergen hai lần. `allergen_id` là quan hệ `ManyToOne` nội bộ cùng database. `user_id` chỉ là scalar vì user thuộc identity service.

`@ToString.Exclude` và `@EqualsAndHashCode.Exclude` trên quan hệ tránh recursion/lazy loading không chủ ý từ Lombok.

## 7. DTO và validation

### `HealthRecordRequest`

Chiều cao:

- Bắt buộc.
- Từ 50 đến 250 cm.
- Tối đa một chữ số thập phân.

Cân nặng:

- Bắt buộc.
- Từ 20 đến 300 kg.
- Tối đa một chữ số thập phân.

`BigDecimal` được dùng thay `double` để tránh sai số floating point khi validate, lưu DB và tính BMI.

### `UpdateAllergiesRequest`

```java
@NotNull
List<@NotNull Long> allergenIds;
```

- List phải xuất hiện.
- Phần tử không được null.
- List rỗng `[]` hợp lệ và có nghĩa xóa toàn bộ dị ứng.
- ID trùng được service gom lại bằng `HashSet`.

### Response

- `HealthRecordResponse` không trả `userId`, chỉ trả dữ liệu sức khỏe của chính caller.
- `AllergenResponse` trả ID, code, name, category.
- `PageResponse<T>` trả `items`, page, size, totalElements, totalPages.
- `ApiResponse<T>` dùng code thành công mặc định `1000`, bỏ field null khỏi JSON.

## 8. Health record controller và service

### Tạo record

```text
POST /nutrition/me/health-records
 -> validate height/weight
 -> lấy userId từ JWT
 -> tính BMI
 -> recordedAt = now
 -> save
 -> map response
```

BMI:

```java
BigDecimal heightM = heightCm.movePointLeft(2);
weightKg.divide(heightM.multiply(heightM), 1, RoundingMode.HALF_UP);
```

Công thức là `kg / m²`, làm tròn HALF_UP một chữ số. Client không được gửi BMI, tránh dữ liệu không nhất quán.

### Lấy lịch sử

Query chỉ lấy `userId` hiện tại và sort:

```text
recordedAt DESC, id DESC
```

ID là tie-breaker khi hai record cùng timestamp.

Page được clamp:

- `size < 1` -> 1.
- `size > 100` -> 100.
- `page < 0` -> 0.
- Page quá lớn được giới hạn để phép nhân offset không overflow integer.

### Bản ghi mới nhất

Repository method:

```java
findFirstByUserIdOrderByRecordedAtDescIdDesc(userId)
```

Không có record -> HTTP 404/code 2005.

### Sửa record

Service tìm bằng cả ID và user ID:

```java
findByIdAndUserId(recordId, userId)
```

Record không tồn tại và record của người khác đều trả cùng `HEALTH_RECORD_NOT_EXISTED`. Cách này vừa chống sửa chéo user vừa không làm lộ ID của người khác.

Khi update:

- Đổi height/weight.
- Tính lại BMI.
- Giữ nguyên `recordedAt`.
- JPA lifecycle đổi `updatedAt`.

Service hiện không có endpoint xóa health record.

## 9. Allergy controller và service

### Lấy catalog

`AllergenRepository.findAll()` lấy toàn bộ danh mục. Service sort trong Java theo:

1. Thứ tự enum category.
2. Tên theo Vietnamese `Collator`.

Sort trong Java tránh phụ thuộc thứ tự native MySQL enum/collation.

### Lấy dị ứng của tôi

JPQL:

```java
select ua.allergen from UserAllergy ua where ua.userId = :userId
```

Query trả thẳng allergen rồi service sort/map response.

### Replace toàn bộ danh sách

PUT có semantics thay thế, không phải append:

```text
requested IDs
 -> loại ID trùng
 -> tải toàn bộ allergen
 -> nếu thiếu một ID: lỗi, không thay đổi
 -> tải quan hệ hiện tại
 -> removed = current - requested
 -> added = requested - current
 -> delete removed
 -> save added
```

Method có `@Transactional`, nên validation ID và thay đổi quan hệ nằm trong một transaction. Nếu một thao tác lỗi, toàn bộ thay đổi được rollback.

Service chỉ thêm/xóa phần chênh lệch thay vì xóa tất cả rồi insert lại; cách này giảm write và giữ `createdAt` của quan hệ không đổi.

## 10. Repository và mapper

`HealthRecordRepository` cung cấp paging theo user, latest record và lookup theo `(id,userId)`.

`UserAllergyRepository` vừa lấy relation để tính diff, vừa dùng JPQL projection entity allergen.

`AllergenRepository` dùng CRUD/findAll/findAllById có sẵn từ `JpaRepository`.

`HealthRecordMapper` và `AllergenMapper` là MapStruct interface với `componentModel="spring"`. Implementation được sinh lúc compile; các field cùng tên được map tự động.

## 11. Xử lý lỗi

Các code dùng chung giữ nguyên giữa service:

| Code | HTTP | Ý nghĩa |
|---:|---:|---|
| 1001 | 400 | Validation key sai |
| 1008 | 401 | Chưa xác thực |
| 1009 | 403 | Không có quyền |
| 1018 | 400 | JSON/path/query sai |
| 9999 | 500 | Lỗi chưa phân loại |

Code riêng nutrition:

| Code | HTTP | Ý nghĩa |
|---:|---:|---|
| 2001 | 400 | Thiếu chiều cao |
| 2002 | 400 | Chiều cao không hợp lệ |
| 2003 | 400 | Thiếu cân nặng |
| 2004 | 400 | Cân nặng không hợp lệ |
| 2005 | 404 | Health record không tồn tại/không thuộc user |
| 2006 | 400 | Thiếu list allergen |
| 2007 | 400 | Có allergen ID không tồn tại |

`GlobalExceptionHandler` biến validation message như `INVALID_HEIGHT` thành enum `ErrorCode`. Malformed JSON và sai kiểu path/query thành `INVALID_REQUEST`.

`DataIntegrityViolationException` không log message chi tiết vì thông báo DB có thể chứa cặp `userId-allergenId`, làm lộ dữ liệu sức khỏe. Handler chỉ log câu chung và trả 9999.

## 12. Ví dụ API

### Tạo health record

```http
POST /api/nutrition/me/health-records
Authorization: Bearer <token>
Content-Type: application/json

{"heightCm":170.5,"weightKg":62.3}
```

```json
{
  "code": 1000,
  "result": {
    "id": 1,
    "heightCm": 170.5,
    "weightKg": 62.3,
    "bmi": 21.4,
    "recordedAt": "2026-09-30T14:00:00"
  }
}
```

### Phân trang

```http
GET /api/nutrition/me/health-records?page=0&size=20
Authorization: Bearer <token>
```

### Replace allergy

```http
PUT /api/nutrition/me/allergies
Authorization: Bearer <token>
Content-Type: application/json

{"allergenIds":[1,4,9]}
```

Gửi `{"allergenIds":[]}` để xóa hết.

## 13. OpenAPI và Gateway

`OpenApiConfig` khai báo API title, bearer JWT scheme và server `/api`. Swagger tổng truy cập tại:

```text
http://localhost:8080/swagger-ui.html
```

Gateway route `/api/nutrition/**` tới port 8082 và route `/nutrition-service/v3/api-docs/**` tới OpenAPI JSON.

## 14. Test

### Unit/service test

- BMI làm tròn HALF_UP.
- Create lưu đúng user/BMI/time.
- Latest có/không có record.
- Paging clamp size/page và chống overflow.
- Update giữ recordedAt, tính lại BMI, chống sửa record user khác.
- Catalog và allergy sort theo category/tên Việt.
- Replace allergy chỉ add/remove phần chênh lệch.
- List rỗng xóa hết; ID lạ rollback/lỗi.

### Controller/security test

- Validation min/max/scale và required field.
- Malformed JSON, path/query sai kiểu.
- User ID lấy từ JWT.
- Thiếu/sai token trả JSON 401 chuẩn.
- HS256 đúng được chấp nhận, thuật toán khác bị từ chối.
- Data integrity error không log dữ liệu riêng tư.

`NutritionServiceApplicationTests` là context test dùng MySQL thật theo cấu hình hiện tại.

Chạy unit/slice test không cần context DB:

```powershell
cd nutrition-service
./mvnw.cmd test -Dtest='!NutritionServiceApplicationTests'
```

## 15. Chạy local

```powershell
docker compose up -d mysql
cd nutrition-service
./mvnw.cmd spring-boot:run
```

Database `veggiepal_nutrition` được tạo tự động. Service trực tiếp ở `:8082`; URL client chuẩn đi qua gateway `:8080/api/nutrition/...`.

## 16. Giới hạn và điểm cần lưu ý

1. Không xác minh user ID còn tồn tại trong identity service; service tin JWT hợp lệ.
2. Không có foreign key tới user, đúng boundary microservice nhưng có thể còn dữ liệu khi user bị xóa.
3. JWT shared symmetric secret phải được bảo vệ và đồng bộ.
4. Chưa có delete health record.
5. `recordedAt` luôn là thời điểm server tạo, chưa cho nhập thời điểm đo trong quá khứ.
6. Không có optimistic locking/version; concurrent update cùng record dùng last-write-wins.
7. Danh mục allergen seed cố định trong SQL, chưa có admin API.
8. `ddl-auto=update` và credential mặc định chỉ phù hợp local.
9. Catalog hiện cũng yêu cầu JWT dù bản chất có thể là dữ liệu public; đây là rule hiện tại của security config.
10. File `data.sql` cần luôn được lưu/đọc UTF-8 để tên tiếng Việt không lỗi encoding.

## 17. Tóm tắt

Nutrition service là chủ sở hữu độc lập của health record và allergy relation. Nó chỉ nhận danh tính qua `userId` claim, luôn scope query theo user hiện tại, tính BMI phía server và thay allergy theo transaction/difference set. Dữ liệu user/account vẫn thuộc identity service.

