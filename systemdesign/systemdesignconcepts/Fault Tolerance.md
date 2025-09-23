# Fault Tolerance: Building Resilient Systems That Never Break

## 🎯 What is Fault Tolerance?

Fault tolerance is like building a bridge that remains functional even when some of its support beams fail. Just as a well-designed bridge has redundant supports and can handle the failure of individual components without collapsing, a fault-tolerant system continues to operate correctly even when some of its components fail. It's about graceful degradation rather than catastrophic failure.

## 🏗️ Core Concepts

### The Bridge Analogy Extended
- **Redundant Supports**: Multiple components performing the same function
- **Load Redistribution**: Remaining components handle extra load when others fail
- **Structural Integrity**: System maintains core functionality despite failures
- **Safety Margins**: Over-engineering to handle unexpected stress
- **Inspection Systems**: Continuous monitoring to detect weakening components

### Why Fault Tolerance Matters
1. **Business Continuity**: Keep services running despite component failures
2. **User Experience**: Prevent service disruptions and data loss
3. **Cost Efficiency**: Avoid expensive downtime and emergency repairs
4. **Reputation Protection**: Maintain trust through reliable service delivery
5. **Regulatory Compliance**: Meet availability requirements for critical systems

## 🛡️ Fundamental Fault Tolerance Patterns

