# Data Partitioning (Sharding): Splitting Data for Scale

## 🎯 What is Data Partitioning (Sharding)?

Sharding is like organizing a massive library by splitting books across multiple buildings based on subjects. Instead of having one enormous library that becomes impossible to navigate, you have specialized buildings: one for science, one for literature, one for history. In database terms, sharding splits a large dataset across multiple database servers, with each server holding a subset of the data.

## 🏗️ Core Concepts

### The Library Analogy Extended
- **Horizontal Partitioning (Sharding)**: Books distributed across buildings by subject
- **Vertical Partitioning**: Each building stores different parts of books (one has titles and authors, another has content)
- **Functional Partitioning**: Buildings specialized by purpose (lending library, reference library, archive)

### Why Sharding Matters
1. **Scale Beyond Single Server Limits**: No single machine can handle infinite data
2. **Performance**: Smaller datasets mean faster queries
3. **Availability**: Failure of one shard doesn't bring down entire system
4. **Geographic Distribution**: Data closer to users reduces latency
5. **Cost Optimization**: Use appropriate hardware for different data types

## 🔄 Types of Partitioning

### 1. Horizontal Partitioning (Sharding)
**Definition**: Split rows of a table across multiple databases

```sql
-- Original single table
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP
);

-- Sharded across 3 databases
-- Shard 1: users with id 1-1000000
-- Shard 2: users with id 1000001-2000000  
-- Shard 3: users with id 2000001+
```

**Real-world example**: Instagram shards user photos by user ID, ensuring each user's photos are on the same shard for efficient queries.

### 2. Vertical Partitioning
**Definition**: Split columns of a table across multiple databases

```sql
-- Original table
CREATE TABLE user_profiles (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    bio TEXT,
    profile_image BLOB,
    login_count INT,
    last_login TIMESTAMP
);

-- Vertical partitioning
-- Database 1: Core user data
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

-- Database 2: Extended profile data
CREATE TABLE user_details (
    user_id INT PRIMARY KEY,
    bio TEXT,
    profile_image BLOB
);

-- Database 3: Activity data
CREATE TABLE user_activity (
    user_id INT PRIMARY KEY,
    login_count INT,
    last_login TIMESTAMP
);
```

### 3. Functional Partitioning
**Definition**: Split different features/services into separate databases

```python
# Microservices with functional partitioning
class EcommerceSystem:
    def __init__(self):
        self.user_db = UserDatabase()      # User management
        self.product_db = ProductDatabase() # Product catalog
        self.order_db = OrderDatabase()     # Order processing
        self.payment_db = PaymentDatabase() # Payment processing
        self.review_db = ReviewDatabase()   # Reviews and ratings
```

## ⚖️ Sharding Strategies

### 1. Range-Based Sharding
**How it works**: Partition data based on ranges of a key

```python
class RangeBasedSharding:
    def __init__(self):
        self.shards = {
            'shard_1': {'range': (1, 1000000), 'db': 'db1.example.com'},
            'shard_2': {'range': (1000001, 2000000), 'db': 'db2.example.com'},
            'shard_3': {'range': (2000001, 3000000), 'db': 'db3.example.com'},
        }
    
    def get_shard(self, user_id):
        for shard_name, config in self.shards.items():
            start, end = config['range']
            if start <= user_id <= end:
                return config['db']
        return self.shards['shard_3']['db']  # Default to last shard
    
    def query_user(self, user_id):
        shard_db = self.get_shard(user_id)
        return shard_db.query(f"SELECT * FROM users WHERE id = {user_id}")
```

**Pros**: Simple to implement, good for range queries
**Cons**: Risk of hotspots, uneven data distribution
**Use case**: Time-series data, sequential IDs

### 2. Hash-Based Sharding
**How it works**: Use hash function to determine shard

```python
class HashBasedSharding:
    def __init__(self):
        self.shards = [
            'db1.example.com',
            'db2.example.com', 
            'db3.example.com',
            'db4.example.com'
        ]
    
    def get_shard(self, key):
        # Simple hash function
        hash_value = hash(str(key))
        shard_index = hash_value % len(self.shards)
        return self.shards[shard_index]
    
    def query_user(self, user_id):
        shard_db = self.get_shard(user_id)
        return shard_db.query(f"SELECT * FROM users WHERE id = {user_id}")
```

**Pros**: Even distribution, no hotspots
**Cons**: Range queries require checking all shards, resharding is complex
**Use case**: User data, session storage

### 3. Directory-Based Sharding
**How it works**: Maintain a lookup service that maps keys to shards

