# AI Agent Platform

Production-grade multi-agent AI development platform with specialized agents for software development lifecycle.

## Quick Start

1. Copy environment variables:
   ```powershell
   cp .env.example .env
   ```

2. Configure AWS credentials:
   ```powershell
   .\scripts\setup\init-aws.ps1
   ```

3. Initialize infrastructure:
   ```powershell
   .\scripts\setup\init-terraform.ps1
   ```

4. Deploy everything:
   ```powershell
   .\scripts\deploy\deploy-all.ps1
   ```

## Project Structure

- `infra/` - AWS infrastructure (Terraform)
- `agt/` - AI agents (Python)
- `orch/` - Orchestration (Step Functions, Lambda)
- `fe/` - Frontend (React)
- `sec/` - Security configurations
- `guard/` - Guardrail system
- `mon/` - Monitoring & cost control
- `k8s/` - Kubernetes manifests
- `scripts/` - Automation scripts
- `docs/` - Documentation

## Cost Protection

This platform includes multiple layers of cost protection:
- Real-time kill switch (/hour threshold)
- Daily budget limit (/day)
- Monthly hard cap (/month)
- Nightly cleanup of zombie resources
- Nuclear option for emergency shutdown

## Documentation

See `docs/` directory for detailed documentation.
