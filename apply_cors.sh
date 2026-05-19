#!/bin/bash
# Aplica CORS no Firebase Storage e faz deploy no Firebase Hosting
# Execute: chmod +x apply_cors.sh && ./apply_cors.sh

set -e

export PATH=/opt/homebrew/share/google-cloud-sdk/bin:"$PATH"

echo "→ Autenticando no Google Cloud..."
gcloud auth login --project shape-log-app

echo "→ Aplicando CORS no Storage..."
gsutil cors set cors.json gs://shape-log-app.firebasestorage.app

echo "→ Verificando CORS..."
gsutil cors get gs://shape-log-app.firebasestorage.app

echo "✓ CORS aplicado com sucesso!"
echo ""
echo "→ Buildando Flutter Web..."
flutter build web --release --web-renderer canvaskit

echo "→ Fazendo deploy no Firebase Hosting..."
firebase deploy --only hosting --project shape-log-app

echo "✓ Deploy concluído!"
echo "   URL: https://shape-log-app.web.app"
