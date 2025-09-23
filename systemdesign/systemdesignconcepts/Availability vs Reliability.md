# Availability vs Reliability: Understanding System Quality Metrics

## 🎯 What are Availability and Reliability?

Availability and reliability are like the difference between a store being open versus a store providing good service. Availability is whether the store is open when you need it (uptime), while reliability is whether the store consistently provides what you expect when it's open (correctness and consistency of service).

## 🏗️ Core Concepts

### The Store Analogy Extended
- **Availability**: Store hours - is it open when customers need it?
- **Reliability**: Service quality - does it consistently provide correct products and service?
- **Uptime**: Percentage of time the store is actually open
- **MTBF**: Mean time between the store having problems
- **MTTR**: Mean time to fix problems when they occur

### Why These Metrics Matter
1. **User Experience**: Users need systems that are both accessible and dependable
2. **Business Impact**: Downtime and errors directly affect revenue
3. **SLA Compliance**: Service agreements specify both availability and reliability targets
4. **System Design**: Different approaches optimize for different metrics
5. **Resource Planning**: Understanding failure patterns helps with capacity planning

## 📊 Understanding Availability

### What is Availability?
Availability is the percentage of time a system is operational and accessible when required.

```python
import time
import statistics
from datetime import datetime, timedelta

class AvailabilityTracker:
    def __init__(self):
        self.uptime_records = []
        self.downtime_events = []
        self.monitoring_start = time.time()
        self.current_status = 'up'
        self.last_status_change = time.time()
    
    def record_downtime_start(self, reason="Unknown"):
        """Record when system goes down"""
        if self.current_status == 'up':
            uptime_duration = time.time() - self.last_status_change
            self.uptime_records.append(uptime_duration)
            
            self.current_status = 'down'
            self.last_status_change = time.time()
            
            downtime_event = {
                'start_time': time.time(),
                'reason': reason,
                'end_time': None,
                'duration': None
            }
            self.downtime_events.append(downtime_event)
            
            print(f"System DOWN: {reason}")
    
    def record_downtime_end(self, resolution="Fixed"):
        """Record when system comes back up"""
        if self.current_status == 'down':
            downtime_duration = time.time() - self.last_status_change
            
            # Update the last downtime event
            if self.downtime_events:
                last_event = self.downtime_events[-1]
                last_event['end_time'] = time.time()
                last_event['duration'] = downtime_duration
                last_event['resolution'] = resolution
            
            self.current_status = 'up'
            self.last_status_change = time.time()
            
            print(f"System UP: {resolution} (downtime: {downtime_duration:.2f}s)")
    
    def calculate_availability(self, time_period_hours=24):
        """Calculate availability percentage over time period"""
        current_time = time.time()
        period_start = current_time - (time_period_hours * 3600)
        
        # Get downtime events within the period
        period_downtime = 0
        for event in self.downtime_events:
            if event['end_time'] is None:
                continue  # Skip ongoing downtime
            
            event_start = max(event['start_time'], period_start)
            event_end = min(event['end_time'], current_time)
            
            if event_start < event_end:
                period_downtime += (event_end - event_start)
        
        # Handle ongoing downtime
        if self.current_status == 'down':
            ongoing_downtime_start = max(self.last_status_change, period_start)
            if ongoing_downtime_start < current_time:
                period_downtime += (current_time - ongoing_downtime_start)
        
        total_period = time_period_hours * 3600
        uptime = total_period - period_downtime
        availability_percentage = (uptime / total_period) * 100
        
        return {
            'availability_percentage': availability_percentage,
            'uptime_seconds': uptime,
            'downtime_seconds': period_downtime,
            'total_period_seconds': total_period,
            'period_hours': time_period_hours
        }
    
    def get_availability_stats(self):
        """Get comprehensive availability statistics"""
        if not self.downtime_events:
            return {
                'overall_availability': 100.0,
                'mtbf_hours': float('inf'),
                'mttr_minutes': 0,
                'downtime_events': 0
            }
        
        # Calculate MTBF (Mean Time Between Failures)
        total_monitoring_time = time.time() - self.monitoring_start
        completed_downtime_events = [e for e in self.downtime_events if e['end_time'] is not None]
        
        if completed_downtime_events:
            mtbf_seconds = total_monitoring_time / len(completed_downtime_events)
            mtbf_hours = mtbf_seconds / 3600
            
            # Calculate MTTR (Mean Time To Recovery)
            recovery_times = [e['duration'] for e in completed_downtime_events]
            mttr_seconds = statistics.mean(recovery_times)
            mttr_minutes = mttr_seconds / 60
        else:
            mtbf_hours = float('inf')
            mttr_minutes = 0
        
        # Calculate overall availability
        total_downtime = sum(e.get('duration', 0) for e in completed_downtime_events)
        overall_availability = ((total_monitoring_time - total_downtime) / total_monitoring_time) * 100
        
        return {
            'overall_availability': overall_availability,
            'mtbf_hours': mtbf_hours,
            'mttr_minutes': mttr_minutes,
            'downtime_events': len(self.downtime_events),
            'total_downtime_minutes': total_downtime / 60,
            'monitoring_duration_hours': total_monitoring_time / 3600
        }

# Example usage
availability_tracker = AvailabilityTracker()

# Simulate some downtime events
time.sleep(1)
availability_tracker.record_downtime_start("Database connection timeout")
time.sleep(2)  # 2 seconds of downtime
availability_tracker.record_downtime_end("Database connection restored")

# Get availability statistics
stats = availability_tracker.get_availability_stats()
print(f"System Availability: {stats['overall_availability']:.3f}%")
print(f"MTBF: {stats['mtbf_hours']:.2f} hours")
print(f"MTTR: {stats['mttr_minutes']:.2f} minutes")
```

