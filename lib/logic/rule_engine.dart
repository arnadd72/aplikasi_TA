import 'package:flutter/foundation.dart';

/// Mesin rekomendasi berbasis aturan (Tabel 3.7).
///
/// Aturan tidak dipakai untuk mendiagnosis penyakit, melainkan untuk
/// memetakan hasil identifikasi model ke rekomendasi penanganan.
class RuleEngine {
  /// Ambang batas keyakinan awal 70% (Tabel 3.7).
  /// Dievaluasi pada tahap pengujian.
  static const double ambangKeyakinan = 0.70;

  /// R1-R4: memeriksa ambang batas untuk kelas terpilih.
  /// R5: memeriksa keyakinan rendah.
  ///
  /// [idPenyakit] adalah kelas dengan keyakinan tertinggi.
  /// [keyakinan] adalah nilai probabilitas kelas tersebut (0..1).
  static KeputusanAturan evaluasi({
    required String idPenyakit,
    required double keyakinan,
  }) {
    const kelasDikenal = {
      'blas',
      'hawar_daun_bakteri',
      'bercak_cokelat',
      'normal',
    };
    if (!kelasDikenal.contains(idPenyakit)) {
      throw StateError('Label model tidak terdaftar: $idPenyakit');
    }

    if (keyakinan < ambangKeyakinan) {
      return const KeputusanAturan(
        aturan: 'R5',
        tidakDikenali: true,
        pesan:
            'Citra tidak dikenali. Keyakinan model di bawah 70%. '
            'Silakan ambil ulang foto dengan pencahayaan cukup, fokus, '
            'dan bagian daun yang bergejala terlihat jelas.',
      );
    }

    if (idPenyakit == 'normal') {
      // R4
      return const KeputusanAturan(
        aturan: 'R4',
        tidakDikenali: false,
        pesan:
            'Daun terdeteksi sehat. Tidak ditemukan gejala penyakit. '
            'Tetap lakukan pemantauan secara berkala.',
      );
    }

    final kode = switch (idPenyakit) {
      'blas' => 'R1',
      'hawar_daun_bakteri' => 'R2',
      'bercak_cokelat' => 'R3',
      _ => throw StateError('Label model tidak terdaftar: $idPenyakit'),
    };

    debugPrint('[RuleEngine] aturan $kode aktif untuk kelas $idPenyakit');
    return KeputusanAturan(
      aturan: kode,
      tidakDikenali: false,
      pesan: 'Tampilkan informasi dan rekomendasi penanganan.',
    );
  }
}

class KeputusanAturan {
  /// Kode aturan yang aktif: R1..R5.
  final String aturan;

  /// True bila aturan R5 aktif (citra tidak dikenali).
  final bool tidakDikenali;

  /// Pesan yang ditampilkan ke pengguna.
  final String pesan;

  const KeputusanAturan({
    required this.aturan,
    required this.tidakDikenali,
    required this.pesan,
  });
}
