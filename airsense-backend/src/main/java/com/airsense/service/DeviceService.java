package com.airsense.service;

import com.airsense.dto.DeviceRequest;
import com.airsense.entity.Device;
import com.airsense.repository.DeviceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class DeviceService {

    private final DeviceRepository deviceRepository;

    @Transactional
    public Device registerOrUpdateDevice(DeviceRequest request) {
        return deviceRepository.findByDeviceId(request.getDeviceId())
                .map(existing -> {
                    existing.setDeviceName(request.getDeviceName());
                    if (request.getLocation() != null) {
                        existing.setLocation(request.getLocation());
                    }
                    return deviceRepository.save(existing);
                })
                .orElseGet(() -> deviceRepository.save(
                        Device.builder()
                                .deviceId(request.getDeviceId())
                                .deviceName(request.getDeviceName())
                                .location(request.getLocation())
                                .status("ONLINE")
                                .lastActiveAt(LocalDateTime.now())
                                .build()
                ));
    }

    @Transactional
    public void recordDeviceActivity(String deviceId) {
        deviceRepository.findByDeviceId(deviceId).ifPresentOrElse(
                device -> {
                    device.setStatus("ONLINE");
                    device.setLastActiveAt(LocalDateTime.now());
                    deviceRepository.save(device);
                },
                () -> {
                    // Auto-register device if unknown
                    deviceRepository.save(
                            Device.builder()
                                    .deviceId(deviceId)
                                    .deviceName("AirSense Node (" + deviceId + ")")
                                    .location("Default Location")
                                    .status("ONLINE")
                                    .lastActiveAt(LocalDateTime.now())
                                    .build()
                    );
                }
        );
    }

    public List<Device> getAllDevices() {
        return deviceRepository.findAll();
    }

    public Optional<Device> getDeviceByDeviceId(String deviceId) {
        return deviceRepository.findByDeviceId(deviceId);
    }
}