### Availability Levels and SLAs

```python
class AvailabilitySLA:
    def __init__(self):
        self.sla_levels = {
            '99.9%': {
                'name': 'Three Nines',
                'annual_downtime': '8.77 hours',
                'monthly_downtime': '43.83 minutes',
                'weekly_downtime': '10.08 minutes',
                'daily_downtime': '1.44 minutes',
                'use_cases': ['Standard web applications', 'Internal tools']
            },
            '99.95%': {
                'name': 'Three Nines Five',
                'annual_downtime': '4.38 hours',
                'monthly_downtime': '21.91 minutes',
                'weekly_downtime': '5.04 minutes',
                'daily_downtime': '43.2 seconds',
                'use_cases': ['E-commerce platforms', 'Business applications']
            },
            '99.99%': {
                'name': 'Four Nines',
                'annual_downtime': '52.60 minutes',
                'monthly_downtime': '4.38 minutes',
                'weekly_downtime': '1.01 minutes',
                'daily_downtime': '8.64 seconds',
                'use_cases': ['Financial services', 'Healthcare systems']
            },
            '99.999%': {
                'name': 'Five Nines',
                'annual_downtime': '5.26 minutes',
                'monthly_downtime': '26.3 seconds',
                'weekly_downtime': '6.05 seconds',
                'daily_downtime': '0.864 seconds',
                'use_cases': ['Critical infrastructure', 'Emergency services']
            }
        }
    
    def calculate_allowed_downtime(self, availability_percentage, time_period_days=365):
        """Calculate allowed downtime for given availability target"""
        uptime_percentage = availability_percentage / 100
        downtime_percentage = 1 - uptime_percentage
        
        total_seconds = time_period_days * 24 * 3600
        allowed_downtime_seconds = total_seconds * downtime_percentage
        
        return {
            'availability_target': f"{availability_percentage}%",
            'time_period_days': time_period_days,
            'allowed_downtime_seconds': allowed_downtime_seconds,
            'allowed_downtime_minutes': allowed_downtime_seconds / 60,
            'allowed_downtime_hours': allowed_downtime_seconds / 3600,
            'allowed_downtime_days': allowed_downtime_seconds / (24 * 3600)
        }
    
    def assess_sla_compliance(self, actual_availability, target_availability):
        """Assess whether actual availability meets SLA target"""
        compliance = actual_availability >= target_availability
        
        if compliance:
            buffer = actual_availability - target_availability
            status = "COMPLIANT"
        else:
            deficit = target_availability - actual_availability
            status = "NON-COMPLIANT"
            buffer = -deficit
        
        return {
            'status': status,
            'actual_availability': actual_availability,
            'target_availability': target_availability,
            'buffer_or_deficit': buffer,
            'compliant': compliance
        }

# Example SLA calculations
sla_calculator = AvailabilitySLA()

# Calculate allowed downtime for 99.9% availability
downtime_calc = sla_calculator.calculate_allowed_downtime(99.9, 30)  # 30 days
print(f"99.9% availability allows {downtime_calc['allowed_downtime_minutes']:.2f} minutes downtime per month")

# Assess compliance
compliance = sla_calculator.assess_sla_compliance(actual_availability=99.85, target_availability=99.9)
print(f"SLA Status: {compliance['status']}")
```

## 🔧 Understanding Reliability

### What is Reliability?
Reliability is the probability that a system will perform correctly during a specific time duration under specified conditions.

