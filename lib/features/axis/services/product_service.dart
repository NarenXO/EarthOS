import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:earthos/core/services/gemini_service.dart';

class ProductService {
  Future<Map<String, dynamic>> fetchProductData(String barcode) async {
    print('ProductService: barcode=$barcode');
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      print('ProductService: calling OpenFoodFacts API');

      final response = await http.get(url);
      print('ProductService: OpenFoodFacts status=${response.statusCode}');

      if (response.statusCode != 200) {
        print('ProductService: product not found in database, using Gemini fallback');
        return await _getGeminiFallback(barcode);
      }

      final data = jsonDecode(response.body);
      print('ProductService: parsing OpenFoodFacts response');

      if (data['status'] != 1) {
        print('ProductService: product status != 1, using Gemini fallback');
        return await _getGeminiFallback(barcode);
      }

      final product = data['product'] as Map<String, dynamic>?;
      final productName = product?['product_name'] as String? ?? 'Unknown Product';
      final brands = product?['brands'] as String? ?? 'Unknown';
      final packaging = product?['packaging'] as String? ?? 'Unknown';
      final categories = product?['categories'] as String? ?? 'Unknown';

      print('ProductService: product found - name=$productName packaging=$packaging');

      // Pass product data to Gemini for environmental explanation
      String geminiExplanation = '';
      try {
        print('ProductService: calling Gemini for environmental analysis');
        final prompt =
            'Analyze the environmental impact of product "$productName" (Brand: $brands, Packaging: $packaging, Categories: $categories). Provide a 2-sentence summary of environmental impact and recyclability.';
        geminiExplanation = await GeminiService.generate(prompt);
        print('ProductService: Gemini analysis complete');
      } catch (e) {
        print('ProductService: Gemini failed, using fallback: $e');
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
      print('ProductService: exception: $e');
      return await _getGeminiFallback(barcode);
    }
  }

  Future<Map<String, dynamic>> _getGeminiFallback(String barcode) async {
    print('ProductService: using Gemini fallback for barcode=$barcode');
    try {
      final prompt = 'Analyze the environmental impact of a product with barcode $barcode. Since it\'s not in the database, provide general guidance on checking packaging materials and recyclability. Keep it to 2 sentences.';
      final geminiExplanation = await GeminiService.generate(prompt);
      return {
        'error': 'Product not found in database',
        'product_name': 'Unknown Product',
        'brands': 'Unknown',
        'packaging': 'Unknown',
        'categories': 'Unknown',
        'gemini_explanation': geminiExplanation,
      };
    } catch (e) {
      print('ProductService: Gemini fallback failed: $e');
      return {
        'error': 'Product not found in database',
        'product_name': 'Unknown Product',
        'brands': 'Unknown',
        'packaging': 'Unknown',
        'categories': 'Unknown',
        'gemini_explanation': 'Product not found in database. Please check the packaging material for recyclability information.',
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