```python
class DirectoryBasedSharding:
    def __init__(self):
        self.directory_service = DirectoryService()
        self.shards = {
            'shard_1': 'db1.example.com',
            'shard_2': 'db2.example.com',
            'shard_3': 'db3.example.com'
        }
    
    def get_shard(self, key):
        shard_name = self.directory_service.lookup(key)
        return self.shards[shard_name]
    
    def add_new_shard(self, shard_name, shard_url):
        self.shards[shard_name] = shard_url
        # Directory service handles key redistribution
        self.directory_service.rebalance()
```

**Pros**: Flexible, supports complex sharding logic
**Cons**: Directory service is a potential bottleneck
**Use case**: Complex business logic for data placement

### 4. Consistent Hashing
**How it works**: Use consistent hashing to minimize resharding impact

```python
import hashlib
import bisect

class ConsistentHashSharding:
    def __init__(self, nodes, replicas=3):
        self.replicas = replicas
        self.ring = {}
        self.sorted_keys = []
        
        for node in nodes:
            self.add_node(node)
    
    def _hash(self, key):
        return int(hashlib.md5(key.encode()).hexdigest(), 16)
    
    def add_node(self, node):
        for i in range(self.replicas):
            key = self._hash(f"{node}:{i}")
            self.ring[key] = node
            bisect.insort(self.sorted_keys, key)
    
    def remove_node(self, node):
        for i in range(self.replicas):
            key = self._hash(f"{node}:{i}")
            del self.ring[key]
            self.sorted_keys.remove(key)
    
    def get_node(self, key):
        if not self.ring:
            return None
        
        hash_key = self._hash(str(key))
        idx = bisect.bisect_right(self.sorted_keys, hash_key)
        
        if idx == len(self.sorted_keys):
            idx = 0
        
        return self.ring[self.sorted_keys[idx]]
```

**Pros**: Minimal data movement when adding/removing shards
**Cons**: Complex implementation
**Use case**: Distributed caches, large-scale systems

## 🌍 Real-World Sharding Examples

### 1. Twitter's Approach
```python
# Twitter's timeline sharding strategy
class TwitterSharding:
    def __init__(self):
        # Shard by user ID for user data
        self.user_shards = HashBasedSharding()
        
        # Shard by tweet ID for tweet data  
        self.tweet_shards = RangeBasedSharding()
        
        # Timeline data uses fan-out approach
        self.timeline_cache = RedisCluster()
    
    def post_tweet(self, user_id, tweet_content):
        # Store tweet in tweet shard
        tweet_id = generate_tweet_id()
        tweet_shard = self.tweet_shards.get_shard(tweet_id)
        tweet_shard.insert(tweet_id, tweet_content, user_id)
        
        # Fan out to followers' timelines
        followers = self.get_followers(user_id)
        for follower_id in followers:
            timeline_shard = self.timeline_cache.get_shard(follower_id)
            timeline_shard.add_to_timeline(follower_id, tweet_id)
```

### 2. Uber's Data Architecture
```python
# Uber's location-based sharding
class UberSharding:
    def __init__(self):
        # Shard by geographic regions (geohash)
        self.location_shards = GeographicSharding()
        
        # User data sharded by user ID
        self.user_shards = HashBasedSharding()
        
        # Trip data sharded by trip ID
        self.trip_shards = TimeBasedSharding()
    
    def find_nearby_drivers(self, rider_location):
        geohash = self.calculate_geohash(rider_location)
        location_shard = self.location_shards.get_shard(geohash)
        return location_shard.find_drivers_in_radius(rider_location, radius=5)
```

### 3. Instagram's Photo Storage
```python
# Instagram's photo sharding strategy
class InstagramSharding:
    def __init__(self):
        # Photos sharded by user ID to keep user's photos together
        self.photo_shards = UserBasedSharding()
        
        # Metadata in separate shards for faster queries
        self.metadata_shards = HashBasedSharding()
    
    def upload_photo(self, user_id, photo_data, metadata):
        # Store photo on user's shard
        photo_shard = self.photo_shards.get_shard(user_id)
        photo_id = photo_shard.store_photo(user_id, photo_data)
        
        # Store metadata for search/discovery
        metadata_shard = self.metadata_shards.get_shard(photo_id)
        metadata_shard.store_metadata(photo_id, metadata)
```

## 🛠️ Implementation Challenges and Solutions

### 1. Cross-Shard Queries
**Problem**: Queries spanning multiple shards are complex and slow

