# Bulkhead Pattern: Resource Isolation and Fault Containment

## 🎯 What is the Bulkhead Pattern?

The Bulkhead Pattern is like the watertight compartments in a ship's hull that prevent the entire vessel from sinking if one section is breached. Just as these compartments isolate water damage to a single area, the bulkhead pattern isolates different parts of a system so that failure in one component doesn't bring down the entire system. It's about creating boundaries that contain failures and protect critical resources.

## 🏗️ Core Concepts

### The Ship Compartment Analogy
- **Watertight Compartments**: Isolated sections that can be sealed off
- **Critical Systems**: Essential ship functions that must remain operational
- **Resource Allocation**: Each compartment has dedicated resources
- **Failure Containment**: Damage in one compartment doesn't affect others
- **Controlled Flooding**: Allow non-critical areas to fail to save the ship
- **Emergency Protocols**: Procedures for isolating damaged sections

### Why Bulkhead Pattern Matters
1. **Fault Isolation**: Prevent failures from spreading across system boundaries
2. **Resource Protection**: Preserve critical resources for essential operations
3. **Performance Isolation**: Prevent resource contention between components
4. **Graceful Degradation**: Allow non-critical features to fail while maintaining core functionality
5. **Predictable Behavior**: Ensure system behavior remains consistent under load

## 🚢 Bulkhead Implementation

