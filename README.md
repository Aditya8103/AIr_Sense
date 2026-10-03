# 🌬️ AirSense — Precision IoT Air Quality Monitoring System

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.4-brightgreen.svg?logo=springboot)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg?logo=openjdk)](https://www.oracle.com/java/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg?logo=dart)](https://dart.dev/)
[![MySQL](https://img.shields.io/badge/MySQL-8.x%20(Aiven%20Cloud)-4479A1.svg?logo=mysql)](https://aiven.io/mysql)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows%20%7C%20macOS-blue.svg)](#)

**AirSense** is a full-stack, enterprise-grade IoT environmental monitoring platform designed to capture, process, analyze, and visualize real-time air quality metrics. It seamlessly connects hardware sensor nodes (ESP32 with MQ135 & DHT11) to a robust Spring Boot REST backend, persistent cloud storage on Aiven MySQL, and an intuitive, cross-platform Flutter application.

---

## 📌 Table of Contents

- [System Architecture](#-system-architecture)
- [Project Evolution & Transition](#-project-evolution--transition)
- [Key Features Implemented](#-key-features-implemented)
  - [1. Backend Service (`airsense-backend`)](#1-backend-service-airsense-backend)
  - [2. Frontend Application (`Frontend`)](#2-frontend-application-frontend)
  - [3. Database & Cloud Infrastructure](#3-database--cloud-infrastructure)
  - [4. Automated Health & Alert Engine](#4-automated-health--alert-engine)
- [Project Directory Structure](#-project-directory-structure)
- [REST API Reference](#-rest-api-reference)
- [IoT Device Payload & Hardware Integration](#-iot-device-payload--hardware-integration)
- [Getting Started](#-getting-started)
  - [Backend Setup](#backend-setup)
  - [Frontend Setup](#frontend-setup)

---

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph IoT Hardware Layer
        ESP32[ESP32 Microcontroller]
        MQ135[MQ135 Gas / Smoke / CO2 Sensor]
        DHT11[DHT11 Temperature & Humidity Sensor]
        MQ135 --> ESP32
        DHT11 --> ESP32
    end

    subgraph Backend Microservice (Spring Boot 3.3.4 + Java 21)
        API[Spring Boot REST API :8080]
        SensorSvc[Sensor Service & AQI Calculator]
        AlertSvc[Automated Alert Engine]
        DeviceSvc[Device Lifecycle & Heartbeat]
        AuthSvc[Authentication Service]

        ESP32 -- "POST /api/sensors/data" --> API
        API --> SensorSvc
        SensorSvc --> AlertSvc
        SensorSvc --> DeviceSvc
    end

    subgraph Cloud Persistence Layer
        AivenDB[(Aiven Cloud MySQL 8.x)]
        API <-->|HikariCP / JPA Hibernate| AivenDB
    end

    subgraph Client Application Layer (Flutter 3.x)
        FlutterApp[AirSense Cross-Platform App]
        Dashboard[Live Metrics Dashboard]
        Analytics[Historical Charts (fl_chart)]
        AlertsView[Alerts & Notifications Screen]
        ProfileView[Device Status & Settings]

        FlutterApp --> Dashboard
        FlutterApp --> Analytics
        FlutterApp --> AlertsView
        FlutterApp --> ProfileView
        FlutterApp <-->|ApiService (HTTP REST & Polling Stream)| API
    end
```

---

## 🔄 Architecture & Backend

The architecture is built on a custom **Spring Boot + Cloud MySQL** backend to achieve:
- **Full Data Ownership**: Eliminates vendor lock-in with a relational SQL schema.
- **Server-Side Business Logic**: Automatic AQI calculation, sensor telemetry normalization, and server-side threshold alert dispatch.
- **Device Management**: Explicit device registration, heartbeat monitoring, and activity timestamps.
- **High-Performance Querying**: Indexed time-series queries for 1-hour, 24-hour, 7-day, and 30-day analytics charts.
- **Cross-Platform Networking**: Clean network abstraction in Flutter via `ApiService` routing to `10.0.2.2:8080` for Android emulators and `localhost:8080` for Web/Desktop.

---

## 🚀 Key Features Implemented

### 1. Backend Service (`airsense-backend`)
- **Modern Spring Boot 3.3.4 & Java 21**: High-performance REST microservice using Spring Data JPA and Hibernate.
- **Cloud Database Integration**: Connected to high-availability Aiven Cloud MySQL with HikariCP connection pooling and automatic schema management (`update`).
- **Telemetry Ingestion Engine**:
  - Ingests temperature, humidity, CO2, smoke, and gas levels from IoT hardware.
  - Automatically calculates AQI if not supplied by the sensor node.
  - Categorizes readings into standardized health statuses (*Good*, *Moderate*, *Unhealthy for Sensitive Groups*, *Unhealthy*, *Very Unhealthy*, *Hazardous*).
- **Automated Threshold Alerting**:
  - Generates instant notifications for dangerous environmental conditions.
- **Device Lifecycle & Status**:
  - Automatically tracks device heartbeats and marks devices as `ONLINE` with updated timestamps upon each telemetry post.
- **User Authentication**:
  - User registration and login endpoints with secure password handling.
- **Enterprise Standards**:
  - Standardized JSON responses via `ApiResponse<T>`.
  - Global error handling via `@RestControllerAdvice` (`GlobalExceptionHandler`).
  - Cross-Origin Resource Sharing (`CorsConfig`) configured for Web, Mobile, and Desktop clients.

### 2. Frontend Application (`Frontend`)
- **Flutter 3 (Dart 3)**: Single codebase targeting Android, iOS, Web, and Desktop.
- **Custom `ApiService` Integration**:
  - Reactive streams (`getSensorStream()`) using dynamic periodic polling.
  - Automatic platform-aware base URL resolution (`10.0.2.2:8080` on Android emulator vs `localhost:8080` on web/desktop).
- **Real-Time Dashboard (`DashboardScreen`)**:
  - Live metric cards for AQI, Temperature, Humidity, CO2, and Smoke.
  - Dynamic visual indicators, AQI status chips, and contextual environmental health tips.
- **Interactive Analytics (`AnalyticsScreen`)**:
  - Built with `fl_chart` for smooth line/area chart visualizations.
  - Interactive filter chips supporting multiple time ranges: `1H`, `24H`, `7D`, `30D`, and `CUSTOM`.
- **Alert Center (`AlertsScreen`)**:
  - Chronological list of safety warnings and critical alarms.
  - Color-coded severity tags (`CRITICAL`, `WARNING`, `INFO`).
  - Ability to mark alerts as acknowledged/read.
- **Profile & Device Management (`ProfileScreen`)**:
  - Live device connectivity indicator (`ONLINE` / `OFFLINE`).
  - Notification switches, theme preferences, and hardware metadata display.
- **Design System & Theme**:
  - Polished modern dark aesthetic (`AppColors`, `AppTheme`, `TextStyles`).
  - Reusable modular components (`SensorCard`, `StatusChip`, `TrendCard`, `AlertItem`, `FilterChip`, `SettingSwitch`, `ProfileOption`).

### 3. Database & Cloud Infrastructure
Hosted on **Aiven Cloud MySQL** with the following schema:
- **`users`**: User identities, credentials, roles, and registration timestamps.
- **`devices`**: Registered IoT hardware units (`device_id`, `device_name`, `location`, `status`, `last_active_at`).
- **`sensor_readings`**: High-frequency telemetry time-series indexed by `(device_id, recorded_at)` for fast range queries.
- **`alerts`**: System alerts indexed by `(device_id, created_at)` with read/unread tracking.

### 4. Automated Health & Alert Engine
The backend continuously inspects incoming telemetry against established health and safety thresholds:

| Parameter | Threshold | Severity | Alert Type |
|---|---|---|---|
| **AQI** | $\ge 200$ | `CRITICAL` | `VERY_UNHEALTHY_AQI` |
| **AQI** | $\ge 150$ | `WARNING` | `UNHEALTHY_AQI` |
| **CO2** | $\ge 1200\text{ ppm}$ | `WARNING` | `HIGH_CO2` |
| **Smoke / Gas** | $\ge 0.08$ | `CRITICAL` | `SMOKE_DETECTED` |
| **Temperature** | $\ge 42.0^\circ\text{C}$ | `WARNING` | `HIGH_TEMPERATURE` |

---

## 📂 Project Directory Structure

```plaintext
AIr_Sense/
├── README.md                          # Global repository documentation
├── airsense-backend/                  # Spring Boot 3 + Java 21 REST API
│   ├── pom.xml                        # Maven dependencies & build configuration
│   └── src/main/
│       ├── java/com/airsense/
│       │   ├── AirSenseApplication.java
│       │   ├── config/                # CorsConfig, GlobalExceptionHandler
│       │   ├── controller/            # Auth, Device, Sensor, Alert Controllers
│       │   ├── dto/                   # Request & Response Data Transfer Objects
│       │   ├── entity/                # JPA Entities (User, Device, SensorReading, Alert)
│       │   ├── repository/            # Spring Data JPA Repositories
│       │   └── service/               # Sensor, Alert, Device, Auth Services
│       └── resources/
│           ├── application.properties # Server port, Aiven MySQL & HikariCP config
│           └── schema.sql             # Relational database table definitions
│
└── Frontend/                          # Flutter 3 Cross-Platform Application
    ├── pubspec.yaml                   # Flutter dependencies (http, fl_chart, lottie)
    └── lib/
        ├── app.dart                   # AeroGuardApp root widget
        ├── main.dart                  # Application entrypoint
        ├── core/
        │   ├── constants/             # App constants
        │   ├── routes/                # Application navigation routes
        │   ├── services/              # ApiService (REST client & reactive stream)
        │   └── theme/                 # AppColors, AppTheme, TextStyles
        ├── data/
        │   ├── dummy/                 # Fallback offline telemetry
        │   └── models/                # SensorData, AlertModel, AnalyticsModel
        ├── features/
        │   ├── alerts/                # AlertsScreen
        │   ├── analytics/             # AnalyticsScreen (fl_chart metrics)
        │   ├── dashboard/             # DashboardScreen (Live gauges & cards)
        │   ├── profile/               # ProfileScreen (Device status & settings)
        │   ├── settings/              # SettingsScreen
        │   └── splash/                # SplashScreen
        └── shared/widgets/            # Reusable modular UI widgets
```

---

## 📡 REST API Reference

All endpoints return a uniform response envelope:
```json
{
  "success": true,
  "message": "Operation description",
  "data": { ... }
}
```

### Authentication (`/api/auth`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register a new user (`name`, `email`, `password`) |
| `POST` | `/api/auth/login` | Authenticate existing user |

### Devices (`/api/devices`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/devices` | List all registered IoT devices |
| `POST` | `/api/devices` | Register or update a device (`deviceId`, `deviceName`, `location`) |
| `GET` | `/api/devices/{deviceId}` | Retrieve device metadata and online status |

### Sensor Telemetry (`/api/sensors`)
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/sensors/data` | Ingest sensor telemetry from ESP32 or simulation |
| `GET` | `/api/sensors/latest?deviceId=...` | Retrieve most recent sensor reading for dashboard |
| `GET` | `/api/sensors/history?deviceId=...&range=24H` | Historical telemetry for charts (`1H`, `24H`, `7D`, `30D`) |
| `GET` | `/api/sensors/recent?deviceId=...` | Retrieve latest 50 readings |

### Alerts (`/api/alerts`)
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/alerts?deviceId=...` | Retrieve chronological alerts list |
| `PUT` | `/api/alerts/{id}/read` | Mark a specific alert as read |
| `GET` | `/api/alerts/unread-count` | Retrieve count of pending unread alerts |

---

## 🔌 IoT Device Payload & Hardware Integration

The backend is configured to accept telemetry payloads from microcontrollers such as the **ESP32** connected to **MQ135** (gas/smoke) and **DHT11/DHT22** (temp/humidity).

### Example Telemetry Ingestion Payload
```http
POST /api/sensors/data HTTP/1.1
Host: your-server-ip:8080
Content-Type: application/json

{
  "deviceId": "ESP32_AIR_01",
  "temperature": 27.4,
  "humidity": 58.2,
  "co2": 520.0,
  "smoke": 0.02,
  "aqi": 62
}
```
> **Note**: If `aqi` is omitted in the request, the backend automatically calculates it based on `co2` and `smoke` values.

---

## 🛠️ Getting Started

### Prerequisites
- **Java**: OpenJDK 21 or higher
- **Maven**: 3.8+ (or use `./mvnw`)
- **Flutter**: 3.22+ & Dart 3.x
- **Database**: Access to MySQL (Aiven Cloud pre-configured in `application.properties`, or local MySQL)

---

### Backend Setup

1. Open a terminal and navigate to the backend folder:
   ```bash
   cd airsense-backend
   ```
2. Build and compile the project:
   ```bash
   mvn clean compile
   ```
3. Run the Spring Boot application:
   ```bash
   mvn spring-boot:run
   ```
4. Verify the server is running on `http://localhost:8080`.

---

### Frontend Setup

1. Open a terminal and navigate to the frontend directory:
   ```bash
   cd Frontend
   ```
2. Fetch Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   - **For Chrome / Web**:
     ```bash
     flutter run -d chrome
     ```
   - **For Windows Desktop**:
     ```bash
     flutter run -d windows
     ```
   - **For Android Emulator**:
     ```bash
     flutter run -d <emulator-id>
     ```

---

### 🐳 Docker Deployment

You can build and deploy AirSense using Docker and Docker Compose:

#### 1. Run with Docker Compose (Recommended)
Run backend and web frontend together:
```bash
docker compose up -d --build
```
- **Backend API**: `http://localhost:8080/api`
- **Flutter Web UI**: `http://localhost`

If you want to run an offline local MySQL database container instead of the cloud database:
```bash
docker compose --profile local-db up -d --build
```

#### 2. Build & Run Backend Standalone
```bash
cd airsense-backend
docker build -t airsense-backend .
docker run -p 8080:8080 airsense-backend
```

#### 3. Deploy to Cloud (Render / Railway / Cloud Run / AWS)
The repository includes root and service-level Dockerfiles. Point your cloud container builder to:
- **Dockerfile**: `./Dockerfile` (or `./airsense-backend/Dockerfile`)
- **Port**: `8080`
- **Environment Variables**: Configure `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, and `SPRING_DATASOURCE_PASSWORD`.

---

## 👨‍💻 Contributors

- **Aditya Verma** ([@Aditya8103](https://github.com/Aditya8103))
