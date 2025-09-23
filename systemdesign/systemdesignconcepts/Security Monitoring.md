# Security Monitoring: The Digital Watchtower

## 🎯 What is Security Monitoring?

Security monitoring is like having a sophisticated surveillance system for a high-security facility, complete with cameras, motion sensors, and alert systems. Just as security guards watch monitors 24/7 to detect suspicious activities, security monitoring systems continuously observe digital infrastructure to identify threats, anomalies, and potential breaches in real-time, enabling rapid response to protect valuable assets.

## 🏗️ Core Concepts

### The Security Operations Center Analogy
- **SIEM (Security Information and Event Management)**: Central monitoring dashboard
- **Log Aggregation**: Collecting feeds from all security cameras
- **Threat Detection**: AI-powered analysis of suspicious patterns
- **Incident Response**: Security team protocols for different threat levels
- **Forensic Analysis**: Investigating security incidents after they occur
- **Compliance Monitoring**: Ensuring security policies are followed

### Why Security Monitoring Matters
1. **Early Threat Detection**: Identify attacks before they cause damage
2. **Compliance Requirements**: Meet regulatory security standards
3. **Incident Response**: Rapid response to security events
4. **Forensic Analysis**: Understand how breaches occurred
5. **Risk Management**: Continuous assessment of security posture

## 🔍 Security Monitoring Architecture

