class HelpContent {
  const HelpContent({
    required this.title,
    required this.what,
    required this.example,
    required this.where,
  });

  final String title;
  final String what;
  final String example;
  final String where;
}

const Map<String, HelpContent> clinicHelpContent = {
  'sio': HelpContent(
    title: 'SIO klinik',
    what: 'Nomor izin operasional yang tercantum pada dokumen klinik.',
    example: 'Ikuti penulisan nomor yang tertera pada dokumen izin Anda.',
    where: 'Periksa dokumen izin operasional yang diterbitkan untuk klinik.',
  ),
  'clinic_npwp': HelpContent(
    title: 'NPWP klinik',
    what: 'Nomor pajak milik badan atau usaha klinik.',
    example: 'Masukkan 15 atau 16 digit angka sesuai dokumen NPWP.',
    where: 'Lihat kartu atau dokumen NPWP milik klinik.',
  ),
  'fasyankes_code': HelpContent(
    title: 'Kode fasyankes',
    what: 'Kode identitas fasilitas pelayanan kesehatan.',
    example: 'Masukkan kode yang tercantum pada bukti registrasi fasilitas.',
    where: 'Periksa dokumen registrasi fasilitas atau akun layanan terkait.',
  ),
  'deed': HelpContent(
    title: 'Akta pendirian',
    what: 'Nomor akta pendirian badan hukum klinik, jika berlaku.',
    example: 'Salin nomor akta sesuai dokumen, termasuk tanda baca bila ada.',
    where: 'Lihat akta pendirian atau dokumen perubahan badan hukum.',
  ),
  'str': HelpContent(
    title: 'STR',
    what: 'Nomor Surat Tanda Registrasi tenaga kesehatan.',
    example: 'Masukkan nomor persis seperti yang tertera pada dokumen STR.',
    where: 'Periksa dokumen atau akun penerbit STR milik tenaga kesehatan.',
  ),
  'sip': HelpContent(
    title: 'SIP',
    what: 'Nomor Surat Izin Praktik tenaga kesehatan.',
    example: 'Masukkan nomor persis seperti yang tertera pada dokumen SIP.',
    where: 'Periksa dokumen izin praktik yang dimiliki tenaga kesehatan.',
  ),
  'nik': HelpContent(
    title: 'NIK',
    what: 'Nomor Induk Kependudukan tenaga kesehatan.',
    example: 'Masukkan 16 digit angka tanpa spasi.',
    where: 'Lihat KTP milik tenaga kesehatan.',
  ),
  'registration_request': HelpContent(
    title: 'Surat permohonan registrasi',
    what: 'Surat pengantar untuk mengajukan pendaftaran klinik.',
    example: 'Unggah surat yang sudah ditandatangani pihak berwenang.',
    where: 'Siapkan surat internal klinik sesuai proses yang berlaku.',
  ),
  'quality_commitment': HelpContent(
    title: 'Surat komitmen mutu',
    what: 'Pernyataan klinik mengenai komitmen menjaga mutu layanan.',
    example: 'Pastikan nama klinik dan pihak yang menandatangani terbaca.',
    where: 'Gunakan dokumen komitmen mutu yang disiapkan klinik.',
  ),
  'satusehat_org': HelpContent(
    title: 'ID organisasi SATUSEHAT',
    what: 'Identitas organisasi klinik pada layanan SATUSEHAT.',
    example: 'Salin ID organisasi dari akun atau portal SATUSEHAT klinik.',
    where: 'Periksa detail organisasi pada portal SATUSEHAT.',
  ),
  'satusehat_api': HelpContent(
    title: 'Kode API SATUSEHAT',
    what: 'Kredensial rahasia untuk menghubungkan sistem klinik.',
    example: 'Jangan kirim kode ini melalui chat atau unggah sebagai dokumen.',
    where: 'Minta kredensial dari pengelola akun SATUSEHAT klinik.',
  ),
  'service_sop': HelpContent(
    title: 'SOP layanan',
    what: 'Panduan kerja klinik untuk menjalankan layanan tertentu.',
    example: 'Unggah dokumen yang sesuai dengan layanan yang dijalankan.',
    where: 'Minta salinan terbaru kepada penanggung jawab mutu klinik.',
  ),
  'clinic_photo': HelpContent(
    title: 'Foto klinik',
    what: 'Foto yang membantu menunjukkan lokasi atau fasilitas klinik.',
    example: 'Gunakan foto yang terang, fokus, dan tidak menampilkan pasien.',
    where: 'Ambil foto area klinik yang aman untuk dibagikan.',
  ),
};
