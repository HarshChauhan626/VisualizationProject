# Consistency Patterns: Managing Data Consistency in Distributed Systems

## 🎯 What are Consistency Patterns?

Consistency patterns are like rules for keeping multiple copies of a document synchronized across different offices. Just as offices might have different policies for when and how documents are updated, distributed systems have different patterns for ensuring data consistency across multiple nodes.

## 🏗️ Core Concepts

### The Office Document Analogy
- **Strong Consistency**: All offices must have the exact same version before anyone can make changes
- **Eventual Consistency**: Offices update their copies over time, eventually all will match
- **Weak Consistency**: Offices might have different versions, and that's acceptable
- **Causal Consistency**: Changes that depend on each other happen in the right order

### Why Consistency Patterns Matter
1. **Data Integrity**: Ensure data remains accurate across all nodes
2. **User Experience**: Users see predictable behavior from the system
3. **Business Logic**: Support complex operations that span multiple data items
4. **Performance Trade-offs**: Balance consistency with speed and availability
5. **Conflict Resolution**: Handle concurrent updates gracefully

## 💪 Strong Consistency

### Definition
All nodes see the same data at the same time. Every read receives the most recent write or an error.

```python
class StrongConsistency:
    def __init__(self):
        self.nodes = [Node1(), Node2(), Node3()]
        self.lock = DistributedLock()
    
    def write(self, key, value):
        # Acquire distributed lock
        with self.lock.acquire(key):
            # Write to ALL nodes before confirming success
            for node in self.nodes:
                if not node.write(key, value):
                    # If any node fails, rollback all changes
                    self.rollback_all_nodes(key)
                    raise WriteFailedException("Could not achieve strong consistency")
            
            return "Write successful - all nodes updated"
    
    def read(self, key):
        # Read from majority to ensure latest value
        responses = []
        for node in self.nodes:
            try:
                responses.append(node.read(key))
            except Exception:
                pass
        
        if len(responses) >= len(self.nodes) // 2 + 1:
            # Return the most recent version
            return self.get_latest_version(responses)
        else:
            raise ReadFailedException("Cannot guarantee strong consistency")
```

**Real-world example**: Bank account balances - when you transfer money, both accounts must be updated atomically.

**Use Cases**:
- Financial transactions
- Inventory management
- User authentication systems
- Critical business data

**Trade-offs**:
- **Pros**: Data is always consistent, no conflicts
- **Cons**: Higher latency, reduced availability during network issues

### ACID Transactions
```python
class ACIDTransaction:
    def transfer_money(self, from_account, to_account, amount):
        transaction = self.begin_transaction()
        
        try:
            # Atomicity: All operations succeed or fail together
            from_balance = transaction.read(f"balance:{from_account}")
            if from_balance < amount:
                raise InsufficientFundsError()
            
            # Update both accounts
            transaction.write(f"balance:{from_account}", from_balance - amount)
            transaction.write(f"balance:{to_account}", 
                            transaction.read(f"balance:{to_account}") + amount)
            
            # Consistency: Business rules maintained
            self.validate_business_rules(transaction)
            
            # Isolation: Other transactions don't see partial updates
            # Durability: Changes persisted to disk
            transaction.commit()
            
            return "Transfer successful"
            
        except Exception as e:
            transaction.rollback()
            raise e
```

## 🌊 Eventual Consistency

### Definition
System will become consistent over time, given that no new updates are made to the data item.

```python
class EventualConsistency:
    def __init__(self):
        self.nodes = [Node1(), Node2(), Node3()]
        self.replication_queue = Queue()
        self.background_sync = BackgroundSyncProcess()
    
    def write(self, key, value):
        # Write to primary node immediately
        primary_node = self.get_primary_node(key)
        result = primary_node.write(key, value)
        
        # Queue replication to other nodes (asynchronous)
        for node in self.get_replica_nodes(key):
            self.replication_queue.put({
                'node': node,
                'key': key,
                'value': value,
                'timestamp': time.time()
            })
        
        return result  # Return immediately
    
    def read(self, key):
        # Read from any available node (may return stale data)
        for node in self.nodes:
            try:
                return node.read(key)
            except Exception:
                continue
        
        raise NoNodesAvailableError()
    
    def background_replication(self):
        # Background process ensures eventual consistency
        while True:
            replication_task = self.replication_queue.get()
            try:
                node = replication_task['node']
                node.write(replication_task['key'], replication_task['value'])
            except Exception as e:
                # Retry later
                self.replication_queue.put(replication_task)
                time.sleep(60)  # Wait before retry
```

