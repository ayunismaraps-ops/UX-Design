-- Tahap 3: transaksi otomatis, persediaan, jurnal, buku besar, penutupan.

-- COA berganti ke coa.csv. Selama belum ada baris jurnal, daftar akun lama dikosongkan agar seed.py
-- mengisi ulang sesuai coa.csv. Jika pembukuan sudah ada, akun tidak disentuh (seed.py akan menolak).
DELETE FROM "Account" WHERE NOT EXISTS (SELECT 1 FROM "JurnalLine");


ALTER TABLE "Transaksi" ADD COLUMN "noBukti" TEXT;
ALTER TABLE "Transaksi" ADD COLUMN "jenis" TEXT;
ALTER TABLE "Transaksi" ADD COLUMN "pihak" TEXT;
ALTER TABLE "Transaksi" ADD COLUMN "status" TEXT NOT NULL DEFAULT 'terjurnal';
ALTER TABLE "Transaksi" ADD COLUMN "detail" TEXT NOT NULL DEFAULT '{}';
ALTER TABLE "Transaksi" ADD COLUMN "formToken" TEXT;
CREATE UNIQUE INDEX "Transaksi_noBukti_key" ON "Transaksi"("noBukti");
CREATE UNIQUE INDEX "Transaksi_formToken_key" ON "Transaksi"("formToken");

-- Master barang. Jumlah disimpan dalam seperseribu satuan (INTEGER), uang dalam rupiah bulat.
CREATE TABLE "Barang" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "nama" TEXT NOT NULL,
    "namaKunci" TEXT NOT NULL,
    "kategori" TEXT NOT NULL CHECK ("kategori" IN ('dagang', 'perlengkapan')),
    "satuan" TEXT NOT NULL,
    "hargaBeli" INTEGER,
    "hargaJual" INTEGER,
    "aktif" INTEGER NOT NULL DEFAULT 1 CHECK ("aktif" IN (0, 1)),
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX "Barang_kategori_nama_key" ON "Barang"("kategori", "namaKunci");

CREATE TABLE "TransaksiItem" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "transaksiId" TEXT NOT NULL,
    "urut" INTEGER NOT NULL,
    "barangId" TEXT NOT NULL,
    "qty" INTEGER NOT NULL CHECK ("qty" > 0),
    "harga" INTEGER NOT NULL DEFAULT 0 CHECK ("harga" >= 0),
    "diskon" INTEGER NOT NULL DEFAULT 0 CHECK ("diskon" >= 0),
    "subtotal" INTEGER NOT NULL DEFAULT 0,
    "nilaiPokok" INTEGER,
    CONSTRAINT "TransaksiItem_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE RESTRICT,
    CONSTRAINT "TransaksiItem_barangId_fkey" FOREIGN KEY ("barangId") REFERENCES "Barang" ("id") ON DELETE RESTRICT
);
CREATE INDEX "TransaksiItem_transaksiId_idx" ON "TransaksiItem"("transaksiId");

-- Kartu persediaan (buku pembantu). Tidak pernah diubah atau dihapus oleh aplikasi.
CREATE TABLE "KartuPersediaan" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "barangId" TEXT NOT NULL,
    "urut" INTEGER NOT NULL,
    "tanggal" DATETIME NOT NULL,
    "transaksiId" TEXT,
    "jurnalId" TEXT,
    "arah" TEXT NOT NULL CHECK ("arah" IN ('masuk', 'keluar')),
    "sumber" TEXT NOT NULL CHECK ("sumber" IN ('pembelian', 'penjualan', 'kerugian', 'penyesuaian')),
    "qty" INTEGER NOT NULL CHECK ("qty" > 0),
    "nilai" INTEGER NOT NULL CHECK ("nilai" >= 0),
    "saldoQty" INTEGER NOT NULL CHECK ("saldoQty" >= 0),
    "saldoNilai" INTEGER NOT NULL CHECK ("saldoNilai" >= 0),
    "keterangan" TEXT NOT NULL DEFAULT '',
    CONSTRAINT "KartuPersediaan_barangId_fkey" FOREIGN KEY ("barangId") REFERENCES "Barang" ("id") ON DELETE RESTRICT
);
CREATE UNIQUE INDEX "KartuPersediaan_barangId_urut_key" ON "KartuPersediaan"("barangId", "urut");

-- Penomoran berurutan per awalan dan bulan (JU-202611-0001, PJ-202611-0001, ...).
CREATE TABLE "Penomoran" (
    "prefix" TEXT NOT NULL,
    "bulan" TEXT NOT NULL,
    "terakhir" INTEGER NOT NULL,
    PRIMARY KEY ("prefix", "bulan")
);

-- Jejak audit: jurnal dan kartu tidak boleh diubah. Buku besar hanya boleh memperbarui saldoBerjalan.
CREATE TRIGGER "JurnalUmum_tanpa_ubah" BEFORE UPDATE ON "JurnalUmum"
BEGIN SELECT RAISE(ABORT, 'Jurnal umum tidak boleh diubah.'); END;

CREATE TRIGGER "JurnalLine_tanpa_ubah" BEFORE UPDATE ON "JurnalLine"
BEGIN SELECT RAISE(ABORT, 'Baris jurnal tidak boleh diubah.'); END;

CREATE TRIGGER "KartuPersediaan_tanpa_ubah" BEFORE UPDATE ON "KartuPersediaan"
BEGIN SELECT RAISE(ABORT, 'Kartu persediaan tidak boleh diubah.'); END;

CREATE TRIGGER "BukuBesar_hanya_saldo" BEFORE UPDATE OF "id", "jurnalLineId", "periodId", "akunKode", "tanggal", "debit", "kredit" ON "BukuBesar"
BEGIN SELECT RAISE(ABORT, 'Buku besar hanya boleh memperbarui saldo berjalan.'); END;
