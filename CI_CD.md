# CI/CD Documentation

**Comprehensive GitHub Actions workflows for automated building, testing, and releasing**

---

## Overview

EMMA uses GitHub Actions for continuous integration and deployment with multiple specialized workflows:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **Docker CI Build** | Push, PR, Manual | Build and test on every commit |
| **Docker Release** | Tags, Manual | Create official releases |
| **Security Scanning** | Push, PR, Schedule | Security vulnerability scanning |
| **Nightly Build** | Schedule, Manual | Daily build verification |

---

## Workflows

### 1. Docker CI Build

**File:** `.github/workflows/docker-ci.yml`

**Triggers:**
- Push to `main`, `develop`, `claude/**`, `feature/**` branches
- Pull requests to `main`, `develop`
- Manual dispatch with build variant selection

**Jobs:**
- ✅ **Verify** - Environment and configuration check
- ✅ **Build Debug** - Fast debug builds for PRs
- ✅ **Build Release** - Production builds with crypto
- ✅ **Test** - Unit test execution
- ✅ **Build Server** - Python translation server
- ✅ **Security Scan** - Trivy vulnerability scanning
- ✅ **Build Summary** - Consolidated results

**Outputs:**
- Debug APKs (7-day retention)
- Release APKs (30-day retention)
- Test reports (14-day retention)
- Build logs (on failure)

**Usage:**

```bash
# Automatically runs on push/PR

# Manual trigger with variant selection
# GitHub UI: Actions > Docker CI Build > Run workflow > Select variant
```

---

### 2. Docker Release Build

**File:** `.github/workflows/docker-release.yml`

**Triggers:**
- Push to tags matching `v*.*.*`
- Manual dispatch with version input

**Jobs:**
- ✅ **Prepare** - Version validation and parsing
- ✅ **Build All Variants** - Matrix build of all flavors
  - prodGmsWebsiteRelease
  - prodFossWebsiteRelease
  - prodFossStoreRelease
- ✅ **Build Server** - Translation server Docker image
- ✅ **Create Release** - GitHub release with artifacts

**Features:**
- Automatic version detection from git tags
- APK signing (if keystore configured)
- Checksum generation (SHA256)
- Release notes generation
- Multi-variant parallel builds

**Creating a Release:**

```bash
# 1. Tag a version
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 2. Workflow automatically:
#    - Builds all variants
#    - Signs APKs (if keystore configured)
#    - Generates checksums
#    - Creates GitHub release
#    - Uploads all artifacts

# 3. Release published at:
#    https://github.com/SWORDIntel/SWORDCOMM/releases/tag/v1.2.3
```

**Manual Release:**

```bash
# GitHub UI: Actions > Docker Release Build > Run workflow
# Input: v1.2.3
```

**Artifacts:**
- `EMMA-{version}-GMS-{signed|unsigned}.apk`
- `EMMA-{version}-FOSS-{signed|unsigned}.apk`
- `emma-server-{version}.tar.gz`
- SHA256 checksums for all files

---

### 3. Security Scanning

**File:** `.github/workflows/security-scan.yml`

**Triggers:**
- Push to `main`, `develop`
- Pull requests
- Daily at 2 AM UTC
- Manual dispatch

**Scans:**

#### Trivy Scan
- Repository file system scan
- CRITICAL, HIGH, MEDIUM severity
- SARIF upload to GitHub Security

#### Docker Image Scan
- Android builder image scan
- Python server image scan
- Separate security alerts per image

#### Dependency Review
- PR-only dependency analysis
- License compliance checking
- High severity failure threshold

#### Secret Scanning
- TruffleHog OSS integration
- Verified secrets only
- Full history scan

#### Crypto Validation
- Weak algorithm detection
- Post-quantum crypto verification
- Configuration validation

#### Android Security
- Manifest security checks
- Debuggable flag detection
- Clear text traffic audit
- Exported component review

**Security Reports:**
- GitHub Security tab
- SARIF uploads
- Artifact reports
- Job summaries

---

### 4. Nightly Build

**File:** `.github/workflows/nightly-build.yml`

