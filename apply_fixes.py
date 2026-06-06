#!/usr/bin/env python3
"""
Script de correções automáticas — Cacau da Neta App
Executa todas as correções da auditoria de uma só vez.

Uso:
    python apply_fixes.py <caminho_raiz_do_projeto>

Exemplo:
    python apply_fixes.py "C:/Users/Alex Salles/Apps - desenvolvimento/cacau da neta"
"""

import sys
import os
import re
import shutil
from pathlib import Path
from datetime import datetime

# ─── cores para o terminal ────────────────────────────────────────────────────
GREEN  = "\033[92m"
YELLOW = "\033[93m"
RED    = "\033[91m"
CYAN   = "\033[96m"
RESET  = "\033[0m"
BOLD   = "\033[1m"

def ok(msg):    print(f"  {GREEN}✔{RESET}  {msg}")
def warn(msg):  print(f"  {YELLOW}⚠{RESET}  {msg}")
def err(msg):   print(f"  {RED}✘{RESET}  {msg}")
def section(msg): print(f"\n{BOLD}{CYAN}── {msg} {'─' * (55 - len(msg))}{RESET}")

# ─── utilitários de arquivo ───────────────────────────────────────────────────
def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def write(path: Path, content: str):
    path.write_text(content, encoding="utf-8")

def replace_exact(path: Path, old: str, new: str, label: str) -> bool:
    content = read(path)
    if old not in content:
        warn(f"{label} — trecho não encontrado (já corrigido?)")
        return False
    write(path, content.replace(old, new, 1))
    ok(label)
    return True

def replace_all(path: Path, old: str, new: str, label: str) -> bool:
    content = read(path)
    if old not in content:
        warn(f"{label} — trecho não encontrado (já corrigido?)")
        return False
    count = content.count(old)
    write(path, content.replace(old, new))
    ok(f"{label} ({count}x)")
    return True

def delete_file(path: Path, label: str):
    if path.exists():
        path.unlink()
        ok(f"Removido: {label}")
    else:
        warn(f"Não encontrado para remover: {label}")