```python
import time
import threading
from typing import Dict, List, Optional, Any, Callable
from enum import Enum
from dataclasses import dataclass
from collections import defaultdict, deque
import queue
import concurrent.futures
from abc import ABC, abstractmethod

class BulkheadType(Enum):
    THREAD_POOL = "thread_pool"
    CONNECTION_POOL = "connection_pool"
    MEMORY_POOL = "memory_pool"
    CPU_QUOTA = "cpu_quota"
    RATE_LIMIT = "rate_limit"

class ResourceState(Enum):
    AVAILABLE = "available"
    ALLOCATED = "allocated"
    EXHAUSTED = "exhausted"
    DEGRADED = "degraded"

@dataclass
class ResourceQuota:
    max_size: int
    current_usage: int
    reserved_for_critical: int
    warning_threshold: float = 0.8
    critical_threshold: float = 0.95

class BulkheadResource(ABC):
    """Abstract base class for bulkhead resources"""
    
    def __init__(self, name: str, max_capacity: int):
        self.name = name
        self.max_capacity = max_capacity
        self.current_usage = 0
        self.state = ResourceState.AVAILABLE
        self.allocations: Dict[str, int] = {}
        self.lock = threading.RLock()
        
    @abstractmethod
    def acquire(self, consumer_id: str, amount: int = 1) -> bool:
        """Acquire resource"""
        pass
    
    @abstractmethod
    def release(self, consumer_id: str, amount: int = 1) -> bool:
        """Release resource"""
        pass
    
    def get_utilization(self) -> float:
        """Get resource utilization percentage"""
        return (self.current_usage / self.max_capacity) * 100 if self.max_capacity > 0 else 0
    
    def get_available_capacity(self) -> int:
        """Get available capacity"""
        return max(0, self.max_capacity - self.current_usage)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get resource statistics"""
        return {
            'name': self.name,
            'max_capacity': self.max_capacity,
            'current_usage': self.current_usage,
            'available_capacity': self.get_available_capacity(),
            'utilization_percent': self.get_utilization(),
            'state': self.state.value,
            'active_consumers': len(self.allocations),
            'allocations': self.allocations.copy()
        }

class ThreadPoolBulkhead(BulkheadResource):
    """Thread pool bulkhead for isolating concurrent operations"""
    
    def __init__(self, name: str, max_threads: int):
        super().__init__(name, max_threads)
        self.executor = concurrent.futures.ThreadPoolExecutor(max_workers=max_threads)
        self.active_futures: Dict[str, List[concurrent.futures.Future]] = defaultdict(list)
        
    def acquire(self, consumer_id: str, amount: int = 1) -> bool:
        """Acquire threads for consumer"""
        with self.lock:
            if self.current_usage + amount <= self.max_capacity:
                self.current_usage += amount
                self.allocations[consumer_id] = self.allocations.get(consumer_id, 0) + amount
                return True
            return False
    
    def release(self, consumer_id: str, amount: int = 1) -> bool:
        """Release threads from consumer"""
        with self.lock:
            if consumer_id in self.allocations and self.allocations[consumer_id] >= amount:
                self.allocations[consumer_id] -= amount
                self.current_usage -= amount
                
                if self.allocations[consumer_id] == 0:
                    del self.allocations[consumer_id]
                
                return True
            return False
    
    def submit_task(self, consumer_id: str, task: Callable, *args, **kwargs) -> Optional[concurrent.futures.Future]:
        """Submit task to thread pool"""
        
        if not self.acquire(consumer_id):
            return None
        
        try:
            future = self.executor.submit(self._execute_with_cleanup, consumer_id, task, *args, **kwargs)
            self.active_futures[consumer_id].append(future)
            return future
        except Exception:
            self.release(consumer_id)
            return None
    
    def _execute_with_cleanup(self, consumer_id: str, task: Callable, *args, **kwargs):
        """Execute task and cleanup resources"""
        try:
            result = task(*args, **kwargs)
            return result
        finally:
            self.release(consumer_id)
            # Remove completed future
            if consumer_id in self.active_futures:
                self.active_futures[consumer_id] = [
                    f for f in self.active_futures[consumer_id] if not f.done()
                ]

class ConnectionPoolBulkhead(BulkheadResource):
    """Connection pool bulkhead for database/service connections"""
    
    def __init__(self, name: str, max_connections: int):
        super().__init__(name, max_connections)
        self.connections: queue.Queue = queue.Queue(maxsize=max_connections)
        self.active_connections: Dict[str, List[Any]] = defaultdict(list)
        
        # Initialize connection pool
        for i in range(max_connections):
            # Mock connection object
            connection = MockConnection(f"{name}_conn_{i}")
            self.connections.put(connection)
    
    def acquire(self, consumer_id: str, amount: int = 1) -> bool:
        """Acquire connections for consumer"""
        acquired_connections = []
        
        try:
            for _ in range(amount):
                connection = self.connections.get_nowait()
                acquired_connections.append(connection)
            
            with self.lock:
                self.active_connections[consumer_id].extend(acquired_connections)
                self.current_usage += amount
                self.allocations[consumer_id] = self.allocations.get(consumer_id, 0) + amount
            
            return True
            
        except queue.Empty:
            # Return any acquired connections
            for conn in acquired_connections:
                self.connections.put(conn)
            return False
    
    def release(self, consumer_id: str, amount: int = 1) -> bool:
        """Release connections from consumer"""
        with self.lock:
            if consumer_id not in self.active_connections:
                return False
            
            consumer_connections = self.active_connections[consumer_id]
            
            if len(consumer_connections) < amount:
                return False
            
            # Release connections back to pool
            for _ in range(amount):
                connection = consumer_connections.pop()
                self.connections.put(connection)
            
            self.current_usage -= amount
            self.allocations[consumer_id] -= amount
            
            if self.allocations[consumer_id] == 0:
                del self.allocations[consumer_id]
                del self.active_connections[consumer_id]
            
            return True
    
    def get_connection(self, consumer_id: str, timeout: float = 1.0) -> Optional[Any]:
        """Get a connection for consumer"""
        
        if self.acquire(consumer_id):
            return self.active_connections[consumer_id][-1]
        return None

class MockConnection:
    """Mock connection for demonstration"""
    
    def __init__(self, connection_id: str):
        self.connection_id = connection_id
        self.created_at = time.time()
        self.last_used = time.time()
    
    def execute(self, query: str) -> Dict[str, Any]:
        """Mock query execution"""
        self.last_used = time.time()
        time.sleep(0.1)  # Simulate query time
        
        return {
            'connection_id': self.connection_id,
            'query': query,
            'result': f'Result for {query}',
            'execution_time': 0.1
        }

class MemoryPoolBulkhead(BulkheadResource):
    """Memory pool bulkhead for memory allocation isolation"""
    
    def __init__(self, name: str, max_memory_mb: int):
        super().__init__(name, max_memory_mb)
        self.memory_allocations: Dict[str, List[Dict[str, Any]]] = defaultdict(list)
    
    def acquire(self, consumer_id: str, amount: int = 1) -> bool:
        """Acquire memory for consumer (amount in MB)"""
        with self.lock:
            if self.current_usage + amount <= self.max_capacity:
                allocation = {
                    'size_mb': amount,
                    'allocated_at': time.time(),
                    'allocation_id': f"{consumer_id}_{len(self.memory_allocations[consumer_id])}"
                }
                
                self.memory_allocations[consumer_id].append(allocation)
                self.current_usage += amount
                self.allocations[consumer_id] = self.allocations.get(consumer_id, 0) + amount
                
                return True
            return False
    
    def release(self, consumer_id: str, amount: int = 1) -> bool:
        """Release memory from consumer"""
        with self.lock:
            if consumer_id not in self.memory_allocations:
                return False
            
            consumer_allocations = self.memory_allocations[consumer_id]
            
            # Find allocations to release
            released_amount = 0
            allocations_to_remove = []
            
            for i, allocation in enumerate(consumer_allocations):
                if released_amount + allocation['size_mb'] <= amount:
                    released_amount += allocation['size_mb']
                    allocations_to_remove.append(i)
                    
                    if released_amount == amount:
                        break
            
            if released_amount == 0:
                return False
            
            # Remove allocations
            for i in reversed(allocations_to_remove):
                consumer_allocations.pop(i)
            
            self.current_usage -= released_amount
            self.allocations[consumer_id] -= released_amount
            
            if self.allocations[consumer_id] == 0:
                del self.allocations[consumer_id]
                del self.memory_allocations[consumer_id]
            
            return True

class BulkheadManager:
    """Manager for multiple bulkhead resources"""
    
    def __init__(self):
        self.bulkheads: Dict[str, BulkheadResource] = {}
        self.service_allocations: Dict[str, Dict[str, int]] = defaultdict(dict)
        self.monitoring_enabled = True
        self.metrics_history: deque = deque(maxlen=1000)
        
        # Start monitoring thread
        self.monitor_thread = threading.Thread(target=self._monitoring_loop)
        self.monitor_thread.daemon = True
        self.monitor_thread.start()
    
    def add_bulkhead(self, bulkhead: BulkheadResource):
        """Add bulkhead resource to manager"""
        self.bulkheads[bulkhead.name] = bulkhead
        print(f"Added bulkhead: {bulkhead.name} (capacity: {bulkhead.max_capacity})")
    
    def allocate_resources(self, service_name: str, resource_requirements: Dict[str, int]) -> Dict[str, bool]:
        """Allocate resources for a service"""
        
        results = {}
        allocated_resources = {}
        
        try:
            # Try to allocate all required resources
            for resource_name, amount in resource_requirements.items():
                if resource_name in self.bulkheads:
                    bulkhead = self.bulkheads[resource_name]
                    
                    if bulkhead.acquire(service_name, amount):
                        allocated_resources[resource_name] = amount
                        results[resource_name] = True
                    else:
                        results[resource_name] = False
                        raise ResourceAllocationException(f"Failed to allocate {resource_name}")
                else:
                    results[resource_name] = False
                    raise ResourceAllocationException(f"Unknown resource: {resource_name}")
            
            # Update service allocations
            self.service_allocations[service_name].update(allocated_resources)
            
        except ResourceAllocationException:
            # Rollback any allocated resources
            for resource_name, amount in allocated_resources.items():
                self.bulkheads[resource_name].release(service_name, amount)
            
        return results
    
    def release_service_resources(self, service_name: str) -> bool:
        """Release all resources for a service"""
        
        if service_name not in self.service_allocations:
            return False
        
        allocations = self.service_allocations[service_name]
        
        for resource_name, amount in allocations.items():
            if resource_name in self.bulkheads:
                self.bulkheads[resource_name].release(service_name, amount)
        
        del self.service_allocations[service_name]
        return True
    
    def get_system_health(self) -> Dict[str, Any]:
        """Get overall system health"""
        
        total_bulkheads = len(self.bulkheads)
        healthy_bulkheads = 0
        degraded_bulkheads = 0
        exhausted_bulkheads = 0
        
        bulkhead_stats = {}
        
        for name, bulkhead in self.bulkheads.items():
            stats = bulkhead.get_stats()
            bulkhead_stats[name] = stats
            
            utilization = stats['utilization_percent']
            
            if utilization < 70:
                healthy_bulkheads += 1
            elif utilization < 90:
                degraded_bulkheads += 1
            else:
                exhausted_bulkheads += 1
        
        return {
            'timestamp': time.time(),
            'total_bulkheads': total_bulkheads,
            'healthy': healthy_bulkheads,
            'degraded': degraded_bulkheads,
            'exhausted': exhausted_bulkheads,
            'overall_health_score': (healthy_bulkheads / total_bulkheads * 100) if total_bulkheads > 0 else 100,
            'bulkhead_details': bulkhead_stats,
            'active_services': len(self.service_allocations),
            'service_allocations': dict(self.service_allocations)
        }
    
    def _monitoring_loop(self):
        """Background monitoring loop"""
        
        while self.monitoring_enabled:
            try:
                # Collect metrics
                health = self.get_system_health()
                self.metrics_history.append(health)
                
                # Check for resource exhaustion
                for name, stats in health['bulkhead_details'].items():
                    if stats['utilization_percent'] > 95:
                        print(f"⚠️  Bulkhead {name} is {stats['utilization_percent']:.1f}% utilized")
                
                time.sleep(10)  # Monitor every 10 seconds
                
            except Exception as e:
                print(f"Monitoring error: {e}")
                time.sleep(5)
    
    def get_performance_trends(self, hours: int = 1) -> Dict[str, Any]:
        """Get performance trends over time"""
        
        cutoff_time = time.time() - (hours * 3600)
        recent_metrics = [m for m in self.metrics_history if m['timestamp'] >= cutoff_time]
        
        if not recent_metrics:
            return {'message': 'No recent metrics available'}
        
        # Calculate trends
        trends = {}
        
        for bulkhead_name in self.bulkheads.keys():
            utilizations = []
            
            for metric in recent_metrics:
                if bulkhead_name in metric['bulkhead_details']:
                    utilization = metric['bulkhead_details'][bulkhead_name]['utilization_percent']
                    utilizations.append(utilization)
            
            if utilizations:
                trends[bulkhead_name] = {
                    'min_utilization': min(utilizations),
                    'max_utilization': max(utilizations),
                    'avg_utilization': sum(utilizations) / len(utilizations),
                    'current_utilization': utilizations[-1] if utilizations else 0,
                    'trend_direction': 'increasing' if len(utilizations) > 1 and utilizations[-1] > utilizations[0] else 'stable'
                }
        
        return {
            'time_period_hours': hours,
            'metrics_count': len(recent_metrics),
            'bulkhead_trends': trends
        }

class ResourceAllocationException(Exception):
    """Exception raised when resource allocation fails"""
    pass

class ServiceWithBulkheads:
    """Example service using bulkhead pattern"""
    
    def __init__(self, service_name: str, bulkhead_manager: BulkheadManager):
        self.service_name = service_name
        self.bulkhead_manager = bulkhead_manager
        
        # Define resource requirements
        self.resource_requirements = {
            'web_threads': 10,
            'db_connections': 5,
            'cache_memory': 100  # MB
        }
        
        # Allocate resources
        self.allocated = self.bulkhead_manager.allocate_resources(
            self.service_name, self.resource_requirements
        )
        
        print(f"Service {service_name} resource allocation: {self.allocated}")
    
    def process_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process request using allocated resources"""
        
        # Check if we have required resources
        if not all(self.allocated.values()):
            return {
                'status': 'error',
                'message': 'Insufficient resources allocated',
                'allocated_resources': self.allocated
            }
        
        # Simulate processing using different resources
        thread_pool = self.bulkhead_manager.bulkheads.get('web_threads')
        db_pool = self.bulkhead_manager.bulkheads.get('db_connections')
        
        if isinstance(thread_pool, ThreadPoolBulkhead):
            # Submit task to thread pool
            future = thread_pool.submit_task(
                self.service_name,
                self._process_with_resources,
                request_data
            )
            
            if future:
                try:
                    result = future.result(timeout=5.0)
                    return result
                except concurrent.futures.TimeoutError:
                    return {'status': 'timeout', 'message': 'Request timed out'}
            else:
                return {'status': 'error', 'message': 'No threads available'}
        
        # Fallback to direct processing
        return self._process_with_resources(request_data)
    
    def _process_with_resources(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Process request with resource usage simulation"""
        
        # Simulate database query
        db_pool = self.bulkhead_manager.bulkheads.get('db_connections')
        if isinstance(db_pool, ConnectionPoolBulkhead):
            connection = db_pool.get_connection(self.service_name)
            if connection:
                db_result = connection.execute(f"SELECT * FROM table WHERE id = {request_data.get('id', 1)}")
            else:
                db_result = {'error': 'No database connection available'}
        else:
            db_result = {'simulated': 'database_result'}
        
        # Simulate memory usage
        memory_pool = self.bulkhead_manager.bulkheads.get('cache_memory')
        if isinstance(memory_pool, MemoryPoolBulkhead):
            # Temporarily allocate some memory for processing
            memory_allocated = memory_pool.acquire(f"{self.service_name}_temp", 10)  # 10MB
            if memory_allocated:
                # Simulate memory-intensive operation
                time.sleep(0.1)
                memory_pool.release(f"{self.service_name}_temp", 10)
        
        return {
            'status': 'success',
            'service': self.service_name,
            'request_id': request_data.get('id', 'unknown'),
            'db_result': db_result,
            'processing_time': 0.1,
            'resources_used': self.allocated
        }
    
    def shutdown(self):
        """Shutdown service and release resources"""
        self.bulkhead_manager.release_service_resources(self.service_name)
        print(f"Service {self.service_name} shutdown and resources released")

# Example usage
print("=== Bulkhead Pattern Demo ===")

# Create bulkhead manager
bulkhead_manager = BulkheadManager()

# Add different types of bulkheads
thread_bulkhead = ThreadPoolBulkhead("web_threads", 20)
db_bulkhead = ConnectionPoolBulkhead("db_connections", 15)
memory_bulkhead = MemoryPoolBulkhead("cache_memory", 500)  # 500MB

bulkhead_manager.add_bulkhead(thread_bulkhead)
bulkhead_manager.add_bulkhead(db_bulkhead)
bulkhead_manager.add_bulkhead(memory_bulkhead)

# Create services with different resource requirements
print("\n--- Creating Services ---")

user_service = ServiceWithBulkheads("user_service", bulkhead_manager)
order_service = ServiceWithBulkheads("order_service", bulkhead_manager)
analytics_service = ServiceWithBulkheads("analytics_service", bulkhead_manager)

# Simulate requests
print("\n--- Processing Requests ---")

services = [user_service, order_service, analytics_service]

for i in range(10):
    service = services[i % len(services)]
    request = {'id': i + 1, 'data': f'request_{i + 1}'}
    
    result = service.process_request(request)
    print(f"{service.service_name} request {i + 1}: {result['status']}")

# Check system health
print("\n--- System Health ---")
health = bulkhead_manager.get_system_health()

print(f"Overall health score: {health['overall_health_score']:.1f}%")
print(f"Healthy bulkheads: {health['healthy']}/{health['total_bulkheads']}")
print(f"Active services: {health['active_services']}")

print("\nBulkhead utilization:")
for name, stats in health['bulkhead_details'].items():
    print(f"  {name}: {stats['utilization_percent']:.1f}% "
          f"({stats['current_usage']}/{stats['max_capacity']})")

# Test resource exhaustion
print("\n--- Testing Resource Exhaustion ---")

# Try to create a service that would exhaust resources
greedy_service_requirements = {
    'web_threads': 15,  # This should cause resource exhaustion
    'db_connections': 12,
    'cache_memory': 200
}

try:
    greedy_allocation = bulkhead_manager.allocate_resources(
        "greedy_service", greedy_service_requirements
    )
    print(f"Greedy service allocation: {greedy_allocation}")
except Exception as e:
    print(f"Resource exhaustion handled: {e}")

# Get performance trends
time.sleep(1)  # Let monitoring collect some data

trends = bulkhead_manager.get_performance_trends(hours=1)
if 'bulkhead_trends' in trends:
    print("\n--- Performance Trends ---")
    for bulkhead_name, trend_data in trends['bulkhead_trends'].items():
        print(f"{bulkhead_name}: avg {trend_data['avg_utilization']:.1f}%, "
              f"max {trend_data['max_utilization']:.1f}%, "
              f"trend: {trend_data['trend_direction']}")

# Cleanup
print("\n--- Cleanup ---")
for service in services:
    service.shutdown()

final_health = bulkhead_manager.get_system_health()
print(f"Final health score: {final_health['overall_health_score']:.1f}%")

bulkhead_manager.monitoring_enabled = False

print("\n--- Bulkhead Pattern Demo Completed ---")
```

## 📚 Conclusion

The Bulkhead Pattern is essential for building resilient systems that can isolate failures and protect critical resources. By creating boundaries between different system components and allocating dedicated resources, bulkheads prevent cascade failures and ensure that critical functionality remains available even when parts of the system are under stress.

**Key Takeaways:**

1. **Resource Isolation**: Separate resources for different system components
2. **Failure Containment**: Prevent failures from spreading across boundaries
3. **Performance Protection**: Avoid resource contention between services
4. **Graceful Degradation**: Allow non-critical components to fail safely
5. **Monitoring and Alerting**: Track resource utilization and health

The future of bulkhead patterns includes dynamic resource allocation, machine learning-powered capacity planning, and integration with cloud-native orchestration platforms. Whether building microservices, distributed systems, or high-traffic applications, implementing bulkhead patterns is crucial for maintaining system stability and user experience.

Remember: bulkheads are about creating safe boundaries that allow systems to fail partially without complete system failure—it's better to have some functionality working than none at all.
