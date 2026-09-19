/// Kutu durumu — Bekliyor / Boşaltıldı / Alındı (Kaldırıldı)
enum BoxStatus {
  waiting,   // Kutu mekanda bekliyor (yeşil pin)
  emptied,   // Kutu boşaltıldı ama yerinde duruyor (sarı pin)
  collected, // Kutu alındı ve haritadan kaldırıldı
}