```python
class ReliabilityTracker:
    def __init__(self):
        self.request_log = []
        self.error_log = []
        self.performance_log = []
    
    def record_request(self, request_id, success=True, response_time_ms=None, error_type=None):
        """Record a request and its outcome"""
        timestamp = time.time()
        
        request_record = {
            'request_id': request_id,
            'timestamp': timestamp,
            'success': success,
            'response_time_ms': response_time_ms,
            'error_type': error_type
        }
        
        self.request_log.append(request_record)
        
        if not success:
            error_record = {
                'request_id': request_id,
                'timestamp': timestamp,
                'error_type': error_type,
                'response_time_ms': response_time_ms
            }
            self.error_log.append(error_record)
        
        if response_time_ms is not None:
            self.performance_log.append({
                'timestamp': timestamp,
                'response_time_ms': response_time_ms,
                'success': success
            })
    
    def calculate_reliability_metrics(self, time_window_hours=24):
        """Calculate various reliability metrics"""
        current_time = time.time()
        window_start = current_time - (time_window_hours * 3600)
        
        # Filter requests within time window
        window_requests = [r for r in self.request_log if r['timestamp'] >= window_start]
        window_errors = [e for e in self.error_log if e['timestamp'] >= window_start]
        
        if not window_requests:
            return None
        
        total_requests = len(window_requests)
        successful_requests = len([r for r in window_requests if r['success']])
        failed_requests = len(window_errors)
        
        # Basic reliability metrics
        success_rate = (successful_requests / total_requests) * 100
        error_rate = (failed_requests / total_requests) * 100
        
        # Error categorization
        error_types = {}
        for error in window_errors:
            error_type = error.get('error_type', 'Unknown')
            error_types[error_type] = error_types.get(error_type, 0) + 1
        
        # Performance reliability (requests meeting SLA)
        performance_requests = [r for r in window_requests if r['response_time_ms'] is not None]
        sla_threshold_ms = 1000  # 1 second SLA
        
        if performance_requests:
            sla_compliant_requests = [r for r in performance_requests 
                                    if r['response_time_ms'] <= sla_threshold_ms]
            performance_reliability = (len(sla_compliant_requests) / len(performance_requests)) * 100
        else:
            performance_reliability = None
        
        return {
            'time_window_hours': time_window_hours,
            'total_requests': total_requests,
            'successful_requests': successful_requests,
            'failed_requests': failed_requests,
            'success_rate': success_rate,
            'error_rate': error_rate,
            'error_types': error_types,
            'performance_reliability': performance_reliability,
            'sla_threshold_ms': sla_threshold_ms
        }
    
    def calculate_mtbf_mttr(self):
        """Calculate Mean Time Between Failures and Mean Time To Recovery"""
        if not self.error_log:
            return {
                'mtbf_hours': float('inf'),
                'mttr_minutes': 0,
                'failure_count': 0
            }
        
        # Group consecutive errors as single failure incidents
        incidents = []
        current_incident = None
        
        for error in sorted(self.error_log, key=lambda x: x['timestamp']):
            if current_incident is None:
                current_incident = {
                    'start_time': error['timestamp'],
                    'errors': [error]
                }
            else:
                # If error is within 5 minutes of previous, consider it same incident
                if error['timestamp'] - current_incident['errors'][-1]['timestamp'] <= 300:
                    current_incident['errors'].append(error)
                else:
                    # New incident
                    incidents.append(current_incident)
                    current_incident = {
                        'start_time': error['timestamp'],
                        'errors': [error]
                    }
        
        if current_incident:
            incidents.append(current_incident)
        
        # Calculate MTBF
        if len(incidents) > 1:
            total_time = self.request_log[-1]['timestamp'] - self.request_log[0]['timestamp']
            mtbf_seconds = total_time / len(incidents)
            mtbf_hours = mtbf_seconds / 3600
        else:
            mtbf_hours = float('inf')
        
        # Calculate MTTR (assuming each incident lasts until first successful request after)
        mttr_times = []
        for incident in incidents:
            incident_start = incident['start_time']
            
            # Find first successful request after incident start
            recovery_request = None
            for request in sorted(self.request_log, key=lambda x: x['timestamp']):
                if request['timestamp'] > incident_start and request['success']:
                    recovery_request = request
                    break
            
            if recovery_request:
                recovery_time = recovery_request['timestamp'] - incident_start
                mttr_times.append(recovery_time)
        
        if mttr_times:
            mttr_seconds = statistics.mean(mttr_times)
            mttr_minutes = mttr_seconds / 60
        else:
            mttr_minutes = 0
        
        return {
            'mtbf_hours': mtbf_hours,
            'mttr_minutes': mttr_minutes,
            'failure_count': len(incidents),
            'incidents': incidents
        }

# Example usage
reliability_tracker = ReliabilityTracker()

# Simulate various requests
import random

for i in range(1000):
    success = random.random() > 0.05  # 95% success rate
    response_time = random.gauss(500, 200)  # 500ms average, 200ms std dev
    error_type = None if success else random.choice(['timeout', 'server_error', 'bad_request'])
    
    reliability_tracker.record_request(
        request_id=f"req_{i}",
        success=success,
        response_time_ms=max(0, response_time),
        error_type=error_type
    )

# Calculate reliability metrics
reliability_metrics = reliability_tracker.calculate_reliability_metrics()
mtbf_mttr = reliability_tracker.calculate_mtbf_mttr()

print(f"Success Rate: {reliability_metrics['success_rate']:.2f}%")
print(f"Error Rate: {reliability_metrics['error_rate']:.2f}%")
print(f"Performance Reliability: {reliability_metrics['performance_reliability']:.2f}%")
print(f"MTBF: {mtbf_mttr['mtbf_hours']:.2f} hours")
print(f"MTTR: {mtbf_mttr['mttr_minutes']:.2f} minutes")
```

### Types of Reliability