### 1. Redundancy Patterns
```python
import random
import time
import threading
from typing import List, Dict, Any, Optional
from enum import Enum
from dataclasses import dataclass

class ComponentStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    FAILED = "failed"
    RECOVERING = "recovering"

@dataclass
class Component:
    id: str
    status: ComponentStatus
    load: float
    last_health_check: float
    failure_count: int = 0
    recovery_attempts: int = 0

class RedundancyManager:
    def __init__(self, component_type: str, min_healthy_components: int = 2):
        self.component_type = component_type
        self.min_healthy_components = min_healthy_components
        self.components: Dict[str, Component] = {}
        self.active_components: List[str] = []
        self.standby_components: List[str] = []
        self.request_queue = []
        self.load_balancer = LoadBalancer()
        
    def add_component(self, component_id: str, is_standby: bool = False):
        """Add component to redundancy group"""
        component = Component(
            id=component_id,
            status=ComponentStatus.HEALTHY,
            load=0.0,
            last_health_check=time.time()
        )
        
        self.components[component_id] = component
        
        if is_standby:
            self.standby_components.append(component_id)
        else:
            self.active_components.append(component_id)
            self.load_balancer.add_server(component_id)
        
        print(f"Added {component_id} as {'standby' if is_standby else 'active'} component")
    
    def handle_component_failure(self, component_id: str):
        """Handle component failure with automatic failover"""
        if component_id not in self.components:
            return False
        
        component = self.components[component_id]
        component.status = ComponentStatus.FAILED
        component.failure_count += 1
        
        print(f"Component {component_id} failed (failure #{component.failure_count})")
        
        # Remove from active components
        if component_id in self.active_components:
            self.active_components.remove(component_id)
            self.load_balancer.remove_server(component_id)
            
            # Redistribute load to remaining components
            self._redistribute_load(component_id)
        
        # Check if we need to activate standby components
        healthy_active = len([c for c in self.active_components 
                            if self.components[c].status == ComponentStatus.HEALTHY])
        
        if healthy_active < self.min_healthy_components:
            self._activate_standby_components()
        
        # Start recovery process
        self._start_component_recovery(component_id)
        
        return True
    
    def _redistribute_load(self, failed_component_id: str):
        """Redistribute load from failed component"""
        failed_component = self.components[failed_component_id]
        failed_load = failed_component.load
        
        if not self.active_components:
            print("WARNING: No active components available for load redistribution!")
            return
        
        # Distribute load evenly among remaining active components
        load_per_component = failed_load / len(self.active_components)
        
        for component_id in self.active_components:
            component = self.components[component_id]
            if component.status == ComponentStatus.HEALTHY:
                component.load += load_per_component
                print(f"Redistributed {load_per_component:.2f} load to {component_id}")
    
    def _activate_standby_components(self):
        """Activate standby components when needed"""
        needed_components = self.min_healthy_components - len(self.active_components)
        
        for _ in range(min(needed_components, len(self.standby_components))):
            standby_id = self.standby_components.pop(0)
            standby_component = self.components[standby_id]
            
            if standby_component.status == ComponentStatus.HEALTHY:
                self.active_components.append(standby_id)
                self.load_balancer.add_server(standby_id)
                print(f"Activated standby component {standby_id}")
    
    def _start_component_recovery(self, component_id: str):
        """Start recovery process for failed component"""
        def recovery_process():
            component = self.components[component_id]
            component.status = ComponentStatus.RECOVERING
            component.recovery_attempts += 1
            
            print(f"Starting recovery for {component_id} (attempt #{component.recovery_attempts})")
            
            # Simulate recovery time
            recovery_time = min(30, 5 * component.recovery_attempts)  # Exponential backoff
            time.sleep(recovery_time)
            
            # Simulate recovery success/failure
            recovery_success = random.random() > 0.3  # 70% success rate
            
            if recovery_success:
                component.status = ComponentStatus.HEALTHY
                component.load = 0.0
                component.last_health_check = time.time()
                
                # Add back to standby pool
                self.standby_components.append(component_id)
                print(f"Component {component_id} recovered successfully")
            else:
                component.status = ComponentStatus.FAILED
                print(f"Component {component_id} recovery failed")
                
                # Retry recovery if not too many attempts
                if component.recovery_attempts < 5:
                    threading.Timer(60, lambda: self._start_component_recovery(component_id)).start()
        
        # Start recovery in background thread
        recovery_thread = threading.Thread(target=recovery_process)
        recovery_thread.daemon = True
        recovery_thread.start()
    
    def get_system_health(self) -> Dict[str, Any]:
        """Get overall system health status"""
        total_components = len(self.components)
        healthy_components = len([c for c in self.components.values() 
                                if c.status == ComponentStatus.HEALTHY])
        failed_components = len([c for c in self.components.values() 
                               if c.status == ComponentStatus.FAILED])
        
        health_percentage = (healthy_components / total_components * 100) if total_components > 0 else 0
        
        return {
            'total_components': total_components,
            'healthy_components': healthy_components,
            'active_components': len(self.active_components),
            'standby_components': len(self.standby_components),
            'failed_components': failed_components,
            'health_percentage': health_percentage,
            'fault_tolerance_level': self._calculate_fault_tolerance_level(),
            'can_handle_failures': healthy_components >= self.min_healthy_components
        }
    
    def _calculate_fault_tolerance_level(self) -> str:
        """Calculate current fault tolerance level"""
        healthy_active = len([c for c in self.active_components 
                            if self.components[c].status == ComponentStatus.HEALTHY])
        total_available = healthy_active + len(self.standby_components)
        
        if total_available >= self.min_healthy_components * 2:
            return "HIGH"
        elif total_available >= self.min_healthy_components:
            return "MEDIUM"
        else:
            return "LOW"

# Example usage: Database cluster with fault tolerance
class FaultTolerantDatabase:
    def __init__(self):
        self.redundancy_manager = RedundancyManager("database", min_healthy_components=2)
        self.data_replication = DataReplicationManager()
        self.connection_pool = ConnectionPool()
        
    def setup_cluster(self):
        """Set up database cluster with redundancy"""
        # Add primary database nodes
        self.redundancy_manager.add_component("db-primary-1")
        self.redundancy_manager.add_component("db-primary-2")
        
        # Add standby nodes
        self.redundancy_manager.add_component("db-standby-1", is_standby=True)
        self.redundancy_manager.add_component("db-standby-2", is_standby=True)
        
        print("Database cluster setup complete")
    
    def execute_query(self, query: str, is_write: bool = False) -> Dict[str, Any]:
        """Execute query with fault tolerance"""
        max_retries = 3
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                # Select appropriate database node
                if is_write:
                    db_node = self._select_write_node()
                else:
                    db_node = self._select_read_node()
                
                if not db_node:
                    raise Exception("No healthy database nodes available")
                
                # Execute query
                result = self._execute_on_node(db_node, query)
                
                # Replicate write operations
                if is_write:
                    self.data_replication.replicate_write(query, result)
                
                return {
                    'success': True,
                    'result': result,
                    'executed_on': db_node,
                    'retry_count': retry_count
                }
                
            except Exception as e:
                retry_count += 1
                print(f"Query execution failed on attempt {retry_count}: {e}")
                
                if retry_count < max_retries:
                    # Mark node as potentially failed
                    if 'db_node' in locals():
                        self._handle_node_error(db_node, str(e))
                    
                    # Wait before retry with exponential backoff
                    time.sleep(2 ** retry_count)
                else:
                    return {
                        'success': False,
                        'error': str(e),
                        'retry_count': retry_count
                    }
    
    def _select_write_node(self) -> Optional[str]:
        """Select healthy node for write operations"""
        active_nodes = self.redundancy_manager.active_components
        
        for node_id in active_nodes:
            node = self.redundancy_manager.components[node_id]
            if node.status == ComponentStatus.HEALTHY and node.load < 0.8:
                return node_id
        
        return None
    
    def _handle_node_error(self, node_id: str, error: str):
        """Handle database node error"""
        # Classify error severity
        if "connection refused" in error.lower() or "timeout" in error.lower():
            # Likely node failure
            self.redundancy_manager.handle_component_failure(node_id)
        else:
            # Temporary error, mark as degraded
            node = self.redundancy_manager.components[node_id]
            node.status = ComponentStatus.DEGRADED

# Usage example
ft_database = FaultTolerantDatabase()
ft_database.setup_cluster()

# Simulate normal operations
for i in range(10):
    result = ft_database.execute_query(f"SELECT * FROM users WHERE id = {i}")
    if result['success']:
        print(f"Query {i} executed successfully on {result['executed_on']}")
    else:
        print(f"Query {i} failed: {result['error']}")

# Simulate node failure
ft_database.redundancy_manager.handle_component_failure("db-primary-1")

# Check system health
health = ft_database.redundancy_manager.get_system_health()
print(f"System Health: {health['health_percentage']:.1f}% ({health['fault_tolerance_level']} tolerance)")
```

