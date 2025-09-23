# Domain Name System (DNS): The Internet's Phone Book

## 🎯 What is DNS?

DNS is like the phone book of the internet. Just as you look up someone's name to find their phone number, DNS translates human-readable domain names (like google.com) into IP addresses (like 142.250.191.14) that computers use to communicate. Without DNS, you'd have to remember numerical IP addresses for every website you want to visit.

## 🏗️ Core Concepts

### The Phone Book Analogy
- **Domain Name**: Person's name (easy to remember)
- **IP Address**: Phone number (what devices actually use)
- **DNS Server**: Phone book (contains the mappings)
- **DNS Query**: Looking up a name to find the number
- **DNS Cache**: Your personal address book (frequently used numbers)

### Why DNS Matters
1. **User-Friendly**: Humans remember names better than numbers
2. **Flexibility**: IP addresses can change without affecting domain names
3. **Load Distribution**: Multiple IP addresses can serve the same domain
4. **Service Discovery**: Find services and resources on networks
5. **Global Scalability**: Hierarchical system scales worldwide

## 🏛️ DNS Hierarchy

### DNS Tree Structure
```python
class DNSHierarchy:
    def __init__(self):
        self.root_servers = [
            "198.41.0.4",    # a.root-servers.net
            "199.9.14.201",  # b.root-servers.net
            "192.33.4.12",   # c.root-servers.net
            # ... 13 root servers total
        ]
        
        self.tld_servers = {
            'com': ['192.5.6.30', '192.12.94.30'],
            'org': ['199.19.56.1', '199.19.57.1'],
            'net': ['192.5.5.241', '192.12.94.30'],
            'edu': ['192.5.89.10', '192.12.94.30'],
            'gov': ['192.5.89.10', '192.12.94.30']
        }
        
        self.authoritative_servers = {
            'google.com': ['216.239.32.10', '216.239.34.10'],
            'facebook.com': ['157.240.1.35', '157.240.1.36'],
            'amazon.com': ['205.251.242.103', '205.251.245.203']
        }
    
    def resolve_domain(self, domain):
        """Simulate DNS resolution process"""
        print(f"Resolving {domain}...")
        
        # Step 1: Query root server
        root_response = self.query_root_server(domain)
        print(f"Root server says: Ask TLD server for .{root_response['tld']}")
        
        # Step 2: Query TLD server
        tld_response = self.query_tld_server(domain, root_response['tld'])
        print(f"TLD server says: Ask {tld_response['authoritative']} for {domain}")
        
        # Step 3: Query authoritative server
        auth_response = self.query_authoritative_server(domain, tld_response['authoritative'])
        print(f"Authoritative server says: {domain} is {auth_response['ip']}")
        
        return auth_response['ip']
    
    def query_root_server(self, domain):
        """Query root server for TLD information"""
        tld = domain.split('.')[-1]
        return {
            'tld': tld,
            'tld_servers': self.tld_servers.get(tld, [])
        }
    
    def query_tld_server(self, domain, tld):
        """Query TLD server for authoritative server"""
        return {
            'domain': domain,
            'authoritative': self.authoritative_servers.get(domain, ['unknown'])[0]
        }
    
    def query_authoritative_server(self, domain, auth_server):
        """Query authoritative server for final IP"""
        # Simulate looking up A record
        ip_addresses = self.authoritative_servers.get(domain, ['127.0.0.1'])
        return {
            'domain': domain,
            'ip': ip_addresses[0],
            'ttl': 300  # 5 minutes
        }

# Example usage
dns = DNSHierarchy()
ip_address = dns.resolve_domain('google.com')
print(f"Final result: google.com -> {ip_address}")
```

## 📋 DNS Record Types

