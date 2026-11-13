import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/context_ext.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_crop_service.dart';
import '../../../widgets/buttons.dart';
import '../data/document_repository.dart';
import '../models/clinic_document_model.dart';
import '../models/clinic_enums.dart';
import '../models/health_worker_models.dart';

class DocumentUploadTile extends StatefulWidget {
  const DocumentUploadTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.clinicId,
    this.docType,
    this.workerId,
    this.workerDocType,
    this.existingClinicDoc,
    this.existingWorkerDoc,
    this.isRequired = false,
    this.allowUpload = true,
    this.onChanged,
    this.documentRepo,
  }) : assert(
          (clinicId != null && docType != null) ||
              (clinicId != null && workerId != null && workerDocType != null),
          'Must provide either clinic document parameters or worker document parameters',
        );

  final String title;
  final String subtitle;
  final String? clinicId;
  final DocumentType? docType;
  final String? workerId;
  final WorkerDocumentType? workerDocType;
  final ClinicDocumentModel? existingClinicDoc;
  final HealthWorkerDocumentModel? existingWorkerDoc;
  final bool isRequired;
  final bool allowUpload;
  final VoidCallback? onChanged;
  final DocumentRepository? documentRepo;

  @override
  State<DocumentUploadTile> createState() => _DocumentUploadTileState();
}

class _DocumentUploadTileState extends State<DocumentUploadTile> {
  bool _uploading = false;
  String? _error;