### 2. Circuit Breaker Pattern
```python
class CircuitBreakerState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Blocking requests
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60, 
                 success_threshold: int = 3):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.success_threshold = success_threshold
        
        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time = None
        self.call_history = []
        
    def call(self, func, *args, **kwargs):
        """Execute function call through circuit breaker"""
        
        if self.state == CircuitBreakerState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitBreakerState.HALF_OPEN
                print("Circuit breaker transitioning to HALF_OPEN")
            else:
                raise CircuitBreakerOpenException(
                    f"Circuit breaker is OPEN. Last failure: {self.last_failure_time}"
                )
        
        try:
            start_time = time.time()
            result = func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            self._record_success(execution_time)
            return result
            
        except Exception as e:
            self._record_failure(str(e))
            raise e
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if self.last_failure_time is None:
            return True
        
        return time.time() - self.last_failure_time >= self.recovery_timeout
    
    def _record_success(self, execution_time: float):
        """Record successful call"""
        self.call_history.append({
            'timestamp': time.time(),
            'success': True,
            'execution_time': execution_time
        })
        
        if self.state == CircuitBreakerState.HALF_OPEN:
            self.success_count += 1
            
            if self.success_count >= self.success_threshold:
                self.state = CircuitBreakerState.CLOSED
                self.failure_count = 0
                self.success_count = 0
                print("Circuit breaker CLOSED - service recovered")
        else:
            self.failure_count = max(0, self.failure_count - 1)  # Gradually reduce failure count
    
    def _record_failure(self, error: str):
        """Record failed call"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        self.call_history.append({
            'timestamp': time.time(),
            'success': False,
            'error': error
        })
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitBreakerState.OPEN
            self.success_count = 0
            print(f"Circuit breaker OPENED after {self.failure_count} failures")
    
    def get_metrics(self) -> Dict[str, Any]:
        """Get circuit breaker metrics"""
        recent_calls = [call for call in self.call_history 
                       if time.time() - call['timestamp'] <= 300]  # Last 5 minutes
        
        if not recent_calls:
            return {
                'state': self.state.value,
                'failure_count': self.failure_count,
                'success_rate': 0,
                'avg_response_time': 0,
                'total_calls': len(self.call_history)
            }
        
        successful_calls = [call for call in recent_calls if call['success']]
        success_rate = len(successful_calls) / len(recent_calls) * 100
        
        if successful_calls:
            avg_response_time = sum(call.get('execution_time', 0) 
                                  for call in successful_calls) / len(successful_calls)
        else:
            avg_response_time = 0
        
        return {
            'state': self.state.value,
            'failure_count': self.failure_count,
            'success_rate': success_rate,
            'avg_response_time': avg_response_time * 1000,  # Convert to ms
            'recent_calls': len(recent_calls),
            'total_calls': len(self.call_history)
        }

class CircuitBreakerOpenException(Exception):
    pass

# Example: External API client with circuit breaker
class ExternalAPIClient:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=3,
            recovery_timeout=30,
            success_threshold=2
        )
        self.fallback_cache = {}
    
    def make_api_call(self, endpoint: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        """Make API call with circuit breaker protection"""
        
        def api_request():
            # Simulate API call
            if random.random() < 0.3:  # 30% failure rate for demonstration
                raise Exception("API service unavailable")
            
            # Simulate response
            return {
                'data': f'Response from {endpoint}',
                'timestamp': time.time(),
                'params': params
            }
        
        try:
            result = self.circuit_breaker.call(api_request)
            
            # Cache successful response for fallback
            cache_key = f"{endpoint}:{hash(str(params))}"
            self.fallback_cache[cache_key] = result
            
            return result
            
        except CircuitBreakerOpenException:
            # Circuit breaker is open, use fallback
            return self._get_fallback_response(endpoint, params)
        except Exception as e:
            # Other errors, try fallback
            fallback = self._get_fallback_response(endpoint, params)
            if fallback:
                return fallback
            else:
                raise e
    
    def _get_fallback_response(self, endpoint: str, params: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Get fallback response from cache"""
        cache_key = f"{endpoint}:{hash(str(params))}"
        cached_response = self.fallback_cache.get(cache_key)
        
        if cached_response:
            return {
                **cached_response,
                'from_cache': True,
                'cache_timestamp': cached_response.get('timestamp')
            }
        
        # Return default fallback
        return {
            'data': f'Fallback response for {endpoint}',
            'fallback': True,
            'timestamp': time.time()
        }

# Usage example
api_client = ExternalAPIClient("https://api.example.com")

# Make API calls and observe circuit breaker behavior
for i in range(20):
    try:
        response = api_client.make_api_call(f"/users/{i}")
        print(f"Call {i}: {'SUCCESS' if not response.get('fallback') else 'FALLBACK'}")
        
        # Print circuit breaker metrics every 5 calls
        if i % 5 == 0:
            metrics = api_client.circuit_breaker.get_metrics()
            print(f"  CB State: {metrics['state']}, Success Rate: {metrics['success_rate']:.1f}%")
    
    except Exception as e:
        print(f"Call {i}: ERROR - {e}")
    
    time.sleep(0.1)  # Brief pause between calls
```

