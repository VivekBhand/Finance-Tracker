import 'package:dio/dio.dart';

import '../models/holding.dart';

/// Fetches live market data from NSE and AMFI — no API key required.
class NseMarketService {
  final Dio _dio = Dio();
  String? _cookie;

  /// Establish NSE session via cookie handshake.
  Future<void> _initSession() async {
    if (_cookie != null) return;
    try {
      final response = await _dio.get(
        'https://www.nseindia.com',
        options: Options(headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html',
        }),
      );
      final cookies = response.headers['set-cookie'];
      if (cookies != null) {
        _cookie = cookies.map((c) => c.split(';').first).join('; ');
      }
    } catch (_) {
      // Session init failed — subsequent calls will silently return null
    }
  }

  /// Get live equity price from NSE (no API key needed).
  Future<double?> getEquityPrice(String symbol) async {
    await _initSession();
    try {
      final response = await _dio.get(
        'https://www.nseindia.com/api/quote-equity',
        queryParameters: {'symbol': symbol},
        options: Options(headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://www.nseindia.com',
          'Cookie': _cookie ?? '',
        }),
      );
      return (response.data['priceInfo']?['lastPrice'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  /// Get mutual fund NAV from AMFI (public, no key needed).
  /// [schemeCode] is the AMFI scheme code (e.g. "119551").
  Future<double?> getMutualFundNav(String schemeCode) async {
    try {
      final response =
          await _dio.get('https://api.mfapi.in/mf/$schemeCode/latest');
      final data = response.data;
      if (data is Map &&
          data['data'] is List &&
          (data['data'] as List).isNotEmpty) {
        return double.tryParse(data['data'][0]['nav']?.toString() ?? '');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Refresh prices for all holdings from NSE/AMFI.
  Future<void> refreshPrices(List<Holding> holdings) async {
    for (final h in holdings) {
      try {
        double? price;
        if (h.assetType == AssetType.equity && h.symbol != null) {
          price = await getEquityPrice(h.symbol!);
        } else if (h.assetType == AssetType.mutualFund && h.isin != null) {
          price = await getMutualFundNav(h.isin!);
        }
        if (price != null) {
          h.currentPrice = price;
          h.lastUpdated = DateTime.now();
        }
      } catch (_) {
        // Silently skip failed lookups, retain cached price
      }
    }
  }
}
