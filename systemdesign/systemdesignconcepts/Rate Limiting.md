# Rate Limiting: Controlling the Flow of Requests

## 🎯 What is Rate Limiting?

Rate limiting is like having a bouncer at a popular nightclub who controls how many people can enter and how fast they can come in. Just as the bouncer prevents overcrowding and maintains order, rate limiting controls the number of requests a client can make to prevent system overload and ensure fair resource usage.

## 🏗️ Core Concepts

### The Nightclub Analogy Extended
- **Token Bucket**: VIP passes that refill over time - you can enter if you have a pass
- **Leaky Bucket**: Steady admission rate regardless of crowd size outside
- **Fixed Window**: Club opens for exactly 1 hour, admits 100 people, then closes
- **Sliding Window**: Tracks admissions over the last rolling hour

### Why Rate Limiting Matters
1. **Prevent Abuse**: Stop malicious users from overwhelming your system
2. **Fair Usage**: Ensure all users get reasonable access to resources
3. **Cost Control**: Limit expensive operations to manage infrastructure costs
4. **Quality of Service**: Maintain performance for legitimate users
5. **Security**: Mitigate DDoS attacks and brute force attempts

## ⚡ Rate Limiting Algorithms

### 1. Token Bucket Algorithm

**How it works**: Tokens are added to a bucket at a fixed rate. Each request consumes a token. If no tokens available, request is rejected.

```python
import time
import threading
from collections import defaultdict

class TokenBucket:
    def __init__(self, capacity, refill_rate):
        self.capacity = capacity          # Maximum tokens in bucket
        self.tokens = capacity           # Current tokens
        self.refill_rate = refill_rate   # Tokens added per second
        self.last_refill = time.time()
        self.lock = threading.Lock()
    
    def consume(self, tokens=1):
        with self.lock:
            now = time.time()
            # Add tokens based on elapsed time
            tokens_to_add = (now - self.last_refill) * self.refill_rate
            self.tokens = min(self.capacity, self.tokens + tokens_to_add)
            self.last_refill = now
            
            if self.tokens >= tokens:
                self.tokens -= tokens
                return True  # Request allowed
            else:
                return False  # Request rejected

# Usage example
class APIRateLimiter:
    def __init__(self):
        # Different buckets for different users
        self.buckets = defaultdict(lambda: TokenBucket(capacity=100, refill_rate=10))
    
    def is_allowed(self, user_id, tokens_needed=1):
        bucket = self.buckets[user_id]
        return bucket.consume(tokens_needed)

# Example usage
rate_limiter = APIRateLimiter()

def handle_api_request(user_id, request):
    if rate_limiter.is_allowed(user_id):
        return process_request(request)
    else:
        return {"error": "Rate limit exceeded", "retry_after": 60}
```

**Real-world example**: AWS API Gateway uses token bucket for throttling API calls.

**Advantages**:
- Allows bursts of traffic up to bucket capacity
- Smooth rate limiting over time
- Simple to understand and implement

**Disadvantages**:
- May allow sudden bursts that could overwhelm downstream systems
- Memory overhead for storing bucket state

### 2. Leaky Bucket Algorithm

**How it works**: Requests are queued and processed at a steady rate, like water dripping from a leaky bucket.

```python
import time
import queue
import threading

class LeakyBucket:
    def __init__(self, capacity, leak_rate):
        self.capacity = capacity      # Maximum queue size
        self.leak_rate = leak_rate   # Requests processed per second
        self.queue = queue.Queue(maxsize=capacity)
        self.last_leak = time.time()
        self.lock = threading.Lock()
    
    def add_request(self, request):
        with self.lock:
            # Leak (process) requests based on elapsed time
            now = time.time()
            elapsed = now - self.last_leak
            requests_to_leak = int(elapsed * self.leak_rate)
            
            for _ in range(min(requests_to_leak, self.queue.qsize())):
                try:
                    leaked_request = self.queue.get_nowait()
                    self.process_request(leaked_request)
                except queue.Empty:
                    break
            
            self.last_leak = now
            
            # Try to add new request
            try:
                self.queue.put_nowait(request)
                return True  # Request queued
            except queue.Full:
                return False  # Bucket overflow
    
    def process_request(self, request):
        # Process the request at steady rate
        print(f"Processing request: {request}")

# Usage for traffic shaping
class TrafficShaper:
    def __init__(self):
        self.bucket = LeakyBucket(capacity=1000, leak_rate=100)  # 100 req/sec
    
    def handle_request(self, request):
        if self.bucket.add_request(request):
            return {"status": "queued", "message": "Request will be processed"}
        else:
            return {"status": "rejected", "message": "System overloaded"}
```

