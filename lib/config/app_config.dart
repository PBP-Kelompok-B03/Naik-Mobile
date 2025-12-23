class AppConfig {
  // Base URL for the Django backend
  // IMPORTANT: Choose the correct URL based on your device:

  // For Android emulator: use 'http://10.0.2.2:8000'
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';

  // For iOS simulator: use 'https://raymundo-rafaelito-naik.pbp.cs.ui.ac.id'
  static const String iosSimulatorUrl =
      'https://raymundo-rafaelito-naik.pbp.cs.ui.ac.id';

  // For physical device: use your computer's IP address
  // Find your IP: Windows (ipconfig), Mac/Linux (ifconfig)
  static const String physicalDeviceUrl = 'http://192.168.1.100:8000';

  // TODO: Change this based on your device!
  // Use androidEmulatorUrl, iosSimulatorUrl, or physicalDeviceUrl
  static const String baseUrl = iosSimulatorUrl; // CHANGE THIS!

  // API endpoints
  static const String productJsonEndpoint = '$baseUrl/json/';
  static const String proxyImageEndpoint = '$baseUrl/proxy-image/';
}
