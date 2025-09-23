# Prefetching: Predictive Resource Loading

## 🎯 What is Prefetching?

Prefetching is like a chess grandmaster thinking several moves ahead - anticipating what resources will be needed next and loading them proactively. While lazy loading waits for demand, prefetching predicts future needs and loads resources in advance, creating seamless user experiences by eliminating wait times for anticipated actions.

## 🏗️ Core Concepts

### The Chess Grandmaster Analogy
- **Anticipation**: Predict opponent's (user's) next moves
- **Preparation**: Load resources before they're needed
- **Strategic Thinking**: Balance current needs with future possibilities
- **Resource Management**: Don't overwhelm with excessive preparation
- **Adaptive Learning**: Improve predictions based on patterns

### Why Prefetching Matters
1. **Zero Perceived Latency**: Resources appear instantly when needed
2. **Improved User Experience**: Smooth, responsive interactions
3. **Bandwidth Optimization**: Load during idle periods
4. **Reduced Server Load**: Distribute requests over time
5. **Competitive Advantage**: Faster applications win users

## 🚀 Prefetching Implementation

```python
import time
import threading
import asyncio
from typing import Dict, List, Optional, Any, Callable, Set
from dataclasses import dataclass, field
from collections import defaultdict, deque
from abc import ABC, abstractmethod
import heapq
import random

@dataclass
class PrefetchRequest:
    resource_id: str
    priority: int  # Lower number = higher priority
    created_at: float
    predicted_access_time: float
    prefetch_strategy: str
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def __lt__(self, other):
        return self.priority < other.priority

class PrefetchStrategy(ABC):
    """Abstract base class for prefetch strategies"""
    
    @abstractmethod
    def predict_next_resources(self, current_resource: str, 
                             access_history: List[str]) -> List[PrefetchRequest]:
        """Predict what resources to prefetch next"""
        pass
    
    @abstractmethod
    def get_priority(self, resource_id: str, context: Dict[str, Any]) -> int:
        """Get priority for resource prefetching"""
        pass

class SequentialPrefetchStrategy(PrefetchStrategy):
    """Prefetch based on sequential patterns"""
    
    def __init__(self, lookahead: int = 3):
        self.lookahead = lookahead
    
    def predict_next_resources(self, current_resource: str, 
                             access_history: List[str]) -> List[PrefetchRequest]:
        """Predict sequential resources"""
        requests = []
        
        # Extract numeric part if present
        try:
            if '_' in current_resource:
                prefix, num_str = current_resource.rsplit('_', 1)
                current_num = int(num_str)
                
                # Prefetch next sequential items
                for i in range(1, self.lookahead + 1):
                    next_resource = f"{prefix}_{current_num + i}"
                    priority = i  # Lower priority for further items
                    
                    requests.append(PrefetchRequest(
                        resource_id=next_resource,
                        priority=priority,
                        created_at=time.time(),
                        predicted_access_time=time.time() + (i * 2.0),
                        prefetch_strategy="sequential"
                    ))
        except ValueError:
            pass
        
        return requests
    
    def get_priority(self, resource_id: str, context: Dict[str, Any]) -> int:
        return context.get('sequence_distance', 5)

class PatternBasedPrefetchStrategy(PrefetchStrategy):
    """Prefetch based on historical access patterns"""
    
    def __init__(self, pattern_window: int = 10):
        self.pattern_window = pattern_window
        self.access_patterns: Dict[str, Dict[str, int]] = defaultdict(lambda: defaultdict(int))
    
    def learn_pattern(self, from_resource: str, to_resource: str):
        """Learn access pattern"""
        self.access_patterns[from_resource][to_resource] += 1
    
    def predict_next_resources(self, current_resource: str, 
                             access_history: List[str]) -> List[PrefetchRequest]:
        """Predict based on learned patterns"""
        requests = []
        
        if current_resource in self.access_patterns:
            patterns = self.access_patterns[current_resource]
            total_accesses = sum(patterns.values())
            
            for next_resource, count in patterns.items():
                probability = count / total_accesses
                
                if probability > 0.1:  # Only prefetch if >10% probability
                    priority = int((1.0 - probability) * 10)  # Higher prob = lower priority number
                    
                    requests.append(PrefetchRequest(
                        resource_id=next_resource,
                        priority=priority,
                        created_at=time.time(),
                        predicted_access_time=time.time() + (priority * 0.5),
                        prefetch_strategy="pattern",
                        metadata={'probability': probability}
                    ))
        
        return requests
    
    def get_priority(self, resource_id: str, context: Dict[str, Any]) -> int:
        probability = context.get('probability', 0.1)
        return int((1.0 - probability) * 10)

class UserBehaviorPrefetchStrategy(PrefetchStrategy):
    """Prefetch based on user behavior analysis"""
    
    def __init__(self):
        self.user_sessions: Dict[str, List[str]] = defaultdict(list)
        self.common_transitions: Dict[str, List[str]] = defaultdict(list)
    
    def analyze_user_session(self, user_id: str, resource_sequence: List[str]):
        """Analyze user session to learn behavior"""
        self.user_sessions[user_id] = resource_sequence
        
        # Build transition patterns
        for i in range(len(resource_sequence) - 1):
            from_resource = resource_sequence[i]
            to_resource = resource_sequence[i + 1]
            
            if to_resource not in self.common_transitions[from_resource]:
                self.common_transitions[from_resource].append(to_resource)
    
    def predict_next_resources(self, current_resource: str, 
                             access_history: List[str]) -> List[PrefetchRequest]:
        """Predict based on user behavior"""
        requests = []
        
        if current_resource in self.common_transitions:
            transitions = self.common_transitions[current_resource]
            
            for i, next_resource in enumerate(transitions[:3]):  # Top 3 transitions
                requests.append(PrefetchRequest(
                    resource_id=next_resource,
                    priority=i + 1,
                    created_at=time.time(),
                    predicted_access_time=time.time() + ((i + 1) * 1.0),
                    prefetch_strategy="user_behavior"
                ))
        
        return requests
    
    def get_priority(self, resource_id: str, context: Dict[str, Any]) -> int:
        return context.get('behavior_rank', 5)

class PrefetchCache:
    """Cache for prefetched resources"""
    
    def __init__(self, max_size: int = 100):
        self.max_size = max_size
        self.cache: Dict[str, Any] = {}
        self.access_times: Dict[str, float] = {}
        self.prefetch_times: Dict[str, float] = {}
        self.lock = threading.RLock()
    
    def store(self, resource_id: str, data: Any, prefetch_time: float = None):
        """Store prefetched resource"""
        with self.lock:
            # Evict if cache is full
            if len(self.cache) >= self.max_size:
                self._evict_lru()
            
            self.cache[resource_id] = data
            self.prefetch_times[resource_id] = prefetch_time or time.time()
    
    def get(self, resource_id: str) -> Optional[Any]:
        """Get resource from cache"""
        with self.lock:
            if resource_id in self.cache:
                self.access_times[resource_id] = time.time()
                return self.cache[resource_id]
            return None
    
    def _evict_lru(self):
        """Evict least recently used item"""
        if not self.access_times:
            # If no access times, evict oldest prefetched
            if self.prefetch_times:
                oldest_resource = min(self.prefetch_times.keys(), 
                                    key=lambda k: self.prefetch_times[k])
                self._remove_resource(oldest_resource)
        else:
            # Evict least recently accessed
            lru_resource = min(self.access_times.keys(), 
                             key=lambda k: self.access_times[k])
            self._remove_resource(lru_resource)
    
    def _remove_resource(self, resource_id: str):
        """Remove resource from cache"""
        self.cache.pop(resource_id, None)
        self.access_times.pop(resource_id, None)
        self.prefetch_times.pop(resource_id, None)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get cache statistics"""
        with self.lock:
            total_resources = len(self.cache)
            accessed_resources = len(self.access_times)
            
            return {
                'total_cached': total_resources,
                'accessed_count': accessed_resources,
                'hit_rate': (accessed_resources / total_resources) if total_resources > 0 else 0,
                'cache_utilization': (total_resources / self.max_size) * 100
            }

class PrefetchManager:
    """Main prefetch manager"""
    
    def __init__(self, resource_loader: Callable[[str], Any], 
                 cache_size: int = 100, max_concurrent: int = 5):
        self.resource_loader = resource_loader
        self.cache = PrefetchCache(cache_size)
        self.max_concurrent = max_concurrent
        
        # Prefetch queue and workers
        self.prefetch_queue: List[PrefetchRequest] = []
        self.active_prefetches: Set[str] = set()
        self.strategies: List[PrefetchStrategy] = []
        
        # Statistics
        self.stats = {
            'prefetch_requests': 0,
            'prefetch_hits': 0,
            'prefetch_misses': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'successful_predictions': 0,
            'failed_predictions': 0
        }
        
        # Access history
        self.access_history: deque = deque(maxlen=100)
        
        # Thread management
        self.prefetch_enabled = True
        self.lock = threading.RLock()
        
        # Start prefetch worker
        self.worker_thread = threading.Thread(target=self._prefetch_worker)
        self.worker_thread.daemon = True
        self.worker_thread.start()
    
    def add_strategy(self, strategy: PrefetchStrategy):
        """Add prefetch strategy"""
        self.strategies.append(strategy)
    
    def get_resource(self, resource_id: str, context: Dict[str, Any] = None) -> Any:
        """Get resource with prefetching"""
        context = context or {}
        
        # Check cache first
        cached_data = self.cache.get(resource_id)
        if cached_data is not None:
            self.stats['cache_hits'] += 1
            self._record_access(resource_id)
            self._trigger_prefetch(resource_id, context)
            return cached_data
        
        # Load resource
        self.stats['cache_misses'] += 1
        data = self.resource_loader(resource_id)
        
        # Store in cache
        self.cache.store(resource_id, data)
        
        # Record access and trigger prefetch
        self._record_access(resource_id)
        self._trigger_prefetch(resource_id, context)
        
        return data
    
    def _record_access(self, resource_id: str):
        """Record resource access"""
        self.access_history.append((resource_id, time.time()))
        
        # Learn patterns for pattern-based strategies
        if len(self.access_history) >= 2:
            prev_resource = self.access_history[-2][0]
            for strategy in self.strategies:
                if isinstance(strategy, PatternBasedPrefetchStrategy):
                    strategy.learn_pattern(prev_resource, resource_id)
    
    def _trigger_prefetch(self, current_resource: str, context: Dict[str, Any]):
        """Trigger prefetching based on current resource"""
        
        # Get recent access history
        recent_accesses = [item[0] for item in list(self.access_history)[-10:]]
        
        # Generate prefetch requests from all strategies
        new_requests = []
        for strategy in self.strategies:
            requests = strategy.predict_next_resources(current_resource, recent_accesses)
            new_requests.extend(requests)
        
        # Add to prefetch queue
        with self.lock:
            for request in new_requests:
                if (request.resource_id not in self.active_prefetches and 
                    self.cache.get(request.resource_id) is None):
                    heapq.heappush(self.prefetch_queue, request)
                    self.stats['prefetch_requests'] += 1
    
    def _prefetch_worker(self):
        """Background worker for prefetching"""
        
        while self.prefetch_enabled:
            try:
                with self.lock:
                    # Check if we can start more prefetches
                    if (len(self.active_prefetches) >= self.max_concurrent or 
                        not self.prefetch_queue):
                        time.sleep(0.1)
                        continue
                    
                    # Get highest priority request
                    request = heapq.heappop(self.prefetch_queue)
                    self.active_prefetches.add(request.resource_id)
                
                # Prefetch resource
                self._execute_prefetch(request)
                
            except Exception as e:
                print(f"Prefetch worker error: {e}")
                time.sleep(0.5)
    
    def _execute_prefetch(self, request: PrefetchRequest):
        """Execute single prefetch request"""
        
        try:
            # Load resource
            data = self.resource_loader(request.resource_id)
            
            # Store in cache
            self.cache.store(request.resource_id, data, request.created_at)
            
            self.stats['successful_predictions'] += 1
            
        except Exception as e:
            print(f"Failed to prefetch {request.resource_id}: {e}")
            self.stats['failed_predictions'] += 1
            
        finally:
            with self.lock:
                self.active_prefetches.discard(request.resource_id)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get prefetch statistics"""
        cache_stats = self.cache.get_stats()
        
        return {
            'prefetch_stats': self.stats.copy(),
            'cache_stats': cache_stats,
            'active_prefetches': len(self.active_prefetches),
            'queued_requests': len(self.prefetch_queue),
            'access_history_size': len(self.access_history)
        }
    
    def shutdown(self):
        """Shutdown prefetch manager"""
        self.prefetch_enabled = False

# Example implementations
class WebPagePrefetcher:
    """Prefetcher for web pages"""
    
    def __init__(self):
        def page_loader(page_id: str) -> Dict[str, Any]:
            # Simulate page loading
            time.sleep(0.2)
            return {
                'page_id': page_id,
                'content': f'Content for page {page_id}',
                'load_time': time.time()
            }
        
        self.prefetch_manager = PrefetchManager(page_loader, cache_size=50)
        
        # Add strategies
        self.prefetch_manager.add_strategy(SequentialPrefetchStrategy(lookahead=2))
        self.prefetch_manager.add_strategy(PatternBasedPrefetchStrategy())
    
    def navigate_to_page(self, page_id: str) -> Dict[str, Any]:
        """Navigate to page with prefetching"""
        return self.prefetch_manager.get_resource(page_id)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get prefetching statistics"""
        return self.prefetch_manager.get_stats()

class DatabasePrefetcher:
    """Prefetcher for database records"""
    
    def __init__(self):
        def record_loader(record_id: str) -> Dict[str, Any]:
            # Simulate database query
            time.sleep(0.1)
            return {
                'record_id': record_id,
                'data': f'Database record {record_id}',
                'timestamp': time.time()
            }
        
        self.prefetch_manager = PrefetchManager(record_loader, cache_size=200)
        
        # Add user behavior strategy
        behavior_strategy = UserBehaviorPrefetchStrategy()
        self.prefetch_manager.add_strategy(behavior_strategy)
        
        # Simulate learning user behavior
        behavior_strategy.analyze_user_session('user1', ['record_1', 'record_2', 'record_5'])
        behavior_strategy.analyze_user_session('user2', ['record_1', 'record_3', 'record_4'])
    
    def get_record(self, record_id: str) -> Dict[str, Any]:
        """Get database record with prefetching"""
        return self.prefetch_manager.get_resource(record_id)

# Example usage and testing
print("=== Prefetching Demo ===")

# Test web page prefetching
print("\n--- Web Page Prefetching Test ---")
web_prefetcher = WebPagePrefetcher()

print("Navigating through pages:")
for page_num in [1, 2, 3, 5, 6]:
    page_id = f"page_{page_num}"
    start_time = time.time()
    page_data = web_prefetcher.navigate_to_page(page_id)
    load_time = time.time() - start_time
    
    print(f"  {page_id}: loaded in {load_time:.3f}s")

# Check statistics
web_stats = web_prefetcher.get_stats()
print(f"\nWeb prefetching statistics:")
print(f"  Cache hits: {web_stats['cache_stats']['hit_rate']:.2%}")
print(f"  Successful predictions: {web_stats['prefetch_stats']['successful_predictions']}")
print(f"  Active prefetches: {web_stats['active_prefetches']}")

# Test database prefetching
print("\n--- Database Prefetching Test ---")
db_prefetcher = DatabasePrefetcher()

print("Accessing database records:")
for record_num in [1, 2, 3, 4, 5]:
    record_id = f"record_{record_num}"
    start_time = time.time()
    record_data = db_prefetcher.get_record(record_id)
    load_time = time.time() - start_time
    
    print(f"  {record_id}: loaded in {load_time:.3f}s")

# Test pattern learning
print("\n--- Pattern Learning Test ---")
pattern_strategy = PatternBasedPrefetchStrategy()

# Simulate access patterns
patterns = [
    ('home', 'profile'),
    ('home', 'settings'),
    ('profile', 'edit_profile'),
    ('profile', 'view_posts'),
    ('settings', 'privacy'),
    ('home', 'profile'),  # Repeat to strengthen pattern
    ('profile', 'edit_profile')
]

for from_page, to_page in patterns:
    pattern_strategy.learn_pattern(from_page, to_page)

# Test predictions
predictions = pattern_strategy.predict_next_resources('home', [])
print("Predictions from 'home' page:")
for pred in predictions:
    print(f"  {pred.resource_id} (priority: {pred.priority}, "
          f"probability: {pred.metadata.get('probability', 0):.2%})")

# Test concurrent prefetching
print("\n--- Concurrent Prefetching Test ---")

def concurrent_access_test():
    """Test concurrent access patterns"""
    import concurrent.futures
    
    def access_resource(resource_id: str):
        return web_prefetcher.navigate_to_page(resource_id)
    
    # Simulate concurrent users
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = []
        
        # Submit concurrent requests
        for i in range(10, 20):
            future = executor.submit(access_resource, f"page_{i}")
            futures.append(future)
        
        # Wait for completion
        for future in concurrent.futures.as_completed(futures):
            try:
                result = future.result()
                print(f"  Loaded: {result['page_id']}")
            except Exception as e:
                print(f"  Error: {e}")

concurrent_access_test()

# Final statistics
print("\n--- Final Statistics ---")
final_stats = web_prefetcher.get_stats()

print("Prefetch performance:")
print(f"  Total prefetch requests: {final_stats['prefetch_stats']['prefetch_requests']}")
print(f"  Successful predictions: {final_stats['prefetch_stats']['successful_predictions']}")
print(f"  Failed predictions: {final_stats['prefetch_stats']['failed_predictions']}")
print(f"  Cache hit rate: {final_stats['cache_stats']['hit_rate']:.2%}")
print(f"  Cache utilization: {final_stats['cache_stats']['cache_utilization']:.1f}%")

# Cleanup
web_prefetcher.prefetch_manager.shutdown()

print("\n--- Prefetching Demo Completed ---")
```

## 📚 Conclusion

Prefetching transforms user experience by anticipating needs and loading resources proactively. From simple sequential prefetching to sophisticated machine learning-based prediction, prefetching strategies enable applications to provide instant responses and seamless interactions.

**Key Takeaways:**

1. **Predict Intelligently**: Use patterns, behavior, and context to predict future needs
2. **Balance Resources**: Don't overwhelm bandwidth or storage with excessive prefetching
3. **Learn Continuously**: Adapt strategies based on actual usage patterns
4. **Monitor Performance**: Track prediction accuracy and cache effectiveness
5. **Handle Concurrency**: Manage prefetch workers and resource contention

The future of prefetching includes AI-powered prediction models, edge computing integration, and real-time user behavior analysis. Whether building web applications, mobile apps, or content delivery systems, implementing intelligent prefetching strategies is essential for creating responsive, user-friendly experiences.
