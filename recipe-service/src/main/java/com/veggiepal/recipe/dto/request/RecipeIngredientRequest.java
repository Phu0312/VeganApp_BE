package com.veggiepal.recipe.dto.request;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeIngredientRequest {

    @NotNull
    Long ingredientId;

    @NotNull
    @DecimalMin("0.01")
    BigDecimal quantity;

    @NotNull
    String unit;

    String note;
}