# API Gateway - Tài liệu kiến trúc và giải thích mã nguồn

## 1. Vai trò

`api-gateway` là cổng HTTP duy nhất dành cho frontend. Gateway không chứa business logic, không truy cập database và hiện không tự xác thực JWT. Nó chịu trách nhiệm:

- Nhận request tại port `8080`.
- Chọn microservice dựa trên URL.
- Bỏ prefix `/api` trước khi forward.
- Proxy OpenAPI JSON của từng service.
- Cung cấp Swagger UI tổng hợp.
- Xử lý CORS cho frontend local.

```text
Frontend
   |
   v
Gateway :8080
   ├── identity-service  :8081
   ├── nutrition-service :8082
   └── blog-service      :8083
```

## 2. Công nghệ

File `api-gateway/pom.xml` khai báo:

| Dependency | Vai trò |
|---|---|
| Spring Boot 4.1.1 | Nền tảng ứng dụng |
| Java 21 | Runtime/ngôn ngữ |
| Spring Cloud Gateway Server Web MVC | Routing/proxy theo mô hình Servlet MVC |
| Spring Boot Actuator | Nền tảng health check/monitoring |
| Springdoc OpenAPI UI | Swagger UI tổng hợp |
| Spring Boot Test | Context test |

`spring-cloud-dependencies` BOM phiên bản `2025.1.3` quản lý phiên bản các module Spring Cloud tương thích.

## 3. Điểm khởi động

`ApiGatewayApplication.java`:

```java
@SpringBootApplication
public class ApiGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(ApiGatewayApplication.class, args);
    }
}
```

`@SpringBootApplication` bật auto-configuration và quét package `com.veggiepal.gateway`, bao gồm `CorsConfig`.

## 4. Cấu hình tổng quát

Trong `application.yaml`:

```yaml
server:
  port: 8080

spring:
  application:
    name: api-gateway
```

Gateway chạy tại `http://localhost:8080`.

## 5. Cơ chế route

Mỗi route gồm ba thành phần:

```yaml
- id: identity-service
  uri: http://localhost:8081
  predicates:
    - Path=/api/auth/**
  filters:
    - StripPrefix=1
```

- `id`: tên duy nhất của route.
- `uri`: địa chỉ upstream service.
- `Path`: điều kiện URL để route được chọn.
- `StripPrefix=1`: bỏ segment đầu tiên trước khi forward.

Ví dụ:

```text
POST http://localhost:8080/api/auth/login
                     |
                     | bỏ segment /api
                     v
POST http://localhost:8081/auth/login
```

### Bảng route business

| URL client | Upstream | URL service nhận |
|---|---|---|
| `/api/auth/**` | Identity `:8081` | `/auth/**` |
| `/api/users/**` | Identity `:8081` | `/users/**` |
| `/api/nutrition/**` | Nutrition `:8082` | `/nutrition/**` |
| `/api/blogs/**` | Blog `:8083` | `/blogs/**` |
| `/api/categories/**` | Blog `:8083` | `/categories/**` |
| `/api/comments/**` | Blog `:8083` | `/comments/**` |

Gateway tách route theo tài nguyên. Vì vậy blog service không cần URL kiểu `/blog/blogs`; client dùng trực tiếp `/api/blogs`.

### Route OpenAPI

| Gateway URL | Upstream URL |
|---|---|
| `/identity-service/v3/api-docs` | `http://localhost:8081/v3/api-docs` |
| `/nutrition-service/v3/api-docs` | `http://localhost:8082/v3/api-docs` |
| `/blog-service/v3/api-docs` | `http://localhost:8083/v3/api-docs` |

Các route docs cũng dùng `StripPrefix=1`: segment mang tên service chỉ giúp gateway phân biệt upstream.

## 6. Swagger UI tổng hợp

```yaml
springdoc:
  swagger-ui:
    path: /swagger-ui.html
    urls:
      - name: Identity Service
        url: /identity-service/v3/api-docs
      - name: Nutrition Service
        url: /nutrition-service/v3/api-docs
      - name: Blog Service
        url: /blog-service/v3/api-docs
```

Truy cập:

```text
http://localhost:8080/swagger-ui.html
```

Dropdown Swagger cho phép chuyển giữa ba OpenAPI definition. Gateway không gộp chúng thành một JSON duy nhất; UI tải definition tương ứng khi người dùng chọn.

Để thêm service mới cần đồng thời:

1. Thêm route API.
2. Thêm route `/service-name/v3/api-docs/**`.
3. Thêm entry vào `springdoc.swagger-ui.urls`.

## 7. CORS

File `configuration/CorsConfig.java` tạo một `CorsFilter` áp dụng cho `/**`.

```java
config.setAllowedOriginPatterns(List.of("http://localhost:*"));
```

