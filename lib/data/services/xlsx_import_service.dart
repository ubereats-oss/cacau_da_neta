import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class XlsxImportResult {
  const XlsxImportResult({
    required this.criados,
    required this.atualizados,
    required this.erros,
    required this.mensagensErro,
  });
  final int criados;
  final int atualizados;
  final int erros;
  final List<String> mensagensErro;
  bool get sucesso => erros == 0;
  int get total => criados + atualizados;
}

class _ProdutoXlsx {
  const _ProdutoXlsx({
    required this.nome,
    required this.quantidade,
    required this.preco,
    required this.categoria,
  });
  final String nome;
  final String quantidade;
  final double preco;
  final String categoria;
}

class XlsxImportService {
  XlsxImportService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// Lê o arquivo .xlsx e importa os produtos para o Firestore.
  ///
  /// Formato esperado da planilha:
  ///   Linha 1: cabeçalho (Nome | Quantity | Preço | Categoria)
  ///   Linha 2+: dados
  ///   Coluna A: Nome
  ///   Coluna B: Quantity (ex: 250g)
  ///   Coluna C: Preço (número)
  ///   Coluna D: Categoria (ex: Nibs | Chá | Amêndoas | Geral)
  Future<XlsxImportResult> importar(File arquivo) async {
    final bytes = await arquivo.readAsBytes();
    return importarBytes(bytes);
  }

  Future<XlsxImportResult> importarBytes(Uint8List bytes) async {
    final workbook = Excel.decodeBytes(bytes);
    final sheetName = workbook.sheets.keys.first;
    final sheet = workbook.sheets[sheetName]!;
    final produtos = _lerProdutos(sheet);
    if (produtos.isEmpty) {
      return const XlsxImportResult(
        criados: 0,
        atualizados: 0,
        erros: 1,
        mensagensErro: ['Nenhum produto encontrado na planilha.'],
      );
    }
    return _salvarNoBanco(produtos);
  }

  List<_ProdutoXlsx> _lerProdutos(Sheet sheet) {
    final produtos = <_ProdutoXlsx>[];
    // Linha 0 = cabeçalho, começa na linha 1
    for (int i = 1; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      final nome = _cellString(row, 0);
      final quantidade = _cellString(row, 1);
      final precoRaw = _cellString(row, 2);
      final categoria = _cellString(row, 3);
      if (nome.isEmpty) continue;
      final preco =
          double.tryParse(
            precoRaw
                .replaceAll('R\$', '')
                .replaceAll('.', '')
                .replaceAll(',', '.')
                .trim(),
          ) ??
          0;
      if (preco <= 0) continue;
      produtos.add(
        _ProdutoXlsx(
          nome: nome,
          quantidade: quantidade,
          preco: preco,
          categoria: categoria,
        ),
      );
    }
    return produtos;
  }

  String _cellString(List<Data?> row, int index) {
    if (index >= row.length) return '';
    final cell = row[index];
    if (cell == null || cell.value == null) return '';
    return cell.value.toString().trim();
  }

  String _mapCategoria(String categoria) {
    return categoria.isNotEmpty ? categoria : 'Geral';
  }

  Future<XlsxImportResult> _salvarNoBanco(List<_ProdutoXlsx> produtos) async {
    final colecao = _db.collection('products');
    int criados = 0;
    int atualizados = 0;
    int erros = 0;
    final mensagensErro = <String>[];
    for (final p in produtos) {
      try {
        final descricao = p.quantidade.isNotEmpty
            ? 'Embalagem: ${p.quantidade}'
            : '';
        final categoria = _mapCategoria(p.categoria);
        final agora = FieldValue.serverTimestamp();
        final snapshot = await colecao
            .where('name', isEqualTo: p.nome)
            .where('description', isEqualTo: descricao)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          await snapshot.docs.first.reference.update({
            'price': p.preco,
            'category': categoria,
            'updatedAt': agora,
          });
          atualizados++;
        } else {
          await colecao.add({
            'name': p.nome,
            'description': descricao,
            'price': p.preco,
            'category': categoria,
            'imageUrl': '',
            'isActive': true,
            'isFeatured': false,
            'createdAt': agora,
            'updatedAt': agora,
          });
          criados++;
        }
      } catch (e) {
        erros++;
        mensagensErro.add('${p.nome}: ${e.toString()}');
      }
    }
    return XlsxImportResult(
      criados: criados,
      atualizados: atualizados,
      erros: erros,
      mensagensErro: mensagensErro,
    );
  }
}