```python
class ReliabilityTypes:
    def __init__(self):
        self.reliability_aspects = {
            'functional_reliability': {
                'description': 'System produces correct outputs for given inputs',
                'metrics': ['Success rate', 'Error rate', 'Data accuracy'],
                'measurement_methods': [
                    'Automated testing',
                    'Input/output validation',
                    'Business logic verification'
                ],
                'example': 'Banking system correctly processes 99.99% of transactions'
            },
            'performance_reliability': {
                'description': 'System consistently meets performance requirements',
                'metrics': ['Response time consistency', 'SLA compliance', 'Throughput stability'],
                'measurement_methods': [
                    'Response time monitoring',
                    'Load testing',
                    'Performance benchmarking'
                ],
                'example': 'API responds within 100ms for 95% of requests'
            },
            'availability_reliability': {
                'description': 'System is accessible when needed',
                'metrics': ['Uptime percentage', 'MTBF', 'MTTR'],
                'measurement_methods': [
                    'Health checks',
                    'Uptime monitoring',
                    'Incident tracking'
                ],
                'example': 'Service maintains 99.9% uptime'
            },
            'data_reliability': {
                'description': 'Data remains accurate, consistent, and uncorrupted',
                'metrics': ['Data integrity', 'Consistency checks', 'Backup success rate'],
                'measurement_methods': [
                    'Checksums',
                    'Data validation',
                    'Backup verification'
                ],
                'example': 'Database maintains ACID properties for all transactions'
            }
        }
    
    def assess_system_reliability(self, system_metrics):
        """Assess overall system reliability across different aspects"""
        
        assessment = {}
        overall_score = 0
        aspects_count = 0
        
        for aspect, definition in self.reliability_aspects.items():
            if aspect in system_metrics:
                metrics = system_metrics[aspect]
                score = self.calculate_aspect_score(aspect, metrics)
                
                assessment[aspect] = {
                    'score': score,
                    'metrics': metrics,
                    'status': self.get_status_from_score(score)
                }
                
                overall_score += score
                aspects_count += 1
        
        if aspects_count > 0:
            assessment['overall_reliability_score'] = overall_score / aspects_count
            assessment['overall_status'] = self.get_status_from_score(assessment['overall_reliability_score'])
        
        return assessment
    
    def calculate_aspect_score(self, aspect, metrics):
        """Calculate reliability score for specific aspect"""
        
        if aspect == 'functional_reliability':
            success_rate = metrics.get('success_rate', 0)
            return success_rate
        
        elif aspect == 'performance_reliability':
            sla_compliance = metrics.get('sla_compliance', 0)
            return sla_compliance
        
        elif aspect == 'availability_reliability':
            uptime_percentage = metrics.get('uptime_percentage', 0)
            return uptime_percentage
        
        elif aspect == 'data_reliability':
            data_integrity = metrics.get('data_integrity', 0)
            return data_integrity
        
        return 0
    
    def get_status_from_score(self, score):
        """Convert numerical score to status"""
        if score >= 99.9:
            return 'Excellent'
        elif score >= 99.5:
            return 'Good'
        elif score >= 99.0:
            return 'Acceptable'
        elif score >= 95.0:
            return 'Poor'
        else:
            return 'Critical'
```

## ⚖️ Availability vs Reliability Trade-offs

### Understanding the Relationship