### Common DNS Record Types
```python
class DNSRecords:
    def __init__(self):
        self.records = {
            'example.com': {
                'A': ['192.0.2.1', '192.0.2.2'],           # IPv4 addresses
                'AAAA': ['2001:db8::1', '2001:db8::2'],    # IPv6 addresses
                'CNAME': [],                                # Canonical name (alias)
                'MX': [                                     # Mail exchange
                    {'priority': 10, 'server': 'mail1.example.com'},
                    {'priority': 20, 'server': 'mail2.example.com'}
                ],
                'NS': [                                     # Name servers
                    'ns1.example.com',
                    'ns2.example.com'
                ],
                'TXT': [                                    # Text records
                    'v=spf1 include:_spf.example.com ~all',
                    'google-site-verification=abc123'
                ],
                'SRV': [                                    # Service records
                    {'priority': 10, 'weight': 60, 'port': 5060, 'target': 'sip1.example.com'},
                    {'priority': 10, 'weight': 40, 'port': 5060, 'target': 'sip2.example.com'}
                ],
                'PTR': 'example.com',                       # Reverse DNS
                'SOA': {                                    # Start of Authority
                    'primary': 'ns1.example.com',
                    'admin': 'admin.example.com',
                    'serial': 2024012301,
                    'refresh': 3600,
                    'retry': 1800,
                    'expire': 604800,
                    'minimum': 86400
                }
            }
        }
    
    def get_record(self, domain, record_type):
        """Get DNS record for domain and type"""
        domain_records = self.records.get(domain, {})
        return domain_records.get(record_type, [])
    
    def add_record(self, domain, record_type, value):
        """Add DNS record"""
        if domain not in self.records:
            self.records[domain] = {}
        
        if record_type not in self.records[domain]:
            self.records[domain][record_type] = []
        
        if isinstance(self.records[domain][record_type], list):
            self.records[domain][record_type].append(value)
        else:
            self.records[domain][record_type] = value

# Example DNS record configurations
def setup_web_application_dns():
    """Example DNS setup for web application"""
    dns_records = DNSRecords()
    
    # Main website
    dns_records.add_record('myapp.com', 'A', '203.0.113.1')
    dns_records.add_record('myapp.com', 'A', '203.0.113.2')  # Load balancing
    
    # WWW subdomain (alias)
    dns_records.add_record('www.myapp.com', 'CNAME', 'myapp.com')
    
    # API subdomain
    dns_records.add_record('api.myapp.com', 'A', '203.0.113.10')
    dns_records.add_record('api.myapp.com', 'A', '203.0.113.11')
    
    # CDN subdomain
    dns_records.add_record('cdn.myapp.com', 'CNAME', 'myapp.cloudfront.net')
    
    # Email servers
    dns_records.add_record('myapp.com', 'MX', {'priority': 10, 'server': 'mail1.myapp.com'})
    dns_records.add_record('myapp.com', 'MX', {'priority': 20, 'server': 'mail2.myapp.com'})
    
    # Email security (SPF, DKIM, DMARC)
    dns_records.add_record('myapp.com', 'TXT', 'v=spf1 include:_spf.google.com ~all')
    dns_records.add_record('_dmarc.myapp.com', 'TXT', 'v=DMARC1; p=quarantine; rua=mailto:dmarc@myapp.com')
    
    return dns_records
```

## 🔄 DNS Resolution Process

