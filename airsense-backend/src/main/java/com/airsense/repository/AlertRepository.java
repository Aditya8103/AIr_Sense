package com.airsense.repository;

import com.airsense.entity.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlertRepository extends JpaRepository<Alert, Long> {

    List<Alert> findAllByOrderByCreatedAtDesc();

    List<Alert> findByDeviceIdOrderByCreatedAtDesc(String deviceId);

    List<Alert> findByIsReadFalseOrderByCreatedAtDesc();

    long countByIsReadFalse();
}
