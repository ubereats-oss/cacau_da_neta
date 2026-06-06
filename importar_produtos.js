/**
 * importar_produtos.js
 *
 * Importa produtos de uma planilha Excel para o Firestore.
 * Evita duplicatas: se o produto ja existir (mesmo nome + quantidade),
 * atualiza o preco. Se nao existir, cria.
 *
 * USO:
 *   node importar_produtos.js                        <- usa Lista_de_produtos.xlsx
 *   node importar_produtos.js outra_planilha.xlsx    <- usa outro arquivo
 *
 * FORMATO ESPERADO DA PLANILHA:
 *   Linha 1: cabeçalho (Nome | Quantity | Preço | Categoria)
 *   Linha 2+: dados
 *   Coluna A: Nome
 *   Coluna B: Quantity (ex: 250g)
 *   Coluna C: Preço (número)
 *   Coluna D: Categoria (ex: Nibs | Chá | Amêndoas | Geral)
 */

const admin = require("firebase-admin");
const XLSX = require("xlsx");
const fs = require("fs");
const path = require("path");

const SERVICE_ACCOUNT_PATH = process.env.GOOGLE_APPLICATION_CREDENTIALS
  ? path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS)
  : path.join(__dirname, "serviceAccountKeyCacauDaNeta.json");
const ARQUIVO_XLSX = process.argv[2] || "Lista_de_produtos.xlsx";

if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
  console.error(
    `Credencial Firebase nao encontrada: ${SERVICE_ACCOUNT_PATH}\n` +
      "Defina GOOGLE_APPLICATION_CREDENTIALS ou crie serviceAccountKeyCacauDaNeta.json."
  );
  process.exit(1);
}

const serviceAccount = require(SERVICE_ACCOUNT_PATH);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function mapCategoria(categoria) {
  return categoria && categoria.trim().length > 0 ? categoria.trim() : "Geral";
}

function lerPlanilha(caminho) {
  const wb = XLSX.readFile(caminho);
  const ws = wb.Sheets[wb.SheetNames[0]];
  const rows = XLSX.utils.sheet_to_json(ws, { header: 1, defval: null });

  const produtos = [];

  for (let i = 1; i < rows.length; i++) {
    const row = rows[i];

    const nome = (row[0] || "").toString().trim();
    const quantidade = (row[1] || "").toString().trim();
    const preco =
      parseFloat(
        (row[2] || "")
          .toString()
          .replace("R$", "")
          .replace(".", "")
          .replace(",", ".")
      ) || 0;
    const categoria = (row[3] || "").toString().trim();

    if (!nome || preco === 0) continue;

    produtos.push({ nome, quantidade, preco, categoria });
  }

  return produtos;
}

async function importar(produtos) {
  const colecao = db.collection("products");
  let criados = 0;
  let atualizados = 0;
  let erros = 0;

  for (const p of produtos) {
    try {
      const descricao = p.quantidade ? `Embalagem: ${p.quantidade}` : "";
      const categoria = mapCategoria(p.categoria);

      const snapshot = await colecao
        .where("name", "==", p.nome)
        .where("description", "==", descricao)
        .limit(1)
        .get();

      const agora = admin.firestore.FieldValue.serverTimestamp();

      if (!snapshot.empty) {
        await snapshot.docs[0].ref.update({
          price: p.preco,
          category: categoria,
          updatedAt: agora,
        });
        console.log(
          `  Atualizado: ${p.nome} (${p.quantidade}) -> R$ ${p.preco.toFixed(2)}`
        );
        atualizados++;
      } else {
        await colecao.add({
          name: p.nome,
          description: descricao,
          price: p.preco,
          category: categoria,
          imageUrl: "",
          isActive: true,
          isFeatured: false,
          createdAt: agora,
          updatedAt: agora,
        });
        console.log(
          `  Criado:     ${p.nome} (${p.quantidade}) -> R$ ${p.preco.toFixed(2)}`
        );
        criados++;
      }
    } catch (err) {
      console.error(`  Erro em "${p.nome}": ${err.message}`);
      erros++;
    }
  }

  return { criados, atualizados, erros };
}

(async () => {
  const caminhoArquivo = path.join(__dirname, ARQUIVO_XLSX);

  console.log("\nCacau da Neta - Importador de Produtos");
  console.log(`Arquivo: ${caminhoArquivo}\n`);

  let produtos;
  try {
    produtos = lerPlanilha(caminhoArquivo);
  } catch (err) {
    console.error(`Erro ao ler planilha: ${err.message}`);
    process.exit(1);
  }

  if (produtos.length === 0) {
    console.log("Nenhum produto encontrado na planilha.");
    process.exit(0);
  }

  console.log(`${produtos.length} produto(s) encontrado(s). Importando...\n`);

  const { criados, atualizados, erros } = await importar(produtos);

  console.log("\n-----------------------------");
  console.log(`  Criados:     ${criados}`);
  console.log(`  Atualizados: ${atualizados}`);
  console.log(`  Erros:       ${erros}`);
  console.log("-----------------------------\n");

  process.exit(erros > 0 ? 1 : 0);
})();