**Triggers:**
- Daily at 3 AM UTC
- Manual dispatch

**Jobs:**
- ✅ **Nightly Build** - Both debug and release
- ✅ **Nightly Tests** - Full test suite
- ✅ **Performance Benchmark** - Build metrics

**Purpose:**
- Catch integration issues early
- Verify build stability
- Track performance trends
- Ensure dependencies are up-to-date

**Artifacts:**
- Nightly builds (7-day retention)
- Test results (14-day retention)
- Performance metrics (30-day retention)

---

## Configuration

### Environment Variables

Set in workflow files or repository settings:

```yaml
env:
  PRODUCTION_CRYPTO: ON
  GRADLE_OPTS: "-Dorg.gradle.daemon=false -Dorg.gradle.parallel=true"
```

### Repository Secrets

Configure in GitHub Settings > Secrets and variables > Actions:

| Secret | Required | Purpose |
|--------|----------|---------|
| `SECRET_KEYSTORE` | Optional | Base64-encoded keystore file |
| `SECRET_KEYSTORE_PASSWORD` | Optional | Keystore password |
| `SECRET_KEYSTORE_ALIAS` | Optional | Key alias |

**Creating secrets:**

```bash
# 1. Generate keystore
keytool -genkey -v -keystore my-release-key.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias my-alias

# 2. Encode keystore
base64 my-release-key.jks

# 3. Add to GitHub:
#    Settings > Secrets > New repository secret
#    Name: SECRET_KEYSTORE
#    Value: <base64 output>

# 4. Add password and alias secrets
```

### Repository Variables

Optional build customization:

| Variable | Default | Purpose |
|----------|---------|---------|
| `CI_APP_TITLE` | EMMA | App display name |
| `CI_PACKAGE_ID` | im.molly.app | Package identifier |
| `CI_BUILD_VARIANTS` | prod(Gms\|Foss) | Build variant regex |

---

## Workflow Features

### Caching

All workflows use multi-layer caching:

- **Docker Buildx cache** - Layer caching for fast rebuilds
- **Gradle cache** - Dependency and build cache
- **Workflow-specific keys** - Separate caches per workflow

### Disk Space Management

Automatic cleanup before builds:

```yaml
- name: Free up disk space
  run: |
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /usr/local/lib/android
    sudo rm -rf /opt/ghc
    sudo docker image prune --all --force
```

### Build Summaries

All workflows generate markdown summaries in the GitHub UI with:
- Job status
- Artifact locations
- Configuration used
- Links to artifacts

### Parallel Builds

Release workflow uses matrix strategy:

```yaml
strategy:
  matrix:
    variant:
      - prodGmsWebsiteRelease
      - prodFossWebsiteRelease
      - prodFossStoreRelease
  fail-fast: false
```

---

## Usage Examples

### Running Workflows Manually

#### Docker CI Build

```
1. Go to: Actions > Docker CI Build
2. Click: Run workflow
3. Select branch: main
4. Select build variant: debug/release/full
5. Click: Run workflow
```

#### Docker Release Build

```
1. Go to: Actions > Docker Release Build
2. Click: Run workflow
3. Enter version: v1.2.3
4. Click: Run workflow
```

#### Security Scanning

```
1. Go to: Actions > Security Scanning
2. Click: Run workflow
3. Select branch: main
4. Click: Run workflow
```

### Accessing Artifacts

```
1. Go to workflow run page
2. Scroll to "Artifacts" section
3. Download desired artifact
4. Verify checksum if available
```

### Viewing Security Results

```
1. Go to: Security tab
2. Select: Code scanning alerts
3. Filter by tool: Trivy, Dependency Review
4. Review and dismiss/fix alerts
```

---

## Monitoring

### Build Status Badges

README includes badges for all workflows:

