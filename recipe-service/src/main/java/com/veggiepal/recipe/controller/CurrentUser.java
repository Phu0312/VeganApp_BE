package com.veggiepal.recipe.controller;

import org.springframework.security.oauth2.jwt.Jwt;

import com.veggiepal.recipe.exception.AppException;
import com.veggiepal.recipe.exception.ErrorCode;

public final class CurrentUser {

    private CurrentUser() {
    }

    public static Long id(
            Jwt jwt
    ) {

        Object userId =
                jwt.getClaim("userId");

        if (userId instanceof Number number) {
            return number.longValue();
        }

        if (userId instanceof String value) {

            try {
                return Long.valueOf(value);
            } catch (NumberFormatException ignored) {
            }
        }

        throw new AppException(
                ErrorCode.UNAUTHENTICATED
        );
    }

    public static boolean isAdmin(
            Jwt jwt
    ) {

        String role =
                jwt.getClaimAsString(
                        "role"
                );

        return "ADMIN".equals(role);
    }
}