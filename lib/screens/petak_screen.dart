import 'package:flutter/material.dart';

import '../data/catatan_lapangan_repository.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../utils/format_waktu.dart';
import '../widgets/komponen.dart';
import 'form_petak_screen.dart';
import 'sesi_survei_screen.dart';
import 'timeline_petak_screen.dart';

/// Halaman Lahan Saya sesuai PRD F-11 dan S-10.
///
/// Menampilkan daftar kartu lahan beserta varietas, luas + satuan,
/// tanggal tanam & umur tanaman (HST), serta akses ke detail lahan,
/// survei, edit, dan penghapusan dengan konfirmasi.
class PetakScreen extends StatefulWidget {
  const PetakScreen({
    super.key,
    this.repository = const DatabaseCatatanLapanganRepository(),
  });

  final CatatanLapanganRepository repository;

  @override
  State<PetakScreen> createState() => _PetakScreenState();
}

class _PetakScreenState extends State<PetakScreen> {
  late Future<List<Petak>> _future;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() => _future = widget.repository.semuaPetak();

  Future<void> _tambah() async {
    final berubah = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormPetakScreen(repository: widget.repository),
      ),
    );
    if (berubah == true && mounted) setState(_muat);
  }

  Future<void> _edit(Petak petak) async {
    final berubah = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            FormPetakScreen(repository: widget.repository, petakAwal: petak),
      ),
    );
    if (berubah == true && mounted) setState(_muat);
  }

  Future<void> _hapus(Petak petak) async {
    final id = petak.idPetak;
    if (id == null) return;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus ${petak.nama}?'),
        content: const Text(
          'Data lahan, jadwal perawatan, dan catatan pengamatan lahan ini '
          'akan dihapus. Riwayat hasil identifikasi tetap dipertahankan '
          'di menu Riwayat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
              minimumSize: const Size(88, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus Lahan'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await widget.repository.hapusPetak(id);
    if (!mounted) return;
    setState(_muat);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${petak.nama} dihapus.')));
  }

  Future<void> _tambahMusim(Petak petak) async {
    final controller = TextEditingController(
      text: 'Musim ${DateTime.now().year}',
    );
    final nama = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mulai musim tanam'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama musim'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nama == null || nama.isEmpty) return;
    await widget.repository.akhiriMusimPetak(petak.idPetak!, DateTime.now());
    await widget.repository.simpanMusim(
      MusimTanam(idPetak: petak.idPetak!, nama: nama, mulai: DateTime.now()),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$nama dimulai.')));
    }
  }

  Future<void> _mulaiSurvei(Petak petak) async {
    final musim = await widget.repository.musimUntukPetak(petak.idPetak!);
    final aktif = musim.where((item) => item.aktif).firstOrNull;
    final sesiAda = await widget.repository.sesiUntukPetak(petak.idPetak!);
    var dasar = sesiAda.where((item) => !item.selesaiDilakukan).firstOrNull;
    if (dasar == null) {
      final baru = SesiSurvei(
        idPetak: petak.idPetak!,
        idMusim: aktif?.idMusim,
        mulai: DateTime.now(),
        targetDaun: 5,
      );
      final id = await widget.repository.mulaiSesi(baru);
      dasar = SesiSurvei(
        idSesi: id,
        idPetak: baru.idPetak,
        idMusim: baru.idMusim,
        mulai: baru.mulai,
        targetDaun: baru.targetDaun,
      );
    }
    final tersimpan = await widget.repository.riwayatSesi(dasar.idSesi!);
    final pengamatanAwal = [
      for (final item in tersimpan)
        PengamatanSurvei(
          idPenyakit: item.idPenyakit,
          tidakPasti: item.status == StatusIdentifikasi.tidakPasti,
        ),
    ];
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SesiSurveiScreen(
          sesi: dasar!,
          namaPetak: petak.nama,
          repository: widget.repository,
          pengamatanAwal: pengamatanAwal,
        ),
      ),
    );
    if (mounted) setState(_muat);
  }

  Future<void> _bukaDetail(Petak petak) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TimelinePetakScreen(petak: petak, repository: widget.repository),
      ),
    );
    if (mounted) setState(_muat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lahan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambah,
        icon: const Icon(Icons.add),
        label: const Text('Tambah petak'),
      ),
      body: FutureBuilder<List<Petak>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return KeadaanKosong(
              ikon: Icons.error_outline,
              judul: 'Lahan gagal dimuat',
              pesan: snapshot.error.toString(),
            );
          }
          final data = snapshot.data ?? const <Petak>[];
          if (data.isEmpty) {
            return KeadaanKosong(
              ikon: Icons.grass_outlined,
              judul: 'Belum ada petak',
              pesan:
                  'Tambahkan lahan atau petak sawah untuk mengelompokkan '
                  'pemeriksaan daun, umur tanaman (HST), pengamatan lapangan, '
                  'dan jadwal perawatan.',
              aksi: FilledButton.icon(
                onPressed: _tambah,
                icon: const Icon(Icons.add),
                label: const Text('Tambah petak'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.horizontal,
              AppSpacing.md,
              AppSpacing.horizontal,
              96,
            ),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.smPlus),
            itemBuilder: (context, index) {
              final petak = data[index];
              final hst = petak.umurHariSetelahTanam();
              final fase = petak.faseTanam();

              return Card(
                child: InkWell(
                  onTap: () => _bukaDetail(petak),
                  borderRadius: BorderRadius.circular(AppRadius.sedang),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    petak.nama,
                                    style: context.teks.titleLarge,
                                  ),
                                  if (petak.lokasiCatatan.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      petak.lokasiCatatan,
                                      style: context.teks.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (hst != null)
                              Lencana(
                                teks: '$hst HST',
                                warna: context.palet.primary,
                                ikon: Icons.schedule_outlined,
                              ),
                            PopupMenuButton<String>(
                              tooltip: 'Opsi lahan',
                              onSelected: (aksi) {
                                switch (aksi) {
                                  case 'edit':
                                    _edit(petak);
                                  case 'musim':
                                    _tambahMusim(petak);
                                  case 'hapus':
                                    _hapus(petak);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit Lahan'),
                                ),
                                PopupMenuItem(
                                  value: 'musim',
                                  child: Text('Mulai Musim Tanam Baru'),
                                ),
                                PopupMenuItem(
                                  value: 'hapus',
                                  child: Text('Hapus Lahan'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 4,
                          children: [
                            if (petak.varietas.isNotEmpty)
                              Text(
                                'Varietas: ${petak.varietas}',
                                style: context.teks.bodySmall,
                              ),
                            if (petak.labelLuas != null)
                              Text(
                                'Luas: ${petak.labelLuas}',
                                style: context.teks.bodySmall,
                              ),
                            if (petak.tanggalTanam != null)
                              Text(
                                'Tanam: ${FormatWaktu.angka(petak.tanggalTanam!)}',
                                style: context.teks.bodySmall,
                              ),
                            if (fase != null)
                              Text(
                                fase,
                                style: context.teks.labelMedium?.copyWith(
                                  color: context.palet.primary,
                                ),
                              ),
                          ],
                        ),
                        if (petak.catatan.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            petak.catatan,
                            style: context.teks.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () => _mulaiSurvei(petak),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Mulai survei'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _bukaDetail(petak),
                              icon: const Icon(Icons.timeline),
                              label: const Text('Timeline'),
                            ),
                            TextButton.icon(
                              onPressed: () => _edit(petak),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
