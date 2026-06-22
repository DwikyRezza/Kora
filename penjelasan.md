# Dokumentasi Sistem Aplikasi Kora
**Kora - Personal Digital Assistant for Athletes**

Dokumen ini menjelaskan alur kerja (flow), arsitektur desain, serta seluruh berkas kode beserta fungsinya di dalam proyek Kora.

---

## 1. Alur Kerja Aplikasi (Application Flow)

Aplikasi Kora memadukan fitur pemantauan kebugaran, nutrisi, jadwal latihan, serta aspek sosial antar atlet. Berikut adalah penjelasan detail mengenai alur utama sistem:

### A. Alur Autentikasi dan Onboarding (Gambar 1 & 2)
1. **Pendaftaran/Login**: Saat membuka aplikasi pertama kali, pengguna disajikan halaman [LandingScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/landing_screen.dart). Pengguna melakukan autentikasi menggunakan Google Sign-In melalui [AuthService](file:///d:/Rezza/Kuliah/Kora/lib/services/auth_service.dart).
2. **Pengecekan Profil di Cloud**: Setelah login berhasil, aplikasi menanyakan status profil ke Cloud Firestore menggunakan [ProfileService](file:///d:/Rezza/Kuliah/Kora/lib/services/profile_service.dart).
   - **Jika pengguna baru (belum onboarding)**: Aplikasi mengalihkan pengguna ke [OnboardingScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/onboarding_screen.dart) untuk mengisi data profil (usia, gender, tinggi badan, berat badan, tujuan kebugaran seperti Bulking/Diet, dan target protein harian). Data profil ini kemudian diunggah ke Cloud Firestore dan disimpan lokal.
   - **Jika pengguna lama (sudah onboarding)**: Aplikasi secara otomatis mengunduh seluruh data historis pengguna dari Cloud Firestore (nutrisi, latihan, riwayat tubuh, jadwal) dan memasukkannya ke database SQLite lokal melalui [CloudSyncService](file:///d:/Rezza/Kuliah/Kora/lib/services/cloud_sync_service.dart).
3. **Dashboard Utama**: Pengguna masuk ke [MainNavigation](file:///d:/Rezza/Kuliah/Kora/lib/main.dart) yang memiliki tab bar untuk mengakses halaman Home, Meal (Nutrisi), Training, Plan (Jadwal), dan Profil.

### B. Alur Pelacakan Aktivitas Lari (Gambar 7)
1. **Memulai Sesi Lari**: Pada halaman [WorkoutScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/workout_screen.dart), pengguna menekan tombol untuk melacak aktivitas lari. Melalui [LocationService](file:///d:/Rezza/Kuliah/Kora/lib/services/location_service.dart), aplikasi akan meminta izin akses GPS dan menonaktifkan optimasi baterai agar pelacakan tidak terhenti di latar belakang.
2. **Android Foreground Service**: Aplikasi mengaktifkan Foreground Service menggunakan paket `flutter_foreground_task` yang menjalankan callback [RunningTaskHandler](file:///d:/Rezza/Kuliah/Kora/lib/services/running_task_handler.dart) di dalam isolate latar belakang terpisah.
3. **Pelacakan Lokasi Real-time**:
   - GPS memancarkan koordinat setiap 1 detik.
   - [RunningTaskHandler](file:///d:/Rezza/Kuliah/Kora/lib/services/running_task_handler.dart) memfilter anomali koordinat (lompatan lokasi > 200 meter atau akurasi buruk > 100 meter).
   - Layanan ini menghitung durasi total, waktu bergerak (*moving time*), akumulasi jarak dalam kilometer, elevasi tanjakan (*elevation gain*), serta laju kecepatan rata-rata per kilometer (*splits*).
   - Statistik diperbarui secara waktu nyata (*real-time*) ke UI melalui port komunikasi data dan ke notifikasi Android yang interaktif (memiliki tombol Pause dan Stop).
4. **Mengakhiri Sesi**: Ketika pengguna menekan tombol Stop, service akan dihentikan. Data ringkasan lari dan jalur koordinat rute (*polyline*) difinalisasi dan disimpan ke dalam SQLite lokal.
5. **Sinkronisasi**: Aplikasi memicu pencadangan otomatis data lari yang baru ke Cloud Firestore secara asinkron.

### C. Alur Pencatatan Nutrisi dan Integrasi Gemini AI
1. **Pencatatan Makanan**: Melalui [ProteinScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/protein_screen.dart), pengguna dapat mencatat asupan makanan (nama makanan, protein, kalori, karbohidrat, lemak, serat, dsb).
2. **Rekomendasi Diet**: [MealRecommenderService](file:///d:/Rezza/Kuliah/Kora/lib/services/meal_recommender_service.dart) memberikan rekomendasi makanan yang cocok berdasarkan tujuan kebugaran pengguna (misal Bulking vs Cutting) serta estimasi anggaran biaya harian (Ekonomi, Medium, Premium).
3. **Konsultasi AI (Gemini AI)**: Pengguna dapat berkonsultasi mengenai nutrisi dan rencana makan di [AiNutritionScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/ai_nutrition_screen.dart) yang terintegrasi dengan Google Generative AI (Gemini) menggunakan `google_generative_ai`.

### D. Alur Sosial dan Interaksi Pengguna
1. **Berbagi Latihan**: Pengguna dapat mempublikasikan aktivitas latihan mereka ke Feed Sosial menggunakan [SocialService](file:///d:/Rezza/Kuliah/Kora/lib/services/social_service.dart).
2. **Interaksi Feed**: Pengguna yang mengikuti (*follow*) atlet lain dapat melihat kiriman di [SocialScreen](file:///d:/Rezza/Kuliah/Kora/lib/screens/social_screen.dart), memberikan Suka (*Like*), serta menulis Komentar pada postingan yang langsung memicu notifikasi cloud ke pembuat postingan.

---

## 2. Arsitektur Desain (Design Architecture)

Kora dibangun menggunakan pendekatan arsitektur yang modular, responsif, dan mendukung kondisi luring (*offline-first*):

### A. Strategi Sinkronisasi Database Hibrida (Hybrid Database Strategy)
* **SQLite (sqflite)**: Bertindak sebagai *Primary Local Cache*. Semua data masukan pengguna (nutrisi, hidrasi, latihan, pengukuran tubuh) langsung disimpan ke SQLite lokal demi respon aplikasi yang super cepat tanpa terhambat latensi jaringan.
* **Cloud Firestore**: Bertindak sebagai *Secondary Backup & Source of Truth*.
  - **Firestore Offline Persistence**: Diaktifkan secara bawaan di `main.dart` untuk mempermudah caching koleksi profil.
  - **Pencadangan (Sync Up)**: Secara berkala (menggunakan batch operasi), data lokal yang baru akan diunggah ke Firestore di bawah dokumen pengguna berdasarkan UID mereka.
  - **Pemulihan (Sync Down)**: Ketika pengguna masuk ke perangkat baru, data lama ditarik sepenuhnya dari Firestore dan di-import ulang ke SQLite lokal.

### B. Isolasi Latar Belakang (Background Isolate Service)
Untuk mematuhi kebijakan sistem operasi Android yang ketat mengenai penggunaan GPS di latar belakang, Kora memisahkan tugas penanganan lokasi dari isolate UI utama:
```
[ Main UI Isolate ] <====== Bidirectional Port ======> [ Background Isolate (Foreground Service) ]
   - Merender UI Peta                                     - Berlangganan Stream GPS (Geolocator)
   - Menerima Data Agregat                                - Menyaring koordinat & Menghitung Jarak/Durasi
   - Memicu Start/Pause/Resume                            - Mengatur Notifikasi Aktif Android
```
Hal ini memastikan aplikasi tidak mengalami lag saat melacak rute dan pelacakan tetap berjalan mulus meskipun aplikasi diminimalkan atau ponsel terkunci.

### C. Pemisahan Berdasarkan Lapisan (Layered Architecture)
Kode diatur ke dalam folder-folder terpisah sesuai dengan fungsinya:
1. **Models**: Representasi struktur data/entitas bisnis.
2. **Services**: Kumpulan kelas logika bisnis murni, integrasi API eksternal (Firebase, Gemini, Strava), dan interaksi database.
3. **Screens**: Lapisan presentasi (UI Halaman).
4. **Widgets**: Komponen UI kecil yang dapat digunakan kembali (*reusable components*).
5. **Theme & Utils**: Konfigurasi tema global, responsivitas layar, dan utilitas pendukung.

---

## 3. Struktur Berkas dan Fungsinya

Berikut adalah pemetaan seluruh berkas di dalam folder `lib` beserta fungsinya masing-masing:

### A. Berkas Utama
* **[lib/main.dart](file:///d:/Rezza/Kuliah/Kora/lib/main.dart)**: Titik masuk utama (*entry point*) aplikasi Flutter. Menginisialisasi Firebase, memuat setelan tema, menyalakan persistensi offline Firestore, menginisialisasi port foreground task, menentukan halaman awal berdasarkan status login/onboarding, dan mengatur widget navigasi navigasi bawah (*Bottom Navigation Bar*).

### B. Folder Models (`lib/models/`)
Menyimpan struktur kelas data yang digunakan di seluruh aplikasi:
* **[body_measurement.dart](file:///d:/Rezza/Kuliah/Kora/lib/models/body_measurement.dart)**: Model data untuk merepresentasikan riwayat pengukuran fisik tubuh pengguna (berat badan, tinggi badan, kadar lemak, lingkar dada, lingkar pinggang, pinggul, dan lengan).
* **[exercise_definition.dart](file:///d:/Rezza/Kuliah/Kora/lib/models/exercise_definition.dart)**: Struktur data pendukung templat gerakan latihan beban (Weightlifting) standar atau kustom.
* **[protein_entry.dart](file:///d:/Rezza/Kuliah/Kora/lib/models/protein_entry.dart)**: Representasi item makanan atau air yang dikonsumsi, mencakup kadar protein, kalori, karbohidrat, lemak, serat, gula, garam, volume air (ml), jenis makan (*breakfast/lunch/dinner/snack*), emoji pendukung, dan tanggal pencatatan.
* **[schedule_event.dart](file:///d:/Rezza/Kuliah/Kora/lib/models/schedule_event.dart)**: Model untuk menyimpan agenda latihan terjadwal, mencakup judul, tipe aktivitas, tanggal-waktu target, durasi, catatan, dan status penyelesaian (`pending`, `done`, `failed`).
* **[workout.dart](file:///d:/Rezza/Kuliah/Kora/lib/models/workout.dart)**: Model utama untuk mencatat sesi latihan pengguna, baik lari (GPS, durasi, jarak, elevasi, pecahan waktu/splits, rute polyline) maupun angkat beban (kumpulan set, repetisi, beban).

### C. Folder Services (`lib/services/`)
Menangani interaksi data, API eksternal, basis data lokal, dan sistem operasi:
* **[auth_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/auth_service.dart)**: Mengelola integrasi Google Sign-In dan Firebase Authentication, mengecek eksistensi profil pengguna di Cloud Firestore, serta menangani proses keluar (*Sign Out*) dan pembersihan data lokal.
* **[cloud_sync_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/cloud_sync_service.dart)**: Melakukan sinkronisasi data hibrida dua arah (*bidirectional sync*) antara database SQLite lokal dan dokumen Cloud Firestore untuk tabel latihan, foto latihan, nutrisi, jadwal, dan antropometri tubuh.
* **[database_helper.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/database_helper.dart)**: Pengelola SQLite lokal. Mengatur inisialisasi basis data `Kora.db`, membuat tabel, mengelola migrasi skema (sekarang versi 12), membuat indeks pencarian untuk tanggal dan nama makanan, serta menyediakan antarmuka CRUD (Create, Read, Update, Delete) lokal.
* **[location_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/location_service.dart)**: Mengelola konfigurasi dan siklus hidup Foreground Service untuk pelacakan lari. Meminta perizinan lokasi/notifikasi, menyalakan mode *Wakelock* agar CPU tetap menyala saat layar mati, serta mengirim sinyal kontrol ke TaskHandler.
* **[meal_recommender_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/meal_recommender_service.dart)**: Mesin pemberi rekomendasi makanan lokal berbasis anggaran biaya harian pengguna (kategori Ekonomi, Medium, Premium) dan target kebugaran (Bulking vs Cutting/Diet).
* **[notification_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/notification_service.dart)**: Mengelola pemberitahuan lokal menggunakan paket `flutter_local_notifications`. Digunakan untuk mendaftarkan pengingat jadwal latihan, serta menyinkronkan notifikasi in-app sosial (suka, komentar, pengikut baru) dari Cloud Firestore.
* **[profile_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/profile_service.dart)**: Mengelola pengambilan, pemutakhiran, dan penyimpanan profil pengguna (baik lokal di SharedPreferences & SQLite maupun di Cloud Firestore). Menentukan apakah pengguna telah menyelesaikan tahapan onboarding.
* **[running_task_handler.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/running_task_handler.dart)**: Kelas penangan tugas latar belakang (*Background Task Handler*) yang diisolasi. Berjalan independen untuk membaca data GPS Geolocation, menghitung metrik statistik lari real-time, meng-update status notifikasi interaktif Android, dan melempar koordinat kembali ke thread UI utama.
* **[settings_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/settings_service.dart)**: Mengelola preferensi pengguna global seperti pilihan tema aplikasi (Terang/Gelap) menggunakan SharedPreferences.
* **[social_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/social_service.dart)**: Menangani interaksi sosial atlet di Firestore, seperti menghitung pengikut (*followers/following*), melakukan follow/unfollow, menerbitkan riwayat latihan ke beranda feed sosial (`feed_posts`), serta mengelola aksi Like dan penulisan Komentar pada postingan.
* **[storage_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/storage_service.dart)**: Mengelola unggah berkas media (foto latihan, foto profil) ke Firebase Storage untuk dibagikan secara online di feed sosial.
* **[whistleblower_service.dart](file:///d:/Rezza/Kuliah/Kora/lib/services/whistleblower_service.dart)**: Mengatur umpan balik audio dan haptik (suara peluit menggunakan `audioplayers` dan pola getaran menggunakan `vibration`) saat sesi latihan selesai atau alarm berbunyi.

### D. Folder Screens (`lib/screens/`)
Berisi kode antarmuka halaman utama dan alur navigasi aplikasi:
* **[landing_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/landing_screen.dart)**: Halaman selamat datang dengan desain minimalis premium. Menampilkan logo Kora dan tombol aksi untuk masuk dengan Google.
* **[login_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/login_screen.dart)**: Halaman login sederhana yang membungkus pemanggilan autentikasi Google.
* **[onboarding_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/onboarding_screen.dart)**: Halaman pengisian profil awal interaktif untuk pengguna baru guna menghitung kebutuhan kalori dan target protein harian mereka.
* **[home_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/home_screen.dart)**: Dashboard utama atlet. Menampilkan statistik kemajuan nutrisi harian (ring protein cair/makro), log air hidrasi, ringkasan latihan terakhir, agenda jadwal hari ini, serta akses cepat ke menu lainnya.
* **[protein_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/protein_screen.dart)**: Halaman manajemen gizi. Menampilkan bagan asupan harian, daftar riwayat makan, fitur pencarian cepat makanan populer, tombol rekomendasi makanan, dan tombol konsultasi gizi AI.
* **[ai_nutrition_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/ai_nutrition_screen.dart)**: Asisten ahli gizi pribadi bertenaga AI. Memungkinkan pengguna berkonsultasi mengenai takaran makanan, resep sehat, atau rencana diet secara langsung dengan Gemini AI.
* **[workout_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/workout_screen.dart)**: Beranda olahraga yang merangkum total latihan mingguan dan riwayat latihan terakhir. Menyediakan tombol melayang (*Floating Action Button*) untuk memulai aktivitas baru.
* **[workout_setup_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/workout_setup_screen.dart)**: Formulir pengaturan latihan untuk memilih tipe olahraga (Lari vs Angkat Beban), target durasi/jarak lari, atau memilih daftar gerakan angkat beban.
* **[running_tracker_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/running_tracker_screen.dart)**: Halaman pelacakan lari aktif. Menampilkan visualisasi peta rute (Google Maps), koordinat jalur rute, kecepatan saat ini (*pace*), total durasi, tanjakan elevasi, dan tombol kontrol Pause/Stop.
* **[weightlifting_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/weightlifting_screen.dart)**: Halaman logging gerakan latihan beban sebelum sesi latihan dimulai.
* **[active_workout_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/active_workout_screen.dart)**: Papan pencatatan aktif latihan angkat beban. Memungkinkan pengguna mencatat beban (kg) dan repetisi untuk setiap set latihan secara berurutan dengan timer istirahat terintegrasi.
* **[workout_summary_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/workout_summary_screen.dart)**: Halaman rangkuman setelah latihan diselesaikan. Menampilkan data statistik lengkap (jarak, kalori, elevation gain, split kecepatan, waktu bergerak), peta rute, opsi mengunggah foto sesi latihan, tombol simpan/publikasikan ke feed, dan tombol bagikan eksternal (mengambil tangkapan layar kartu latihan).
* **[workout_detail_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/workout_detail_screen.dart)**: Menampilkan rincian detail data latihan masa lalu, mencakup peta interaktif jalur lari, statistik splits, dan foto-foto latihan terkait.
* **[schedule_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/schedule_screen.dart)**: Kalender perencanaan latihan mingguan/bulanan. Pengguna dapat membuat jadwal baru, mencatat detail latihan yang direncanakan, serta memicu notifikasi pengingat lokal.
* **[body_stats_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/body_stats_screen.dart)**: Halaman pemantauan parameter tubuh. Menampilkan grafik garis fluktuasi berat badan dan kadar lemak tubuh (menggunakan paket `fl_chart`) serta menginput catatan antropometri baru.
* **[profile_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/profile_screen.dart)**: Halaman profil pengguna yang menyajikan total ringkasan latihan, daftar pengikut/diikuti, tombol menuju edit profil, status langganan premium, tab postingan feed buatan sendiri, dan akses ke pengaturan aplikasi.
* **[edit_profile_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/edit_profile_screen.dart)**: Halaman edit untuk memperbarui data dasar antropometri pengguna seperti berat badan terbaru, tinggi badan, target protein, dan foto profil.
* **[public_profile_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/public_profile_screen.dart)**: Profil publik atlet lain. Menampilkan pencapaian olahraga mereka, jumlah pengikut, tombol follow/unfollow, dan feed postingan yang mereka terbitkan.
* **[social_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/social_screen.dart)**: Feed sosial atlet Kora. Menampilkan postingan latihan dari pengguna lain yang diikuti, daftar pencarian pengguna berdasarkan username untuk berteman, serta daftar pengikut.
* **[setting_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/setting_screen.dart)**: Halaman setelan aplikasi. Menyediakan opsi ganti tema aplikasi (Light/Dark mode) serta tombol logout akun.
* **[weekly_report_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/weekly_report_screen.dart)**: Halaman laporan kebugaran berkala mingguan pengguna yang membandingkan performa latihan dan asupan nutrisi dari minggu ke minggu.
* **[qna_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/qna_screen.dart)**: Halaman tanya-jawab pintar seputar fitur aplikasi Kora dan tips kebugaran umum.
* **[notification_screen.dart](file:///d:/Rezza/Kuliah/Kora/lib/screens/notification_screen.dart)**: Daftar pemberitahuan aktivitas sosial in-app (seperti notifikasi ketika postingan disukai, dikomentari, atau ketika mendapat pengikut baru).

### E. Folder Theme (`lib/theme/`)
* **[app_theme.dart](file:///d:/Rezza/Kuliah/Kora/lib/theme/app_theme.dart)**: Pusat konfigurasi estetika aplikasi. Menyediakan palet warna kustom bertema atletik (Ember Orange, Verdant Green, Signal Red-Orange, Sky Blue, Plum, Iris, Graphite, Fog, dan Paper White), konfigurasi `ThemeData` untuk tema Light dan Dark, serta pengaturan notifier reaktif (`ValueNotifier<ThemeMode>`) untuk pergantian tema seketika.

### F. Folder Utils (`lib/utils/`)
* **[responsive.dart](file:///d:/Rezza/Kuliah/Kora/lib/utils/responsive.dart)**: Utilitas helper untuk menghitung kecocokan ukuran font, padding, dan dimensi widget agar antarmuka aplikasi terukur sempurna di berbagai ukuran layar ponsel (*responsive layout sizing*).
* **[tab_visibility.dart](file:///d:/Rezza/Kuliah/Kora/lib/utils/tab_visibility.dart)**: Kelas pemantau indeks tab aktif di bar navigasi bawah untuk menghentikan render map atau animasi yang tidak terlihat agar hemat baterai.

### G. Folder Widgets (`lib/widgets/`)
Komponen UI modular kecil yang digunakan berulang kali untuk menjaga konsistensi visual:
* **[comment_bottom_sheet.dart](file:///d:/Rezza/Kuliah/Kora/lib/widgets/comment_bottom_sheet.dart)**: Lembar pop-up bawah (*bottom sheet*) interaktif untuk memuat, menampilkan, dan menginput komentar baru pada postingan feed sosial.
* **[common_widgets.dart](file:///d:/Rezza/Kuliah/Kora/lib/widgets/common_widgets.dart)**: Kumpulan komponen UI standar seperti tombol dengan sudut membulat, kartu informasi berdesain premium, indikator loading khusus, dialog konfirmasi, dan input field berdesain seragam.
* **[feed_post_card.dart](file:///d:/Rezza/Kuliah/Kora/lib/widgets/feed_post_card.dart)**: Kartu postingan feed sosial yang membungkus data visual ringkasan latihan atlet (rute peta statis, durasi lari, pace, set beban), tombol toggle Like, dan pintasan membuka lembar komentar.
