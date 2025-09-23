# Health Checks & Auto-Recovery: Self-Healing Systems

## 🎯 What are Health Checks and Auto-Recovery?

Health checks and auto-recovery are like having a smart home system that continuously monitors your house and automatically fixes problems. Just as a smart system might detect a water leak and shut off the water supply, or notice a security breach and activate alarms, health checks monitor system components and auto-recovery mechanisms automatically respond to issues without human intervention.

## 🏗️ Core Concepts

### The Smart Home Analogy
- **Health Checks**: Sensors monitoring temperature, humidity, security, power
- **Auto-Recovery**: Automated responses like adjusting thermostats, calling repair services
- **Escalation**: Alerting homeowners when automatic fixes aren't sufficient
- **Preventive Maintenance**: Regular system checks before problems occur
- **Learning System**: Adapting responses based on past incidents

### Why Health Checks and Auto-Recovery Matter
1. **Minimize Downtime**: Detect and fix issues before users notice them
2. **Reduce Operational Burden**: Less manual intervention required
3. **Improve Reliability**: Consistent, predictable responses to common issues
4. **Cost Efficiency**: Prevent small issues from becoming expensive failures
5. **24/7 Operations**: Systems can heal themselves even when no one is watching

## 🔍 Health Check Implementation

```python
import time
import threading
import requests
import psutil
import subprocess
from typing import Dict, List, Any, Optional, Callable
from enum import Enum
from dataclasses import dataclass
from datetime import datetime, timedelta

class HealthStatus(Enum):
    HEALTHY = "healthy"
    WARNING = "warning" 
    CRITICAL = "critical"
    UNKNOWN = "unknown"

@dataclass
class HealthCheckResult:
    check_name: str
    status: HealthStatus
    response_time_ms: float
    message: str
    metadata: Dict[str, Any]
    timestamp: float

class BaseHealthCheck:
    def __init__(self, name: str, interval_seconds: int = 30, timeout_seconds: int = 10):
        self.name = name
        self.interval_seconds = interval_seconds
        self.timeout_seconds = timeout_seconds
        self.last_result: Optional[HealthCheckResult] = None
        self.history: List[HealthCheckResult] = []
        self.enabled = True
        
    def execute(self) -> HealthCheckResult:
        """Execute health check and return result"""
        if not self.enabled:
            return HealthCheckResult(
                check_name=self.name,
                status=HealthStatus.UNKNOWN,
                response_time_ms=0,
                message="Health check disabled",
                metadata={},
                timestamp=time.time()
            )
        
        start_time = time.time()
        
        try:
            result = self._perform_check()
            response_time = (time.time() - start_time) * 1000
            
            health_result = HealthCheckResult(
                check_name=self.name,
                status=result['status'],
                response_time_ms=response_time,
                message=result['message'],
                metadata=result.get('metadata', {}),
                timestamp=time.time()
            )
            
        except Exception as e:
            response_time = (time.time() - start_time) * 1000
            health_result = HealthCheckResult(
                check_name=self.name,
                status=HealthStatus.CRITICAL,
                response_time_ms=response_time,
                message=f"Health check failed: {str(e)}",
                metadata={'exception': str(e)},
                timestamp=time.time()
            )
        
        self.last_result = health_result
        self.history.append(health_result)
        
        # Keep only recent history
        if len(self.history) > 100:
            self.history = self.history[-100:]
        
        return health_result
    
    def _perform_check(self) -> Dict[str, Any]:
        """Override this method in subclasses"""
        raise NotImplementedError("Subclasses must implement _perform_check")
    
    def get_health_trends(self, hours: int = 24) -> Dict[str, Any]:
        """Analyze health trends over time"""
        cutoff_time = time.time() - (hours * 3600)
        recent_results = [r for r in self.history if r.timestamp >= cutoff_time]
        
        if not recent_results:
            return {'status': 'no_data'}
        
        status_counts = {}
        response_times = []
        
        for result in recent_results:
            status = result.status.value
            status_counts[status] = status_counts.get(status, 0) + 1
            response_times.append(result.response_time_ms)
        
        return {
            'total_checks': len(recent_results),
            'status_distribution': status_counts,
            'avg_response_time_ms': sum(response_times) / len(response_times),
            'max_response_time_ms': max(response_times),
            'success_rate': status_counts.get('healthy', 0) / len(recent_results) * 100
        }

class HTTPHealthCheck(BaseHealthCheck):
    def __init__(self, name: str, url: str, expected_status: int = 200, 
                 expected_content: str = None, **kwargs):
        super().__init__(name, **kwargs)
        self.url = url
        self.expected_status = expected_status
        self.expected_content = expected_content
    
    def _perform_check(self) -> Dict[str, Any]:
        """Perform HTTP health check"""
        
        response = requests.get(self.url, timeout=self.timeout_seconds)
        
        metadata = {
            'url': self.url,
            'status_code': response.status_code,
            'response_size': len(response.content),
            'headers': dict(response.headers)
        }
        
        # Check status code
        if response.status_code != self.expected_status:
            return {
                'status': HealthStatus.CRITICAL,
                'message': f"Expected status {self.expected_status}, got {response.status_code}",
                'metadata': metadata
            }
        
        # Check content if specified
        if self.expected_content and self.expected_content not in response.text:
            return {
                'status': HealthStatus.WARNING,
                'message': f"Expected content '{self.expected_content}' not found",
                'metadata': metadata
            }
        
        return {
            'status': HealthStatus.HEALTHY,
            'message': f"HTTP check successful ({response.status_code})",
            'metadata': metadata
        }

class DatabaseHealthCheck(BaseHealthCheck):
    def __init__(self, name: str, connection_string: str, test_query: str = "SELECT 1", **kwargs):
        super().__init__(name, **kwargs)
        self.connection_string = connection_string
        self.test_query = test_query
    
    def _perform_check(self) -> Dict[str, Any]:
        """Perform database connectivity check"""
        
        # Simulate database connection and query
        # In real implementation, use actual database driver
        try:
            # Simulate connection time
            connection_time = time.time()
            time.sleep(0.01)  # Simulate connection delay
            
            # Simulate query execution
            query_start = time.time()
            time.sleep(0.005)  # Simulate query time
            query_time = (time.time() - query_start) * 1000
            
            metadata = {
                'connection_string': self.connection_string.split('@')[-1],  # Hide credentials
                'test_query': self.test_query,
                'query_time_ms': query_time,
                'connection_pool_size': 10  # Simulated
            }
            
            # Simulate occasional slow queries
            if query_time > 100:
                return {
                    'status': HealthStatus.WARNING,
                    'message': f"Slow database response: {query_time:.2f}ms",
                    'metadata': metadata
                }
            
            return {
                'status': HealthStatus.HEALTHY,
                'message': f"Database check successful ({query_time:.2f}ms)",
                'metadata': metadata
            }
            
        except Exception as e:
            return {
                'status': HealthStatus.CRITICAL,
                'message': f"Database connection failed: {str(e)}",
                'metadata': {'error': str(e)}
            }

class SystemResourceHealthCheck(BaseHealthCheck):
    def __init__(self, name: str, cpu_threshold: float = 80, memory_threshold: float = 85, 
                 disk_threshold: float = 90, **kwargs):
        super().__init__(name, **kwargs)
        self.cpu_threshold = cpu_threshold
        self.memory_threshold = memory_threshold
        self.disk_threshold = disk_threshold
    
    def _perform_check(self) -> Dict[str, Any]:
        """Check system resource utilization"""
        
        # Get system metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        metadata = {
            'cpu_percent': cpu_percent,
            'memory_percent': memory.percent,
            'disk_percent': disk.percent,
            'memory_available_gb': memory.available / (1024**3),
            'disk_free_gb': disk.free / (1024**3)
        }
        
        issues = []
        status = HealthStatus.HEALTHY
        
        # Check CPU
        if cpu_percent > self.cpu_threshold:
            issues.append(f"High CPU usage: {cpu_percent:.1f}%")
            status = HealthStatus.WARNING if cpu_percent < 95 else HealthStatus.CRITICAL
        
        # Check Memory
        if memory.percent > self.memory_threshold:
            issues.append(f"High memory usage: {memory.percent:.1f}%")
            status = HealthStatus.WARNING if memory.percent < 95 else HealthStatus.CRITICAL
        
        # Check Disk
        if disk.percent > self.disk_threshold:
            issues.append(f"High disk usage: {disk.percent:.1f}%")
            status = HealthStatus.WARNING if disk.percent < 98 else HealthStatus.CRITICAL
        
        if issues:
            message = "; ".join(issues)
        else:
            message = f"System resources OK (CPU: {cpu_percent:.1f}%, Mem: {memory.percent:.1f}%, Disk: {disk.percent:.1f}%)"
        
        return {
            'status': status,
            'message': message,
            'metadata': metadata
        }

class HealthCheckManager:
    def __init__(self):
        self.health_checks: Dict[str, BaseHealthCheck] = {}
        self.running = False
        self.check_threads: Dict[str, threading.Thread] = {}
        self.results: Dict[str, HealthCheckResult] = {}
        self.listeners: List[Callable] = []
        
    def register_health_check(self, health_check: BaseHealthCheck):
        """Register a health check"""
        self.health_checks[health_check.name] = health_check
        print(f"Registered health check: {health_check.name}")
    
    def add_result_listener(self, listener: Callable[[str, HealthCheckResult], None]):
        """Add listener for health check results"""
        self.listeners.append(listener)
    
    def start_monitoring(self):
        """Start health check monitoring"""
        if self.running:
            return
        
        self.running = True
        
        for name, health_check in self.health_checks.items():
            thread = threading.Thread(target=self._run_health_check_loop, args=(name,))
            thread.daemon = True
            thread.start()
            self.check_threads[name] = thread
        
        print(f"Started monitoring {len(self.health_checks)} health checks")
    
    def stop_monitoring(self):
        """Stop health check monitoring"""
        self.running = False
        print("Stopped health check monitoring")
    
    def _run_health_check_loop(self, check_name: str):
        """Run health check in loop"""
        health_check = self.health_checks[check_name]
        
        while self.running:
            try:
                result = health_check.execute()
                self.results[check_name] = result
                
                # Notify listeners
                for listener in self.listeners:
                    try:
                        listener(check_name, result)
                    except Exception as e:
                        print(f"Listener error for {check_name}: {e}")
                
                time.sleep(health_check.interval_seconds)
                
            except Exception as e:
                print(f"Error in health check loop for {check_name}: {e}")
                time.sleep(5)  # Brief pause before retry
    
    def get_overall_health(self) -> Dict[str, Any]:
        """Get overall system health status"""
        
        if not self.results:
            return {
                'status': HealthStatus.UNKNOWN.value,
                'message': 'No health check results available',
                'checks': {}
            }
        
        check_statuses = {}
        status_counts = {'healthy': 0, 'warning': 0, 'critical': 0, 'unknown': 0}
        
        for check_name, result in self.results.items():
            check_statuses[check_name] = {
                'status': result.status.value,
                'message': result.message,
                'response_time_ms': result.response_time_ms,
                'last_check': result.timestamp
            }
            
            status_counts[result.status.value] += 1
        
        # Determine overall status
        if status_counts['critical'] > 0:
            overall_status = HealthStatus.CRITICAL
        elif status_counts['warning'] > 0:
            overall_status = HealthStatus.WARNING
        else:
            overall_status = HealthStatus.HEALTHY
        
        return {
            'status': overall_status.value,
            'message': f"Overall system health: {overall_status.value}",
            'summary': status_counts,
            'checks': check_statuses,
            'total_checks': len(self.results)
        }

# Example usage
health_manager = HealthCheckManager()

# Register different types of health checks
health_manager.register_health_check(
    HTTPHealthCheck("web_server", "http://localhost:8080/health", interval_seconds=30)
)

health_manager.register_health_check(
    DatabaseHealthCheck("primary_db", "postgresql://localhost:5432/myapp", interval_seconds=60)
)

health_manager.register_health_check(
    SystemResourceHealthCheck("system_resources", interval_seconds=15)
)

# Add result listener
def health_result_listener(check_name: str, result: HealthCheckResult):
    if result.status != HealthStatus.HEALTHY:
        print(f"ALERT: {check_name} - {result.status.value}: {result.message}")

health_manager.add_result_listener(health_result_listener)

# Start monitoring
health_manager.start_monitoring()

# Check overall health after some time
time.sleep(5)
overall_health = health_manager.get_overall_health()
print(f"Overall Health: {overall_health['status']}")
for check_name, details in overall_health['checks'].items():
    print(f"  {check_name}: {details['status']} - {details['message']}")
```