**Real-world example**: Network routers use leaky bucket for traffic shaping.

**Advantages**:
- Smooth, steady output rate
- Good for protecting downstream systems
- Natural queuing mechanism

**Disadvantages**:
- Adds latency (requests may wait in queue)
- May not utilize available capacity during low traffic

### 3. Fixed Window Counter

**How it works**: Count requests in fixed time windows (e.g., per minute). Reset counter at window boundary.

```python
import time
from collections import defaultdict

class FixedWindowCounter:
    def __init__(self, limit, window_size):
        self.limit = limit           # Max requests per window
        self.window_size = window_size  # Window size in seconds
        self.windows = defaultdict(lambda: {"count": 0, "start_time": 0})
    
    def is_allowed(self, key):
        now = time.time()
        window = self.windows[key]
        
        # Check if we need a new window
        if now - window["start_time"] >= self.window_size:
            window["count"] = 0
            window["start_time"] = now
        
        if window["count"] < self.limit:
            window["count"] += 1
            return True
        else:
            return False

# Example: API rate limiting
class APIFixedWindowLimiter:
    def __init__(self):
        # 1000 requests per hour per user
        self.limiter = FixedWindowCounter(limit=1000, window_size=3600)
    
    def check_rate_limit(self, user_id):
        if self.limiter.is_allowed(user_id):
            return {"allowed": True}
        else:
            # Calculate time until window resets
            window = self.limiter.windows[user_id]
            reset_time = window["start_time"] + self.limiter.window_size
            retry_after = int(reset_time - time.time())
            
            return {
                "allowed": False,
                "retry_after": retry_after,
                "limit": self.limiter.limit,
                "remaining": 0
            }

# Usage
limiter = APIFixedWindowLimiter()

def api_endpoint(user_id):
    rate_limit_result = limiter.check_rate_limit(user_id)
    
    if rate_limit_result["allowed"]:
        return {"data": "API response"}
    else:
        return {
            "error": "Rate limit exceeded",
            "retry_after": rate_limit_result["retry_after"]
        }, 429  # HTTP 429 Too Many Requests
```

**Real-world example**: Twitter API limits tweets per 15-minute window.

**Advantages**:
- Simple to implement and understand
- Memory efficient
- Clear reset time for users

**Disadvantages**:
- Allows traffic spikes at window boundaries
- Uneven request distribution

### 4. Sliding Window Log

**How it works**: Keep a log of request timestamps and count requests in a sliding time window.

```python
import time
from collections import defaultdict, deque

class SlidingWindowLog:
    def __init__(self, limit, window_size):
        self.limit = limit
        self.window_size = window_size
        self.request_logs = defaultdict(deque)
    
    def is_allowed(self, key):
        now = time.time()
        log = self.request_logs[key]
        
        # Remove requests outside the window
        while log and log[0] <= now - self.window_size:
            log.popleft()
        
        # Check if we can allow this request
        if len(log) < self.limit:
            log.append(now)
            return True
        else:
            return False
    
    def get_remaining_requests(self, key):
        now = time.time()
        log = self.request_logs[key]
        
        # Clean old requests
        while log and log[0] <= now - self.window_size:
            log.popleft()
        
        return max(0, self.limit - len(log))

# Example: Precise rate limiting for critical APIs
class CriticalAPILimiter:
    def __init__(self):
        # 100 requests per minute with precise sliding window
        self.limiter = SlidingWindowLog(limit=100, window_size=60)
    
    def handle_request(self, user_id, request):
        if self.limiter.is_allowed(user_id):
            remaining = self.limiter.get_remaining_requests(user_id)
            
            response = process_critical_request(request)
            response.headers["X-RateLimit-Remaining"] = str(remaining)
            response.headers["X-RateLimit-Limit"] = "100"
            
            return response
        else:
            return {
                "error": "Rate limit exceeded",
                "message": "You have exceeded the rate limit for this API"
            }, 429
```

