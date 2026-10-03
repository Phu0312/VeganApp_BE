package com.veggiepal.recipe.entity;

import java.math.BigDecimal;

import jakarta.persistence.*;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(
        name = "recipe_ingredients",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_recipe_ingredient",
                        columnNames = {
                                "recipe_id",
                                "ingredient_id"
                        }
                )
        }
)
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
public class RecipeIngredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "recipe_id",
            nullable = false
    )
    Recipe recipe;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "ingredient_id",
            nullable = false
    )
    Ingredient ingredient;

    @Column(
            nullable = false,
            precision = 10,
            scale = 2
    )
    BigDecimal quantity;

    @Column(nullable = false, length = 30)
    String unit;

    @Column(length = 300)
    String note;
}