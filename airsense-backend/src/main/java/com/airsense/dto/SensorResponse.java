package com.airsense.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SensorResponse {

    private Long id;
    private String deviceId;
    private Double temperature;
    private Double humidity;
    private Double co2;
    private Double smoke;
    private Integer aqi;
    private String aqiStatus; // Good, Moderate, Unhealthy for Sensitive Groups, Unhealthy, Very Unhealthy, Hazardous
    private LocalDateTime recordedAt;
}
