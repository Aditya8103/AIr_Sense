package com.airsense.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.*;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HotspotResponseDto {

    @JsonProperty("total_nodes")
    private Integer totalNodes;

    @JsonProperty("critical_count")
    private Integer criticalCount;

    @JsonProperty("ranked_nodes")
    private List<PredictionResponseDto> rankedNodes;
}
