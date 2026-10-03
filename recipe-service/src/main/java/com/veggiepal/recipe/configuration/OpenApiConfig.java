package com.veggiepal.recipe.configuration;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.servers.Server;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI recipeOpenAPI() {

        return new OpenAPI()
                .addServersItem(
                        new Server()
                                .url("/api")
                                .description("API Gateway")
                );
    }
}