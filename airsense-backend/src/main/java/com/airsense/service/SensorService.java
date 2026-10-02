package com.airsense.service;

import com.airsense.dto.SensorDataRequest;
import com.airsense.dto.SensorResponse;
import com.airsense.entity.SensorReading;
import com.airsense.repository.SensorReadingRepository;
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
public class SensorService {

    private final SensorReadingRepository sensorReadingRepository;
    private final DeviceService deviceService;
    private final AlertService alertService;

    private static final String DEFAULT_DEVICE_ID = "ESP32_AIR_01";

    @Transactional
    public SensorResponse saveReading(SensorDataRequest request) {
        String deviceId = (request.getDeviceId() != null && !request.getDeviceId().isBlank())
                ? request.getDeviceId()
                : DEFAULT_DEVICE_ID;

        // Smoke / gas value normalization
        double smokeValue = request.getSmoke() != null
                ? request.getSmoke()
                : (request.getGasValue() != null ? request.getGasValue() : 0.0);

        // Auto-calculate AQI if not provided
        int aqi = request.getAqi() != null ? request.getAqi() : calculateAqi(request.getCo2(), smokeValue);

        SensorReading reading = SensorReading.builder()
                .deviceId(deviceId)
                .temperature(request.getTemperature())
                .humidity(request.getHumidity())
                .co2(request.getCo2())
                .smoke(smokeValue)
                .aqi(aqi)
                .recordedAt(LocalDateTime.now())
                .build();

        SensorReading saved = sensorReadingRepository.save(reading);
        log.info("Saved sensor reading ID: {} for device: {}", saved.getId(), deviceId);

        // Update device status to ONLINE
        deviceService.recordDeviceActivity(deviceId);

        // Evaluate automated alerts based on thresholds
        evaluateAlerts(saved);

        return mapToResponse(saved);
    }

    public Optional<SensorResponse> getLatestReading(String deviceId) {
        Optional<SensorReading> reading = (deviceId != null && !deviceId.isBlank())
                ? sensorReadingRepository.findTopByDeviceIdOrderByRecordedAtDesc(deviceId)
                : sensorReadingRepository.findTopByOrderByRecordedAtDesc();

        return reading.map(this::mapToResponse);
    }

    public List<SensorResponse> getHistory(String deviceId, String range) {
        LocalDateTime cutoff = resolveCutoff(range);

        List<SensorReading> readings = (deviceId != null && !deviceId.isBlank())
                ? sensorReadingRepository.findByDeviceIdAndRecordedAtAfterOrderByRecordedAtAsc(deviceId, cutoff)
                : sensorReadingRepository.findByRecordedAtAfterOrderByRecordedAtAsc(cutoff);

        return readings.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    public List<SensorResponse> getRecentReadings(String deviceId) {
        List<SensorReading> readings = (deviceId != null && !deviceId.isBlank())
                ? sensorReadingRepository.findTop50ByDeviceIdOrderByRecordedAtDesc(deviceId)
                : sensorReadingRepository.findTop50ByOrderByRecordedAtDesc();

        return readings.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    private void evaluateAlerts(SensorReading reading) {
        // 1. AQI Threshold
        if (reading.getAqi() >= 200) {
            alertService.createAlert(
                    reading.getDeviceId(),
                    "VERY_UNHEALTHY_AQI",
                    "Hazardous AQI detected: " + reading.getAqi() + ". Avoid outdoor exposure!",
                    "CRITICAL"
            );
        } else if (reading.getAqi() >= 150) {
            alertService.createAlert(
                    reading.getDeviceId(),
                    "UNHEALTHY_AQI",
                    "High AQI detected: " + reading.getAqi() + ". Air quality is poor.",
                    "WARNING"
            );
        }

        // 2. CO2 Threshold (Normal indoor is 400-800, >1000 is poor ventilation)
        if (reading.getCo2() >= 1200) {
            alertService.createAlert(
                    reading.getDeviceId(),
                    "HIGH_CO2",
                    "Elevated CO2 level: " + reading.getCo2().intValue() + " ppm. Ventilation recommended.",
                    "WARNING"
            );
        }

        // 3. Smoke/Gas Threshold
        if (reading.getSmoke() >= 0.08) {
            alertService.createAlert(
                    reading.getDeviceId(),
                    "SMOKE_DETECTED",
                    "Elevated smoke / harmful gas level detected: " + String.format("%.2f", reading.getSmoke()),
                    "CRITICAL"
            );
        }

        // 4. High Temperature Threshold
        if (reading.getTemperature() >= 42.0) {
            alertService.createAlert(
                    reading.getDeviceId(),
                    "HIGH_TEMPERATURE",
                    "High ambient temperature: " + String.format("%.1f", reading.getTemperature()) + "°C",
                    "WARNING"
            );
        }
    }

    private int calculateAqi(double co2, double smoke) {
        // Standard baseline mapping: 400ppm -> ~30 AQI, 1000ppm -> ~100 AQI
        int calculated = (int) Math.round((co2 / 10.0) + (smoke * 500.0));
        return Math.max(10, Math.min(500, calculated));
    }

    private LocalDateTime resolveCutoff(String range) {
        if (range == null) return LocalDateTime.now().minusHours(24);
        return switch (range.toUpperCase()) {
            case "1H" -> LocalDateTime.now().minusHours(1);
            case "7D" -> LocalDateTime.now().minusDays(7);
            case "30D" -> LocalDateTime.now().minusDays(30);
            default -> LocalDateTime.now().minusHours(24); // 24H default
        };
    }

    private SensorResponse mapToResponse(SensorReading r) {
        return SensorResponse.builder()
                .id(r.getId())
                .deviceId(r.getDeviceId())
                .temperature(r.getTemperature())
                .humidity(r.getHumidity())
                .co2(r.getCo2())
                .smoke(r.getSmoke())
                .aqi(r.getAqi())
                .aqiStatus(resolveAqiStatus(r.getAqi()))
                .recordedAt(r.getRecordedAt())
                .build();
    }

    private String resolveAqiStatus(int aqi) {
        if (aqi <= 50) return "Good";
        if (aqi <= 100) return "Moderate";
        if (aqi <= 150) return "Unhealthy for Sensitive Groups";
        if (aqi <= 200) return "Unhealthy";
        if (aqi <= 300) return "Very Unhealthy";
        return "Hazardous";
    }
}
