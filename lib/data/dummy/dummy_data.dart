import '../models/sensor_data.dart';

class DummyData {
  static SensorData sensor = SensorData(
    co2: 412,
    smoke: 0.02,
    temperature: 24.8,
    humidity: 42,
    aqi: 32,
  );
}
