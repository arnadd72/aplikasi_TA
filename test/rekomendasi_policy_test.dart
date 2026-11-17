import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'konten rekomendasi tidak memuat dosis pestisida atau merek dagang',
    () async {
      final raw = await rootBundle.loadString('assets/data/penyakit.json');
      final teks = jsonEncode(jsonDecode(raw)).toLowerCase();

      expect(teks, isNot(contains('mikrogram/ml')));
      expect(teks, isNot(contains('seng sulfat (2%)')));
      expect(teks, isNot(contains('sesuai dosis')));
      expect(teks, isNot(contains('merek dagang')));

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final kategori = (data['kelas'] as List)
          .expand((item) => (item['rekomendasi'] as List))
          .map((item) => item['kategori'])
          .toSet();
      expect(kategori, containsAll(['hayati', 'kimia']));
    },
  );
}
