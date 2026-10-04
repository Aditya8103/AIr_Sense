package com.airsense.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PredictionResponseDto {

    @JsonProperty("device_id")
    private String deviceId;

    private String location;

    @JsonProperty("current_pm25")
    private Double currentPm25;

    @JsonProperty("predicted_pm25")
    private Double predictedPm25;

    @JsonProperty("prediction_horizon")
    private String predictionHorizon;

    private String trend;

    @JsonProperty("risk_level")
    private String riskLevel;

    @JsonProperty("recommended_action")
    private String recommendedAction;

    @JsonProperty("model_version")
    private String modelVersion;

    private String algorithm;
}
