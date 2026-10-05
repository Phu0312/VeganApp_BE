-- ============================================================
-- VEGGIEPAL BLOG SERVICE - SAMPLE DATA
-- ============================================================


-- ============================================================
-- 1. CATEGORIES
-- ============================================================

-- FOOD TYPE: Món chính
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'FOOD_TYPE',
    'Món chính',
    1,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Món chính'
);


-- FOOD TYPE: Món ăn sáng
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'FOOD_TYPE',
    'Món ăn sáng',
    2,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Món ăn sáng'
);


-- FOOD TYPE: Salad
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'FOOD_TYPE',
    'Salad',
    3,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Salad'
);


-- FOOD TYPE: Món nước
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'FOOD_TYPE',
    'Món nước',
    4,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Món nước'
);


-- RECIPE TYPE: Việt Nam
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'RECIPE_TYPE',
    'Việt Nam',
    1,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Việt Nam'
);


-- RECIPE TYPE: Healthy
INSERT INTO categories
(
    parent_id,
    type,
    name,
    display_order,
    is_active,
    created_at,
    updated_at
)
SELECT
    NULL,
    'RECIPE_TYPE',
    'Healthy',
    2,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM categories
    WHERE name = 'Healthy'
);


-- ============================================================
-- 2. BLOGS
-- ============================================================


-- BLOG 1
INSERT INTO blogs
(
    author_id,
    category_id,
    title,
    content,
    thumbnail_url,
    status,
    view_count,
    vote_score,
    published_at,
    created_at,
    updated_at
)
SELECT
    1,
    c.id,
    '5 món chay đơn giản cho người mới bắt đầu',
    'Ăn chay không cần phải quá phức tạp. Với những nguyên liệu quen thuộc như đậu hũ, rau xanh, nấm và gạo lứt, bạn hoàn toàn có thể chuẩn bị những bữa ăn vừa ngon vừa đầy đủ dinh dưỡng.

Trong bài viết này, VeggiePal gợi ý 5 món chay đơn giản gồm đậu hũ sốt cà chua, cơm gạo lứt rau củ, canh nấm, salad đậu gà và mì rau củ.

Điều quan trọng nhất khi mới bắt đầu ăn chay là duy trì sự đa dạng trong thực phẩm và chú ý bổ sung đủ protein thực vật.',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
    'PUBLISHED',
    128,
    0,
    NOW() - INTERVAL 10 DAY,
    NOW() - INTERVAL 10 DAY,
    NOW() - INTERVAL 10 DAY
FROM categories c
WHERE c.name = 'Món chính'
  AND NOT EXISTS (
    SELECT 1
    FROM blogs
    WHERE title = '5 món chay đơn giản cho người mới bắt đầu'
    );


-- BLOG 2
INSERT INTO blogs
(
    author_id,
    category_id,
    title,
    content,
    thumbnail_url,
    status,
    view_count,
    vote_score,
    published_at,
    created_at,
    updated_at
)
SELECT
    2,
    c.id,
    'Bữa sáng chay giàu protein nên ăn gì?',
    'Protein là một trong những chất dinh dưỡng được quan tâm nhiều nhất khi ăn chay.

Một bữa sáng chay có thể kết hợp yến mạch, sữa đậu nành, hạt chia, bơ đậu phộng và trái cây. Ngoài ra, đậu hũ và các loại đậu cũng là nguồn protein thực vật rất tốt.

Việc phân bổ protein đều trong ngày giúp cơ thể hấp thu tốt hơn và duy trì cảm giác no lâu.',
    'https://images.unsplash.com/photo-1498837167922-ddd27525d352',
    'PUBLISHED',
    85,
    0,
    NOW() - INTERVAL 7 DAY,
    NOW() - INTERVAL 7 DAY,
    NOW() - INTERVAL 7 DAY
FROM categories c
WHERE c.name = 'Món ăn sáng'
  AND NOT EXISTS (
    SELECT 1
    FROM blogs
    WHERE title = 'Bữa sáng chay giàu protein nên ăn gì?'
    );


-- BLOG 3
INSERT INTO blogs
(
    author_id,
    category_id,
    title,
    content,
    thumbnail_url,
    status,
    view_count,
    vote_score,
    published_at,
    created_at,
    updated_at
)
SELECT
    2,
    c.id,
    'Cách làm salad đậu gà và bơ nhanh trong 15 phút',
    'Salad đậu gà và bơ là lựa chọn phù hợp cho những ngày bận rộn.

Bạn chỉ cần chuẩn bị đậu gà đã luộc, bơ, cà chua, rau xanh và một chút nước cốt chanh. Trộn đều tất cả nguyên liệu và nêm gia vị vừa ăn.

