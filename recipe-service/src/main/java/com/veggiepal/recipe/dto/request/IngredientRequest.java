package com.veggiepal.recipe.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class IngredientRequest {

    @NotBlank(message = "INGREDIENT_NAME_REQUIRED")
    @Size(max = 150, message = "INVALID_INGREDIENT_NAME")
    String name;

    @Size(max = 1000, message = "INVALID_INGREDIENT_DESCRIPTION")
    String description;

    @NotNull(message = "CALORIES_REQUIRED")
    @DecimalMin(
            value = "0.0",
            inclusive = true,
            message = "INVALID_NUTRITION_VALUE"
    )
    BigDecimal caloriesPer100g;

    @NotNull(message = "PROTEIN_REQUIRED")
    @DecimalMin(
            value = "0.0",
            inclusive = true,
            message = "INVALID_NUTRITION_VALUE"
    )
    BigDecimal proteinPer100g;

    @NotNull(message = "CARBS_REQUIRED")
    @DecimalMin(
            value = "0.0",
            inclusive = true,
            message = "INVALID_NUTRITION_VALUE"
    )
    BigDecimal carbsPer100g;

    @NotNull(message = "FAT_REQUIRED")
    @DecimalMin(
            value = "0.0",
            inclusive = true,
            message = "INVALID_NUTRITION_VALUE"
    )
    BigDecimal fatPer100g;

    @DecimalMin(
            value = "0.0",
            inclusive = true,
            message = "INVALID_NUTRITION_VALUE"
    )
    BigDecimal fiberPer100g;

    Boolean vegan;

    Boolean allergen;

    Boolean active;
}