### Step-by-Step Resolution
```python
class DNSResolver:
    def __init__(self):
        self.cache = DNSCache()
        self.root_servers = RootServerList()
        self.stats = {'queries': 0, 'cache_hits': 0, 'cache_misses': 0}
    
    def resolve(self, domain, record_type='A'):
        """Resolve domain name to IP address"""
        self.stats['queries'] += 1
        
        # Step 1: Check local cache
        cached_result = self.cache.get(domain, record_type)
        if cached_result and not cached_result.is_expired():
            self.stats['cache_hits'] += 1
            return cached_result.value
        
        self.stats['cache_misses'] += 1
        
        # Step 2: Perform iterative resolution
        result = self.iterative_resolve(domain, record_type)
        
        # Step 3: Cache the result
        self.cache.set(domain, record_type, result, ttl=result.get('ttl', 300))
        
        return result
    
    def iterative_resolve(self, domain, record_type):
        """Perform iterative DNS resolution"""
        
        # Start with root servers
        current_servers = self.root_servers.get_servers()
        domain_parts = domain.split('.')
        
        for i in range(len(domain_parts)):
            # Query current set of servers
            for server in current_servers:
                try:
                    response = self.query_server(server, domain, record_type)
                    
                    if response.is_authoritative_answer():
                        # Found the answer
                        return response.get_answer()
                    
                    elif response.has_referral():
                        # Got referral to more specific servers
                        current_servers = response.get_referral_servers()
                        break
                        
                except DNSTimeoutException:
                    continue  # Try next server
            
            else:
                # All servers failed
                raise DNSResolutionException(f"Failed to resolve {domain}")
        
        raise DNSResolutionException(f"No authoritative answer for {domain}")
    
    def query_server(self, server, domain, record_type):
        """Query specific DNS server"""
        query = DNSQuery(domain, record_type)
        
        try:
            # Send UDP query (DNS typically uses UDP)
            response = self.send_udp_query(server, query)
            
            if response.is_truncated():
                # Response too large for UDP, retry with TCP
                response = self.send_tcp_query(server, query)
            
            return response
            
        except socket.timeout:
            raise DNSTimeoutException(f"Timeout querying {server}")

class DNSCache:
    def __init__(self, max_size=10000):
        self.cache = {}
        self.max_size = max_size
        self.access_times = {}
    
    def get(self, domain, record_type):
        """Get cached DNS record"""
        cache_key = f"{domain}:{record_type}"
        
        if cache_key in self.cache:
            self.access_times[cache_key] = time.time()
            return self.cache[cache_key]
        
        return None
    
    def set(self, domain, record_type, value, ttl):
        """Cache DNS record with TTL"""
        cache_key = f"{domain}:{record_type}"
        
        # Implement LRU eviction if cache is full
        if len(self.cache) >= self.max_size:
            self.evict_lru()
        
        cache_entry = DNSCacheEntry(value, ttl)
        self.cache[cache_key] = cache_entry
        self.access_times[cache_key] = time.time()
    
    def evict_lru(self):
        """Evict least recently used entry"""
        if not self.access_times:
            return
        
        lru_key = min(self.access_times.keys(), key=lambda k: self.access_times[k])
        del self.cache[lru_key]
        del self.access_times[lru_key]

class DNSCacheEntry:
    def __init__(self, value, ttl):
        self.value = value
        self.cached_at = time.time()
        self.ttl = ttl
    
    def is_expired(self):
        """Check if cache entry has expired"""
        return time.time() - self.cached_at > self.ttl
```

## 🌍 Real-World DNS Examples

### 1. Google's DNS Infrastructure
```python
class GoogleDNSSimulation:
    def __init__(self):
        # Google Public DNS
        self.public_dns_servers = ['8.8.8.8', '8.8.4.4']
        
        # Google's authoritative servers
        self.authoritative_servers = {
            'google.com': ['216.239.32.10', '216.239.34.10', '216.239.36.10', '216.239.38.10'],
            'youtube.com': ['216.239.32.10', '216.239.34.10'],
            'gmail.com': ['216.239.32.10', '216.239.34.10']
        }
        
        # Anycast network - same IP, multiple locations
        self.anycast_locations = {
            '8.8.8.8': [
                {'location': 'Mountain View, CA', 'latency': 10},
                {'location': 'New York, NY', 'latency': 50},
                {'location': 'London, UK', 'latency': 100},
                {'location': 'Tokyo, Japan', 'latency': 150}
            ]
        }
    
    def resolve_with_anycast(self, client_location, domain):
        """Simulate anycast DNS resolution"""
        
        # Find nearest Google DNS server
        nearest_server = self.find_nearest_anycast_server(client_location)
        
        print(f"Client in {client_location} routed to DNS server in {nearest_server['location']}")
        print(f"Latency: {nearest_server['latency']}ms")
        
        # Perform resolution
        return self.resolve_domain(domain)
    
    def find_nearest_anycast_server(self, client_location):
        """Find nearest anycast server (simplified)"""
        # In reality, this is done by BGP routing
        servers = self.anycast_locations['8.8.8.8']
        
        # Simulate geographic proximity
        location_distances = {
            'San Francisco': {'Mountain View, CA': 10, 'New York, NY': 50, 'London, UK': 100, 'Tokyo, Japan': 150},
            'New York': {'New York, NY': 10, 'Mountain View, CA': 50, 'London, UK': 80, 'Tokyo, Japan': 140},
            'London': {'London, UK': 10, 'New York, NY': 80, 'Mountain View, CA': 100, 'Tokyo, Japan': 120},
            'Tokyo': {'Tokyo, Japan': 10, 'London, UK': 120, 'Mountain View, CA': 150, 'New York, NY': 140}
        }
        
        distances = location_distances.get(client_location, {})
        nearest_location = min(distances.keys(), key=lambda loc: distances[loc])
        
        return next(server for server in servers if server['location'] == nearest_location)

# Example: Global DNS resolution
google_dns = GoogleDNSSimulation()

# Client in San Francisco
sf_result = google_dns.resolve_with_anycast('San Francisco', 'google.com')

# Client in London  
london_result = google_dns.resolve_with_anycast('London', 'google.com')
```

