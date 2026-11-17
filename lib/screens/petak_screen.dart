import 'package:flutter/material.dart';

import '../data/catatan_lapangan_repository.dart';
import '../models/catatan_lapangan.dart';
import '../models/hasil_identifikasi.dart';
import '../theme/app_tokens.dart';
import '../widgets/komponen.dart';
import 'form_petak_screen.dart';
import 'sesi_survei_screen.dart';
import 'timeline_petak_screen.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan lapangan')),
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
              judul: 'Petak gagal dimuat',
              pesan: snapshot.error.toString(),
            );
          }
          final data = snapshot.data ?? const <Petak>[];
          if (data.isEmpty) {
            return KeadaanKosong(
              ikon: Icons.grid_view_outlined,
              judul: 'Belum ada petak',
              pesan:
                  'Tambahkan petak untuk mengelompokkan musim, survei, '
                  'dan hasil pemeriksaan daun.',
              aksi: FilledButton.icon(
                onPressed: _tambah,
                icon: const Icon(Icons.add),
                label: const Text('Tambah petak'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              96,
            ),
            itemCount: data.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final petak = data[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(petak.nama, style: context.teks.titleLarge),
                      if (petak.lokasiCatatan.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(petak.lokasiCatatan),
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
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TimelinePetakScreen(
                                  petak: petak,
                                  repository: widget.repository,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.timeline),
                            label: const Text('Timeline'),
                          ),
                          TextButton.icon(
                            onPressed: () => _tambahMusim(petak),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Musim tanam'),
                          ),
                        ],
                      ),
                    ],
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
