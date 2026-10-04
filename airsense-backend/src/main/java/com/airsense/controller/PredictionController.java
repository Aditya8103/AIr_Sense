package com.airsense.controller;

import com.airsense.dto.ApiResponse;
import com.airsense.dto.HotspotResponseDto;
import com.airsense.dto.PredictionResponseDto;
import com.airsense.service.AiService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PredictionController {

    private final AiService aiService;

    /**
     * Get Latest 1-Hour AI Prediction
     * GET /api/predictions/latest?deviceId=...
     */
    @GetMapping("/predictions/latest")
    public ResponseEntity<ApiResponse<PredictionResponseDto>> getLatestPrediction(
            @RequestParam(required = false) String deviceId) {
        PredictionResponseDto prediction = aiService.getPrediction(deviceId);
        return ResponseEntity.ok(ApiResponse.ok("AI Prediction retrieved successfully", prediction));
    }

    /**
     * Get Citywide Ranked Hotspot Analysis
     * GET /api/hotspots
     */
    @GetMapping("/hotspots")
    public ResponseEntity<ApiResponse<HotspotResponseDto>> getHotspots() {
        HotspotResponseDto hotspots = aiService.getHotspots();
        return ResponseEntity.ok(ApiResponse.ok("Hotspots analysis retrieved successfully", hotspots));
    }
}