```python
class AvailabilityReliabilityRelationship:
    def __init__(self):
        self.relationship_patterns = {
            'high_availability_low_reliability': {
                'description': 'System is always accessible but often produces incorrect results',
                'examples': [
                    'Web server returns cached stale data to stay responsive',
                    'Database serves reads during inconsistent state',
                    'Load balancer routes to unhealthy servers to maintain uptime'
                ],
                'business_impact': 'Users can access system but may receive wrong information',
                'mitigation_strategies': [
                    'Implement circuit breakers',
                    'Add data validation layers',
                    'Improve health checks'
                ]
            },
            'low_availability_high_reliability': {
                'description': 'System produces correct results when accessible but is often down',
                'examples': [
                    'System goes offline for maintenance frequently',
                    'Conservative failover that shuts down on any error',
                    'Batch processing system with long downtimes'
                ],
                'business_impact': 'Users trust the system when it works but frustrated by downtime',
                'mitigation_strategies': [
                    'Implement redundancy',
                    'Reduce maintenance windows',
                    'Add graceful degradation'
                ]
            },
            'high_availability_high_reliability': {
                'description': 'System is both accessible and produces correct results',
                'examples': [
                    'Well-designed distributed systems with consensus',
                    'Multi-region deployments with data consistency',
                    'Fault-tolerant systems with comprehensive monitoring'
                ],
                'business_impact': 'Optimal user experience and business outcomes',
                'challenges': [
                    'Complex architecture',
                    'Higher costs',
                    'Difficult to achieve and maintain'
                ]
            },
            'low_availability_low_reliability': {
                'description': 'System is often inaccessible and produces incorrect results',
                'examples': [
                    'Poorly maintained legacy systems',
                    'Under-resourced infrastructure',
                    'Systems without proper monitoring or testing'
                ],
                'business_impact': 'Severe negative impact on users and business',
                'urgent_actions': [
                    'Immediate system overhaul',
                    'Emergency monitoring implementation',
                    'Resource allocation increase'
                ]
            }
        }
    
    def analyze_system_characteristics(self, availability_percent, reliability_percent):
        """Analyze system based on availability and reliability percentages"""
        
        # Classify into quadrants
        high_availability = availability_percent >= 99.0
        high_reliability = reliability_percent >= 99.0
        
        if high_availability and high_reliability:
            category = 'high_availability_high_reliability'
        elif high_availability and not high_reliability:
            category = 'high_availability_low_reliability'
        elif not high_availability and high_reliability:
            category = 'low_availability_high_reliability'
        else:
            category = 'low_availability_low_reliability'
        
        pattern_info = self.relationship_patterns[category]
        
        return {
            'category': category,
            'availability_percent': availability_percent,
            'reliability_percent': reliability_percent,
            'pattern_description': pattern_info['description'],
            'business_impact': pattern_info['business_impact'],
            'recommendations': pattern_info.get('mitigation_strategies', 
                                              pattern_info.get('urgent_actions', []))
        }
    
    def calculate_system_effectiveness(self, availability_percent, reliability_percent):
        """Calculate overall system effectiveness"""
        
        # System effectiveness is the product of availability and reliability
        # This represents the probability that the system is both accessible AND correct
        availability_decimal = availability_percent / 100
        reliability_decimal = reliability_percent / 100
        
        effectiveness = availability_decimal * reliability_decimal * 100
        
        return {
            'availability_percent': availability_percent,
            'reliability_percent': reliability_percent,
            'system_effectiveness_percent': effectiveness,
            'interpretation': self.interpret_effectiveness(effectiveness)
        }
    
    def interpret_effectiveness(self, effectiveness):
        """Interpret system effectiveness score"""
        if effectiveness >= 99.0:
            return "Excellent - System provides reliable service when needed"
        elif effectiveness >= 95.0:
            return "Good - System generally provides reliable service"
        elif effectiveness >= 90.0:
            return "Acceptable - System has room for improvement"
        elif effectiveness >= 80.0:
            return "Poor - System reliability or availability needs attention"
        else:
            return "Critical - System requires immediate improvement"

# Example analysis
analyzer = AvailabilityReliabilityRelationship()

# Analyze different system scenarios
scenarios = [
    {'name': 'Production System A', 'availability': 99.9, 'reliability': 99.8},
    {'name': 'Legacy System B', 'availability': 95.0, 'reliability': 98.0},
    {'name': 'New System C', 'availability': 99.5, 'reliability': 96.0},
    {'name': 'Critical System D', 'availability': 85.0, 'reliability': 85.0}
]

for scenario in scenarios:
    analysis = analyzer.analyze_system_characteristics(
        scenario['availability'], 
        scenario['reliability']
    )
    effectiveness = analyzer.calculate_system_effectiveness(
        scenario['availability'], 
        scenario['reliability']
    )
    
    print(f"\n{scenario['name']}:")
    print(f"  Category: {analysis['category']}")
    print(f"  Effectiveness: {effectiveness['system_effectiveness_percent']:.1f}%")
    print(f"  Status: {effectiveness['interpretation']}")
```

## 🏗️ Designing for High Availability and Reliability

### Architectural Patterns

