const XLSX = require('xlsx');
const path = require('path');

const arquivo = process.argv[2] || 'Lista_de_produtos.xlsx';
const wb = XLSX.readFile(path.join(__dirname, arquivo));
const ws = wb.Sheets[wb.SheetNames[0]];

console.log('Abas:', wb.SheetNames);
console.log('Range:', ws['!ref']);
console.log('\nConteúdo bruto (primeiras 10 linhas):');

const rows = XLSX.utils.sheet_to_json(ws, { header: 1, defval: null });
rows.slice(0, 10).forEach((row, i) => {
  console.log(`Linha ${i}:`, JSON.stringify(row));
});
