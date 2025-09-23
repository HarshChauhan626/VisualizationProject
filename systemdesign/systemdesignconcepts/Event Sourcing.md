# Event Sourcing: Building Systems on Immutable Events

## 🎯 What is Event Sourcing?

Event Sourcing is like keeping a detailed journal of everything that happens in your life instead of just maintaining a current status summary. Rather than storing just the current state ("I have $1000 in my bank account"), event sourcing stores every event that led to that state ("Deposited $500", "Withdrew $200", "Deposited $700"). This approach provides a complete audit trail and enables powerful capabilities like time travel, replay, and rebuilding state from scratch.

## 🏗️ Core Concepts

### The Life Journal Analogy
- **Events**: Individual entries in your journal (what happened, when, why)
- **Event Store**: The complete journal with all entries
- **Current State**: Summary derived from reading all journal entries
- **Snapshots**: Occasional summaries to avoid re-reading everything
- **Projections**: Different views of your life story (financial, health, career)
- **Time Travel**: Ability to see what your state was at any point in history

### Why Event Sourcing Matters
1. **Complete Audit Trail**: Never lose information about what happened
2. **Temporal Queries**: Answer questions about past states
3. **Replay Capability**: Rebuild state by replaying events
4. **Multiple Views**: Create different projections from same events
5. **Debugging Power**: Understand exactly how state was derived

## 📚 Event Sourcing Implementation

