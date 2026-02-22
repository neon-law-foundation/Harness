# Homebrew Distribution

The Standards CLI is distributed via Homebrew using a custom tap (repository) hosted at
`neon-law-foundation/homebrew-tap`.

## Installation

Users can install the Standards CLI using Homebrew:

```bash
# Add the tap
brew tap neon-law-foundation/tap

# Install standards
brew install standards
```

Or in a single command:

```bash
brew install neon-law-foundation/tap/standards
```

## How It Works

### Daily Automated Releases

The `.github/workflows/daily-release.yml` workflow runs daily at 2 AM UTC and:

1. **Generates version** from current date in `YYYY.MM.DD` format (e.g., `2026.01.08`)
2. **Builds binaries** for multiple architectures:
   - Apple Silicon (arm64)
   - Intel (x86_64)
   - Universal binary (both architectures)
3. **Creates GitHub release** with all binaries and checksums
4. **Updates Homebrew formula** automatically in the tap repository

### Version Format

Versions follow the `YYYY.MM.DD` format:

- `2026.01.08` = January 8, 2026
- `2026.12.31` = December 31, 2026

This ensures:

- ✅ Automatic daily releases
- ✅ Clear chronological ordering
- ✅ No manual version bumping needed
- ✅ Users always know which day a release was built

## Setting Up the Homebrew Tap

### Prerequisites

1. **Create the tap repository** at `github.com/neon-law-foundation/homebrew-tap`
   - Must be public
   - Name must start with `homebrew-`

2. **Generate a Personal Access Token**:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Name: "Homebrew Tap Release Bot"
   - Scopes: Select `repo` (all sub-scopes)
   - Copy the token

3. **Add token to repository secrets**:
   - Go to SagebrushStandards repository
   - Settings → Secrets and variables → Actions
   - New repository secret:
     - Name: `HOMEBREW_TAP_TOKEN`
     - Value: (paste the token)

### Initialize the Tap Repository

```bash
# Clone the tap repository
git clone https://github.com/neon-law-foundation/homebrew-tap.git
cd homebrew-tap

# Create Formula directory
mkdir -p Formula

# Create initial formula (will be auto-updated by workflow)
cat > Formula/standards.rb <<'EOF'
class Standards < Formula
  desc "Legal standards and compliance management CLI"
  homepage "https://github.com/neon-law-foundation/SagebrushStandards"
  url "https://github.com/neon-law-foundation/SagebrushStandards/releases/download/v2026.01.08/standards-2026.01.08-macos-universal.tar.gz"
  sha256 "PLACEHOLDER_WILL_BE_UPDATED_BY_WORKFLOW"
  version "2026.01.08"
  license "Apache-2.0"

  def install
    bin.install "standards-macos-universal" => "standards"
  end

  test do
    assert_match "standards", shell_output("#{bin}/standards --version")
  end
end
EOF

# Create README
cat > README.md <<'HEREDOC'
# Neon Law Foundation Homebrew Tap

This tap provides Homebrew formulas for Neon Law Foundation tools.

## Installation

brew tap neon-law-foundation/tap
brew install standards

## Available Formulas

### standards

Legal standards and compliance management CLI tool.

## Releases

Formulas are automatically updated daily by GitHub Actions when new releases are published.
HEREDOC

# Commit and push the changes
git add .
git commit -m "chore: initialize homebrew tap"
git push
```

### Repository Structure

```txt
homebrew-tap/
├── Formula/
│   └── standards.rb          # Homebrew formula (auto-updated)
└── README.md                  # Tap documentation
```

## Workflow Details

### Trigger Conditions

The workflow runs:

- **Daily** at 2 AM UTC via cron schedule
- **Manually** via workflow_dispatch

### Skip Duplicate Releases

The workflow checks if a release for today already exists. If it does, it skips building and
publishing to avoid duplicate releases.

### Build Process

1. Checkout code
2. Setup Swift 6.0
3. Build for arm64 architecture
4. Build for x86_64 architecture
5. Create universal binary using `lipo`
6. Package into tar.gz archives
7. Generate SHA256 checksums

### Release Artifacts

Each release includes:

- `standards-YYYY.MM.DD-macos-arm64.tar.gz` - Apple Silicon binary
- `standards-YYYY.MM.DD-macos-x86_64.tar.gz` - Intel binary
- `standards-YYYY.MM.DD-macos-universal.tar.gz` - Universal binary
- `checksums.txt` - SHA256 checksums for all archives

### Homebrew Formula Update

After creating the release, the workflow:

1. Clones the `homebrew-tap` repository
2. Updates `Formula/standards.rb` with:
   - New version number (YYYY.MM.DD)
   - New download URL
   - New SHA256 checksum
3. Commits and pushes the updated formula

## Manual Release

To trigger a manual release:

1. Go to GitHub Actions in the SagebrushStandards repository
2. Select "Daily Release" workflow
3. Click "Run workflow"
4. Select the branch (usually `main`)
5. Click "Run workflow"

## Testing Locally

Before releasing, test the binary locally:

```bash
# Build release binary
swift build -c release

# Test the binary
.build/release/StandardsCLI --version
.build/release/StandardsCLI --help
```

## Troubleshooting

### Workflow fails with "Resource not accessible by integration"

- Ensure repository has "Read and write permissions" for Actions
- Go to Settings → Actions → General → Workflow permissions
- Select "Read and write permissions"

### Homebrew update fails with authentication error

- Check that `HOMEBREW_TAP_TOKEN` secret is set correctly
- Verify the token has `repo` scope
- Ensure the token hasn't expired

### Universal binary creation fails

- Verify both arm64 and x86_64 builds succeeded
- Check that Swift toolchain supports cross-compilation
- Ensure `lipo` command is available (should be on macOS by default)

### Users can't install from tap

- Verify tap repository is public
- Check formula syntax: `brew audit --strict Formula/standards.rb`
- Test installation locally: `brew install --build-from-source Formula/standards.rb`

## References

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Creating Taps](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
- [GitHub Actions for Swift](https://github.com/swift-actions)