**Real-world example**: GitHub API uses sliding window for precise rate limiting.

**Advantages**:
- Precise rate limiting
- No traffic spikes at boundaries
- Accurate request counting

**Disadvantages**:
- Higher memory usage (stores all request timestamps)
- More complex implementation

### 5. Sliding Window Counter

**How it works**: Hybrid approach combining fixed windows with sliding calculation.

```python
import time
from collections import defaultdict

class SlidingWindowCounter:
    def __init__(self, limit, window_size):
        self.limit = limit
        self.window_size = window_size
        # Store counts for current and previous windows
        self.windows = defaultdict(lambda: {
            "current_window": {"count": 0, "start_time": 0},
            "previous_window": {"count": 0, "start_time": 0}
        })
    
    def is_allowed(self, key):
        now = time.time()
        window_data = self.windows[key]
        current = window_data["current_window"]
        previous = window_data["previous_window"]
        
        # Calculate current window start
        current_window_start = (now // self.window_size) * self.window_size
        
        # Check if we need to rotate windows
        if current_window_start != current["start_time"]:
            # Move current to previous
            previous["count"] = current["count"]
            previous["start_time"] = current["start_time"]
            
            # Reset current window
            current["count"] = 0
            current["start_time"] = current_window_start
        
        # Calculate sliding window count
        time_into_window = now - current_window_start
        previous_window_weight = (self.window_size - time_into_window) / self.window_size
        
        estimated_count = (previous["count"] * previous_window_weight + 
                          current["count"])
        
        if estimated_count < self.limit:
            current["count"] += 1
            return True
        else:
            return False

# Example: Balanced rate limiting
class BalancedRateLimiter:
    def __init__(self):
        # 1000 requests per hour with sliding window
        self.limiter = SlidingWindowCounter(limit=1000, window_size=3600)
    
    def check_limit(self, user_id):
        return self.limiter.is_allowed(user_id)
```

**Advantages**:
- Good balance between accuracy and efficiency
- Prevents boundary traffic spikes
- Lower memory usage than sliding window log

**Disadvantages**:
- Approximate counting
- More complex than fixed window

## 🌍 Distributed Rate Limiting

### Redis-Based Distributed Rate Limiter

```python
import redis
import time
import json

class DistributedRateLimiter:
    def __init__(self, redis_client, algorithm='token_bucket'):
        self.redis = redis_client
        self.algorithm = algorithm
    
    def token_bucket_check(self, key, capacity, refill_rate, tokens_requested=1):
        """Distributed token bucket using Redis Lua script"""
        lua_script = """
        local key = KEYS[1]
        local capacity = tonumber(ARGV[1])
        local refill_rate = tonumber(ARGV[2])
        local tokens_requested = tonumber(ARGV[3])
        local now = tonumber(ARGV[4])
        
        local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
        local tokens = tonumber(bucket[1]) or capacity
        local last_refill = tonumber(bucket[2]) or now
        
        -- Calculate tokens to add
        local elapsed = now - last_refill
        local tokens_to_add = elapsed * refill_rate
        tokens = math.min(capacity, tokens + tokens_to_add)
        
        if tokens >= tokens_requested then
            tokens = tokens - tokens_requested
            redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
            redis.call('EXPIRE', key, 3600)  -- Expire after 1 hour of inactivity
            return {1, tokens}  -- Allowed, remaining tokens
        else
            redis.call('HMSET', key, 'tokens', tokens, 'last_refill', now)
            redis.call('EXPIRE', key, 3600)
            return {0, tokens}  -- Rejected, remaining tokens
        end
        """
        
        result = self.redis.eval(
            lua_script, 1, key, 
            capacity, refill_rate, tokens_requested, time.time()
        )
        
        return {
            'allowed': bool(result[0]),
            'remaining_tokens': result[1]
        }
    
    def sliding_window_check(self, key, limit, window_size):
        """Distributed sliding window using Redis sorted sets"""
        now = time.time()
        pipeline = self.redis.pipeline()
        
        # Remove expired entries
        pipeline.zremrangebyscore(key, 0, now - window_size)
        
        # Count current requests in window
        pipeline.zcard(key)
        
        # Add current request
        pipeline.zadd(key, {str(now): now})
        
        # Set expiration
        pipeline.expire(key, int(window_size) + 1)
        
        results = pipeline.execute()
        current_requests = results[1]
        
        if current_requests < limit:
            return {'allowed': True, 'remaining': limit - current_requests - 1}
        else:
            # Remove the request we just added since it's not allowed
            self.redis.zrem(key, str(now))
            return {'allowed': False, 'remaining': 0}

# Usage example
redis_client = redis.Redis(host='localhost', port=6379, db=0)
rate_limiter = DistributedRateLimiter(redis_client)

def api_with_distributed_rate_limit(user_id):
    # Check rate limit: 100 requests per minute
    result = rate_limiter.sliding_window_check(
        f"rate_limit:user:{user_id}", 
        limit=100, 
        window_size=60
    )
    
    if result['allowed']:
        return {
            "data": "API response",
            "rate_limit": {
                "remaining": result['remaining'],
                "limit": 100,
                "window": 60
            }
        }
    else:
        return {"error": "Rate limit exceeded"}, 429
```

