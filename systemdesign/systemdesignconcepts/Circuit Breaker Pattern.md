# Circuit Breaker Pattern: Preventing Cascade Failures

## 🎯 What is the Circuit Breaker Pattern?

The Circuit Breaker Pattern is like an electrical circuit breaker in your home that automatically cuts power when it detects dangerous electrical conditions. Just as a home circuit breaker prevents electrical fires by stopping current flow during overloads, a software circuit breaker prevents cascade failures by stopping requests to failing services, giving them time to recover while protecting the overall system.

## 🏗️ Core Concepts

### The Electrical Circuit Breaker Analogy
- **Closed State**: Normal operation, electricity flows freely
- **Open State**: Breaker has tripped, no current flows (requests blocked)
- **Half-Open State**: Testing if the problem is resolved (limited requests allowed)
- **Failure Detection**: Monitoring for overloads or short circuits
- **Automatic Recovery**: Breaker resets itself when conditions normalize
- **Fast Failure**: Immediate response instead of waiting for timeout

### Why Circuit Breaker Pattern Matters
1. **Prevent Cascade Failures**: Stop failures from spreading across services
2. **Fail Fast**: Return errors immediately instead of waiting for timeouts
3. **Resource Protection**: Preserve system resources during failures
4. **Automatic Recovery**: Test service health and resume when recovered
5. **System Stability**: Maintain overall system stability during partial failures

## ⚡ Circuit Breaker Implementation

