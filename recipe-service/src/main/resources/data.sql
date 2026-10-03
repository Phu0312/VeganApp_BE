-- ============================================================
-- VEGGIEPAL RECIPE SERVICE - SAMPLE DATA
-- ============================================================


-- ============================================================
-- 1. INGREDIENTS
-- ============================================================

INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Đậu hũ',
    'dau hu',
    'Đậu hũ làm từ đậu nành',
    76,
    8.1,
    1.9,
    4.8,
    0.3,
    TRUE,
    TRUE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'dau hu'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Gạo lứt',
    'gao lut',
    'Gạo lứt nguyên cám',
    370,
    7.9,
    77.2,
    2.9,
    3.5,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'gao lut'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Cà chua',
    'ca chua',
    'Cà chua tươi giàu vitamin',
    18,
    0.9,
    3.9,
    0.2,
    1.2,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'ca chua'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Bông cải xanh',
    'bong cai xanh',
    'Bông cải xanh giàu chất xơ',
    34,
    2.8,
    6.6,
    0.4,
    2.6,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'bong cai xanh'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Cà rốt',
    'ca rot',
    'Cà rốt tươi',
    41,
    0.9,
    9.6,
    0.2,
    2.8,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'ca rot'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Đậu gà',
    'dau ga',
    'Đậu gà giàu protein thực vật',
    164,
    8.9,
    27.4,
    2.6,
    7.6,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'dau ga'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Bơ',
    'bo',
    'Quả bơ giàu chất béo không bão hòa',
    160,
    2.0,
    8.5,
    14.7,
    6.7,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'bo'
);


INSERT INTO ingredients
(
    name,
    normalized_name,
    description,
    calories_per_100g,
    protein_per_100g,
    carbs_per_100g,
    fat_per_100g,
    fiber_per_100g,
    vegan,
    allergen,
    active,
    created_at,
    updated_at
)
SELECT
    'Rau chân vịt',
    'rau chan vit',
    'Rau chân vịt giàu vitamin và khoáng chất',
    23,
    2.9,
    3.6,
    0.4,
    2.2,
    TRUE,
    FALSE,
    TRUE,
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM ingredients
    WHERE normalized_name = 'rau chan vit'
);


-- ============================================================
-- 2. RECIPE 1
-- CƠM GẠO LỨT ĐẬU HŨ
-- ============================================================

INSERT INTO recipes
(
    user_id,
    title,
    description,
    image_url,
    servings,
    prep_time,
    cook_time,
    status,
    created_at,
    updated_at,
    published_at
)
SELECT
    1,
    'Cơm gạo lứt đậu hũ',
    'Món cơm gạo lứt kết hợp đậu hũ và rau củ, phù hợp cho bữa ăn chay lành mạnh.',
    'https://images.unsplash.com/photo-1547592180-85f173990554',
    2,
    15,
    30,
    'PUBLISHED',
    NOW(),
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM recipes
    WHERE title = 'Cơm gạo lứt đậu hũ'
);


-- Đậu hũ 200g
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    200,
    'GRAM',
    'Cắt thành miếng vuông'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'dau hu'
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Gạo lứt 150g
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    150,
    'GRAM',
    'Vo sạch trước khi nấu'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'gao lut'
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Cà chua 100g
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    100,
    'GRAM',
    'Rửa sạch và cắt lát'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'ca chua'
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Bông cải xanh 100g
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    100,
    'GRAM',
    'Cắt miếng vừa ăn'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'bong cai xanh'
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Cà rốt 80g
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    80,
    'GRAM',
    'Cắt lát mỏng'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'ca rot'
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- ============================================================
-- RECIPE 1 STEPS
-- ============================================================

INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    1,
    'Vo sạch gạo lứt và nấu chín.'
FROM recipes r
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 1
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    2,
    'Cắt đậu hũ thành miếng và áp chảo vàng hai mặt.'
FROM recipes r
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 2
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    3,
    'Hấp bông cải xanh và cà rốt cho vừa chín.'
FROM recipes r
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 3
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    4,
    'Sơ chế và cắt cà chua thành lát.'
FROM recipes r
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 4
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    5,
    'Cho cơm, đậu hũ và rau củ ra đĩa rồi thưởng thức.'
FROM recipes r
WHERE r.title = 'Cơm gạo lứt đậu hũ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 5
);


-- ============================================================
-- 3. RECIPE 2
-- SALAD ĐẬU GÀ VÀ BƠ
-- ============================================================

INSERT INTO recipes
(
    user_id,
    title,
    description,
    image_url,
    servings,
    prep_time,
    cook_time,
    status,
    created_at,
    updated_at,
    published_at
)
SELECT
    1,
    'Salad đậu gà và bơ',
    'Salad chay giàu protein và chất xơ từ đậu gà, bơ và rau xanh.',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd',
    2,
    15,
    5,
    'PUBLISHED',
    NOW(),
    NOW(),
    NOW()
    WHERE NOT EXISTS (
    SELECT 1
    FROM recipes
    WHERE title = 'Salad đậu gà và bơ'
);


-- Đậu gà
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    200,
    'GRAM',
    'Luộc chín'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'dau ga'
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Cà chua
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    100,
    'GRAM',
    'Cắt nhỏ'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'ca chua'
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Bơ
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    100,
    'GRAM',
    'Cắt thành khối nhỏ'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'bo'
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- Rau chân vịt
INSERT INTO recipe_ingredients
(
    recipe_id,
    ingredient_id,
    quantity,
    unit,
    note
)
SELECT
    r.id,
    i.id,
    80,
    'GRAM',
    'Rửa sạch và để ráo'
FROM recipes r
         JOIN ingredients i
              ON i.normalized_name = 'rau chan vit'
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_ingredients ri
    WHERE ri.recipe_id = r.id
      AND ri.ingredient_id = i.id
);


-- ============================================================
-- RECIPE 2 STEPS
-- ============================================================

INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    1,
    'Rửa sạch rau chân vịt và để ráo.'
FROM recipes r
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 1
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    2,
    'Cho đậu gà đã luộc vào tô.'
FROM recipes r
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 2
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    3,
    'Thêm cà chua và bơ đã cắt vào tô.'
FROM recipes r
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 3
);


INSERT INTO recipe_steps
(
    recipe_id,
    step_number,
    instruction
)
SELECT
    r.id,
    4,
    'Thêm rau chân vịt và trộn đều tất cả nguyên liệu.'
FROM recipes r
WHERE r.title = 'Salad đậu gà và bơ'
  AND NOT EXISTS (
    SELECT 1
    FROM recipe_steps rs
    WHERE rs.recipe_id = r.id
      AND rs.step_number = 4
);