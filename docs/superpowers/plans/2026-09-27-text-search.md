# Text Search (US 7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khi `GET /blogs` có `keyword`, bài khớp ở tiêu đề luôn đứng trước bài chỉ khớp ở nội dung (BR của task sheet `[BE] API Tìm kiếm Text`).

**Architecture:** Endpoint, service và chữ ký repository giữ nguyên. Chỉ thêm một `ORDER BY case ... end` vào `@Query` của `BlogRepository.search`; Spring Data nối `Sort` của `Pageable` vào sau nó, nên `sort` chỉ còn quyết định thứ tự bên trong mỗi tầng.

**Tech Stack:** Java 21, Spring Boot 4.1.1, Spring Data JPA + Hibernate, MySQL 8.4, JUnit 5 + MockMvc.

**Spec:** [`docs/superpowers/specs/2026-09-27-text-search-design.md`](../specs/2026-09-27-text-search-design.md)

## Global Constraints

- **Không commit, không push.** Người dùng tự review diff và tự commit. Step cuối chỉ dừng lại và bàn giao.
- **Không có parent POM.** Chạy Maven từ trong `blog-service/`. Trên Windows dùng Git Bash (`./mvnw`); PowerShell làm hỏng tham số `-Dtest=...`.
- **Thay đổi `@Query` bắt buộc chạy `BlogServiceIntegrationTests`** (xem `CLAUDE.md`), không chỉ bộ test nhanh.
- **Integration test cần Docker:** MySQL ở `localhost:3307`, root/12345. Test tự tạo schema `veggiepal_blog_it`.
- **Không `@Lob`** trên cột cần search, và không đổi kiểu cột `title`/`content`.
- **Không có linter/formatter.** Bám style của file xung quanh.

---

## File Structure

| File | Thay đổi |
|---|---|
| `blog-service/src/main/java/com/veggiepal/blog/repository/BlogRepository.java` | `search`: thêm `ORDER BY` xếp hạng (dòng 28-41) |
| `blog-service/src/main/java/com/veggiepal/blog/controller/BlogController.java` | `@Operation` summary ở dòng 123 |
| `blog-service/src/test/java/com/veggiepal/blog/BlogServiceIntegrationTests.java` | Thêm một case sau `keywordSearch_isCaseInsensitive` (kết thúc ở dòng 163) |
| `CLAUDE.md` | Một bullet trong mục blog-service, sau bullet "Voting is..." (dòng 123) |

Chỉ có một task: cả bốn thay đổi cùng phục vụ một hành vi, và reviewer không thể duyệt riêng phần query mà bác phần test.

---

## Task 1: Xếp hạng tiêu đề trước trong keyword search

**Files:**
- Modify: `blog-service/src/main/java/com/veggiepal/blog/repository/BlogRepository.java:28-41`
- Modify: `blog-service/src/main/java/com/veggiepal/blog/controller/BlogController.java:123`
- Modify: `CLAUDE.md:123`
- Test: `blog-service/src/test/java/com/veggiepal/blog/BlogServiceIntegrationTests.java:164`

**Interfaces:**
- Consumes: `BlogRepository.search(ContentStatus status, Long categoryId, String keyword, Pageable pageable)` giữ nguyên chữ ký. `BlogService.getPublishedBlogs` gọi nó với `normalizeKeyword(keyword)` (`null` khi rỗng) và `Sort` từ `sortFor(sort)`, mặc định `publishedAt DESC, id DESC`.
- Test helpers có sẵn trong `BlogServiceIntegrationTests`: `unique()` trả 8 ký tự hex, `body(String marker)` trả nội dung >= 20 ký tự chứa `marker`, `createRootCategory(String name)` và `createPublishedBlog(long categoryId, String title, String content)` trả `long` id.
- Produces: không có API mới. Chỉ thứ tự `result.items` của `GET /blogs?keyword=` thay đổi.

- [ ] **Step 1: Bật hạ tầng**

Chạy ở thư mục gốc repo:

```bash
docker compose up -d
docker ps --format '{{.Names}} {{.Status}}'
```

Expected: có dòng `veggiepal-mysql Up ...`. Nếu lỗi `failed to connect to the docker API`, mở Docker Desktop rồi chạy lại.

- [ ] **Step 2: Viết test đỏ**

Chèn vào `BlogServiceIntegrationTests.java` ngay sau method `keywordSearch_isCaseInsensitive()` (sau dòng 163), trước `@Test` của `readingABlog_incrementsItsViewCount`:

```java

    // Task sheet US7: a title match ranks above a body-only match. The body match is
    // published second, so without the ranking the default newest-first sort would put it on top.
    @Test
    void keywordSearch_ranksTitleMatchesBeforeBodyMatches() throws Exception {
        String keyword = "tukhoa" + unique();
        long categoryId = createRootCategory("Danh mục " + unique());
        long titleMatch = createPublishedBlog(categoryId, "Đậu hũ " + keyword, body(unique()));
        long bodyMatch = createPublishedBlog(categoryId, "Bún chay " + unique(), body(keyword));

        mockMvc.perform(get("/blogs").param("keyword", keyword))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.totalElements").value(2))
                .andExpect(jsonPath("$.result.items[0].id").value(titleMatch))
                .andExpect(jsonPath("$.result.items[1].id").value(bodyMatch));
    }
```

Mỗi lần chạy dùng một keyword mới, nên các dòng còn lại từ lần chạy trước trong `veggiepal_blog_it` không ảnh hưởng tới `totalElements`.