**Real-world example**: Social media posts - it's okay if your post appears on friends' feeds a few seconds later.

**Use Cases**:
- Social media feeds
- Content distribution
- Analytics and reporting
- Non-critical user data

**Trade-offs**:
- **Pros**: High availability, low latency, good scalability
- **Cons**: Temporary inconsistencies, complex conflict resolution

### DNS Example
```python
class DNSEventualConsistency:
    def __init__(self):
        self.authoritative_servers = [Server1(), Server2()]
        self.caching_servers = [Cache1(), Cache2(), Cache3()]
        self.ttl = 3600  # 1 hour
    
    def update_dns_record(self, domain, ip_address):
        # Update authoritative servers
        for server in self.authoritative_servers:
            server.update_record(domain, ip_address, ttl=self.ttl)
        
        # Caching servers will eventually pick up the change
        # when their cached records expire
        return "DNS record updated - will propagate within 1 hour"
    
    def resolve_domain(self, domain):
        # Check cache first
        for cache in self.caching_servers:
            try:
                record = cache.get_record(domain)
                if not record.is_expired():
                    return record.ip_address  # May be stale
            except CacheMissException:
                continue
        
        # Query authoritative server if not cached
        for server in self.authoritative_servers:
            try:
                return server.get_record(domain).ip_address
            except Exception:
                continue
```

## 🔄 Weak Consistency

### Definition
System makes no guarantees about when all nodes will be consistent. Applications must handle inconsistent data.

```python
class WeakConsistency:
    def __init__(self):
        self.nodes = [Node1(), Node2(), Node3()]
    
    def write(self, key, value):
        # Write to any available node
        for node in self.nodes:
            try:
                result = node.write(key, value)
                # Don't wait for replication
                self.async_replicate(key, value, exclude=node)
                return result
            except Exception:
                continue
        
        raise NoNodesAvailableError()
    
    def read(self, key):
        # Read from any node - no consistency guarantees
        node = random.choice(self.nodes)
        return node.read(key)  # Data may be stale or inconsistent
    
    def async_replicate(self, key, value, exclude=None):
        # Best-effort replication
        for node in self.nodes:
            if node != exclude:
                try:
                    asyncio.create_task(node.write(key, value))
                except Exception:
                    pass  # Ignore failures
```

**Real-world example**: Gaming leaderboards - it's okay if players see slightly different rankings temporarily.

**Use Cases**:
- Real-time gaming
- Live sports scores
- Stock price feeds
- IoT sensor data

## 🔗 Causal Consistency

### Definition
Operations that are causally related are seen by all nodes in the same order. Concurrent operations may be seen in different orders.

```python
class CausalConsistency:
    def __init__(self):
        self.nodes = [Node1(), Node2(), Node3()]
        self.vector_clock = VectorClock()
    
    def write(self, key, value, dependencies=None):
        # Increment vector clock
        timestamp = self.vector_clock.increment()
        
        # Create causal metadata
        causal_metadata = {
            'timestamp': timestamp,
            'dependencies': dependencies or [],
            'node_id': self.get_node_id()
        }
        
        # Write with causal information
        for node in self.nodes:
            node.write_with_causality(key, value, causal_metadata)
        
        return timestamp
    
    def read(self, key):
        # Read and check causal dependencies
        responses = []
        for node in self.nodes:
            try:
                response = node.read_with_causality(key)
                responses.append(response)
            except Exception:
                continue
        
        # Return causally consistent view
        return self.resolve_causal_order(responses)

# Example: Social media comments
class SocialMediaCausality:
    def post_comment(self, post_id, comment_text, user_id):
        # Original post is a dependency
        post_timestamp = self.get_post_timestamp(post_id)
        
        comment_timestamp = self.write(
            f"comment:{uuid.uuid4()}", 
            {
                'text': comment_text,
                'user_id': user_id,
                'post_id': post_id
            },
            dependencies=[post_timestamp]
        )
        
        return comment_timestamp
    
    def reply_to_comment(self, original_comment_id, reply_text, user_id):
        # Reply depends on original comment
        original_comment_timestamp = self.get_comment_timestamp(original_comment_id)
        
        reply_timestamp = self.write(
            f"comment:{uuid.uuid4()}",
            {
                'text': reply_text,
                'user_id': user_id,
                'reply_to': original_comment_id
            },
            dependencies=[original_comment_timestamp]
        )
        
        return reply_timestamp
```