```python
import time
import threading
import random
from typing import Dict, List, Optional, Any, Callable
from enum import Enum
from dataclasses import dataclass, asdict
from collections import deque, defaultdict
import statistics

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

@dataclass
class CircuitBreakerConfig:
    failure_threshold: int = 5
    recovery_timeout: int = 60
    success_threshold: int = 3
    timeout: float = 10.0
    expected_exception_types: List[type] = None
    
    def __post_init__(self):
        if self.expected_exception_types is None:
            self.expected_exception_types = [Exception]

@dataclass
class CallResult:
    success: bool
    response_time: float
    error: Optional[str]
    timestamp: float

class CircuitBreakerMetrics:
    def __init__(self, window_size: int = 100):
        self.window_size = window_size
        self.calls: deque = deque(maxlen=window_size)
        self.failure_count = 0
        self.success_count = 0
        self.total_calls = 0
        
    def record_call(self, result: CallResult):
        """Record call result for metrics"""
        
        # Remove old call if at capacity
        if len(self.calls) == self.window_size:
            old_call = self.calls[0]
            if old_call.success:
                self.success_count -= 1
            else:
                self.failure_count -= 1
        
        # Add new call
        self.calls.append(result)
        self.total_calls += 1
        
        if result.success:
            self.success_count += 1
        else:
            self.failure_count += 1
    
    def get_failure_rate(self) -> float:
        """Get current failure rate"""
        if not self.calls:
            return 0.0
        return self.failure_count / len(self.calls)
    
    def get_success_rate(self) -> float:
        """Get current success rate"""
        if not self.calls:
            return 0.0
        return self.success_count / len(self.calls)
    
    def get_average_response_time(self) -> float:
        """Get average response time"""
        if not self.calls:
            return 0.0
        
        response_times = [call.response_time for call in self.calls if call.success]
        return statistics.mean(response_times) if response_times else 0.0
    
    def get_recent_calls(self, count: int = 10) -> List[CallResult]:
        """Get recent calls"""
        return list(self.calls)[-count:]

class CircuitBreaker:
    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        self.name = name
        self.config = config or CircuitBreakerConfig()
        self.state = CircuitState.CLOSED
        self.metrics = CircuitBreakerMetrics()
        
        # State tracking
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        self.state_changed_time = time.time()
        
        # Thread safety
        self.lock = threading.RLock()
        
        # Callbacks
        self.state_change_listeners: List[Callable] = []
        
    def add_state_change_listener(self, listener: Callable[[str, CircuitState, CircuitState], None]):
        """Add listener for state changes"""
        self.state_change_listeners.append(listener)
    
    def call(self, func: Callable, *args, fallback: Callable = None, **kwargs) -> Any:
        """Execute function call through circuit breaker"""
        
        with self.lock:
            # Check if call is allowed
            if not self._can_execute():
                if fallback:
                    return fallback(*args, **kwargs)
                else:
                    raise CircuitBreakerOpenException(
                        f"Circuit breaker '{self.name}' is OPEN"
                    )
            
            # Execute the call
            return self._execute_call(func, *args, **kwargs)
    
    def _can_execute(self) -> bool:
        """Check if call can be executed based on current state"""
        
        if self.state == CircuitState.CLOSED:
            return True
        elif self.state == CircuitState.OPEN:
            # Check if recovery timeout has passed
            if self._should_attempt_reset():
                self._transition_to_half_open()
                return True
            return False
        elif self.state == CircuitState.HALF_OPEN:
            return True
        
        return False
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if self.last_failure_time is None:
            return True
        
        return time.time() - self.last_failure_time >= self.config.recovery_timeout
    
    def _execute_call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute the actual function call"""
        
        start_time = time.time()
        
        try:
            # Execute with timeout
            result = self._execute_with_timeout(func, *args, **kwargs)
            
            # Record successful call
            response_time = time.time() - start_time
            call_result = CallResult(
                success=True,
                response_time=response_time,
                error=None,
                timestamp=time.time()
            )
            
            self._record_success(call_result)
            return result
            
        except Exception as e:
            # Record failed call
            response_time = time.time() - start_time
            call_result = CallResult(
                success=False,
                response_time=response_time,
                error=str(e),
                timestamp=time.time()
            )
            
            self._record_failure(call_result, e)
            raise e
    
    def _execute_with_timeout(self, func: Callable, *args, **kwargs) -> Any:
        """Execute function with timeout"""
        
        # Simple timeout implementation (in production, use proper timeout mechanisms)
        try:
            result = func(*args, **kwargs)
            return result
        except Exception as e:
            # Check if this is an expected exception type
            if any(isinstance(e, exc_type) for exc_type in self.config.expected_exception_types):
                raise e
            else:
                # Unexpected exception, treat as failure
                raise e
    
    def _record_success(self, call_result: CallResult):
        """Record successful call"""
        
        self.metrics.record_call(call_result)
        
        if self.state == CircuitState.HALF_OPEN:
            self.success_count += 1
            
            if self.success_count >= self.config.success_threshold:
                self._transition_to_closed()
        else:
            # In CLOSED state, reset failure count on success
            self.failure_count = max(0, self.failure_count - 1)
    
    def _record_failure(self, call_result: CallResult, exception: Exception):
        """Record failed call"""
        
        self.metrics.record_call(call_result)
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.state == CircuitState.CLOSED:
            if self.failure_count >= self.config.failure_threshold:
                self._transition_to_open()
        elif self.state == CircuitState.HALF_OPEN:
            # Any failure in half-open state transitions back to open
            self._transition_to_open()
    
    def _transition_to_open(self):
        """Transition circuit breaker to OPEN state"""
        old_state = self.state
        self.state = CircuitState.OPEN
        self.success_count = 0
        self.state_changed_time = time.time()
        
        self._notify_state_change(old_state, self.state)
        print(f"Circuit breaker '{self.name}' transitioned to OPEN")
    
    def _transition_to_half_open(self):
        """Transition circuit breaker to HALF_OPEN state"""
        old_state = self.state
        self.state = CircuitState.HALF_OPEN
        self.success_count = 0
        self.state_changed_time = time.time()
        
        self._notify_state_change(old_state, self.state)
        print(f"Circuit breaker '{self.name}' transitioned to HALF_OPEN")
    
    def _transition_to_closed(self):
        """Transition circuit breaker to CLOSED state"""
        old_state = self.state
        self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.state_changed_time = time.time()
        
        self._notify_state_change(old_state, self.state)
        print(f"Circuit breaker '{self.name}' transitioned to CLOSED")
    
    def _notify_state_change(self, old_state: CircuitState, new_state: CircuitState):
        """Notify listeners of state change"""
        for listener in self.state_change_listeners:
            try:
                listener(self.name, old_state, new_state)
            except Exception as e:
                print(f"Error in state change listener: {e}")
    
    def force_open(self):
        """Force circuit breaker to open state"""
        with self.lock:
            if self.state != CircuitState.OPEN:
                self._transition_to_open()
    
    def force_close(self):
        """Force circuit breaker to closed state"""
        with self.lock:
            if self.state != CircuitState.CLOSED:
                self._transition_to_closed()
    
    def get_state(self) -> CircuitState:
        """Get current circuit breaker state"""
        return self.state
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get circuit breaker metrics"""
        
        with self.lock:
            return {
                'name': self.name,
                'state': self.state.value,
                'failure_count': self.failure_count,
                'success_count': self.success_count,
                'failure_rate': self.metrics.get_failure_rate(),
                'success_rate': self.metrics.get_success_rate(),
                'average_response_time': self.metrics.get_average_response_time(),
                'total_calls': self.metrics.total_calls,
                'state_changed_time': self.state_changed_time,
                'last_failure_time': self.last_failure_time,
                'time_in_current_state': time.time() - self.state_changed_time,
                'config': asdict(self.config)
            }

class CircuitBreakerOpenException(Exception):
    """Exception raised when circuit breaker is open"""
    pass

class CircuitBreakerRegistry:
    """Registry for managing multiple circuit breakers"""
    
    def __init__(self):
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
        self.global_listeners: List[Callable] = []
        
    def get_circuit_breaker(self, name: str, config: CircuitBreakerConfig = None) -> CircuitBreaker:
        """Get or create circuit breaker"""
        
        if name not in self.circuit_breakers:
            cb = CircuitBreaker(name, config)
            
            # Add global listeners to new circuit breaker
            for listener in self.global_listeners:
                cb.add_state_change_listener(listener)
            
            self.circuit_breakers[name] = cb
        
        return self.circuit_breakers[name]
    
    def add_global_state_listener(self, listener: Callable[[str, CircuitState, CircuitState], None]):
        """Add global state change listener"""
        self.global_listeners.append(listener)
        
        # Add to existing circuit breakers
        for cb in self.circuit_breakers.values():
            cb.add_state_change_listener(listener)
    
    def get_all_metrics(self) -> Dict[str, Dict[str, Any]]:
        """Get metrics for all circuit breakers"""
        return {name: cb.get_metrics() for name, cb in self.circuit_breakers.items()}
    
    def get_health_summary(self) -> Dict[str, Any]:
        """Get health summary of all circuit breakers"""
        
        total_breakers = len(self.circuit_breakers)
        open_breakers = sum(1 for cb in self.circuit_breakers.values() if cb.get_state() == CircuitState.OPEN)
        half_open_breakers = sum(1 for cb in self.circuit_breakers.values() if cb.get_state() == CircuitState.HALF_OPEN)
        closed_breakers = total_breakers - open_breakers - half_open_breakers
        
        return {
            'total_circuit_breakers': total_breakers,
            'closed': closed_breakers,
            'open': open_breakers,
            'half_open': half_open_breakers,
            'health_percentage': (closed_breakers / total_breakers * 100) if total_breakers > 0 else 100
        }

# Circuit Breaker Decorator
def circuit_breaker(name: str, config: CircuitBreakerConfig = None, 
                   fallback: Callable = None, registry: CircuitBreakerRegistry = None):
    """Decorator to apply circuit breaker pattern to functions"""
    
    if registry is None:
        registry = CircuitBreakerRegistry()
    
    def decorator(func):
        cb = registry.get_circuit_breaker(name, config)
        
        def wrapper(*args, **kwargs):
            return cb.call(func, *args, fallback=fallback, **kwargs)
        
        wrapper.circuit_breaker = cb
        return wrapper
    
    return decorator

# Example usage and testing
print("=== Circuit Breaker Pattern Demo ===")

# Create circuit breaker registry
registry = CircuitBreakerRegistry()

# Add global state change listener
def state_change_listener(name: str, old_state: CircuitState, new_state: CircuitState):
    print(f"🔄 Circuit breaker '{name}' changed from {old_state.value} to {new_state.value}")

registry.add_global_state_listener(state_change_listener)

# Example: External API service with circuit breaker
class ExternalAPIService:
    def __init__(self):
        self.circuit_breaker = registry.get_circuit_breaker(
            "external_api", 
            CircuitBreakerConfig(
                failure_threshold=3,
                recovery_timeout=10,
                success_threshold=2
            )
        )
        
    def call_api(self, endpoint: str, data: Dict[str, Any] = None) -> Dict[str, Any]:
        """Call external API with circuit breaker protection"""
        
        def api_call():
            # Simulate API call with random failures
            if random.random() < 0.4:  # 40% failure rate for demo
                raise Exception(f"API call to {endpoint} failed")
            
            # Simulate response time
            time.sleep(random.uniform(0.1, 0.5))
            
            return {
                'status': 'success',
                'endpoint': endpoint,
                'data': data,
                'response_time': random.uniform(100, 500)
            }
        
        def fallback_response():
            return {
                'status': 'fallback',
                'endpoint': endpoint,
                'message': 'Circuit breaker is open, using cached response',
                'data': {'cached': True}
            }
        
        try:
            return self.circuit_breaker.call(api_call, fallback=fallback_response)
        except CircuitBreakerOpenException:
            return fallback_response()

# Example: Database service with circuit breaker decorator
@circuit_breaker("database", CircuitBreakerConfig(failure_threshold=5, recovery_timeout=15))
def database_query(query: str) -> Dict[str, Any]:
    """Database query with circuit breaker"""
    
    # Simulate database query with occasional failures
    if random.random() < 0.3:  # 30% failure rate
        raise Exception(f"Database query failed: {query}")
    
    time.sleep(random.uniform(0.05, 0.2))  # Simulate query time
    
    return {
        'status': 'success',
        'query': query,
        'results': [{'id': i, 'data': f'result_{i}'} for i in range(5)]
    }

# Test the services
print("\n--- Testing External API Service ---")
api_service = ExternalAPIService()

# Make multiple API calls to trigger circuit breaker
for i in range(15):
    try:
        result = api_service.call_api(f"/users/{i}")
        status = result['status']
        print(f"Call {i+1}: {status} - {result.get('message', 'Success')}")
        
        # Check circuit breaker state every few calls
        if (i + 1) % 5 == 0:
            metrics = api_service.circuit_breaker.get_metrics()
            print(f"  Circuit breaker state: {metrics['state']}, failure rate: {metrics['failure_rate']:.2%}")
        
    except Exception as e:
        print(f"Call {i+1}: ERROR - {e}")
    
    time.sleep(0.2)  # Brief pause between calls

print("\n--- Testing Database Service ---")

# Test database service
for i in range(10):
    try:
        result = database_query(f"SELECT * FROM users WHERE id = {i}")
        print(f"DB Query {i+1}: {result['status']}")
        
    except CircuitBreakerOpenException as e:
        print(f"DB Query {i+1}: Circuit breaker is open")
    except Exception as e:
        print(f"DB Query {i+1}: ERROR - {e}")
    
    time.sleep(0.1)

# Get overall health summary
print("\n--- Circuit Breaker Health Summary ---")
health_summary = registry.get_health_summary()
print(f"Total circuit breakers: {health_summary['total_circuit_breakers']}")
print(f"Closed: {health_summary['closed']}")
print(f"Open: {health_summary['open']}")
print(f"Half-open: {health_summary['half_open']}")
print(f"Overall health: {health_summary['health_percentage']:.1f}%")

# Detailed metrics for each circuit breaker
print("\n--- Detailed Metrics ---")
all_metrics = registry.get_all_metrics()

for name, metrics in all_metrics.items():
    print(f"\n{name} Circuit Breaker:")
    print(f"  State: {metrics['state']}")
    print(f"  Total calls: {metrics['total_calls']}")
    print(f"  Failure rate: {metrics['failure_rate']:.2%}")
    print(f"  Average response time: {metrics['average_response_time']:.2f}ms")
    print(f"  Time in current state: {metrics['time_in_current_state']:.1f}s")

print("\n--- Circuit Breaker Demo Completed ---")
```

