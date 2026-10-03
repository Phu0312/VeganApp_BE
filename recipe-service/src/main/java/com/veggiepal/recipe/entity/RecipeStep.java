package com.veggiepal.recipe.entity;

import jakarta.persistence.*;

import lombok.*;
import lombok.experimental.FieldDefaults;

@Entity
@Table(
        name = "recipe_steps",
        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_recipe_step_number",
                        columnNames = {
                                "recipe_id",
                                "step_number"
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
public class RecipeStep {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(
            name = "recipe_id",
            nullable = false
    )
    Recipe recipe;

    @Column(
            name = "step_number",
            nullable = false
    )
    Integer stepNumber;

    @Column(
            nullable = false,
            length = 2000
    )
    String instruction;
}