## 🔄 Auto-Recovery Implementation

```python
class RecoveryAction:
    def __init__(self, name: str, action_func: Callable, max_attempts: int = 3, 
                 cooldown_seconds: int = 60):
        self.name = name
        self.action_func = action_func
        self.max_attempts = max_attempts
        self.cooldown_seconds = cooldown_seconds
        self.attempt_count = 0
        self.last_attempt = 0
        self.success_count = 0
        self.failure_count = 0
    
    def can_execute(self) -> bool:
        """Check if recovery action can be executed"""
        if self.attempt_count >= self.max_attempts:
            return False
        
        if time.time() - self.last_attempt < self.cooldown_seconds:
            return False
        
        return True
    
    def execute(self, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute recovery action"""
        if not self.can_execute():
            return {
                'success': False,
                'message': 'Recovery action cannot be executed (max attempts or cooldown)',
                'attempt_count': self.attempt_count
            }
        
        self.attempt_count += 1
        self.last_attempt = time.time()
        
        try:
            result = self.action_func(context or {})
            
            if result.get('success', True):
                self.success_count += 1
                return {
                    'success': True,
                    'message': f"Recovery action '{self.name}' succeeded",
                    'attempt_count': self.attempt_count,
                    'result': result
                }
            else:
                self.failure_count += 1
                return {
                    'success': False,
                    'message': f"Recovery action '{self.name}' failed: {result.get('message', 'Unknown error')}",
                    'attempt_count': self.attempt_count
                }
                
        except Exception as e:
            self.failure_count += 1
            return {
                'success': False,
                'message': f"Recovery action '{self.name}' failed with exception: {str(e)}",
                'attempt_count': self.attempt_count,
                'exception': str(e)
            }
    
    def reset(self):
        """Reset recovery action state"""
        self.attempt_count = 0
        self.last_attempt = 0

class AutoRecoveryManager:
    def __init__(self):
        self.recovery_rules: Dict[str, List[RecoveryAction]] = {}
        self.recovery_history: List[Dict[str, Any]] = []
        self.enabled = True
        
    def register_recovery_rule(self, health_check_name: str, recovery_actions: List[RecoveryAction]):
        """Register recovery actions for a health check"""
        self.recovery_rules[health_check_name] = recovery_actions
        print(f"Registered {len(recovery_actions)} recovery actions for {health_check_name}")
    
    def handle_health_check_result(self, check_name: str, result: HealthCheckResult):
        """Handle health check result and trigger recovery if needed"""
        
        if not self.enabled:
            return
        
        # Only trigger recovery for critical or warning status
        if result.status not in [HealthStatus.CRITICAL, HealthStatus.WARNING]:
            return
        
        if check_name not in self.recovery_rules:
            print(f"No recovery rules defined for {check_name}")
            return
        
        recovery_actions = self.recovery_rules[check_name]
        
        print(f"Triggering auto-recovery for {check_name} (status: {result.status.value})")
        
        recovery_context = {
            'health_check_name': check_name,
            'health_result': result,
            'timestamp': time.time()
        }
        
        # Execute recovery actions in sequence
        for action in recovery_actions:
            if not action.can_execute():
                print(f"Skipping recovery action '{action.name}' (cannot execute)")
                continue
            
            print(f"Executing recovery action: {action.name}")
            
            recovery_result = action.execute(recovery_context)
            
            # Record recovery attempt
            recovery_record = {
                'timestamp': time.time(),
                'health_check': check_name,
                'action_name': action.name,
                'success': recovery_result['success'],
                'message': recovery_result['message'],
                'attempt_count': recovery_result['attempt_count']
            }
            
            self.recovery_history.append(recovery_record)
            
            if recovery_result['success']:
                print(f"Recovery action '{action.name}' succeeded")
                # Reset subsequent actions on success
                for remaining_action in recovery_actions[recovery_actions.index(action)+1:]:
                    remaining_action.reset()
                break
            else:
                print(f"Recovery action '{action.name}' failed: {recovery_result['message']}")
        
        # Keep only recent history
        if len(self.recovery_history) > 1000:
            self.recovery_history = self.recovery_history[-1000:]
    
    def get_recovery_statistics(self) -> Dict[str, Any]:
        """Get recovery statistics"""
        
        if not self.recovery_history:
            return {'message': 'No recovery history available'}
        
        total_attempts = len(self.recovery_history)
        successful_attempts = len([r for r in self.recovery_history if r['success']])
        
        # Group by action name
        action_stats = {}
        for record in self.recovery_history:
            action_name = record['action_name']
            if action_name not in action_stats:
                action_stats[action_name] = {'attempts': 0, 'successes': 0}
            
            action_stats[action_name]['attempts'] += 1
            if record['success']:
                action_stats[action_name]['successes'] += 1
        
        # Calculate success rates
        for action_name, stats in action_stats.items():
            stats['success_rate'] = (stats['successes'] / stats['attempts']) * 100
        
        return {
            'total_recovery_attempts': total_attempts,
            'successful_recoveries': successful_attempts,
            'overall_success_rate': (successful_attempts / total_attempts) * 100,
            'action_statistics': action_stats,
            'recent_recoveries': self.recovery_history[-10:]  # Last 10 attempts
        }

# Define recovery actions
def restart_service_action(context: Dict[str, Any]) -> Dict[str, Any]:
    """Restart service recovery action"""
    service_name = context.get('service_name', 'unknown_service')
    
    try:
        # Simulate service restart
        print(f"Restarting service: {service_name}")
        time.sleep(2)  # Simulate restart time
        
        # Simulate success/failure
        success = random.random() > 0.2  # 80% success rate
        
        if success:
            return {'success': True, 'message': f'Service {service_name} restarted successfully'}
        else:
            return {'success': False, 'message': f'Failed to restart service {service_name}'}
            
    except Exception as e:
        return {'success': False, 'message': f'Exception during service restart: {str(e)}'}

def clear_cache_action(context: Dict[str, Any]) -> Dict[str, Any]:
    """Clear cache recovery action"""
    try:
        print("Clearing application cache")
        time.sleep(0.5)  # Simulate cache clear time
        
        return {'success': True, 'message': 'Cache cleared successfully'}
        
    except Exception as e:
        return {'success': False, 'message': f'Failed to clear cache: {str(e)}'}

def scale_up_action(context: Dict[str, Any]) -> Dict[str, Any]:
    """Scale up resources recovery action"""
    try:
        print("Scaling up resources")
        time.sleep(3)  # Simulate scaling time
        
        return {'success': True, 'message': 'Resources scaled up successfully'}
        
    except Exception as e:
        return {'success': False, 'message': f'Failed to scale up: {str(e)}'}

def send_alert_action(context: Dict[str, Any]) -> Dict[str, Any]:
    """Send alert to operations team"""
    try:
        health_result = context.get('health_result')
        message = f"CRITICAL: {health_result.check_name} - {health_result.message}"
        
        print(f"Sending alert: {message}")
        
        # Simulate sending alert (email, Slack, PagerDuty, etc.)
        return {'success': True, 'message': 'Alert sent to operations team'}
        
    except Exception as e:
        return {'success': False, 'message': f'Failed to send alert: {str(e)}'}

# Set up auto-recovery
recovery_manager = AutoRecoveryManager()

# Define recovery actions for web server health check
web_server_recovery = [
    RecoveryAction("clear_cache", clear_cache_action, max_attempts=2, cooldown_seconds=30),
    RecoveryAction("restart_service", lambda ctx: restart_service_action({**ctx, 'service_name': 'web_server'}), 
                  max_attempts=3, cooldown_seconds=60),
    RecoveryAction("scale_up", scale_up_action, max_attempts=1, cooldown_seconds=300),
    RecoveryAction("send_alert", send_alert_action, max_attempts=1, cooldown_seconds=3600)
]

recovery_manager.register_recovery_rule("web_server", web_server_recovery)

# Define recovery actions for database health check
database_recovery = [
    RecoveryAction("restart_db_service", lambda ctx: restart_service_action({**ctx, 'service_name': 'database'}),
                  max_attempts=2, cooldown_seconds=120),
    RecoveryAction("failover_to_replica", lambda ctx: {'success': True, 'message': 'Failover completed'},
                  max_attempts=1, cooldown_seconds=600),
    RecoveryAction("send_critical_alert", send_alert_action, max_attempts=1, cooldown_seconds=1800)
]

recovery_manager.register_recovery_rule("primary_db", database_recovery)

# Connect auto-recovery to health check manager
health_manager.add_result_listener(recovery_manager.handle_health_check_result)

# Simulate some time passing and check recovery statistics
time.sleep(10)

recovery_stats = recovery_manager.get_recovery_statistics()
print(f"\nRecovery Statistics:")
print(f"Total recovery attempts: {recovery_stats.get('total_recovery_attempts', 0)}")
print(f"Success rate: {recovery_stats.get('overall_success_rate', 0):.1f}%")

if 'action_statistics' in recovery_stats:
    print("Action-specific statistics:")
    for action_name, stats in recovery_stats['action_statistics'].items():
        print(f"  {action_name}: {stats['successes']}/{stats['attempts']} "
              f"({stats['success_rate']:.1f}% success)")
```