**Real-world example**: Social media threads where replies must appear after the original comment, but concurrent comments can appear in any order.

## 🔄 Session Consistency

### Definition
Guarantees consistency within a single user session, but not across different sessions.

```python
class SessionConsistency:
    def __init__(self):
        self.nodes = [Node1(), Node2(), Node3()]
        self.session_store = {}
    
    def create_session(self, user_id):
        session_id = str(uuid.uuid4())
        self.session_store[session_id] = {
            'user_id': user_id,
            'preferred_node': self.select_node_for_user(user_id),
            'read_timestamp': 0,
            'write_timestamp': 0
        }
        return session_id
    
    def read(self, session_id, key):
        session = self.session_store[session_id]
        node = session['preferred_node']
        
        # Ensure reads are monotonic within session
        data, timestamp = node.read_with_timestamp(key)
        
        if timestamp >= session['read_timestamp']:
            session['read_timestamp'] = timestamp
            return data
        else:
            # Wait for node to catch up to session's view
            return self.wait_for_timestamp(node, key, session['read_timestamp'])
    
    def write(self, session_id, key, value):
        session = self.session_store[session_id]
        node = session['preferred_node']
        
        timestamp = node.write_with_timestamp(key, value)
        session['write_timestamp'] = max(session['write_timestamp'], timestamp)
        
        return timestamp

# Example: E-commerce shopping cart
class ShoppingCartConsistency:
    def __init__(self):
        self.session_consistency = SessionConsistency()
    
    def add_to_cart(self, session_id, product_id, quantity):
        # User sees their own cart changes immediately
        cart = self.session_consistency.read(session_id, f"cart:{session_id}")
        cart[product_id] = cart.get(product_id, 0) + quantity
        
        self.session_consistency.write(session_id, f"cart:{session_id}", cart)
        
        return cart
    
    def view_cart(self, session_id):
        # Always see your own changes
        return self.session_consistency.read(session_id, f"cart:{session_id}")
```

## 📊 Consistency Levels in Practice

### Apache Cassandra's Tunable Consistency
```python
class CassandraConsistency:
    def __init__(self):
        self.replication_factor = 3
        self.consistency_levels = {
            'ONE': 1,           # Weak consistency
            'TWO': 2,           # Stronger consistency  
            'THREE': 3,         # Strongest consistency
            'QUORUM': 2,        # Majority (RF/2 + 1)
            'ALL': 3,           # Strongest consistency
            'LOCAL_QUORUM': 2,  # Quorum within local datacenter
            'EACH_QUORUM': 2    # Quorum in each datacenter
        }
    
    def write(self, key, value, consistency_level='ONE'):
        required_acks = self.consistency_levels[consistency_level]
        successful_writes = 0
        
        for node in self.get_replica_nodes(key):
            try:
                node.write(key, value)
                successful_writes += 1
                
                if successful_writes >= required_acks:
                    return "Write successful"
            except Exception:
                continue
        
        if successful_writes < required_acks:
            raise ConsistencyException(f"Could not achieve {consistency_level}")
    
    def read(self, key, consistency_level='ONE'):
        required_responses = self.consistency_levels[consistency_level]
        responses = []
        
        for node in self.get_replica_nodes(key):
            try:
                response = node.read_with_timestamp(key)
                responses.append(response)
                
                if len(responses) >= required_responses:
                    # Return most recent version
                    return max(responses, key=lambda r: r.timestamp).value
            except Exception:
                continue
        
        if len(responses) < required_responses:
            raise ConsistencyException(f"Could not achieve {consistency_level}")
```