```markdown
[![Docker CI Build](https://github.com/SWORDIntel/SWORDCOMM/actions/workflows/docker-ci.yml/badge.svg)](...)
[![Docker Release](https://github.com/SWORDIntel/SWORDCOMM/actions/workflows/docker-release.yml/badge.svg)](...)
[![Security Scanning](https://github.com/SWORDIntel/SWORDCOMM/actions/workflows/security-scan.yml/badge.svg)](...)
[![Nightly Build](https://github.com/SWORDIntel/SWORDCOMM/actions/workflows/nightly-build.yml/badge.svg)](...)
```

### Notifications

GitHub automatically notifies on:
- Workflow failures
- Security vulnerabilities
- Dependency issues

Configure notifications:
```
Settings > Notifications > Actions
```

---

## Troubleshooting

### Build Failures

#### Out of Disk Space

```yaml
# Already handled automatically, but if needed:
- name: Additional cleanup
  run: docker system prune -a --volumes -f
```

#### Docker Build Timeout

```yaml
# Increase timeout if needed
timeout-minutes: 120
```

#### Gradle OOM

```yaml
# Reduce parallel workers
env:
  GRADLE_OPTS: "-Dorg.gradle.workers.max=2"
```

### Security Scan Issues

#### Too Many Alerts

```yaml
# Adjust severity threshold
severity: 'CRITICAL,HIGH'  # Remove MEDIUM
```

#### False Positives

```yaml
# Add to .trivyignore file
CVE-2023-12345
```

### Release Issues

#### Version Format Error

```bash
# Ensure version matches: v1.2.3 or v1.2.3-beta
git tag -a v1.2.3 -m "Release v1.2.3"
```

#### Unsigned APKs

```bash
# Configure keystore secrets in repository settings
# See "Repository Secrets" section above
```

---

## Best Practices

### Commit Messages

```bash
# Conventional commits format
git commit -m "feat: add offline translation fallback"
git commit -m "fix: resolve memory leak in crypto module"
git commit -m "docs: update Docker build guide"
```

### Branch Naming

```bash
# Feature branches
git checkout -b feature/add-widget-support

# Bug fixes
git checkout -b fix/translation-crash

# Claude development
git checkout -b claude/improvement-name-sessionid
```

### Pull Requests

- ✅ Wait for CI checks to pass
- ✅ Review security scan results
- ✅ Test artifacts if available
- ✅ Update documentation if needed

### Release Process

```bash
# 1. Update version
# 2. Update CHANGELOG.md
# 3. Commit changes
# 4. Create and push tag
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# 5. Wait for release workflow
# 6. Verify artifacts
# 7. Publish release (if draft)
```

---

## Advanced Configuration

### Custom Docker Registry

```yaml
- name: Login to registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    push: true
    tags: ghcr.io/swordintel/emma-builder:latest
```

### Matrix Builds

```yaml
strategy:
  matrix:
    variant: [prodGms, prodFoss]
    crypto: [ON, OFF]
    exclude:
      - variant: prodGms
        crypto: OFF
```

### Conditional Jobs

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
```

---

## Maintenance

### Updating Workflows

```bash
# 1. Edit workflow file
vim .github/workflows/docker-ci.yml

# 2. Test locally with act (optional)
act push

# 3. Commit and push
git add .github/workflows/docker-ci.yml
git commit -m "ci: update Docker CI workflow"
git push
```

### Updating Dependencies

```yaml
# Dependabot configuration in .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Monitoring Costs

```bash
# View Actions usage
# Settings > Billing > Actions

# Check workflow efficiency
# Actions > Workflow runs > View duration
```

---

## Support

### Documentation

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Docker Build Guide](DOCKER_BUILD.md)
- [Security Best Practices](https://docs.github.com/en/code-security)

### Getting Help

1. Check workflow logs
2. Review GitHub Actions status
3. Search repository issues
4. Check action versions

---

## Changelog

### v1.0.0 (2025-11-06)

- ✅ Docker CI Build workflow
- ✅ Docker Release workflow
- ✅ Security scanning workflow
- ✅ Nightly build workflow
- ✅ Automated APK signing
- ✅ Multi-variant builds
- ✅ Comprehensive security scans
- ✅ Build summaries and badges

---

**Last Updated:** November 6, 2025
**Status:** ✅ Production Ready
**Workflows:** 4 active workflows
