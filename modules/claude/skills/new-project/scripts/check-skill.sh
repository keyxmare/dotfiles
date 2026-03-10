#!/bin/bash
set -euo pipefail

# check-skill.sh — Vérifie l'intégrité du skill /new-project
# Usage: check-skill.sh [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
STACKS_DIR="${HOME}/.claude/stacks"
COMMANDS_DIR="${HOME}/.claude/commands/new-project"

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

PASSED=0
WARNED=0
FAILED=0

check_pass() {
  echo "  ✓ $1"
  PASSED=$((PASSED + 1))
}

check_warn() {
  echo "  ⚠ $1"
  WARNED=$((WARNED + 1))
}

check_fail() {
  echo "  ✗ $1"
  FAILED=$((FAILED + 1))
}

echo "=== Vérification du skill /new-project ==="
echo ""

# 1. Structure du skill
echo "📁 Structure"
for dir in assets assets/templates references references/web-app references/modules scripts presets; do
  if [[ -d "$SKILL_DIR/$dir" ]]; then
    check_pass "$dir/ existe"
  else
    check_fail "$dir/ manquant"
  fi
done

# 2. Fichiers principaux
echo ""
echo "📄 Fichiers principaux"
for file in SKILL.md assets/versions.json assets/scaffold.config.schema.json scripts/init-structure.sh; do
  if [[ -f "$SKILL_DIR/$file" ]]; then
    check_pass "$file"
  else
    check_fail "$file manquant"
  fi
done

# 3. versions.json valide
echo ""
echo "🔢 versions.json"
if python3 -c "import json; json.load(open('$SKILL_DIR/assets/versions.json'))" 2>/dev/null; then
  check_pass "JSON valide"
  # Check required keys
  for key in skill runtimes backend frontend infrastructure tools; do
    if python3 -c "import json; d=json.load(open('$SKILL_DIR/assets/versions.json')); assert '$key' in d" 2>/dev/null; then
      check_pass "Clé '$key' présente"
    else
      check_fail "Clé '$key' manquante"
    fi
  done
else
  check_fail "JSON invalide"
fi

# 4. Schema JSON valide
echo ""
echo "📐 scaffold.config.schema.json"
if python3 -c "import json; json.load(open('$SKILL_DIR/assets/scaffold.config.schema.json'))" 2>/dev/null; then
  check_pass "JSON valide"
else
  check_fail "JSON invalide"
fi

# 5. Templates
echo ""
echo "🧩 Templates"
TEMPLATE_DIR="$SKILL_DIR/assets/templates"
EXPECTED_TEMPLATES=(
  "entity.php.tpl"
  "entity-simple.php.tpl"
  "command.php.tpl"
  "command-handler.php.tpl"
  "query.php.tpl"
  "controller.php.tpl"
  "controller-crud.php.tpl"
  "service-crud.php.tpl"
  "api-response.php.tpl"
  "error-output.php.tpl"
  "dto-input.php.tpl"
  "dto-output.php.tpl"
  "paginated-output.php.tpl"
  "domain-exception.php.tpl"
  "not-found-exception.php.tpl"
  "exception-listener.php.tpl"
  "event.php.tpl"
  "event-listener.php.tpl"
  "repository-interface.php.tpl"
  "doctrine-repository.php.tpl"
  "value-object.php.tpl"
  "entity-factory.php.tpl"
  "health-controller.php.tpl"
  "readiness-controller.php.tpl"
  "object-mapper.php.tpl"
  "value-object-email.php.tpl"
  "value-object-money.php.tpl"
  "value-object-slug.php.tpl"
  "webhook-controller.php.tpl"
  "handler-test.php.tpl"
  "query-handler-test.php.tpl"
  "handler-test-pest.php.tpl"
  "query-handler-test-pest.php.tpl"
  "integration-controller-test.php.tpl"
  "integration-controller-test-pest.php.tpl"
  "integration-repository-test.php.tpl"
  "integration-repository-test-pest.php.tpl"
  "controller-crud-test.php.tpl"
  "controller-crud-test-pest.php.tpl"
  "entity-type.ts.tpl"
  "service-nuxt.ts.tpl"
  "service-vue.ts.tpl"
  "store.ts.tpl"
  "store-test.ts.tpl"
  "composable.ts.tpl"
  "composable-test.ts.tpl"
  "list-page-nuxt.vue.tpl"
  "list-page-vue.vue.tpl"
  "detail-page-nuxt.vue.tpl"
  "detail-page-vue.vue.tpl"
  "form-page-nuxt.vue.tpl"
  "form-page-vue.vue.tpl"
  "e2e-crud.spec.ts.tpl"
)

for tpl in "${EXPECTED_TEMPLATES[@]}"; do
  if [[ -f "$TEMPLATE_DIR/$tpl" ]]; then
    $VERBOSE && check_pass "$tpl"
  else
    check_fail "$tpl manquant"
  fi
done
if ! $VERBOSE; then
  FOUND=$(find "$TEMPLATE_DIR" -name "*.tpl" 2>/dev/null | wc -l | tr -d ' ')
  check_pass "$FOUND templates trouvés (${#EXPECTED_TEMPLATES[@]} attendus)"
fi

