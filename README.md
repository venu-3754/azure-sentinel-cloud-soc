# Azure Sentinel Cloud SOC & Detection Engineering Lab

![Microsoft Sentinel](https://img.shields.io/badge/SIEM-Microsoft%20Sentinel-blue?style=flat&logo=microsoftazure)
![KQL](https://img.shields.io/badge/Language-KQL%20(Kusto)-orange?style=flat)
![MITRE ATT&CK](https://img.shields.io/badge/Framework-MITRE%20ATT%26CK-red?style=flat)
![SOAR](https://img.shields.io/badge/SOAR-Azure%20Logic%20Apps-green?style=flat)

An end-to-end cloud Security Operations Center (SOC) lab built inside Microsoft Azure using **Microsoft Sentinel**, **Azure Log Analytics**, **Windows Security Events & Sysmon**, and **Azure Logic Apps (SOAR)**.

---

## 📌 Project Overview
The objective of this project is to simulate real-world SOC analyst workflows:
1. **Telemetry Ingestion**: Ingesting endpoint security logs and Sysmon telemetry via Azure Monitor Agent (AMA).
2. **Adversary Simulation**: Executing controlled attack techniques mapped to the MITRE ATT&CK framework (Credential Access, Execution, Persistence, Defense Evasion).
3. **Detection Engineering**: Authoring custom Kusto Query Language (KQL) scheduled analytics rules to detect malicious behavior with minimal false positives.
4. **SOAR Automation**: Building an automated triage playbook using Azure Logic Apps to query threat intelligence (AbuseIPDB API) and alert the SOC team.
5. **Incident Investigation**: Conducting root cause analysis and writing standardized SOC incident reports.

---

## 🏗️ Architecture

```
[Attacker / Public Internet]
             │
             ▼
[Target Windows VM (Azure)]
  ├── Windows Security Events (4625, 4624, 4720, 4728)
  ├── Sysmon Telemetry (Process Creation, Network Connections)
  └── Azure Monitor Agent (AMA) + Data Collection Rule (DCR)
             │
             ▼
[Log Analytics Workspace (law-sentinel-soc)]
             │
             ▼
[Microsoft Sentinel SIEM]
  ├── KQL Analytics Rules (MITRE ATT&CK Mapped)
  ├── Interactive SOC Dashboard (Sentinel Workbooks)
  └── Incident & Alert Queue
             │
             ▼
[Azure Logic Apps (SOAR Playbook)]
  ├── Extract Attacker IP
  ├── Query Threat Intel (AbuseIPDB API)
  └── Post Enriched Incident Summary (Teams / Discord / Email)
```

---

## 🎯 Simulated MITRE ATT&CK Techniques & Detections

| Technique ID | Technique Name | Tactic | Event Source | Detection Query |
|---|---|---|---|---|
| **T1110.001** | Brute Force: Password Guessing | Credential Access | Windows Security (4625) | [`detections/brute_force_rdp.kql`](detections/brute_force_rdp.kql) |
| **T1105** / **T1218** | Ingress Tool Transfer / LOLBAS | Execution / Defense Evasion | Sysmon (Event ID 1) | [`detections/lolbas_certutil_download.kql`](detections/lolbas_certutil_download.kql) |
| **T1136.001** | Create Account: Local Account | Persistence | Windows Security (4720, 4728) | [`detections/local_admin_creation.kql`](detections/local_admin_creation.kql) |
| **T1027** / **T1059.001** | Obfuscated PowerShell Execution | Execution / Defense Evasion | Sysmon (Event ID 1) | [`detections/obfuscated_powershell.kql`](detections/obfuscated_powershell.kql) |

---

## 📁 Repository Structure
```text
├── attack_simulation/
│   └── simulate_attacks.ps1         # Safe script to generate telemetry on target VM
├── detections/
│   ├── brute_force_rdp.kql          # High-volume failed RDP logons
│   ├── lolbas_certutil_download.kql # Malicious use of certutil.exe to pull payloads
│   ├── local_admin_creation.kql     # Backdoor administrative account creation
│   └── obfuscated_powershell.kql    # Base64 encoded and hidden PowerShell execution
├── incident_reports/
│   └── INCIDENT_REPORT_TEMPLATE.md  # Standardized SOC post-incident report template
└── playbooks/
    └── soar_threat_intel_flow.md    # Azure Logic App SOAR playbook architecture
```

---

## 🚀 Step-by-Step Deployment Guide

### 1. Azure Setup & Log Ingestion
- Provision a **Log Analytics Workspace** (`law-sentinel-soc`) and enable **Microsoft Sentinel**.
- Launch a Windows 10/11 or Windows Server 2022 VM (`Standard_B2s`).
- Install [Sysmon with SwiftOnSecurity config](https://github.com/SwiftOnSecurity/sysmon-config).
- Deploy the **Azure Monitor Agent (AMA)** and create a Data Collection Rule (DCR) collecting both `SecurityEvent` and `Microsoft-Windows-Sysmon/Operational`.

### 2. Attack Simulation
- On the target VM, execute the commands from [`attack_simulation/simulate_attacks.ps1`](attack_simulation/simulate_attacks.ps1).

### 3. Detection Engineering
- In Sentinel, navigate to **Analytics** > **Create** > **Scheduled query rule**.
- Copy each query from the [`detections/`](detections/) folder, set the MITRE ATT&CK tactic/technique tags, configure entity mapping (Account, IP, Host), and set evaluation intervals.

### 4. SOAR Playbook Configuration
- In Sentinel, navigate to **Automation** > **Create** > **Playbook with incident trigger**.
- Configure the Logic App flow described in [`playbooks/soar_threat_intel_flow.md`](playbooks/soar_threat_intel_flow.md) to enrich alerts with AbuseIPDB threat scores.

---

## 📈 Sample Incident Investigation Report
See [`incident_reports/INCIDENT_REPORT_TEMPLATE.md`](incident_reports/INCIDENT_REPORT_TEMPLATE.md) for a full walkthrough of investigating a simulated brute force attack followed by unauthorized privilege escalation.