## 🛡️ Advanced Circuit Breaker Patterns

```python
class AdaptiveCircuitBreaker(CircuitBreaker):
    """Circuit breaker that adapts thresholds based on historical performance"""
    
    def __init__(self, name: str, config: CircuitBreakerConfig = None):
        super().__init__(name, config)
        self.performance_history: deque = deque(maxlen=1000)
        self.adaptive_enabled = True
        self.base_failure_threshold = config.failure_threshold if config else 5
        
    def _record_failure(self, call_result: CallResult, exception: Exception):
        """Enhanced failure recording with adaptation"""
        
        super()._record_failure(call_result, exception)
        
        # Record performance data
        self.performance_history.append({
            'timestamp': call_result.timestamp,
            'success': call_result.success,
            'response_time': call_result.response_time,
            'error_type': type(exception).__name__
        })
        
        # Adapt thresholds if enabled
        if self.adaptive_enabled:
            self._adapt_thresholds()
    
    def _adapt_thresholds(self):
        """Adapt failure threshold based on recent performance"""
        
        if len(self.performance_history) < 50:
            return  # Need more data
        
        recent_data = list(self.performance_history)[-50:]  # Last 50 calls
        
        # Calculate recent failure rate
        failures = sum(1 for entry in recent_data if not entry['success'])
        recent_failure_rate = failures / len(recent_data)
        
        # Calculate average response time for successful calls
        successful_calls = [entry for entry in recent_data if entry['success']]
        if successful_calls:
            avg_response_time = statistics.mean([call['response_time'] for call in successful_calls])
        else:
            avg_response_time = 0
        
        # Adapt failure threshold based on system health
        if recent_failure_rate > 0.5:  # High failure rate
            # Lower threshold to trip faster
            self.config.failure_threshold = max(2, self.base_failure_threshold - 2)
        elif recent_failure_rate < 0.1:  # Low failure rate
            # Raise threshold to be more tolerant
            self.config.failure_threshold = min(10, self.base_failure_threshold + 2)
        else:
            # Reset to base threshold
            self.config.failure_threshold = self.base_failure_threshold
        
        # Adapt recovery timeout based on response times
        if avg_response_time > 1000:  # Slow responses
            # Longer recovery timeout
            self.config.recovery_timeout = min(300, self.config.recovery_timeout * 1.5)
        elif avg_response_time < 200:  # Fast responses
            # Shorter recovery timeout
            self.config.recovery_timeout = max(10, self.config.recovery_timeout * 0.8)

class MultiLevelCircuitBreaker:
    """Circuit breaker with multiple failure levels and responses"""
    
    def __init__(self, name: str):
        self.name = name
        self.levels = {
            'warning': CircuitBreaker(f"{name}_warning", CircuitBreakerConfig(
                failure_threshold=3, recovery_timeout=30, success_threshold=2
            )),
            'critical': CircuitBreaker(f"{name}_critical", CircuitBreakerConfig(
                failure_threshold=7, recovery_timeout=60, success_threshold=3
            )),
            'emergency': CircuitBreaker(f"{name}_emergency", CircuitBreakerConfig(
                failure_threshold=10, recovery_timeout=120, success_threshold=5
            ))
        }
        
        self.current_level = 'warning'
        self.escalation_rules = {
            'warning': {'next_level': 'critical', 'condition': lambda: self._check_escalation_condition('warning')},
            'critical': {'next_level': 'emergency', 'condition': lambda: self._check_escalation_condition('critical')},
            'emergency': {'next_level': None, 'condition': lambda: False}
        }
    
    def call(self, func: Callable, *args, **kwargs) -> Any:
        """Execute call through appropriate circuit breaker level"""
        
        # Check for escalation
        self._check_escalation()
        
        # Get current circuit breaker
        current_cb = self.levels[self.current_level]
        
        try:
            return current_cb.call(func, *args, **kwargs)
        except CircuitBreakerOpenException:
            # Try degraded service if available
            return self._handle_degraded_service(*args, **kwargs)
    
    def _check_escalation_condition(self, level: str) -> bool:
        """Check if escalation condition is met"""
        cb = self.levels[level]
        metrics = cb.get_metrics()
        
        # Escalate if failure rate is high and circuit breaker is frequently opening
        return (metrics['failure_rate'] > 0.6 and 
                cb.get_state() == CircuitState.OPEN)
    
    def _check_escalation(self):
        """Check and perform escalation if needed"""
        current_rule = self.escalation_rules[self.current_level]
        
        if current_rule['next_level'] and current_rule['condition']():
            old_level = self.current_level
            self.current_level = current_rule['next_level']
            print(f"🔺 Escalated circuit breaker '{self.name}' from {old_level} to {self.current_level}")
    
    def _handle_degraded_service(self, *args, **kwargs) -> Any:
        """Handle degraded service when all circuit breakers are open"""
        
        if self.current_level == 'emergency':
            # Emergency fallback
            return {
                'status': 'emergency_fallback',
                'message': 'Service is experiencing severe issues',
                'timestamp': time.time()
            }
        else:
            # Standard fallback
            return {
                'status': 'degraded_service',
                'message': 'Service is temporarily degraded',
                'timestamp': time.time()
            }
    
    def get_overall_metrics(self) -> Dict[str, Any]:
        """Get metrics for all levels"""
        
        return {
            'current_level': self.current_level,
            'levels': {
                level: cb.get_metrics() 
                for level, cb in self.levels.items()
            }
        }

class CircuitBreakerMonitor:
    """Monitor and manage multiple circuit breakers"""
    
    def __init__(self):
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
        self.alerts: List[Dict[str, Any]] = []
        self.monitoring_enabled = True
        
        # Start monitoring thread
        self.monitor_thread = threading.Thread(target=self._monitoring_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()
    
    def register_circuit_breaker(self, circuit_breaker: CircuitBreaker):
        """Register circuit breaker for monitoring"""
        self.circuit_breakers[circuit_breaker.name] = circuit_breaker
        
        # Add state change listener
        circuit_breaker.add_state_change_listener(self._on_state_change)
    
    def _on_state_change(self, name: str, old_state: CircuitState, new_state: CircuitState):
        """Handle circuit breaker state changes"""
        
        alert = {
            'timestamp': time.time(),
            'type': 'state_change',
            'circuit_breaker': name,
            'old_state': old_state.value,
            'new_state': new_state.value,
            'severity': 'high' if new_state == CircuitState.OPEN else 'medium'
        }
        
        self.alerts.append(alert)
        
        # Keep only recent alerts
        if len(self.alerts) > 1000:
            self.alerts = self.alerts[-1000:]
    
    def _monitoring_loop(self):
        """Background monitoring loop"""
        
        while self.monitoring_enabled:
            try:
                # Check for circuit breakers that have been open too long
                current_time = time.time()
                
                for name, cb in self.circuit_breakers.items():
                    metrics = cb.get_metrics()
                    
                    if (metrics['state'] == 'open' and 
                        current_time - metrics['state_changed_time'] > 300):  # 5 minutes
                        
                        alert = {
                            'timestamp': current_time,
                            'type': 'prolonged_outage',
                            'circuit_breaker': name,
                            'duration': current_time - metrics['state_changed_time'],
                            'severity': 'critical'
                        }
                        
                        self.alerts.append(alert)
                
                time.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                print(f"Monitoring error: {e}")
                time.sleep(10)
    
    def get_dashboard_data(self) -> Dict[str, Any]:
        """Get monitoring dashboard data"""
        
        current_time = time.time()
        
        # Circuit breaker states
        states = {'closed': 0, 'open': 0, 'half_open': 0}
        unhealthy_breakers = []
        
        for name, cb in self.circuit_breakers.items():
            state = cb.get_state().value
            states[state] += 1
            
            if state in ['open', 'half_open']:
                metrics = cb.get_metrics()
                unhealthy_breakers.append({
                    'name': name,
                    'state': state,
                    'failure_rate': metrics['failure_rate'],
                    'time_in_state': current_time - metrics['state_changed_time']
                })
        
        # Recent alerts
        recent_alerts = [
            alert for alert in self.alerts 
            if current_time - alert['timestamp'] <= 3600  # Last hour
        ]
        
        return {
            'timestamp': current_time,
            'total_circuit_breakers': len(self.circuit_breakers),
            'states': states,
            'health_percentage': (states['closed'] / len(self.circuit_breakers) * 100) 
                               if self.circuit_breakers else 100,
            'unhealthy_breakers': unhealthy_breakers,
            'recent_alerts': recent_alerts[-10:],  # Last 10 alerts
            'alert_summary': {
                'total': len(recent_alerts),
                'critical': len([a for a in recent_alerts if a['severity'] == 'critical']),
                'high': len([a for a in recent_alerts if a['severity'] == 'high'])
            }
        }

# Example of advanced patterns
print("\n=== Advanced Circuit Breaker Patterns Demo ===")

# Adaptive circuit breaker
print("\n--- Adaptive Circuit Breaker ---")
adaptive_cb = AdaptiveCircuitBreaker("adaptive_service", 
                                   CircuitBreakerConfig(failure_threshold=5))

# Multi-level circuit breaker
print("\n--- Multi-Level Circuit Breaker ---")
multi_level_cb = MultiLevelCircuitBreaker("critical_service")

# Circuit breaker monitor
monitor = CircuitBreakerMonitor()
monitor.register_circuit_breaker(adaptive_cb)

# Simulate service calls with varying failure rates
def simulate_service_with_varying_failure():
    """Simulate a service with varying failure rates"""
    # Start with high failure rate, then improve
    failure_rates = [0.8, 0.6, 0.4, 0.2, 0.1]
    
    for i, failure_rate in enumerate(failure_rates):
        print(f"\n--- Phase {i+1}: {failure_rate:.0%} failure rate ---")
        
        for j in range(10):
            try:
                def unreliable_service():
                    if random.random() < failure_rate:
                        raise Exception(f"Service failure (phase {i+1})")
                    return f"Success in phase {i+1}"
                
                result = adaptive_cb.call(unreliable_service)
                print(f"  Call {j+1}: {result}")
                
            except Exception as e:
                print(f"  Call {j+1}: Failed - {e}")
            
            time.sleep(0.1)
        
        # Check adaptive threshold changes
        metrics = adaptive_cb.get_metrics()
        print(f"  Adapted failure threshold: {adaptive_cb.config.failure_threshold}")
        print(f"  Current state: {metrics['state']}")

simulate_service_with_varying_failure()

# Test multi-level circuit breaker
print("\n--- Multi-Level Circuit Breaker Test ---")

def critical_service():
    if random.random() < 0.7:  # High failure rate
        raise Exception("Critical service failure")
    return "Critical service success"

for i in range(15):
    try:
        result = multi_level_cb.call(critical_service)
        print(f"Call {i+1}: {result}")
    except Exception as e:
        print(f"Call {i+1}: {e}")
    
    time.sleep(0.1)

# Show multi-level metrics
ml_metrics = multi_level_cb.get_overall_metrics()
print(f"\nMulti-level current level: {ml_metrics['current_level']}")

# Get monitoring dashboard
dashboard = monitor.get_dashboard_data()
print(f"\n--- Monitoring Dashboard ---")
print(f"Total circuit breakers: {dashboard['total_circuit_breakers']}")
print(f"Health percentage: {dashboard['health_percentage']:.1f}%")
print(f"Circuit breaker states: {dashboard['states']}")
print(f"Recent alerts: {dashboard['alert_summary']['total']}")

monitor.monitoring_enabled = False

print("\n--- Advanced Circuit Breaker Demo Completed ---")
```

## 📚 Conclusion

The Circuit Breaker Pattern is a critical resilience pattern that prevents cascade failures and provides graceful degradation in distributed systems. From basic failure detection to sophisticated adaptive and multi-level implementations, circuit breakers are essential for building fault-tolerant systems that can handle partial failures gracefully.

**Key Takeaways:**

1. **Fail Fast**: Return errors immediately instead of waiting for timeouts
2. **Prevent Cascades**: Stop failures from spreading throughout the system
3. **Automatic Recovery**: Test service health and resume when conditions improve
4. **Graceful Degradation**: Provide fallback responses when services are unavailable
5. **Adaptive Behavior**: Adjust thresholds based on system performance patterns

The future of circuit breakers includes machine learning-powered failure prediction, integration with service meshes, and quantum-resistant implementations. Whether building microservices, distributed systems, or cloud-native applications, understanding and implementing circuit breaker patterns is essential for creating resilient, self-healing systems.

Remember: circuit breakers are not just about handling failures—they're about building systems that gracefully degrade and automatically recover, providing consistent user experiences even when underlying services are struggling.
