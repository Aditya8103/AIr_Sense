package com.airsense.controller;

import com.airsense.dto.ApiResponse;
import com.airsense.dto.SensorDataRequest;
import com.airsense.dto.SensorResponse;
import com.airsense.service.SensorService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sensors")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SensorController {

    private final SensorService sensorService;

    /**
     * Ingest telemetry from ESP32 or simulation
     * POST /api/sensors/data
     */
    @PostMapping("/data")
    public ResponseEntity<ApiResponse<SensorResponse>> ingestData(@Valid @RequestBody SensorDataRequest request) {
        SensorResponse response = sensorService.saveReading(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Telemetry recorded successfully", response));
    }

    /**
     * Get latest sensor reading for live dashboard
     * GET /api/sensors/latest?deviceId=...
     */
    @GetMapping("/latest")
    public ResponseEntity<ApiResponse<SensorResponse>> getLatest(
            @RequestParam(required = false) String deviceId) {
        return sensorService.getLatestReading(deviceId)
                .map(reading -> ResponseEntity.ok(ApiResponse.ok(reading)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error("No sensor data available yet")));
    }

    /**
     * Get historical readings for charts (1H, 24H, 7D, 30D)
     * GET /api/sensors/history?deviceId=...&range=24H
     */
    @GetMapping("/history")
    public ResponseEntity<ApiResponse<List<SensorResponse>>> getHistory(
            @RequestParam(required = false) String deviceId,
            @RequestParam(defaultValue = "24H") String range) {
        List<SensorResponse> history = sensorService.getHistory(deviceId, range);
        return ResponseEntity.ok(ApiResponse.ok(history));
    }

    /**
     * Get recent readings
     * GET /api/sensors/recent?deviceId=...
     */
    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<List<SensorResponse>>> getRecent(
            @RequestParam(required = false) String deviceId) {
        List<SensorResponse> readings = sensorService.getRecentReadings(deviceId);
        return ResponseEntity.ok(ApiResponse.ok(readings));
    }
}
