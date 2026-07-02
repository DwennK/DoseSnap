# DoseSnap Backend API

DoseSnap ne doit pas embarquer de cle API IA dans l'app iOS. L'app peut appeler un backend controle par le proprietaire du produit, et ce backend appelle ensuite le fournisseur IA.

## Endpoint

`POST /analyze-food`

Implementation MVP recommandee :

- Cloudflare Workers
- TypeScript
- Hono
- Zod
- MiniMax Vision appele cote Worker

## Input

Option 1, JSON base64 :

```json
{
  "image_base64": "..."
}
```

Option 2, multipart :

```text
file: image/jpeg ou image/png
```

Le backend peut aussi accepter des metadonnees non sensibles comme la langue de reponse ou le pays, si cela aide les portions alimentaires.

Exemple utilise par l'app iOS actuelle :

```json
{
  "image_base64": "...",
  "locale": "fr-FR"
}
```

## Output

```json
{
  "detected_items": [
    {
      "name": "string",
      "estimated_carbs_g": 0,
      "confidence": 0.0
    }
  ],
  "total_carbs_low_g": 0,
  "total_carbs_mid_g": 0,
  "total_carbs_high_g": 0,
  "confidence": 0.0,
  "warnings": ["string"],
  "explanation": "string"
}
```

## Securite

- Ne jamais inclure de cle OpenAI ou autre cle IA dans l'app iOS.
- Authentifier l'app ou l'utilisateur cote backend si l'API est exposee publiquement.
- Limiter la taille des images et supprimer les metadonnees EXIF si elles ne sont pas necessaires.
- Ajouter du rate limiting pour reduire les abus et les couts.
- Retourner des messages prudents : estimation, suggestion, a verifier.
- Ne pas calculer de dose d'insuline cote backend.
- Ne pas stocker `MINIMAX_API_KEY` dans l'app iOS. Utiliser `wrangler secret put MINIMAX_API_KEY`.
- Configurer `APP_API_TOKEN` avec `wrangler secret put APP_API_TOKEN` avant tout backend MiniMax reel.
- Un token applicatif simple ne remplace pas une vraie protection mobile comme App Attest verifie cote serveur ou une auth utilisateur.
- Ne pas activer un mode App Attest / DeviceCheck sans verification Apple cote backend; des headers presents ne constituent pas une preuve.

## Confidentialite

- Eviter de stocker les images brutes.
- Si des logs sont necessaires, journaliser seulement des identifiants anonymises, tailles de payload, statuts et temps de reponse.
- Supprimer ou anonymiser les donnees de debug rapidement.
- Documenter clairement la retention et l'usage des donnees avant tout deploiement reel.
