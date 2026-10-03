package com.veggiepal.recipe.dto.response;

import java.time.LocalDateTime;
import java.util.List;

import com.veggiepal.recipe.enums.RecipeStatus;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeResponse {

    Long id;

    Long userId;

    String title;

    String description;

    String imageUrl;

    Integer servings;

    Integer prepTime;

    Integer cookTime;

    RecipeStatus status;

    List<RecipeIngredientResponse> ingredients;

    List<RecipeStepResponse> steps;

    LocalDateTime createdAt;

    LocalDateTime updatedAt;

    LocalDateTime publishedAt;
}