```python
class HighAvailabilityPatterns:
    def __init__(self):
        self.patterns = {
            'redundancy': {
                'description': 'Multiple instances of critical components',
                'types': {
                    'active_active': 'All instances handle traffic simultaneously',
                    'active_passive': 'Primary instance handles traffic, others standby',
                    'n_plus_one': 'N instances handle normal load, +1 for failover'
                },
                'implementation_example': self.implement_redundancy,
                'availability_impact': 'High - eliminates single points of failure',
                'reliability_impact': 'Medium - depends on consensus mechanisms'
            },
            'geographic_distribution': {
                'description': 'Deploy across multiple geographic regions',
                'benefits': [
                    'Disaster recovery',
                    'Reduced latency',
                    'Regulatory compliance'
                ],
                'implementation_example': self.implement_geo_distribution,
                'availability_impact': 'Very High - survives regional outages',
                'reliability_impact': 'Medium - network partitions can cause issues'
            },
            'circuit_breakers': {
                'description': 'Prevent cascade failures by isolating failing components',
                'states': ['Closed', 'Open', 'Half-Open'],
                'implementation_example': self.implement_circuit_breaker,
                'availability_impact': 'High - prevents system-wide failures',
                'reliability_impact': 'High - maintains service quality during issues'
            },
            'graceful_degradation': {
                'description': 'Reduce functionality rather than complete failure',
                'strategies': [
                    'Disable non-essential features',
                    'Serve cached content',
                    'Use simplified algorithms'
                ],
                'implementation_example': self.implement_graceful_degradation,
                'availability_impact': 'High - keeps core functionality available',
                'reliability_impact': 'Medium - reduced functionality may affect user experience'
            }
        }
    
    def implement_redundancy(self):
        """Example redundancy implementation"""
        return """
        class RedundantService:
            def __init__(self):
                self.primary_instances = [
                    ServiceInstance('primary-1'),
                    ServiceInstance('primary-2'),
                    ServiceInstance('primary-3')
                ]
                self.backup_instances = [
                    ServiceInstance('backup-1'),
                    ServiceInstance('backup-2')
                ]
                self.health_checker = HealthChecker()
            
            def handle_request(self, request):
                # Try primary instances first
                healthy_primaries = self.health_checker.get_healthy_instances(
                    self.primary_instances
                )
                
                if healthy_primaries:
                    return self.load_balance(healthy_primaries, request)
                
                # Fallback to backup instances
                healthy_backups = self.health_checker.get_healthy_instances(
                    self.backup_instances
                )
                
                if healthy_backups:
                    return self.load_balance(healthy_backups, request)
                
                raise ServiceUnavailableException("All instances unhealthy")
        """
    
    def implement_circuit_breaker(self):
        """Example circuit breaker implementation"""
        return """
        class CircuitBreaker:
            def __init__(self, failure_threshold=5, recovery_timeout=60):
                self.failure_threshold = failure_threshold
                self.recovery_timeout = recovery_timeout
                self.failure_count = 0
                self.last_failure_time = None
                self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN
            
            def call(self, func, *args, **kwargs):
                if self.state == 'OPEN':
                    if time.time() - self.last_failure_time > self.recovery_timeout:
                        self.state = 'HALF_OPEN'
                    else:
                        raise CircuitBreakerOpenException("Circuit breaker is open")
                
                try:
                    result = func(*args, **kwargs)
                    self.on_success()
                    return result
                except Exception as e:
                    self.on_failure()
                    raise e
            
            def on_success(self):
                self.failure_count = 0
                self.state = 'CLOSED'
            
            def on_failure(self):
                self.failure_count += 1
                self.last_failure_time = time.time()
                
                if self.failure_count >= self.failure_threshold:
                    self.state = 'OPEN'
        """

class HighReliabilityPatterns:
    def __init__(self):
        self.patterns = {
            'input_validation': {
                'description': 'Validate all inputs to prevent errors',
                'layers': ['Client-side', 'API Gateway', 'Service Layer', 'Database'],
                'implementation_example': self.implement_input_validation,
                'reliability_impact': 'High - prevents invalid data processing'
            },
            'idempotency': {
                'description': 'Operations can be safely retried',
                'techniques': ['Unique request IDs', 'Natural idempotency', 'State checks'],
                'implementation_example': self.implement_idempotency,
                'reliability_impact': 'High - enables safe retries'
            },
            'transactional_integrity': {
                'description': 'Ensure data consistency across operations',
                'mechanisms': ['ACID transactions', 'Saga pattern', '2PC'],
                'implementation_example': self.implement_transactions,
                'reliability_impact': 'Very High - maintains data consistency'
            },
            'comprehensive_monitoring': {
                'description': 'Monitor all aspects of system health',
                'metrics': ['Business metrics', 'Technical metrics', 'User experience'],
                'implementation_example': self.implement_monitoring,
                'reliability_impact': 'High - enables proactive issue detection'
            }
        }
    
    def implement_input_validation(self):
        """Example input validation implementation"""
        return """
        class InputValidator:
            def __init__(self):
                self.validation_rules = {
                    'email': r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    'phone': r'^\+?1?[0-9]{10,15}$',
                    'uuid': r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
                }
            
            def validate_request(self, request_data, schema):
                errors = []
                
                for field, rules in schema.items():
                    value = request_data.get(field)
                    
                    # Required field check
                    if rules.get('required') and not value:
                        errors.append(f"{field} is required")
                        continue
                    
                    # Type validation
                    expected_type = rules.get('type')
                    if expected_type and not isinstance(value, expected_type):
                        errors.append(f"{field} must be of type {expected_type.__name__}")
                    
                    # Pattern validation
                    pattern = rules.get('pattern')
                    if pattern and not re.match(pattern, str(value)):
                        errors.append(f"{field} format is invalid")
                
                return errors
        """
```

## 📊 Monitoring and Measurement

### Comprehensive Monitoring System