Cho phép frontend HTTP chạy ở bất kỳ port localhost nào, ví dụ Vite `5173` hoặc React `3000`.

```java
config.setAllowedMethods(List.of(
    "GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"
));
```

`OPTIONS` phục vụ preflight request của browser.

```java
config.setAllowedHeaders(List.of("*"));
config.setAllowCredentials(true);
```

- Cho phép mọi request header, bao gồm `Authorization` và `Content-Type`.
- Cho phép credential mode của browser.

```java
source.registerCorsConfiguration("/**", config);
```

Cấu hình áp dụng cho toàn bộ route gateway.

Production cần thay `http://localhost:*` bằng danh sách origin cụ thể của frontend. Khi `allowCredentials=true`, không nên mở origin tùy ý.

## 8. Gateway và JWT

Gateway hiện không có Spring Security/resource server. Luồng thực tế:

```text
Client gửi Authorization header
 -> Gateway giữ nguyên header khi proxy
 -> Upstream service kiểm tra JWT
```

Ưu điểm:

- Mỗi service tự bảo vệ endpoint của mình.
- Gọi trực tiếp service cũng vẫn cần token.
- Rule public/protected nằm gần business API.

Hệ quả:

- Mỗi service cần cùng `JWT_SECRET`.
- Security configuration bị lặp.
- Gateway không chặn sớm token sai.

Không nên chỉ xác thực ở gateway rồi bỏ security ở service, vì khi đó request đi trực tiếp tới port nội bộ có thể bypass quyền.

## 9. Luồng request

```text
1. Browser gửi request tới :8080.
2. CorsFilter thêm/kiểm tra CORS header.
3. Gateway so khớp Path predicate.
4. StripPrefix bỏ một segment.
5. Gateway forward method, headers, query, body tới upstream.
6. Upstream xác thực và xử lý business logic.
7. Gateway proxy status, headers và body về client.
```

Nếu không có route phù hợp, request không tới microservice và gateway trả lỗi route/not found.

Nếu upstream không chạy, gateway trả lỗi kết nối/5xx; đây không phải lỗi controller của service.

## 10. Test

`ApiGatewayApplicationTests` dùng `@SpringBootTest` với test `contextLoads()`. Test chỉ xác nhận Spring context và cấu hình bean khởi tạo được; chưa kiểm thử:

- Route thực sự forward đúng upstream.
- `StripPrefix` đúng.
- CORS response/preflight.
- Swagger aggregation.
- Hành vi khi upstream timeout hoặc không hoạt động.

Chạy test:

```powershell
cd api-gateway
./mvnw.cmd test
```

Chạy ứng dụng:

```powershell
./mvnw.cmd spring-boot:run
```

## 11. Debug thường gặp

### Gateway trả 404

- Kiểm tra URL có prefix `/api` không.
- Kiểm tra tài nguyên đã có route trong YAML chưa.
- Kiểm tra indentation YAML.

### Gateway trả 5xx/connection refused

- Kiểm tra upstream tương ứng có chạy đúng port 8081/8082/8083.
- Gateway đang dùng địa chỉ `localhost`, phù hợp khi chạy các process trên cùng host; nếu chạy tất cả trong container cần dùng service DNS name thay vì localhost.

### CORS bị browser chặn

- Cấu hình hiện chỉ cho `http://localhost:*`.
- Frontend dùng `https`, IP LAN hoặc domain khác sẽ không được phép.
- Kiểm tra request preflight `OPTIONS` có đi qua gateway hay không.

### Swagger không tải một service

- Mở trực tiếp route `/service-name/v3/api-docs`.
- Kiểm tra service đang chạy.
- Kiểm tra cả route docs và entry Swagger UI.

## 12. Giới hạn hiện tại

1. Upstream URI được hard-code thành localhost, chưa có service discovery.
2. Chưa có load balancing nhiều instance.
3. Chưa có retry, circuit breaker, timeout hay fallback được cấu hình rõ.
4. Chưa có rate limiting.
5. Chưa có centralized authentication tại gateway; upstream vẫn là lớp bảo vệ chính.
6. Actuator dependency đã có nhưng chưa expose/configure endpoint monitoring cụ thể.
7. CORS chỉ phục vụ frontend local.
8. Chưa có automated route/CORS integration test.
9. Chưa có correlation ID hoặc distributed tracing.
10. Gateway là single entry point nên production cần health check, redundancy và reverse proxy/load balancer phù hợp.

## 13. Tóm tắt

Gateway là lớp định tuyến mỏng:

```text
/api/auth, /api/users      -> identity
/api/nutrition             -> nutrition
/api/blogs/categories/comments -> blog
```

Nó bỏ `/api`, giữ request data và chuyển tiếp tới service. JWT được upstream kiểm tra. CORS tập trung ở gateway và Swagger UI tập hợp tài liệu của cả ba service.

