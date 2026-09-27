# Text Search (US 7) — Design Spec

| Thuộc tính | Giá trị |
|---|---|
| Ngày | 2026-09-27 |
| Nhánh | `feature/text-search` |
| Trạng thái | Chờ review |
| Tài liệu gốc | Task sheet "PHÂN CHIA TASK", tab `TASK`, US 7: `[BE] API Tìm kiếm Text`, `[FE] UI Search Bar`, `[FE] UI Search Results`; blog-service spec [`2026-09-20-blog-service-design.md`](2026-09-20-blog-service-design.md) mục 6.3 |

## 1. Mục tiêu

BUSINESS RULE của dòng `[BE] API Tìm kiếm Text`:

> Ưu tiên kết quả khớp Tiêu đề trước. (Có thể nghiên cứu tích hợp Full-Text Search của MySQL nếu dư thời gian).

Sau thay đổi này, khi có `keyword`, bài khớp ở tiêu đề luôn đứng trước bài chỉ khớp ở nội dung.

## 2. Hiện trạng

`GET /blogs?keyword=` đã có từ blog-service (Task 5). Đối chiếu với ba dòng US 7:

| Yêu cầu | Nguồn | Hiện trạng |
|---|---|---|
| Tìm theo từ khóa trên tiêu đề và nội dung | `[BE] API Tìm kiếm Text` | Có: `lower(title) LIKE %kw% OR lower(content) LIKE %kw%`, chỉ trên `PUBLISHED` |
| Ưu tiên kết quả khớp tiêu đề | `[BE] API Tìm kiếm Text` | **Chưa**: kết quả chỉ xếp theo `sort` (mặc định `publishedAt DESC`), nên bài mới khớp nội dung đứng trên bài cũ khớp tiêu đề |
| Không có kết quả thì FE hiện "Rất tiếc, không tìm thấy kết quả" | `[FE] UI Search Results` | Có: page rỗng, HTTP 200 |
| Gõ >= 2 ký tự mới gọi API, debounce 500ms | `[FE] UI Search Bar` | Việc của FE |

Khoảng trống duy nhất là thứ tự xếp.

## 3. Thiết kế

### 3.1 Xếp hạng hai tầng

Thêm một `ORDER BY` vào `BlogRepository.search`, giữ nguyên `WHERE`:

```sql
order by case when lower(b.title) like lower(concat('%', :keyword, '%')) then 0 else 1 end
```

- Tầng 0 là bài khớp tiêu đề (dù nội dung có khớp hay không), tầng 1 là bài chỉ khớp nội dung.
- Spring Data nối `Sort` của `Pageable` vào **sau** biểu thức này, nên `sort` quyết định thứ tự bên trong mỗi tầng: `newest` (mặc định, `publishedAt DESC, id DESC`), `popular`, `mostViewed`.
- Không có `keyword` (`null` sau `normalizeKeyword`): `like null` ra `NULL`, mọi bài rơi vào `else 1`, cùng một tầng, và danh sách blog thường xếp y như trước.
- Count query do Spring Data tự sinh bỏ `ORDER BY`; `:keyword` vẫn nằm trong `WHERE` nên việc bind không đổi.

Ví dụ, `keyword=đậu`, `sort=newest`:

| # | Tiêu đề | Khớp ở | Đăng |
|---|---|---|---|
| 1 | Đậu hũ sốt cà | tiêu đề | 2 ngày trước |
| 2 | Canh đậu non | tiêu đề | 5 ngày trước |
| 3 | Bún chay | nội dung | hôm nay |
| 4 | Salad rau | nội dung | hôm qua |

### 3.2 Hợp đồng API

Không đổi. FE Search Bar và Search Results gọi:

```
GET /api/blogs?keyword=<từ khóa>&page=0&size=10[&categoryId=][&sort=]
```

Response vẫn là `ApiResponse<PageResponse<BlogSummaryResponse>>`. Chỉ thứ tự `items` thay đổi khi có `keyword`.