```python
class SystemMonitor:
    def __init__(self):
        self.availability_tracker = AvailabilityTracker()
        self.reliability_tracker = ReliabilityTracker()
        self.alert_thresholds = {
            'availability_threshold': 99.9,
            'error_rate_threshold': 1.0,  # 1%
            'response_time_threshold': 1000,  # 1 second
            'mttr_threshold': 30  # 30 minutes
        }
        self.dashboards = {}
    
    def collect_system_metrics(self):
        """Collect comprehensive system metrics"""
        current_time = time.time()
        
        # Availability metrics
        availability_stats = self.availability_tracker.get_availability_stats()
        
        # Reliability metrics
        reliability_stats = self.reliability_tracker.calculate_reliability_metrics()
        mtbf_mttr = self.reliability_tracker.calculate_mtbf_mttr()
        
        # System resource metrics
        system_metrics = self.get_system_resource_metrics()
        
        # Business metrics
        business_metrics = self.get_business_metrics()
        
        comprehensive_metrics = {
            'timestamp': current_time,
            'availability': availability_stats,
            'reliability': reliability_stats,
            'mtbf_mttr': mtbf_mttr,
            'system_resources': system_metrics,
            'business_metrics': business_metrics
        }
        
        # Check for alerts
        self.check_and_send_alerts(comprehensive_metrics)
        
        return comprehensive_metrics
    
    def get_system_resource_metrics(self):
        """Get system resource utilization metrics"""
        # In a real implementation, this would collect actual system metrics
        return {
            'cpu_usage_percent': 65.5,
            'memory_usage_percent': 78.2,
            'disk_usage_percent': 45.8,
            'network_io_mbps': 125.3,
            'active_connections': 1247,
            'thread_pool_utilization': 0.82
        }
    
    def get_business_metrics(self):
        """Get business-level metrics"""
        return {
            'transactions_per_minute': 1250,
            'revenue_per_hour': 15750.50,
            'user_satisfaction_score': 4.2,
            'conversion_rate': 0.034,
            'customer_support_tickets': 23
        }
    
    def check_and_send_alerts(self, metrics):
        """Check metrics against thresholds and send alerts"""
        alerts = []
        
        # Availability alerts
        if metrics['availability']:
            availability = metrics['availability']['overall_availability']
            if availability < self.alert_thresholds['availability_threshold']:
                alerts.append({
                    'type': 'availability',
                    'severity': 'critical',
                    'message': f"Availability {availability:.2f}% below threshold {self.alert_thresholds['availability_threshold']}%"
                })
        
        # Reliability alerts
        if metrics['reliability']:
            error_rate = metrics['reliability']['error_rate']
            if error_rate > self.alert_thresholds['error_rate_threshold']:
                alerts.append({
                    'type': 'reliability',
                    'severity': 'warning',
                    'message': f"Error rate {error_rate:.2f}% above threshold {self.alert_thresholds['error_rate_threshold']}%"
                })
        
        # MTTR alerts
        if metrics['mtbf_mttr']:
            mttr = metrics['mtbf_mttr']['mttr_minutes']
            if mttr > self.alert_thresholds['mttr_threshold']:
                alerts.append({
                    'type': 'mttr',
                    'severity': 'warning',
                    'message': f"MTTR {mttr:.1f} minutes above threshold {self.alert_thresholds['mttr_threshold']} minutes"
                })
        
        # Send alerts
        for alert in alerts:
            self.send_alert(alert)
    
    def send_alert(self, alert):
        """Send alert to appropriate channels"""
        print(f"ALERT [{alert['severity'].upper()}] {alert['type']}: {alert['message']}")
        
        # In real implementation, would send to:
        # - PagerDuty
        # - Slack
        # - Email
        # - SMS for critical alerts
    
    def generate_sla_report(self, time_period_days=30):
        """Generate SLA compliance report"""
        
        availability_metrics = self.availability_tracker.calculate_availability(time_period_days * 24)
        reliability_metrics = self.reliability_tracker.calculate_reliability_metrics(time_period_days * 24)
        
        # Calculate SLA compliance
        sla_calculator = AvailabilitySLA()
        
        availability_compliance = sla_calculator.assess_sla_compliance(
            availability_metrics['availability_percentage'],
            99.9  # Target SLA
        )
        
        report = {
            'report_period_days': time_period_days,
            'availability_sla': availability_compliance,
            'reliability_metrics': reliability_metrics,
            'sla_summary': {
                'availability_target': '99.9%',
                'availability_actual': f"{availability_metrics['availability_percentage']:.3f}%",
                'reliability_actual': f"{reliability_metrics['success_rate']:.3f}%" if reliability_metrics else 'N/A',
                'overall_status': availability_compliance['status']
            },
            'recommendations': self.generate_sla_recommendations(availability_compliance, reliability_metrics)
        }
        
        return report
    
    def generate_sla_recommendations(self, availability_compliance, reliability_metrics):
        """Generate recommendations based on SLA performance"""
        
        recommendations = []
        
        if not availability_compliance['compliant']:
            recommendations.append({
                'area': 'Availability',
                'priority': 'High',
                'recommendation': 'Implement additional redundancy and improve MTTR',
                'actions': [
                    'Add more server instances',
                    'Implement automated failover',
                    'Improve monitoring and alerting',
                    'Conduct failure mode analysis'
                ]
            })
        
        if reliability_metrics and reliability_metrics['error_rate'] > 1.0:
            recommendations.append({
                'area': 'Reliability',
                'priority': 'Medium',
                'recommendation': 'Reduce error rate through better input validation and testing',
                'actions': [
                    'Implement comprehensive input validation',
                    'Increase test coverage',
                    'Add more detailed error handling',
                    'Implement circuit breakers'
                ]
            })
        
        return recommendations
```

