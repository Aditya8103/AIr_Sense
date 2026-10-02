package com.airsense.service;

import com.airsense.dto.AlertResponse;
import com.airsense.entity.Alert;
import com.airsense.repository.AlertRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AlertService {

    private final AlertRepository alertRepository;

    @Transactional
    public Alert createAlert(String deviceId, String alertType, String message, String severity) {
        // Prevent alert duplicate spam if an identical unread alert exists within past 10 minutes
        List<Alert> unread = alertRepository.findByDeviceIdOrderByCreatedAtDesc(deviceId);
        boolean recentDuplicate = unread.stream()
                .anyMatch(a -> !a.getIsRead()
                        && a.getAlertType().equalsIgnoreCase(alertType)
                        && a.getCreatedAt() != null
                        && a.getCreatedAt().isAfter(LocalDateTime.now().minusMinutes(10)));

        if (recentDuplicate) {
            log.debug("Skipping duplicate alert {} for device {}", alertType, deviceId);
            return null;
        }

        Alert alert = Alert.builder()
                .deviceId(deviceId)
                .alertType(alertType)
                .message(message)
                .severity(severity)
                .isRead(false)
                .createdAt(LocalDateTime.now())
                .build();

        Alert saved = alertRepository.save(alert);
        log.warn("Triggered {} Alert for device {}: {}", severity, deviceId, message);
        return saved;
    }

    public List<AlertResponse> getAllAlerts(String deviceId) {
        List<Alert> alerts = (deviceId != null && !deviceId.isBlank())
                ? alertRepository.findByDeviceIdOrderByCreatedAtDesc(deviceId)
                : alertRepository.findAllByOrderByCreatedAtDesc();

        return alerts.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional
    public Optional<AlertResponse> markAsRead(Long alertId) {
        return alertRepository.findById(alertId).map(alert -> {
            alert.setIsRead(true);
            return mapToResponse(alertRepository.save(alert));
        });
    }

    public long getUnreadCount() {
        return alertRepository.countByIsReadFalse();
    }

    private AlertResponse mapToResponse(Alert a) {
        return AlertResponse.builder()
                .id(a.getId())
                .deviceId(a.getDeviceId())
                .alertType(a.getAlertType())
                .message(a.getMessage())
                .severity(a.getSeverity())
                .isRead(a.getIsRead())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
