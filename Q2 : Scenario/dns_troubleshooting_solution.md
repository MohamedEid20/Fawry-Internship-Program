# DNS Troubleshooting Solution for internal.example.com

## Situation Analysis

Users are reporting "host not found" errors when trying to access `internal.example.com`. The service appears to be up, suggesting a DNS or network configuration issue rather than a service outage.

## 1️⃣ Verify DNS Resolution

First, we need to compare DNS resolution between local DNS servers (configured in `/etc/resolv.conf`) and an external DNS server (Google's `8.8.8.8`):

### Check current DNS configuration:

cat /etc/resolv.conf

Example output:

````
nameserver 192.168.1.10  # Internal company DNS server
search example.com


### Resolve using system DNS:

```bash
dig internal.example.com
````

Example output showing failure:

```
;; ANSWER SECTION:
;; No answer section
```

### Resolve using external DNS:

```bash
dig @8.8.8.8 internal.example.com
```

Example output:

```
;; ANSWER SECTION:
internal.example.com. 300 IN A 192.168.10.25
```

If the external DNS can't resolve it either, it confirms this is an internal-only domain that should only be resolvable by internal DNS servers.

### Alternative tools:

```bash
nslookup internal.example.com
host internal.example.com
getent hosts internal.example.com
```

## 2️⃣ Diagnose Service Reachability

### Test basic connectivity:

```bash
# If we obtained an IP from DNS or hosts file
ping 192.168.10.25  # Using IP from previous step
```

### Check HTTP service:

```bash
curl -v http://internal.example.com/
# OR
curl -v http://192.168.10.25/
```

### Check HTTPS service:

```bash
curl -v https://internal.example.com/
# OR
curl -v https://192.168.10.25/
```

### Test specific ports:

```bash
telnet internal.example.com 80
telnet internal.example.com 443
# OR using netcat
nc -zv internal.example.com 80
nc -zv internal.example.com 443
```

### Check routing path:

```bash
traceroute internal.example.com
# OR
mtr internal.example.com
```

## 3️⃣ Potential Causes of the Issue

### DNS-Related Issues:

1. **Incorrect DNS server configuration** in `/etc/resolv.conf`
2. **Missing or incorrect DNS record** for internal.example.com
3. **DNS caching issues** with outdated/stale records
4. **Split-horizon DNS misconfiguration** (internal vs. external DNS views)
5. **Internal DNS server down** or not responding
6. **DNS zone transfer failure** between primary and secondary DNS servers
7. **Firewall blocking DNS traffic** (UDP/TCP port 53)
8. **DNSSEC validation failures** if DNSSEC is enabled

### Network/Service Issues:

1. **Firewall blocking web traffic** to the internal.example.com server
2. **Routing issues** preventing traffic from reaching the server
3. **Web service down** on the server (Apache/Nginx/etc. not running)
4. **Web service misconfiguration** (wrong virtual host settings)
5. **Network segmentation** preventing access from certain subnets
6. **VPN configuration issues** if access requires VPN
7. **Load balancer problems** if service is behind a load balancer
8. **NAT issues** if there's network address translation involved
9. **Certificate issues** for HTTPS connections
10. **Proxy configuration problems** if traffic goes through a proxy

## 4️⃣ Fixing the Issues

### For DNS Issues:

#### 1. Incorrect DNS Server Configuration

**Diagnosis:**

```bash
cat /etc/resolv.conf
ping $(grep nameserver /etc/resolv.conf | head -1 | awk '{print $2}')
```

**Fix:**

```bash
# Edit resolv.conf temporarily
sudo nano /etc/resolv.conf
# Add correct nameservers:
# nameserver 192.168.1.10
# nameserver 192.168.1.11
```

#### 2. Missing or Incorrect DNS Record

**Diagnosis:**

```bash
# Check if the record exists on the DNS server
dig @192.168.1.10 internal.example.com
```

**Fix (on DNS server):**

```bash
# Access the DNS server and add/correct the record
# For BIND:
sudo nano /etc/bind/zones/db.example.com
# Add: internal  IN  A  192.168.10.25

# Then reload the DNS server:
sudo systemctl reload bind9
```

#### 3. DNS Caching Issues

**Diagnosis:**

```bash
# Check cached records
dig +trace internal.example.com
```

**Fix:**

```bash
# Flush DNS cache
# For systemd-resolved:
sudo systemd-resolve --flush-caches

# For nscd:
sudo systemctl restart nscd
```

#### 4. Internal DNS Server Down

**Diagnosis:**

```bash
# Check if DNS server is responding
dig @192.168.1.10 example.com
```

**Fix:**

```bash
# On the DNS server:
sudo systemctl status bind9
sudo systemctl restart bind9
```

### For Network/Service Issues:

#### 1. Firewall Blocking Web Traffic

**Diagnosis:**

```bash
# Check firewall rules
sudo iptables -L
sudo ufw status
```

**Fix:**

```bash
# Allow HTTP/HTTPS traffic
sudo ufw allow http
sudo ufw allow https
# OR
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo netfilter-persistent save
```

#### 2. Web Service Down

**Diagnosis:**

```bash
# Check if service is running
sudo systemctl status apache2
# OR
sudo systemctl status nginx

# Check listening ports
sudo ss -tlnp | grep '80\|443'
```

**Fix:**

```bash
# Start/restart the web service
sudo systemctl restart apache2
# OR
sudo systemctl restart nginx
```

#### 3. Routing Issues

**Diagnosis:**

```bash
# Check routing table
ip route
# Trace route to destination
traceroute internal.example.com
```

**Fix:**

```bash
# Add specific route if needed
sudo ip route add 192.168.10.0/24 via 192.168.1.1
# Make persistent:
echo "192.168.10.0/24 via 192.168.1.1" | sudo tee -a /etc/network/routes
```

## 🏆 Bonus Solutions

### Configure Local /etc/hosts Entry for Testing

This bypasses DNS resolution completely, allowing you to test if the service is accessible when DNS issues are eliminated:

```bash
# Add entry to hosts file
sudo sh -c 'echo "192.168.10.25 internal.example.com" >> /etc/hosts'

# Verify it works
ping internal.example.com
curl http://internal.example.com/
```

To remove the entry after testing:

```bash
sudo sed -i '/internal.example.com/d' /etc/hosts
```

### Persist DNS Settings

#### Using systemd-resolved:

```bash
sudo nano /etc/systemd/resolved.conf
```

Add/modify:

```
[Resolve]
DNS=192.168.1.10 192.168.1.11
Domains=example.com
```

Then restart the service:

```bash
sudo systemctl restart systemd-resolved
```

#### Using NetworkManager:

```bash
# Edit connection
sudo nmcli connection modify "Ethernet connection 1" ipv4.dns "192.168.1.10 192.168.1.11"
sudo nmcli connection modify "Ethernet connection 1" ipv4.dns-search "example.com"

# Reconnect to apply changes
sudo nmcli connection up "Ethernet connection 1"
```

## 📸 Documentation Process

For a real-world situation, document each step with screenshots:

1. Initial error screenshots from users
2. DNS resolution tests and results
3. Service connectivity tests
4. Configuration changes and their effects
5. Final verification showing the restored service

This documentation helps with:

- Future troubleshooting of similar issues
- Training for other team members
- Audit trails for system changes
- Root cause analysis reports