### 2. Cloudflare's 1.1.1.1 DNS
```python
class CloudflareDNSSimulation:
    def __init__(self):
        self.dns_servers = ['1.1.1.1', '1.0.0.1']
        self.edge_locations = 200+  # 200+ cities
        self.privacy_features = {
            'no_logging': True,
            'dns_over_https': True,
            'dns_over_tls': True,
            'malware_blocking': True
        }
    
    def resolve_with_privacy(self, domain, client_ip):
        """Resolve DNS with privacy protection"""
        
        # Don't log client IP or queries
        if not self.privacy_features['no_logging']:
            self.log_query(client_ip, domain)  # This won't happen
        
        # Check malware database
        if self.privacy_features['malware_blocking']:
            if self.is_malware_domain(domain):
                return self.block_response("Malware detected")
        
        # Resolve normally
        result = self.resolve_domain(domain)
        
        # Return result without tracking
        return result
    
    def dns_over_https(self, domain):
        """DNS over HTTPS (DoH) implementation"""
        
        # Encrypt DNS query over HTTPS
        encrypted_query = {
            'name': domain,
            'type': 'A',
            'do': False,  # DNSSEC validation
            'cd': False   # Checking disabled
        }
        
        # Send to https://cloudflare-dns.com/dns-query
        response = self.send_doh_query(encrypted_query)
        
        return self.parse_doh_response(response)
    
    def dns_over_tls(self, domain):
        """DNS over TLS (DoT) implementation"""
        
        # Establish TLS connection on port 853
        tls_connection = self.establish_tls_connection('1.1.1.1', 853)
        
        # Send encrypted DNS query
        query = self.create_dns_query(domain, 'A')
        encrypted_query = tls_connection.encrypt(query)
        
        response = tls_connection.send_and_receive(encrypted_query)
        
        return self.parse_dns_response(response)
```

