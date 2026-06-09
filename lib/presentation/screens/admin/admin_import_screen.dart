import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_provider.dart';
import '../../../../data/services/xlsx_import_service.dart';

class AdminImportScreen extends ConsumerStatefulWidget {
  const AdminImportScreen({super.key});
  @override
  ConsumerState<AdminImportScreen> createState() => _AdminImportScreenState();
}

class _AdminImportScreenState extends ConsumerState<AdminImportScreen> {
  final _service = XlsxImportService();
  bool _isLoading = false;
  String? _arquivoNome;
  File? _arquivoSelecionado;
  Uint8List? _arquivoBytesWeb;
  XlsxImportResult? _resultado;
  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: kIsWeb,
    );
    if (result == null) return;
    if (kIsWeb) {
      final bytes = result.files.single.bytes;
      if (bytes == null) return;
      setState(() {
        _arquivoBytesWeb = bytes;
        _arquivoSelecionado = null;
        _arquivoNome = result.files.single.name;
        _resultado = null;
      });
    } else {
      if (result.files.single.path == null) return;
      setState(() {
        _arquivoSelecionado = File(result.files.single.path!);
        _arquivoBytesWeb = null;
        _arquivoNome = result.files.single.name;
        _resultado = null;
      });
    }
  }

  Future<void> _importar() async {
    if (_arquivoSelecionado == null && _arquivoBytesWeb == null) return;
    setState(() {
      _isLoading = true;
      _resultado = null;
    });
    try {
      final XlsxImportResult resultado;
      if (kIsWeb && _arquivoBytesWeb != null) {
        resultado = await _service.importarBytes(_arquivoBytesWeb!);
      } else {
        resultado = await _service.importar(_arquivoSelecionado!);
      }
      setState(() => _resultado = resultado);
    } catch (e) {
      setState(() {
        _resultado = XlsxImportResult(
          criados: 0,
          atualizados: 0,
          erros: 1,
          mensagensErro: [e.toString()],
        );
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    if (currentUser == null || !currentUser.isMaster) {
      return const Scaffold(body: Center(child: Text('Acesso negado.')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Planilha')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrução
            Card(
              color: AppColors.primary.withValues(alpha: 0.07),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Formato esperado da planilha',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _FormatRow(col: 'A', label: 'Nome do produto'),
                    _FormatRow(col: 'B', label: 'Quantidade (ex: 250g)'),
                    _FormatRow(col: 'C', label: 'Preço (número, ex: 20.90)'),
                    _FormatRow(
                      col: 'D',
                      label: 'Categoria (ex: Nibs / Chá / Amêndoas / Geral)',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Linha 1: cabeçalho  •  A partir da linha 2: dados',
                      style: TextStyle(fontSize: 12, color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Seleção de arquivo
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _selecionarArquivo,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Selecionar planilha .xlsx'),
            ),
            if (_arquivoNome != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: AppColors.grey600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _arquivoNome!,
                      style: const TextStyle(color: AppColors.grey700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Botão importar
            FilledButton.icon(
              onPressed: ((_arquivoSelecionado == null && _arquivoBytesWeb == null) || _isLoading)
                  ? null
                  : _importar,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isLoading ? 'Importando...' : 'Importar para o banco',
              ),
            ),
            // Resultado
            if (_resultado != null) ...[
              const SizedBox(height: 24),
              _ResultadoCard(resultado: _resultado!),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  const _FormatRow({required this.col, required this.label});
  final String col;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              col,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _ResultadoCard extends StatelessWidget {
  const _ResultadoCard({required this.resultado});
  final XlsxImportResult resultado;
  @override
  Widget build(BuildContext context) {
    final cor = resultado.sucesso ? AppColors.success : AppColors.error;
    final icone = resultado.sucesso
        ? Icons.check_circle_outline
        : Icons.error_outline;
    final titulo = resultado.sucesso
        ? '${resultado.total} produto(s) importado(s) com sucesso!'
        : 'Importação concluída com erros';
    return Card(
      color: cor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.add_circle_outline,
              label: 'Criados',
              value: resultado.criados,
              color: AppColors.success,
            ),
            _StatRow(
              icon: Icons.edit_outlined,
              label: 'Atualizados',
              value: resultado.atualizados,
              color: AppColors.info,
            ),
            if (resultado.erros > 0) ...[
              _StatRow(
                icon: Icons.cancel_outlined,
                label: 'Erros',
                value: resultado.erros,
                color: AppColors.error,
              ),
              const SizedBox(height: 8),
              ...resultado.mensagensErro.map(
                (msg) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• $msg',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppColors.grey700)),
          const Spacer(),
          Text(
            '$value',
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
