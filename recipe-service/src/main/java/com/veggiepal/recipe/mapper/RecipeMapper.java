package com.veggiepal.recipe.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.veggiepal.recipe.dto.response.RecipeIngredientResponse;
import com.veggiepal.recipe.dto.response.RecipeResponse;
import com.veggiepal.recipe.dto.response.RecipeStepResponse;
import com.veggiepal.recipe.entity.Recipe;
import com.veggiepal.recipe.entity.RecipeIngredient;
import com.veggiepal.recipe.entity.RecipeStep;

@Mapper(componentModel = "spring")
public interface RecipeMapper {

    @Mapping(
            target = "ingredients",
            source = "ingredients"
    )
    @Mapping(
            target = "steps",
            source = "steps"
    )
    RecipeResponse toRecipeResponse(
            Recipe recipe
    );

    @Mapping(
            target = "ingredientId",
            source = "ingredient.id"
    )
    @Mapping(
            target = "ingredientName",
            source = "ingredient.name"
    )
    RecipeIngredientResponse
    toRecipeIngredientResponse(
            RecipeIngredient recipeIngredient
    );

    RecipeStepResponse toRecipeStepResponse(
            RecipeStep recipeStep
    );
}