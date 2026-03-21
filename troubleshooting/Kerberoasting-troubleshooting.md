# Kerberoasting Detection – Wazuh Troubleshooting

Quick checklist for when Event ID `4769` is visible on the DC but the Kerberoasting alert does not appear in Wazuh.

---

## 1. Confirm DC Event Logging

On the domain controller:

```powershell
auditpol /get /subcategory:"Kerberos Service Ticket Operations"
```

You should see:

- Setting: `Success and Failure`  

If not, enable it:

```powershell
auditpol /set /subcategory:"Kerberos Service Ticket Operations" /success:enable /failure:enable
```

Verify 4769 events exist:

```powershell
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4769]]" -MaxEvents 5
```

If there are no 4769 events, Wazuh cannot detect Kerberoasting.

---

## 2. Confirm Wazuh Agent on DC01

On `DC01`:

```powershell
Get-Service WazuhSvc
```

Service should be `Running`.

In the Wazuh dashboard:

- Agent status for `DC01` should be `Active`.  

If not, fix connectivity:

1. Check manager IP in agent config:

   ```powershell
   notepad "C:\Program Files (x86)\ossec-agent\ossec.conf"
   ```

   Confirm:

   ```xml
   <server>
     <address>WAZUH_MANAGER_IP</address>
     <port>1514</port>
   </server>
   ```

2. Restart agent:

   ```powershell
   net stop WazuhSvc
   net start WazuhSvc
   ```

If still disconnected, use `Test-NetConnection` to confirm network path to the manager on port 1514.

---

## 3. Verify Logs Reach the Manager

On the Wazuh manager:

```bash
sudo tail -f /var/ossec/logs/archives/archives.log | grep 4769
```

Then run the Kerberoasting attack again.

- If you see 4769 events here, the agent and manager pipeline is working.  
- If not, the agent is not sending Security events; check the agent’s `ossec.conf` and any `agent.conf` overrides for Windows event collection.

---

## 4. Confirm Custom Rule Exists and Is Loaded

On the manager, check the custom rule:

```bash
sudo cat /var/ossec/etc/rules/local_rules.xml
```

Ensure the Kerberoasting rule is present and exactly like this:

```xml
<group name="windows,kerberos,attack">
  <rule id="100500" level="10">
    <if_group>windows</if_group>
    <field name="win.system.eventID">^4769$</field>
    <field name="win.eventdata.ticketEncryptionType">^0x17$</field>
    <description>Possible Kerberoasting (4769 TGS, RC4 ticketEncryptionType 0x17)</description>
    <mitre>
      <id>T1558.003</id>
    </mitre>
  </rule>
</group>
```

Test rule loading:

```bash
sudo /var/ossec/bin/wazuh-analysisd -t
```

- Fix any XML or rule errors reported.  
- When clean, restart the manager:

```bash
sudo systemctl restart wazuh-manager
```

---

## 5. Validate Rule Matching with wazuh-logtest

1. Grab a sample 4769 event from archives:

   ```bash
   sudo grep '"eventID":"4769"' /var/ossec/logs/archives/archives.log | tail -1
   ```

2. Copy the full JSON portion starting at the first `{`.

3. Run logtest:

   ```bash
   sudo /var/ossec/bin/wazuh-logtest
   ```

4. Paste the JSON and press Enter twice.

You want to see in Phase 3:

- `id: '100500'`  
- Description: your Kerberoasting rule text  

If you only see rule `1002` (unknown problem) then the custom rule is not matching and you should:

- Re-check field names (`win.system.eventID`, `win.eventdata.ticketEncryptionType`).  
- Confirm the value of `ticketEncryptionType` in the event is `0x17`, not `0x12` or another value.

---

## 6. Confirm Alerts Are Written

With everything loaded and matching in logtest, generate a fresh Kerberoasting run, then on the manager:

```bash
sudo grep "100500" /var/ossec/logs/alerts/alerts.log | tail -5
```

You should see new lines for rule `100500`.

If alerts exist in `alerts.log` but not in the dashboard:

- Check that `wazuh-manager`, `wazuh-indexer`, and `wazuh-dashboard` services are all running.  
- Confirm your Discover view points to index pattern `wazuh-alerts-*` and time range covers the attack window.

---

## Quick Decision Tree

- No 4769 on DC01 → Fix audit policy.  
- 4769 on DC01, none in archives → Fix agent config or connectivity.  
- 4769 in archives, no rule match in logtest → Fix custom rule (fields, `if_group`, syntax).  
- Rule matches in logtest, no entries in alerts.log → Check manager service and rule loading.  
- Entries in alerts.log, nothing in dashboard → Fix index pattern or time range in Wazuh UI.

This file is meant as a fast runbook so you can get Kerberoasting detection working again without re-learning all the steps.
