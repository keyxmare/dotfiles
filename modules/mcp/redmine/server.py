#!/usr/bin/env python3
import json
import sys
import os
import urllib.request
import urllib.parse
import urllib.error
from collections import Counter
from datetime import date
from pathlib import Path

BASE_URL = os.environ.get("REDMINE_BASE_URL", "https://redmine.motoblouz.com")
CUSTOM_FIELD_TYPE = 68
PROTOCOL_VERSION = "2025-03-26"


def get_api_key():
    key_file = Path.home() / ".config/redmine/api_key"
    if key_file.exists():
        return key_file.read_text().strip()
    return os.environ.get("REDMINE_API_KEY", "")


def redmine_request(path, params=None):
    api_key = get_api_key()
    query = {"key": api_key}
    if params:
        query.update(params)
    url = f"{BASE_URL}{path}?{urllib.parse.urlencode(query)}"
    req = urllib.request.Request(url, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def get_ticket_type(issue):
    for cf in issue.get("custom_fields", []):
        if cf["id"] == CUSTOM_FIELD_TYPE:
            return cf.get("value", "")
    return ""


def format_issue(issue):
    lines = [
        f"# [{issue['id']}] {issue['subject']}",
        f"**Projet:** {issue['project']['name']}",
        f"**Statut:** {issue['status']['name']}",
        f"**Priorité:** {issue['priority']['name']}",
        f"**Auteur:** {issue['author']['name']}",
        f"**Assigné à:** {issue.get('assigned_to', {}).get('name', 'Non assigné')}",
        f"**Créé le:** {issue.get('created_on', '')}",
        f"**Mis à jour:** {issue.get('updated_on', '')}",
    ]
    if issue.get("description"):
        lines += ["", "## Description", issue["description"]]
    journals = [j for j in issue.get("journals", []) if j.get("notes")]
    if journals:
        lines.append("\n## Dernières notes")
        for j in journals[-5:]:
            lines.append(f"\n**{j['created_on']}** par **{j['user']['name']}**:\n{j['notes']}")
    return "\n".join(lines)


def format_issues_list(issues, label=None):
    if not issues:
        prefix = f"**{label}** — " if label else ""
        return f"{prefix}Aucun ticket trouvé."
    header = f"**{label}** ({len(issues)})\n" if label else f"{len(issues)} ticket(s) trouvé(s):\n"
    lines = [header]
    for issue in issues:
        assigned = issue.get("assigned_to", {}).get("name", "—")
        updated = issue.get("updated_on", "")[:10]
        lines.append(f"- **[{issue['id']}]** {issue['subject']} | {issue['status']['name']} | {assigned} | {updated}")
    return "\n".join(lines)


def format_rapport_md(tdc_issues, dds_issues, incident_issues):
    today = date.today().isoformat()
    lines = []

    lines.append(f"## Tour de contrôle — À trier ({len(tdc_issues)} tickets)\n")
    if tdc_issues:
        lines.append("| # | Sujet | Priorité | Créé le |")
        lines.append("|---|-------|----------|---------|")
        for i in tdc_issues:
            created = i.get("created_on", "")[:10]
            lines.append(f"| [{i['id']}] | {i['subject'][:65]} | {i['priority']['name']} | {created} |")
    else:
        lines.append("Aucun ticket à trier.")

    lines.append("")
    dds_due = sorted([i for i in dds_issues if i.get("due_date")], key=lambda x: x["due_date"])
    lines.append(f"## DDS avec échéance ({len(dds_due)}/{len(dds_issues)} tickets)\n")
    if dds_due:
        lines.append("| # | Sujet | Statut | Assigné | Échéance |")
        lines.append("|---|-------|--------|---------|----------|")
        for i in dds_due:
            assigned = i.get("assigned_to", {}).get("name", "—")
            due = i["due_date"]
            flag = " !" if due < today else ""
            lines.append(f"| [{i['id']}] | {i['subject'][:60]} | {i['status']['name']} | {assigned} | {due}{flag} |")
    else:
        lines.append("Aucun DDS avec échéance.")

    lines.append("")
    lines.append(f"## Incidents par statut ({len(incident_issues)} total)\n")
    if incident_issues:
        by_status = Counter(i["status"]["name"] for i in incident_issues)
        lines.append("| Statut | Nb |")
        lines.append("|--------|----|")
        for status, count in sorted(by_status.items(), key=lambda x: -x[1]):
            lines.append(f"| {status} | {count} |")
    else:
        lines.append("Aucun incident.")

    return "\n".join(lines)


def format_rapport_slack(tdc_issues, dds_issues, incident_issues):
    today = date.today().isoformat()
    base = "https://redmine.motoblouz.com/issues"
    lines = []

    lines.append(f"*Tour de contrôle — À trier ({len(tdc_issues)} tickets)*")
    if tdc_issues:
        for i in tdc_issues:
            created = i.get("created_on", "")[:10]
            prio = f" _{i['priority']['name']}_" if i["priority"]["name"] != "Normal" else ""
            lines.append(f"• <{base}/{i['id']}|#{i['id']}> {i['subject']}{prio} — {created}")
    else:
        lines.append("_Aucun ticket à trier._")

    lines.append("")
    dds_due = sorted([i for i in dds_issues if i.get("due_date")], key=lambda x: x["due_date"])
    lines.append(f"*DDS avec échéance ({len(dds_due)}/{len(dds_issues)} tickets)*")
    if dds_due:
        for i in dds_due:
            assigned = i.get("assigned_to", {}).get("name", "—")
            due = i["due_date"]
            flag = " !" if due < today else ""
            assignee = f" — {assigned}" if assigned != "—" else ""
            lines.append(f"• <{base}/{i['id']}|#{i['id']}> {i['subject']} — _{i['status']['name']}_{assignee} — {due}{flag}")
    else:
        lines.append("_Aucun DDS avec échéance._")

    lines.append("")
    lines.append(f"*Incidents par statut ({len(incident_issues)} total)*")
    if incident_issues:
        by_status = Counter(i["status"]["name"] for i in incident_issues)
        for status, count in sorted(by_status.items(), key=lambda x: -x[1]):
            lines.append(f"• {status} : *{count}*")
    else:
        lines.append("_Aucun incident._")

    return "\n".join(lines)


TOOLS = [
    {
        "name": "redmine_get_ticket",
        "description": "Récupère un ticket Redmine par son ID",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "ID du ticket Redmine"}
            },
            "required": ["id"],
        },
    },
    {
        "name": "redmine_search_tickets",
        "description": "Recherche des tickets Redmine par sujet ou assignation",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Texte à rechercher dans le sujet"},
                "assigned_to_id": {"type": "string", "description": "ID utilisateur assigné (optionnel)"},
                "status_id": {"type": "string", "description": "ID statut : open, closed, * (optionnel)"},
                "limit": {"type": "integer", "description": "Nombre max de résultats", "default": 25},
            },
            "required": ["query"],
        },
    },
    {
        "name": "redmine_list_my_tickets",
        "description": "Liste les tickets assignés à l'utilisateur courant",
        "inputSchema": {
            "type": "object",
            "properties": {
                "status_id": {"type": "string", "description": "Filtre statut: open, closed, * (défaut: open)"},
                "limit": {"type": "integer", "description": "Nombre max de résultats", "default": 25},
            },
        },
    },
    {
        "name": "redmine_tour_de_controle",
        "description": "Liste les tickets de la Tour de contrôle (projet digital, query 420)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "limit": {"type": "integer", "description": "Nombre max de résultats", "default": 50},
            },
        },
    },
    {
        "name": "redmine_squad_quotidienne",
        "description": "Liste les tickets de la squad quotidienne : DDS et incidents séparément (projet digital, query 365)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "limit": {"type": "integer", "description": "Nombre max de résultats par type", "default": 50},
            },
        },
    },
    {
        "name": "redmine_add_note",
        "description": "Ajoute une note/commentaire à un ticket Redmine",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "description": "ID du ticket"},
                "note": {"type": "string", "description": "Contenu de la note (markdown)"},
            },
            "required": ["id", "note"],
        },
    },
    {
        "name": "redmine_rapport",
        "description": "Rapport journalier : tour de contrôle à trier + DDS avec échéance + incidents par statut",
        "inputSchema": {
            "type": "object",
            "properties": {
                "format": {"type": "string", "enum": ["markdown", "slack"], "description": "Format de sortie (défaut: markdown)"},
            },
        },
    },
]


