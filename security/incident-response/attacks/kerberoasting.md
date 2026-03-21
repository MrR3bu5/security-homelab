# Kerberoasting – Active Directory Service Ticket Abuse

## Objective

Show how a low-privileged domain user can request Kerberos service tickets for SPN-backed accounts, extract crackable material, and trigger detection in Wazuh using Windows Security Event ID 4769 with RC4 encryption. 

## Lab Preconditions

- Active Directory domain `LAB.LOCAL` with at least one service account mapped to an SPN, for example `svc_sql`.
- Domain controller `DC01` with:
  - Wazuh agent installed and connected to the manager.
  - Audit policy enabled: `Kerberos Service Ticket Operations` set to Success and Failure.
- Attacker host (Kali) with valid domain user credentials and Impacket installed. 
- Wazuh manager and indexer online, sending data to `wazuh-alerts-*` and `wazuh-archives-*` indexes. 

## Attack Execution

From the Kali attacker, request TGS tickets for all SPN-backed accounts:

```bash
python3 GetUserSPNs.py LAB/bbob:Password123 -dc-ip 10.30.10.10 -outputfile kerberoast_hashes.txt
```

This command:

- Queries Active Directory for accounts with SPNs. 
- Requests Kerberos service tickets for those SPNs. 
- Writes TGS hashes to the output file (for example `kerberoast_hashes.txt`) for offline cracking with tools such as hashcat. 

Each SPN requested generates a Windows Security log entry on `DC01` with Event ID `4769`, one event per service ticket. 

## Observed Telemetry

On the domain controller (`DC01`), Event ID `4769` entries relevant to Kerberoasting include:

- `win.system.eventID`: `4769` (Kerberos service ticket requested). 
- `win.eventdata.targetUserName`: low-privileged domain user, for example `bbob@LAB.LOCAL`.
- `win.eventdata.serviceName`: targeted service account SPN, for example `svc_sql`, not a machine account and not `krbtgt`. 
- `win.eventdata.ticketEncryptionType`: `0x17` (RC4-HMAC), uncommon in modern domains that use AES by default.
- `win.eventdata.ipAddress`: attacker host IP, for example `::ffff:10.30.66.100`. 

Normal `4769` activity usually uses encryption types `0x11` or `0x12` (AES) and often targets computer accounts or `krbtgt` rather than user-backed service accounts. 

## Wazuh Detection Logic

### Custom Rule

Custom Wazuh rule on the manager:

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

Notes:

- `<if_group>windows</if_group>` ensures a Windows decoder has run and populated the `win.*` fields before evaluation. 
- The rule fires for any `4769` event where `ticketEncryptionType` is `0x17`, indicating RC4-encrypted service tickets typically used in Kerberoasting. 

### Where to Look in Wazuh

- **Archives** (`wazuh-archives-*`):
  - Confirm raw ingestion from `DC01`.
  - Example query in Discover:

    ```text
    data.win.system.eventID: 4769
    ```

- **Alerts** (`wazuh-alerts-*`):
  - Confirm detection.
  - Example queries:

    ```text
    rule.id: 100500
    ```

    ```text
    data.win.system.eventID: 4769 AND data.win.eventdata.ticketEncryptionType: 0x17
    ```

A Kerberoasting run should generate a short burst of `4769` events in archives and matching alerts with rule ID `100500` in the alerts index. 

## Troubleshooting Notes

If the Kerberoasting alert does not fire:

1. **Agent connectivity**

   Confirm the Wazuh agent on `DC01` is Active and points to the correct manager IP and port `1514`.

2. **Audit policy**

   On `DC01`, run:

   ```bash
   auditpol /get /subcategory:"Kerberos Service Ticket Operations"
   ```

   It must return `Success and Failure`. 

3. **Event ingestion**

   On the manager, run:

   ```bash
   sudo tail -f /var/ossec/logs/archives/archives.log | grep 4769
   ```

   If `4769` appears here, the pipeline from agent to manager is working.

4. **Rule loading**

   Validate rules:

   ```bash
   sudo /var/ossec/bin/wazuh-analysisd -t
   ```

   Restart manager after any rule change:

   ```bash
   sudo systemctl restart wazuh-manager
   ```


5. **Rule evaluation**

   Use `wazuh-logtest` with a sample `4769` JSON event from `archives.log` to confirm rule `100500` matches as expected.

## Defensive Takeaways

- Kerberoasting uses normal Kerberos behavior, so focus on:
  - Who requested tickets.
  - Which services were targeted.
  - Which encryption types were used. 

- Monitoring Event ID `4769` with `ticketEncryptionType` `0x17` and non-machine `serviceName` values is a practical way to detect Kerberoasting. 

- Centralizing Windows Security logs from all domain controllers into Wazuh or another SIEM, then applying rules like `100500`, enables early detection without relying on network signatures. 
