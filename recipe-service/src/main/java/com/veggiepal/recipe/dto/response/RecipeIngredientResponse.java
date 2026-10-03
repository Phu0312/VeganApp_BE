package com.veggiepal.recipe.dto.response;

import java.math.BigDecimal;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeIngredientResponse {

    Long ingredientId;

    String ingredientName;

    BigDecimal quantity;

    String unit;

    String note;
}