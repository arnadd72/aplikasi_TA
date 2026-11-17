import 'package:flutter_test/flutter_test.dart';
import 'package:padi_scan/models/hasil_identifikasi.dart';

void main() {
  test('baris riwayat v1 mendapat default audit yang aman', () {
    final riwayat = Riwayat.fromDb({
      'id_riwayat': 7,
      'path_foto': '/foto/lama.jpg',
      'id_penyakit': 'blas',
      'keyakinan': 0.91,
      'waktu': '2026-01-03T10:00:00.000',
    });

    expect(riwayat.idPetak, isNull);
    expect(riwayat.idMusim, isNull);
    expect(riwayat.idSesi, isNull);
    expect(riwayat.aturan, '');
    expect(riwayat.status, StatusIdentifikasi.terklasifikasi);
    expect(riwayat.waktuInferensiMs, 0);
    expect(riwayat.modelVersion, 'tidak-tercatat');
    expect(riwayat.auditTersedia, isFalse);
  });

  test('baris riwayat v2 mempertahankan seluruh bukti audit', () {
    final awal = Riwayat(
      idRiwayat: 9,
      pathFoto: '/foto/baru.jpg',
      idPenyakit: 'hawar_daun_bakteri',
      keyakinan: 0.88,
      waktu: DateTime(2026, 11, 17, 8, 30),
      idPetak: 2,
      idMusim: 4,
      idSesi: 6,
      status: StatusIdentifikasi.terklasifikasi,
      aturan: 'R2',
      waktuPraprosesMs: 21,
      waktuInferensiMs: 63,
      waktuTotalMs: 101,
      fotoGelap: true,
      fotoBuram: false,
      modelVersion: 'mobilenetv2-local-2026-10',
      probabilitasJson: '{"hawar_daun_bakteri":0.88}',
      auditTersedia: true,
    );

    final hasil = Riwayat.fromDb(awal.toDb());

    expect(hasil.idPetak, 2);
    expect(hasil.idMusim, 4);
    expect(hasil.idSesi, 6);
    expect(hasil.aturan, 'R2');
    expect(hasil.waktuPraprosesMs, 21);
    expect(hasil.waktuInferensiMs, 63);
    expect(hasil.waktuTotalMs, 101);
    expect(hasil.fotoGelap, isTrue);
    expect(hasil.fotoBuram, isFalse);
    expect(hasil.modelVersion, 'mobilenetv2-local-2026-10');
    expect(hasil.probabilitasJson, '{"hawar_daun_bakteri":0.88}');
    expect(hasil.auditTersedia, isTrue);
  });
}
