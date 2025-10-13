// lib/services/websocket_service.dart
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  
  WebSocketChannel? _channel;
  final _availabilityController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get availabilityStream => _availabilityController.stream;
  
  void connect(String carWashId) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080'),
    );
    
    // الاشتراك في تحديثات المغسلة
    _channel!.sink.add(jsonEncode({
      'type': 'subscribe',
      'carWashId': carWashId,
    }));
    
    // الاستماع للتحديثات
    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'availability_update') {
        _availabilityController.add(data);
      }
    });
  }
  
  void disconnect() {
    _channel?.sink.close();
    _availabilityController.close();
  }
}