  late final DocumentRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.documentRepo ?? SupabaseDocumentRepository();
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
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Pilih berkas'),
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
      late final Uint8List bytes;
      late final String name;
      late final String ext;
      if (widget.workerDocType == WorkerDocumentType.profile_photo) {
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
        final croppedBytes = await cropAndResizeImage(
          context: context,
          sourcePath: sourcePath,
          ratioX: 3,
          ratioY: 4,
          title: 'Pangkas pasfoto formal',
        );
        if (!mounted) return;
        if (croppedBytes == null) {
          if (mounted) setState(() => _uploading = false);
          return;
        }
        bytes = croppedBytes;
        name = '${selectedName.replaceAll(RegExp(r'\.[^.]+$'), '')}.jpg';
        ext = 'jpg';
      } else if (useCamera) {
        final image = await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (image == null) {
          if (mounted) setState(() => _uploading = false);
          return;
        }
        bytes = await image.readAsBytes();
        name = image.name;
        ext = 'jpg';
      } else {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        );
        if (files.isEmpty) {
          if (mounted) setState(() => _uploading = false);
          return;
        }
        final file = files.first;
        bytes = await file.readAsBytes();
        name = file.name;
        ext = file.extension?.toLowerCase() ?? '';
      }

      if (bytes.isEmpty) {
        throw Exception('Berkas tidak dapat dibaca atau kosong.');
      }

      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Ukuran berkas melebihi batas maksimal 10 MB.');
      }

      final mimeType = ext == 'pdf'
          ? 'application/pdf'
          : (ext == 'webp'
              ? 'image/webp'
              : 'image/${ext == 'jpg' ? 'jpeg' : ext}');

      if (widget.docType != null && widget.clinicId != null) {
        // Delete previous if exists
        if (widget.existingClinicDoc != null) {
          await _repo.deleteClinicDocument(widget.existingClinicDoc!);
        }
        await _repo.uploadClinicDocument(
          clinicId: widget.clinicId!,
          docType: widget.docType!,
          fileName: name,
          bytes: bytes,
          mimeType: mimeType,
        );
      } else if (widget.workerDocType != null &&
          widget.clinicId != null &&
          widget.workerId != null) {
        if (widget.existingWorkerDoc != null) {
          await _repo.deleteWorkerDocument(widget.existingWorkerDoc!);
        }
        await _repo.uploadWorkerDocument(
          clinicId: widget.clinicId!,
          workerId: widget.workerId!,
          docType: widget.workerDocType!,
          fileName: name,
          bytes: bytes,
          mimeType: mimeType,
        );
      }

      if (mounted) {
        setState(() => _uploading = false);
        widget.onChanged?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Terkirim. Tim kami akan meninjau ulang setelah berkas diperbarui.')),
        );
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

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?'),
        content:
            const Text('Dokumen yang terunggah akan dihapus secara permanen.'),
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
      if (widget.existingClinicDoc != null) {
        await _repo.deleteClinicDocument(widget.existingClinicDoc!);
      } else if (widget.existingWorkerDoc != null) {
        await _repo.deleteWorkerDocument(widget.existingWorkerDoc!);
      }
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

  Future<void> _openSignedUrl(String? signedUrl) async {
    if (signedUrl == null || signedUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tautan pratinjau dokumen tidak tersedia.')),
        );
      }
      return;
    }
    final uri = Uri.tryParse(signedUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Tidak dapat membuka pratinjau dokumen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final clinicDoc = widget.existingClinicDoc;
    final workerDoc = widget.existingWorkerDoc;

    final bool hasDoc = clinicDoc != null || workerDoc != null;
    final String? fileName = clinicDoc?.fileName ?? workerDoc?.fileName;
    final int? sizeBytes = clinicDoc?.sizeBytes ?? workerDoc?.sizeBytes;
    final DocumentReviewStatus reviewStatus = clinicDoc?.reviewStatus ??
        workerDoc?.reviewStatus ??
        DocumentReviewStatus.pending;
    final String? reviewNote = clinicDoc?.reviewNote ?? workerDoc?.reviewNote;
    final String? signedUrl = clinicDoc?.signedUrl ?? workerDoc?.signedUrl;

    Color statusColor = Colors.amber.shade800;
    if (reviewStatus == DocumentReviewStatus.approved) {
      statusColor = Colors.green;
    }
    if (reviewStatus == DocumentReviewStatus.rejected) {
      statusColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasDoc
              ? (reviewStatus == DocumentReviewStatus.approved
                  ? Colors.green.withValues(alpha: 0.5)
                  : c.border)
              : (widget.isRequired
                  ? Colors.amber.withValues(alpha: 0.6)
                  : c.border),
          width: hasDoc ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hasDoc ? Colors.green.withValues(alpha: 0.1) : c.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  hasDoc ? Icons.description : Icons.upload_file,
                  color: hasDoc ? Colors.green : c.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: context.sBody
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.isRequired)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Wajib',
                              style: context.sLabel.copyWith(
                                color: Colors.red,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: context.sSmall.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
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
                    child: Text(
                      _error!,
                      style: context.sSmall
                          .copyWith(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (hasDoc) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fileName ?? 'Dokumen Terunggah',
                          style: context.sBody.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppFormatters.formatFileSize(sizeBytes),
                        style: context.sSmall.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          reviewStatus.label,
                          style: context.sLabel.copyWith(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _openSignedUrl(signedUrl),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_outlined,
                                      size: 14, color: c.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lihat',
                                    style: context.sBody.copyWith(
                                        color: c.accent, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (widget.allowUpload) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _pickAndUpload,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                child: Text(
                                  'Ganti',
                                  style: context.sBody.copyWith(
                                      color: Colors.blue, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _delete,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              child: Text(
                                'Hapus',
                                style: context.sBody
                                    .copyWith(color: Colors.red, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (reviewNote != null && reviewNote.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Catatan peninjau: $reviewNote',
                      style: context.sSmall
                          .copyWith(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ] else if (widget.allowUpload) ...[
            AppButton(
              _uploading ? 'Mengunggah Berkas...' : 'Pilih & Unggah Berkas',
              icon: Icons.file_upload_outlined,
              kind: BtnKind.secondary,
              loading: _uploading,
              onPressed: _pickAndUpload,
            ),
            const SizedBox(height: 4),
            Text(
              'Format didukung: PDF, JPG, PNG, WEBP (maks. 10 MB)',
              style: context.sSmall.copyWith(fontSize: 11),
            ),
          ] else ...[
            Text(
              'Dokumen lama hanya dapat dilihat atau dihapus.',
              style: context.sSmall,
            ),
          ],
        ],
      ),
    );
  }
}
