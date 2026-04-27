%{
  # --- Common ---
  common_error: "Terjadi kesalahan. Silakan coba lagi.",
  common_cancel: "Dibatalkan.",
  common_invalid_input: "Input tidak valid. Coba lagi.",
  common_not_found: "Tidak ditemukan.",
  common_unauthorized: "Kamu tidak punya akses ke fitur ini.",
  common_yes: "Ya",
  common_no: "Tidak",
  common_back: "« Kembali",
  common_save: "Simpan",
  common_edit: "Ubah",
  common_cancel_action: "Batalkan",
  common_continue: "Lanjutkan",
  common_done: "Selesai",
  common_confirm: "Konfirmasi",
  common_skip: "Lewati",
  common_or: "atau",

  # --- Start & Welcome ---
  start_welcome_new:
    "Halo! 👋 Selamat datang di *Trenurang* — asisten pasar yang membantu kamu beli, jual, dan terhubung.\n\nMau mulai dari mana?",
  start_welcome_back: "Halo lagi, *%{name}*! 👋 Mau ngapain hari ini?",
  start_guest_menu:
    "🛍 Jelajahi pasar\n📋 Daftar sekarang\nℹ️ Tentang Trenurang",
  start_btn_explore: "🛍 Jelajahi Pasar",
  start_btn_register: "📋 Daftar",
  start_btn_about: "ℹ️ Tentang",

  # --- Register ---
  register_start:
    "Oke, kita mulai pendaftaran!\n\n*Langkah 1 dari 5*\nSiapa namamu? (nama lengkap atau nama panggilan)",
  register_step1_name_invalid:
    "Nama tidak valid. Gunakan 2–30 karakter, maksimal 3 kata, bukan kata umum.",
  register_step2_username:
    "*Langkah 2 dari 5*\nPilih username unikmu.\nContoh: `budi_jkt` atau `warung_maju`\n_(Gunakan huruf kecil, angka, atau underscore)_",
  register_step2_username_taken: "Username *%{username}* sudah dipakai. Coba yang lain.",
  register_step2_username_invalid:
    "Username tidak valid. Gunakan huruf kecil, angka, atau underscore (3–30 karakter).",
  register_step3_email:
    "*Langkah 3 dari 5*\nMasukkan email kamu (opsional).\nEmail digunakan untuk notifikasi tagihan dan info penting.",
  register_step3_email_invalid:
    "Format email tidak valid. Coba lagi atau tekan Lewati.",
  register_step4_location:
    "*Langkah 4 dari 5*\nBagikan lokasimu agar pasar terdekat bisa menemukanmu. 📍\n\nKirim lokasi via Telegram atau ketik nama kota/kecamatan.",
  register_step4_location_invalid:
    "Lokasi tidak dikenali. Coba kirim via tombol lokasi Telegram atau ketik nama kota.",
  register_step5_confirm:
    "*Langkah 5 dari 5* — Konfirmasi data kamu:\n\n👤 Nama: *%{name}*\n🔖 Username: `%{username}`\n📧 Email: *%{email}*\n📍 Lokasi: *%{location}*\n\nSudah benar?",
  register_btn_save: "✅ Simpan & Mulai",
  register_btn_restart: "🔄 Ulang dari Awal",
  register_btn_skip: "⏭️ Lewati",
  register_success:
    "🎉 Selamat datang, *%{name}*!\n\nAkun Trenurang kamu sudah aktif. Sekarang kamu bisa jelajahi pasar, buat toko, atau langsung order.",
  register_interrupted:
    "Kamu sedang dalam proses pendaftaran.\n\nMau lanjutkan dari langkah terakhir atau mulai ulang?",
  register_btn_resume: "▶️ Lanjutkan",

  # --- Home ---
  home_buyer: "Halo, *%{name}*! 👋\nMau cari apa hari ini?",
  home_seller: "Halo, *%{name}*! 🏪\nToko aktifmu: *%{store_name}*",
  home_guest: "Halo! 👋 Kamu belum login.\nMau jelajahi pasar dulu atau langsung daftar?",
  home_btn_market: "🛍 Pasar",
  home_btn_store: "🏪 Toko Saya",
  home_btn_orders: "📦 Pesanan",
  home_btn_profile: "👤 Profil",
  home_btn_walkin: "🎫 Kode Walk-in",
  home_btn_relation: "🤝 Relasi B2B",

  # --- Profile ---
  profile_show:
    "👤 *Profil Kamu*\n\nNama: *%{name}*\n🔖 Username: `%{username}`\n📍 Lokasi: *%{location}*\n🌐 Bahasa: *%{lang}*\n⭐ Trust Score: *%{trust_score}*",
  profile_edit_name: "Ketik nama barumu:",
  profile_edit_username: "Ketik username barumu:",
  profile_updated: "✅ Profil berhasil diperbarui.",

  # --- Market ---
  market_prompt_location:
    "📍 Untuk menjelajahi pasar terdekat, bagikan lokasimu dulu.",
  market_no_results: "Tidak ada toko atau produk ditemukan di sekitar kamu.",
  market_browse_prompt: "Mau cari apa?",
  market_btn_find_store: "🔍 Cari Toko",
  market_btn_find_product: "🔍 Cari Produk",

  # --- Store ---
  store_no_store: "Kamu belum punya toko. Mau buat sekarang?",
  store_btn_create: "🏪 Buat Toko",
  store_create_name: "Apa nama tokomu?",
  store_create_type: "Jenis toko:\n- *good* — jual barang\n- *service* — jual jasa\n- *mix* — keduanya",
  store_create_success: "🎉 Toko *%{name}* berhasil dibuat!",
  store_inactive_warning: "⚠️ Toko kamu sedang tidak aktif.",

  # --- Order ---
  order_empty: "Belum ada pesanan.",
  order_created: "✅ Pesanan berhasil dibuat. Kode: `%{code}`",
  order_confirmed: "✅ Pesanan dikonfirmasi oleh penjual.",
  order_cancelled: "❌ Pesanan dibatalkan.",
  order_pending_seller: "⏳ Menunggu konfirmasi penjual...",
  order_walkin_prompt: "Masukkan kode order walk-in yang kamu dapat dari penjual:",
  order_walkin_invalid: "Kode tidak ditemukan atau sudah tidak berlaku.",
  order_walkin_success: "✅ Kode diterima! Order kamu sedang diproses.",

  # --- Golden Code ---
  golden_notify_confirmed:
    "✅ Order kamu dari *%{store_name}* dikonfirmasi. Kode ordermu: `%{code}` — cek hadiahnya! 🎁",
  golden_reveal_winner:
    "🎉 Selamat! Kode `%{code}` adalah *Golden Code* dari *%{store_name}*!\n\nHadiahmu: *%{reward}*\nBerlaku hingga: *%{deadline}*",
  golden_banner: "🎁 Kamu punya hadiah yang belum diklaim!",

  # --- Trust Score ---
  trust_score_tier_unverified: "Belum Teruji",
  trust_score_tier_beginner: "Pemula Aktif",
  trust_score_tier_growing: "Pedagang Tumbuh",
  trust_score_tier_reliable: "Pedagang Andal",
  trust_score_tier_master: "Juragan",

  # --- Settings ---
  settings_menu: "⚙️ *Pengaturan*",
  settings_lang_prompt: "Pilih bahasa:",
  settings_lang_updated: "✅ Bahasa berhasil diubah.",
  settings_chat_disabled: "✅ Chat dari semua penjual dinonaktifkan.",
  settings_chat_enabled: "✅ Chat dari semua penjual diaktifkan kembali.",
  settings_reset_confirm: "⚠️ Ini akan menghapus semua data sesi kamu. Lanjutkan?",
  settings_reset_done: "✅ Sesi berhasil direset.",

  # --- Errors & System ---
  error_gate_l1: "Silakan daftar dulu untuk menggunakan fitur ini. /register",
  error_gate_l2: "Fitur ini hanya untuk pembeli yang sudah pernah order.",
  error_gate_l3: "Fitur ini hanya untuk penjual yang punya toko aktif.",
  error_gate_l4: "Fitur ini hanya untuk penjual dengan relasi B2B aktif.",
  error_unknown_command: "Perintah tidak dikenali. Ketik /help untuk melihat daftar perintah.",
  error_flow_interrupted:
    "Kamu sedang dalam proses *%{flow}*.\n\nMau lanjutkan atau batalkan?",
  error_flow_btn_continue: "▶️ Lanjutkan",
  error_flow_btn_cancel: "✖️ Batalkan",


  # --- About ---
  about_text:
    "*Trenurang* — Infrastruktur ekonomi berbasis AI.\n\nMenghubungkan pembeli, penjual, dan mitra bisnis secara langsung. Dari warung lokal hingga distribusi nasional.",

  # --- Terms ---
  terms_prompt: "Dengan menggunakan Trenurang, kamu menyetujui Syarat & Ketentuan kami.",
  terms_btn_read: "📄 Baca Syarat & Ketentuan",

  # --- Persona ---
  persona_consent_prompt:
    "Boleh kami simpan beberapa info tentang aktivitas ekonomimu untuk membantu mencarikan peluang yang tepat? Data ini tidak dibagikan tanpa izin eksplisit kamu. (UU PDP 2024)",
  persona_consent_btn_yes: "✅ Ya, Saya Setuju",
  persona_consent_btn_no: "❌ Tidak Sekarang",
  persona_consent_granted: "✅ Terima kasih! Kami akan mulai mencarikan peluang yang cocok.",
}