```python
import time
import threading
import json
import hashlib
import re
from typing import Dict, List, Optional, Any, Set, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from collections import defaultdict, deque
import ipaddress
import statistics

class ThreatLevel(Enum):
    LOW = 1
    MEDIUM = 2
    HIGH = 3
    CRITICAL = 4

class EventType(Enum):
    LOGIN_ATTEMPT = "login_attempt"
    AUTHENTICATION_FAILURE = "auth_failure"
    PRIVILEGE_ESCALATION = "privilege_escalation"
    SUSPICIOUS_ACTIVITY = "suspicious_activity"
    DATA_ACCESS = "data_access"
    SYSTEM_CHANGE = "system_change"
    NETWORK_ANOMALY = "network_anomaly"
    MALWARE_DETECTED = "malware_detected"

@dataclass
class SecurityEvent:
    event_id: str
    timestamp: float
    event_type: EventType
    source_ip: str
    user_id: Optional[str]
    resource: str
    action: str
    success: bool
    threat_level: ThreatLevel
    details: Dict[str, Any]
    raw_log: str
    
class ThreatIntelligence:
    """Threat intelligence and IP reputation service"""
    
    def __init__(self):
        # Simulated threat intelligence feeds
        self.malicious_ips: Set[str] = {
            "192.168.100.1", "10.0.0.100", "172.16.0.100"  # Example malicious IPs
        }
        
        self.suspicious_user_agents = {
            "sqlmap", "nikto", "nmap", "masscan", "zap"
        }
        
        self.known_attack_patterns = {
            "sql_injection": [r"union\s+select", r"drop\s+table", r"exec\s*\("],
            "xss": [r"<script", r"javascript:", r"onerror="],
            "path_traversal": [r"\.\./", r"\.\.\\", r"%2e%2e"],
            "command_injection": [r";\s*cat\s+", r";\s*ls\s+", r"&&\s*whoami"]
        }
        
        self.geo_risk_countries = {"CN", "RU", "KP", "IR"}  # High-risk countries
    
    def check_ip_reputation(self, ip: str) -> Dict[str, Any]:
        """Check IP reputation against threat intelligence"""
        
        reputation_score = 100  # Start with good reputation
        risk_factors = []
        
        # Check against known malicious IPs
        if ip in self.malicious_ips:
            reputation_score = 0
            risk_factors.append("Known malicious IP")
        
        # Check IP type
        try:
            ip_obj = ipaddress.ip_address(ip)
            
            if ip_obj.is_private:
                risk_factors.append("Private IP")
            elif ip_obj.is_multicast:
                reputation_score -= 20
                risk_factors.append("Multicast IP")
            elif ip_obj.is_reserved:
                reputation_score -= 30
                risk_factors.append("Reserved IP")
        
        except ValueError:
            reputation_score = 0
            risk_factors.append("Invalid IP format")
        
        # Simulate geographic risk (normally would use GeoIP service)
        if hash(ip) % 10 < 2:  # 20% chance of high-risk country
            reputation_score -= 40
            risk_factors.append("High-risk geographic location")
        
        return {
            'ip': ip,
            'reputation_score': max(0, reputation_score),
            'risk_factors': risk_factors,
            'is_malicious': reputation_score <= 20
        }
    
    def detect_attack_patterns(self, text: str) -> List[Dict[str, Any]]:
        """Detect known attack patterns in text"""
        
        detected_attacks = []
        
        for attack_type, patterns in self.known_attack_patterns.items():
            for pattern in patterns:
                matches = re.findall(pattern, text, re.IGNORECASE)
                if matches:
                    detected_attacks.append({
                        'attack_type': attack_type,
                        'pattern': pattern,
                        'matches': matches,
                        'confidence': 0.8  # High confidence for known patterns
                    })
        
        return detected_attacks
    
    def check_user_agent(self, user_agent: str) -> Dict[str, Any]:
        """Check user agent for suspicious patterns"""
        
        is_suspicious = False
        risk_factors = []
        
        user_agent_lower = user_agent.lower()
        
        # Check against known attack tools
        for suspicious_ua in self.suspicious_user_agents:
            if suspicious_ua in user_agent_lower:
                is_suspicious = True
                risk_factors.append(f"Contains '{suspicious_ua}' (attack tool)")
        
        # Check for empty or very short user agent
        if len(user_agent.strip()) < 10:
            is_suspicious = True
            risk_factors.append("Unusually short user agent")
        
        # Check for common bot patterns
        bot_patterns = ["bot", "crawler", "spider", "scraper"]
        for pattern in bot_patterns:
            if pattern in user_agent_lower:
                risk_factors.append(f"Bot-like user agent ({pattern})")
        
        return {
            'user_agent': user_agent,
            'is_suspicious': is_suspicious,
            'risk_factors': risk_factors
        }

class AnomalyDetector:
    """Behavioral anomaly detection"""
    
    def __init__(self):
        self.user_baselines: Dict[str, Dict[str, Any]] = {}
        self.ip_baselines: Dict[str, Dict[str, Any]] = {}
        self.learning_window = 86400 * 7  # 7 days
        self.min_samples = 10
    
    def update_user_baseline(self, user_id: str, event: SecurityEvent):
        """Update user behavior baseline"""
        
        if user_id not in self.user_baselines:
            self.user_baselines[user_id] = {
                'login_times': [],
                'source_ips': defaultdict(int),
                'resources_accessed': defaultdict(int),
                'actions_performed': defaultdict(int),
                'last_updated': time.time()
            }
        
        baseline = self.user_baselines[user_id]
        
        # Update login times
        hour_of_day = time.localtime(event.timestamp).tm_hour
        baseline['login_times'].append(hour_of_day)
        
        # Keep only recent data
        cutoff_time = event.timestamp - self.learning_window
        baseline['login_times'] = [t for t in baseline['login_times'] if t >= cutoff_time]
        
        # Update other metrics
        baseline['source_ips'][event.source_ip] += 1
        baseline['resources_accessed'][event.resource] += 1
        baseline['actions_performed'][event.action] += 1
        baseline['last_updated'] = event.timestamp
    
    def detect_user_anomalies(self, user_id: str, event: SecurityEvent) -> List[Dict[str, Any]]:
        """Detect anomalies in user behavior"""
        
        anomalies = []
        
        if user_id not in self.user_baselines:
            return anomalies  # No baseline yet
        
        baseline = self.user_baselines[user_id]
        
        if len(baseline['login_times']) < self.min_samples:
            return anomalies  # Not enough data
        
        # Check login time anomaly
        hour_of_day = time.localtime(event.timestamp).tm_hour
        typical_hours = set(baseline['login_times'])
        
        if hour_of_day not in typical_hours:
            # Calculate how unusual this time is
            hour_distances = [min(abs(hour_of_day - h), 24 - abs(hour_of_day - h)) 
                            for h in typical_hours]
            min_distance = min(hour_distances)
            
            if min_distance > 3:  # More than 3 hours from typical times
                anomalies.append({
                    'type': 'unusual_login_time',
                    'severity': 'medium',
                    'details': f'Login at {hour_of_day}:00, typical times: {sorted(typical_hours)}'
                })
        
        # Check new IP anomaly
        if event.source_ip not in baseline['source_ips']:
            # New IP for this user
            total_logins = sum(baseline['source_ips'].values())
            
            if total_logins > 20:  # Only flag if user has established pattern
                anomalies.append({
                    'type': 'new_source_ip',
                    'severity': 'medium',
                    'details': f'First time seeing IP {event.source_ip} for user {user_id}'
                })
        
        # Check unusual resource access
        if event.resource not in baseline['resources_accessed']:
            resource_count = len(baseline['resources_accessed'])
            
            if resource_count > 5:  # User has accessed multiple resources before
                anomalies.append({
                    'type': 'new_resource_access',
                    'severity': 'low',
                    'details': f'First time accessing {event.resource}'
                })
        
        return anomalies
    
    def detect_rate_anomalies(self, events: List[SecurityEvent], 
                            time_window: int = 300) -> List[Dict[str, Any]]:
        """Detect rate-based anomalies"""
        
        anomalies = []
        current_time = time.time()
        
        # Group events by source IP and user
        ip_events = defaultdict(list)
        user_events = defaultdict(list)
        
        for event in events:
            if current_time - event.timestamp <= time_window:
                ip_events[event.source_ip].append(event)
                if event.user_id:
                    user_events[event.user_id].append(event)
        
        # Check for high request rates from single IP
        for ip, ip_event_list in ip_events.items():
            if len(ip_event_list) > 100:  # More than 100 requests in time window
                failed_attempts = sum(1 for e in ip_event_list if not e.success)
                failure_rate = failed_attempts / len(ip_event_list)
                
                anomalies.append({
                    'type': 'high_request_rate',
                    'severity': 'high' if failure_rate > 0.5 else 'medium',
                    'details': f'IP {ip}: {len(ip_event_list)} requests in {time_window}s, {failure_rate:.1%} failed'
                })
        
        # Check for rapid-fire login attempts
        for user_id, user_event_list in user_events.items():
            login_attempts = [e for e in user_event_list if e.event_type == EventType.LOGIN_ATTEMPT]
            
            if len(login_attempts) > 10:  # More than 10 login attempts
                failed_logins = sum(1 for e in login_attempts if not e.success)
                
                if failed_logins > 5:
                    anomalies.append({
                        'type': 'brute_force_attempt',
                        'severity': 'high',
                        'details': f'User {user_id}: {failed_logins} failed logins in {time_window}s'
                    })
        
        return anomalies

class SecurityMonitor:
    """Main security monitoring system"""
    
    def __init__(self):
        self.events: deque = deque(maxlen=100000)  # Keep last 100k events
        self.alerts: List[Dict[str, Any]] = []
        self.threat_intelligence = ThreatIntelligence()
        self.anomaly_detector = AnomalyDetector()
        
        # Monitoring rules
        self.monitoring_rules = self._setup_monitoring_rules()
        
        # Statistics
        self.stats = {
            'total_events': 0,
            'alerts_generated': 0,
            'threats_blocked': 0,
            'false_positives': 0
        }
        
        # Background monitoring
        self.running = True
        self.monitor_thread = threading.Thread(target=self._monitoring_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()
    
    def _setup_monitoring_rules(self) -> List[Dict[str, Any]]:
        """Set up security monitoring rules"""
        
        return [
            {
                'name': 'Multiple Failed Logins',
                'condition': lambda events: self._check_failed_login_threshold(events),
                'severity': ThreatLevel.HIGH,
                'action': 'alert_and_block'
            },
            {
                'name': 'Privilege Escalation Attempt',
                'condition': lambda events: self._check_privilege_escalation(events),
                'severity': ThreatLevel.CRITICAL,
                'action': 'alert_and_investigate'
            },
            {
                'name': 'Suspicious Data Access Pattern',
                'condition': lambda events: self._check_data_access_pattern(events),
                'severity': ThreatLevel.MEDIUM,
                'action': 'alert'
            },
            {
                'name': 'Off-Hours Administrative Activity',
                'condition': lambda events: self._check_off_hours_admin(events),
                'severity': ThreatLevel.MEDIUM,
                'action': 'alert'
            }
        ]
    
    def ingest_event(self, event: SecurityEvent):
        """Ingest security event for monitoring"""
        
        # Add to event stream
        self.events.append(event)
        self.stats['total_events'] += 1
        
        # Update user baselines for anomaly detection
        if event.user_id:
            self.anomaly_detector.update_user_baseline(event.user_id, event)
        
        # Immediate threat analysis
        self._analyze_event(event)
        
        # Check monitoring rules
        self._check_monitoring_rules()
    
    def _analyze_event(self, event: SecurityEvent):
        """Analyze individual event for immediate threats"""
        
        alerts = []
        
        # Check IP reputation
        ip_reputation = self.threat_intelligence.check_ip_reputation(event.source_ip)
        if ip_reputation['is_malicious']:
            alerts.append({
                'type': 'malicious_ip',
                'severity': ThreatLevel.HIGH,
                'message': f"Request from malicious IP {event.source_ip}",
                'event_id': event.event_id,
                'details': ip_reputation
            })
        
        # Check for attack patterns in event details
        if 'request_data' in event.details:
            attack_patterns = self.threat_intelligence.detect_attack_patterns(
                event.details['request_data']
            )
            
            for pattern in attack_patterns:
                alerts.append({
                    'type': 'attack_pattern_detected',
                    'severity': ThreatLevel.HIGH,
                    'message': f"{pattern['attack_type']} pattern detected",
                    'event_id': event.event_id,
                    'details': pattern
                })
        
        # Check user agent
        if 'user_agent' in event.details:
            ua_analysis = self.threat_intelligence.check_user_agent(
                event.details['user_agent']
            )
            
            if ua_analysis['is_suspicious']:
                alerts.append({
                    'type': 'suspicious_user_agent',
                    'severity': ThreatLevel.MEDIUM,
                    'message': f"Suspicious user agent detected",
                    'event_id': event.event_id,
                    'details': ua_analysis
                })
        
        # Detect behavioral anomalies
        if event.user_id:
            anomalies = self.anomaly_detector.detect_user_anomalies(event.user_id, event)
            
            for anomaly in anomalies:
                alerts.append({
                    'type': 'behavioral_anomaly',
                    'severity': ThreatLevel.MEDIUM,
                    'message': f"Behavioral anomaly: {anomaly['type']}",
                    'event_id': event.event_id,
                    'details': anomaly
                })
        
        # Generate alerts
        for alert in alerts:
            self._generate_alert(alert)
    
    def _check_monitoring_rules(self):
        """Check all monitoring rules against recent events"""
        
        recent_events = list(self.events)[-1000:]  # Check last 1000 events
        
        for rule in self.monitoring_rules:
            try:
                if rule['condition'](recent_events):
                    self._generate_alert({
                        'type': 'rule_violation',
                        'severity': rule['severity'],
                        'message': f"Monitoring rule triggered: {rule['name']}",
                        'rule_name': rule['name'],
                        'action': rule['action']
                    })
            except Exception as e:
                print(f"Error checking rule {rule['name']}: {e}")
    
    def _check_failed_login_threshold(self, events: List[SecurityEvent]) -> bool:
        """Check for multiple failed login attempts"""
        
        # Look for failed login attempts in last 5 minutes
        cutoff_time = time.time() - 300
        
        failed_logins = defaultdict(int)
        
        for event in events:
            if (event.timestamp >= cutoff_time and 
                event.event_type == EventType.LOGIN_ATTEMPT and 
                not event.success):
                failed_logins[event.source_ip] += 1
        
        # Check if any IP has more than 5 failed attempts
        return any(count > 5 for count in failed_logins.values())
    
    def _check_privilege_escalation(self, events: List[SecurityEvent]) -> bool:
        """Check for privilege escalation attempts"""
        
        cutoff_time = time.time() - 600  # Last 10 minutes
        
        for event in events:
            if (event.timestamp >= cutoff_time and 
                event.event_type == EventType.PRIVILEGE_ESCALATION):
                return True
        
        return False
    
    def _check_data_access_pattern(self, events: List[SecurityEvent]) -> bool:
        """Check for suspicious data access patterns"""
        
        cutoff_time = time.time() - 3600  # Last hour
        
        user_access_counts = defaultdict(int)
        
        for event in events:
            if (event.timestamp >= cutoff_time and 
                event.event_type == EventType.DATA_ACCESS and 
                event.user_id):
                user_access_counts[event.user_id] += 1
        
        # Check if any user accessed more than 100 resources in an hour
        return any(count > 100 for count in user_access_counts.values())
    
    def _check_off_hours_admin(self, events: List[SecurityEvent]) -> bool:
        """Check for administrative activity outside business hours"""
        
        cutoff_time = time.time() - 3600  # Last hour
        
        for event in events:
            if (event.timestamp >= cutoff_time and 
                'admin' in event.details.get('user_roles', [])):
                
                # Check if outside business hours (9 AM - 6 PM)
                hour = time.localtime(event.timestamp).tm_hour
                if hour < 9 or hour > 18:
                    return True
        
        return False
    
    def _generate_alert(self, alert_data: Dict[str, Any]):
        """Generate security alert"""
        
        alert = {
            'alert_id': f"alert_{int(time.time())}_{len(self.alerts)}",
            'timestamp': time.time(),
            'severity': alert_data['severity'].name,
            'type': alert_data['type'],
            'message': alert_data['message'],
            'details': alert_data.get('details', {}),
            'status': 'open',
            'assigned_to': None,
            'resolution': None
        }
        
        self.alerts.append(alert)
        self.stats['alerts_generated'] += 1
        
        # Print high severity alerts immediately
        if alert_data['severity'] in [ThreatLevel.HIGH, ThreatLevel.CRITICAL]:
            print(f"🚨 {alert['severity']} ALERT: {alert['message']}")
    
    def _monitoring_loop(self):
        """Background monitoring loop"""
        
        while self.running:
            try:
                # Periodic analysis of events
                recent_events = list(self.events)[-5000:]  # Last 5000 events
                
                # Detect rate anomalies
                rate_anomalies = self.anomaly_detector.detect_rate_anomalies(recent_events)
                
                for anomaly in rate_anomalies:
                    self._generate_alert({
                        'type': 'rate_anomaly',
                        'severity': ThreatLevel.HIGH if anomaly['severity'] == 'high' else ThreatLevel.MEDIUM,
                        'message': f"Rate anomaly detected: {anomaly['type']}",
                        'details': anomaly
                    })
                
                time.sleep(60)  # Run every minute
                
            except Exception as e:
                print(f"Monitoring loop error: {e}")
                time.sleep(10)
    
    def get_security_dashboard(self) -> Dict[str, Any]:
        """Get security monitoring dashboard data"""
        
        current_time = time.time()
        
        # Recent events (last hour)
        recent_events = [e for e in self.events if current_time - e.timestamp <= 3600]
        
        # Recent alerts (last 24 hours)
        recent_alerts = [a for a in self.alerts if current_time - a['timestamp'] <= 86400]
        
        # Alert severity distribution
        alert_severity = defaultdict(int)
        for alert in recent_alerts:
            alert_severity[alert['severity']] += 1
        
        # Event type distribution
        event_types = defaultdict(int)
        for event in recent_events:
            event_types[event.event_type.value] += 1
        
        # Top source IPs
        source_ips = defaultdict(int)
        for event in recent_events:
            source_ips[event.source_ip] += 1
        
        top_ips = sorted(source_ips.items(), key=lambda x: x[1], reverse=True)[:10]
        
        return {
            'timestamp': current_time,
            'summary': {
                'total_events_24h': len([e for e in self.events if current_time - e.timestamp <= 86400]),
                'total_alerts_24h': len(recent_alerts),
                'open_alerts': len([a for a in recent_alerts if a['status'] == 'open']),
                'critical_alerts': alert_severity.get('CRITICAL', 0),
                'high_alerts': alert_severity.get('HIGH', 0)
            },
            'event_distribution': dict(event_types),
            'alert_distribution': dict(alert_severity),
            'top_source_ips': top_ips,
            'recent_critical_alerts': [
                a for a in recent_alerts[-10:] 
                if a['severity'] in ['CRITICAL', 'HIGH']
            ],
            'system_health': {
                'monitoring_active': self.running,
                'events_processed': self.stats['total_events'],
                'alerts_generated': self.stats['alerts_generated'],
                'threats_blocked': self.stats['threats_blocked']
            }
        }
    
    def stop_monitoring(self):
        """Stop security monitoring"""
        self.running = False

# Example usage
print("=== Security Monitoring Demo ===")

# Create security monitor
security_monitor = SecurityMonitor()

# Simulate security events
print("\n--- Simulating Security Events ---")

# Normal login
normal_event = SecurityEvent(
    event_id="event_001",
    timestamp=time.time(),
    event_type=EventType.LOGIN_ATTEMPT,
    source_ip="192.168.1.100",
    user_id="user_123",
    resource="login_page",
    action="authenticate",
    success=True,
    threat_level=ThreatLevel.LOW,
    details={"user_agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"},
    raw_log="[INFO] User login successful"
)

security_monitor.ingest_event(normal_event)

# Suspicious login from malicious IP
malicious_event = SecurityEvent(
    event_id="event_002",
    timestamp=time.time(),
    event_type=EventType.LOGIN_ATTEMPT,
    source_ip="192.168.100.1",  # Known malicious IP
    user_id="user_456",
    resource="login_page",
    action="authenticate",
    success=False,
    threat_level=ThreatLevel.HIGH,
    details={"user_agent": "sqlmap/1.0"},
    raw_log="[WARN] Failed login from suspicious IP"
)

security_monitor.ingest_event(malicious_event)

# SQL injection attempt
injection_event = SecurityEvent(
    event_id="event_003",
    timestamp=time.time(),
    event_type=EventType.SUSPICIOUS_ACTIVITY,
    source_ip="192.168.1.200",
    user_id=None,
    resource="api/users",
    action="query",
    success=False,
    threat_level=ThreatLevel.HIGH,
    details={"request_data": "SELECT * FROM users UNION SELECT password FROM admin"},
    raw_log="[ERROR] SQL injection attempt blocked"
)

security_monitor.ingest_event(injection_event)

# Multiple failed login attempts (brute force simulation)
for i in range(8):
    brute_force_event = SecurityEvent(
        event_id=f"event_bf_{i}",
        timestamp=time.time(),
        event_type=EventType.LOGIN_ATTEMPT,
        source_ip="192.168.1.150",
        user_id="admin",
        resource="login_page",
        action="authenticate",
        success=False,
        threat_level=ThreatLevel.MEDIUM,
        details={"user_agent": "Python requests"},
        raw_log=f"[WARN] Failed login attempt #{i+1}"
    )
    
    security_monitor.ingest_event(brute_force_event)

# Wait for processing
time.sleep(2)

# Get security dashboard
print("\n--- Security Dashboard ---")
dashboard = security_monitor.get_security_dashboard()

print(f"Events (24h): {dashboard['summary']['total_events_24h']}")
print(f"Alerts (24h): {dashboard['summary']['total_alerts_24h']}")
print(f"Critical alerts: {dashboard['summary']['critical_alerts']}")
print(f"High alerts: {dashboard['summary']['high_alerts']}")

print("\nEvent distribution:")
for event_type, count in dashboard['event_distribution'].items():
    print(f"  {event_type}: {count}")

print("\nTop source IPs:")
for ip, count in dashboard['top_source_ips']:
    print(f"  {ip}: {count} events")

print("\nRecent critical alerts:")
for alert in dashboard['recent_critical_alerts']:
    print(f"  {alert['severity']}: {alert['message']}")

# Stop monitoring
security_monitor.stop_monitoring()

print("\n--- Security Monitoring Demo Completed ---")
```

## 📚 Conclusion

Security monitoring is the vigilant guardian of modern digital infrastructure, providing continuous oversight and rapid response capabilities. From threat intelligence and anomaly detection to comprehensive SIEM systems, effective security monitoring requires a multi-layered approach that combines automated detection with human expertise.

**Key Takeaways:**

1. **Continuous Vigilance**: Security monitoring must operate 24/7 with automated detection
2. **Behavioral Analysis**: Detect anomalies by understanding normal behavior patterns  
3. **Threat Intelligence**: Leverage external threat feeds and reputation services
4. **Rapid Response**: Minimize time between detection and response
5. **Comprehensive Logging**: Collect and analyze logs from all system components

The future includes AI-powered threat hunting, quantum-safe security measures, and zero-trust monitoring architectures. Whether protecting small applications or enterprise infrastructure, robust security monitoring is essential for maintaining trust and protecting valuable assets.

Remember: security monitoring is not just about detecting attacks—it's about building a comprehensive security posture that enables rapid detection, response, and recovery from security incidents.