### 3.3 Hành vi sẵn có, ghi lại cho FE

Không đổi trong spec này, liệt kê để FE không phải đoán:

- `keyword` được `trim()`; chuỗi rỗng hoặc toàn khoảng trắng nghĩa là không lọc.
- Không phân biệt hoa thường.
- **Không phân biệt dấu:** cột `title`/`content` dùng collation mặc định `utf8mb4_0900_ai_ci`, nên `pho` tìm ra "Phở", và `che` tìm ra cả "Chè" lẫn "Chế". Với search thì rộng như vậy là có lợi (người dùng hay gõ không dấu). Ngược với tên danh mục, vốn cố ý dùng `as_ci`.
- Kết hợp được với `categoryId` và `sort`.
- Chỉ trả bài `PUBLISHED`.

## 4. Không làm

| Phương án | Lý do bỏ |
|---|---|
| MySQL `FULLTEXT` + `MATCH ... AGAINST` | (1) `ddl-auto` không tạo được FULLTEXT index, repo không có migration. (2) `innodb_ft_min_token_size=3` mặc định bỏ qua âm tiết 2 ký tự như "bò", "cà", "đỗ", trừ khi đổi sang parser `ngram`. (3) `MATCH` khớp theo từ, không theo chuỗi con, nên kiểu gõ "ph" ra "phở" từ 2 ký tự của FE không còn chạy. BR chỉ ghi "nếu dư thời gian". |
| BE chặn `keyword` dưới 2 ký tự | Đó là rule của FE Search Bar. Search 1 ký tự chỉ trả kết quả rộng hơn, không gây hại. |
| Hai query (tiêu đề, rồi nội dung) rồi ghép | Làm vỡ phân trang và `totalElements`. |
| Ba tầng (tiêu đề bắt đầu bằng keyword > tiêu đề chứa > nội dung) | Người dùng chọn hai tầng (2026-09-27). |

## 5. Giới hạn đã biết

Có từ trước, không sửa ở đây:

- **`content` là HTML** từ rich text editor, nên keyword trùng tên tag hoặc thuộc tính ("strong", "href") cũng khớp. Sửa khi cần bằng một cột plain text sinh lúc lưu bài.
- **`%` và `_` trong keyword là wildcard** của `LIKE`. Hậu quả chỉ là kết quả rộng hơn.
- **Quét toàn bảng**: `LIKE '%kw%'` không dùng được index. Chấp nhận ở quy mô đồ án; hướng nâng cấp là ý 7 mục 11 của blog-service spec.

## 6. Kiểm thử

Thay đổi `@Query` nên `BlogServiceIntegrationTests` là gate bắt buộc (xem `CLAUDE.md`). Thêm một case:

- `keywordSearch_ranksTitleMatchesBeforeBodyMatches`: tạo bài A khớp keyword ở tiêu đề **trước**, rồi tạo bài B chỉ khớp ở nội dung **sau** (B mới hơn). Search theo keyword, assert `totalElements == 2`, `items[0].id == A`, `items[1].id == B`.
- Kiểm tra bằng mutation: bỏ `ORDER BY` thì `sort=newest` đẩy B lên đầu và case này đỏ.
- Case này cũng chứng minh count query sinh tự động vẫn chạy khi query có `ORDER BY` chứa tham số.

`BlogServiceTest` không đổi: service và chữ ký `search(...)` giữ nguyên.

## 7. File thay đổi

| File | Thay đổi |
|---|---|
| `blog-service/.../repository/BlogRepository.java` | Thêm `ORDER BY` xếp hạng vào `search` |
| `blog-service/.../controller/BlogController.java` | `@Operation` summary nói rõ tiêu đề được ưu tiên |
| `blog-service/src/test/.../BlogServiceIntegrationTests.java` | Thêm case ở mục 6 |
| `CLAUDE.md` | Một dòng về cách xếp hạng search trong mục blog-service |
