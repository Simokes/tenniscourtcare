import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/repository_exception.dart';
import '../../features/settings/providers/app_settings_provider.dart' show ClubLocation;

class NominatimService {
  final http.Client _client;

  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  Future<ClubLocation?> geocode({
    required String street,
    required String postalCode,
    required String city,
  }) async {
    try {
      final queryParams = {
        'street': street,
        'postalcode': postalCode,
        'city': city,
        'country': 'France',
        'format': 'json',
        'limit': '1',
      };

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', queryParams);

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'TennisCourtCare/1.0',
        },
      );

      if (response.statusCode != 200) {
        throw RepositoryException('Erreur HTTP lors du géocodage: ${response.statusCode}');
      }

      final data = json.decode(response.body) as List<dynamic>;

      if (data.isEmpty) {
        return null; // Not found
      }

      final firstResult = data.first as Map<String, dynamic>;
      final latString = firstResult['lat'] as String;
      final lonString = firstResult['lon'] as String;

      final lat = double.tryParse(latString);
      final lon = double.tryParse(lonString);

      if (lat != null && lon != null) {
        return ClubLocation(latitude: lat, longitude: lon);
      }

      return null;
    } catch (e) {
      if (e is RepositoryException) {
        rethrow;
      }
      throw RepositoryException('Erreur inattendue lors du géocodage: $e');
    }
  }
}