```python
# Problem: Finding users by email across all shards
def find_user_by_email(email):
    results = []
    for shard in all_shards:
        result = shard.query("SELECT * FROM users WHERE email = ?", email)
        if result:
            results.append(result)
    return results  # Slow - queries all shards

# Solution 1: Denormalization
class UserEmailIndex:
    def __init__(self):
        # Separate index mapping emails to shard locations
        self.email_to_shard = {}
    
    def find_user_by_email(self, email):
        shard_id = self.email_to_shard.get(email)
        if shard_id:
            shard = get_shard(shard_id)
            return shard.query("SELECT * FROM users WHERE email = ?", email)

# Solution 2: Search service
class UserSearchService:
    def __init__(self):
        self.elasticsearch = ElasticsearchClient()
    
    def index_user(self, user_data):
        # Index user data for search
        self.elasticsearch.index(user_data)
    
    def find_user_by_email(self, email):
        # Search returns shard location + user ID
        result = self.elasticsearch.search({"email": email})
        shard_id = result['shard_id']
        user_id = result['user_id']
        
        # Query specific shard
        shard = get_shard(shard_id)
        return shard.get_user(user_id)
```

### 2. Rebalancing and Resharding
**Problem**: Adding new shards requires data redistribution

```python
class ReshardingManager:
    def __init__(self):
        self.current_shards = []
        self.migration_status = {}
    
    def add_new_shard(self, new_shard):
        # 1. Add new shard to routing but don't send traffic yet
        self.register_shard(new_shard, active=False)
        
        # 2. Migrate data gradually
        self.start_data_migration(new_shard)
        
        # 3. Dual-write to old and new shards during migration
        self.enable_dual_write(new_shard)
        
        # 4. Switch reads to new shard after migration complete
        self.activate_shard(new_shard)
        
        # 5. Clean up old data
        self.cleanup_migrated_data()
    
    def migrate_data_chunk(self, source_shard, target_shard, key_range):
        # Migrate data in small chunks to minimize impact
        data = source_shard.get_range(key_range)
        target_shard.bulk_insert(data)
        
        # Verify migration success
        if self.verify_migration(source_shard, target_shard, key_range):
            source_shard.delete_range(key_range)
```

### 3. Maintaining Referential Integrity
**Problem**: Foreign key relationships across shards

```python
# Problem: User and Order data on different shards
class CrossShardIntegrity:
    def create_order(self, user_id, order_data):
        user_shard = self.get_user_shard(user_id)
        order_shard = self.get_order_shard(order_data['order_id'])
        
        # How to ensure user exists before creating order?
        # How to handle if user is deleted after order creation?

# Solution: Event-driven consistency
class EventDrivenSharding:
    def __init__(self):
        self.event_bus = EventBus()
    
    def create_order(self, user_id, order_data):
        # 1. Verify user exists
        user_shard = self.get_user_shard(user_id)
        user = user_shard.get_user(user_id)
        if not user:
            raise UserNotFoundError()
        
        # 2. Create order
        order_shard = self.get_order_shard(order_data['order_id'])
        order = order_shard.create_order(order_data)
        
        # 3. Publish event for other services
        event = OrderCreatedEvent(order.id, user_id, order.total)
        self.event_bus.publish(event)
    
    def delete_user(self, user_id):
        # 1. Check for existing orders
        orders = self.get_user_orders(user_id)  # Cross-shard query
        if orders:
            raise UserHasOrdersError()
        
        # 2. Delete user
        user_shard = self.get_user_shard(user_id)
        user_shard.delete_user(user_id)
        
        # 3. Publish event
        event = UserDeletedEvent(user_id)
        self.event_bus.publish(event)
```

## 📊 Sharding Best Practices

### 1. Choose the Right Shard Key
```python
# Good shard keys characteristics:
shard_key_criteria = {
    'high_cardinality': 'Many unique values',
    'even_distribution': 'No hotspots',
    'query_friendly': 'Supports common query patterns',
    'immutable': 'Doesn\'t change over time'
}

# Examples:
good_shard_keys = {
    'user_id': 'High cardinality, even distribution',
    'email_hash': 'Even distribution, immutable',
    'device_id': 'High cardinality for IoT data'
}

bad_shard_keys = {
    'status': 'Low cardinality (active/inactive)',
    'created_date': 'Hotspots on recent data',
    'country': 'Uneven distribution (US >> Vatican)'
}
```

### 2. Monitor Shard Health
```python
class ShardMonitor:
    def __init__(self):
        self.metrics = {}
    
    def collect_shard_metrics(self):
        for shard in self.shards:
            metrics = {
                'query_latency': shard.get_avg_query_time(),
                'cpu_usage': shard.get_cpu_usage(),
                'memory_usage': shard.get_memory_usage(),
                'disk_usage': shard.get_disk_usage(),
                'connection_count': shard.get_connection_count(),
                'data_size': shard.get_data_size()
            }
            self.metrics[shard.id] = metrics
    
    def detect_hotspots(self):
        avg_queries = sum(m['query_latency'] for m in self.metrics.values()) / len(self.metrics)
        
        hotspots = []
        for shard_id, metrics in self.metrics.items():
            if metrics['query_latency'] > avg_queries * 2:  # 2x average
                hotspots.append(shard_id)
        
        return hotspots
```

