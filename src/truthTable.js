// Menghasilkan semua baris kombinasi 0/1 untuk n variabel,
// urutan hitungan biner standar (variabel pertama = bit paling kiri/MSB).
// Contoh variables=["A","B"] -> [[0,0],[0,1],[1,0],[1,1]]
export function truthRows(n) {
  const rows = []
  const total = 2 ** n
  for (let i = 0; i < total; i++) {
    const row = []
    for (let j = n - 1; j >= 0; j--) row.push((i >> j) & 1)
    rows.push(row)
  }
  return rows
}

export const JENIS_BUG = [
  { value: 'urutan', label: 'Bug Urutan' },
  { value: 'kondisi', label: 'Bug Kondisi' },
  { value: 'perulangan', label: 'Bug Perulangan' },
]