## 🌍 Real-World Examples

### 1. Netflix: Chaos Engineering for Reliability
```python
class NetflixChaosEngineering:
    """Netflix's approach to building reliable systems through controlled failure"""
    
    def __init__(self):
        self.chaos_tools = {
            'chaos_monkey': 'Randomly terminates instances',
            'chaos_gorilla': 'Simulates entire availability zone failures',
            'chaos_kong': 'Simulates entire region failures',
            'latency_monkey': 'Introduces artificial delays',
            'conformity_monkey': 'Finds instances not following best practices'
        }
    
    def run_chaos_experiment(self, experiment_type, target_service):
        """Run controlled chaos experiment"""
        
        print(f"Starting chaos experiment: {experiment_type} on {target_service}")
        
        # Establish baseline metrics
        baseline_metrics = self.collect_baseline_metrics(target_service)
        
        # Run experiment
        if experiment_type == 'instance_failure':
            self.simulate_instance_failure(target_service)
        elif experiment_type == 'latency_injection':
            self.inject_latency(target_service)
        elif experiment_type == 'dependency_failure':
            self.simulate_dependency_failure(target_service)
        
        # Monitor impact
        experiment_metrics = self.monitor_experiment_impact(target_service)
        
        # Analyze results
        results = self.analyze_chaos_results(baseline_metrics, experiment_metrics)
        
        return results
    
    def analyze_chaos_results(self, baseline, experiment):
        """Analyze chaos experiment results"""
        
        return {
            'availability_impact': experiment['availability'] - baseline['availability'],
            'reliability_impact': experiment['error_rate'] - baseline['error_rate'],
            'user_impact': experiment['user_satisfaction'] - baseline['user_satisfaction'],
            'recovery_time': experiment.get('recovery_time', 0),
            'lessons_learned': [
                'System gracefully handled instance failures',
                'Circuit breakers prevented cascade failures',
                'Monitoring detected issues within SLA timeframes'
            ]
        }
```

### 2. Amazon: Two-Pizza Team Ownership Model
```python
class AmazonServiceOwnership:
    """Amazon's approach to service reliability through team ownership"""
    
    def __init__(self):
        self.service_ownership_model = {
            'team_size': 'Two-pizza team (6-8 people)',
            'responsibilities': [
                'Development and deployment',
                'Monitoring and alerting',
                'On-call rotation',
                'SLA definition and compliance',
                'Capacity planning'
            ],
            'tools_provided': [
                'CloudWatch for monitoring',
                'AWS X-Ray for tracing',
                'Internal deployment tools',
                'Automated testing frameworks'
            ]
        }
    
    def define_service_sla(self, service_name, requirements):
        """Define SLA based on business requirements"""
        
        sla_definition = {
            'service_name': service_name,
            'availability_target': requirements.get('availability', 99.9),
            'latency_targets': {
                'p50': requirements.get('p50_latency_ms', 100),
                'p99': requirements.get('p99_latency_ms', 500)
            },
            'error_rate_target': requirements.get('max_error_rate', 0.1),
            'dependencies': requirements.get('dependencies', []),
            'monitoring_requirements': self.define_monitoring_requirements(),
            'on_call_procedures': self.define_on_call_procedures()
        }
        
        return sla_definition
    
    def define_monitoring_requirements(self):
        """Define comprehensive monitoring requirements"""
        
        return {
            'health_checks': {
                'shallow': 'Simple connectivity check',
                'deep': 'End-to-end functionality check'
            },
            'metrics': [
                'Request count and rate',
                'Error count and rate',
                'Response time percentiles',
                'Dependency health',
                'Business metrics'
            ],
            'alerts': [
                'SLA breach warnings',
                'Error rate spikes',
                'Dependency failures',
                'Capacity thresholds'
            ],
            'dashboards': [
                'Operational dashboard',
                'Business metrics dashboard',
                'Dependency health dashboard'
            ]
        }
```

## 📚 Conclusion

Availability and reliability are both crucial for system success, but they represent different aspects of system quality. Availability focuses on uptime and accessibility, while reliability focuses on correctness and consistency of service. The best systems achieve high levels of both through careful architectural design, comprehensive monitoring, and operational excellence.

**Key Takeaways:**

1. **Measure Both Metrics**: Track availability and reliability separately to understand system behavior
2. **Understand Trade-offs**: Some optimizations improve one metric while affecting the other
3. **Design for Both**: Use patterns like redundancy, circuit breakers, and graceful degradation
4. **Monitor Comprehensively**: Implement monitoring that covers both availability and reliability aspects
5. **Plan for Failure**: Assume failures will happen and design recovery mechanisms

The future of high-availability and high-reliability systems lies in AI-powered operations, predictive failure detection, and self-healing architectures. Whether you're building a simple web application or a mission-critical system, understanding these concepts is essential for creating systems that users can depend on.

Remember: availability without reliability frustrates users with incorrect results, while reliability without availability frustrates users with inaccessible systems. Strive for both to create truly dependable systems.