### 3. Bulkhead Pattern
```python
class ResourcePool:
    def __init__(self, pool_name: str, max_size: int):
        self.pool_name = pool_name
        self.max_size = max_size
        self.active_resources = 0
        self.queue = []
        self.usage_stats = {
            'total_requests': 0,
            'successful_acquisitions': 0,
            'timeouts': 0,
            'peak_usage': 0
        }
        self.lock = threading.Lock()
    
    def acquire_resource(self, timeout: float = 10.0) -> bool:
        """Acquire resource from pool"""
        with self.lock:
            self.usage_stats['total_requests'] += 1
            
            if self.active_resources < self.max_size:
                self.active_resources += 1
                self.usage_stats['successful_acquisitions'] += 1
                self.usage_stats['peak_usage'] = max(self.usage_stats['peak_usage'], 
                                                   self.active_resources)
                return True
            else:
                # Pool exhausted
                self.usage_stats['timeouts'] += 1
                return False
    
    def release_resource(self):
        """Release resource back to pool"""
        with self.lock:
            if self.active_resources > 0:
                self.active_resources -= 1
    
    def get_utilization(self) -> float:
        """Get current pool utilization percentage"""
        return (self.active_resources / self.max_size) * 100 if self.max_size > 0 else 0
    
    def get_stats(self) -> Dict[str, Any]:
        """Get pool statistics"""
        return {
            'pool_name': self.pool_name,
            'max_size': self.max_size,
            'active_resources': self.active_resources,
            'utilization_percentage': self.get_utilization(),
            'usage_stats': self.usage_stats.copy()
        }

class BulkheadManager:
    def __init__(self):
        self.resource_pools: Dict[str, ResourcePool] = {}
        self.service_mappings: Dict[str, str] = {}  # service -> pool_name
    
    def create_bulkhead(self, pool_name: str, max_resources: int):
        """Create isolated resource pool (bulkhead)"""
        self.resource_pools[pool_name] = ResourcePool(pool_name, max_resources)
        print(f"Created bulkhead '{pool_name}' with {max_resources} resources")
    
    def assign_service_to_bulkhead(self, service_name: str, pool_name: str):
        """Assign service to specific bulkhead"""
        if pool_name not in self.resource_pools:
            raise ValueError(f"Bulkhead '{pool_name}' does not exist")
        
        self.service_mappings[service_name] = pool_name
        print(f"Assigned service '{service_name}' to bulkhead '{pool_name}'")
    
    def execute_with_bulkhead(self, service_name: str, func, *args, **kwargs):
        """Execute function within service's bulkhead"""
        
        pool_name = self.service_mappings.get(service_name)
        if not pool_name:
            raise ValueError(f"Service '{service_name}' not assigned to any bulkhead")
        
        pool = self.resource_pools[pool_name]
        
        # Try to acquire resource
        if pool.acquire_resource():
            try:
                start_time = time.time()
                result = func(*args, **kwargs)
                execution_time = time.time() - start_time
                
                return {
                    'success': True,
                    'result': result,
                    'execution_time': execution_time,
                    'pool_used': pool_name
                }
            finally:
                pool.release_resource()
        else:
            # Resource pool exhausted
            return {
                'success': False,
                'error': f'Resource pool {pool_name} exhausted',
                'pool_utilization': pool.get_utilization()
            }
    
    def get_system_health(self) -> Dict[str, Any]:
        """Get overall bulkhead system health"""
        
        pool_stats = {}
        total_utilization = 0
        
        for pool_name, pool in self.resource_pools.items():
            stats = pool.get_stats()
            pool_stats[pool_name] = stats
            total_utilization += stats['utilization_percentage']
        
        avg_utilization = total_utilization / len(self.resource_pools) if self.resource_pools else 0
        
        return {
            'total_bulkheads': len(self.resource_pools),
            'average_utilization': avg_utilization,
            'pool_details': pool_stats,
            'service_assignments': self.service_mappings.copy()
        }

# Example: Web application with bulkhead isolation
class WebApplicationWithBulkheads:
    def __init__(self):
        self.bulkhead_manager = BulkheadManager()
        self.setup_bulkheads()
    
    def setup_bulkheads(self):
        """Set up resource isolation bulkheads"""
        
        # Create separate resource pools for different service types
        self.bulkhead_manager.create_bulkhead('critical_services', 20)    # High priority
        self.bulkhead_manager.create_bulkhead('standard_services', 30)    # Normal priority
        self.bulkhead_manager.create_bulkhead('background_services', 10)  # Low priority
        self.bulkhead_manager.create_bulkhead('external_apis', 15)        # External calls
        
        # Assign services to bulkheads
        self.bulkhead_manager.assign_service_to_bulkhead('user_authentication', 'critical_services')
        self.bulkhead_manager.assign_service_to_bulkhead('payment_processing', 'critical_services')
        self.bulkhead_manager.assign_service_to_bulkhead('order_management', 'standard_services')
        self.bulkhead_manager.assign_service_to_bulkhead('product_catalog', 'standard_services')
        self.bulkhead_manager.assign_service_to_bulkhead('analytics_reporting', 'background_services')
        self.bulkhead_manager.assign_service_to_bulkhead('email_notifications', 'background_services')
        self.bulkhead_manager.assign_service_to_bulkhead('third_party_apis', 'external_apis')
    
    def process_user_request(self, request_type: str, user_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process user request using appropriate bulkhead"""
        
        def simulate_service_call():
            # Simulate service processing time
            processing_time = random.uniform(0.1, 2.0)
            time.sleep(processing_time)
            
            # Simulate occasional failures
            if random.random() < 0.1:  # 10% failure rate
                raise Exception(f"Service error in {request_type}")
            
            return f"Processed {request_type} for user {user_data.get('user_id', 'unknown')}"
        
        try:
            result = self.bulkhead_manager.execute_with_bulkhead(
                request_type, simulate_service_call
            )
            
            if result['success']:
                return {
                    'status': 'success',
                    'data': result['result'],
                    'processing_time': result['execution_time'],
                    'bulkhead_used': result['pool_used']
                }
            else:
                return {
                    'status': 'resource_exhausted',
                    'error': result['error'],
                    'pool_utilization': result.get('pool_utilization', 0)
                }
                
        except Exception as e:
            return {
                'status': 'service_error',
                'error': str(e)
            }

# Usage example and load testing
web_app = WebApplicationWithBulkheads()

# Simulate concurrent requests
import concurrent.futures

def simulate_user_request(request_id: int):
    request_types = ['user_authentication', 'payment_processing', 'order_management', 
                    'product_catalog', 'analytics_reporting', 'third_party_apis']
    
    request_type = random.choice(request_types)
    user_data = {'user_id': f'user_{request_id}'}
    
    result = web_app.process_user_request(request_type, user_data)
    
    return {
        'request_id': request_id,
        'request_type': request_type,
        'result': result
    }

# Run load test with concurrent requests
print("Starting bulkhead load test...")

with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
    # Submit 100 concurrent requests
    futures = [executor.submit(simulate_user_request, i) for i in range(100)]
    
    results = []
    for future in concurrent.futures.as_completed(futures):
        try:
            result = future.result()
            results.append(result)
        except Exception as e:
            print(f"Request failed: {e}")

# Analyze results
success_count = len([r for r in results if r['result']['status'] == 'success'])
resource_exhausted = len([r for r in results if r['result']['status'] == 'resource_exhausted'])
service_errors = len([r for r in results if r['result']['status'] == 'service_error'])

print(f"\nLoad Test Results:")
print(f"Total requests: {len(results)}")
print(f"Successful: {success_count}")
print(f"Resource exhausted: {resource_exhausted}")
print(f"Service errors: {service_errors}")

# Check bulkhead health
health = web_app.bulkhead_manager.get_system_health()
print(f"\nBulkhead System Health:")
print(f"Average utilization: {health['average_utilization']:.1f}%")

for pool_name, stats in health['pool_details'].items():
    print(f"{pool_name}: {stats['utilization_percentage']:.1f}% utilized, "
          f"{stats['usage_stats']['successful_acquisitions']}/{stats['usage_stats']['total_requests']} successful")
```

