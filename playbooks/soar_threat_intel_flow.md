# Azure Logic Apps SOAR Playbook: Automated Threat Intelligence Enrichment

## 📌 Playbook Overview
When an incident is created in **Microsoft Sentinel** (e.g. `High-Volume RDP Brute Force Detection`), this playbook triggers automatically, parses the offending IP address entity, queries the **AbuseIPDB Threat Intelligence API**, posts an enriched triage note into the Sentinel incident comments, and sends an alert card to the SOC channel.

---

## 🛠️ Workflow Architecture

```
[Sentinel Incident Trigger]
            │
            ▼
[Entities - Get IPs] (Extract IP entity from incident)
            │
            ▼
[Condition] (Is IP public / non-RFC1918?)
            │
            ├── (Yes) ──► [HTTP Action: Query AbuseIPDB API]
            │                   │
            │                   ▼
            │             [Parse JSON Response]
            │             (Extract abuseConfidenceScore, countryCode, isp, totalReports)
            │                   │
            │                   ▼
            │             [Sentinel: Add Comment to Incident]
            │             (Attach formatted threat intelligence summary)
            │                   │
            │                   ▼
            │             [Post Message to SOC Teams / Discord Webhook]
            │
            └── (No)  ──► [Terminate / Skip Private IP]
```

---

## ⚙️ Detailed Step Configuration

### Step 1: Trigger
- **Connector:** Microsoft Sentinel
- **Trigger:** *When a Microsoft Sentinel incident creation rule was triggered*

### Step 2: Extract IP Entity
- **Action:** *Entities - Get IPs*
- **Parameter:** Incident Entities: `triggerBody()?['object']?['properties']?['relatedEntities']`

### Step 3: Threat Intelligence API Call
- **Action:** *HTTP*
- **Method:** `GET`
- **URI:** `https://api.abuseipdb.com/api/v2/check`
- **Headers:**
  - `Key`: `<YOUR_ABUSEIPDB_API_KEY>`
  - `Accept`: `application/json`
- **Queries:**
  - `ipAddress`: `@{items('For_each_IP')?['properties']?['address']}`
  - `maxAgeInDays`: `90`

### Step 4: Parse JSON Response
Use the sample schema from AbuseIPDB:
```json
{
  "data": {
    "ipAddress": "198.51.100.2",
    "isPublic": true,
    "ipVersion": 4,
    "isWhitelisted": false,
    "abuseConfidenceScore": 88,
    "countryCode": "RU",
    "usageType": "Data Center/Web Hosting/Transit",
    "isp": "BadActor ISP",
    "domain": "badactor.example",
    "totalReports": 342,
    "numDistinctUsers": 78,
    "lastReportedAt": "2026-10-21T08:12:00+00:00"
  }
}
```

### Step 5: Add Comment to Sentinel Incident
- **Action:** *Add comment to incident (V3)*
- **Incident ARM ID:** `triggerBody()?['object']?['id']`
- **Incident Comment:**
  ```markdown
  ### 🔍 Automated Threat Intelligence Triage (AbuseIPDB)
  * **Offending IP:** `@{body('Parse_JSON')?['data']?['ipAddress']}`
  * **Abuse Confidence Score:** `@{body('Parse_JSON')?['data']?['abuseConfidenceScore']}%`
  * **Country / ISP:** `@{body('Parse_JSON')?['data']?['countryCode']}` / `@{body('Parse_JSON')?['data']?['isp']}`
  * **Total Historical Reports:** `@{body('Parse_JSON')?['data']?['totalReports']}`
  * **Recommendation:** If Confidence Score > 75%, escalate to Tier 2 for perimeter blocklist addition.
  ```
