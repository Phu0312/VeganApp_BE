package com.veggiepal.recipe.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.*;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE)
@Entity
@Table(
        name = "ingredients",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_ingredients_normalized_name",
                        columnNames = "normalized_name"
                )
        },
        indexes = {
                @Index(
                        name = "idx_ingredients_name",
                        columnList = "name"
                ),
                @Index(
                        name = "idx_ingredients_vegan",
                        columnList = "vegan"
                ),
                @Index(
                        name = "idx_ingredients_allergen",
                        columnList = "allergen"
                )
        }
)
public class Ingredient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @Column(nullable = false, length = 150)
    String name;

    @Column(
            name = "normalized_name",
            nullable = false,
            length = 150
    )
    String normalizedName;

    @Column(length = 1000)
    String description;

    @Column(
            name = "calories_per_100g",
            precision = 10,
            scale = 2,
            nullable = false
    )
    BigDecimal caloriesPer100g;

    @Column(
            name = "protein_per_100g",
            precision = 10,
            scale = 2,
            nullable = false
    )
    BigDecimal proteinPer100g;

    @Column(
            name = "carbs_per_100g",
            precision = 10,
            scale = 2,
            nullable = false
    )
    BigDecimal carbsPer100g;

    @Column(
            name = "fat_per_100g",
            precision = 10,
            scale = 2,
            nullable = false
    )
    BigDecimal fatPer100g;

    @Column(
            name = "fiber_per_100g",
            precision = 10,
            scale = 2
    )
    BigDecimal fiberPer100g;

    @Column(nullable = false)
    Boolean vegan;

    @Column(nullable = false)
    Boolean allergen;

    @Column(name = "image_url", length = 512)
    String imageUrl;

    @Column(nullable = false)
    Boolean active;

    @Column(
            name = "created_at",
            nullable = false,
            updatable = false
    )
    LocalDateTime createdAt;

    @Column(
            name = "updated_at",
            nullable = false
    )
    LocalDateTime updatedAt;

    @PrePersist
    void prePersist() {

        LocalDateTime now = LocalDateTime.now();

        createdAt = now;
        updatedAt = now;

        if (active == null) {
            active = true;
        }

        if (vegan == null) {
            vegan = true;
        }

        if (allergen == null) {
            allergen = false;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}