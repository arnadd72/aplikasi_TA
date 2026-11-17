import 'package:flutter/material.dart';

import '../data/catatan_lapangan_repository.dart';
import '../models/catatan_lapangan.dart';
import '../theme/app_tokens.dart';

class FormPetakScreen extends StatefulWidget {
  const FormPetakScreen({super.key, required this.repository});

  final CatatanLapanganRepository repository;

  @override
  State<FormPetakScreen> createState() => _FormPetakScreenState();
}

class _FormPetakScreenState extends State<FormPetakScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _lokasi = TextEditingController();
  final _luas = TextEditingController();
  final _varietas = TextEditingController();
  DateTime? _tanggalTanam;
  bool _sibuk = false;

  @override
  void dispose() {
    _nama.dispose();
    _lokasi.dispose();
    _luas.dispose();
    _varietas.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _sibuk = true);
    final luas = double.tryParse(_luas.text.trim().replaceAll(',', '.'));
    await widget.repository.simpanPetak(
      Petak(
        nama: _nama.text.trim(),
        lokasiCatatan: _lokasi.text.trim(),
        luasHektare: luas,
        varietas: _varietas.text.trim(),
        tanggalTanam: _tanggalTanam,
        dibuatPada: DateTime.now(),
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah petak')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(
                labelText: 'Nama petak',
                hintText: 'Contoh: Petak Utara',
              ),
              textInputAction: TextInputAction.next,
              validator: (nilai) => nilai == null || nilai.trim().isEmpty
                  ? 'Nama petak wajib diisi.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _varietas,
              decoration: const InputDecoration(
                labelText: 'Varietas (opsional)',
                hintText: 'Contoh: Inpari 32',
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
                      : '${_tanggalTanam!.day}/${_tanggalTanam!.month}/${_tanggalTanam!.year}',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _lokasi,
              decoration: const InputDecoration(
                labelText: 'Catatan lokasi',
                hintText: 'Contoh: dekat saluran air',
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _luas,
              decoration: const InputDecoration(
                labelText: 'Luas (hektare, opsional)',
                hintText: 'Contoh: 0,75',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (nilai) {
                if (nilai == null || nilai.trim().isEmpty) return null;
                final angka = double.tryParse(nilai.replaceAll(',', '.'));
                return angka == null || angka <= 0
                    ? 'Masukkan luas lebih dari 0.'
                    : null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _sibuk ? null : _simpan,
              icon: const Icon(Icons.save_outlined),
              label: Text(_sibuk ? 'Menyimpan…' : 'Simpan petak'),
            ),
          ],
        ),
      ),
    );
  }
}