Món ăn này cung cấp protein thực vật, chất xơ và chất béo không bão hòa.',
    'https://images.unsplash.com/photo-1546793665-c74683f339c1',
    'PUBLISHED',
    203,
    0,
    NOW() - INTERVAL 4 DAY,
    NOW() - INTERVAL 4 DAY,
    NOW() - INTERVAL 4 DAY
FROM categories c
WHERE c.name = 'Salad'
  AND NOT EXISTS (
    SELECT 1
    FROM blogs
    WHERE title = 'Cách làm salad đậu gà và bơ nhanh trong 15 phút'
    );


-- BLOG 4
INSERT INTO blogs
(
    author_id,
    category_id,
    title,
    content,
    thumbnail_url,
    status,
    view_count,
    vote_score,
    published_at,
    created_at,
    updated_at
)
SELECT
    3,
    c.id,
    'Phở chay nấu tại nhà có khó không?',
    'Phở chay có thể nấu tại nhà với những nguyên liệu khá đơn giản.

Nước dùng có thể được tạo vị ngọt tự nhiên từ củ cải trắng, cà rốt, hành tây và nấm. Các loại gia vị như quế, hồi và gừng giúp tạo mùi thơm đặc trưng cho món phở.

Khi ăn có thể dùng thêm đậu hũ, nấm, rau thơm và giá.',
    'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43',
    'PUBLISHED',
    156,
    0,
    NOW() - INTERVAL 2 DAY,
    NOW() - INTERVAL 2 DAY,
    NOW() - INTERVAL 2 DAY
FROM categories c
WHERE c.name = 'Món nước'
  AND NOT EXISTS (
    SELECT 1
    FROM blogs
    WHERE title = 'Phở chay nấu tại nhà có khó không?'
    );


-- BLOG 5 - DRAFT
INSERT INTO blogs
(
    author_id,
    category_id,
    title,
    content,
    thumbnail_url,
    status,
    view_count,
    vote_score,
    published_at,
    created_at,
    updated_at
)
SELECT
    2,
    c.id,
    'Thực đơn chay 7 ngày cho người bận rộn',
    'Đây là bản nháp cho bài viết về thực đơn chay trong một tuần.

Bài viết sẽ giới thiệu các món ăn đơn giản, dễ chuẩn bị và có thể meal prep trước.',
    NULL,
    'DRAFT',
    0,
    0,
    NULL,
    NOW(),
    NOW()
FROM categories c
WHERE c.name = 'Healthy'
  AND NOT EXISTS (
    SELECT 1
    FROM blogs
    WHERE title = 'Thực đơn chay 7 ngày cho người bận rộn'
);


-- ============================================================
-- 3. COMMENTS
-- ============================================================


-- COMMENT BLOG 1
INSERT INTO comments
(
    author_id,
    target_type,
    target_id,
    parent_comment_id,
    content,
    status,
    created_at,
    updated_at
)
SELECT
    2,
    'BLOG',
    b.id,
    NULL,
    'Bài viết rất hữu ích cho người mới bắt đầu ăn chay.',
    'VISIBLE',
    NOW() - INTERVAL 9 DAY,
    NOW() - INTERVAL 9 DAY
FROM blogs b
WHERE b.title = '5 món chay đơn giản cho người mới bắt đầu'
  AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.target_type = 'BLOG'
  AND c.target_id = b.id
  AND c.author_id = 2
  AND c.content = 'Bài viết rất hữu ích cho người mới bắt đầu ăn chay.'
    );


-- COMMENT BLOG 1 - USER 3
INSERT INTO comments
(
    author_id,
    target_type,
    target_id,
    parent_comment_id,
    content,
    status,
    created_at,
    updated_at
)
SELECT
    3,
    'BLOG',
    b.id,
    NULL,
    'Mình sẽ thử món cơm gạo lứt rau củ.',
    'VISIBLE',
    NOW() - INTERVAL 8 DAY,
    NOW() - INTERVAL 8 DAY
FROM blogs b
WHERE b.title = '5 món chay đơn giản cho người mới bắt đầu'
  AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.target_type = 'BLOG'
  AND c.target_id = b.id
  AND c.author_id = 3
  AND c.content = 'Mình sẽ thử món cơm gạo lứt rau củ.'
    );


-- REPLY COMMENT
INSERT INTO comments
(
    author_id,
    target_type,
    target_id,
    parent_comment_id,
    content,
    status,
    created_at,
    updated_at
)
SELECT
    1,
    'BLOG',
    b.id,
    parent.id,
    'Bạn có thể thêm đậu hũ để tăng lượng protein cho món nhé.',
    'VISIBLE',
    NOW() - INTERVAL 8 DAY,
    NOW() - INTERVAL 8 DAY
FROM blogs b
    JOIN comments parent
