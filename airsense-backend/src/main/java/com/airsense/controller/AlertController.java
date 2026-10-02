package com.airsense.controller;

import com.airsense.dto.AlertResponse;
import com.airsense.dto.ApiResponse;
import com.airsense.service.AlertService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alerts")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AlertController {

    private final AlertService alertService;

    /**
     * Get alerts list (for mobile AlertsScreen)
     * GET /api/alerts?deviceId=...
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<AlertResponse>>> getAlerts(
            @RequestParam(required = false) String deviceId) {
        List<AlertResponse> alerts = alertService.getAllAlerts(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(alerts));
    }

    /**
     * Mark an alert as read
     * PUT /api/alerts/{id}/read
     */
    @PutMapping("/{id}/read")
    public ResponseEntity<ApiResponse<AlertResponse>> markAsRead(@PathVariable Long id) {
        return alertService.markAsRead(id)
                .map(alert -> ResponseEntity.ok(ApiResponse.ok("Alert marked as read", alert)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    /**
     * Get count of unread alerts
     * GET /api/alerts/unread-count
     */
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount() {
        long count = alertService.getUnreadCount();
        return ResponseEntity.ok(ApiResponse.ok(count));
    }
}
