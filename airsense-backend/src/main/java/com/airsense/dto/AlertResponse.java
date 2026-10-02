package com.airsense.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AlertResponse {

    private Long id;
    private String deviceId;
    private String alertType;
    private String message;
    private String severity;
    private Boolean isRead;
    private LocalDateTime createdAt;
}
