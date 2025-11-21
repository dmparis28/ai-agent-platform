# AI Agent Platform - Frontend

React + TypeScript frontend with AWS Cognito authentication.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Copy environment variables:
```bash
cp .env.example .env
```

3. Update `.env` with your Cognito values from Terraform outputs

4. Run development server:
```bash
npm run dev
```

5. Build for production:
```bash
npm run build
```

## Deployment to S3

After running `terraform apply`, deploy the built frontend:

```bash
npm run build
aws s3 sync dist/ s3://ai-agent-platform-frontend --delete
```

## Features

- AWS Cognito authentication
- Agent task creation
- Real-time task monitoring
- Cost tracking dashboard
- Mobile-responsive (Galaxy Fold optimized)