## 📊 Advanced Health Check and Recovery Patterns

```python
class PredictiveHealthMonitor:
    """Monitor health trends to predict failures before they occur"""
    
    def __init__(self):
        self.metric_history = {}
        self.prediction_models = {}
        self.anomaly_thresholds = {}
        
    def record_metric(self, metric_name: str, value: float, timestamp: float = None):
        """Record metric value for trend analysis"""
        if timestamp is None:
            timestamp = time.time()
            
        if metric_name not in self.metric_history:
            self.metric_history[metric_name] = []
            
        self.metric_history[metric_name].append({
            'value': value,
            'timestamp': timestamp
        })
        
        # Keep only recent history (last 24 hours)
        cutoff_time = timestamp - (24 * 3600)
        self.metric_history[metric_name] = [
            entry for entry in self.metric_history[metric_name]
            if entry['timestamp'] >= cutoff_time
        ]
    
    def detect_anomalies(self, metric_name: str) -> Dict[str, Any]:
        """Detect anomalies in metric trends"""
        
        if metric_name not in self.metric_history:
            return {'status': 'no_data'}
            
        history = self.metric_history[metric_name]
        
        if len(history) < 10:
            return {'status': 'insufficient_data'}
        
        # Calculate basic statistics
        values = [entry['value'] for entry in history[-50:]]  # Last 50 data points
        mean_value = sum(values) / len(values)
        
        # Calculate standard deviation
        variance = sum((x - mean_value) ** 2 for x in values) / len(values)
        std_dev = variance ** 0.5
        
        # Current value
        current_value = history[-1]['value']
        
        # Detect anomalies (values beyond 2 standard deviations)
        anomaly_threshold = 2 * std_dev
        is_anomaly = abs(current_value - mean_value) > anomaly_threshold
        
        # Trend analysis
        recent_values = values[-10:]  # Last 10 values
        older_values = values[-20:-10]  # Previous 10 values
        
        recent_mean = sum(recent_values) / len(recent_values)
        older_mean = sum(older_values) / len(older_values) if older_values else recent_mean
        
        trend_direction = "increasing" if recent_mean > older_mean else "decreasing"
        trend_magnitude = abs(recent_mean - older_mean) / older_mean * 100 if older_mean != 0 else 0
        
        return {
            'status': 'analyzed',
            'is_anomaly': is_anomaly,
            'current_value': current_value,
            'mean_value': mean_value,
            'standard_deviation': std_dev,
            'deviation_from_mean': abs(current_value - mean_value),
            'trend_direction': trend_direction,
            'trend_magnitude_percent': trend_magnitude,
            'prediction': self._predict_future_values(metric_name)
        }
    
    def _predict_future_values(self, metric_name: str, hours_ahead: int = 2) -> Dict[str, Any]:
        """Simple linear prediction of future values"""
        
        history = self.metric_history[metric_name]
        
        if len(history) < 20:
            return {'status': 'insufficient_data_for_prediction'}
        
        # Use linear regression on recent data
        recent_data = history[-20:]  # Last 20 data points
        
        # Calculate slope (rate of change)
        x_values = list(range(len(recent_data)))
        y_values = [entry['value'] for entry in recent_data]
        
        n = len(recent_data)
        sum_x = sum(x_values)
        sum_y = sum(y_values)
        sum_xy = sum(x * y for x, y in zip(x_values, y_values))
        sum_x2 = sum(x * x for x in x_values)
        
        # Linear regression: y = mx + b
        slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x)
        intercept = (sum_y - slope * sum_x) / n
        
        # Predict future values
        current_time = recent_data[-1]['timestamp']
        prediction_time = current_time + (hours_ahead * 3600)
        
        # Project trend forward
        predicted_value = y_values[-1] + (slope * hours_ahead * 3600 / 300)  # Assuming 5-minute intervals
        
        return {
            'status': 'predicted',
            'predicted_value': predicted_value,
            'prediction_time': prediction_time,
            'trend_slope': slope,
            'confidence': 'medium'  # Simple confidence measure
        }

class AdaptiveRecoveryManager(AutoRecoveryManager):
    """Auto-recovery manager that learns from past recovery attempts"""
    
    def __init__(self):
        super().__init__()
        self.recovery_effectiveness = {}  # action -> success_rate
        self.learning_enabled = True
        
    def handle_health_check_result(self, check_name: str, result: HealthCheckResult):
        """Enhanced recovery handling with learning"""
        
        if not self.enabled:
            return
            
        # Update recovery action effectiveness based on history
        if self.learning_enabled:
            self._update_recovery_effectiveness()
        
        # Only trigger recovery for critical or warning status
        if result.status not in [HealthStatus.CRITICAL, HealthStatus.WARNING]:
            return
        
        if check_name not in self.recovery_rules:
            return
        
        recovery_actions = self.recovery_rules[check_name]
        
        # Sort actions by effectiveness (learned from history)
        sorted_actions = self._sort_actions_by_effectiveness(recovery_actions)
        
        print(f"Triggering adaptive auto-recovery for {check_name}")
        
        recovery_context = {
            'health_check_name': check_name,
            'health_result': result,
            'timestamp': time.time()
        }
        
        # Execute most effective actions first
        for action in sorted_actions:
            if not action.can_execute():
                continue
            
            effectiveness = self.recovery_effectiveness.get(action.name, 0.5)
            print(f"Executing recovery action: {action.name} (effectiveness: {effectiveness:.2f})")
            
            recovery_result = action.execute(recovery_context)
            
            # Record recovery attempt with enhanced metadata
            recovery_record = {
                'timestamp': time.time(),
                'health_check': check_name,
                'action_name': action.name,
                'success': recovery_result['success'],
                'message': recovery_result['message'],
                'attempt_count': recovery_result['attempt_count'],
                'effectiveness_score': effectiveness,
                'health_status': result.status.value
            }
            
            self.recovery_history.append(recovery_record)
            
            if recovery_result['success']:
                print(f"Recovery action '{action.name}' succeeded")
                break
            else:
                print(f"Recovery action '{action.name}' failed")
    
    def _update_recovery_effectiveness(self):
        """Update recovery action effectiveness based on historical success"""
        
        action_stats = {}
        
        # Analyze recent recovery history (last 100 attempts)
        recent_history = self.recovery_history[-100:]
        
        for record in recent_history:
            action_name = record['action_name']
            
            if action_name not in action_stats:
                action_stats[action_name] = {'successes': 0, 'attempts': 0}
            
            action_stats[action_name]['attempts'] += 1
            if record['success']:
                action_stats[action_name]['successes'] += 1
        
        # Update effectiveness scores
        for action_name, stats in action_stats.items():
            if stats['attempts'] > 0:
                effectiveness = stats['successes'] / stats['attempts']
                
                # Apply smoothing to avoid dramatic changes
                current_effectiveness = self.recovery_effectiveness.get(action_name, 0.5)
                self.recovery_effectiveness[action_name] = (
                    0.7 * current_effectiveness + 0.3 * effectiveness
                )
    
    def _sort_actions_by_effectiveness(self, actions: List[RecoveryAction]) -> List[RecoveryAction]:
        """Sort recovery actions by their learned effectiveness"""
        
        return sorted(actions, 
                     key=lambda action: self.recovery_effectiveness.get(action.name, 0.5),
                     reverse=True)

# Usage example with predictive monitoring
predictive_monitor = PredictiveHealthMonitor()
adaptive_recovery = AdaptiveRecoveryManager()

# Simulate metric collection over time
for i in range(100):
    # Simulate CPU usage with gradual increase (potential problem)
    cpu_usage = 30 + (i * 0.5) + random.uniform(-5, 5)
    predictive_monitor.record_metric('cpu_usage', cpu_usage)
    
    # Simulate memory usage with periodic spikes
    memory_usage = 50 + (10 * (i % 10)) + random.uniform(-3, 3)
    predictive_monitor.record_metric('memory_usage', memory_usage)
    
    time.sleep(0.01)  # Brief pause

# Analyze trends and detect anomalies
cpu_analysis = predictive_monitor.detect_anomalies('cpu_usage')
memory_analysis = predictive_monitor.detect_anomalies('memory_usage')

print("=== Predictive Analysis ===")
print(f"CPU Anomaly Detected: {cpu_analysis['is_anomaly']}")
print(f"CPU Trend: {cpu_analysis['trend_direction']} by {cpu_analysis['trend_magnitude_percent']:.1f}%")

if cpu_analysis['prediction']['status'] == 'predicted':
    print(f"CPU Predicted Value (2h): {cpu_analysis['prediction']['predicted_value']:.1f}%")

print(f"\nMemory Anomaly Detected: {memory_analysis['is_anomaly']}")
print(f"Memory Trend: {memory_analysis['trend_direction']} by {memory_analysis['trend_magnitude_percent']:.1f}%")
```

## 📚 Conclusion

Health checks and auto-recovery systems are the immune system of modern applications—they detect problems early and respond automatically to maintain system health. From basic HTTP checks to sophisticated predictive monitoring, these systems enable true operational resilience and reduce the burden on operations teams.

**Key Takeaways:**

1. **Implement Comprehensive Health Checks**: Monitor all critical system components and dependencies
2. **Design Graduated Recovery Actions**: Start with simple fixes and escalate to more complex interventions
3. **Learn from Recovery History**: Use past recovery attempts to improve future responses
4. **Monitor Health Trends**: Detect problems before they become critical through predictive analysis
5. **Balance Automation and Human Oversight**: Automate routine recoveries but escalate complex issues

The future of health checks and auto-recovery includes AI-powered anomaly detection, self-tuning recovery parameters, and integration with infrastructure-as-code for dynamic system healing. Whether you're managing a simple web application or a complex microservices architecture, implementing robust health checks and auto-recovery is essential for maintaining reliable, self-healing systems.

Remember: the best recovery is prevention—design systems that detect and resolve issues before users are affected, and always have escalation paths for scenarios that automated recovery cannot handle.
