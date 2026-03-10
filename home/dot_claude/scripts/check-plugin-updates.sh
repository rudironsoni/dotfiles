#!/bin/bash
# Check for Claude Code plugin updates
# Compares installed plugin versions with latest available in marketplaces

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
PLUGINS_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"
MARKETPLACES_DIR="$CLAUDE_DIR/plugins/marketplaces"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check dependencies
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed.${NC}"
    echo "Install jq:"
    echo "  macOS:         brew install jq"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  Fedora:        sudo dnf install jq"
    echo "  Windows:       choco install jq"
    exit 1
fi

if [[ ! -f "$PLUGINS_FILE" ]]; then
    echo -e "${RED}Error: Plugin file not found at $PLUGINS_FILE${NC}"
    exit 1
fi

echo -e "${BOLD}Checking Claude Code plugin updates...${NC}\n"

# Check if marketplaces directory exists and has content
if [[ ! -d "$MARKETPLACES_DIR" ]] || [[ -z "$(ls -A "$MARKETPLACES_DIR" 2>/dev/null)" ]]; then
    echo -e "${YELLOW}Warning: No marketplaces found at $MARKETPLACES_DIR${NC}"
    echo "Install plugins first with: claude plugin install <plugin>@<marketplace>"
    exit 0
fi

# Fetch latest from all marketplaces
echo -e "${BLUE}Fetching latest from marketplaces...${NC}"
for marketplace_dir in "$MARKETPLACES_DIR"/*/; do
    if [[ -d "$marketplace_dir/.git" ]]; then
        marketplace_name=$(basename "$marketplace_dir")
        (cd "$marketplace_dir" && git fetch origin --quiet 2>/dev/null) || true
    fi
done
echo ""

updates_available=0
up_to_date=0
unknown_version=0
cannot_compare=0

# Parse installed plugins
plugins=$(jq -r '.plugins | keys[]' "$PLUGINS_FILE" 2>/dev/null)

for plugin_key in $plugins; do
    # Extract plugin name and marketplace (handles @scope/plugin@marketplace format)
    marketplace="${plugin_key##*@}"
    plugin_name="${plugin_key%@*}"

    # Get installed info
    installed_version=$(jq -r ".plugins[\"$plugin_key\"][0].version // \"unknown\"" "$PLUGINS_FILE")
    installed_sha=$(jq -r ".plugins[\"$plugin_key\"][0].gitCommitSha // \"\"" "$PLUGINS_FILE")
    is_local=$(jq -r ".plugins[\"$plugin_key\"][0].isLocal // false" "$PLUGINS_FILE")

    marketplace_dir="$MARKETPLACES_DIR/$marketplace"

    if [[ ! -d "$marketplace_dir/.git" ]]; then
        continue
    fi

    # Get latest SHA from marketplace
    latest_sha=$(cd "$marketplace_dir" && git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null || echo "")

    if [[ -z "$latest_sha" || -z "$installed_sha" ]]; then
        continue
    fi

    # Check if there are commits between installed and latest
    if [[ "$installed_sha" != "$latest_sha" ]]; then
        # Count commits ahead
        commits_ahead=$(cd "$marketplace_dir" && git rev-list --count "$installed_sha..$latest_sha" 2>/dev/null || echo "?")

        if [[ "$commits_ahead" == "?" ]]; then
            echo -e "${BLUE}?${NC}  ${BOLD}$plugin_name${NC}@$marketplace"
            echo -e "   Cannot compare (installed SHA not found in remote history)"
            ((cannot_compare++))
            continue
        fi

        if [[ "$commits_ahead" != "0" ]]; then
            # Try to find version info from commit messages
            latest_version=$(cd "$marketplace_dir" && git log --oneline "$installed_sha..$latest_sha" 2>/dev/null | grep -i "$plugin_name" | head -1 | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "")

            if [[ -n "$latest_version" ]]; then
                echo -e "${YELLOW}⬆${NC}  ${BOLD}$plugin_name${NC}@$marketplace"
                echo -e "   ${RED}$installed_version${NC} → ${GREEN}$latest_version${NC} ($commits_ahead commits)"
                ((updates_available++))
            elif [[ "$is_local" == "true" || "$installed_version" == "unknown" ]]; then
                echo -e "${YELLOW}⬆${NC}  ${BOLD}$plugin_name${NC}@$marketplace"
                echo -e "   $commits_ahead commits behind (local plugin, no version tracking)"
                ((unknown_version++))
            else
                echo -e "${YELLOW}⬆${NC}  ${BOLD}$plugin_name${NC}@$marketplace"
                echo -e "   ${RED}$installed_version${NC} → ${GREEN}newer available${NC} ($commits_ahead commits)"
                ((updates_available++))
            fi
        else
            ((up_to_date++))
        fi
    else
        ((up_to_date++))
    fi
done

echo ""
echo -e "${BOLD}Summary:${NC}"
if [[ $updates_available -gt 0 ]]; then
    echo -e "  ${YELLOW}$updates_available plugin(s) with updates available${NC}"
fi
if [[ $unknown_version -gt 0 ]]; then
    echo -e "  ${BLUE}$unknown_version local plugin(s) with possible updates${NC}"
fi
echo -e "  ${GREEN}$up_to_date plugin(s) up to date${NC}"
if [[ $cannot_compare -gt 0 ]]; then
    echo -e "  ${BLUE}$cannot_compare plugin(s) could not be compared${NC}"
fi

if [[ $updates_available -gt 0 || $unknown_version -gt 0 ]]; then
    echo ""
    echo -e "${BOLD}To update a plugin:${NC}"
    echo -e "  claude plugin update <plugin-name>@<marketplace>"
    echo ""
    echo -e "${BOLD}Example:${NC}"
    echo -e "  claude plugin update superpowers@superpowers-marketplace"
fi
