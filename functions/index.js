/**
 * Cloud Functions - Cacau da Neta
 *
 * Funcoes:
 *   criarPagamentoPix  - callable - cria pagamento Pix no Mercado Pago
 *   webhookMercadoPago - HTTPS    - recebe notificacoes de pagamento do MP
 *
 * Setup inicial (executar UMA VEZ no terminal):
 *   firebase functions:secrets:set MERCADOPAGO_ACCESS_TOKEN
 *   (cole o Access Token quando solicitado)
 *
 * Deploy:
 *   firebase deploy --only functions
 */

"use strict";

const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const https = require("https");

initializeApp();

setGlobalOptions({
  region: "southamerica-east1",
  maxInstances: 10,
});

const mpAccessToken = defineSecret("MERCADOPAGO_ACCESS_TOKEN");
const webhookMercadoPagoUrl =
  "https://southamerica-east1-cacau-da-neta.cloudfunctions.net/webhookMercadoPago";

function mpRequest({ method, path, body, token }) {
  return new Promise((resolve, reject) => {
    const payload = body ? JSON.stringify(body) : null;
    const options = {
      hostname: "api.mercadopago.com",
      path,
      method,
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${token}`,
        "X-Idempotency-Key": body?.external_reference ?? Date.now().toString(),
      },
    };

    if (payload) {
      options.headers["Content-Length"] = Buffer.byteLength(payload);
    }

    const req = https.request(options, (res) => {
      let raw = "";
      res.on("data", (chunk) => (raw += chunk));
      res.on("end", () => {
        try {
          resolve({ statusCode: res.statusCode, body: JSON.parse(raw) });
        } catch {
          resolve({ statusCode: res.statusCode, body: raw });
        }
      });
    });

    req.on("error", reject);
    if (payload) req.write(payload);
    req.end();
  });
}

async function getMpConfig(db) {
  const doc = await db.collection("settings").doc("mercadopago").get();
  if (!doc.exists) return { sandbox: true };
  return doc.data();
}

exports.criarPagamentoPix = onCall(
  {
    secrets: [mpAccessToken],
    enforceAppCheck: false,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuario nao autenticado.");
    }

    const { orderId, total, customerEmail, customerName } = request.data;

    if (!orderId || !total || !customerEmail || !customerName) {
      throw new HttpsError(
        "invalid-argument",
        "Parametros obrigatorios ausentes."
      );
    }

    const db = getFirestore();
    const token = mpAccessToken.value();

    if (!token) {
      throw new HttpsError(
        "failed-precondition",
        "Token do Mercado Pago nao configurado. Configure o secret MERCADOPAGO_ACCESS_TOKEN."
      );
    }

    const orderRef = db.collection("orders").doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      throw new HttpsError("not-found", "Pedido nao encontrado.");
    }

    const orderData = orderSnap.data();
    if (orderData.customerId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Acesso negado.");
    }

    const config = await getMpConfig(db);

    const paymentBody = {
      transaction_amount: Number(total.toFixed(2)),
      description: `Pedido Cacau da Neta #${orderId
        .substring(0, 8)
        .toUpperCase()}`,
      payment_method_id: "pix",
      external_reference: orderId,
      notification_url: webhookMercadoPagoUrl,
      payer: {
        email: customerEmail,
        first_name: customerName.split(" ")[0] ?? customerName,
        last_name: customerName.split(" ").slice(1).join(" ") || "-",
      },
    };

    const { statusCode, body: payment } = await mpRequest({
      method: "POST",
      path: "/v1/payments",
      body: paymentBody,
      token,
    });

    if (statusCode !== 201 || !payment.id) {
      console.error("Erro MP:", statusCode, JSON.stringify(payment));
      throw new HttpsError(
        "internal",
        payment?.message ?? "Erro ao criar pagamento no Mercado Pago."
      );
    }

    const pixCode =
      payment.point_of_interaction?.transaction_data?.qr_code ?? "";
    const pixQrCodeBase64 =
      payment.point_of_interaction?.transaction_data?.qr_code_base64 ?? "";
    const paymentId = String(payment.id);

    await orderRef.update({
      pixCode,
      pixQrCodeBase64,
      paymentId,
      mpStatus: payment.status,
      sandbox: config.sandbox ?? true,
      updatedAt: FieldValue.serverTimestamp(),
    });

    console.log(
      `Pix criado - orderId: ${orderId} | paymentId: ${paymentId} | sandbox: ${config.sandbox}`
    );

    return { pixCode, pixQrCodeBase64, paymentId };
  }
);

exports.webhookMercadoPago = onRequest(
  {
    secrets: [mpAccessToken],
  },
  async (req, res) => {
    res.status(200).send("OK");

    try {
      const type = req.body?.type ?? req.query?.topic;
      const dataId = req.body?.data?.id ?? req.query?.id;

      if (type !== "payment" || !dataId) {
        console.log("Webhook ignorado - tipo:", type, "id:", dataId);
        return;
      }

      const token = mpAccessToken.value();
      if (!token) {
        console.error("Secret MERCADOPAGO_ACCESS_TOKEN nao configurado.");
        return;
      }

      const { statusCode, body: payment } = await mpRequest({
        method: "GET",
        path: `/v1/payments/${dataId}`,
        token,
      });

      if (statusCode !== 200) {
        console.error(
          "Erro ao consultar pagamento:",
          statusCode,
          JSON.stringify(payment)
        );
        return;
      }

      const orderId = payment.external_reference;
      const mpStatus = payment.status;

      if (!orderId) {
        console.log("Webhook sem external_reference - paymentId:", dataId);
        return;
      }

      const statusMap = {
        approved: "confirmed",
        pending: "awaiting_payment",
        in_process: "awaiting_payment",
        rejected: "cancelled",
        cancelled: "cancelled",
        refunded: "cancelled",
        charged_back: "cancelled",
      };

      const orderStatus = statusMap[mpStatus] ?? "awaiting_payment";

      const db = getFirestore();
      const orderRef = db.collection("orders").doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        console.error("Pedido nao encontrado para orderId:", orderId);
        return;
      }

      await orderRef.update({
        status: orderStatus,
        mpStatus,
        paymentId: String(payment.id),
        updatedAt: FieldValue.serverTimestamp(),
      });

      console.log(
        `Webhook processado - orderId: ${orderId} | mpStatus: ${mpStatus} | orderStatus: ${orderStatus}`
      );
    } catch (err) {
      console.error("Erro no webhook:", err);
    }
  }
);