### MongoDB's Read Concerns
```python
class MongoDBConsistency:
    def __init__(self):
        self.replica_set = ReplicaSet()
    
    def read_with_concern(self, query, read_concern='local'):
        if read_concern == 'local':
            # Read from primary or secondary (eventual consistency)
            return self.replica_set.any_node().find(query)
        
        elif read_concern == 'available':
            # Read from any available node, even during partitions
            for node in self.replica_set.nodes:
                try:
                    return node.find(query)
                except Exception:
                    continue
        
        elif read_concern == 'majority':
            # Read data acknowledged by majority (strong consistency)
            return self.replica_set.read_with_majority_ack(query)
        
        elif read_concern == 'linearizable':
            # Strongest consistency - read from primary with confirmation
            primary = self.replica_set.primary
            return primary.find_with_read_confirmation(query)
```

## 🔄 Conflict Resolution Strategies

### Last Writer Wins (LWW)
```python
class LastWriterWins:
    def resolve_conflict(self, version1, version2):
        # Simple timestamp-based resolution
        if version1.timestamp > version2.timestamp:
            return version1
        elif version2.timestamp > version1.timestamp:
            return version2
        else:
            # Same timestamp - use node ID as tiebreaker
            return version1 if version1.node_id < version2.node_id else version2

# Example: User profile updates
class UserProfileLWW:
    def update_profile(self, user_id, updates):
        current_profile = self.get_profile(user_id)
        
        # Create new version with timestamp
        new_version = {
            'data': {**current_profile.data, **updates},
            'timestamp': time.time(),
            'node_id': self.node_id
        }
        
        # Write to all replicas
        for replica in self.replicas:
            replica.write_profile(user_id, new_version)
        
        return new_version
```

### Vector Clocks
```python
class VectorClock:
    def __init__(self, node_id, nodes):
        self.node_id = node_id
        self.clock = {node: 0 for node in nodes}
    
    def increment(self):
        self.clock[self.node_id] += 1
        return self.clock.copy()
    
    def update(self, other_clock):
        for node in self.clock:
            self.clock[node] = max(self.clock[node], other_clock.get(node, 0))
        self.clock[self.node_id] += 1
    
    def happens_before(self, other_clock):
        # Check if this clock happens before another
        return (all(self.clock[node] <= other_clock.get(node, 0) for node in self.clock) and
                any(self.clock[node] < other_clock.get(node, 0) for node in self.clock))
    
    def concurrent_with(self, other_clock):
        return not (self.happens_before(other_clock) or 
                   VectorClock.from_dict(other_clock).happens_before(self.clock))

class VectorClockConflictResolution:
    def resolve_conflict(self, version1, version2):
        clock1 = version1.vector_clock
        clock2 = version2.vector_clock
        
        if clock1.happens_before(clock2):
            return version2  # version2 is newer
        elif clock2.happens_before(clock1):
            return version1  # version1 is newer
        else:
            # Concurrent updates - need application-specific resolution
            return self.merge_concurrent_versions(version1, version2)
```

### CRDTs (Conflict-free Replicated Data Types)
```python
class GCounterCRDT:
    """Grow-only counter that automatically resolves conflicts"""
    def __init__(self, node_id, nodes):
        self.node_id = node_id
        self.counters = {node: 0 for node in nodes}
    
    def increment(self, amount=1):
        self.counters[self.node_id] += amount
    
    def value(self):
        return sum(self.counters.values())
    
    def merge(self, other_counter):
        # Merge operation is commutative and associative
        for node in self.counters:
            self.counters[node] = max(
                self.counters[node], 
                other_counter.counters.get(node, 0)
            )

class PNCounterCRDT:
    """Increment/decrement counter using two G-Counters"""
    def __init__(self, node_id, nodes):
        self.positive = GCounterCRDT(node_id, nodes)
        self.negative = GCounterCRDT(node_id, nodes)
    
    def increment(self, amount=1):
        self.positive.increment(amount)
    
    def decrement(self, amount=1):
        self.negative.increment(amount)
    
    def value(self):
        return self.positive.value() - self.negative.value()
    
    def merge(self, other_counter):
        self.positive.merge(other_counter.positive)
        self.negative.merge(other_counter.negative)

# Example: Collaborative document editing
class CollaborativeDocument:
    def __init__(self, doc_id, node_id):
        self.doc_id = doc_id
        self.node_id = node_id
        self.operations = []  # Ordered list of operations
        self.vector_clock = VectorClock(node_id, ['node1', 'node2', 'node3'])
    
    def insert_text(self, position, text):
        operation = {
            'type': 'insert',
            'position': position,
            'text': text,
            'timestamp': self.vector_clock.increment(),
            'node_id': self.node_id
        }
        
        self.operations.append(operation)
        self.replicate_operation(operation)
    
    def apply_remote_operation(self, operation):
        # Transform operation based on concurrent operations
        transformed_op = self.operational_transform(operation)
        self.operations.append(transformed_op)
        self.vector_clock.update(operation['timestamp'])
```

