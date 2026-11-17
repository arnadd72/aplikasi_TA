/// Pemformatan tanggal dan waktu dalam bahasa Indonesia.
///
/// Ditulis manual tanpa paket `intl` agar tidak ada data lokal tambahan
/// yang perlu diunduh dan NF-01 (sepenuhnya offline) tetap terpenuhi.
abstract final class FormatWaktu {
  static const List<String> _bulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _bulanPanjang = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String _dua(int n) => n.toString().padLeft(2, '0');

  /// "16 Nov 2026, 01:24"
  static String ringkas(DateTime w) =>
      '${_dua(w.day)} ${_bulanSingkat[w.month - 1]} ${w.year}, '
      '${_dua(w.hour)}:${_dua(w.minute)}';

  /// "16/11/2026 01:24"
  static String angka(DateTime w) =>
      '${_dua(w.day)}/${_dua(w.month)}/${w.year} '
      '${_dua(w.hour)}:${_dua(w.minute)}';

  /// "16 November 2026"
  static String panjang(DateTime w) =>
      '${w.day} ${_bulanPanjang[w.month - 1]} ${w.year}';

  /// "baru saja", "12 menit lalu", "3 jam lalu", "2 hari lalu".
  static String relatif(DateTime w, {DateTime? sekarang}) {
    final kini = sekarang ?? DateTime.now();
    final beda = kini.difference(w);
    if (beda.inSeconds < 60) return 'baru saja';
    if (beda.inMinutes < 60) return '${beda.inMinutes} menit lalu';
    if (beda.inHours < 24) return '${beda.inHours} jam lalu';
    if (beda.inDays < 30) return '${beda.inDays} hari lalu';
    return panjang(w);
  }
}