### 3. Amazon Route 53
```python
class Route53Simulation:
    def __init__(self):
        self.hosted_zones = {}
        self.health_checks = {}
        self.routing_policies = [
            'simple', 'weighted', 'latency', 'failover', 'geolocation', 'multivalue'
        ]
    
    def create_hosted_zone(self, domain):
        """Create hosted zone for domain"""
        zone_id = f"Z{hash(domain) % 1000000:06d}"
        
        self.hosted_zones[zone_id] = {
            'domain': domain,
            'records': {},
            'name_servers': [
                f"ns-{random.randint(1, 2048)}.awsdns-{random.randint(10, 64)}.com",
                f"ns-{random.randint(1, 2048)}.awsdns-{random.randint(10, 64)}.net",
                f"ns-{random.randint(1, 2048)}.awsdns-{random.randint(10, 64)}.org",
                f"ns-{random.randint(1, 2048)}.awsdns-{random.randint(10, 64)}.co.uk"
            ]
        }
        
        return zone_id
    
    def create_weighted_routing(self, zone_id, name, records_with_weights):
        """Create weighted routing policy"""
        
        total_weight = sum(record['weight'] for record in records_with_weights)
        
        routing_config = {
            'type': 'weighted',
            'records': records_with_weights,
            'total_weight': total_weight
        }
        
        self.hosted_zones[zone_id]['records'][name] = routing_config
    
    def resolve_weighted(self, zone_id, name):
        """Resolve using weighted routing"""
        
        record_config = self.hosted_zones[zone_id]['records'].get(name)
        if not record_config or record_config['type'] != 'weighted':
            return None
        
        # Select record based on weights
        random_weight = random.randint(1, record_config['total_weight'])
        current_weight = 0
        
        for record in record_config['records']:
            current_weight += record['weight']
            if random_weight <= current_weight:
                return record['value']
        
        return record_config['records'][-1]['value']  # Fallback
    
    def create_latency_routing(self, zone_id, name, regional_records):
        """Create latency-based routing"""
        
        routing_config = {
            'type': 'latency',
            'regional_records': regional_records  # {region: ip_address}
        }
        
        self.hosted_zones[zone_id]['records'][name] = routing_config
    
    def resolve_latency(self, zone_id, name, client_location):
        """Resolve using latency-based routing"""
        
        record_config = self.hosted_zones[zone_id]['records'].get(name)
        if not record_config or record_config['type'] != 'latency':
            return None
        
        # Find region with lowest latency to client
        lowest_latency = float('inf')
        best_region = None
        
        for region, ip_address in record_config['regional_records'].items():
            latency = self.calculate_latency(client_location, region)
            if latency < lowest_latency:
                lowest_latency = latency
                best_region = region
        
        return record_config['regional_records'][best_region]

# Example Route 53 setup
route53 = Route53Simulation()

# Create hosted zone
zone_id = route53.create_hosted_zone('myapp.com')

# Set up weighted routing for A/B testing
route53.create_weighted_routing(zone_id, 'myapp.com', [
    {'value': '203.0.113.1', 'weight': 70},  # 70% traffic
    {'value': '203.0.113.2', 'weight': 30}   # 30% traffic
])

# Set up latency-based routing
route53.create_latency_routing(zone_id, 'api.myapp.com', {
    'us-east-1': '203.0.113.10',
    'us-west-2': '203.0.113.11', 
    'eu-west-1': '203.0.113.12',
    'ap-southeast-1': '203.0.113.13'
})
```

## 🔧 Advanced DNS Features

### 1. DNSSEC (DNS Security Extensions)
```python
class DNSSECImplementation:
    def __init__(self):
        self.key_pairs = {}  # Domain -> {private_key, public_key}
        self.signatures = {}  # Record -> signature
        self.trust_anchors = {}  # Root keys
    
    def sign_dns_record(self, domain, record_type, record_value):
        """Sign DNS record with DNSSEC"""
        
        # Get domain's private key
        private_key = self.key_pairs[domain]['private_key']
        
        # Create canonical form of record
        canonical_record = self.canonicalize_record(domain, record_type, record_value)
        
        # Sign the record
        signature = self.create_signature(canonical_record, private_key)
        
        # Store signature
        record_key = f"{domain}:{record_type}"
        self.signatures[record_key] = {
            'signature': signature,
            'key_tag': self.calculate_key_tag(domain),
            'algorithm': 'RSASHA256',
            'labels': len(domain.split('.')),
            'original_ttl': 300,
            'expiration': time.time() + 86400,  # 24 hours
            'inception': time.time()
        }
        
        return signature
    
    def verify_dns_record(self, domain, record_type, record_value, signature_data):
        """Verify DNSSEC signature"""
        
        # Get domain's public key (DNSKEY record)
        public_key = self.get_public_key(domain)
        
        if not public_key:
            return False, "No public key found"
        
        # Recreate canonical form
        canonical_record = self.canonicalize_record(domain, record_type, record_value)
        
        # Verify signature
        is_valid = self.verify_signature(canonical_record, signature_data['signature'], public_key)
        
        # Check signature validity period
        current_time = time.time()
        if current_time < signature_data['inception'] or current_time > signature_data['expiration']:
            return False, "Signature expired or not yet valid"
        
        return is_valid, "Valid" if is_valid else "Invalid signature"
    
    def create_ds_record(self, domain, parent_domain):
        """Create DS record for delegation"""
        
        # Get KSK (Key Signing Key) from child domain
        ksk_public_key = self.key_pairs[domain]['public_key']
        
        # Calculate digest
        ds_digest = self.calculate_sha256_digest(domain, ksk_public_key)
        
        ds_record = {
            'key_tag': self.calculate_key_tag(domain),
            'algorithm': 8,  # RSASHA256
            'digest_type': 2,  # SHA-256
            'digest': ds_digest
        }
        
        return ds_record
```