- [ ] **Step 3: Chạy để xác nhận test đỏ**

```bash
cd blog-service
./mvnw test -Dtest='BlogServiceIntegrationTests#keywordSearch_ranksTitleMatchesBeforeBodyMatches'
```

Expected: FAIL tại `JSON path "$.result.items[0].id"`, expected là id của `titleMatch`, actual là id của `bodyMatch`. Đỏ vì **sai thứ tự**. Nếu đỏ vì lý do khác (context không lên, kết nối DB, `totalElements` khác 2), dừng lại và xử lý trước khi sang Step 4.

- [ ] **Step 4: Thêm `ORDER BY` xếp hạng**

Trong `BlogRepository.java`, thay khối `@Query` của `search` (dòng 28-35) bằng:

```java
    // Task sheet US7: title matches rank above body-only matches. The Pageable's sort is
    // appended after this expression, so it only orders rows within each tier. With no
    // keyword, like null is NULL and every row falls into the same tier.
    @Query("""
            select b from Blog b
            where b.status = :status
              and (:categoryId is null or b.category.id = :categoryId)
              and (:keyword is null
                   or lower(b.title) like lower(concat('%', :keyword, '%'))
                   or lower(b.content) like lower(concat('%', :keyword, '%')))
            order by case when lower(b.title) like lower(concat('%', :keyword, '%')) then 0 else 1 end
            """)
```

Chữ ký `Page<Blog> search(...)` bên dưới giữ nguyên.

- [ ] **Step 5: Chạy lại để xác nhận test xanh**

```bash
./mvnw test -Dtest='BlogServiceIntegrationTests#keywordSearch_ranksTitleMatchesBeforeBodyMatches'
```

Expected: `Tests run: 1, Failures: 0, Errors: 0`.

Nếu context không khởi động được vì lỗi validate query ở `ORDER BY`, hoặc count query lỗi bind tham số, **không** tự đổi sang native query. Dùng `superpowers:systematic-debugging` và báo lại người dùng.

- [ ] **Step 6: Cập nhật Swagger summary**

`BlogController.java` dòng 123, đổi:

```java
    @Operation(summary = "Published blogs; keyword searches title and content")
```

thành:

```java
    @Operation(summary = "Published blogs; keyword searches title and content, title matches first")
```

- [ ] **Step 7: Ghi lại vào `CLAUDE.md`**

Chèn bullet này ngay sau bullet bắt đầu bằng **Voting is** (dòng 123) trong mục `### blog-service`:

```markdown
- **Keyword search ranks title matches first** (task sheet US7): `BlogRepository.search` orders by `case when title like %kw% then 0 else 1 end` ahead of the `Pageable` sort, so `sort` only orders rows within each tier. It stays `LIKE`, not FULLTEXT, on purpose: InnoDB FULLTEXT skips 2-letter Vietnamese syllables ("bò", "cà") and matches whole words, which breaks the FE's search-as-you-type from 2 characters. The default `ai_ci` collation makes it accent-insensitive ("pho" finds "Phở").
```

- [ ] **Step 8: Chạy bộ test nhanh**

```bash
./mvnw test -Dtest='!BlogServiceApplicationTests,!BlogServiceIntegrationTests'
```

Expected: `BUILD SUCCESS`, `Failures: 0, Errors: 0`. `BlogServiceTest` mock `search(...)` với chữ ký không đổi nên không cần sửa.

- [ ] **Step 9: Chạy gate cần database**

```bash
./mvnw test -Dtest='BlogServiceApplicationTests,BlogServiceIntegrationTests'
```

Expected: `BUILD SUCCESS`, `Failures: 0, Errors: 0`. Nhất là `keywordSearch_matchesTextInsideTheBody` và `keywordSearch_isCaseInsensitive` vẫn xanh, và `publishedBlog_appearsInTheListWithItsCategoryName` (list không có keyword) vẫn xanh.

- [ ] **Step 10: Kiểm tra mutation**

Tạm xóa dòng `order by case ...` trong `BlogRepository.java`, rồi chạy:

```bash
./mvnw test -Dtest='BlogServiceIntegrationTests#keywordSearch_ranksTitleMatchesBeforeBodyMatches'
```

Expected: FAIL giống Step 3. Sau đó **khôi phục dòng vừa xóa** và chạy lại để thấy PASS. Step này chứng minh test thật sự bảo vệ BR.

- [ ] **Step 11: Bàn giao, không commit**

```bash
git status
git diff --stat
```

Expected: đúng 4 file ở mục File Structure thay đổi, cộng spec và plan này. Dừng lại, báo kết quả Step 8-10 cho người dùng. Message gợi ý nếu người dùng muốn:

```
feat(blog): rank title matches first in keyword search
```

---

## Kiểm tra sau khi xong

- [ ] `GET /blogs?keyword=X`: mọi bài khớp tiêu đề đứng trước mọi bài chỉ khớp nội dung (Step 9, 10).
- [ ] `GET /blogs` không keyword xếp y như trước (Step 9, `publishedBlog_appearsInTheListWithItsCategoryName`).
- [ ] `sort=popular` / `mostViewed` vẫn nhận, chỉ xếp bên trong mỗi tầng (`BlogServiceTest` ở Step 8 kiểm tra `Sort` được truyền xuống).
- [ ] Không có kết quả vẫn trả page rỗng, HTTP 200 (không đổi code đường này).
- [ ] Không commit.
