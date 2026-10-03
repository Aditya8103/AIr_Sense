package com.airsense.repository;

import com.airsense.entity.SensorReading;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface SensorReadingRepository extends JpaRepository<SensorReading, Long> {

    // Get the single latest reading for a specific device
    Optional<SensorReading> findTopByDeviceIdOrderByRecordedAtDesc(String deviceId);

    // Get the overall single latest reading (if deviceId not specified)
    Optional<SensorReading> findTopByOrderByRecordedAtDesc();

    // Get readings for a device after a certain time (e.g. past 1 hour, 24 hours, 7 days)
    List<SensorReading> findByDeviceIdAndRecordedAtAfterOrderByRecordedAtAsc(String deviceId, LocalDateTime after);

    // Get readings after a certain time across all devices
    List<SensorReading> findByRecordedAtAfterOrderByRecordedAtAsc(LocalDateTime after);

    // Get latest N readings for a device
    List<SensorReading> findTop50ByDeviceIdOrderByRecordedAtDesc(String deviceId);

    // Get latest N readings overall
    List<SensorReading> findTop50ByOrderByRecordedAtDesc();
}