### Consistent Hashing for Rate Limiting

```python
import hashlib
import bisect

class ConsistentHashRateLimiter:
    def __init__(self, rate_limiter_nodes, replicas=3):
        self.nodes = {}
        self.ring = {}
        self.sorted_keys = []
        self.replicas = replicas
        
        for node in rate_limiter_nodes:
            self.add_node(node)
    
    def _hash(self, key):
        return int(hashlib.md5(key.encode()).hexdigest(), 16)
    
    def add_node(self, node):
        self.nodes[node.id] = node
        
        for i in range(self.replicas):
            key = self._hash(f"{node.id}:{i}")
            self.ring[key] = node.id
            bisect.insort(self.sorted_keys, key)
    
    def get_node(self, key):
        if not self.ring:
            return None
        
        hash_key = self._hash(key)
        idx = bisect.bisect_right(self.sorted_keys, hash_key)
        
        if idx == len(self.sorted_keys):
            idx = 0
        
        node_id = self.ring[self.sorted_keys[idx]]
        return self.nodes[node_id]
    
    def check_rate_limit(self, user_id, limit, window):
        # Route user to consistent rate limiter node
        node = self.get_node(user_id)
        return node.check_rate_limit(user_id, limit, window)
```

## 🛡️ Advanced Rate Limiting Patterns

### Hierarchical Rate Limiting

```python
class HierarchicalRateLimiter:
    def __init__(self):
        self.global_limiter = TokenBucket(capacity=10000, refill_rate=1000)
        self.user_limiters = defaultdict(lambda: TokenBucket(capacity=100, refill_rate=10))
        self.ip_limiters = defaultdict(lambda: TokenBucket(capacity=1000, refill_rate=100))
    
    def is_allowed(self, user_id, ip_address, tokens=1):
        # Check global rate limit first
        if not self.global_limiter.consume(tokens):
            return {"allowed": False, "reason": "Global rate limit exceeded"}
        
        # Check IP-based rate limit
        if not self.ip_limiters[ip_address].consume(tokens):
            return {"allowed": False, "reason": "IP rate limit exceeded"}
        
        # Check user-specific rate limit
        if not self.user_limiters[user_id].consume(tokens):
            return {"allowed": False, "reason": "User rate limit exceeded"}
        
        return {"allowed": True}

# Usage
hierarchical_limiter = HierarchicalRateLimiter()

def protected_endpoint(user_id, ip_address, request):
    result = hierarchical_limiter.is_allowed(user_id, ip_address)
    
    if result["allowed"]:
        return process_request(request)
    else:
        return {"error": result["reason"]}, 429
```

### Adaptive Rate Limiting