def call_tool(name, args):
    if name == "redmine_get_ticket":
        data = redmine_request(f"/issues/{args['id']}.json", {"include": "journals,watchers"})
        return format_issue(data["issue"])

    if name == "redmine_search_tickets":
        params = {
            "subject": f"~{args['query']}",
            "limit": args.get("limit", 25),
        }
        if "assigned_to_id" in args:
            params["assigned_to_id"] = args["assigned_to_id"]
        if "status_id" in args:
            params["status_id"] = args["status_id"]
        data = redmine_request("/issues.json", params)
        return format_issues_list(data["issues"])

    if name == "redmine_list_my_tickets":
        params = {
            "assigned_to_id": "me",
            "status_id": args.get("status_id", "open"),
            "limit": args.get("limit", 25),
        }
        data = redmine_request("/issues.json", params)
        return format_issues_list(data["issues"])

    if name == "redmine_add_note":
        api_key = get_api_key()
        url = f"{BASE_URL}/issues/{args['id']}.json"
        body = json.dumps({"issue": {"notes": args["note"]}}).encode()
        req = urllib.request.Request(
            f"{url}?key={api_key}",
            data=body,
            headers={"Content-Type": "application/json"},
            method="PUT",
        )
        urllib.request.urlopen(req, timeout=10)
        return f"Note ajoutée au ticket #{args['id']}."

    if name == "redmine_tour_de_controle":
        data = redmine_request(
            "/projects/digital/issues.json",
            {"query_id": 420, "limit": args.get("limit", 50)},
        )
        return format_issues_list(data["issues"], "Tour de contrôle")

    if name == "redmine_squad_quotidienne":
        data = redmine_request(
            "/projects/digital/issues.json",
            {"query_id": 365, "limit": 100},
        )
        all_issues = data["issues"]
        dds = [i for i in all_issues if get_ticket_type(i) == "DDS"]
        incidents = [i for i in all_issues if get_ticket_type(i) == "Incident"]
        sections = [
            format_issues_list(dds, "DDS — Demandes de services"),
            "",
            format_issues_list(incidents, "Incidents"),
        ]
        return "\n".join(sections)

    if name == "redmine_rapport":
        tdc = redmine_request("/projects/digital/issues.json", {"query_id": 420, "limit": 100})
        sq = redmine_request("/projects/digital/issues.json", {"query_id": 365, "limit": 100})
        all_sq = sq["issues"]
        dds = [i for i in all_sq if get_ticket_type(i) == "DDS"]
        incidents = [i for i in all_sq if get_ticket_type(i) == "Incident"]
        if args.get("format") == "slack":
            return format_rapport_slack(tdc["issues"], dds, incidents)
        return format_rapport_md(tdc["issues"], dds, incidents)

    raise ValueError(f"Unknown tool: {name}")