### 2. DNS Load Balancing
```python
class DNSLoadBalancer:
    def __init__(self):
        self.server_pools = {}
        self.health_checks = {}
        self.algorithms = {
            'round_robin': self.round_robin_select,
            'weighted': self.weighted_select,
            'least_connections': self.least_connections_select,
            'geographic': self.geographic_select
        }
    
    def add_server_pool(self, domain, servers, algorithm='round_robin'):
        """Add server pool for domain"""
        self.server_pools[domain] = {
            'servers': servers,
            'algorithm': algorithm,
            'current_index': 0,
            'health_status': {server['ip']: True for server in servers}
        }
    
    def resolve_with_load_balancing(self, domain, client_location=None):
        """Resolve domain with load balancing"""
        
        pool = self.server_pools.get(domain)
        if not pool:
            return None
        
        # Filter healthy servers
        healthy_servers = [
            server for server in pool['servers']
            if pool['health_status'][server['ip']]
        ]
        
        if not healthy_servers:
            # All servers unhealthy, return any server
            healthy_servers = pool['servers']
        
        # Select server based on algorithm
        algorithm = self.algorithms[pool['algorithm']]
        selected_server = algorithm(domain, healthy_servers, client_location)
        
        return selected_server['ip']
    
    def round_robin_select(self, domain, servers, client_location):
        """Round robin server selection"""
        pool = self.server_pools[domain]
        selected_server = servers[pool['current_index'] % len(servers)]
        pool['current_index'] += 1
        return selected_server
    
    def weighted_select(self, domain, servers, client_location):
        """Weighted server selection"""
        total_weight = sum(server.get('weight', 1) for server in servers)
        random_weight = random.randint(1, total_weight)
        
        current_weight = 0
        for server in servers:
            current_weight += server.get('weight', 1)
            if random_weight <= current_weight:
                return server
        
        return servers[-1]  # Fallback
    
    def geographic_select(self, domain, servers, client_location):
        """Geographic server selection"""
        if not client_location:
            return servers[0]
        
        # Find server in same region
        for server in servers:
            if server.get('region') == client_location.get('region'):
                return server
        
        # Find nearest server by distance
        min_distance = float('inf')
        nearest_server = servers[0]
        
        for server in servers:
            distance = self.calculate_distance(
                client_location, 
                server.get('location', {})
            )
            if distance < min_distance:
                min_distance = distance
                nearest_server = server
        
        return nearest_server
    
    def perform_health_checks(self):
        """Perform health checks on all servers"""
        for domain, pool in self.server_pools.items():
            for server in pool['servers']:
                is_healthy = self.check_server_health(server)
                pool['health_status'][server['ip']] = is_healthy
    
    def check_server_health(self, server):
        """Check if server is healthy"""
        try:
            # Simple HTTP health check
            response = requests.get(
                f"http://{server['ip']}/health",
                timeout=5
            )
            return response.status_code == 200
        except requests.RequestException:
            return False

# Example usage
dns_lb = DNSLoadBalancer()

# Add server pool for myapp.com
dns_lb.add_server_pool('myapp.com', [
    {'ip': '203.0.113.1', 'weight': 3, 'region': 'us-east', 'location': {'lat': 40.7128, 'lon': -74.0060}},
    {'ip': '203.0.113.2', 'weight': 2, 'region': 'us-west', 'location': {'lat': 37.7749, 'lon': -122.4194}},
    {'ip': '203.0.113.3', 'weight': 1, 'region': 'eu-west', 'location': {'lat': 51.5074, 'lon': -0.1278}}
], algorithm='weighted')

# Resolve with load balancing
client_location = {'region': 'us-east', 'lat': 40.7128, 'lon': -74.0060}
selected_ip = dns_lb.resolve_with_load_balancing('myapp.com', client_location)
print(f"Selected server: {selected_ip}")
```

## 📊 DNS Monitoring and Analytics