```python
class AdaptiveRateLimiter:
    def __init__(self):
        self.base_limit = 100
        self.current_limit = 100
        self.error_rate_threshold = 0.05  # 5%
        self.success_count = 0
        self.error_count = 0
        self.adjustment_factor = 0.1
        
        self.limiter = TokenBucket(capacity=self.current_limit, refill_rate=self.current_limit/60)
    
    def is_allowed(self, key):
        return self.limiter.consume()
    
    def record_success(self):
        self.success_count += 1
        self.adjust_limit()
    
    def record_error(self):
        self.error_count += 1
        self.adjust_limit()
    
    def adjust_limit(self):
        total_requests = self.success_count + self.error_count
        
        if total_requests > 100:  # Adjust after every 100 requests
            error_rate = self.error_count / total_requests
            
            if error_rate > self.error_rate_threshold:
                # High error rate - decrease limit
                new_limit = max(10, self.current_limit * (1 - self.adjustment_factor))
            else:
                # Low error rate - increase limit
                new_limit = min(self.base_limit * 2, self.current_limit * (1 + self.adjustment_factor))
            
            if new_limit != self.current_limit:
                self.current_limit = int(new_limit)
                # Update limiter with new capacity
                self.limiter = TokenBucket(capacity=self.current_limit, refill_rate=self.current_limit/60)
            
            # Reset counters
            self.success_count = 0
            self.error_count = 0

# Usage
adaptive_limiter = AdaptiveRateLimiter()

def adaptive_api_endpoint(user_id, request):
    if adaptive_limiter.is_allowed(user_id):
        try:
            response = process_request(request)
            adaptive_limiter.record_success()
            return response
        except Exception as e:
            adaptive_limiter.record_error()
            raise e
    else:
        return {"error": "Rate limit exceeded"}, 429
```

### Rate Limiting with Priority Queues

```python
import heapq
import time
from enum import Enum

class Priority(Enum):
    LOW = 3
    NORMAL = 2
    HIGH = 1
    CRITICAL = 0

class PriorityRateLimiter:
    def __init__(self, capacity, process_rate):
        self.capacity = capacity
        self.process_rate = process_rate
        self.queues = {priority: [] for priority in Priority}
        self.last_process = time.time()
    
    def add_request(self, request, priority=Priority.NORMAL):
        # Check if we have capacity
        total_queued = sum(len(queue) for queue in self.queues.values())
        
        if total_queued >= self.capacity:
            # Drop lowest priority requests first
            if self._drop_lowest_priority():
                heapq.heappush(self.queues[priority], (time.time(), request))
                return True
            else:
                return False
        else:
            heapq.heappush(self.queues[priority], (time.time(), request))
            return True
    
    def process_requests(self):
        now = time.time()
        elapsed = now - self.last_process
        requests_to_process = int(elapsed * self.process_rate)
        
        processed = 0
        # Process requests by priority
        for priority in sorted(Priority, key=lambda p: p.value):
            queue = self.queues[priority]
            
            while queue and processed < requests_to_process:
                timestamp, request = heapq.heappop(queue)
                self.execute_request(request)
                processed += 1
            
            if processed >= requests_to_process:
                break
        
        self.last_process = now
        return processed
    
    def _drop_lowest_priority(self):
        # Drop from lowest priority queue first
        for priority in sorted(Priority, key=lambda p: p.value, reverse=True):
            queue = self.queues[priority]
            if queue:
                heapq.heappop(queue)
                return True
        return False
    
    def execute_request(self, request):
        print(f"Processing request: {request}")

# Usage
priority_limiter = PriorityRateLimiter(capacity=1000, process_rate=100)

def handle_request_with_priority(request, user_tier):
    if user_tier == 'premium':
        priority = Priority.HIGH
    elif user_tier == 'standard':
        priority = Priority.NORMAL
    else:
        priority = Priority.LOW
    
    if priority_limiter.add_request(request, priority):
        return {"status": "queued", "priority": priority.name}
    else:
        return {"status": "rejected", "reason": "Queue full"}, 503
```

## 🔧 Implementation Best Practices

### Rate Limiting Headers

```python
class RateLimitHeaders:
    @staticmethod
    def add_headers(response, limit, remaining, reset_time):
        response.headers['X-RateLimit-Limit'] = str(limit)
        response.headers['X-RateLimit-Remaining'] = str(remaining)
        response.headers['X-RateLimit-Reset'] = str(int(reset_time))
        
        if remaining == 0:
            response.headers['Retry-After'] = str(int(reset_time - time.time()))
        
        return response

# Flask example
from flask import Flask, request, jsonify

app = Flask(__name__)
rate_limiter = APIRateLimiter()

@app.before_request
def check_rate_limit():
    user_id = get_user_id(request)
    
    if not rate_limiter.is_allowed(user_id):
        response = jsonify({"error": "Rate limit exceeded"})
        response.status_code = 429
        
        # Add rate limiting headers
        bucket = rate_limiter.buckets[user_id]
        reset_time = time.time() + (bucket.capacity - bucket.tokens) / bucket.refill_rate
        
        RateLimitHeaders.add_headers(response, bucket.capacity, int(bucket.tokens), reset_time)
        
        return response
```

