# SOC Incident Investigation Report

| Field | Details |
|---|---|
| **Incident ID** | INC-20261021-001 |
| **Severity** | High |
| **Status** | Closed (Contained & Remediated) |
| **Lead Analyst** | Security Operations Analyst (Tier 1 / Tier 2) |
| **Date / Time Detected** | 2026-10-21 09:14:22 UTC |
| **Affected Asset(s)** | `vm-target-endpoint` (10.0.0.4) |
| **Identified Attacker IP** | `198.51.100.2` (DigitalOcean ASN / Abuse Score: 92%) |

---

## 1. Executive Summary
On October 21, 2026, Microsoft Sentinel generated a High-severity alert indicating anomalous brute-force authentication activity against endpoint `vm-target-endpoint`. Subsequent investigation revealed unauthorized access via compromised credentials, followed by defense evasion and persistence through local administrator account creation (`SOCBackdoorUser`). The attacker IP was isolated at the Network Security Group (NSG) layer, the compromised account was disabled, and forensic artifacts were preserved.

---

## 2. MITRE ATT&CK Mapping

```
[Initial Access / Credential Access] ──► [Defense Evasion / Execution] ──► [Persistence]
       T1110.001 (Brute Force)              T1105 / T1218 (Certutil)           T1136.001 (Local Account)
```

- **Initial Access & Credential Access:** [T1110.001 - Brute Force: Password Guessing](https://attack.mitre.org/techniques/T1110/001/)
- **Execution / Defense Evasion:** [T1105 - Ingress Tool Transfer](https://attack.mitre.org/techniques/T1105/) & [T1218 - System Binary Proxy Execution: Certutil](https://attack.mitre.org/techniques/T1218/)
- **Persistence:** [T1136.001 - Create Account: Local Account](https://attack.mitre.org/techniques/T1136/001/)

---

## 3. Incident Timeline (UTC)

| Timestamp | Event ID / Source | Activity Description |
|---|---|---|
| **09:10:15** | WinSec 4625 | 14 consecutive failed RDP logon attempts from source `198.51.100.2`. |
| **09:13:02** | WinSec 4624 | Successful RDP logon for user account `AdminUser` from `198.51.100.2`. |
| **09:14:22** | Sentinel Alert | Rule `High-Volume RDP Brute Force Detection` triggered. Incident created. |
| **09:15:40** | Sysmon 1 | Process `certutil.exe -urlcache -split -f <external_url>` spawned by `AdminUser`. |
| **09:17:11** | WinSec 4720 | New local user `SOCBackdoorUser` created. |
| **09:17:15** | WinSec 4732 | `SOCBackdoorUser` added to local `Administrators` security group. |
| **09:22:00** | Analyst Action | SOC analyst acknowledged alert; isolated host from external network. |

---

## 4. Root Cause Analysis
The target virtual machine had Remote Desktop Protocol (Port 3389) exposed directly to the public internet without Multi-Factor Authentication (MFA) or network IP whitelisting. The local account `AdminUser` was protected only by a weak password, allowing automated password spraying / brute force to succeed within 14 attempts.

---

## 5. Containment & Remediation Actions

1. **Network Containment:** Added immediate Deny Inbound rule in the Azure Network Security Group (NSG) for attacker IP `198.51.100.2`.
2. **Account Remediation:**
   - Disabled the compromised `AdminUser` account and initiated a forced password reset.
   - Deleted the rogue backdoor user `SOCBackdoorUser` via `net user SOCBackdoorUser /delete`.
3. **Artifact Cleanup:** Removed downloaded payload located at `C:\Users\AdminUser\AppData\Local\Temp\simulated_payload.txt`.
4. **Hardening Measures:**
   - Closed public port 3389 inbound; migrated management access to **Azure Bastion** and Just-In-Time (JIT) VM Access.
   - Enforced password complexity and account lockout policies after 5 failed attempts.
