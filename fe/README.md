# AI Agent Platform - Frontend (Next.js)

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.local.example .env.local
# Edit .env.local with your Cognito credentials

# Run development server
npm run dev

# Open http://localhost:3000
```

## Deployment to Lambda

```bash
# Build for production
npm run build

# Package for Lambda
npm run package:lambda

# Deploy (requires AWS CLI configured)
aws lambda update-function-code \
  --function-name nextjs-frontend \
  --zip-file fileb://./dist/lambda.zip
```

## Migration from Vite

This frontend was migrated from Vite to Next.js for:
- Server-side rendering (SSR)
- Better SEO
- Lambda deployment
- Infinite scalability

Previous Vite backup: `../backups/fe-vite-backup-*`