### Graceful Degradation

```python
class GracefulRateLimiter:
    def __init__(self):
        self.strict_limiter = TokenBucket(capacity=100, refill_rate=10)
        self.degraded_limiter = TokenBucket(capacity=50, refill_rate=5)
        self.system_health = SystemHealthMonitor()
    
    def is_allowed(self, user_id, request_type):
        if self.system_health.is_healthy():
            # Normal operation
            return self.strict_limiter.consume()
        else:
            # Degraded mode - stricter limits
            if request_type == 'critical':
                return self.degraded_limiter.consume()
            else:
                return False  # Block non-critical requests

class SystemHealthMonitor:
    def __init__(self):
        self.cpu_threshold = 80
        self.memory_threshold = 85
        self.error_rate_threshold = 0.1
    
    def is_healthy(self):
        cpu_usage = get_cpu_usage()
        memory_usage = get_memory_usage()
        error_rate = get_error_rate()
        
        return (cpu_usage < self.cpu_threshold and 
                memory_usage < self.memory_threshold and 
                error_rate < self.error_rate_threshold)
```

## 📊 Monitoring and Observability

```python
class RateLimitMetrics:
    def __init__(self):
        self.metrics = {
            'requests_allowed': 0,
            'requests_rejected': 0,
            'total_requests': 0,
            'rejection_reasons': defaultdict(int)
        }
    
    def record_request(self, allowed, reason=None):
        self.metrics['total_requests'] += 1
        
        if allowed:
            self.metrics['requests_allowed'] += 1
        else:
            self.metrics['requests_rejected'] += 1
            if reason:
                self.metrics['rejection_reasons'][reason] += 1
    
    def get_rejection_rate(self):
        if self.metrics['total_requests'] == 0:
            return 0
        return self.metrics['requests_rejected'] / self.metrics['total_requests']
    
    def get_metrics_summary(self):
        return {
            'total_requests': self.metrics['total_requests'],
            'allowed_requests': self.metrics['requests_allowed'],
            'rejected_requests': self.metrics['requests_rejected'],
            'rejection_rate': self.get_rejection_rate(),
            'rejection_reasons': dict(self.metrics['rejection_reasons'])
        }

# Usage with monitoring
class MonitoredRateLimiter:
    def __init__(self):
        self.limiter = TokenBucket(capacity=100, refill_rate=10)
        self.metrics = RateLimitMetrics()
    
    def is_allowed(self, user_id):
        allowed = self.limiter.consume()
        
        if allowed:
            self.metrics.record_request(True)
        else:
            self.metrics.record_request(False, 'rate_limit_exceeded')
        
        return allowed
    
    def get_health_status(self):
        rejection_rate = self.metrics.get_rejection_rate()
        
        if rejection_rate > 0.5:
            return {'status': 'unhealthy', 'reason': 'high_rejection_rate'}
        elif rejection_rate > 0.2:
            return {'status': 'degraded', 'reason': 'elevated_rejection_rate'}
        else:
            return {'status': 'healthy'}
```

## 📚 Conclusion

Rate limiting is a critical component for building resilient, fair, and secure systems. The choice of algorithm depends on your specific requirements for traffic patterns, precision, and system resources. From simple token buckets to sophisticated adaptive systems, rate limiting helps ensure your services remain available and performant for all users.

**Key Takeaways:**

1. **Choose the right algorithm**: Consider your traffic patterns and precision requirements
2. **Think distributedly**: Use Redis or similar systems for distributed rate limiting
3. **Monitor and adapt**: Track metrics and adjust limits based on system health
4. **Provide clear feedback**: Use proper HTTP headers and error messages
5. **Plan for failure**: Implement graceful degradation when systems are under stress

The future of rate limiting lies in intelligent, adaptive systems that can automatically adjust based on system health, user behavior, and business priorities. Whether you're protecting a simple API or a complex distributed system, understanding these patterns is essential for building robust, scalable architectures.

Remember: rate limiting is not just about preventing abuse—it's about ensuring fair access to resources and maintaining system reliability under all conditions.
