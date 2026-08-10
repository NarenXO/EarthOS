import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:earthos/core/services/gemini_service.dart';

class ProductService {
  Future<Map<String, dynamic>> fetchProductData(String barcode) async {
    print('Barcode: $barcode');
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );

      final response = await http.get(url);
      print('Product API status: ${response.statusCode}');

      if (response.statusCode != 200) {
        return {
          'error': 'Product not found',
          'product_name': 'Unknown Product',
          'brands': 'Unknown',
          'packaging': 'Unknown',
          'categories': 'Unknown',
          'gemini_explanation': 'Product not found in database for barcode $barcode.',
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
          'gemini_explanation': 'Product details unavailable for barcode $barcode.',
        };
      }

      final product = data['product'] as Map<String, dynamic>?;
      final productName = product?['product_name'] as String? ?? 'Unknown Product';
      final brands = product?['brands'] as String? ?? 'Unknown';
      final packaging = product?['packaging'] as String? ?? 'Unknown';
      final categories = product?['categories'] as String? ?? 'Unknown';

      // Pass product data to Gemini for environmental explanation
      String geminiExplanation = '';
      try {
        final prompt =
            'Analyze the environmental impact of product "$productName" (Brand: $brands, Packaging: $packaging, Categories: $categories). Provide a 2-sentence summary of environmental impact and recyclability.';
        geminiExplanation = await GeminiService.generate(prompt);
      } catch (e) {
        geminiExplanation = estimatePackagingImpact(packaging);
      }

      return {
        'product_name': productName,
        'brands': brands,
        'packaging': packaging,
        'categories': categories,
        'gemini_explanation': geminiExplanation,
      };
    } catch (e) {
      print('Product service exception: $e');
      return {
        'error': 'Failed to fetch product data',
        'product_name': 'Unknown Product',
        'brands': 'Unknown',
        'packaging': 'Unknown',
        'categories': 'Unknown',
        'gemini_explanation': 'Error fetching product data: $e',
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