## 🌍 Real-World Consistency Patterns

### Amazon DynamoDB
```python
class DynamoDBConsistency:
    def __init__(self):
        self.default_consistency = 'eventual'
        self.strong_consistency_available = True
    
    def get_item(self, table, key, consistent_read=False):
        if consistent_read:
            # Strong consistency - read from primary
            return self.primary_node.get_item(table, key)
        else:
            # Eventual consistency - read from any replica
            return self.any_replica().get_item(table, key)
    
    def put_item(self, table, item):
        # Write to primary, asynchronously replicate
        result = self.primary_node.put_item(table, item)
        
        # Eventual consistency across replicas
        self.async_replicate_to_replicas(table, item)
        
        return result
```

### Google Spanner
```python
class SpannerConsistency:
    def __init__(self):
        self.true_time = TrueTimeAPI()
        self.global_consistency = True
    
    def read_write_transaction(self, operations):
        # Globally consistent transactions
        commit_timestamp = self.true_time.now()
        
        # Two-phase commit across all participating nodes
        prepared = self.prepare_phase(operations, commit_timestamp)
        
        if all(prepared):
            return self.commit_phase(operations, commit_timestamp)
        else:
            self.abort_transaction(operations)
            raise TransactionAbortedException()
    
    def read_only_transaction(self, queries):
        # Consistent snapshot across all nodes
        snapshot_timestamp = self.true_time.now()
        
        results = []
        for query in queries:
            result = self.read_at_timestamp(query, snapshot_timestamp)
            results.append(result)
        
        return results
```

## 📊 Choosing the Right Consistency Pattern

### Decision Matrix
```python
class ConsistencyDecisionFramework:
    def recommend_pattern(self, requirements):
        decision_matrix = {
            'financial_transactions': {
                'pattern': 'Strong Consistency',
                'reasoning': 'Money cannot be lost or duplicated',
                'implementation': 'ACID transactions with 2PC'
            },
            
            'social_media_posts': {
                'pattern': 'Eventual Consistency',
                'reasoning': 'High availability more important than immediate consistency',
                'implementation': 'Asynchronous replication with conflict resolution'
            },
            
            'collaborative_editing': {
                'pattern': 'Causal Consistency',
                'reasoning': 'Order of edits matters, but concurrent edits can be merged',
                'implementation': 'Operational Transform with vector clocks'
            },
            
            'user_sessions': {
                'pattern': 'Session Consistency',
                'reasoning': 'User should see their own changes immediately',
                'implementation': 'Sticky sessions with read-your-writes'
            },
            
            'analytics_data': {
                'pattern': 'Weak Consistency',
                'reasoning': 'Approximate results acceptable for better performance',
                'implementation': 'Best-effort replication'
            }
        }
        
        return decision_matrix.get(requirements['use_case'], 
                                 'Analyze specific requirements')
```

## 📚 Conclusion

Consistency patterns are fundamental to building reliable distributed systems. The choice of pattern depends on your specific requirements for data accuracy, system availability, and performance. Understanding these patterns helps you make informed architectural decisions and build systems that behave predictably under various conditions.

**Key Takeaways:**

1. **No one-size-fits-all**: Different data types may need different consistency patterns
2. **Trade-offs are inevitable**: Stronger consistency typically means lower availability or performance
3. **Conflict resolution is crucial**: Plan for how your system will handle concurrent updates
4. **Monitor and measure**: Track actual consistency behavior in production
5. **Evolution is possible**: Systems can use different patterns for different operations

The future of consistency patterns lies in adaptive systems that can dynamically adjust their consistency guarantees based on current conditions, application requirements, and business priorities. Whether you're building a simple application or a complex distributed system, understanding these patterns is essential for creating robust, scalable architectures.

Remember: consistency is not just about data—it's about creating predictable, reliable experiences for your users and applications.
