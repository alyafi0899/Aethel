import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_crop_service.dart';
import '../../../widgets/buttons.dart';
import '../data/media_repository.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_media_model.dart';

class PublicMediaUploader extends StatefulWidget {
  const PublicMediaUploader({
    super.key,
    required this.clinicId,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.existingMedia = const [],
    this.isRequired = false,
    this.onChanged,
    this.mediaRepo,
  });

  final String clinicId;
  final MediaKind kind;
  final String title;
  final String subtitle;
  final List<ClinicMediaModel> existingMedia;
  final bool isRequired;
  final VoidCallback? onChanged;
  final MediaRepository? mediaRepo;

  @override
  State<PublicMediaUploader> createState() => _PublicMediaUploaderState();
}

class _PublicMediaUploaderState extends State<PublicMediaUploader> {
  bool _uploading = false;
  String? _error;

  late final MediaRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.mediaRepo ?? SupabaseMediaRepository();
  }

  Future<void> _pickAndUpload() async {
    final useCamera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto dengan kamera'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih foto'),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
    if (useCamera == null) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      late final String sourcePath;
      late final String selectedName;
      if (useCamera) {
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 100,
        );
        if (!mounted) return;
        if (image == null) {
          setState(() => _uploading = false);
          return;
        }
        sourcePath = image.path;
        selectedName = image.name;
      } else {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        );
        if (!mounted) return;
        if (files.isEmpty) {
          setState(() => _uploading = false);
          return;
        }
        final file = files.first;
        sourcePath = resolveImageCropSourcePath(
          filePath: file.path,
          fileUri: file.uri,
        );
        selectedName = file.name;
      }

      final ratio = switch (widget.kind) {
        MediaKind.logo => (1.0, 1.0),
        MediaKind.cover => (16.0, 9.0),
        MediaKind.gallery => (4.0, 3.0),
      };
      final bytes = await cropAndResizeImage(
        context: context,
        sourcePath: sourcePath,
        ratioX: ratio.$1,
        ratioY: ratio.$2,
        title: switch (widget.kind) {
          MediaKind.logo => 'Pangkas logo klinik',
          MediaKind.cover => 'Pangkas foto sampul',
          MediaKind.gallery => 'Pangkas foto galeri',
        },
      );
      if (!mounted) return;
      if (bytes == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }

      final name = '${selectedName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg';

      if (bytes.isEmpty) {
        throw Exception('Berkas gambar tidak dapat dibaca atau kosong.');
      }

      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Ukuran gambar melebihi batas maksimal 5 MB.');
      }

      const mimeType = 'image/jpeg';

      if (widget.kind == MediaKind.gallery &&
          widget.existingMedia.length >= 8) {
        throw Exception('Batas maksimal galeri adalah 8 foto.');
      }

      await _repo.uploadPublicMedia(
        clinicId: widget.clinicId,
        kind: widget.kind,
        fileName: name,
        bytes: bytes,
        mimeType: mimeType,
        sortOrder:
            widget.kind == MediaKind.gallery ? widget.existingMedia.length : 0,
      );

      if (mounted) {
        setState(() => _uploading = false);
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = ErrorMapper.mapError(e);
        });
      }
    }
  }

  Future<void> _delete(ClinicMediaModel media) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Media Publik?'),
        content:
            const Text('Foto yang terunggah akan dihapus secara permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      await _repo.deleteMedia(media);
      if (mounted) {
        setState(() => _uploading = false);
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = ErrorMapper.mapError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mediaItems =
        widget.existingMedia.where((m) => m.kind == widget.kind).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: mediaItems.isNotEmpty
              ? Colors.green.withValues(alpha: 0.5)
              : (widget.isRequired
                  ? Colors.amber.withValues(alpha: 0.6)
                  : c.border),
          width: mediaItems.isNotEmpty ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: context.sBody
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.isRequired) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Wajib',
                              style: context.sLabel
                                  .copyWith(color: Colors.red, fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: context.sSmall.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              if (widget.kind != MediaKind.gallery || mediaItems.length < 8)
                AppButton(
                  _uploading ? 'Mengunggah...' : 'Pilih Gambar',
                  icon: Icons.image_outlined,
                  kind: BtnKind.secondary,
                  loading: _uploading,
                  onPressed: _pickAndUpload,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Privacy Note Banner
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Foto tampil ke pasien setelah disetujui. Jangan unggah foto yang memuat data atau wajah pasien.',
                    style: context.sSmall
                        .copyWith(color: Colors.blue.shade900, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(_error!,
                        style: context.sSmall
                            .copyWith(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (mediaItems.isEmpty)
            Text('Belum ada gambar ditambahkan.', style: context.sSmall)
          else if (widget.kind == MediaKind.logo)
            _buildLogoPreview(context, mediaItems.first)
          else if (widget.kind == MediaKind.cover)
            _buildCoverPreview(context, mediaItems.first)
          else
            _buildGalleryPreview(context, mediaItems),
        ],
      ),
    );
  }

  Widget _buildLogoPreview(BuildContext context, ClinicMediaModel item) {
    final c = context.c;
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: c.bg,
          backgroundImage:
              item.publicUrl != null ? NetworkImage(item.publicUrl!) : null,
          child: item.publicUrl == null
              ? const Icon(Icons.business, size: 36)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.fileName ?? 'Logo Klinik',
                  style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
              Text(AppFormatters.formatFileSize(item.sizeBytes),
                  style: context.sSmall),
              const SizedBox(height: 4),
              _statusBadge(item.reviewStatus, item.reviewNote),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _delete(item),
        ),
      ],
    );
  }

  Widget _buildCoverPreview(BuildContext context, ClinicMediaModel item) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: c.bg,
              child: item.publicUrl != null
                  ? Image.network(item.publicUrl!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.landscape, size: 48)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.fileName ?? 'Foto Sampul',
                    style: context.sBody.copyWith(fontWeight: FontWeight.bold)),
                Text(AppFormatters.formatFileSize(item.sizeBytes),
                    style: context.sSmall),
              ],
            ),
            Row(
              children: [
                _statusBadge(item.reviewStatus, item.reviewNote),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _delete(item),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryPreview(
      BuildContext context, List<ClinicMediaModel> items) {
    return Column(
      children: items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: item.publicUrl != null
                    ? Image.network(item.publicUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.image),
              ),
            ),
            title: Text(item.fileName ?? 'Foto Galeri'),
            subtitle: Row(
              children: [
                Text(AppFormatters.formatFileSize(item.sizeBytes)),
                const SizedBox(width: 12),
                _statusBadge(item.reviewStatus, item.reviewNote),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(item),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _statusBadge(DocumentReviewStatus status, String? note) {
    Color col = Colors.amber.shade800;
    if (status == DocumentReviewStatus.approved) col = Colors.green;
    if (status == DocumentReviewStatus.rejected) col = Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.label,
            style: TextStyle(
                color: col, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        if (note != null && note.isNotEmpty)
          Text('Catatan: $note',
              style: const TextStyle(color: Colors.red, fontSize: 11)),
      ],
    );
  }
}
