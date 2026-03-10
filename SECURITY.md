# Security and Secrets Handling

This document describes how secrets and sensitive data are handled in these dotfiles.

## Overview

These dotfiles use a **defense-in-depth** approach to security:

1. **No hardcoded secrets** - No passwords, tokens, or keys are stored in the repository
2. **Template-based secrets** - Secrets are injected at apply-time using templates
3. **1Password integration** - Primary secrets management via 1Password CLI
4. **Private file prefix** - Sensitive files use the `private_` prefix
5. **CI/CD validation** - Automated checks for secrets in PRs

## Secrets Management Strategy

### 1. 1Password (Recommended)

1Password is the primary method for managing secrets in these dotfiles.

#### Setup

1. Install 1Password CLI:
   ```bash
   brew install 1password-cli  # macOS
   # or follow: https://developer.1password.com/docs/cli/get-started/
   ```

2. Sign in:
   ```bash
   eval $(op signin)
   ```

3. Verify installation:
   ```bash
   chezmoi doctor | grep 1password
   ```

#### Using Secrets in Templates

```go-template
# SSH config example
{{- if lookPath "op" }}
IdentityFile ~/.ssh/id_ed25519
# Private key from 1Password:
# {{ output "op" "read" "op://Private/SSH Key/private key" }}
{{- end }}
```

### 2. Environment Variables

For CI/CD and container environments, use environment variables:

```go-template
# In template files
api_key = {{ env "API_KEY" | quote }}
```

### 3. Prompt on Apply

For one-time secrets that shouldn't be stored:

```go-template
{{- $secret := promptString "Enter your API key" }}
key = {{ $secret | quote }}
```

## Sensitive Files

The following files contain sensitive data and use the `private_` prefix:

| File | Purpose | Protection |
|------|---------|------------|
| `private_dot_ssh/config` | SSH configuration | `private_` prefix + template |
| `private_dot_ssh/id_*` | SSH keys | `private_` prefix + ignored |
| `private_dot_gnupg/` | GPG configuration | `private_` prefix |

## Files That Are Excluded

These files are excluded from the repository and must be created locally:

| File | Reason | Alternative |
|------|--------|-------------|
| `~/.copilot/config.json` | OAuth tokens | Authenticate with `gh auth login` |
| `~/.claude/.credentials.json` | API keys | Re-authenticate on new machine |
| `~/.config/gh/hosts.yml` | GitHub auth tokens | Use `gh auth login` |
| `~/.config/opencode/antigravity-accounts.json` | Account tokens | Re-authenticate |

## Security Best Practices

### 1. Never Commit Secrets

Before committing, always check:

```bash
# Search for potential secrets
grep -r -i "password\|secret\|token\|key" --include="*.tmpl" .

# Use the built-in chezmoi check
chezmoi execute-template < path/to/template.tmpl
```

### 2. Use Private Prefix

For sensitive files, always use the `private_` prefix:

```bash
# This file will have 600 permissions automatically
private_dot_ssh/config
```

### 3. Template Syntax for Secrets

Always use template syntax for secret injection:

```go-template
# Good - template syntax
password = {{ env "MY_PASSWORD" | quote }}

# Bad - hardcoded
password = "mysecretpassword"
```

### 4. Conditional Secret Loading

Always provide fallbacks when secrets may not be available:

```go-template
{{- if lookPath "op" }}
# Use 1Password secret
api_key = {{ output "op" "read" "op://vault/item/field" | quote }}
{{- else }}
# Fallback - user must set manually
api_key = "set via environment variable"
{{- end }}
```

## CI/CD Security

The GitHub Actions workflows include several security measures:

### TruffleHog Secret Detection

All PRs are scanned for secrets using TruffleHog:

```yaml
- uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    head: HEAD
    extra_args: --debug --only-verified
```

### Template Validation

All templates are validated for syntax errors:

```bash
chezmoi execute-template < file.tmpl
```

### Hardcoded Secret Check

The CI checks for potential hardcoded secrets:

```bash
grep -r -i "password\|secret\|token\|key" --include="*.tmpl" . | grep -v "{{"
```

## SSH Key Management

### Recommended: 1Password SSH Agent

1. Enable SSH agent in 1Password:
   - Settings > Developer > "Use 1Password SSH agent"

2. Configure SSH to use 1Password:
   ```
   # In ~/.ssh/config
   Host *
       IdentityAgent "~/.1password/agent.sock"
   ```

### Alternative: Traditional SSH Keys

```bash
# Generate a new key (do not commit to dotfiles!)
ssh-keygen -t ed25519 -C "your@email.com"

# The key will be created in ~/.ssh/
# This directory is excluded from dotfiles
```

## GPG Key Management

GPG keys should be managed separately from dotfiles:

```bash
# Export keys for backup (do not commit!)
gpg --export-secret-keys > secret-keys-backup.gpg

# Import on new machine
gpg --import secret-keys-backup.gpg
```

## API Token Management

### GitHub Tokens

Use `gh auth login` instead of storing tokens:

```bash
# Authenticate interactively
gh auth login

# This creates ~/.config/gh/hosts.yml (excluded from dotfiles)
```

### Other Services

For services that require API tokens:

1. Store in 1Password
2. Use environment variables
3. Use `chezmoi apply --promptString key=value`

## Incident Response

If a secret is accidentally committed:

1. **Rotate the secret immediately** - Don't rely on git history removal
2. **Revoke old credentials** - Contact the service provider
3. **Document the incident** - For your own records

### Rotating Secrets

```bash
# For SSH keys
ssh-keygen -t ed25519 -C "your@email.com" -f ~/.ssh/id_ed25519_new

# For API tokens
# Generate new token via service's web interface
# Update in 1Password or environment
```

## Security Checklist

Before pushing to a public repository:

- [ ] No hardcoded passwords in templates
- [ ] No API keys in configuration files
- [ ] No private SSH keys committed
- [ ] No OAuth tokens in any files
- [ ] `private_` prefix used for sensitive files
- [ ] .gitignore excludes credential files
- [ ] 1Password is used for secrets where possible
- [ ] Environment variables used for CI/CD secrets

## Reporting Security Issues

If you discover a security vulnerability in these dotfiles:

1. Do not open a public issue
2. Contact the maintainer directly
3. Allow time for remediation before disclosure

## See Also

- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)
- [Chezmoi Secret Management](https://www.chezmoi.io/user-guide/secrets/)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
