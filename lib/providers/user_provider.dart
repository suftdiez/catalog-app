import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// =======================================================
// USER PROFILE MODEL
// =======================================================
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String avatarUrl;
  final String memberType;

  UserProfile({
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.avatarUrl = '',
    this.memberType = 'Member Gold',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? 'Pengguna',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      memberType: json['memberType'] ?? 'Member Gold',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'memberType': memberType,
    };
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    String? memberType,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      memberType: memberType ?? this.memberType,
    );
  }
}

// =======================================================
// USER PROVIDER (STATE MANAGEMENT)
// =======================================================
class UserProvider with ChangeNotifier {
  UserProfile _profile = UserProfile(name: 'Pengguna', email: '');
  bool _isLoaded = false;

  UserProfile get profile => _profile;
  bool get isLoaded => _isLoaded;

  UserProvider() {
    _loadFromLocal();
  }

  // Update profile
  void updateProfile(UserProfile newProfile) {
    _profile = newProfile;
    _saveToLocal();
    notifyListeners();
  }

  // Update specific fields
  void updateName(String name) {
    _profile = _profile.copyWith(name: name);
    _saveToLocal();
    notifyListeners();
  }

  void updatePhone(String phone) {
    _profile = _profile.copyWith(phone: phone);
    _saveToLocal();
    notifyListeners();
  }

  void updateAddress(String address) {
    _profile = _profile.copyWith(address: address);
    _saveToLocal();
    notifyListeners();
  }

  // Initialize from login data
  void initFromLogin(String email) {
    String name = email.split('@').first;
    _profile = UserProfile(name: name, email: email);
    _saveToLocal();
    notifyListeners();
  }

  // Save to local storage
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_profile.toJson());
    await prefs.setString('user_profile', jsonString);
  }

  // Load from local storage
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_profile');
    
    if (data != null && data.isNotEmpty) {
      _profile = UserProfile.fromJson(jsonDecode(data));
    } else {
      // Try to get username from old storage
      String? username = prefs.getString('username');
      if (username != null) {
        _profile = UserProfile(name: username.split('@').first, email: username);
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  // Clear on logout
  void clearProfile() {
    _profile = UserProfile(name: 'Pengguna', email: '');
    _isLoaded = false;
    notifyListeners();
  }
}
