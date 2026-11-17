import 'package:flutter/material.dart';

import '../data/catatan_lapangan_repository.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../models/penyakit.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'detail_riwayat_screen.dart';

class TimelinePetakScreen extends StatefulWidget {
  const TimelinePetakScreen({
    super.key,
    required this.petak,
    required this.repository,
  });

  final Petak petak;
  final CatatanLapanganRepository repository;

  @override
  State<TimelinePetakScreen> createState() => _TimelinePetakScreenState();
}

class _TimelinePetakScreenState extends State<TimelinePetakScreen> {
  int? _idMusim;
  StatusIdentifikasi? _status;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Timeline ${widget.petak.nama}')),
      body: FutureBuilder<List<MusimTanam>>(
        future: widget.repository.musimUntukPetak(widget.petak.idPetak!),
        builder: (context, musimSnapshot) => FutureBuilder<List<Riwayat>>(
          future: widget.repository.timelinePetak(widget.petak.idPetak!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                musimSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || musimSnapshot.hasError) {
              return KeadaanKosong(
                ikon: Icons.error_outline,
                judul: 'Timeline gagal dimuat',
                pesan: '${snapshot.error ?? musimSnapshot.error}',
              );
            }
            final semua = snapshot.data ?? const <Riwayat>[];
            final musim = musimSnapshot.data ?? const <MusimTanam>[];
            if (semua.isEmpty) {
              return const KeadaanKosong(
                ikon: Icons.timeline_outlined,
                judul: 'Belum ada pengamatan',
                pesan: 'Mulai survei untuk membangun catatan perubahan petak.',
              );
            }
            final data = semua.where((item) {
              if (_idMusim != null && item.idMusim != _idMusim) return false;
              if (_status != null && item.status != _status) return false;
              return true;
            }).toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Jumlah sampel diperiksa: ${data.length}',
                        style: context.teks.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: _idMusim,
                              decoration: const InputDecoration(
                                labelText: 'Musim',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua musim'),
                                ),
                                for (final item in musim)
                                  DropdownMenuItem(
                                    value: item.idMusim,
                                    child: Text(item.nama),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _idMusim = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<StatusIdentifikasi?>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Semua status'),
                                ),
                                DropdownMenuItem(
                                  value: StatusIdentifikasi.terklasifikasi,
                                  child: Text('Penyakit'),
                                ),
                                DropdownMenuItem(
                                  value: StatusIdentifikasi.sehat,
                                  child: Text('Sehat'),
                                ),
                                DropdownMenuItem(
                                  value: StatusIdentifikasi.tidakPasti,
                                  child: Text('Tidak pasti'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _status = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: data.isEmpty
                      ? const KeadaanKosong(
                          ikon: Icons.filter_alt_off_outlined,
                          judul: 'Tidak ada yang cocok',
                          pesan: 'Ubah filter musim atau status.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.lg,
                          ),
                          itemCount: data.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final item = data[index];
                            return Card(
                              child: ListTile(
                                minVerticalPadding: AppSpacing.sm,
                                leading: Icon(
                                  item.status == StatusIdentifikasi.tidakPasti
                                      ? Icons.help_outline
                                      : item.idPenyakit == 'normal'
                                      ? Icons.eco_outlined
                                      : Icons.coronavirus_outlined,
                                ),
                                title: Text(
                                  item.penyakit?.nama ??
                                      (item.idPenyakit.isEmpty
                                          ? 'Hasil tidak pasti'
                                          : Penyakit.namaDariId(
                                              item.idPenyakit,
                                            )),
                                ),
                                subtitle: Text(
                                  '${FormatWaktu.panjang(item.waktu)} · '
                                  '${(item.keyakinan * 100).toStringAsFixed(1)}%',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetailRiwayatScreen(riwayat: item),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
