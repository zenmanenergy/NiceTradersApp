#!/bin/bash

###############################################################################
# Localization Editor - Production Deployment Script
# 
# This script deploys the localization editor to production, including:
# - Database backup
# - Schema migration
# - Backend deployment
# - Frontend build and deployment
# - Service restart and validation
#
# Usage: ./deploy_localization_editor.sh [--dry-run] [--skip-backup]
###############################################################################

set -e  # Exit on any error

# Configuration
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$REPO_ROOT/Server"
BROWSER_DIR="$REPO_ROOT/Client/Browser"
BACKUP_DIR="$REPO_ROOT/backups/localization"
VENV="$SERVER_DIR/venv/bin/python3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
SKIP_BACKUP=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

###############################################################################
# FUNCTIONS
###############################################################################

log_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}\n"
}

log_error() {
    echo -e "${RED}✗ $1${NC}\n"
}

log_warning() {
    echo -e "${YELLOW}⚠ $1${NC}\n"
}

run_cmd() {
    local cmd=$1
    local description=$2
    
    echo -e "  ${BLUE}→${NC} ${description}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "    ${YELLOW}[DRY RUN]${NC} Would execute: $cmd"
    else
        if eval "$cmd" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓${NC} Done"
            return 0
        else
            echo -e "    ${RED}✗${NC} Failed"
            log_error "Command failed: $cmd"
            return 1
        fi
    fi
}

