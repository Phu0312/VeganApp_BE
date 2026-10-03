package com.veggiepal.recipe.dto.request;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeRequest {

    @NotBlank
    String title;

    String description;

    String imageUrl;

    @NotNull
    @Min(1)
    Integer servings;

    @Min(0)
    Integer prepTime;

    @Min(0)
    Integer cookTime;

    @NotEmpty
    List<@Valid RecipeIngredientRequest> ingredients;

    @NotEmpty
    List<@Valid RecipeStepRequest> steps;
}