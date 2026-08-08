import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductService {
  Future<Map<String, dynamic>> fetchProductData(String barcode) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return {
          'error': 'Product not found',
          'product_name': 'Unknown Product',
          'brands': 'Unknown',
          'packaging': 'Unknown',
          'categories': 'Unknown',
        };
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 1) {
        return {
          'error': 'Product not found',
          'product_name': 'Unknown Product',
          'brands': 'Unknown',
          'packaging': 'Unknown',
          'categories': 'Unknown',
        };
      }

      final product = data['product'] as Map<String, dynamic>?;

      return {
        'product_name': product?['product_name'] as String? ?? 'Unknown Product',
        'brands': product?['brands'] as String? ?? 'Unknown',
        'packaging': product?['packaging'] as String? ?? 'Unknown',
        'categories': product?['categories'] as String? ?? 'Unknown',
      };
    } catch (e) {
      return {
        'error': 'Failed to fetch product data',
        'product_name': 'Unknown Product',
        'brands': 'Unknown',
        'packaging': 'Unknown',
        'categories': 'Unknown',
      };
    }
  }

  String estimatePackagingImpact(String packaging) {
    final lowerPackaging = packaging.toLowerCase();

    if (lowerPackaging.contains('plastic')) {
      return 'Moderate impact - Plastic is difficult to recycle and persists in environment';
    } else if (lowerPackaging.contains('glass')) {
      return 'Low impact - Glass is highly recyclable but energy-intensive to produce';
    } else if (lowerPackaging.contains('aluminum') || lowerPackaging.contains('metal')) {
      return 'Moderate impact - Aluminum is recyclable but requires significant energy to produce';
    } else if (lowerPackaging.contains('paper') || lowerPackaging.contains('cardboard')) {
      return 'Low impact - Paper/cardboard is biodegradable and recyclable';
    } else if (lowerPackaging.contains('mixed')) {
      return 'High impact - Mixed materials are difficult to separate and recycle';
    } else {
      return 'Unknown impact - Packaging type not recognized';
    }
  }
}
