import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/time_slot.dart';

class CapacityService {
  static const String baseUrl = 'YOUR_API_BASE_URL'; // استبدل بـ URL الخاص بك

  Future<List<TimeSlot>> getDaySlots({
    required String carWashId,
    required DateTime date,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      final response = await http.post(
        Uri.parse('$baseUrl/get_day_slots.php'),
        body: {
          'car_wash_id': carWashId,
          'date': formattedDate,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['slots'] != null) {
          return (data['slots'] as List)
              .map((e) => TimeSlot.fromJson(e))
              .toList();
        }
        return [];
      } else {
        throw Exception('فشل جلب البيانات');
      }
    } catch (e) {
      throw Exception('خطأ في جلب الفترات: $e');
    }
  }

  Future<bool> updateCapacity({
    required String slotId,
    required int newCapacity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_capacity.php'),
        body: {
          'slot_id': slotId,
          'new_capacity': newCapacity.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('خطأ في تحديث السعة: $e');
    }
  }

  Future<bool> toggleSlot({
    required String slotId,
    required bool isActive,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/toggle_slot.php'),
        body: {
          'slot_id': slotId,
          'is_active': isActive ? '1' : '0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('خطأ في تعديل حالة الفترة: $e');
    }
  }

  Future<bool> deleteSlot({
    required String slotId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_slot.php'),
        body: {
          'slot_id': slotId,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('خطأ في حذف الفترة: $e');
    }
  }

  Future<bool> addTimeSlot({
    required String carWashId,
    required DateTime date,
    required TimeOfDay time,
    required int capacity,
  }) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final formattedTime =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('$baseUrl/add_time_slot.php'),
        body: {
          'car_wash_id': carWashId,
          'date': formattedDate,
          'time': formattedTime,
          'capacity': capacity.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('خطأ في إضافة الفترة: $e');
    }
  }
}