check_prerequisites() {
    log_step "Checking Prerequisites"
    
    local missing=0
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found"
        missing=1
    else
        echo "  ✓ Python3: $(python3 --version)"
    fi
    
    # Check MySQL
    if ! command -v mysql &> /dev/null; then
        log_warning "MySQL client not found - database operations may fail"
    else
        echo "  ✓ MySQL: Found"
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js not found - frontend build will fail"
        missing=1
    else
        echo "  ✓ Node.js: $(node --version)"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        log_error "npm not found - frontend build will fail"
        missing=1
    else
        echo "  ✓ npm: $(npm --version)"
    fi
    
    # Check directories
    if [ ! -d "$SERVER_DIR" ]; then
        log_error "Server directory not found: $SERVER_DIR"
        missing=1
    else
        echo "  ✓ Server directory: $SERVER_DIR"
    fi
    
    if [ ! -d "$BROWSER_DIR" ]; then
        log_error "Browser directory not found: $BROWSER_DIR"
        missing=1
    else
        echo "  ✓ Browser directory: $BROWSER_DIR"
    fi
    
    if [ $missing -eq 1 ]; then
        log_error "Prerequisites check failed - please install missing dependencies"
        return 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

backup_database() {
    log_step "Creating Database Backup"
    
    mkdir -p "$BACKUP_DIR"
    
    local backup_file="$BACKUP_DIR/translations_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    run_cmd "mysqldump -h localhost -u stevenelson -pmwitcitw711 nicetraders \
        translations translation_history view_translation_keys_cache \
        > '$backup_file'" \
        "Exporting translations tables to SQL"
    
    if [ -f "$backup_file" ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_success "Database backup created: $backup_file ($size)"
        echo "$backup_file" >> "$BACKUP_DIR/latest_backup.txt"
        return 0
    else
        log_error "Database backup failed"
        return 1
    fi
}

run_database_migration() {
    log_step "Running Database Migration"
    
    if [ ! -f "$SERVER_DIR/migrate_localization_schema.py" ]; then
        log_error "Migration script not found: $SERVER_DIR/migrate_localization_schema.py"
        return 1
    fi
    
    run_cmd "cd '$SERVER_DIR' && '$VENV' migrate_localization_schema.py" \
        "Executing database migration script"
    
    if [ $? -eq 0 ]; then
        log_success "Database migration completed"
        return 0
    else
        log_error "Database migration failed"
        return 1
    fi
}

verify_database_changes() {
    log_step "Verifying Database Schema Changes"
    
    local verify_script=$(cat << 'EOF'
import pymysql
import pymysql.cursors

try:
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    # Check columns exist
    cursor.execute("DESCRIBE translations")
    cols = [row['Field'] for row in cursor.fetchall()]
    required_cols = ['updated_by', 'status', 'notes']
    
    for col in required_cols:
        if col not in cols:
            print(f"ERROR: Column '{col}' not found in translations table")
            exit(1)
    
    # Check tables exist
    cursor.execute("SHOW TABLES LIKE 'translation_history'")
    if not cursor.fetchone():
        print("ERROR: translation_history table not found")
        exit(1)
    
    cursor.execute("SHOW TABLES LIKE 'view_translation_keys_cache'")
    if not cursor.fetchone():
        print("ERROR: view_translation_keys_cache table not found")
        exit(1)
    
    # Check record counts
    cursor.execute("SELECT COUNT(*) as count FROM translations")
    trans_count = cursor.fetchone()['count']
    
    cursor.execute("SELECT COUNT(*) as count FROM view_translation_keys_cache")
    cache_count = cursor.fetchone()['count']
    
    print(f"✓ Database schema verified")
    print(f"  - Translations: {trans_count:,} records")
    print(f"  - Cache views: {cache_count} records")
    
    db.close()
    exit(0)
    
except Exception as e:
    print(f"ERROR: Database verification failed: {e}")
    exit(1)
EOF
)
    
    run_cmd "'$VENV' << 'PYEOF'\n$verify_script\nPYEOF" \
        "Verifying database schema changes"
    
    if [ $? -eq 0 ]; then
        log_success "Database schema verification passed"
        return 0
    else
        log_error "Database schema verification failed"
        return 1
    fi
}

deploy_backend() {
    log_step "Deploying Backend"
    
    # Test Flask app loads
    run_cmd "cd '$SERVER_DIR' && '$VENV' -c 'from flask_app import app; from Translations.AdminTranslations import *; print(\"OK\")'" \
        "Testing Flask app import and endpoints"
    
    if [ $? -ne 0 ]; then
        log_error "Flask app import failed - deployment aborted"
        return 1
    fi
    
    log_success "Backend deployment verified (Flask app loads successfully)"
    return 0
}

deploy_frontend() {
    log_step "Deploying Frontend"
    
    # Check package.json exists
    if [ ! -f "$BROWSER_DIR/package.json" ]; then
        log_error "package.json not found in $BROWSER_DIR"
        return 1
    fi
    
    # Install dependencies
    run_cmd "cd '$BROWSER_DIR' && npm install --legacy-peer-deps" \
        "Installing frontend dependencies"
    
    if [ $? -ne 0 ]; then
        log_error "npm install failed"
        return 1
    fi
    
    # Build frontend
    run_cmd "cd '$BROWSER_DIR' && npm run build" \
        "Building frontend (SvelteKit)"
    
    if [ $? -ne 0 ]; then
        log_error "Frontend build failed"
        return 1
    fi
    
    log_success "Frontend deployment completed"
    return 0
}

generate_inventory() {
    log_step "Generating Translation Inventory"
    
    if [ ! -f "$REPO_ROOT/build_translation_inventory.py" ]; then
        log_warning "Inventory builder script not found - skipping"
        return 0
    fi
    
    run_cmd "cd '$REPO_ROOT' && '$VENV' build_translation_inventory.py" \
        "Generating translation inventory from iOS code"
    
    if [ -f "$REPO_ROOT/translation_inventory.json" ]; then
        log_success "Translation inventory generated"
        return 0
    else
        log_warning "Inventory generation failed or skipped"
        return 0
    fi
}

validate_deployment() {
    log_step "Validating Deployment"
    
    local errors=0
    
    # Check Flask app
    echo -e "  ${BLUE}→${NC} Testing Flask app endpoints..."
    if cd "$SERVER_DIR" && "$VENV" -c "from flask_app import app; from Translations.AdminTranslations import *; print('Endpoints loaded')" >> "$LOG_FILE" 2>&1; then
        echo -e "    ${GREEN}✓${NC} Flask app endpoints OK"
    else
        echo -e "    ${RED}✗${NC} Flask app endpoints FAILED"
        errors=$((errors + 1))
    fi
    
    # Check frontend build
    echo -e "  ${BLUE}→${NC} Checking frontend build..."
    if [ -d "$BROWSER_DIR/.svelte-kit" ] || [ -d "$BROWSER_DIR/build" ]; then
        echo -e "    ${GREEN}✓${NC} Frontend build OK"
    else
        echo -e "    ${RED}✗${NC} Frontend build FAILED"
        errors=$((errors + 1))
    fi
    
    # Check database
    echo -e "  ${BLUE}→${NC} Verifying database connectivity..."
    if run_cmd "'$VENV' << 'PYEOF'\nimport pymysql\ndb = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')\ndb.close()\nprint('OK')\nPYEOF" "Database connectivity" 2>/dev/null; then
        echo -e "    ${GREEN}✓${NC} Database OK"
    else
        echo -e "    ${RED}✗${NC} Database FAILED"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Deployment validation passed"
        return 0
    else
        log_error "Deployment validation failed with $errors errors"
        return 1
    fi
}

print_summary() {
    log_step "Deployment Summary"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${YELLOW}[DRY RUN MODE]${NC}"
        echo -e "    No actual changes were made. Remove --dry-run to deploy.\n"
    fi
    
    if [ "$SKIP_BACKUP" = true ]; then
        echo -e "  ${YELLOW}[BACKUP SKIPPED]${NC}"
        echo -e "    Database backup was not created.\n"
    else
        echo -e "  ${BLUE}Database Backup:${NC}"
        echo -e "    $BACKUP_DIR\n"
    fi
    
    echo -e "  ${BLUE}Next Steps:${NC}"
    echo -e "    1. Start the Flask server: cd $SERVER_DIR && ./run.sh"
    echo -e "    2. Test the localization editor: http://localhost:5173/localization"
    echo -e "    3. Check status dashboard: http://localhost:5173/localization/status\n"
}

handle_error() {
    log_error "Deployment failed!"
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}DEPLOYMENT FAILED${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ "$SKIP_BACKUP" != true ] && [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}To rollback, restore the latest backup:${NC}"
        local latest_backup=$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -1)
        if [ -n "$latest_backup" ]; then
            echo -e "  mysql -u stevenelson -pmwitcitw711 nicetraders < '$latest_backup'\n"
        fi
    fi
    
    exit 1
}

###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Localization Editor - Production Deployment        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}\n"
    
    # Run deployment steps
    check_prerequisites || handle_error
    
    if [ "$SKIP_BACKUP" != true ]; then
        backup_database || handle_error
    else
        log_warning "Database backup skipped"
    fi
    
    run_database_migration || handle_error
    verify_database_changes || handle_error
    deploy_backend || handle_error
    deploy_frontend || handle_error
    generate_inventory || handle_error
    
    if [ "$DRY_RUN" != true ]; then
        validate_deployment || handle_error
    fi
    
    # Success
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ DEPLOYMENT SUCCESSFUL                           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}\n"
    
    print_summary
}

# Run main with error handling
main || handle_error
