# Retry Mechanisms: Resilient Failure Handling

## 🎯 What are Retry Mechanisms?

Retry mechanisms are like a persistent salesperson who doesn't give up after the first "no" but waits, adjusts their approach, and tries again with increasing patience. Just as a good salesperson knows when to back off and when to persist, retry mechanisms intelligently handle transient failures by attempting operations again with smart timing strategies, ultimately improving system reliability without overwhelming failing services.

## 🏗️ Core Concepts

### The Persistent Salesperson Analogy
- **Initial Attempt**: First try with standard approach
- **Backoff Strategy**: Waiting longer between subsequent attempts
- **Jitter**: Adding randomness to avoid thundering herd
- **Circuit Breaking**: Knowing when to stop trying completely
- **Exponential Patience**: Increasing wait times with each failure
- **Success Recognition**: Stopping retries when the goal is achieved

### Why Retry Mechanisms Matter
1. **Transient Failure Recovery**: Handle temporary network glitches and service hiccups
2. **System Reliability**: Improve overall success rates without code changes
3. **User Experience**: Reduce visible failures through transparent recovery
4. **Resource Efficiency**: Avoid overwhelming already-struggling services
5. **Operational Simplicity**: Handle common failure patterns automatically

## 🔄 Retry Implementation

```python
import time
import random
import asyncio
import threading
from typing import Dict, List, Optional, Any, Callable, Union
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict
import logging
from abc import ABC, abstractmethod
import functools

class RetryStrategy(Enum):
    FIXED_DELAY = "fixed_delay"
    LINEAR_BACKOFF = "linear_backoff"
    EXPONENTIAL_BACKOFF = "exponential_backoff"
    FIBONACCI_BACKOFF = "fibonacci_backoff"
    CUSTOM = "custom"

class RetryResult(Enum):
    SUCCESS = "success"
    RETRY_EXHAUSTED = "retry_exhausted"
    NON_RETRYABLE_ERROR = "non_retryable_error"
    CIRCUIT_BREAKER_OPEN = "circuit_breaker_open"

@dataclass
class RetryConfig:
    max_attempts: int = 3
    strategy: RetryStrategy = RetryStrategy.EXPONENTIAL_BACKOFF
    base_delay: float = 1.0
    max_delay: float = 60.0
    multiplier: float = 2.0
    jitter: bool = True
    jitter_range: float = 0.1
    retryable_exceptions: List[type] = field(default_factory=lambda: [Exception])
    non_retryable_exceptions: List[type] = field(default_factory=list)
    timeout: Optional[float] = None

@dataclass
class RetryAttempt:
    attempt_number: int
    delay_before_attempt: float
    start_time: float
    end_time: Optional[float]
    success: bool
    error: Optional[Exception]
    response_time: float

class BackoffCalculator:
    """Calculate backoff delays for different retry strategies"""
    
    @staticmethod
    def fixed_delay(attempt: int, base_delay: float, **kwargs) -> float:
        """Fixed delay between retries"""
        return base_delay
    
    @staticmethod
    def linear_backoff(attempt: int, base_delay: float, multiplier: float = 1.0, **kwargs) -> float:
        """Linear backoff: delay increases linearly"""
        return base_delay * attempt * multiplier
    
    @staticmethod
    def exponential_backoff(attempt: int, base_delay: float, multiplier: float = 2.0, 
                          max_delay: float = 60.0, **kwargs) -> float:
        """Exponential backoff: delay doubles each time"""
        delay = base_delay * (multiplier ** (attempt - 1))
        return min(delay, max_delay)
    
    @staticmethod
    def fibonacci_backoff(attempt: int, base_delay: float, max_delay: float = 60.0, **kwargs) -> float:
        """Fibonacci backoff: delay follows Fibonacci sequence"""
        
        def fibonacci(n):
            if n <= 1:
                return n
            return fibonacci(n - 1) + fibonacci(n - 2)
        
        delay = base_delay * fibonacci(attempt)
        return min(delay, max_delay)
    
    @staticmethod
    def add_jitter(delay: float, jitter_range: float = 0.1) -> float:
        """Add random jitter to delay"""
        jitter = delay * jitter_range * (2 * random.random() - 1)  # ±jitter_range
        return max(0, delay + jitter)

class RetryStatistics:
    """Track retry statistics and patterns"""
    
    def __init__(self):
        self.attempts: List[RetryAttempt] = []
        self.success_count = 0
        self.failure_count = 0
        self.retry_exhausted_count = 0
        self.total_operations = 0
        self.total_retry_time = 0.0
        
    def record_operation(self, attempts: List[RetryAttempt], final_result: RetryResult):
        """Record completed retry operation"""
        
        self.attempts.extend(attempts)
        self.total_operations += 1
        
        if final_result == RetryResult.SUCCESS:
            self.success_count += 1
        elif final_result == RetryResult.RETRY_EXHAUSTED:
            self.retry_exhausted_count += 1
        else:
            self.failure_count += 1
        
        # Calculate total retry time
        operation_time = sum(attempt.response_time + attempt.delay_before_attempt 
                           for attempt in attempts)
        self.total_retry_time += operation_time
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get comprehensive retry statistics"""
        
        if self.total_operations == 0:
            return {'message': 'No operations recorded'}
        
        successful_operations = [op for op in self._group_by_operation() if op['success']]
        
        # Calculate success rate
        success_rate = self.success_count / self.total_operations
        
        # Calculate average attempts per operation
        total_attempts = len(self.attempts)
        avg_attempts = total_attempts / self.total_operations
        
        # Calculate average retry time
        avg_retry_time = self.total_retry_time / self.total_operations
        
        # Analyze retry patterns
        retry_patterns = self._analyze_retry_patterns()
        
        return {
            'total_operations': self.total_operations,
            'success_rate': success_rate,
            'retry_exhausted_rate': self.retry_exhausted_count / self.total_operations,
            'average_attempts_per_operation': avg_attempts,
            'average_retry_time_seconds': avg_retry_time,
            'total_attempts': total_attempts,
            'retry_patterns': retry_patterns,
            'performance_impact': {
                'total_retry_overhead': self.total_retry_time,
                'average_overhead_per_operation': avg_retry_time
            }
        }
    
    def _group_by_operation(self) -> List[Dict[str, Any]]:
        """Group attempts by operation"""
        # This is a simplified grouping - in practice, you'd need operation IDs
        operations = []
        current_operation = []
        
        for attempt in self.attempts:
            if attempt.attempt_number == 1 and current_operation:
                # New operation started
                operations.append({
                    'attempts': current_operation.copy(),
                    'success': current_operation[-1].success
                })
                current_operation = []
            
            current_operation.append(attempt)
        
        if current_operation:
            operations.append({
                'attempts': current_operation,
                'success': current_operation[-1].success
            })
        
        return operations
    
    def _analyze_retry_patterns(self) -> Dict[str, Any]:
        """Analyze common retry patterns"""
        
        if not self.attempts:
            return {}
        
        # Analyze by attempt number
        attempts_by_number = defaultdict(list)
        for attempt in self.attempts:
            attempts_by_number[attempt.attempt_number].append(attempt)
        
        pattern_analysis = {}
        for attempt_num, attempts in attempts_by_number.items():
            success_rate = sum(1 for a in attempts if a.success) / len(attempts)
            avg_response_time = sum(a.response_time for a in attempts) / len(attempts)
            
            pattern_analysis[f'attempt_{attempt_num}'] = {
                'count': len(attempts),
                'success_rate': success_rate,
                'average_response_time': avg_response_time
            }
        
        return pattern_analysis

class RetryHandler:
    """Main retry handler with configurable strategies"""
    
    def __init__(self, config: RetryConfig = None):
        self.config = config or RetryConfig()
        self.statistics = RetryStatistics()
        self.circuit_breakers: Dict[str, Any] = {}
        
    def execute(self, operation: Callable, *args, operation_id: str = None, **kwargs) -> Any:
        """Execute operation with retry logic"""
        
        attempts = []
        last_exception = None
        
        for attempt_num in range(1, self.config.max_attempts + 1):
            # Calculate delay for this attempt
            if attempt_num > 1:
                delay = self._calculate_delay(attempt_num - 1)
                time.sleep(delay)
            else:
                delay = 0
            
            # Create attempt record
            attempt = RetryAttempt(
                attempt_number=attempt_num,
                delay_before_attempt=delay,
                start_time=time.time(),
                end_time=None,
                success=False,
                error=None,
                response_time=0
            )
            
            try:
                # Execute the operation
                start_time = time.time()
                result = operation(*args, **kwargs)
                end_time = time.time()
                
                # Success!
                attempt.end_time = end_time
                attempt.success = True
                attempt.response_time = end_time - start_time
                attempts.append(attempt)
                
                # Record statistics
                self.statistics.record_operation(attempts, RetryResult.SUCCESS)
                
                return result
                
            except Exception as e:
                end_time = time.time()
                attempt.end_time = end_time
                attempt.error = e
                attempt.response_time = end_time - start_time
                attempts.append(attempt)
                
                last_exception = e
                
                # Check if this exception is retryable
                if not self._is_retryable_exception(e):
                    self.statistics.record_operation(attempts, RetryResult.NON_RETRYABLE_ERROR)
                    raise e
                
                # Check timeout
                if self.config.timeout:
                    total_time = sum(a.response_time + a.delay_before_attempt for a in attempts)
                    if total_time >= self.config.timeout:
                        break
                
                # If this was the last attempt, break
                if attempt_num >= self.config.max_attempts:
                    break
        
        # All retries exhausted
        self.statistics.record_operation(attempts, RetryResult.RETRY_EXHAUSTED)
        raise RetryExhaustedException(
            f"Operation failed after {self.config.max_attempts} attempts. Last error: {last_exception}"
        )
    
    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay before next attempt"""
        
        if self.config.strategy == RetryStrategy.FIXED_DELAY:
            delay = BackoffCalculator.fixed_delay(attempt, self.config.base_delay)
        elif self.config.strategy == RetryStrategy.LINEAR_BACKOFF:
            delay = BackoffCalculator.linear_backoff(
                attempt, self.config.base_delay, self.config.multiplier
            )
        elif self.config.strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = BackoffCalculator.exponential_backoff(
                attempt, self.config.base_delay, self.config.multiplier, self.config.max_delay
            )
        elif self.config.strategy == RetryStrategy.FIBONACCI_BACKOFF:
            delay = BackoffCalculator.fibonacci_backoff(
                attempt, self.config.base_delay, self.config.max_delay
            )
        else:
            delay = self.config.base_delay
        
        # Add jitter if enabled
        if self.config.jitter:
            delay = BackoffCalculator.add_jitter(delay, self.config.jitter_range)
        
        return delay
    
    def _is_retryable_exception(self, exception: Exception) -> bool:
        """Check if exception is retryable"""
        
        # Check non-retryable exceptions first
        for non_retryable_type in self.config.non_retryable_exceptions:
            if isinstance(exception, non_retryable_type):
                return False
        
        # Check retryable exceptions
        for retryable_type in self.config.retryable_exceptions:
            if isinstance(exception, retryable_type):
                return True
        
        return False

class RetryExhaustedException(Exception):
    """Exception raised when all retry attempts are exhausted"""
    pass

# Retry Decorator
def retry(config: RetryConfig = None, operation_id: str = None):
    """Decorator for adding retry logic to functions"""
    
    if config is None:
        config = RetryConfig()
    
    def decorator(func):
        retry_handler = RetryHandler(config)
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            return retry_handler.execute(func, *args, operation_id=operation_id, **kwargs)
        
        wrapper.retry_handler = retry_handler
        return wrapper
    
    return decorator

# Async Retry Handler
class AsyncRetryHandler:
    """Async version of retry handler"""
    
    def __init__(self, config: RetryConfig = None):
        self.config = config or RetryConfig()
        self.statistics = RetryStatistics()
    
    async def execute(self, operation: Callable, *args, **kwargs) -> Any:
        """Execute async operation with retry logic"""
        
        attempts = []
        last_exception = None
        
        for attempt_num in range(1, self.config.max_attempts + 1):
            # Calculate delay for this attempt
            if attempt_num > 1:
                delay = self._calculate_delay(attempt_num - 1)
                await asyncio.sleep(delay)
            else:
                delay = 0
            
            # Create attempt record
            attempt = RetryAttempt(
                attempt_number=attempt_num,
                delay_before_attempt=delay,
                start_time=time.time(),
                end_time=None,
                success=False,
                error=None,
                response_time=0
            )
            
            try:
                # Execute the operation
                start_time = time.time()
                
                if asyncio.iscoroutinefunction(operation):
                    result = await operation(*args, **kwargs)
                else:
                    result = operation(*args, **kwargs)
                
                end_time = time.time()
                
                # Success!
                attempt.end_time = end_time
                attempt.success = True
                attempt.response_time = end_time - start_time
                attempts.append(attempt)
                
                # Record statistics
                self.statistics.record_operation(attempts, RetryResult.SUCCESS)
                
                return result
                
            except Exception as e:
                end_time = time.time()
                attempt.end_time = end_time
                attempt.error = e
                attempt.response_time = end_time - start_time
                attempts.append(attempt)
                
                last_exception = e
                
                # Check if this exception is retryable
                if not self._is_retryable_exception(e):
                    self.statistics.record_operation(attempts, RetryResult.NON_RETRYABLE_ERROR)
                    raise e
                
                # If this was the last attempt, break
                if attempt_num >= self.config.max_attempts:
                    break
        
        # All retries exhausted
        self.statistics.record_operation(attempts, RetryResult.RETRY_EXHAUSTED)
        raise RetryExhaustedException(
            f"Async operation failed after {self.config.max_attempts} attempts. Last error: {last_exception}"
        )
    
    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay before next attempt"""
        # Same logic as sync version
        if self.config.strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = BackoffCalculator.exponential_backoff(
                attempt, self.config.base_delay, self.config.multiplier, self.config.max_delay
            )
        else:
            delay = self.config.base_delay
        
        if self.config.jitter:
            delay = BackoffCalculator.add_jitter(delay, self.config.jitter_range)
        
        return delay
    
    def _is_retryable_exception(self, exception: Exception) -> bool:
        """Check if exception is retryable"""
        # Same logic as sync version
        for non_retryable_type in self.config.non_retryable_exceptions:
            if isinstance(exception, non_retryable_type):
                return False
        
        for retryable_type in self.config.retryable_exceptions:
            if isinstance(exception, retryable_type):
                return True
        
        return False

# Example usage and testing
print("=== Retry Mechanisms Demo ===")

# Define some example exceptions
class NetworkError(Exception):
    pass

class ServiceUnavailableError(Exception):
    pass

class AuthenticationError(Exception):
    pass

# Example: Unreliable service that fails randomly
class UnreliableService:
    def __init__(self, failure_rate: float = 0.7):
        self.failure_rate = failure_rate
        self.call_count = 0
    
    def call_api(self, endpoint: str) -> Dict[str, Any]:
        """Simulate API call that fails randomly"""
        self.call_count += 1
        
        # Simulate different types of failures
        if random.random() < self.failure_rate:
            failure_type = random.choice([
                NetworkError("Connection timeout"),
                ServiceUnavailableError("Service temporarily unavailable"),
                AuthenticationError("Invalid credentials")  # Non-retryable
            ])
            raise failure_type
        
        # Success
        return {
            'status': 'success',
            'endpoint': endpoint,
            'call_number': self.call_count,
            'response_time': random.uniform(0.1, 0.5)
        }

# Test different retry strategies
print("\n--- Testing Different Retry Strategies ---")

service = UnreliableService(failure_rate=0.6)

# 1. Exponential backoff retry
exponential_config = RetryConfig(
    max_attempts=4,
    strategy=RetryStrategy.EXPONENTIAL_BACKOFF,
    base_delay=0.5,
    max_delay=8.0,
    multiplier=2.0,
    jitter=True,
    retryable_exceptions=[NetworkError, ServiceUnavailableError],
    non_retryable_exceptions=[AuthenticationError]
)

retry_handler = RetryHandler(exponential_config)

print("Testing exponential backoff:")
for i in range(5):
    try:
        start_time = time.time()
        result = retry_handler.execute(service.call_api, f"/endpoint_{i}")
        end_time = time.time()
        
        print(f"  Call {i+1}: SUCCESS after {end_time - start_time:.2f}s - {result['call_number']} attempts")
        
    except RetryExhaustedException as e:
        print(f"  Call {i+1}: FAILED - {e}")
    except AuthenticationError as e:
        print(f"  Call {i+1}: NON-RETRYABLE - {e}")

# 2. Using retry decorator
print("\n--- Testing Retry Decorator ---")

@retry(RetryConfig(
    max_attempts=3,
    strategy=RetryStrategy.LINEAR_BACKOFF,
    base_delay=0.3,
    multiplier=1.5
))
def decorated_api_call(endpoint: str) -> Dict[str, Any]:
    """API call with retry decorator"""
    return service.call_api(endpoint)

for i in range(3):
    try:
        result = decorated_api_call(f"/decorated_{i}")
        print(f"  Decorated call {i+1}: SUCCESS")
    except Exception as e:
        print(f"  Decorated call {i+1}: FAILED - {type(e).__name__}")

# 3. Async retry
print("\n--- Testing Async Retry ---")

async def async_api_call(endpoint: str) -> Dict[str, Any]:
    """Async API call simulation"""
    await asyncio.sleep(0.1)  # Simulate async operation
    return service.call_api(endpoint)

async def test_async_retry():
    async_retry_handler = AsyncRetryHandler(RetryConfig(
        max_attempts=3,
        strategy=RetryStrategy.FIBONACCI_BACKOFF,
        base_delay=0.2
    ))
    
    for i in range(3):
        try:
            result = await async_retry_handler.execute(async_api_call, f"/async_{i}")
            print(f"  Async call {i+1}: SUCCESS")
        except Exception as e:
            print(f"  Async call {i+1}: FAILED - {type(e).__name__}")

# Run async test
asyncio.run(test_async_retry())

# 4. Retry statistics analysis
print("\n--- Retry Statistics Analysis ---")

stats = retry_handler.statistics.get_statistics()

print(f"Total operations: {stats['total_operations']}")
print(f"Success rate: {stats['success_rate']:.2%}")
print(f"Average attempts per operation: {stats['average_attempts_per_operation']:.2f}")
print(f"Average retry time: {stats['average_retry_time_seconds']:.2f}s")

if 'retry_patterns' in stats:
    print("\nRetry patterns:")
    for pattern, data in stats['retry_patterns'].items():
        print(f"  {pattern}: {data['count']} attempts, "
              f"{data['success_rate']:.2%} success rate, "
              f"{data['average_response_time']:.3f}s avg response time")

# 5. Testing different backoff strategies
print("\n--- Comparing Backoff Strategies ---")

strategies_to_test = [
    (RetryStrategy.FIXED_DELAY, "Fixed Delay"),
    (RetryStrategy.LINEAR_BACKOFF, "Linear Backoff"),
    (RetryStrategy.EXPONENTIAL_BACKOFF, "Exponential Backoff"),
    (RetryStrategy.FIBONACCI_BACKOFF, "Fibonacci Backoff")
]

for strategy, name in strategies_to_test:
    config = RetryConfig(
        max_attempts=4,
        strategy=strategy,
        base_delay=0.5,
        max_delay=10.0,
        multiplier=2.0
    )
    
    # Calculate delays for demonstration
    delays = []
    for attempt in range(1, 5):
        if strategy == RetryStrategy.FIXED_DELAY:
            delay = BackoffCalculator.fixed_delay(attempt, config.base_delay)
        elif strategy == RetryStrategy.LINEAR_BACKOFF:
            delay = BackoffCalculator.linear_backoff(attempt, config.base_delay, config.multiplier)
        elif strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = BackoffCalculator.exponential_backoff(attempt, config.base_delay, config.multiplier, config.max_delay)
        elif strategy == RetryStrategy.FIBONACCI_BACKOFF:
            delay = BackoffCalculator.fibonacci_backoff(attempt, config.base_delay, config.max_delay)
        
        delays.append(delay)
    
    print(f"{name}: delays = {[f'{d:.2f}s' for d in delays]}")

print("\n--- Retry Mechanisms Demo Completed ---")
```

## 📚 Conclusion

Retry mechanisms are fundamental building blocks for creating resilient distributed systems that can handle transient failures gracefully. From simple fixed delays to sophisticated exponential backoff with jitter, these patterns help systems recover automatically from temporary issues while avoiding overwhelming already-struggling services.

**Key Takeaways:**

1. **Choose Appropriate Strategy**: Match backoff strategy to failure patterns
2. **Add Jitter**: Prevent thundering herd problems with randomization
3. **Set Reasonable Limits**: Balance persistence with resource protection
4. **Handle Non-Retryable Errors**: Don't retry permanent failures
5. **Monitor and Measure**: Track retry patterns and success rates

The future of retry mechanisms includes machine learning-powered adaptive strategies, integration with circuit breakers and bulkheads, and context-aware retry policies. Whether building microservices, API clients, or distributed systems, implementing intelligent retry mechanisms is essential for creating robust, user-friendly applications.

Remember: retry mechanisms should be smart about when to give up—persistence is valuable, but knowing when to stop is equally important for system health and user experience.