## 📊 Fault Tolerance Monitoring and Metrics

```python
class FaultToleranceMonitor:
    def __init__(self):
        self.failure_events = []
        self.recovery_events = []
        self.system_metrics = {
            'mtbf': 0,  # Mean Time Between Failures
            'mttr': 0,  # Mean Time To Recovery
            'availability': 0,
            'fault_tolerance_score': 0
        }
        self.component_health = {}
        
    def record_failure_event(self, component_id: str, failure_type: str, 
                           severity: str, metadata: Dict[str, Any] = None):
        """Record system failure event"""
        
        failure_event = {
            'component_id': component_id,
            'failure_type': failure_type,
            'severity': severity,  # 'low', 'medium', 'high', 'critical'
            'timestamp': time.time(),
            'metadata': metadata or {}
        }
        
        self.failure_events.append(failure_event)
        
        # Update component health
        if component_id not in self.component_health:
            self.component_health[component_id] = {
                'failure_count': 0,
                'last_failure': None,
                'status': 'healthy'
            }
        
        self.component_health[component_id]['failure_count'] += 1
        self.component_health[component_id]['last_failure'] = time.time()
        self.component_health[component_id]['status'] = 'failed'
        
        print(f"Failure recorded: {component_id} - {failure_type} ({severity})")
    
    def record_recovery_event(self, component_id: str, recovery_method: str,
                            recovery_time: float, metadata: Dict[str, Any] = None):
        """Record system recovery event"""
        
        recovery_event = {
            'component_id': component_id,
            'recovery_method': recovery_method,
            'recovery_time': recovery_time,
            'timestamp': time.time(),
            'metadata': metadata or {}
        }
        
        self.recovery_events.append(recovery_event)
        
        # Update component health
        if component_id in self.component_health:
            self.component_health[component_id]['status'] = 'recovered'
        
        print(f"Recovery recorded: {component_id} - {recovery_method} ({recovery_time:.2f}s)")
    
    def calculate_mtbf(self, component_id: str = None) -> float:
        """Calculate Mean Time Between Failures"""
        
        if component_id:
            failures = [f for f in self.failure_events if f['component_id'] == component_id]
        else:
            failures = self.failure_events
        
        if len(failures) < 2:
            return float('inf')
        
        # Calculate time intervals between failures
        failure_times = sorted([f['timestamp'] for f in failures])
        intervals = []
        
        for i in range(1, len(failure_times)):
            interval = failure_times[i] - failure_times[i-1]
            intervals.append(interval)
        
        return sum(intervals) / len(intervals) / 3600  # Convert to hours
    
    def calculate_mttr(self, component_id: str = None) -> float:
        """Calculate Mean Time To Recovery"""
        
        if component_id:
            recoveries = [r for r in self.recovery_events if r['component_id'] == component_id]
        else:
            recoveries = self.recovery_events
        
        if not recoveries:
            return 0
        
        total_recovery_time = sum(r['recovery_time'] for r in recoveries)
        return total_recovery_time / len(recoveries) / 60  # Convert to minutes
    
    def calculate_availability(self, time_window_hours: float = 24) -> float:
        """Calculate system availability percentage"""
        
        current_time = time.time()
        window_start = current_time - (time_window_hours * 3600)
        
        # Get failures and recoveries within time window
        window_failures = [f for f in self.failure_events if f['timestamp'] >= window_start]
        window_recoveries = [r for r in self.recovery_events if r['timestamp'] >= window_start]
        
        total_downtime = 0
        
        # Calculate downtime for each failure
        for failure in window_failures:
            failure_time = failure['timestamp']
            component_id = failure['component_id']
            
            # Find corresponding recovery
            recovery = next((r for r in window_recoveries 
                           if r['component_id'] == component_id and r['timestamp'] > failure_time), 
                          None)
            
            if recovery:
                downtime = recovery['timestamp'] - failure_time
            else:
                # Still down
                downtime = current_time - failure_time
            
            total_downtime += downtime
        
        total_time = time_window_hours * 3600
        uptime = total_time - total_downtime
        
        return (uptime / total_time) * 100 if total_time > 0 else 100
    
    def calculate_fault_tolerance_score(self) -> float:
        """Calculate overall fault tolerance score (0-100)"""
        
        score = 100
        
        # Factor 1: Availability (40% weight)
        availability = self.calculate_availability()
        availability_score = availability * 0.4
        
        # Factor 2: Recovery capability (30% weight)
        mttr = self.calculate_mttr()
        if mttr > 0:
            # Better score for faster recovery (inverse relationship)
            recovery_score = max(0, 30 - (mttr / 10))  # Penalize slow recovery
        else:
            recovery_score = 30
        
        # Factor 3: Failure frequency (20% weight)
        mtbf = self.calculate_mtbf()
        if mtbf != float('inf'):
            # Better score for less frequent failures
            frequency_score = min(20, mtbf / 10)  # Max 20 points
        else:
            frequency_score = 20
        
        # Factor 4: Component diversity (10% weight)
        unique_components = len(set(f['component_id'] for f in self.failure_events))
        total_components = len(self.component_health)
        
        if total_components > 0:
            diversity_score = 10 * (1 - (unique_components / total_components))
        else:
            diversity_score = 10
        
        total_score = availability_score + recovery_score + frequency_score + diversity_score
        
        return min(100, max(0, total_score))
    
    def generate_fault_tolerance_report(self) -> Dict[str, Any]:
        """Generate comprehensive fault tolerance report"""
        
        report = {
            'timestamp': time.time(),
            'summary': {
                'total_failures': len(self.failure_events),
                'total_recoveries': len(self.recovery_events),
                'mtbf_hours': self.calculate_mtbf(),
                'mttr_minutes': self.calculate_mttr(),
                'availability_24h': self.calculate_availability(24),
                'fault_tolerance_score': self.calculate_fault_tolerance_score()
            },
            'component_analysis': {},
            'failure_patterns': self._analyze_failure_patterns(),
            'recommendations': []
        }
        
        # Analyze each component
        for component_id, health_info in self.component_health.items():
            component_mtbf = self.calculate_mtbf(component_id)
            component_mttr = self.calculate_mttr(component_id)
            
            report['component_analysis'][component_id] = {
                'failure_count': health_info['failure_count'],
                'current_status': health_info['status'],
                'mtbf_hours': component_mtbf,
                'mttr_minutes': component_mttr,
                'last_failure': health_info.get('last_failure')
            }
        
        # Generate recommendations
        report['recommendations'] = self._generate_recommendations(report)
        
        return report
    
    def _analyze_failure_patterns(self) -> Dict[str, Any]:
        """Analyze failure patterns and trends"""
        
        patterns = {
            'by_severity': {},
            'by_type': {},
            'by_time_of_day': {},
            'cascade_failures': 0
        }
        
        # Analyze by severity
        for failure in self.failure_events:
            severity = failure['severity']
            patterns['by_severity'][severity] = patterns['by_severity'].get(severity, 0) + 1
        
        # Analyze by type
        for failure in self.failure_events:
            failure_type = failure['failure_type']
            patterns['by_type'][failure_type] = patterns['by_type'].get(failure_type, 0) + 1
        
        # Analyze cascade failures (multiple failures within short time)
        sorted_failures = sorted(self.failure_events, key=lambda x: x['timestamp'])
        cascade_threshold = 300  # 5 minutes
        
        for i in range(1, len(sorted_failures)):
            if sorted_failures[i]['timestamp'] - sorted_failures[i-1]['timestamp'] <= cascade_threshold:
                patterns['cascade_failures'] += 1
        
        return patterns
    
    def _generate_recommendations(self, report: Dict[str, Any]) -> List[str]:
        """Generate recommendations based on analysis"""
        
        recommendations = []
        
        # Availability recommendations
        if report['summary']['availability_24h'] < 99.9:
            recommendations.append("Consider implementing additional redundancy to improve availability")
        
        # MTTR recommendations
        if report['summary']['mttr_minutes'] > 15:
            recommendations.append("Improve automated recovery mechanisms to reduce MTTR")
        
        # Component-specific recommendations
        for component_id, analysis in report['component_analysis'].items():
            if analysis['failure_count'] > 5:
                recommendations.append(f"Investigate {component_id} - high failure count ({analysis['failure_count']})")
            
            if analysis['mttr_minutes'] > 30:
                recommendations.append(f"Improve recovery process for {component_id} - slow recovery time")
        
        # Pattern-based recommendations
        patterns = report['failure_patterns']
        if patterns['cascade_failures'] > 0:
            recommendations.append("Implement circuit breakers to prevent cascade failures")
        
        return recommendations

# Usage example
monitor = FaultToleranceMonitor()

# Simulate failure and recovery events
components = ['web-server-1', 'web-server-2', 'database-primary', 'cache-redis', 'load-balancer']
failure_types = ['hardware_failure', 'network_timeout', 'memory_exhaustion', 'disk_full', 'software_crash']
severities = ['low', 'medium', 'high', 'critical']

# Simulate some failures and recoveries over time
for i in range(20):
    component = random.choice(components)
    failure_type = random.choice(failure_types)
    severity = random.choice(severities)
    
    # Record failure
    monitor.record_failure_event(component, failure_type, severity)
    
    # Simulate recovery after some time
    recovery_time = random.uniform(30, 600)  # 30 seconds to 10 minutes
    recovery_method = random.choice(['automatic_restart', 'manual_intervention', 'failover'])
    
    time.sleep(0.1)  # Brief pause
    monitor.record_recovery_event(component, recovery_method, recovery_time)

# Generate fault tolerance report
ft_report = monitor.generate_fault_tolerance_report()

print("=== Fault Tolerance Report ===")
print(f"Fault Tolerance Score: {ft_report['summary']['fault_tolerance_score']:.1f}/100")
print(f"Availability (24h): {ft_report['summary']['availability_24h']:.3f}%")
print(f"MTBF: {ft_report['summary']['mtbf_hours']:.1f} hours")
print(f"MTTR: {ft_report['summary']['mttr_minutes']:.1f} minutes")

print(f"\nFailure Patterns:")
for pattern_type, data in ft_report['failure_patterns'].items():
    if isinstance(data, dict):
        print(f"  {pattern_type}: {data}")
    else:
        print(f"  {pattern_type}: {data}")

print(f"\nRecommendations:")
for recommendation in ft_report['recommendations']:
    print(f"  - {recommendation}")
```

## 📚 Conclusion

Fault tolerance is not just about preventing failures—it's about building systems that gracefully handle inevitable failures and continue providing value to users. From redundancy and circuit breakers to bulkhead patterns and comprehensive monitoring, fault tolerance requires a multi-layered approach that considers both technical and operational aspects.

**Key Takeaways:**

1. **Assume Failures Will Happen**: Design systems expecting component failures rather than hoping they won't occur
2. **Implement Multiple Patterns**: Combine redundancy, circuit breakers, and bulkheads for comprehensive protection
3. **Monitor and Measure**: Track MTBF, MTTR, and availability to understand system resilience
4. **Practice Failure Scenarios**: Use chaos engineering to test fault tolerance mechanisms
5. **Plan Recovery Processes**: Automated recovery is ideal, but have manual procedures as backup

The future of fault tolerance includes AI-powered predictive failure detection, self-healing systems that automatically adapt to changing conditions, and quantum-resistant security measures. Whether you're building a simple web application or a mission-critical distributed system, understanding and implementing fault tolerance patterns is essential for creating systems that users can depend on.

Remember: fault tolerance is an investment in reliability that pays dividends through reduced downtime, improved user experience, and lower operational costs. Build it in from the beginning rather than retrofitting it later.