### 3. Plan for Growth
```python
class ShardingStrategy:
    def __init__(self):
        self.growth_projections = {
            'users_per_month': 100000,
            'data_per_user_mb': 50,
            'queries_per_user_day': 100
        }
    
    def calculate_shard_capacity(self):
        # Plan for 2 years of growth
        projected_users = self.growth_projections['users_per_month'] * 24
        projected_data_gb = (projected_users * 
                           self.growth_projections['data_per_user_mb']) / 1024
        
        # Size shards for 70% capacity at projected load
        shard_capacity_gb = 1000  # 1TB per shard
        required_shards = math.ceil(projected_data_gb / (shard_capacity_gb * 0.7))
        
        return required_shards
```

## 🚨 Common Pitfalls and How to Avoid Them

### 1. Celebrity Problem (Hotspots)
```python
# Problem: Popular users create hotspots
class CelebrityProblem:
    def get_user_timeline(self, user_id):
        if user_id in self.celebrity_users:
            # This shard gets overwhelmed with requests
            return self.get_shard(user_id).get_timeline()

# Solution: Special handling for celebrities
class CelebrityHandling:
    def __init__(self):
        self.celebrity_cache = RedisCluster()
        self.celebrity_threshold = 1000000  # 1M followers
    
    def get_user_timeline(self, user_id):
        if self.is_celebrity(user_id):
            # Use dedicated cache cluster for celebrities
            timeline = self.celebrity_cache.get(f"timeline:{user_id}")
            if not timeline:
                timeline = self.generate_celebrity_timeline(user_id)
                self.celebrity_cache.set(f"timeline:{user_id}", timeline, ttl=60)
            return timeline
        else:
            # Normal sharding for regular users
            return self.get_shard(user_id).get_timeline()
```

### 2. Premature Sharding
```python
# Anti-pattern: Sharding too early
class PrematureSharding:
    def __init__(self):
        # Don't do this for small applications!
        self.user_shard_1 = Database('shard1')  # 1000 users
        self.user_shard_2 = Database('shard2')  # 500 users
        # Complexity without benefits

# Better: Start simple, shard when needed
class GradualScaling:
    def __init__(self):
        self.database = SingleDatabase()  # Start simple
        self.user_count = 0
        self.shard_threshold = 1000000  # 1M users
    
    def should_shard(self):
        return (self.user_count > self.shard_threshold or
                self.database.get_query_latency() > 100)  # 100ms
```

## 🔮 Future of Sharding

### Auto-Sharding Systems
```python
# Modern databases with automatic sharding
class AutoShardingDatabase:
    def __init__(self):
        # System automatically handles sharding
        self.cluster = CockroachDB()  # Or TiDB, YugabyteDB
    
    def insert_user(self, user_data):
        # No manual sharding logic needed
        # Database handles distribution automatically
        return self.cluster.insert("users", user_data)
    
    def query_users(self, query):
        # Database automatically routes queries
        return self.cluster.query(query)
```

### AI-Powered Shard Optimization
```python
class IntelligentSharding:
    def __init__(self):
        self.ml_optimizer = ShardingOptimizer()
    
    def optimize_sharding(self):
        # Analyze query patterns
        query_patterns = self.analyze_queries()
        
        # Predict optimal shard distribution
        optimal_layout = self.ml_optimizer.predict_layout(query_patterns)
        
        # Automatically rebalance if beneficial
        if optimal_layout.improvement > 0.2:  # 20% improvement
            self.rebalance_shards(optimal_layout)
```

## 📚 Conclusion

Data partitioning and sharding are essential techniques for building scalable systems that can handle massive amounts of data and traffic. While sharding introduces complexity, it's often necessary for systems that need to scale beyond what a single database server can handle.

**Key Takeaways:**

1. **Start Simple**: Don't shard prematurely - single databases can handle surprising loads
2. **Choose Shard Keys Carefully**: The shard key determines your system's scalability and query patterns
3. **Plan for Cross-Shard Operations**: Design your application to minimize cross-shard queries
4. **Monitor and Rebalance**: Regularly monitor shard health and rebalance when needed
5. **Consider Alternatives**: Modern distributed databases can handle sharding automatically

The future of sharding lies in intelligent, automated systems that can optimize data distribution based on access patterns and performance requirements. Whether you implement manual sharding or use auto-sharding databases, understanding these concepts is crucial for building scalable data architectures.

Remember: sharding is a powerful tool, but like all powerful tools, it should be used thoughtfully and with a clear understanding of the trade-offs involved.