```python
class DNSMonitoring:
    def __init__(self):
        self.query_logs = []
        self.performance_metrics = {
            'total_queries': 0,
            'cache_hit_ratio': 0,
            'average_response_time': 0,
            'error_rate': 0
        }
        self.geographic_stats = {}
        self.top_domains = {}
    
    def log_dns_query(self, query_info):
        """Log DNS query for analytics"""
        
        log_entry = {
            'timestamp': time.time(),
            'client_ip': query_info['client_ip'],
            'domain': query_info['domain'],
            'record_type': query_info['record_type'],
            'response_code': query_info['response_code'],
            'response_time': query_info['response_time'],
            'cache_hit': query_info['cache_hit'],
            'server_location': query_info['server_location']
        }
        
        self.query_logs.append(log_entry)
        
        # Update metrics
        self.update_metrics(log_entry)
    
    def update_metrics(self, log_entry):
        """Update performance metrics"""
        
        self.performance_metrics['total_queries'] += 1
        
        # Update cache hit ratio
        total_queries = len(self.query_logs)
        cache_hits = sum(1 for log in self.query_logs if log['cache_hit'])
        self.performance_metrics['cache_hit_ratio'] = cache_hits / total_queries
        
        # Update average response time
        total_response_time = sum(log['response_time'] for log in self.query_logs)
        self.performance_metrics['average_response_time'] = total_response_time / total_queries
        
        # Update error rate
        errors = sum(1 for log in self.query_logs if log['response_code'] != 'NOERROR')
        self.performance_metrics['error_rate'] = errors / total_queries
        
        # Update geographic stats
        client_country = self.get_country_from_ip(log_entry['client_ip'])
        if client_country not in self.geographic_stats:
            self.geographic_stats[client_country] = 0
        self.geographic_stats[client_country] += 1
        
        # Update top domains
        domain = log_entry['domain']
        if domain not in self.top_domains:
            self.top_domains[domain] = 0
        self.top_domains[domain] += 1
    
    def generate_report(self):
        """Generate DNS analytics report"""
        
        # Top 10 queried domains
        top_domains = sorted(
            self.top_domains.items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]
        
        # Top 10 countries by query volume
        top_countries = sorted(
            self.geographic_stats.items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]
        
        # Performance summary
        report = {
            'summary': self.performance_metrics,
            'top_domains': top_domains,
            'top_countries': top_countries,
            'query_volume_by_hour': self.get_hourly_query_volume(),
            'response_time_percentiles': self.calculate_response_time_percentiles()
        }
        
        return report
    
    def detect_anomalies(self):
        """Detect DNS query anomalies"""
        
        anomalies = []
        
        # Detect DDoS attacks (high query volume from single IP)
        ip_query_counts = {}
        recent_logs = [log for log in self.query_logs if time.time() - log['timestamp'] < 3600]
        
        for log in recent_logs:
            ip = log['client_ip']
            if ip not in ip_query_counts:
                ip_query_counts[ip] = 0
            ip_query_counts[ip] += 1
        
        for ip, count in ip_query_counts.items():
            if count > 1000:  # More than 1000 queries per hour
                anomalies.append({
                    'type': 'potential_ddos',
                    'client_ip': ip,
                    'query_count': count,
                    'timeframe': '1 hour'
                })
        
        # Detect DNS tunneling (unusual query patterns)
        for log in recent_logs:
            domain = log['domain']
            if len(domain) > 100 or domain.count('.') > 10:
                anomalies.append({
                    'type': 'potential_dns_tunneling',
                    'domain': domain,
                    'client_ip': log['client_ip'],
                    'timestamp': log['timestamp']
                })
        
        return anomalies
```

## 📚 Conclusion

DNS is a fundamental component of internet infrastructure that enables the user-friendly web we know today. From simple domain name resolution to complex traffic management and security features, DNS continues to evolve to meet the demands of modern applications and security requirements.

**Key Takeaways:**

1. **Hierarchical Design**: DNS's tree structure enables global scalability
2. **Caching Strategy**: Multiple levels of caching improve performance
3. **Record Types**: Different record types serve different purposes
4. **Security**: DNSSEC provides authentication and integrity
5. **Load Balancing**: DNS can distribute traffic across multiple servers

The future of DNS lies in enhanced security (DNS over HTTPS/TLS), improved privacy protection, and integration with edge computing platforms. Whether you're building a simple website or a complex global application, understanding DNS concepts is crucial for creating reliable, performant, and secure systems.

Remember: DNS is not just about translating names to addresses—it's about creating a scalable, secure, and efficient system for service discovery and traffic management across the global internet.
