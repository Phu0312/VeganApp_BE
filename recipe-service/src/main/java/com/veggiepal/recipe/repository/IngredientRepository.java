package com.veggiepal.recipe.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.veggiepal.recipe.entity.Ingredient;

@Repository
public interface IngredientRepository extends JpaRepository<Ingredient, Long> {

    Optional<Ingredient> findByNormalizedName(String normalizedName);

    boolean existsByNormalizedName(String normalizedName);

    boolean existsByNormalizedNameAndIdNot(String normalizedName, Long id);

    @Query("""
            select i
            from Ingredient i
            where i.active = true
              and (:keyword is null
                   or lower(i.name)
                   like lower(concat('%', :keyword, '%')))
              and (:vegan is null or i.vegan = :vegan)
              and (:allergen is null or i.allergen = :allergen)
            """)
    Page<Ingredient> search(
            @Param("keyword") String keyword,
            @Param("vegan") Boolean vegan,
            @Param("allergen") Boolean allergen,
            Pageable pageable
    );
}