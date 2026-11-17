import 'package:path/path.dart' as p;

import '../models/hasil_identifikasi.dart';
import 'format_waktu.dart';

abstract final class RiwayatExporter {
  static String _cell(Object? nilai) {
    final teks = nilai?.toString() ?? '';
    if (!teks.contains(RegExp(r'[;"\r\n]'))) return teks;
    return '"${teks.replaceAll('"', '""')}"';
  }

  static String buatCsv(List<Riwayat> data) {
    final baris = <List<Object?>>[
      [
        'no',
        'tanggal',
        'kelas',
        'status',
        'keyakinan_persen',
        'id_petak',
        'id_musim',
        'id_sesi',
        'aturan',
        'waktu_praproses_ms',
        'waktu_inferensi_ms',
        'waktu_total_ms',
        'kualitas_foto',
        'model_version',
        'berkas_foto',
      ],
      for (var i = 0; i < data.length; i++)
        [
          i + 1,
          FormatWaktu.angka(data[i].waktu),
          data[i].idPenyakit.isEmpty ? 'tidak_dikenali' : data[i].idPenyakit,
          data[i].status.kode,
          (data[i].keyakinan * 100).toStringAsFixed(2),
          data[i].idPetak,
          data[i].idMusim,
          data[i].idSesi,
          data[i].aturan,
          data[i].auditTersedia ? data[i].waktuPraprosesMs : 'tidak_dicatat',
          data[i].auditTersedia ? data[i].waktuInferensiMs : 'tidak_dicatat',
          data[i].auditTersedia ? data[i].waktuTotalMs : 'tidak_dicatat',
          data[i].auditTersedia
              ? [
                  if (data[i].fotoGelap) 'gelap',
                  if (data[i].fotoBuram) 'buram',
                  if (!data[i].fotoGelap && !data[i].fotoBuram) 'baik',
                ].join(',')
              : 'tidak_dicatat',
          data[i].modelVersion,
          p.basename(data[i].pathFoto),
        ],
    ];
    return baris.map((row) => row.map(_cell).join(';')).join('\n');
  }
}
