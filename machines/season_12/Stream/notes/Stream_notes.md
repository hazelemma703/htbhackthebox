# Stream — HackTheBox

> **IP:** 10.129.13.197
> **Date:** $(date '+%Y-%m-%d')
> **Difficulty:** Medium
> **OS:** Linux

---

## Reconnaissance

### Nmap

\`\`\`bash
# Paste scan results here
\`\`\`

### Web

- api app
```
http://api.htb-airport.htb/
```

this response a joso data

```json
{"service":"terminal-edge-gateway","status":"operational","version":"1.0.0","node":"tg-edge-01","region":"eu-central-1","uptime":"2d 9h 14m 14s","upstreams":{"flight-data-service":"UP","boarding-control":"UP","gate-assignment":"UP","passenger-manifest":"UP"},"message":"All terminal gateway systems are operational.","timestamp":"2026-10-10T19:46:19.840121931Z"}
```

\`\`\`bash
# Web enumeration results
\`\`\`

---

## Foothold

- **Vector:**
- **Exploit:**

\`\`\`bash
# Exploitation commands
\`\`\`

---

## User Flag

\`\`\`
user.txt:
\`\`\`

---

## Privilege Escalation

- **Vector:**
- **Method:**

\`\`\`bash
# Privesc commands
\`\`\`

---

## Root Flag

\`\`\`
root.txt:
\`\`\`

---

## Credentials

| Service | Username | Password |
|---------|----------|----------|
|         |          |          |

---

## Lessons Learned

-