ON parent.target_id = b.id
    AND parent.target_type = 'BLOG'
    AND parent.content = 'Mình sẽ thử món cơm gạo lứt rau củ.'
WHERE b.title = '5 món chay đơn giản cho người mới bắt đầu'
  AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.parent_comment_id = parent.id
  AND c.content = 'Bạn có thể thêm đậu hũ để tăng lượng protein cho món nhé.'
    );


-- COMMENT BLOG 2
INSERT INTO comments
(
    author_id,
    target_type,
    target_id,
    parent_comment_id,
    content,
    status,
    created_at,
    updated_at
)
SELECT
    3,
    'BLOG',
    b.id,
    NULL,
    'Sữa đậu nành và yến mạch ăn sáng khá tiện.',
    'VISIBLE',
    NOW() - INTERVAL 6 DAY,
    NOW() - INTERVAL 6 DAY
FROM blogs b
WHERE b.title = 'Bữa sáng chay giàu protein nên ăn gì?'
  AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.target_type = 'BLOG'
  AND c.target_id = b.id
  AND c.author_id = 3
  AND c.content = 'Sữa đậu nành và yến mạch ăn sáng khá tiện.'
    );


-- COMMENT BLOG 3
INSERT INTO comments
(
    author_id,
    target_type,
    target_id,
    parent_comment_id,
    content,
    status,
    created_at,
    updated_at
)
SELECT
    1,
    'BLOG',
    b.id,
    NULL,
    'Salad này nhìn đơn giản mà đủ chất.',
    'VISIBLE',
    NOW() - INTERVAL 3 DAY,
    NOW() - INTERVAL 3 DAY
FROM blogs b
WHERE b.title = 'Cách làm salad đậu gà và bơ nhanh trong 15 phút'
  AND NOT EXISTS (
    SELECT 1
    FROM comments c
    WHERE c.target_type = 'BLOG'
  AND c.target_id = b.id
  AND c.author_id = 1
  AND c.content = 'Salad này nhìn đơn giản mà đủ chất.'
    );


-- ============================================================
-- 4. CONTENT VOTES
-- ============================================================


-- BLOG 1: user 2 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    2,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 9 DAY,
    NOW() - INTERVAL 9 DAY
FROM blogs b
WHERE b.title = '5 món chay đơn giản cho người mới bắt đầu'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 2
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 1: user 3 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    3,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 8 DAY,
    NOW() - INTERVAL 8 DAY
FROM blogs b
WHERE b.title = '5 món chay đơn giản cho người mới bắt đầu'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 3
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 2: user 1 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    1,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 6 DAY,
    NOW() - INTERVAL 6 DAY
FROM blogs b
WHERE b.title = 'Bữa sáng chay giàu protein nên ăn gì?'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 1
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 2: user 3 DOWNVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    3,
    'BLOG',
    b.id,
    -1,
    NOW() - INTERVAL 5 DAY,
    NOW() - INTERVAL 5 DAY
FROM blogs b
WHERE b.title = 'Bữa sáng chay giàu protein nên ăn gì?'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 3
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 3: user 1 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    1,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 3 DAY,
    NOW() - INTERVAL 3 DAY
FROM blogs b
WHERE b.title = 'Cách làm salad đậu gà và bơ nhanh trong 15 phút'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 1
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 3: user 2 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    2,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 2 DAY,
    NOW() - INTERVAL 2 DAY
FROM blogs b
WHERE b.title = 'Cách làm salad đậu gà và bơ nhanh trong 15 phút'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 2
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 3: user 3 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    3,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 1 DAY,
    NOW() - INTERVAL 1 DAY
FROM blogs b
WHERE b.title = 'Cách làm salad đậu gà và bơ nhanh trong 15 phút'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 3
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- BLOG 4: user 2 UPVOTE
INSERT INTO content_votes
(
    user_id,
    target_type,
    target_id,
    value,
    created_at,
    updated_at
)
SELECT
    2,
    'BLOG',
    b.id,
    1,
    NOW() - INTERVAL 1 DAY,
    NOW() - INTERVAL 1 DAY
FROM blogs b
WHERE b.title = 'Phở chay nấu tại nhà có khó không?'
  AND NOT EXISTS (
    SELECT 1
    FROM content_votes v
    WHERE v.user_id = 2
  AND v.target_type = 'BLOG'
  AND v.target_id = b.id
    );


-- ============================================================
-- 5. RECALCULATE BLOG VOTE SCORE
-- ============================================================

UPDATE blogs b
SET b.vote_score = COALESCE(
        (
            SELECT SUM(v.value)
            FROM content_votes v
            WHERE v.target_type = 'BLOG'
              AND v.target_id = b.id
        ),
        0
                   );