import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/family_member.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String baseUrl;

  static String get _defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return configured;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/api-test/public';
    }
    return 'http://localhost/api-test/public';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<void> register(String email, String password) async {
    await _send(
      () => _client.post(
        _uri('/accounts/register'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    late http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 15));
    } on Exception catch (error) {
      throw ApiException(
        'Impossible de joindre le serveur. Vérifiez que XAMPP et l’API sont démarrés. ($error)',
      );
    }

    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      payload = decoded;
    } on FormatException {
      throw ApiException('Le serveur a renvoyé une réponse invalide.');
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['success'] != true) {
      final errors = payload['errors'];
      final details = errors is Map
          ? errors.values.join(' ')
          : (payload['message'] ?? 'Erreur HTTP ${response.statusCode}');
      throw ApiException(details.toString());
    }
    return payload;
  }

  Future<void> login(String email, String password) async {
    await _send(
      () => _client.post(
        _uri('/accounts/login'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
  }

  Future<List<FamilyMember>> getFamilyMembers() async {
    final payload = await _send(() => _client.get(_uri('/famille-membres')));
    final data = payload['data'];
    if (data is! List) throw const ApiException('Liste de membres invalide.');
    return data
        .map(
          (item) =>
              FamilyMember.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> createFamilyMember(FamilyMember member, {XFile? image}) async {
    if (image != null) {
      await _sendFamilyImage('/famille-membres', member, image);
      return;
    }
    await _send(
      () => _client.post(
        _uri('/famille-membres'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(member.toJson()),
      ),
    );
  }

  Future<void> updateFamilyMember(FamilyMember member, {XFile? image}) async {
    if (image != null) {
      await _sendFamilyImage('/famille-membres/${member.id}', member, image);
      return;
    }
    await _send(
      () => _client.put(
        _uri('/famille-membres/${member.id}'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode(member.toJson()),
      ),
    );
  }

  Future<void> _sendFamilyImage(
    String path,
    FamilyMember member,
    XFile image,
  ) async {
    final filename = image.name;
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    if (!const {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(extension)) {
      throw const ApiException('Choisissez une image JPG, PNG, GIF ou WebP.');
    }

    late final List<int> bytes;
    try {
      bytes = await image.readAsBytes();
    } on Exception catch (error) {
      throw ApiException('Impossible de lire la photo sélectionnée. ($error)');
    }
    if (bytes.length > 2 * 1024 * 1024) {
      throw const ApiException('La photo ne doit pas dépasser 2 Mo.');
    }

    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(
        member.toJson().map((key, value) => MapEntry(key, value.toString())),
      )
      ..files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      _decodeResponse(response);
    } on ApiException {
      rethrow;
    } on Exception catch (error) {
      throw ApiException(
        'Échec de l’envoi de la photo. Vérifiez votre connexion. ($error)',
      );
    }
  }

  Future<void> deleteFamilyMember(int id) async =>
      _send(() => _client.delete(_uri('/famille-membres/$id')));

  void close() => _client.close();
}