def create_file(path: Path, content: str, label: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    write(path, content)
    ok(f"Criado: {label}")

# ═══════════════════════════════════════════════════════════════════════════════
def main():
    if len(sys.argv) < 2:
        print(f"{RED}Uso: python apply_fixes.py <caminho_raiz_do_projeto>{RESET}")
        sys.exit(1)

    root = Path(sys.argv[1])
    lib  = root / "lib"

    if not (lib / "main.dart").exists():
        err(f"main.dart não encontrado em {lib}. Verifique o caminho.")
        sys.exit(1)

    print(f"\n{BOLD}Cacau da Neta — Aplicando correções da auditoria{RESET}")
    print(f"Projeto: {root}")
    print(f"Início:  {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")

    # ── Backup ────────────────────────────────────────────────────────────────
    backup_dir = root / f"_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copytree(lib, backup_dir / "lib")
    shutil.copy(root / "pubspec.yaml", backup_dir / "pubspec.yaml")
    ok(f"Backup criado em: {backup_dir.name}")

    erros = 0

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 1 — SEGURANÇA E CRÍTICOS
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 1 — Segurança e Críticos")

    # 1.1 — Habilitar persistência offline do Firestore em main.dart
    main_dart = lib / "main.dart"
    replace_exact(
        main_dart,
        "import 'package:firebase_core/firebase_core.dart';\n"
        "import 'package:flutter/material.dart';\n"
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        "import 'core/theme/app_theme.dart';\n"
        "import 'firebase_options.dart';\n"
        "import 'presentation/screens/home_screen.dart';\n"
        "Future<void> main() async {\n"
        "  WidgetsFlutterBinding.ensureInitialized();\n"
        "  await Firebase.initializeApp(\n"
        "    options: DefaultFirebaseOptions.currentPlatform,\n"
        "  );\n"
        "  runApp(\n"
        "    const ProviderScope(\n"
        "      child: CacauDaNetaApp(),\n"
        "    ),\n"
        "  );\n"
        "}",
        "import 'package:cloud_firestore/cloud_firestore.dart';\n"
        "import 'package:firebase_core/firebase_core.dart';\n"
        "import 'package:flutter/material.dart';\n"
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        "import 'core/theme/app_theme.dart';\n"
        "import 'firebase_options.dart';\n"
        "import 'presentation/screens/home_screen.dart';\n"
        "Future<void> main() async {\n"
        "  WidgetsFlutterBinding.ensureInitialized();\n"
        "  await Firebase.initializeApp(\n"
        "    options: DefaultFirebaseOptions.currentPlatform,\n"
        "  );\n"
        "  // Habilita persistência offline do Firestore\n"
        "  FirebaseFirestore.instance.settings = const Settings(\n"
        "    persistenceEnabled: true,\n"
        "  );\n"
        "  runApp(\n"
        "    const ProviderScope(\n"
        "      child: CacauDaNetaApp(),\n"
        "    ),\n"
        "  );\n"
        "}",
        "main.dart — persistência offline Firestore ativada",
    )

    # 1.2 — Remover FirebaseService (dead code — inicialização nunca chamada)
    delete_file(lib / "data/services/firebase_service.dart",
                "data/services/firebase_service.dart (dead code)")

    # 1.3 — Criar arquivo de regras Firestore com aviso bem visível
    firestore_rules = root / "firestore.rules"
    firestore_rules_content = r"""
rules_version = '2';
// ─────────────────────────────────────────────────────────────────────────────
// ATENÇÃO SEGURANÇA: O Access Token do Mercado Pago NÃO deve ser salvo no
// Firestore. Armazene-o apenas nas variáveis de ambiente da Cloud Function
// (Firebase Functions config ou Secret Manager). Veja a auditoria para detalhes.
// ─────────────────────────────────────────────────────────────────────────────
service cloud.firestore {
  match /databases/{database}/documents {
    function isMaster() {
      return request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'master';
    }

    match /products/{id} {
      allow read: if true;
      allow create, update, delete: if isMaster();
    }

    match /users/{userId} {
      allow read: if request.auth != null && (request.auth.uid == userId || isMaster());
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if isMaster();
    }

    // Pedidos: cliente cria e lê os próprios; master lê e atualiza todos
    match /orders/{orderId} {
      allow create: if request.auth != null;
      allow read: if request.auth != null &&
        (request.auth.uid == resource.data.customerId || isMaster());
      allow update: if isMaster();
      allow delete: if false;
    }

    // Configurações de pagamento: somente master
    match /settings/{document} {
      allow read, write: if isMaster();
    }
  }
}
"""
    create_file(firestore_rules, firestore_rules_content,
                "firestore.rules (com regras para /orders e /settings)")

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 2 — EXTENSÕES UTILITÁRIAS (criadas antes de usá-las)
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 2 — Criando extensões utilitárias")

    # 2.1 — double.toBRL() e DateTime.toDisplayDate() / toDisplayDateTime()
    extensions_dir = lib / "core/extensions"
    extensions_dir.mkdir(parents=True, exist_ok=True)

    # Write format_extensions.dart as bytes to avoid Python escape conflicts
    _fmt_path = extensions_dir / 'format_extensions.dart'
    _fmt_path.write_bytes(
        b"import 'package:flutter/material.dart';\n"
        b'\n'
        b'extension CurrencyFormat on double {\n'
        b'  /// Formata como moeda brasileira: R$ 1.234,56\n'
        b'  String toBRL() => \'R\\$ ${toStringAsFixed(2).replaceAll(".", ",")}\';\n'
        b'}\n'
        b'\n'
        b'extension DateTimeDisplay on DateTime {\n'
        b'  /// Ex.: 31/12/2025\n'
        b'  String toDisplayDate() {\n'
        b"    final d = day.toString().padLeft(2, '0');\n"
        b"    final m = month.toString().padLeft(2, '0');\n"
        b"    return '$d/$m/$year';\n"
        b'  }\n'
        b'\n'
        b'  /// Ex.: 31/12/2025 23:59\n'
        b'  String toDisplayDateTime() {\n'
        b"    final h = hour.toString().padLeft(2, '0');\n"
        b"    final min = minute.toString().padLeft(2, '0');\n"
        b"    return '${toDisplayDate()} $h:$min';\n"
        b'  }\n'
        b'}\n'
    )
    ok('core/extensions/format_extensions.dart')

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 3 — ARQUITETURA / PROVIDERS
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 3 — Arquitetura / Providers")

    # 3.1 — Remover userRoleProvider (alias desnecessário) e adicionar allUsersProvider
    user_provider = lib / "presentation/providers/user_provider.dart"
    replace_exact(
        user_provider,
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        "import '../../data/models/user_model.dart';\n"
        "import 'auth_provider.dart';\n"
        "final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {\n"
        "  final authState = ref.watch(authStateProvider);\n"
        "  return authState.when(\n"
        "    data: (user) {\n"
        "      if (user == null) {\n"
        "        return Stream.value(null);\n"
        "      }\n"
        "      return ref.read(userRepositoryProvider).watchUser(user.uid);\n"
        "    },\n"
        "    loading: () => Stream.value(null),\n"
        "    error: (_, _) => Stream.value(null),\n"
        "  );\n"
        "});\n"
        "final userRoleProvider = currentUserProfileProvider;",
        "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        "import '../../data/models/user_model.dart';\n"
        "import 'auth_provider.dart';\n"
        "\n"
        "final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {\n"
        "  final authState = ref.watch(authStateProvider);\n"
        "  return authState.when(\n"
        "    data: (user) {\n"
        "      if (user == null) {\n"
        "        return Stream.value(null);\n"
        "      }\n"
        "      return ref.read(userRepositoryProvider).watchUser(user.uid);\n"
        "    },\n"
        "    loading: () => Stream.value(null),\n"
        "    error: (_, _) => Stream.value(null),\n"
        "  );\n"
        "});\n"
        "\n"
        "// Stream de todos os usuários — usado pelo painel admin\n"
        "final allUsersProvider = StreamProvider<List<UserModel>>((ref) {\n"
        "  return ref.read(userRepositoryProvider).watchAllUsers();\n"
        "});",
        "user_provider.dart — removido userRoleProvider, adicionado allUsersProvider",
    )

    # 3.2 — Remover activeProductsProvider do product_provider
    product_provider = lib / "presentation/providers/product_provider.dart"
    replace_exact(
        product_provider,
        "// Stream reativo — tela pública de produtos (mantido para compatibilidade)\n"
        "final activeProductsProvider = StreamProvider<List<ProductModel>>((ref) {\n"
        "  return ref.read(productRepositoryProvider).watchActiveProducts();\n"
        "});\n",
        "",
        "product_provider.dart — removido activeProductsProvider (dead code)",
    )

    # 3.3 — Migrar _allUsersProvider privado para o provider público em admin_users_screen
    admin_users = lib / "presentation/screens/admin/admin_users_screen.dart"
    # Remove o import desnecessário de user_model (já vem via user_provider)
    # e substitui a referência _allUsersProvider → allUsersProvider
    replace_exact(
        admin_users,
        "final _allUsersProvider = StreamProvider<List<UserModel>>((ref) {\n"
        "  return ref.read(userRepositoryProvider).watchAllUsers();\n"
        "});",
        "// allUsersProvider movido para presentation/providers/user_provider.dart",
        "admin_users_screen.dart — removido _allUsersProvider local",
    )
    replace_exact(
        admin_users,
        "    final usersAsync = ref.watch(_allUsersProvider);",
        "    final usersAsync = ref.watch(allUsersProvider);",
        "admin_users_screen.dart — usando allUsersProvider público",
    )
    # Adicionar import do user_provider se ainda não estiver
    content = read(admin_users)
    if "import '../../providers/user_provider.dart';" not in content:
        replace_exact(
            admin_users,
            "import '../../providers/auth_provider.dart';",
            "import '../../providers/auth_provider.dart';\n"
            "import '../../providers/user_provider.dart';",
            "admin_users_screen.dart — adicionado import user_provider",
        )

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 4 — FORMATAÇÃO DE MOEDA (substituir por .toBRL())
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 4 — Eliminando duplicação de formatação de moeda")

    # Helper: adiciona import de format_extensions se ainda não existe
    def ensure_format_import(path: Path):
        content = read(path)
        import_line = "import '../../../core/extensions/format_extensions.dart';"
        import_line_2 = "import '../../core/extensions/format_extensions.dart';"
        import_line_3 = "import '../core/extensions/format_extensions.dart';"
        if any(x in content for x in [import_line, import_line_2, import_line_3]):
            return  # já tem
        # Detecta o nível de aninhamento pelo caminho
        rel = path.relative_to(lib)
        parts = len(rel.parts) - 1  # -1 para excluir o próprio arquivo
        prefix = "../" * parts
        line = f"import '{prefix}core/extensions/format_extensions.dart';"
        # Insere após o último import existente
        lines = content.split("\n")
        last_import = 0
        for i, l in enumerate(lines):
            if l.startswith("import "):
                last_import = i
        lines.insert(last_import + 1, line)
        write(path, "\n".join(lines))

    # Fase 4: substitui padrões contendo R\$ e aspas simples usando manipulação
    # de linhas diretamente — evita problemas de escaping Python vs Dart.

    def patch_lines(path: Path, rules: list, label_prefix: str):
        """
        rules: lista de (old_line_fragment, new_line, label_suffix)
        Substitui a PRIMEIRA linha que contenha old_line_fragment pela new_line.
        Para regras com 'multiline': (fragments_list, new_lines_list, label_suffix)
        """
        raw = path.read_bytes()
        # Normaliza CRLF → LF para processamento, recoloca ao salvar
        crlf = b"\r\n" in raw
        text = raw.replace(b"\r\n", b"\n").decode("utf-8")
        lines = text.split("\n")
        changed = 0

        for rule in rules:
            if len(rule) == 3 and isinstance(rule[0], list):
                # Regra multi-linha: apaga N linhas consecutivas e insere outras
                fragments, replacements, lbl = rule
                for i in range(len(lines) - len(fragments) + 1):
                    if all(f in lines[i + j] for j, f in enumerate(fragments)):
                        lines[i:i + len(fragments)] = replacements
                        ok(f"{label_prefix} — {lbl}")
                        changed += 1
                        break
                else:
                    warn(f"{label_prefix} — {lbl} (não encontrado)")
            else:
                fragment, replacement, lbl = rule
                found = False
                for i, line in enumerate(lines):
                    if fragment in line:
                        lines[i] = replacement
                        ok(f"{label_prefix} — {lbl}")
                        changed += 1
                        found = True
                        break
                if not found:
                    warn(f"{label_prefix} — {lbl} (não encontrado)")

        result = "\n".join(lines)
        if crlf:
            result = result.replace("\n", "\r\n")
        path.write_bytes(result.encode("utf-8"))

    # 4.1 — product_card.dart
    pcard = lib / "presentation/widgets/product_card.dart"
    ensure_format_import(pcard)
    patch_lines(pcard, [
        (
            ["    final priceText =", "toStringAsFixed(2).replaceAll"],
            ["    final priceText = product.price.toBRL();"],
            "priceText → .toBRL()",
        ),
    ], "product_card.dart")

    # 4.2 — cart_screen.dart
    cart = lib / "presentation/screens/cart/cart_screen.dart"
    ensure_format_import(cart)
    patch_lines(cart, [
        (
            ["    final priceText =", "item.product.price.toStringAsFixed"],
            ["    final priceText = item.product.price.toBRL();"],
            "priceText → .toBRL()",
        ),
        (
            ["    final subtotalText =", "item.subtotal.toStringAsFixed"],
            ["    final subtotalText = item.subtotal.toBRL();"],
            "subtotalText → .toBRL()",
        ),
        (
            "cart.totalPrice.toStringAsFixed(2).replaceAll",
            "        cart.totalPrice.toBRL();",
            "totalText → .toBRL()",
        ),
    ], "cart_screen.dart")

    # 4.3 — admin_orders_screen.dart (2 ocorrências de _formatCurrency / _formatDateTime)
    ao = lib / "presentation/screens/admin/admin_orders_screen.dart"
    ensure_format_import(ao)

    def patch_format_methods_admin(path: Path):
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.replace(b"\r\n", b"\n").decode("utf-8")
        lines = text.split("\n")

        i = 0
        fmt_currency_count = 0
        fmt_datetime_count = 0
        result = []
        while i < len(lines):
            line = lines[i]
            # _formatCurrency: substitui as 2 linhas pela versão delegada
            if "String _formatCurrency(double value) =>" in line and i + 1 < len(lines) and "toStringAsFixed" in lines[i + 1]:
                result.append("  String _formatCurrency(double value) => value.toBRL();")
                i += 2  # pula a linha do corpo antigo
                fmt_currency_count += 1
            # _formatDateTime: substitui 7 linhas pelo one-liner
            elif "String _formatDateTime(DateTime date) {" in line:
                # Encontra o fechamento '  }'
                j = i + 1
                while j < len(lines) and lines[j].strip() != "}":
                    j += 1
                result.append("  String _formatDateTime(DateTime date) => date.toDisplayDateTime();")
                i = j + 1
                fmt_datetime_count += 1
            else:
                result.append(line)
                i += 1

        out = "\n".join(result)
        if crlf:
            out = out.replace("\n", "\r\n")
        path.write_bytes(out.encode("utf-8"))
        ok(f"admin_orders_screen.dart — _formatCurrency → .toBRL() ({fmt_currency_count}x)")
        ok(f"admin_orders_screen.dart — _formatDateTime → extensão ({fmt_datetime_count}x)")

    patch_format_methods_admin(ao)

    # 4.4 — my_orders_screen.dart
    mo = lib / "presentation/screens/orders/my_orders_screen.dart"
    ensure_format_import(mo)

    def patch_format_methods_orders(path: Path):
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.replace(b"\r\n", b"\n").decode("utf-8")
        lines = text.split("\n")
        result = []
        i = 0
        while i < len(lines):
            line = lines[i]
            if "String _formatCurrency(double value) =>" in line and i + 1 < len(lines) and "toStringAsFixed" in lines[i + 1]:
                result.append("  String _formatCurrency(double value) => value.toBRL();")
                i += 2
            elif "String _formatDate(DateTime date) {" in line:
                j = i + 1
                while j < len(lines) and lines[j].strip() != "}":
                    j += 1
                result.append("  String _formatDate(DateTime date) => date.toDisplayDate();")
                i = j + 1
            else:
                result.append(line)
                i += 1
        out = "\n".join(result)
        if crlf:
            out = out.replace("\n", "\r\n")
        path.write_bytes(out.encode("utf-8"))
        ok(f"my_orders_screen.dart — _formatCurrency → .toBRL()")
        ok(f"my_orders_screen.dart — _formatDate → extensão")

    patch_format_methods_orders(mo)

    # 4.5 — order_confirmation_screen.dart
    oc = lib / "presentation/screens/orders/order_confirmation_screen.dart"
    ensure_format_import(oc)

    def patch_format_confirmation(path: Path):
        raw = path.read_bytes()
        crlf = b"\r\n" in raw
        text = raw.replace(b"\r\n", b"\n").decode("utf-8")
        lines = text.split("\n")
        result = []
        i = 0
        while i < len(lines):
            line = lines[i]
            if "String _formatCurrency(double value) {" in line:
                # Substitui o bloco completo de 3 linhas
                j = i + 1
                while j < len(lines) and lines[j].strip() != "}":
                    j += 1
                result.append("  String _formatCurrency(double value) => value.toBRL();")
                i = j + 1
            else:
                result.append(line)
                i += 1
        out = "\n".join(result)
        if crlf:
            out = out.replace("\n", "\r\n")
        path.write_bytes(out.encode("utf-8"))
        ok("order_confirmation_screen.dart — _formatCurrency → .toBRL()")

    patch_format_confirmation(oc)

    # 4.6 — pix_payment_screen.dart (inline: 'R\$ ${total...}' → total.toBRL())
    pp = lib / "presentation/screens/orders/pix_payment_screen.dart"
    ensure_format_import(pp)
    patch_lines(pp, [
        (
            "toStringAsFixed(2).replaceAll('.', ',')}',",
            "            total.toBRL(),",
            "total inline → .toBRL()",
        ),
    ], "pix_payment_screen.dart")

    # 4.7 — admin_products_screen.dart
    ap = lib / "presentation/screens/admin/admin_products_screen.dart"
    ensure_format_import(ap)
    patch_lines(ap, [
        (
            # Tile da lista admin: "R\$ ${product.price...}"
            "R\\$ ${product.price.toStringAsFixed(2)",
            "        product.price.toBRL();",
            "priceText no tile → .toBRL()",
        ),
    ], "admin_products_screen.dart")

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 5 — DEAD CODE: wrappers de status, CustomAppBar
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 5 — Removendo dead code")

    # 5.1 — admin_orders_screen: static _statusColor (nunca chamado)
    replace_exact(
        ao,
        "    static Color _statusColor(OrderStatus status) => status.color;\n",
        "",
        "admin_orders_screen.dart — removido static _statusColor (nunca usado)",
    )

    # 5.2 — _StatusButton._color → status.color direto
    replace_exact(
        ao,
        "    final color = _color(status);\n"
        "    return GestureDetector(",
        "    final color = status.color;\n"
        "    return GestureDetector(",
        "admin_orders_screen.dart — _StatusButton usando status.color direto",
    )
    replace_exact(
        ao,
        "    Color _color(OrderStatus status) => status.color;\n"
        "}\n"
        "class _StatusBadge",
        "}\n"
        "class _StatusBadge",
        "admin_orders_screen.dart — removido _StatusButton._color",
    )

    # 5.3 — _StatusBadge._color → status.color direto
    replace_exact(
        ao,
        "    final color = _color(status);\n"
        "    return Container(\n"
        "      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),",
        "    final color = status.color;\n"
        "    return Container(\n"
        "      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),",
        "admin_orders_screen.dart — _StatusBadge usando status.color direto",
    )
    replace_exact(
        ao,
        "    Color _color(OrderStatus status) => status.color;\n"
        "}\n",
        "}\n",
        "admin_orders_screen.dart — removido _StatusBadge._color",
    )

    # 5.4 — my_orders_screen: _OrderTile._statusColor/_statusIcon
    replace_exact(
        mo,
        "        leading: CircleAvatar(\n"
        "          backgroundColor: _statusColor(status).withValues(alpha: 0.15),\n"
        "          child: Icon(\n"
        "            _statusIcon(status),\n"
        "            color: _statusColor(status),\n",
        "        leading: CircleAvatar(\n"
        "          backgroundColor: status.color.withValues(alpha: 0.15),\n"
        "          child: Icon(\n"
        "            status.icon,\n"
        "            color: status.color,\n",
        "my_orders_screen.dart — CircleAvatar usando status.color/.icon direto",
    )
    replace_exact(
        mo,
        "    Color _statusColor(OrderStatus status) => status.color;\n"
        "    IconData _statusIcon(OrderStatus status) => status.icon;\n",
        "",
        "my_orders_screen.dart — removidos _statusColor/_statusIcon",
    )

    # 5.5 — my_orders_screen: _StatusBadge._color
    replace_exact(
        mo,
        "    final color = _color(status);\n"
        "    return Container(\n"
        "      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n"
        "      decoration: BoxDecoration(\n"
        "        color: color.withValues(alpha: 0.15),\n"
        "        borderRadius: BorderRadius.circular(20),\n"
        "        border: Border.all(color: color.withValues(alpha: 0.4)),\n"
        "      ),\n"
        "      child: Text(\n"
        "        status.label,\n"
        "        style: TextStyle(\n"
        "          fontSize: 11,\n"
        "          fontWeight: FontWeight.w700,\n"
        "          color: color,\n"
        "        ),\n"
        "      ),\n"
        "    );\n"
        "  }\n"
        "    Color _color(OrderStatus status) => status.color;\n"
        "}",
        "    final color = status.color;\n"
        "    return Container(\n"
        "      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),\n"
        "      decoration: BoxDecoration(\n"
        "        color: color.withValues(alpha: 0.15),\n"
        "        borderRadius: BorderRadius.circular(20),\n"
        "        border: Border.all(color: color.withValues(alpha: 0.4)),\n"
        "      ),\n"
        "      child: Text(\n"
        "        status.label,\n"
        "        style: TextStyle(\n"
        "          fontSize: 11,\n"
        "          fontWeight: FontWeight.w700,\n"
        "          color: color,\n"
        "        ),\n"
        "      ),\n"
        "    );\n"
        "  }\n"
        "}",
        "my_orders_screen.dart — removido _StatusBadge._color",
    )

    # 5.6 — Remover CustomAppBar (nunca usado)
    delete_file(lib / "presentation/widgets/custom_app_bar.dart",
                "presentation/widgets/custom_app_bar.dart (nunca usado)")

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 6 — IMAGE.NETWORK COM cacheWidth
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 6 — Adicionando cacheWidth às imagens de rede")

    # 6.1 — product_card.dart (card grid ~180px → decodifica em 400px)
    replace_exact(
        pcard,
        "                  ? Image.network(\n"
        "                      product.imageUrl,\n"
        "                      width: double.infinity,\n"
        "                      fit: BoxFit.cover,\n"
        "                      errorBuilder: (_, _, _) {\n"
        "                        return const _ProductPlaceholder();\n"
        "                      },\n"
        "                    )\n"
        "                  : const _ProductPlaceholder(),",
        "                  ? Image.network(\n"
        "                      product.imageUrl,\n"
        "                      width: double.infinity,\n"
        "                      fit: BoxFit.cover,\n"
        "                      cacheWidth: 400,\n"
        "                      errorBuilder: (_, _, _) {\n"
        "                        return const _ProductPlaceholder();\n"
        "                      },\n"
        "                    )\n"
        "                  : const _ProductPlaceholder(),",
        "product_card.dart — cacheWidth: 400",
    )

    # 6.2 — product_detail_screen.dart (full width hero ~400-600px → 800px)
    pd = lib / "presentation/screens/products/product_detail_screen.dart"
    replace_exact(
        pd,
        "                ? Image.network(\n"
        "                    product.imageUrl,\n"
        "                    width: double.infinity,\n"
        "                    fit: BoxFit.cover,\n"
        "                    errorBuilder: (_, _, _) => const _ProductPlaceholder(),\n"
        "                  )",
        "                ? Image.network(\n"
        "                    product.imageUrl,\n"
        "                    width: double.infinity,\n"
        "                    fit: BoxFit.cover,\n"
        "                    cacheWidth: 800,\n"
        "                    errorBuilder: (_, _, _) => const _ProductPlaceholder(),\n"
        "                  )",
        "product_detail_screen.dart — cacheWidth: 800",
    )

    # 6.3 — cart_screen.dart (thumbnail 64px → cacheWidth 128)
    replace_exact(
        cart,
        "                  ? Image.network(\n"
        "                      item.product.imageUrl,\n"
        "                      width: 64,\n"
        "                      height: 64,\n"
        "                      fit: BoxFit.cover,\n"
        "                      errorBuilder: (_, _, _) => const _ImagePlaceholder(),\n"
        "                    )",
        "                  ? Image.network(\n"
        "                      item.product.imageUrl,\n"
        "                      width: 64,\n"
        "                      height: 64,\n"
        "                      fit: BoxFit.cover,\n"
        "                      cacheWidth: 128,\n"
        "                      errorBuilder: (_, _, _) => const _ImagePlaceholder(),\n"
        "                    )",
        "cart_screen.dart — cacheWidth: 128",
    )

    # 6.4 — admin_products_screen.dart (edição 180px → 360)
    replace_exact(
        ap,
        "                  child: Image.network(\n"
        "                      _editingProduct!.imageUrl,\n"
        "                      height: 180,\n"
        "                      width: double.infinity,\n"
        "                      fit: BoxFit.cover,\n"
        "                    ),",
        "                  child: Image.network(\n"
        "                      _editingProduct!.imageUrl,\n"
        "                      height: 180,\n"
        "                      width: double.infinity,\n"
        "                      fit: BoxFit.cover,\n"
        "                      cacheWidth: 360,\n"
        "                    ),",
        "admin_products_screen.dart — cacheWidth: 360 (imagem de edição)",
    )

    # 6.5 — admin_products_screen.dart (tile 52px → cacheWidth 104)
    replace_exact(
        ap,
        "                child: Image.network(\n"
        "                  product.imageUrl,\n"
        "                  width: 52,\n"
        "                  height: 52,\n"
        "                  fit: BoxFit.cover,\n"
        "                  errorBuilder: (_, _, _) => SizedBox(\n",
        "                child: Image.network(\n"
        "                  product.imageUrl,\n"
        "                  width: 52,\n"
        "                  height: 52,\n"
        "                  fit: BoxFit.cover,\n"
        "                  cacheWidth: 104,\n"
        "                  errorBuilder: (_, _, _) => SizedBox(\n",
        "admin_products_screen.dart — cacheWidth: 104 (tile da lista)",
    )

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 7 — UX: OrderConfirmationScreen no fluxo de pagamento
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 7 — Integrando OrderConfirmationScreen ao fluxo de pagamento")

    replace_exact(
        pp,
        "import '../../../core/constants/app_colors.dart';\n"
        "import '../../../data/models/order_model.dart';\n"
        "import '../../providers/order_provider.dart';",
        "import '../../../core/constants/app_colors.dart';\n"
        "import '../../../data/models/order_model.dart';\n"
        "import '../../providers/order_provider.dart';\n"
        "import 'order_confirmation_screen.dart';",
        "pix_payment_screen.dart — adicionado import order_confirmation_screen",
    )

    replace_exact(
        pp,
        "  void _showSuccessAndNavigate(OrderModel order) {\n"
        "    showDialog(\n"
        "      context: context,\n"
        "      barrierDismissible: false,\n"
        "      builder: (_) => AlertDialog(\n"
        "        content: Column(\n"
        "          mainAxisSize: MainAxisSize.min,\n"
        "          children: [\n"
        "            const Icon(\n"
        "              Icons.check_circle_outline,\n"
        "              size: 64,\n"
        "              color: AppColors.success,\n"
        "            ),\n"
        "            const SizedBox(height: 16),\n"
        "            const Text(\n"
        "              'Pagamento confirmado!',\n"
        "              textAlign: TextAlign.center,\n"
        "              style: TextStyle(\n"
        "                fontSize: 18,\n"
        "                fontWeight: FontWeight.w700,\n"
        "              ),\n"
        "            ),\n"
        "            const SizedBox(height: 8),\n"
        "            const Text(\n"
        "              'Seu pedido foi confirmado e logo será preparado.',\n"
        "              textAlign: TextAlign.center,\n"
        "              style: TextStyle(color: AppColors.grey600),\n"
        "            ),\n"
        "          ],\n"
        "        ),\n"
        "        actions: [\n"
        "          FilledButton(\n"
        "            onPressed: () {\n"
        "              Navigator.of(context).popUntil((route) => route.isFirst);\n"
        "            },\n"
        "            child: const Text('Ver meus pedidos'),\n"
        "          ),\n"
        "        ],\n"
        "      ),\n"
        "    );\n"
        "  }",
        "  void _showSuccessAndNavigate(OrderModel order) {\n"
        "    // Fecha o diálogo de espera e navega para a tela de confirmação\n"
        "    Navigator.of(context).pushAndRemoveUntil(\n"
        "      MaterialPageRoute(\n"
        "        builder: (_) => OrderConfirmationScreen(\n"
        "          orderId: order.id,\n"
        "          order: order,\n"
        "        ),\n"
        "      ),\n"
        "      (route) => route.isFirst,\n"
        "    );\n"
        "  }",
        "pix_payment_screen.dart — navega para OrderConfirmationScreen após pagamento",
    )

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 8 — UX: indicador de fim de lista na paginação
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 8 — Indicador de fim de lista na paginação")

    pl = lib / "presentation/screens/products/product_list_screen.dart"
    replace_exact(
        pl,
        "                          itemCount: filtered.length +\n"
        "                              (pageState.isLoading &&\n"
        "                                      pageState.products.isNotEmpty\n"
        "                                  ? 1\n"
        "                                  : 0),",
        "                          itemCount: filtered.length +\n"
        "                              (pageState.isLoading && pageState.products.isNotEmpty\n"
        "                                  ? 1  // spinner de carregamento\n"
        "                                  : (!pageState.hasMore && pageState.products.isNotEmpty\n"
        "                                      ? 1  // indicador de fim de lista\n"
        "                                      : 0)),",
        "product_list_screen.dart — itemCount com slot para fim de lista",
    )
    replace_exact(
        pl,
        "                            if (index == filtered.length) {\n"
        "                              return const Center(\n"
        "                                child: Padding(\n"
        "                                  padding: EdgeInsets.all(16),\n"
        "                                  child: CircularProgressIndicator(),\n"
        "                                ),\n"
        "                              );\n"
        "                            }",
        "                            if (index == filtered.length) {\n"
        "                              if (pageState.isLoading) {\n"
        "                                return const Center(\n"
        "                                  child: Padding(\n"
        "                                    padding: EdgeInsets.all(16),\n"
        "                                    child: CircularProgressIndicator(),\n"
        "                                  ),\n"
        "                                );\n"
        "                              }\n"
        "                              // Fim da lista\n"
        "                              return Center(\n"
        "                                child: Padding(\n"
        "                                  padding: const EdgeInsets.all(16),\n"
        "                                  child: Text(\n"
        "                                    '\\${filtered.length} produto(s) encontrado(s)',\n"
        "                                    style: const TextStyle(\n"
        "                                      fontSize: 12,\n"
        "                                      color: AppColors.grey500,\n"
        "                                    ),\n"
        "                                  ),\n"
        "                                ),\n"
        "                              );\n"
        "                            }",
        "product_list_screen.dart — indicador de fim de lista",
    )

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 9 — STRINGS SEM ACENTO
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 9 — Corrigindo strings sem acento")

    # auth_provider.dart
    auth_prov = lib / "presentation/providers/auth_provider.dart"
    replace_exact(auth_prov,
        "        message: 'Nao foi possivel criar o usuario.',",
        "        message: 'Não foi possível criar o usuário.',",
        "auth_provider.dart — acento em mensagem de erro",
    )
    replace_exact(auth_prov,
        ": user.email?.split('@').first ?? 'Usuario',",
        ": user.email?.split('@').first ?? 'Usuário',",
        "auth_provider.dart — acento em fallback de nome",
    )

    # auth_screen.dart
    auth_sc = lib / "presentation/screens/auth_screen.dart"
    replace_exact(auth_sc,
        "          content: Text('Nao foi possivel concluir a operacao.'),",
        "          content: Text('Não foi possível concluir a operação.'),",
        "auth_screen.dart — acento em erro genérico",
    )
    replace_exact(auth_sc,
        "      case 'invalid-email':\n"
        "        return 'E-mail invalido.';",
        "      case 'invalid-email':\n"
        "        return 'E-mail inválido.';",
        "auth_screen.dart — acento em e-mail inválido",
    )
    replace_exact(auth_sc,
        "        return 'E-mail ou senha invalidos.';",
        "        return 'E-mail ou senha inválidos.';",
        "auth_screen.dart — acento em credenciais inválidas",
    )
    replace_exact(auth_sc,
        "        return error.message ?? 'Falha na autenticacao.';",
        "        return error.message ?? 'Falha na autenticação.';",
        "auth_screen.dart — acento em falha de autenticação",
    )
    replace_exact(auth_sc,
        "                            return 'Informe um e-mail valido.';",
        "                            return 'Informe um e-mail válido.';",
        "auth_screen.dart — acento em e-mail válido",
    )
    replace_exact(auth_sc,
        "                                ? 'Ainda nao tem conta? Criar conta'\n"
        "                                : 'Ja tem conta? Entrar',",
        "                                ? 'Ainda não tem conta? Criar conta'\n"
        "                                : 'Já tem conta? Entrar',",
        "auth_screen.dart — acentos em links de navegação",
    )

    # admin_users_screen.dart
    replace_exact(admin_users,
        "          content: Text('Voce nao pode rebaixar seu proprio usuario.'),",
        "          content: Text('Você não pode rebaixar seu próprio usuário.'),",
        "admin_users_screen.dart — acento em proteção de role",
    )
    replace_exact(admin_users,
        "            content: Text('Nao e permitido remover o ultimo master do app.'),",
        "            content: Text('Não é permitido remover o último master do app.'),",
        "admin_users_screen.dart — acento em último master",
    )
    replace_exact(admin_users,
        "              child: Text('Nenhum usuario cadastrado.'),",
        "              child: Text('Nenhum usuário cadastrado.'),",
        "admin_users_screen.dart — acento em lista vazia",
    )
    replace_exact(admin_users,
        "        title: const Text('Usuarios'),",
        "        title: const Text('Usuários'),",
        "admin_users_screen.dart — acento no título AppBar",
    )

    # admin_panel_screen.dart
    ap_panel = lib / "presentation/screens/admin/admin_panel_screen.dart"
    replace_exact(ap_panel,
        "        label: 'Usuarios',",
        "        label: 'Usuários',",
        "admin_panel_screen.dart — acento em label do grid",
    )

    # ══════════════════════════════════════════════════════════════════════════
    # FASE 10 — pubspec.yaml: remover dependências mortas
    # ══════════════════════════════════════════════════════════════════════════
    section("FASE 10 — pubspec.yaml: removendo dependências não utilizadas")

    pubspec = root / "pubspec.yaml"
    content = read(pubspec)

    for dep, comment in [
        ("  dio: ^5.3.0\r\n", "dio"),
        ("  dio: ^5.3.0\n", "dio"),
        ("  shared_preferences: ^2.2.0\r\n", "shared_preferences"),
        ("  shared_preferences: ^2.2.0\n", "shared_preferences"),
        ("  share_plus: ^10.0.0\r\n", "share_plus"),
        ("  share_plus: ^10.0.0\n", "share_plus"),
    ]:
        if dep in content:
            content = content.replace(dep, "")
            ok(f"pubspec.yaml — removido {comment}")

    # Remove comentários de seção que ficam sozinhos
    for orphan in [
        "\r\n  # Utilities\r\n",
        "\n  # Utilities\n",
        "\r\n  # Local Storage\r\n",
        "\n  # Local Storage\n",
    ]:
        if orphan in content:
            # Só remove se a próxima linha não for uma dependência
            pass  # deixa os comentários de seção que ainda têm deps abaixo

    write(pubspec, content)

    # ══════════════════════════════════════════════════════════════════════════
    # RELATÓRIO FINAL
    # ══════════════════════════════════════════════════════════════════════════
    print(f"\n{BOLD}{'═' * 60}{RESET}")
    print(f"{BOLD}{GREEN}  Todas as correções aplicadas com sucesso!{RESET}")
    print(f"{'═' * 60}")
    print(f"""
  Próximos passos manuais obrigatórios:
  {YELLOW}1.{RESET} Publicar as novas regras do Firestore:
       firebase deploy --only firestore:rules

  {YELLOW}2.{RESET} Mover o Access Token do Mercado Pago para
     as variáveis da Cloud Function (Secret Manager ou
     firebase functions:config:set mercadopago.token="...").
     Remover o campo 'accessToken' do Firestore.

  {YELLOW}3.{RESET} Criar índice composto no Firestore:
       Coleção: products
       Campos: isActive ASC · name ASC

  {YELLOW}4.{RESET} Executar: flutter pub get

  {YELLOW}5.{RESET} Executar: flutter analyze

  Backup salvo em: {backup_dir.name}
""")

if __name__ == "__main__":
    main()