def handle(req):
    method = req.get("method", "")
    req_id = req.get("id")

    if method == "initialize":
        client_version = req.get("params", {}).get("protocolVersion", PROTOCOL_VERSION)
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": client_version,
                "capabilities": {"tools": {"listChanged": False}},
                "serverInfo": {"name": "redmine-mcp", "version": "2.0.0"},
            },
        }

    if method == "ping":
        return {"jsonrpc": "2.0", "id": req_id, "result": {}}

    if method.startswith("notifications/"):
        return None

    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": req_id, "result": {"tools": TOOLS}}

    if method == "tools/call":
        params = req.get("params", {})
        try:
            text = call_tool(params["name"], params.get("arguments", {}))
            return {
                "jsonrpc": "2.0",
                "id": req_id,
                "result": {"content": [{"type": "text", "text": text}]},
            }
        except urllib.error.HTTPError as e:
            msg = f"HTTP {e.code}: {e.reason}"
            if e.code == 404:
                msg = "Ticket non trouvé (404)"
            elif e.code == 401:
                msg = "Clé API invalide ou absente (~/.config/redmine/api_key)"
            return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32000, "message": msg}}
        except Exception as e:
            return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32000, "message": str(e)}}

    return {
        "jsonrpc": "2.0",
        "id": req_id,
        "error": {"code": -32601, "message": f"Method not found: {method}"},
    }


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            req = json.loads(line)
        except json.JSONDecodeError:
            continue
        resp = handle(req)
        if resp is not None:
            sys.stdout.write(json.dumps(resp) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
