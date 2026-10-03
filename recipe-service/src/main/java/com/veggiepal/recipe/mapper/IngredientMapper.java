package com.veggiepal.recipe.mapper;

import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import com.veggiepal.recipe.dto.request.IngredientRequest;
import com.veggiepal.recipe.dto.response.IngredientResponse;
import com.veggiepal.recipe.entity.Ingredient;

@Mapper(componentModel = "spring")
public interface IngredientMapper {

    Ingredient toIngredient(IngredientRequest request);

    IngredientResponse toIngredientResponse(Ingredient ingredient);

    @BeanMapping(
            nullValuePropertyMappingStrategy =
                    NullValuePropertyMappingStrategy.IGNORE
    )
    void updateIngredient(
            @MappingTarget Ingredient ingredient,
            IngredientRequest request
    );
}