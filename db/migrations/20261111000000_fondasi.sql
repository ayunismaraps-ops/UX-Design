-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "nama" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Account" (
    "kode" TEXT NOT NULL PRIMARY KEY,
    "nama" TEXT NOT NULL,
    "posSaldo" TEXT NOT NULL,
    "posLaporan" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "Period" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "nama" TEXT NOT NULL,
    "tanggalMulai" DATETIME NOT NULL,
    "tanggalAkhir" DATETIME NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'AKTIF'
);

-- CreateTable
CREATE TABLE "Transaksi" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "periodId" TEXT NOT NULL,
    "tanggal" DATETIME NOT NULL,
    "nominal" BIGINT NOT NULL CHECK (typeof("nominal") = 'integer' AND "nominal" BETWEEN 1 AND 999999999999),
    "keterangan" TEXT NOT NULL,
    "menu" TEXT NOT NULL,
    "kategori" TEXT NOT NULL,
    "metode" TEXT NOT NULL,
    "hpp" BIGINT CHECK ("hpp" IS NULL OR (typeof("hpp") = 'integer' AND "hpp" BETWEEN 0 AND 999999999999)),
    "createdById" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Transaksi_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "Period" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Transaksi_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "JurnalUmum" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "nomor" TEXT NOT NULL,
    "periodId" TEXT NOT NULL,
    "transaksiId" TEXT,
    "tanggal" DATETIME NOT NULL,
    "keterangan" TEXT NOT NULL,
    "jenis" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "JurnalUmum_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "Period" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "JurnalUmum_transaksiId_fkey" FOREIGN KEY ("transaksiId") REFERENCES "Transaksi" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "JurnalLine" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "jurnalId" TEXT NOT NULL,
    "akunKode" TEXT NOT NULL,
    "debit" BIGINT NOT NULL DEFAULT 0,
    "kredit" BIGINT NOT NULL DEFAULT 0,
    CONSTRAINT "JurnalLine_satu_sisi" CHECK (
      typeof("debit") = 'integer' AND typeof("kredit") = 'integer'
      AND (("debit" > 0 AND "kredit" = 0) OR ("debit" = 0 AND "kredit" > 0))
    ),
    CONSTRAINT "JurnalLine_jurnalId_fkey" FOREIGN KEY ("jurnalId") REFERENCES "JurnalUmum" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "JurnalLine_akunKode_fkey" FOREIGN KEY ("akunKode") REFERENCES "Account" ("kode") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "BukuBesar" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "jurnalLineId" TEXT NOT NULL,
    "periodId" TEXT NOT NULL,
    "akunKode" TEXT NOT NULL,
    "tanggal" DATETIME NOT NULL,
    "debit" BIGINT NOT NULL DEFAULT 0,
    "kredit" BIGINT NOT NULL DEFAULT 0,
    "saldoBerjalan" BIGINT NOT NULL,
    CONSTRAINT "BukuBesar_satu_sisi" CHECK (
      typeof("debit") = 'integer' AND typeof("kredit") = 'integer' AND typeof("saldoBerjalan") = 'integer'
      AND (("debit" > 0 AND "kredit" = 0) OR ("debit" = 0 AND "kredit" > 0))
    ),
    CONSTRAINT "BukuBesar_jurnalLineId_fkey" FOREIGN KEY ("jurnalLineId") REFERENCES "JurnalLine" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BukuBesar_periodId_fkey" FOREIGN KEY ("periodId") REFERENCES "Period" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "BukuBesar_akunKode_fkey" FOREIGN KEY ("akunKode") REFERENCES "Account" ("kode") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE INDEX "Transaksi_periodId_tanggal_idx" ON "Transaksi"("periodId", "tanggal");

-- CreateIndex
CREATE INDEX "Transaksi_createdById_idx" ON "Transaksi"("createdById");

-- CreateIndex
CREATE UNIQUE INDEX "JurnalUmum_nomor_key" ON "JurnalUmum"("nomor");

-- CreateIndex
CREATE INDEX "JurnalUmum_periodId_tanggal_idx" ON "JurnalUmum"("periodId", "tanggal");

-- CreateIndex
CREATE INDEX "JurnalUmum_transaksiId_idx" ON "JurnalUmum"("transaksiId");

-- CreateIndex
CREATE INDEX "JurnalLine_akunKode_idx" ON "JurnalLine"("akunKode");

-- CreateIndex
CREATE INDEX "JurnalLine_jurnalId_idx" ON "JurnalLine"("jurnalId");

-- CreateIndex
CREATE UNIQUE INDEX "BukuBesar_jurnalLineId_key" ON "BukuBesar"("jurnalLineId");

-- CreateIndex
CREATE INDEX "BukuBesar_periodId_akunKode_tanggal_idx" ON "BukuBesar"("periodId", "akunKode", "tanggal");
