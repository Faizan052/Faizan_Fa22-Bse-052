import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  UserModel? user;

  Future<void> signIn(String em, String pw) async {
    user = await SupabaseService.signIn(em, pw);
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('user', jsonEncode(user!.toMap()));
    }
    notifyListeners();
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user')) {
      final userMap = jsonDecode(prefs.getString('user')!);
      user = UserModel.fromMap(userMap);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    user = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
    notifyListeners();
  }
}
