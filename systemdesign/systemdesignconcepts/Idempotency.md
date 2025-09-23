# Idempotency: Safe Operations in Distributed Systems

## 🎯 What is Idempotency?

Idempotency is like pressing an elevator button - whether you press it once or ten times, the elevator still comes to your floor just once. In distributed systems, an idempotent operation produces the same result no matter how many times it's executed with the same inputs. This property is crucial for building reliable systems that can safely retry operations without unintended side effects.

## 🏗️ Core Concepts

### The Elevator Button Analogy
- **Single Effect**: Pressing multiple times doesn't call multiple elevators
- **Safe Repetition**: No harm in pressing again if unsure
- **Consistent Outcome**: Same result regardless of repetition
- **State Awareness**: System knows if action was already performed
- **User Confidence**: Users can retry without fear of duplication

### Why Idempotency Matters
1. **Safe Retries**: Enable automatic retry mechanisms without side effects
2. **Network Reliability**: Handle network failures and duplicate requests gracefully
3. **User Experience**: Allow users to retry operations without fear
4. **System Consistency**: Maintain data integrity despite repeated operations
5. **Operational Simplicity**: Reduce complexity in error handling and recovery

## 🔄 Idempotency Implementation

```python
import time
import hashlib
import threading
import uuid
from typing import Dict, List, Optional, Any, Callable, Union
from enum import Enum
from dataclasses import dataclass, field
from collections import defaultdict
import json
from abc import ABC, abstractmethod

class OperationStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    EXPIRED = "expired"

@dataclass
class IdempotencyKey:
    key: str
    created_at: float
    expires_at: Optional[float]
    operation_id: str
    client_id: Optional[str] = None
    
    def is_expired(self) -> bool:
        """Check if idempotency key has expired"""
        if self.expires_at is None:
            return False
        return time.time() > self.expires_at
    
    def __hash__(self):
        return hash(self.key)

@dataclass
class OperationResult:
    operation_id: str
    status: OperationStatus
    result: Optional[Any]
    error: Optional[str]
    created_at: float
    completed_at: Optional[float]
    attempts: int
    idempotency_key: str
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for storage/serialization"""
        return {
            'operation_id': self.operation_id,
            'status': self.status.value,
            'result': self.result,
            'error': self.error,
            'created_at': self.created_at,
            'completed_at': self.completed_at,
            'attempts': self.attempts,
            'idempotency_key': self.idempotency_key
        }

class IdempotencyStore(ABC):
    """Abstract store for idempotency keys and operation results"""
    
    @abstractmethod
    def store_operation(self, key: IdempotencyKey, result: OperationResult) -> bool:
        """Store operation result with idempotency key"""
        pass
    
    @abstractmethod
    def get_operation(self, key: str) -> Optional[OperationResult]:
        """Get operation result by idempotency key"""
        pass
    
    @abstractmethod
    def update_operation(self, key: str, result: OperationResult) -> bool:
        """Update existing operation result"""
        pass
    
    @abstractmethod
    def delete_operation(self, key: str) -> bool:
        """Delete operation result"""
        pass
    
    @abstractmethod
    def cleanup_expired(self) -> int:
        """Clean up expired operations"""
        pass

class MemoryIdempotencyStore(IdempotencyStore):
    """In-memory implementation of idempotency store"""
    
    def __init__(self):
        self.operations: Dict[str, OperationResult] = {}
        self.keys: Dict[str, IdempotencyKey] = {}
        self.lock = threading.RLock()
    
    def store_operation(self, key: IdempotencyKey, result: OperationResult) -> bool:
        """Store operation result with idempotency key"""
        with self.lock:
            self.keys[key.key] = key
            self.operations[key.key] = result
            return True
    
    def get_operation(self, key: str) -> Optional[OperationResult]:
        """Get operation result by idempotency key"""
        with self.lock:
            # Check if key exists and is not expired
            if key in self.keys:
                idempotency_key = self.keys[key]
                if idempotency_key.is_expired():
                    # Clean up expired key
                    self.delete_operation(key)
                    return None
            
            return self.operations.get(key)
    
    def update_operation(self, key: str, result: OperationResult) -> bool:
        """Update existing operation result"""
        with self.lock:
            if key in self.operations:
                self.operations[key] = result
                return True
            return False
    
    def delete_operation(self, key: str) -> bool:
        """Delete operation result"""
        with self.lock:
            deleted = False
            if key in self.operations:
                del self.operations[key]
                deleted = True
            if key in self.keys:
                del self.keys[key]
                deleted = True
            return deleted
    
    def cleanup_expired(self) -> int:
        """Clean up expired operations"""
        with self.lock:
            expired_keys = []
            
            for key, idempotency_key in self.keys.items():
                if idempotency_key.is_expired():
                    expired_keys.append(key)
            
            for key in expired_keys:
                self.delete_operation(key)
            
            return len(expired_keys)
    
    def get_stats(self) -> Dict[str, Any]:
        """Get store statistics"""
        with self.lock:
            status_counts = defaultdict(int)
            
            for operation in self.operations.values():
                status_counts[operation.status.value] += 1
            
            return {
                'total_operations': len(self.operations),
                'status_distribution': dict(status_counts),
                'memory_usage_estimate': len(self.operations) * 1024  # Rough estimate
            }

class IdempotencyManager:
    """Main idempotency manager"""
    
    def __init__(self, store: IdempotencyStore = None, default_ttl: int = 3600):
        self.store = store or MemoryIdempotencyStore()
        self.default_ttl = default_ttl  # Default TTL in seconds
        self.lock = threading.RLock()
        
        # Start cleanup thread
        self.cleanup_enabled = True
        self.cleanup_thread = threading.Thread(target=self._cleanup_loop)
        self.cleanup_thread.daemon = True
        self.cleanup_thread.start()
    
    def generate_key(self, operation_name: str, parameters: Dict[str, Any], 
                    client_id: str = None) -> str:
        """Generate idempotency key from operation and parameters"""
        
        # Create deterministic key from operation and parameters
        key_data = {
            'operation': operation_name,
            'parameters': parameters,
            'client_id': client_id
        }
        
        # Sort parameters for consistent key generation
        if isinstance(parameters, dict):
            sorted_params = json.dumps(parameters, sort_keys=True)
        else:
            sorted_params = str(parameters)
        
        key_string = f"{operation_name}:{sorted_params}:{client_id or 'anonymous'}"
        
        # Generate hash
        return hashlib.sha256(key_string.encode()).hexdigest()
    
    def execute_idempotent(self, operation_name: str, operation_func: Callable,
                          parameters: Dict[str, Any] = None,
                          idempotency_key: str = None,
                          client_id: str = None,
                          ttl: int = None) -> OperationResult:
        """Execute operation with idempotency protection"""
        
        parameters = parameters or {}
        ttl = ttl or self.default_ttl
        
        # Generate or use provided idempotency key
        if idempotency_key is None:
            idempotency_key = self.generate_key(operation_name, parameters, client_id)
        
        with self.lock:
            # Check if operation already exists
            existing_result = self.store.get_operation(idempotency_key)
            
            if existing_result:
                # Operation already exists
                if existing_result.status == OperationStatus.COMPLETED:
                    # Return cached result
                    print(f"Returning cached result for key: {idempotency_key[:16]}...")
                    return existing_result
                elif existing_result.status == OperationStatus.IN_PROGRESS:
                    # Operation is in progress, wait or return current state
                    print(f"Operation in progress for key: {idempotency_key[:16]}...")
                    return existing_result
                elif existing_result.status == OperationStatus.FAILED:
                    # Previous attempt failed, allow retry
                    print(f"Retrying failed operation for key: {idempotency_key[:16]}...")
            
            # Create new operation record
            operation_id = str(uuid.uuid4())
            current_time = time.time()
            
            key_obj = IdempotencyKey(
                key=idempotency_key,
                created_at=current_time,
                expires_at=current_time + ttl,
                operation_id=operation_id,
                client_id=client_id
            )
            
            operation_result = OperationResult(
                operation_id=operation_id,
                status=OperationStatus.IN_PROGRESS,
                result=None,
                error=None,
                created_at=current_time,
                completed_at=None,
                attempts=1 if not existing_result else existing_result.attempts + 1,
                idempotency_key=idempotency_key
            )
            
            # Store initial state
            self.store.store_operation(key_obj, operation_result)
        
        # Execute operation outside of lock
        try:
            print(f"Executing operation '{operation_name}' with key: {idempotency_key[:16]}...")
            result = operation_func(**parameters)
            
            # Update with success
            operation_result.status = OperationStatus.COMPLETED
            operation_result.result = result
            operation_result.completed_at = time.time()
            
            self.store.update_operation(idempotency_key, operation_result)
            
            print(f"Operation completed successfully for key: {idempotency_key[:16]}...")
            return operation_result
            
        except Exception as e:
            # Update with failure
            operation_result.status = OperationStatus.FAILED
            operation_result.error = str(e)
            operation_result.completed_at = time.time()
            
            self.store.update_operation(idempotency_key, operation_result)
            
            print(f"Operation failed for key: {idempotency_key[:16]}... - {e}")
            return operation_result
    
    def get_operation_status(self, idempotency_key: str) -> Optional[OperationResult]:
        """Get status of operation by idempotency key"""
        return self.store.get_operation(idempotency_key)
    
    def _cleanup_loop(self):
        """Background cleanup of expired operations"""
        
        while self.cleanup_enabled:
            try:
                cleaned_count = self.store.cleanup_expired()
                if cleaned_count > 0:
                    print(f"Cleaned up {cleaned_count} expired idempotency keys")
                
                time.sleep(300)  # Cleanup every 5 minutes
                
            except Exception as e:
                print(f"Cleanup error: {e}")
                time.sleep(60)  # Wait before retrying
    
    def stop_cleanup(self):
        """Stop cleanup thread"""
        self.cleanup_enabled = False

# Idempotent decorator
def idempotent(operation_name: str = None, manager: IdempotencyManager = None,
              key_generator: Callable = None):
    """Decorator to make functions idempotent"""
    
    if manager is None:
        manager = IdempotencyManager()
    
    def decorator(func):
        nonlocal operation_name
        if operation_name is None:
            operation_name = func.__name__
        
        def wrapper(*args, **kwargs):
            # Generate parameters dict
            parameters = kwargs.copy()
            
            # Add positional args if any
            if args:
                parameters['_args'] = args
            
            # Generate custom key if key_generator provided
            if key_generator:
                idempotency_key = key_generator(*args, **kwargs)
            else:
                idempotency_key = None
            
            # Execute with idempotency
            result = manager.execute_idempotent(
                operation_name=operation_name,
                operation_func=lambda **params: func(*params.pop('_args', ()), **params),
                parameters=parameters,
                idempotency_key=idempotency_key
            )
            
            if result.status == OperationStatus.COMPLETED:
                return result.result
            elif result.status == OperationStatus.FAILED:
                raise Exception(result.error)
            else:
                raise Exception(f"Operation {result.status.value}")
        
        wrapper.idempotency_manager = manager
        return wrapper
    
    return decorator

# Example implementations
class PaymentService:
    """Example payment service with idempotent operations"""
    
    def __init__(self):
        self.idempotency_manager = IdempotencyManager()
        self.processed_payments = {}  # Simulate payment storage
        self.account_balances = {
            'user123': 1000.0,
            'user456': 500.0,
            'merchant789': 0.0
        }
    
    def process_payment(self, user_id: str, merchant_id: str, amount: float,
                       payment_method: str, idempotency_key: str = None) -> Dict[str, Any]:
        """Process payment with idempotency protection"""
        
        def payment_operation(user_id: str, merchant_id: str, amount: float, payment_method: str):
            # Simulate payment processing
            print(f"Processing payment: {user_id} -> {merchant_id}, ${amount}")
            
            # Check user balance
            if self.account_balances.get(user_id, 0) < amount:
                raise Exception("Insufficient funds")
            
            # Simulate processing time
            time.sleep(0.5)
            
            # Process payment
            payment_id = f"pay_{int(time.time())}_{len(self.processed_payments)}"
            
            # Update balances
            self.account_balances[user_id] -= amount
            self.account_balances[merchant_id] = self.account_balances.get(merchant_id, 0) + amount
            
            # Store payment record
            payment_record = {
                'payment_id': payment_id,
                'user_id': user_id,
                'merchant_id': merchant_id,
                'amount': amount,
                'payment_method': payment_method,
                'processed_at': time.time(),
                'status': 'completed'
            }
            
            self.processed_payments[payment_id] = payment_record
            
            return payment_record
        
        # Execute with idempotency
        parameters = {
            'user_id': user_id,
            'merchant_id': merchant_id,
            'amount': amount,
            'payment_method': payment_method
        }
        
        result = self.idempotency_manager.execute_idempotent(
            operation_name='process_payment',
            operation_func=payment_operation,
            parameters=parameters,
            idempotency_key=idempotency_key
        )
        
        if result.status == OperationStatus.COMPLETED:
            return result.result
        elif result.status == OperationStatus.FAILED:
            raise Exception(result.error)
        else:
            return {'status': result.status.value, 'operation_id': result.operation_id}

class OrderService:
    """Example order service with idempotent operations"""
    
    def __init__(self):
        self.orders = {}
        self.inventory = {
            'item1': 100,
            'item2': 50,
            'item3': 25
        }
    
    @idempotent('create_order')
    def create_order(self, user_id: str, items: List[Dict[str, Any]], 
                    shipping_address: Dict[str, str]) -> Dict[str, Any]:
        """Create order with automatic idempotency"""
        
        print(f"Creating order for user {user_id} with {len(items)} items")
        
        # Check inventory
        for item in items:
            item_id = item['item_id']
            quantity = item['quantity']
            
            if self.inventory.get(item_id, 0) < quantity:
                raise Exception(f"Insufficient inventory for item {item_id}")
        
        # Create order
        order_id = f"order_{int(time.time())}_{len(self.orders)}"
        
        # Update inventory
        for item in items:
            self.inventory[item['item_id']] -= item['quantity']
        
        # Store order
        order = {
            'order_id': order_id,
            'user_id': user_id,
            'items': items,
            'shipping_address': shipping_address,
            'status': 'confirmed',
            'created_at': time.time(),
            'total_amount': sum(item.get('price', 10) * item['quantity'] for item in items)
        }
        
        self.orders[order_id] = order
        
        return order

# Example usage and testing
print("=== Idempotency Demo ===")

# Test payment service
print("\n--- Payment Service Idempotency Test ---")
payment_service = PaymentService()

# Test normal payment
try:
    payment1 = payment_service.process_payment(
        user_id='user123',
        merchant_id='merchant789', 
        amount=100.0,
        payment_method='credit_card',
        idempotency_key='payment_001'
    )
    print(f"Payment 1: {payment1['payment_id']} - ${payment1['amount']}")
except Exception as e:
    print(f"Payment 1 failed: {e}")

# Test duplicate payment (should return same result)
try:
    payment2 = payment_service.process_payment(
        user_id='user123',
        merchant_id='merchant789',
        amount=100.0,
        payment_method='credit_card',
        idempotency_key='payment_001'  # Same key
    )
    print(f"Payment 2 (duplicate): {payment2['payment_id']} - ${payment2['amount']}")
    print(f"Same payment ID: {payment1['payment_id'] == payment2['payment_id']}")
except Exception as e:
    print(f"Payment 2 failed: {e}")

# Test different payment (should process normally)
try:
    payment3 = payment_service.process_payment(
        user_id='user123',
        merchant_id='merchant789',
        amount=50.0,
        payment_method='credit_card',
        idempotency_key='payment_002'  # Different key
    )
    print(f"Payment 3 (different): {payment3['payment_id']} - ${payment3['amount']}")
except Exception as e:
    print(f"Payment 3 failed: {e}")

# Check balances
print(f"\nAccount balances:")
for account, balance in payment_service.account_balances.items():
    print(f"  {account}: ${balance}")

# Test order service with decorator
print("\n--- Order Service Idempotency Test ---")
order_service = OrderService()

# Test order creation
order_items = [
    {'item_id': 'item1', 'quantity': 2, 'price': 25.0},
    {'item_id': 'item2', 'quantity': 1, 'price': 50.0}
]

shipping_address = {
    'street': '123 Main St',
    'city': 'Anytown',
    'zip': '12345'
}

try:
    order1 = order_service.create_order(
        user_id='user123',
        items=order_items,
        shipping_address=shipping_address
    )
    print(f"Order 1: {order1['order_id']} - ${order1['total_amount']}")
except Exception as e:
    print(f"Order 1 failed: {e}")

# Test duplicate order (should return same result)
try:
    order2 = order_service.create_order(
        user_id='user123',
        items=order_items,
        shipping_address=shipping_address
    )
    print(f"Order 2 (duplicate): {order2['order_id']} - ${order2['total_amount']}")
    print(f"Same order ID: {order1['order_id'] == order2['order_id']}")
except Exception as e:
    print(f"Order 2 failed: {e}")

# Check inventory
print(f"\nInventory levels:")
for item, quantity in order_service.inventory.items():
    print(f"  {item}: {quantity} units")

# Test idempotency manager statistics
print("\n--- Idempotency Statistics ---")
if hasattr(payment_service.idempotency_manager.store, 'get_stats'):
    payment_stats = payment_service.idempotency_manager.store.get_stats()
    print(f"Payment service operations: {payment_stats}")

if hasattr(order_service.create_order, 'idempotency_manager'):
    order_stats = order_service.create_order.idempotency_manager.store.get_stats()
    print(f"Order service operations: {order_stats}")

# Test concurrent idempotent operations
print("\n--- Concurrent Idempotency Test ---")

import concurrent.futures

def make_concurrent_payment(payment_id: str):
    """Make payment in concurrent thread"""
    try:
        result = payment_service.process_payment(
            user_id='user456',
            merchant_id='merchant789',
            amount=25.0,
            payment_method='debit_card',
            idempotency_key=payment_id
        )
        return f"Success: {result['payment_id']}"
    except Exception as e:
        return f"Failed: {e}"

# Submit same payment from multiple threads
with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
    futures = []
    
    # Submit 5 identical payment requests
    for i in range(5):
        future = executor.submit(make_concurrent_payment, 'concurrent_payment_001')
        futures.append(future)
    
    # Collect results
    results = []
    for future in concurrent.futures.as_completed(futures):
        result = future.result()
        results.append(result)
        print(f"Concurrent payment result: {result}")

# Verify only one payment was processed
unique_payment_ids = set()
for result in results:
    if "Success:" in result:
        payment_id = result.split(": ")[1]
        unique_payment_ids.add(payment_id)

print(f"Unique payment IDs from concurrent requests: {len(unique_payment_ids)}")
print(f"All results identical: {len(set(results)) == 1}")

# Cleanup
payment_service.idempotency_manager.stop_cleanup()

print("\n--- Idempotency Demo Completed ---")
```

