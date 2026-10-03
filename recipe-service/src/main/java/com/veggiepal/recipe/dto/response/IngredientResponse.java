package com.veggiepal.recipe.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class IngredientResponse {

    Long id;

    String name;

    String description;

    BigDecimal caloriesPer100g;

    BigDecimal proteinPer100g;

    BigDecimal carbsPer100g;

    BigDecimal fatPer100g;

    BigDecimal fiberPer100g;

    Boolean vegan;

    Boolean allergen;

    String imageUrl;

    Boolean active;

    LocalDateTime createdAt;

    LocalDateTime updatedAt;
}