```python
import time
import json
import uuid
import threading
from typing import Dict, List, Optional, Any, Callable, Type
from enum import Enum
from dataclasses import dataclass, asdict, field
from collections import defaultdict
from abc import ABC, abstractmethod
import copy

class EventType(Enum):
    ACCOUNT_CREATED = "account_created"
    MONEY_DEPOSITED = "money_deposited"
    MONEY_WITHDRAWN = "money_withdrawn"
    ACCOUNT_CLOSED = "account_closed"
    ORDER_PLACED = "order_placed"
    ORDER_CONFIRMED = "order_confirmed"
    ORDER_SHIPPED = "order_shipped"
    ORDER_DELIVERED = "order_delivered"
    ORDER_CANCELLED = "order_cancelled"

@dataclass
class Event:
    event_id: str
    aggregate_id: str
    event_type: EventType
    event_data: Dict[str, Any]
    timestamp: float
    version: int
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert event to dictionary for storage"""
        return {
            'event_id': self.event_id,
            'aggregate_id': self.aggregate_id,
            'event_type': self.event_type.value,
            'event_data': self.event_data,
            'timestamp': self.timestamp,
            'version': self.version,
            'metadata': self.metadata
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> 'Event':
        """Create event from dictionary"""
        return cls(
            event_id=data['event_id'],
            aggregate_id=data['aggregate_id'],
            event_type=EventType(data['event_type']),
            event_data=data['event_data'],
            timestamp=data['timestamp'],
            version=data['version'],
            metadata=data.get('metadata', {})
        )

class EventStore(ABC):
    """Abstract event store interface"""
    
    @abstractmethod
    def append_events(self, aggregate_id: str, events: List[Event], expected_version: int) -> bool:
        """Append events to aggregate stream"""
        pass
    
    @abstractmethod
    def get_events(self, aggregate_id: str, from_version: int = 0) -> List[Event]:
        """Get events for aggregate from specified version"""
        pass
    
    @abstractmethod
    def get_all_events(self, from_timestamp: float = 0) -> List[Event]:
        """Get all events from specified timestamp"""
        pass
    
    @abstractmethod
    def get_events_by_type(self, event_type: EventType, from_timestamp: float = 0) -> List[Event]:
        """Get events of specific type"""
        pass

class InMemoryEventStore(EventStore):
    """In-memory implementation of event store"""
    
    def __init__(self):
        self.events: Dict[str, List[Event]] = defaultdict(list)  # aggregate_id -> events
        self.all_events: List[Event] = []
        self.lock = threading.RLock()
        
    def append_events(self, aggregate_id: str, events: List[Event], expected_version: int) -> bool:
        """Append events to aggregate stream with optimistic concurrency control"""
        
        with self.lock:
            current_events = self.events[aggregate_id]
            current_version = len(current_events)
            
            # Check expected version for optimistic concurrency control
            if expected_version != current_version:
                return False  # Concurrency conflict
            
            # Append events
            for event in events:
                event.version = current_version + 1
                current_events.append(event)
                self.all_events.append(event)
                current_version += 1
            
            return True
    
    def get_events(self, aggregate_id: str, from_version: int = 0) -> List[Event]:
        """Get events for aggregate from specified version"""
        
        with self.lock:
            events = self.events.get(aggregate_id, [])
            return [e for e in events if e.version > from_version]
    
    def get_all_events(self, from_timestamp: float = 0) -> List[Event]:
        """Get all events from specified timestamp"""
        
        with self.lock:
            return [e for e in self.all_events if e.timestamp >= from_timestamp]
    
    def get_events_by_type(self, event_type: EventType, from_timestamp: float = 0) -> List[Event]:
        """Get events of specific type"""
        
        with self.lock:
            return [e for e in self.all_events 
                   if e.event_type == event_type and e.timestamp >= from_timestamp]
    
    def get_aggregate_version(self, aggregate_id: str) -> int:
        """Get current version of aggregate"""
        
        with self.lock:
            return len(self.events.get(aggregate_id, []))
    
    def get_stats(self) -> Dict[str, Any]:
        """Get event store statistics"""
        
        with self.lock:
            event_type_counts = defaultdict(int)
            
            for event in self.all_events:
                event_type_counts[event.event_type.value] += 1
            
            return {
                'total_events': len(self.all_events),
                'total_aggregates': len(self.events),
                'event_type_distribution': dict(event_type_counts),
                'storage_size_estimate': len(self.all_events) * 1024  # Rough estimate
            }

class Aggregate(ABC):
    """Base class for aggregates in event sourcing"""
    
    def __init__(self, aggregate_id: str):
        self.aggregate_id = aggregate_id
        self.version = 0
        self.uncommitted_events: List[Event] = []
    
    @abstractmethod
    def apply_event(self, event: Event):
        """Apply event to update aggregate state"""
        pass
    
    def raise_event(self, event_type: EventType, event_data: Dict[str, Any], metadata: Dict[str, Any] = None):
        """Raise a new event"""
        
        event = Event(
            event_id=str(uuid.uuid4()),
            aggregate_id=self.aggregate_id,
            event_type=event_type,
            event_data=event_data,
            timestamp=time.time(),
            version=self.version + 1,
            metadata=metadata or {}
        )
        
        self.uncommitted_events.append(event)
        self.apply_event(event)
    
    def mark_events_as_committed(self):
        """Mark all uncommitted events as committed"""
        self.uncommitted_events.clear()
    
    def load_from_history(self, events: List[Event]):
        """Load aggregate from event history"""
        
        for event in sorted(events, key=lambda e: e.version):
            self.apply_event(event)

class BankAccount(Aggregate):
    """Bank account aggregate using event sourcing"""
    
    def __init__(self, account_id: str):
        super().__init__(account_id)
        self.account_holder = ""
        self.balance = 0.0
        self.is_active = False
        self.created_at = None
        self.closed_at = None
    
    def create_account(self, account_holder: str, initial_deposit: float = 0.0):
        """Create new bank account"""
        
        if self.is_active:
            raise Exception("Account already exists")
        
        self.raise_event(EventType.ACCOUNT_CREATED, {
            'account_holder': account_holder,
            'initial_deposit': initial_deposit
        })
        
        if initial_deposit > 0:
            self.raise_event(EventType.MONEY_DEPOSITED, {
                'amount': initial_deposit,
                'description': 'Initial deposit'
            })
    
    def deposit(self, amount: float, description: str = ""):
        """Deposit money to account"""
        
        if not self.is_active:
            raise Exception("Account is not active")
        
        if amount <= 0:
            raise Exception("Deposit amount must be positive")
        
        self.raise_event(EventType.MONEY_DEPOSITED, {
            'amount': amount,
            'description': description,
            'balance_after': self.balance + amount
        })
    
    def withdraw(self, amount: float, description: str = ""):
        """Withdraw money from account"""
        
        if not self.is_active:
            raise Exception("Account is not active")
        
        if amount <= 0:
            raise Exception("Withdrawal amount must be positive")
        
        if amount > self.balance:
            raise Exception("Insufficient funds")
        
        self.raise_event(EventType.MONEY_WITHDRAWN, {
            'amount': amount,
            'description': description,
            'balance_after': self.balance - amount
        })
    
    def close_account(self):
        """Close bank account"""
        
        if not self.is_active:
            raise Exception("Account is already closed")
        
        self.raise_event(EventType.ACCOUNT_CLOSED, {
            'final_balance': self.balance
        })
    
    def apply_event(self, event: Event):
        """Apply event to update account state"""
        
        if event.event_type == EventType.ACCOUNT_CREATED:
            self.account_holder = event.event_data['account_holder']
            self.is_active = True
            self.created_at = event.timestamp
            
        elif event.event_type == EventType.MONEY_DEPOSITED:
            self.balance += event.event_data['amount']
            
        elif event.event_type == EventType.MONEY_WITHDRAWN:
            self.balance -= event.event_data['amount']
            
        elif event.event_type == EventType.ACCOUNT_CLOSED:
            self.is_active = False
            self.closed_at = event.timestamp
        
        self.version = event.version
    
    def get_state(self) -> Dict[str, Any]:
        """Get current account state"""
        
        return {
            'account_id': self.aggregate_id,
            'account_holder': self.account_holder,
            'balance': self.balance,
            'is_active': self.is_active,
            'version': self.version,
            'created_at': self.created_at,
            'closed_at': self.closed_at
        }

class Order(Aggregate):
    """Order aggregate for e-commerce"""
    
    def __init__(self, order_id: str):
        super().__init__(order_id)
        self.customer_id = ""
        self.items = []
        self.total_amount = 0.0
        self.status = "draft"
        self.shipping_address = {}
        self.created_at = None
        self.confirmed_at = None
        self.shipped_at = None
        self.delivered_at = None
    
    def place_order(self, customer_id: str, items: List[Dict[str, Any]], shipping_address: Dict[str, str]):
        """Place new order"""
        
        if self.status != "draft":
            raise Exception("Order already placed")
        
        total_amount = sum(item['price'] * item['quantity'] for item in items)
        
        self.raise_event(EventType.ORDER_PLACED, {
            'customer_id': customer_id,
            'items': items,
            'total_amount': total_amount,
            'shipping_address': shipping_address
        })
    
    def confirm_order(self):
        """Confirm order"""
        
        if self.status != "placed":
            raise Exception(f"Cannot confirm order in status: {self.status}")
        
        self.raise_event(EventType.ORDER_CONFIRMED, {
            'confirmed_at': time.time()
        })
    
    def ship_order(self, tracking_number: str):
        """Ship order"""
        
        if self.status != "confirmed":
            raise Exception(f"Cannot ship order in status: {self.status}")
        
        self.raise_event(EventType.ORDER_SHIPPED, {
            'tracking_number': tracking_number,
            'shipped_at': time.time()
        })
    
    def deliver_order(self):
        """Mark order as delivered"""
        
        if self.status != "shipped":
            raise Exception(f"Cannot deliver order in status: {self.status}")
        
        self.raise_event(EventType.ORDER_DELIVERED, {
            'delivered_at': time.time()
        })
    
    def cancel_order(self, reason: str):
        """Cancel order"""
        
        if self.status in ["delivered", "cancelled"]:
            raise Exception(f"Cannot cancel order in status: {self.status}")
        
        self.raise_event(EventType.ORDER_CANCELLED, {
            'reason': reason,
            'cancelled_at': time.time()
        })
    
    def apply_event(self, event: Event):
        """Apply event to update order state"""
        
        if event.event_type == EventType.ORDER_PLACED:
            self.customer_id = event.event_data['customer_id']
            self.items = event.event_data['items']
            self.total_amount = event.event_data['total_amount']
            self.shipping_address = event.event_data['shipping_address']
            self.status = "placed"
            self.created_at = event.timestamp
            
        elif event.event_type == EventType.ORDER_CONFIRMED:
            self.status = "confirmed"
            self.confirmed_at = event.timestamp
            
        elif event.event_type == EventType.ORDER_SHIPPED:
            self.status = "shipped"
            self.shipped_at = event.timestamp
            
        elif event.event_type == EventType.ORDER_DELIVERED:
            self.status = "delivered"
            self.delivered_at = event.timestamp
            
        elif event.event_type == EventType.ORDER_CANCELLED:
            self.status = "cancelled"
        
        self.version = event.version

class Repository:
    """Repository for loading and saving aggregates"""
    
    def __init__(self, event_store: EventStore):
        self.event_store = event_store
    
    def save(self, aggregate: Aggregate) -> bool:
        """Save aggregate by storing its uncommitted events"""
        
        if not aggregate.uncommitted_events:
            return True  # Nothing to save
        
        # Try to append events with optimistic concurrency control
        success = self.event_store.append_events(
            aggregate.aggregate_id,
            aggregate.uncommitted_events,
            aggregate.version - len(aggregate.uncommitted_events)
        )
        
        if success:
            aggregate.mark_events_as_committed()
        
        return success
    
    def load(self, aggregate_class: Type[Aggregate], aggregate_id: str) -> Optional[Aggregate]:
        """Load aggregate from event store"""
        
        events = self.event_store.get_events(aggregate_id)
        
        if not events:
            return None
        
        aggregate = aggregate_class(aggregate_id)
        aggregate.load_from_history(events)
        
        return aggregate

class Projection(ABC):
    """Base class for event projections"""
    
    def __init__(self, name: str):
        self.name = name
        self.last_processed_timestamp = 0.0
    
    @abstractmethod
    def handle_event(self, event: Event):
        """Handle individual event"""
        pass
    
    def process_events(self, events: List[Event]):
        """Process multiple events"""
        
        for event in sorted(events, key=lambda e: e.timestamp):
            if event.timestamp > self.last_processed_timestamp:
                self.handle_event(event)
                self.last_processed_timestamp = event.timestamp

class AccountBalanceProjection(Projection):
    """Projection for account balances"""
    
    def __init__(self):
        super().__init__("account_balance")
        self.balances: Dict[str, Dict[str, Any]] = {}
    
    def handle_event(self, event: Event):
        """Handle account-related events"""
        
        if event.event_type == EventType.ACCOUNT_CREATED:
            self.balances[event.aggregate_id] = {
                'account_id': event.aggregate_id,
                'account_holder': event.event_data['account_holder'],
                'balance': 0.0,
                'is_active': True,
                'last_updated': event.timestamp
            }
            
        elif event.event_type == EventType.MONEY_DEPOSITED:
            if event.aggregate_id in self.balances:
                account = self.balances[event.aggregate_id]
                account['balance'] += event.event_data['amount']
                account['last_updated'] = event.timestamp
                
        elif event.event_type == EventType.MONEY_WITHDRAWN:
            if event.aggregate_id in self.balances:
                account = self.balances[event.aggregate_id]
                account['balance'] -= event.event_data['amount']
                account['last_updated'] = event.timestamp
                
        elif event.event_type == EventType.ACCOUNT_CLOSED:
            if event.aggregate_id in self.balances:
                account = self.balances[event.aggregate_id]
                account['is_active'] = False
                account['last_updated'] = event.timestamp
    
    def get_balance(self, account_id: str) -> Optional[Dict[str, Any]]:
        """Get account balance"""
        return self.balances.get(account_id)
    
    def get_all_balances(self) -> Dict[str, Dict[str, Any]]:
        """Get all account balances"""
        return self.balances.copy()

class OrderStatusProjection(Projection):
    """Projection for order statuses"""
    
    def __init__(self):
        super().__init__("order_status")
        self.orders: Dict[str, Dict[str, Any]] = {}
    
    def handle_event(self, event: Event):
        """Handle order-related events"""
        
        if event.event_type == EventType.ORDER_PLACED:
            self.orders[event.aggregate_id] = {
                'order_id': event.aggregate_id,
                'customer_id': event.event_data['customer_id'],
                'total_amount': event.event_data['total_amount'],
                'status': 'placed',
                'created_at': event.timestamp,
                'last_updated': event.timestamp
            }
            
        elif event.event_type in [EventType.ORDER_CONFIRMED, EventType.ORDER_SHIPPED, 
                                EventType.ORDER_DELIVERED, EventType.ORDER_CANCELLED]:
            if event.aggregate_id in self.orders:
                order = self.orders[event.aggregate_id]
                
                if event.event_type == EventType.ORDER_CONFIRMED:
                    order['status'] = 'confirmed'
                elif event.event_type == EventType.ORDER_SHIPPED:
                    order['status'] = 'shipped'
                elif event.event_type == EventType.ORDER_DELIVERED:
                    order['status'] = 'delivered'
                elif event.event_type == EventType.ORDER_CANCELLED:
                    order['status'] = 'cancelled'
                
                order['last_updated'] = event.timestamp
    
    def get_order_status(self, order_id: str) -> Optional[Dict[str, Any]]:
        """Get order status"""
        return self.orders.get(order_id)
    
    def get_orders_by_customer(self, customer_id: str) -> List[Dict[str, Any]]:
        """Get orders by customer"""
        return [order for order in self.orders.values() 
               if order['customer_id'] == customer_id]
    
    def get_orders_by_status(self, status: str) -> List[Dict[str, Any]]:
        """Get orders by status"""
        return [order for order in self.orders.values() 
               if order['status'] == status]

class EventSourcingEngine:
    """Main event sourcing engine"""
    
    def __init__(self, event_store: EventStore):
        self.event_store = event_store
        self.repository = Repository(event_store)
        self.projections: Dict[str, Projection] = {}
        self.event_handlers: Dict[EventType, List[Callable]] = defaultdict(list)
        
        # Background projection updates
        self.projection_update_enabled = True
        self.update_thread = threading.Thread(target=self._projection_update_loop)
        self.update_thread.daemon = True
        self.update_thread.start()
    
    def add_projection(self, projection: Projection):
        """Add projection to engine"""
        self.projections[projection.name] = projection
        
        # Rebuild projection from all events
        all_events = self.event_store.get_all_events()
        projection.process_events(all_events)
        
        print(f"Added projection: {projection.name}")
    
    def add_event_handler(self, event_type: EventType, handler: Callable[[Event], None]):
        """Add event handler"""
        self.event_handlers[event_type].append(handler)
    
    def save_aggregate(self, aggregate: Aggregate) -> bool:
        """Save aggregate and trigger projections"""
        
        uncommitted_events = aggregate.uncommitted_events.copy()
        success = self.repository.save(aggregate)
        
        if success:
            # Process events through handlers
            for event in uncommitted_events:
                handlers = self.event_handlers.get(event.event_type, [])
                for handler in handlers:
                    try:
                        handler(event)
                    except Exception as e:
                        print(f"Event handler error: {e}")
        
        return success
    
    def load_aggregate(self, aggregate_class: Type[Aggregate], aggregate_id: str) -> Optional[Aggregate]:
        """Load aggregate from repository"""
        return self.repository.load(aggregate_class, aggregate_id)
    
    def _projection_update_loop(self):
        """Background loop to update projections"""
        
        while self.projection_update_enabled:
            try:
                # Get new events for each projection
                for projection in self.projections.values():
                    new_events = self.event_store.get_all_events(projection.last_processed_timestamp)
                    
                    if new_events:
                        projection.process_events(new_events)
                
                time.sleep(1)  # Update every second
                
            except Exception as e:
                print(f"Projection update error: {e}")
                time.sleep(5)
    
    def stop_projection_updates(self):
        """Stop projection updates"""
        self.projection_update_enabled = False
    
    def replay_events(self, from_timestamp: float = 0) -> Dict[str, Any]:
        """Replay events to rebuild projections"""
        
        events = self.event_store.get_all_events(from_timestamp)
        
        # Clear and rebuild projections
        for projection in self.projections.values():
            projection.last_processed_timestamp = from_timestamp
            projection.process_events(events)
        
        return {
            'events_replayed': len(events),
            'projections_updated': len(self.projections),
            'from_timestamp': from_timestamp
        }
    
    def get_aggregate_at_point_in_time(self, aggregate_class: Type[Aggregate], 
                                     aggregate_id: str, timestamp: float) -> Optional[Aggregate]:
        """Get aggregate state at specific point in time"""
        
        all_events = self.event_store.get_events(aggregate_id)
        historical_events = [e for e in all_events if e.timestamp <= timestamp]
        
        if not historical_events:
            return None
        
        aggregate = aggregate_class(aggregate_id)
        aggregate.load_from_history(historical_events)
        
        return aggregate

# Example usage and testing
print("=== Event Sourcing Demo ===")

# Create event sourcing infrastructure
event_store = InMemoryEventStore()
engine = EventSourcingEngine(event_store)

# Add projections
balance_projection = AccountBalanceProjection()
order_projection = OrderStatusProjection()

engine.add_projection(balance_projection)
engine.add_projection(order_projection)

# Test bank account
print("\n--- Bank Account Event Sourcing ---")

# Create and operate on bank account
account = BankAccount("account_001")
account.create_account("John Doe", 1000.0)
account.deposit(500.0, "Salary deposit")
account.withdraw(200.0, "ATM withdrawal")
account.deposit(300.0, "Bonus")

# Save account
success = engine.save_aggregate(account)
print(f"Account saved: {success}")

# Load account from events
loaded_account = engine.load_aggregate(BankAccount, "account_001")
print(f"Loaded account state: {loaded_account.get_state()}")

# Check projection
balance_info = balance_projection.get_balance("account_001")
print(f"Balance projection: {balance_info}")

# Test order processing
print("\n--- Order Event Sourcing ---")

# Create and process order
order = Order("order_001")
order.place_order("customer_123", [
    {'item_id': 'item1', 'quantity': 2, 'price': 25.0},
    {'item_id': 'item2', 'quantity': 1, 'price': 50.0}
], {'street': '123 Main St', 'city': 'Anytown', 'zip': '12345'})

order.confirm_order()
order.ship_order("TRACK123")

# Save order
engine.save_aggregate(order)

# Check order projection
order_status = order_projection.get_order_status("order_001")
print(f"Order status: {order_status}")

# Test time travel
print("\n--- Time Travel Example ---")

# Get account state at different points in time
current_time = time.time()

# Get state after creation
historical_account = engine.get_aggregate_at_point_in_time(
    BankAccount, "account_001", current_time - 10
)

if historical_account:
    print(f"Historical account state: {historical_account.get_state()}")

# Test event replay
print("\n--- Event Replay ---")

# Get current projections
print(f"Current balance: {balance_projection.get_balance('account_001')}")

# Replay events from beginning
replay_result = engine.replay_events()
print(f"Replay result: {replay_result}")

# Check projections after replay
print(f"Balance after replay: {balance_projection.get_balance('account_001')}")

# Event store statistics
print("\n--- Event Store Statistics ---")
stats = event_store.get_stats()
print(f"Total events: {stats['total_events']}")
print(f"Total aggregates: {stats['total_aggregates']}")
print(f"Event type distribution: {stats['event_type_distribution']}")

# Show all events for account
print("\n--- Account Event History ---")
account_events = event_store.get_events("account_001")
for event in account_events:
    print(f"  {event.event_type.value}: {event.event_data} (v{event.version})")

# Cleanup
engine.stop_projection_updates()

print("\n--- Event Sourcing Demo Completed ---")
```

## 📚 Conclusion

Event Sourcing provides a powerful foundation for building systems that need complete auditability, temporal queries, and the ability to reconstruct state from a series of immutable events. From simple bank accounts to complex order processing systems, event sourcing enables sophisticated capabilities like time travel, replay, and multiple projections from the same event stream.

**Key Takeaways:**

1. **Immutable Events**: Store what happened, not just current state
2. **Complete Audit Trail**: Never lose information about system changes
3. **Temporal Queries**: Answer questions about past states
4. **Multiple Views**: Create different projections from same events
5. **Replay Capability**: Rebuild state and fix bugs by replaying events

The future of event sourcing includes integration with blockchain technologies, machine learning-powered event analysis, and cloud-native event stores with global distribution. Whether building financial systems, e-commerce platforms, or any domain requiring strong auditability, event sourcing provides the foundation for systems that can evolve and adapt while maintaining complete historical context.

Remember: event sourcing is not just about storing events—it's about building systems that can tell the complete story of how they arrived at their current state, enabling powerful debugging, compliance, and analytical capabilities.