## 🎯 Advanced Idempotency Patterns

```python
class DistributedIdempotencyManager:
    """Distributed idempotency manager using external storage"""
    
    def __init__(self, redis_client=None):
        self.redis_client = redis_client or MockRedisClient()
        self.local_cache = {}
        self.cache_ttl = 300  # 5 minutes local cache
        
    def execute_idempotent(self, operation_name: str, operation_func: Callable,
                          parameters: Dict[str, Any] = None,
                          idempotency_key: str = None,
                          ttl: int = 3600) -> OperationResult:
        """Execute operation with distributed idempotency"""
        
        parameters = parameters or {}
        
        if idempotency_key is None:
            idempotency_key = self._generate_key(operation_name, parameters)
        
        # Check local cache first
        cached_result = self._get_from_local_cache(idempotency_key)
        if cached_result:
            return cached_result
        
        # Check distributed store
        distributed_result = self._get_from_distributed_store(idempotency_key)
        if distributed_result:
            # Cache locally
            self._store_in_local_cache(idempotency_key, distributed_result)
            return distributed_result
        
        # Execute operation with distributed locking
        return self._execute_with_distributed_lock(
            operation_name, operation_func, parameters, idempotency_key, ttl
        )
    
    def _execute_with_distributed_lock(self, operation_name: str, operation_func: Callable,
                                     parameters: Dict[str, Any], idempotency_key: str, ttl: int):
        """Execute operation with distributed locking"""
        
        lock_key = f"lock:{idempotency_key}"
        lock_acquired = False
        
        try:
            # Try to acquire distributed lock
            lock_acquired = self.redis_client.set_nx(lock_key, "locked", ex=60)  # 60s lock timeout
            
            if not lock_acquired:
                # Another instance is processing, wait and check result
                time.sleep(0.5)
                result = self._get_from_distributed_store(idempotency_key)
                if result:
                    return result
                else:
                    raise Exception("Operation is being processed by another instance")
            
            # We have the lock, execute operation
            operation_id = str(uuid.uuid4())
            current_time = time.time()
            
            # Store initial state
            initial_result = OperationResult(
                operation_id=operation_id,
                status=OperationStatus.IN_PROGRESS,
                result=None,
                error=None,
                created_at=current_time,
                completed_at=None,
                attempts=1,
                idempotency_key=idempotency_key
            )
            
            self._store_in_distributed_store(idempotency_key, initial_result, ttl)
            
            try:
                # Execute operation
                result = operation_func(**parameters)
                
                # Update with success
                final_result = OperationResult(
                    operation_id=operation_id,
                    status=OperationStatus.COMPLETED,
                    result=result,
                    error=None,
                    created_at=current_time,
                    completed_at=time.time(),
                    attempts=1,
                    idempotency_key=idempotency_key
                )
                
                self._store_in_distributed_store(idempotency_key, final_result, ttl)
                self._store_in_local_cache(idempotency_key, final_result)
                
                return final_result
                
            except Exception as e:
                # Update with failure
                failed_result = OperationResult(
                    operation_id=operation_id,
                    status=OperationStatus.FAILED,
                    result=None,
                    error=str(e),
                    created_at=current_time,
                    completed_at=time.time(),
                    attempts=1,
                    idempotency_key=idempotency_key
                )
                
                self._store_in_distributed_store(idempotency_key, failed_result, ttl)
                return failed_result
                
        finally:
            # Release distributed lock
            if lock_acquired:
                self.redis_client.delete(lock_key)
    
    def _generate_key(self, operation_name: str, parameters: Dict[str, Any]) -> str:
        """Generate idempotency key"""
        key_string = f"{operation_name}:{json.dumps(parameters, sort_keys=True)}"
        return hashlib.sha256(key_string.encode()).hexdigest()
    
    def _get_from_local_cache(self, key: str) -> Optional[OperationResult]:
        """Get result from local cache"""
        if key in self.local_cache:
            cached_data, cached_time = self.local_cache[key]
            if time.time() - cached_time < self.cache_ttl:
                return cached_data
            else:
                del self.local_cache[key]
        return None
    
    def _store_in_local_cache(self, key: str, result: OperationResult):
        """Store result in local cache"""
        self.local_cache[key] = (result, time.time())
    
    def _get_from_distributed_store(self, key: str) -> Optional[OperationResult]:
        """Get result from distributed store"""
        data = self.redis_client.get(f"idempotency:{key}")
        if data:
            result_dict = json.loads(data)
            return OperationResult(
                operation_id=result_dict['operation_id'],
                status=OperationStatus(result_dict['status']),
                result=result_dict['result'],
                error=result_dict['error'],
                created_at=result_dict['created_at'],
                completed_at=result_dict['completed_at'],
                attempts=result_dict['attempts'],
                idempotency_key=result_dict['idempotency_key']
            )
        return None
    
    def _store_in_distributed_store(self, key: str, result: OperationResult, ttl: int):
        """Store result in distributed store"""
        data = json.dumps(result.to_dict())
        self.redis_client.setex(f"idempotency:{key}", ttl, data)

class MockRedisClient:
    """Mock Redis client for demonstration"""
    
    def __init__(self):
        self.data = {}
        self.locks = {}
    
    def get(self, key: str) -> Optional[str]:
        return self.data.get(key)
    
    def setex(self, key: str, ttl: int, value: str):
        self.data[key] = value
        # In real Redis, TTL would be handled automatically
    
    def set_nx(self, key: str, value: str, ex: int = None) -> bool:
        if key not in self.locks:
            self.locks[key] = {'value': value, 'expires': time.time() + (ex or 3600)}
            return True
        else:
            # Check if lock expired
            if time.time() > self.locks[key]['expires']:
                self.locks[key] = {'value': value, 'expires': time.time() + (ex or 3600)}
                return True
            return False
    
    def delete(self, key: str):
        self.data.pop(key, None)
        self.locks.pop(key, None)

class IdempotentHTTPClient:
    """HTTP client with built-in idempotency support"""
    
    def __init__(self, idempotency_manager: IdempotencyManager = None):
        self.idempotency_manager = idempotency_manager or IdempotencyManager()
    
    def post(self, url: str, data: Dict[str, Any], headers: Dict[str, str] = None,
             idempotency_key: str = None, timeout: float = 30.0) -> Dict[str, Any]:
        """Make idempotent POST request"""
        
        def http_request(url: str, data: Dict[str, Any], headers: Dict[str, str]):
            # Simulate HTTP request
            print(f"Making HTTP POST to {url}")
            time.sleep(0.2)  # Simulate network delay
            
            # Simulate occasional failures
            if 'fail' in url:
                raise Exception("HTTP 500 - Server Error")
            
            return {
                'status_code': 200,
                'response': {'id': f'response_{int(time.time())}', 'data': data},
                'headers': {'content-type': 'application/json'}
            }
        
        parameters = {
            'url': url,
            'data': data,
            'headers': headers or {}
        }
        
        result = self.idempotency_manager.execute_idempotent(
            operation_name='http_post',
            operation_func=http_request,
            parameters=parameters,
            idempotency_key=idempotency_key
        )
        
        if result.status == OperationStatus.COMPLETED:
            return result.result
        elif result.status == OperationStatus.FAILED:
            raise Exception(result.error)
        else:
            raise Exception(f"Request {result.status.value}")

# Example usage of advanced patterns
print("\n=== Advanced Idempotency Patterns Demo ===")

# Test distributed idempotency
print("\n--- Distributed Idempotency Test ---")
distributed_manager = DistributedIdempotencyManager()

def expensive_computation(x: int, y: int) -> int:
    """Simulate expensive computation"""
    print(f"Computing {x} + {y} (expensive operation)")
    time.sleep(1)  # Simulate computation time
    return x + y

# Execute expensive computation
result1 = distributed_manager.execute_idempotent(
    operation_name='expensive_computation',
    operation_func=expensive_computation,
    parameters={'x': 10, 'y': 20}
)

print(f"Computation 1: {result1.result} (status: {result1.status.value})")

# Execute same computation (should use cached result)
result2 = distributed_manager.execute_idempotent(
    operation_name='expensive_computation',
    operation_func=expensive_computation,
    parameters={'x': 10, 'y': 20}
)

print(f"Computation 2: {result2.result} (status: {result2.status.value})")
print(f"Same operation ID: {result1.operation_id == result2.operation_id}")

# Test idempotent HTTP client
print("\n--- Idempotent HTTP Client Test ---")
http_client = IdempotentHTTPClient()

# Make API request
api_data = {'user_id': 'user123', 'action': 'create_resource'}

try:
    response1 = http_client.post(
        url='https://api.example.com/resources',
        data=api_data,
        idempotency_key='api_request_001'
    )
    print(f"HTTP Response 1: {response1['response']['id']}")
except Exception as e:
    print(f"HTTP Request 1 failed: {e}")

# Make same API request (should return cached response)
try:
    response2 = http_client.post(
        url='https://api.example.com/resources',
        data=api_data,
        idempotency_key='api_request_001'
    )
    print(f"HTTP Response 2: {response2['response']['id']}")
    print(f"Same response ID: {response1['response']['id'] == response2['response']['id']}")
except Exception as e:
    print(f"HTTP Request 2 failed: {e}")

print("\n--- Advanced Idempotency Demo Completed ---")
```

## 📚 Conclusion

Idempotency is a fundamental property for building reliable distributed systems that can handle network failures, retries, and duplicate requests gracefully. From simple in-memory stores to sophisticated distributed implementations with caching and locking, idempotency ensures that operations can be safely repeated without unintended side effects.

**Key Takeaways:**

1. **Design for Retries**: Make operations idempotent from the beginning
2. **Use Proper Keys**: Generate deterministic keys from operation parameters
3. **Handle Concurrency**: Use locking to prevent race conditions
4. **Cache Results**: Store operation results for fast duplicate detection
5. **Set Appropriate TTLs**: Balance storage costs with retry windows

The future of idempotency includes integration with event sourcing systems, automatic key generation from API signatures, and machine learning-powered duplicate detection. Whether building payment systems, order processing, or any distributed application, implementing robust idempotency patterns is essential for creating reliable, user-friendly systems.

Remember: idempotency is not just about preventing duplicate operations—it's about building systems that users and other systems can interact with confidently, knowing that retries and network issues won't cause unintended consequences.
