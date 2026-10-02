package com.airsense.controller;

import com.airsense.dto.ApiResponse;
import com.airsense.dto.DeviceRequest;
import com.airsense.entity.Device;
import com.airsense.service.DeviceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/devices")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class DeviceController {

    private final DeviceService deviceService;

    /**
     * Get all registered AirSense devices
     * GET /api/devices
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<Device>>> getAllDevices() {
        return ResponseEntity.ok(ApiResponse.ok(deviceService.getAllDevices()));
    }

    /**
     * Register or update a device
     * POST /api/devices
     */
    @PostMapping
    public ResponseEntity<ApiResponse<Device>> registerDevice(@Valid @RequestBody DeviceRequest request) {
        Device device = deviceService.registerOrUpdateDevice(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Device registered successfully", device));
    }

    /**
     * Get device by ID
     * GET /api/devices/{deviceId}
     */
    @GetMapping("/{deviceId}")
    public ResponseEntity<ApiResponse<Device>> getDevice(@PathVariable String deviceId) {
        return deviceService.getDeviceByDeviceId(deviceId)
                .map(d -> ResponseEntity.ok(ApiResponse.ok(d)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(ApiResponse.error("Device not found")));
    }
}
