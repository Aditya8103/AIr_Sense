package com.airsense.dto;

import jakarta.validation.constraints.NotNull;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SensorDataRequest {

    private String deviceId;

    @NotNull(message = "Temperature is required")
    private Double temperature;

    @NotNull(message = "Humidity is required")
    private Double humidity;

    @NotNull(message = "CO2 level is required")
    private Double co2;

    private Double smoke;
    
    // Gas value alternative name from ESP32 MQ135
    private Double gasValue;

    private Integer aqi;
}