# 6. Template placeholders
echo ""
echo "🔗 Placeholders des templates"
BROKEN=0
for tpl in "$TEMPLATE_DIR"/*.tpl; do
  [[ ! -f "$tpl" ]] && continue
  # Check for unclosed {{ without }}
  OPENS=$(grep -o '{{' "$tpl" 2>/dev/null | wc -l | tr -d ' ') || OPENS=0
  CLOSES=$(grep -o '}}' "$tpl" 2>/dev/null | wc -l | tr -d ' ') || CLOSES=0
  if [[ "$OPENS" -ne "$CLOSES" ]]; then
    check_fail "$(basename "$tpl") : $OPENS {{ vs $CLOSES }}"
    BROKEN=$((BROKEN + 1))
  fi
done
[[ $BROKEN -eq 0 ]] && check_pass "Tous les placeholders sont équilibrés"

# 7. References
echo ""
echo "📚 Fichiers de référence"
EXPECTED_REFS=(
  "common.md"
  "ddd-features.md"
  "modules.md"
  "project-types.md"
  "rules-common.md"
  "security.md"
  "scaffold-execution.md"
  "template-resolution.md"
  "troubleshooting.md"
  "web-app/backend.md"
  "web-app/frontend.md"
  "web-app/infrastructure.md"
)
for ref in "${EXPECTED_REFS[@]}"; do
  if [[ -f "$SKILL_DIR/references/$ref" ]]; then
    $VERBOSE && check_pass "references/$ref"
  else
    check_fail "references/$ref manquant"
  fi
done
! $VERBOSE && check_pass "${#EXPECTED_REFS[@]} fichiers de référence vérifiés"

# 8. Module references
echo ""
echo "📦 Références des modules"
MODULES=(auth messenger mailer mercure file-upload i18n monitoring scheduler cache search admin)
for mod in "${MODULES[@]}"; do
  if [[ -f "$SKILL_DIR/references/modules/$mod.md" ]]; then
    $VERBOSE && check_pass "modules/$mod.md"
  else
    check_fail "modules/$mod.md manquant"
  fi
done
! $VERBOSE && check_pass "${#MODULES[@]} modules vérifiés"

# 9. Stacks
echo ""
echo "🗂️  Stacks (~/.claude/stacks/)"
EXPECTED_STACKS=(symfony.md nuxt.md vue.md git.md docker.md makefile.md project-structure.md shell.md patterns.md api.md security.md ci.md database.md)
for stack in "${EXPECTED_STACKS[@]}"; do
  if [[ -f "$STACKS_DIR/$stack" ]]; then
    $VERBOSE && check_pass "stacks/$stack"
  else
    check_warn "stacks/$stack manquant (fallback sur conventions internes)"
  fi
done
! $VERBOSE && check_pass "Stacks vérifiées"

# 10. Commands
echo ""
echo "⚡ Commandes (micro-generators)"
EXPECTED_COMMANDS=(entity.md module.md bounded-context.md feature.md upgrade.md remove.md sync.md evolve.md doctor.md)
for cmd in "${EXPECTED_COMMANDS[@]}"; do
  if [[ -f "$COMMANDS_DIR/$cmd" ]]; then
    $VERBOSE && check_pass "commands/$cmd"
  else
    check_warn "commands/$cmd manquant"
  fi
done

# 11. init-structure.sh executable
echo ""
echo "🔧 Scripts"
if [[ -x "$SKILL_DIR/scripts/init-structure.sh" ]]; then
  check_pass "init-structure.sh est exécutable"
else
  check_warn "init-structure.sh n'est pas exécutable (chmod +x nécessaire)"
fi
if [[ -x "$SKILL_DIR/scripts/check-skill.sh" ]]; then
  check_pass "check-skill.sh est exécutable"
else
  check_warn "check-skill.sh n'est pas exécutable"
fi

# 12. Freshness check versions.json
echo ""
echo "📅 Fraîcheur des versions"
if python3 -c "
import json, datetime
d = json.load(open('$SKILL_DIR/assets/versions.json'))
last = d.get('last_verified', '')
max_age = d.get('max_age_days', 90)
if last:
    last_date = datetime.date.fromisoformat(last)
    age = (datetime.date.today() - last_date).days
    if age > max_age:
        print(f'STALE:{age}')
        exit(1)
    else:
        print(f'OK:{age}')
        exit(0)
else:
    print('NO_DATE')
    exit(2)
" 2>/dev/null; then
  AGE=$(python3 -c "
import json, datetime
d = json.load(open('$SKILL_DIR/assets/versions.json'))
last = datetime.date.fromisoformat(d['last_verified'])
print((datetime.date.today() - last).days)
" 2>/dev/null)
  check_pass "versions.json vérifié il y a ${AGE} jours"
else
  RESULT=$?
  if [[ $RESULT -eq 1 ]]; then
    AGE=$(python3 -c "
import json, datetime
d = json.load(open('$SKILL_DIR/assets/versions.json'))
last = datetime.date.fromisoformat(d['last_verified'])
print((datetime.date.today() - last).days)
" 2>/dev/null)
    check_warn "versions.json a ${AGE} jours — mise à jour recommandée (max ${AGE} jours)"
  else
    check_warn "versions.json n'a pas de champ 'last_verified'"
  fi
fi

# Summary
echo ""
echo "════════════════════════════════════"
echo "  ✓ Passed: $PASSED"
echo "  ⚠ Warned: $WARNED"
echo "  ✗ Failed: $FAILED"
echo "════════════════════════════════════"

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo "Des vérifications ont échoué. Corriger les erreurs avant d'utiliser le skill."
  exit 1
elif [[ $WARNED -gt 0 ]]; then
  echo ""
  echo "Le skill est fonctionnel avec des avertissements mineurs."
  exit 0
else
  echo ""
  echo "Le skill est en parfait état."
  exit 0
fi
