import 'dart:async';
import 'dart:math';
import '../models/weather_model.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  Timer? _weatherTimer;
  final StreamController<WeatherModel> _weatherController =
      StreamController<WeatherModel>.broadcast();
  bool _isMonitoring = false;

  Stream<WeatherModel> get weatherStream => _weatherController.stream;

  WeatherModel? _currentWeather;
  WeatherModel? get currentWeather => _currentWeather;

  // Start weather monitoring
  void startWeatherMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _updateWeather(); // Initial update

    // Update weather every 30 seconds for real-time feel
    _weatherTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateWeather();
    });
  }

  // Stop weather monitoring
  void stopWeatherMonitoring() {
    if (!_isMonitoring) return;
    _weatherTimer?.cancel();
    _weatherTimer = null;
    _isMonitoring = false;
  }

  void _updateWeather() {
    final now = DateTime.now();
    final isDaytime = now.hour >= 6 && now.hour < 18; // 6 AM to 6 PM

    // Simulate realistic weather patterns
    final random = Random();

    // Base temperature changes with time of day and season
    double baseTemp = 25.0; // Base temperature

    // Seasonal variation (rough approximation)
    final month = now.month;
    if (month >= 3 && month <= 5) baseTemp += 5; // Spring
    if (month >= 6 && month <= 8) baseTemp += 10; // Summer
    if (month >= 9 && month <= 11) baseTemp -= 2; // Fall

    // Time of day variation
    if (isDaytime) {
      final hourProgress = (now.hour - 6) / 12; // 0 to 1 from 6 AM to 6 PM
      baseTemp += sin(hourProgress * pi) * 8; // Natural temperature curve
    } else {
      baseTemp -= 5; // Cooler at night
    }

    // Add some random variation (±3°C)
    final temperature = baseTemp + (random.nextDouble() - 0.5) * 6;

    // Humidity based on temperature and time
    final humidity = 60 + (30 - temperature) * 0.5 + random.nextDouble() * 20;

    // Wind patterns
    var windSpeed = 5.0 + random.nextDouble() * 25.0; // 5-30 km/h
    final windDirections = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final windDirection = windDirections[random.nextInt(windDirections.length)];

    // Weather conditions based on various factors
    String condition;
    final rand = random.nextDouble();

    if (!isDaytime && rand < 0.3) {
      condition = 'Clear'; // More likely clear at night
    } else if (temperature > 30.0 && rand < 0.4) {
      condition = 'Sunny';
    } else if (humidity > 70.0 && rand < 0.3) {
      condition = 'Rainy';
    } else if (windSpeed > 20.0 && rand < 0.2) {
      condition = 'Windy';
    } else if (rand < 0.6) {
      condition = 'Cloudy';
    } else {
      condition = 'Partly Cloudy';
    }

    // Typhoon detection (rare occurrence)
    final hasTyphoon = random.nextDouble() < 0.02; // 2% chance
    String? typhoonName;
    int typhoonStrength = 0;

    if (hasTyphoon) {
      final typhoonNames = [
        'Ambo',
        'Butchoy',
        'Carina',
        'Dindo',
        'Enteng',
        'Ferdie',
        'Gener',
        'Helen',
        'Igme',
        'Julian',
      ];
      typhoonName = typhoonNames[random.nextInt(typhoonNames.length)];
      typhoonStrength = random.nextInt(5) + 1; // 1-5 strength

      // Typhoons bring high winds and rain
      condition = 'Stormy';
      windSpeed = max(
        windSpeed,
        30.0 + random.nextDouble() * 50.0,
      ); // 30-80 km/h
    }

    final weather = WeatherModel(
      timestamp: now,
      temperature: temperature.clamp(15, 45), // Reasonable temperature range
      humidity: humidity.clamp(30, 95), // Reasonable humidity range
      windSpeed: windSpeed.clamp(0, 100), // Reasonable wind range
      windDirection: windDirection,
      condition: condition,
      isDaytime: isDaytime,
      hasTyphoon: hasTyphoon,
      typhoonName: typhoonName,
      typhoonStrength: typhoonStrength,
    );

    _currentWeather = weather;
    _weatherController.add(weather);
  }

  // Get weather forecast (simulate for next few hours)
  List<WeatherModel> getWeatherForecast(int hours) {
    final forecasts = <WeatherModel>[];
    final now = DateTime.now();

    for (int i = 1; i <= hours; i++) {
      final forecastTime = now.add(Duration(hours: i));
      final isDaytime = forecastTime.hour >= 6 && forecastTime.hour < 18;

      // Simplified forecast (could be more sophisticated)
      final tempVariation = sin(i * 0.5) * 3; // Temperature oscillation
      final temperature = (_currentWeather?.temperature ?? 25) + tempVariation;

      final forecast = WeatherModel(
        timestamp: forecastTime,
        temperature: temperature,
        humidity:
            (_currentWeather?.humidity ?? 60) + Random().nextDouble() * 10 - 5,
        windSpeed:
            (_currentWeather?.windSpeed ?? 15) + Random().nextDouble() * 10 - 5,
        windDirection: _currentWeather?.windDirection ?? 'N',
        condition: _currentWeather?.condition ?? 'Cloudy',
        isDaytime: isDaytime,
      );

      forecasts.add(forecast);
    }

    return forecasts;
  }
}
