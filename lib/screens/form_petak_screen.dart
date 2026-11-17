import 'package:flutter/material.dart';

import '../data/catatan_lapangan_repository.dart';
import '../models/catatan_lapangan.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';

/// Formulir Tambah atau Edit Lahan sesuai PRD F-11 dan S-11.
///
/// Field:
/// - Nama lahan (wajib)
/// - Lokasi teks (opsional)
/// - Luas (opsional, harus positif jika diisi) + Satuan luas (`ha`, `m²`, `bahu`, `patok`)
/// - Varietas padi (opsional)
/// - Tanggal tanam (opsional)
/// - Catatan (opsional)
class FormPetakScreen extends StatefulWidget {
  const FormPetakScreen({
    super.key,
    required this.repository,
    this.petakAwal,
  });

  final CatatanLapanganRepository repository;
  final Petak? petakAwal;

  @override
  State<FormPetakScreen> createState() => _FormPetakScreenState();
}

class _FormPetakScreenState extends State<FormPetakScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _lokasi;
  late final TextEditingController _luas;
  late final TextEditingController _varietas;
  late final TextEditingController _catatan;
  String _satuanLuas = 'ha';
  DateTime? _tanggalTanam;
  bool _sibuk = false;

  static const List<String> _daftarSatuan = ['ha', 'm²', 'bahu', 'patok'];

  @override
  void initState() {
    super.initState();
    final awal = widget.petakAwal;
    _nama = TextEditingController(text: awal?.nama ?? '');
    _lokasi = TextEditingController(text: awal?.lokasiCatatan ?? '');
    _luas = TextEditingController(
      text: awal?.luasHektare != null
          ? awal!.luasHektare!.toString().replaceAll('.', ',')
          : '',
    );
    _varietas = TextEditingController(text: awal?.varietas ?? '');
    _catatan = TextEditingController(text: awal?.catatan ?? '');
    _satuanLuas = awal != null && _daftarSatuan.contains(awal.satuanLuas)
        ? awal.satuanLuas
        : 'ha';
    _tanggalTanam = awal?.tanggalTanam;
  }

  @override
  void dispose() {
    _nama.dispose();
    _lokasi.dispose();
    _luas.dispose();
    _varietas.dispose();
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sibuk = true);
    final luas = double.tryParse(_luas.text.trim().replaceAll(',', '.'));
    await widget.repository.simpanPetak(
      Petak(
        idPetak: widget.petakAwal?.idPetak,
        nama: _nama.text.trim(),
        lokasiCatatan: _lokasi.text.trim(),
        luasHektare: luas,
        satuanLuas: _satuanLuas,
        varietas: _varietas.text.trim(),
        tanggalTanam: _tanggalTanam,
        catatan: _catatan.text.trim(),
        dibuatPada: widget.petakAwal?.dibuatPada ?? DateTime.now(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.petakAwal == null
              ? 'Lahan berhasil disimpan.'
              : 'Data lahan berhasil diperbarui.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final modeEdit = widget.petakAwal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(modeEdit ? 'Edit Lahan' : 'Tambah Lahan / Petak'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.horizontal,
            AppSpacing.md,
            AppSpacing.horizontal,
            AppSpacing.xl,
          ),
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama lahan / petak (wajib)',
                hintText: 'Contoh: Petak Utara',
              ),
              textInputAction: TextInputAction.next,
              validator: (nilai) => nilai == null || nilai.trim().isEmpty
                  ? 'Nama lahan wajib diisi.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _lokasi,
              decoration: const InputDecoration(
                labelText: 'Lokasi (opsional)',
                hintText: 'Contoh: Blok B dekat saluran irigasi',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _luas,
                    decoration: const InputDecoration(
                      labelText: 'Luas lahan (opsional)',
                      hintText: 'Contoh: 0,5',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (nilai) {
                      if (nilai == null || nilai.trim().isEmpty) return null;
                      final angka = double.tryParse(
                        nilai.trim().replaceAll(',', '.'),
                      );
                      return angka == null || angka <= 0
                          ? 'Masukkan luas lebih dari 0.'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _satuanLuas,
                    decoration: const InputDecoration(labelText: 'Satuan'),
                    items: [
                      for (final s in _daftarSatuan)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _satuanLuas = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _varietas,
              decoration: const InputDecoration(
                labelText: 'Varietas padi (opsional)',
                hintText: 'Contoh: Inpari 32, Ciherang, IR64',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                final tanggal = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _tanggalTanam ?? DateTime.now(),
                );
                if (tanggal != null && mounted) {
                  setState(() => _tanggalTanam = tanggal);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _tanggalTanam == null
                      ? 'Tanggal tanam (opsional)'
                      : 'Tanggal tanam: ${FormatWaktu.panjang(_tanggalTanam!)}',
                ),
              ),
            ),
            if (_tanggalTanam != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _tanggalTanam = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Kosongkan tanggal tanam'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _catatan,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan lahan (opsional)',
                hintText: 'Contoh: Riwayat serangan HDB musim lalu, drainase sedang',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _sibuk ? null : _simpan,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _sibuk
                    ? 'Menyimpan…'
                    : modeEdit
                    ? 'Simpan Perubahan'
                    : 'Simpan petak',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
