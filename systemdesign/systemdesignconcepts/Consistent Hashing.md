# Consistent Hashing: The Art of Distributed Data Placement

## 🎯 What is Consistent Hashing?

Consistent hashing is like organizing a massive library where books can be added to any shelf, but you always know exactly which shelf to check for any book. Unlike traditional hashing where adding a new shelf would require reorganizing most books, consistent hashing ensures that adding or removing shelves only affects the books on adjacent shelves, making the system incredibly efficient for distributed storage and caching.

## 🏗️ Core Concepts

### The Circular Library Analogy
- **Hash Ring**: A circular arrangement of library shelves (like a round library)
- **Data Items**: Books that need to be stored on shelves
- **Nodes**: Individual shelves that can store books
- **Virtual Nodes**: Multiple positions per shelf for better distribution
- **Minimal Redistribution**: Adding/removing shelves only affects nearby books

### Why Consistent Hashing Matters
1. **Minimal Data Movement**: Adding/removing nodes affects only adjacent data
2. **Load Distribution**: Evenly distributes data across all nodes
3. **Fault Tolerance**: System continues working when nodes fail
4. **Scalability**: Easy to add or remove nodes without major disruption
5. **Cache Efficiency**: Maintains cache locality when topology changes

## 🔄 Consistent Hashing Implementation

```python
import hashlib
import bisect
import random
import time
from typing import Dict, List, Set, Optional, Any, Tuple
from collections import defaultdict, Counter
from dataclasses import dataclass
import threading
import json

@dataclass
class Node:
    node_id: str
    host: str
    port: int
    weight: int = 1
    status: str = "active"
    load: float = 0.0
    last_seen: float = 0.0
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}
        self.last_seen = time.time()

@dataclass
class DataItem:
    key: str
    value: Any
    size: int
    created_at: float
    accessed_at: float
    access_count: int = 0
    
    def __post_init__(self):
        if not hasattr(self, 'created_at'):
            self.created_at = time.time()
        if not hasattr(self, 'accessed_at'):
            self.accessed_at = time.time()

class ConsistentHashRing:
    def __init__(self, virtual_nodes_per_node: int = 150, hash_function: str = 'md5'):
        self.virtual_nodes_per_node = virtual_nodes_per_node
        self.hash_function = hash_function
        
        # Ring structure: hash_value -> node_id
        self.ring: Dict[int, str] = {}
        self.sorted_hashes: List[int] = []
        
        # Node management
        self.nodes: Dict[str, Node] = {}
        self.virtual_node_map: Dict[int, str] = {}  # hash -> node_id
        
        # Statistics
        self.stats = {
            'total_keys': 0,
            'redistributions': 0,
            'node_additions': 0,
            'node_removals': 0
        }
        
        # Thread safety
        self.lock = threading.RLock()
    
    def _hash(self, key: str) -> int:
        """Hash a key to a position on the ring"""
        if self.hash_function == 'md5':
            return int(hashlib.md5(key.encode('utf-8')).hexdigest(), 16)
        elif self.hash_function == 'sha1':
            return int(hashlib.sha1(key.encode('utf-8')).hexdigest(), 16)
        else:
            # Simple hash for demonstration
            return hash(key) & 0x7FFFFFFF
    
    def add_node(self, node: Node) -> Dict[str, Any]:
        """Add a node to the hash ring"""
        
        with self.lock:
            if node.node_id in self.nodes:
                return {
                    'success': False,
                    'error': f'Node {node.node_id} already exists'
                }
            
            self.nodes[node.node_id] = node
            
            # Add virtual nodes based on weight
            virtual_nodes_count = self.virtual_nodes_per_node * node.weight
            added_positions = []
            
            for i in range(virtual_nodes_count):
                virtual_key = f"{node.node_id}:{i}"
                hash_value = self._hash(virtual_key)
                
                # Handle hash collisions
                while hash_value in self.ring:
                    hash_value = (hash_value + 1) % (2**32)
                
                self.ring[hash_value] = node.node_id
                self.virtual_node_map[hash_value] = node.node_id
                added_positions.append(hash_value)
            
            # Update sorted hashes
            self.sorted_hashes = sorted(self.ring.keys())
            
            self.stats['node_additions'] += 1
            
            print(f"Added node {node.node_id} with {len(added_positions)} virtual nodes")
            
            return {
                'success': True,
                'virtual_nodes_added': len(added_positions),
                'positions': added_positions
            }
    
    def remove_node(self, node_id: str) -> Dict[str, Any]:
        """Remove a node from the hash ring"""
        
        with self.lock:
            if node_id not in self.nodes:
                return {
                    'success': False,
                    'error': f'Node {node_id} not found'
                }
            
            # Find and remove all virtual nodes for this physical node
            positions_to_remove = []
            
            for hash_value, mapped_node_id in list(self.ring.items()):
                if mapped_node_id == node_id:
                    positions_to_remove.append(hash_value)
            
            # Remove from ring
            for hash_value in positions_to_remove:
                del self.ring[hash_value]
                if hash_value in self.virtual_node_map:
                    del self.virtual_node_map[hash_value]
            
            # Remove node
            del self.nodes[node_id]
            
            # Update sorted hashes
            self.sorted_hashes = sorted(self.ring.keys())
            
            self.stats['node_removals'] += 1
            
            print(f"Removed node {node_id} and {len(positions_to_remove)} virtual nodes")
            
            return {
                'success': True,
                'virtual_nodes_removed': len(positions_to_remove),
                'positions': positions_to_remove
            }
    
    def get_node(self, key: str) -> Optional[str]:
        """Get the node responsible for a key"""
        
        with self.lock:
            if not self.ring:
                return None
            
            key_hash = self._hash(key)
            
            # Find the first node clockwise from the key hash
            idx = bisect.bisect_right(self.sorted_hashes, key_hash)
            
            if idx == len(self.sorted_hashes):
                # Wrap around to the beginning of the ring
                idx = 0
            
            hash_position = self.sorted_hashes[idx]
            return self.ring[hash_position]
    
    def get_nodes(self, key: str, count: int) -> List[str]:
        """Get multiple nodes for replication"""
        
        with self.lock:
            if not self.ring or count <= 0:
                return []
            
            key_hash = self._hash(key)
            nodes = []
            seen_nodes = set()
            
            # Find starting position
            idx = bisect.bisect_right(self.sorted_hashes, key_hash)
            
            # Collect unique nodes clockwise
            for i in range(len(self.sorted_hashes)):
                position_idx = (idx + i) % len(self.sorted_hashes)
                hash_position = self.sorted_hashes[position_idx]
                node_id = self.ring[hash_position]
                
                if node_id not in seen_nodes:
                    nodes.append(node_id)
                    seen_nodes.add(node_id)
                    
                    if len(nodes) >= count:
                        break
            
            return nodes
    
    def get_node_range(self, node_id: str) -> List[Tuple[int, int]]:
        """Get the hash ranges that a node is responsible for"""
        
        with self.lock:
            if node_id not in self.nodes:
                return []
            
            ranges = []
            
            # Find all virtual nodes for this physical node
            node_positions = [pos for pos, nid in self.ring.items() if nid == node_id]
            node_positions.sort()
            
            for position in node_positions:
                # Find the previous position on the ring
                idx = self.sorted_hashes.index(position)
                prev_idx = (idx - 1) % len(self.sorted_hashes)
                prev_position = self.sorted_hashes[prev_idx]
                
                if prev_position < position:
                    ranges.append((prev_position + 1, position))
                else:
                    # Wrap around case
                    ranges.append((prev_position + 1, 2**32 - 1))
                    ranges.append((0, position))
            
            return ranges
    
    def get_load_distribution(self) -> Dict[str, Dict[str, Any]]:
        """Calculate load distribution across nodes"""
        
        with self.lock:
            if not self.ring:
                return {}
            
            node_loads = {}
            total_range = 2**32
            
            for node_id in self.nodes:
                ranges = self.get_node_range(node_id)
                total_responsible = sum(end - start + 1 for start, end in ranges)
                
                load_percentage = (total_responsible / total_range) * 100
                virtual_nodes = sum(1 for nid in self.ring.values() if nid == node_id)
                
                node_loads[node_id] = {
                    'load_percentage': load_percentage,
                    'virtual_nodes': virtual_nodes,
                    'hash_ranges': len(ranges),
                    'total_hash_space': total_responsible,
                    'node_info': self.nodes[node_id]
                }
            
            return node_loads
    
    def rebalance_ring(self, target_deviation: float = 5.0) -> Dict[str, Any]:
        """Rebalance the ring to achieve better load distribution"""
        
        with self.lock:
            load_distribution = self.get_load_distribution()
            
            if not load_distribution:
                return {'success': False, 'error': 'No nodes in ring'}
            
            # Calculate average load
            total_nodes = len(load_distribution)
            target_load = 100.0 / total_nodes
            
            # Find nodes that need rebalancing
            overloaded_nodes = []
            underloaded_nodes = []
            
            for node_id, load_info in load_distribution.items():
                current_load = load_info['load_percentage']
                deviation = abs(current_load - target_load)
                
                if deviation > target_deviation:
                    if current_load > target_load:
                        overloaded_nodes.append((node_id, current_load, deviation))
                    else:
                        underloaded_nodes.append((node_id, current_load, deviation))
            
            if not overloaded_nodes and not underloaded_nodes:
                return {
                    'success': True,
                    'message': 'Ring is already well balanced',
                    'rebalancing_needed': False
                }
            
            # Rebalance by adjusting virtual nodes
            adjustments = []
            
            for node_id, current_load, deviation in overloaded_nodes:
                node = self.nodes[node_id]
                current_virtual = load_distribution[node_id]['virtual_nodes']
                
                # Reduce virtual nodes proportionally
                reduction_factor = target_load / current_load
                new_virtual_count = max(1, int(current_virtual * reduction_factor))
                
                if new_virtual_count < current_virtual:
                    adjustments.append((node_id, 'reduce', current_virtual - new_virtual_count))
            
            for node_id, current_load, deviation in underloaded_nodes:
                node = self.nodes[node_id]
                current_virtual = load_distribution[node_id]['virtual_nodes']
                
                # Increase virtual nodes proportionally
                increase_factor = target_load / current_load
                new_virtual_count = int(current_virtual * increase_factor)
                
                if new_virtual_count > current_virtual:
                    adjustments.append((node_id, 'increase', new_virtual_count - current_virtual))
            
            # Apply adjustments
            for node_id, action, count in adjustments:
                if action == 'reduce':
                    self._reduce_virtual_nodes(node_id, count)
                else:
                    self._add_virtual_nodes(node_id, count)
            
            return {
                'success': True,
                'rebalancing_needed': True,
                'adjustments_made': len(adjustments),
                'adjustments': adjustments
            }
    
    def _reduce_virtual_nodes(self, node_id: str, count: int):
        """Reduce virtual nodes for a specific node"""
        
        # Find virtual nodes for this node
        node_positions = [pos for pos, nid in self.ring.items() if nid == node_id]
        
        # Remove the specified count (randomly)
        positions_to_remove = random.sample(node_positions, min(count, len(node_positions) - 1))
        
        for position in positions_to_remove:
            del self.ring[position]
            if position in self.virtual_node_map:
                del self.virtual_node_map[position]
        
        self.sorted_hashes = sorted(self.ring.keys())
    
    def _add_virtual_nodes(self, node_id: str, count: int):
        """Add virtual nodes for a specific node"""
        
        current_virtual_count = sum(1 for nid in self.ring.values() if nid == node_id)
        
        for i in range(count):
            virtual_key = f"{node_id}:extra:{current_virtual_count + i}"
            hash_value = self._hash(virtual_key)
            
            # Handle collisions
            while hash_value in self.ring:
                hash_value = (hash_value + 1) % (2**32)
            
            self.ring[hash_value] = node_id
            self.virtual_node_map[hash_value] = node_id
        
        self.sorted_hashes = sorted(self.ring.keys())
    
    def get_ring_stats(self) -> Dict[str, Any]:
        """Get comprehensive ring statistics"""
        
        with self.lock:
            load_distribution = self.get_load_distribution()
            
            if not load_distribution:
                return {'message': 'No nodes in ring'}
            
            loads = [info['load_percentage'] for info in load_distribution.values()]
            
            return {
                'total_nodes': len(self.nodes),
                'total_virtual_nodes': len(self.ring),
                'average_virtual_nodes_per_node': len(self.ring) / len(self.nodes) if self.nodes else 0,
                'load_distribution': {
                    'min_load': min(loads),
                    'max_load': max(loads),
                    'avg_load': sum(loads) / len(loads),
                    'std_deviation': self._calculate_std_deviation(loads)
                },
                'ring_balance_score': self._calculate_balance_score(loads),
                'statistics': self.stats.copy(),
                'node_details': load_distribution
            }
    
    def _calculate_std_deviation(self, values: List[float]) -> float:
        """Calculate standard deviation of values"""
        if len(values) < 2:
            return 0.0
        
        mean = sum(values) / len(values)
        variance = sum((x - mean) ** 2 for x in values) / len(values)
        return variance ** 0.5
    
    def _calculate_balance_score(self, loads: List[float]) -> float:
        """Calculate balance score (0-100, higher is better)"""
        if not loads:
            return 0.0
        
        target_load = 100.0 / len(loads)
        max_deviation = max(abs(load - target_load) for load in loads)
        
        # Score decreases as deviation increases
        balance_score = max(0, 100 - (max_deviation * 2))
        return balance_score

class DistributedHashTable:
    """Distributed hash table using consistent hashing"""
    
    def __init__(self, replication_factor: int = 3):
        self.hash_ring = ConsistentHashRing()
        self.replication_factor = replication_factor
        self.data_store: Dict[str, Dict[str, DataItem]] = defaultdict(dict)  # node_id -> {key: data}
        self.key_locations: Dict[str, List[str]] = {}  # key -> [node_ids]
        
        # Performance metrics
        self.metrics = {
            'get_operations': 0,
            'put_operations': 0,
            'delete_operations': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'redistributions': 0
        }
        
        self.lock = threading.RLock()
    
    def add_node(self, node: Node) -> Dict[str, Any]:
        """Add a node to the distributed hash table"""
        
        with self.lock:
            # Add to hash ring
            result = self.hash_ring.add_node(node)
            
            if not result['success']:
                return result
            
            # Initialize data store for new node
            self.data_store[node.node_id] = {}
            
            # Redistribute existing data
            redistributed_keys = self._redistribute_data_for_new_node(node.node_id)
            
            return {
                **result,
                'redistributed_keys': len(redistributed_keys),
                'keys': redistributed_keys
            }
    
    def remove_node(self, node_id: str) -> Dict[str, Any]:
        """Remove a node from the distributed hash table"""
        
        with self.lock:
            if node_id not in self.hash_ring.nodes:
                return {
                    'success': False,
                    'error': f'Node {node_id} not found'
                }
            
            # Get data from the node being removed
            node_data = self.data_store.get(node_id, {})
            
            # Remove from hash ring
            result = self.hash_ring.remove_node(node_id)
            
            if not result['success']:
                return result
            
            # Redistribute data from removed node
            redistributed_keys = self._redistribute_data_from_removed_node(node_id, node_data)
            
            # Clean up
            if node_id in self.data_store:
                del self.data_store[node_id]
            
            return {
                **result,
                'redistributed_keys': len(redistributed_keys),
                'keys': redistributed_keys
            }
    
    def put(self, key: str, value: Any) -> Dict[str, Any]:
        """Store a key-value pair in the distributed hash table"""
        
        with self.lock:
            # Get nodes for this key
            nodes = self.hash_ring.get_nodes(key, self.replication_factor)
            
            if not nodes:
                return {
                    'success': False,
                    'error': 'No nodes available'
                }
            
            # Create data item
            data_item = DataItem(
                key=key,
                value=value,
                size=len(str(value)),
                created_at=time.time(),
                accessed_at=time.time()
            )
            
            # Store on all replica nodes
            successful_stores = []
            failed_stores = []
            
            for node_id in nodes:
                try:
                    self.data_store[node_id][key] = data_item
                    successful_stores.append(node_id)
                except Exception as e:
                    failed_stores.append((node_id, str(e)))
            
            # Update key location tracking
            self.key_locations[key] = successful_stores
            
            self.metrics['put_operations'] += 1
            
            return {
                'success': len(successful_stores) > 0,
                'stored_on_nodes': successful_stores,
                'failed_stores': failed_stores,
                'replication_factor_achieved': len(successful_stores)
            }
    
    def get(self, key: str) -> Dict[str, Any]:
        """Retrieve a value from the distributed hash table"""
        
        with self.lock:
            self.metrics['get_operations'] += 1
            
            # Check if we know where the key is stored
            if key in self.key_locations:
                stored_nodes = self.key_locations[key]
            else:
                # Calculate nodes for this key
                stored_nodes = self.hash_ring.get_nodes(key, self.replication_factor)
            
            if not stored_nodes:
                self.metrics['cache_misses'] += 1
                return {
                    'success': False,
                    'error': 'No nodes available for key'
                }
            
            # Try to retrieve from nodes (try primary first)
            for node_id in stored_nodes:
                if node_id in self.data_store and key in self.data_store[node_id]:
                    data_item = self.data_store[node_id][key]
                    
                    # Update access statistics
                    data_item.accessed_at = time.time()
                    data_item.access_count += 1
                    
                    self.metrics['cache_hits'] += 1
                    
                    return {
                        'success': True,
                        'value': data_item.value,
                        'retrieved_from_node': node_id,
                        'metadata': {
                            'created_at': data_item.created_at,
                            'accessed_at': data_item.accessed_at,
                            'access_count': data_item.access_count,
                            'size': data_item.size
                        }
                    }
            
            self.metrics['cache_misses'] += 1
            return {
                'success': False,
                'error': f'Key {key} not found on any replica nodes'
            }
    
    def delete(self, key: str) -> Dict[str, Any]:
        """Delete a key from the distributed hash table"""
        
        with self.lock:
            self.metrics['delete_operations'] += 1
            
            # Get nodes that might have this key
            if key in self.key_locations:
                stored_nodes = self.key_locations[key]
            else:
                stored_nodes = self.hash_ring.get_nodes(key, self.replication_factor)
            
            successful_deletes = []
            failed_deletes = []
            
            # Delete from all replica nodes
            for node_id in stored_nodes:
                if node_id in self.data_store and key in self.data_store[node_id]:
                    try:
                        del self.data_store[node_id][key]
                        successful_deletes.append(node_id)
                    except Exception as e:
                        failed_deletes.append((node_id, str(e)))
            
            # Clean up location tracking
            if key in self.key_locations:
                del self.key_locations[key]
            
            return {
                'success': len(successful_deletes) > 0,
                'deleted_from_nodes': successful_deletes,
                'failed_deletes': failed_deletes
            }
    
    def _redistribute_data_for_new_node(self, new_node_id: str) -> List[str]:
        """Redistribute data when a new node is added"""
        
        redistributed_keys = []
        
        # Check all existing keys to see if they should move to the new node
        for existing_node_id, node_data in self.data_store.items():
            if existing_node_id == new_node_id:
                continue
            
            keys_to_move = []
            
            for key in list(node_data.keys()):
                # Check if this key should now be on the new node
                current_nodes = self.hash_ring.get_nodes(key, self.replication_factor)
                
                if new_node_id in current_nodes and existing_node_id not in current_nodes:
                    keys_to_move.append(key)
            
            # Move the keys
            for key in keys_to_move:
                data_item = node_data[key]
                self.data_store[new_node_id][key] = data_item
                del node_data[key]
                
                # Update location tracking
                if key in self.key_locations:
                    if existing_node_id in self.key_locations[key]:
                        self.key_locations[key].remove(existing_node_id)
                    if new_node_id not in self.key_locations[key]:
                        self.key_locations[key].append(new_node_id)
                
                redistributed_keys.append(key)
        
        self.metrics['redistributions'] += len(redistributed_keys)
        return redistributed_keys
    
    def _redistribute_data_from_removed_node(self, removed_node_id: str, 
                                           node_data: Dict[str, DataItem]) -> List[str]:
        """Redistribute data when a node is removed"""
        
        redistributed_keys = []
        
        for key, data_item in node_data.items():
            # Find new nodes for this key
            new_nodes = self.hash_ring.get_nodes(key, self.replication_factor)
            
            # Store on new nodes that don't already have it
            for node_id in new_nodes:
                if node_id in self.data_store and key not in self.data_store[node_id]:
                    self.data_store[node_id][key] = data_item
                    redistributed_keys.append(key)
                    break  # Only need to store on one new node
            
            # Update location tracking
            if key in self.key_locations:
                if removed_node_id in self.key_locations[key]:
                    self.key_locations[key].remove(removed_node_id)
                
                # Add new nodes
                for node_id in new_nodes:
                    if node_id not in self.key_locations[key]:
                        self.key_locations[key].append(node_id)
        
        self.metrics['redistributions'] += len(redistributed_keys)
        return redistributed_keys
    
    def get_cluster_stats(self) -> Dict[str, Any]:
        """Get comprehensive cluster statistics"""
        
        with self.lock:
            ring_stats = self.hash_ring.get_ring_stats()
            
            # Calculate data distribution
            data_distribution = {}
            total_keys = 0
            total_size = 0
            
            for node_id, node_data in self.data_store.items():
                node_key_count = len(node_data)
                node_size = sum(item.size for item in node_data.values())
                
                data_distribution[node_id] = {
                    'key_count': node_key_count,
                    'total_size_bytes': node_size,
                    'avg_key_size': node_size / node_key_count if node_key_count > 0 else 0
                }
                
                total_keys += node_key_count
                total_size += node_size
            
            return {
                'ring_statistics': ring_stats,
                'data_distribution': data_distribution,
                'cluster_summary': {
                    'total_keys': total_keys,
                    'total_size_bytes': total_size,
                    'replication_factor': self.replication_factor,
                    'average_keys_per_node': total_keys / len(self.data_store) if self.data_store else 0
                },
                'performance_metrics': self.metrics.copy()
            }

# Example usage and demonstration
print("=== Consistent Hashing Demo ===")

# Create distributed hash table
dht = DistributedHashTable(replication_factor=3)

# Add initial nodes
nodes = [
    Node("node-1", "192.168.1.10", 8080, weight=1),
    Node("node-2", "192.168.1.11", 8080, weight=1),
    Node("node-3", "192.168.1.12", 8080, weight=2),  # Higher weight
    Node("node-4", "192.168.1.13", 8080, weight=1)
]

print("\n--- Adding Nodes ---")
for node in nodes:
    result = dht.add_node(node)
    print(f"Added {node.node_id}: {result['success']}, virtual nodes: {result.get('virtual_nodes_added', 0)}")

# Store some data
print("\n--- Storing Data ---")
test_data = {
    "user:1001": {"name": "John Doe", "email": "john@example.com"},
    "user:1002": {"name": "Jane Smith", "email": "jane@example.com"},
    "user:1003": {"name": "Bob Johnson", "email": "bob@example.com"},
    "session:abc123": {"user_id": 1001, "expires": 1640995200},
    "cache:popular_items": ["item1", "item2", "item3"],
    "config:app_settings": {"theme": "dark", "notifications": True}
}

for key, value in test_data.items():
    result = dht.put(key, value)
    responsible_nodes = dht.hash_ring.get_nodes(key, 3)
    print(f"Stored {key}: {result['success']}, nodes: {responsible_nodes}")

# Retrieve data
print("\n--- Retrieving Data ---")
for key in ["user:1001", "session:abc123", "nonexistent:key"]:
    result = dht.get(key)
    if result['success']:
        print(f"Retrieved {key}: {result['value']} from {result['retrieved_from_node']}")
    else:
        print(f"Failed to retrieve {key}: {result['error']}")

# Show initial cluster stats
print("\n--- Initial Cluster Stats ---")
stats = dht.get_cluster_stats()
print(f"Total keys: {stats['cluster_summary']['total_keys']}")
print(f"Ring balance score: {stats['ring_statistics']['ring_balance_score']:.1f}")

print("Data distribution:")
for node_id, distribution in stats['data_distribution'].items():
    print(f"  {node_id}: {distribution['key_count']} keys, {distribution['total_size_bytes']} bytes")

# Add a new node (demonstrate minimal redistribution)
print("\n--- Adding New Node (Demonstrating Minimal Redistribution) ---")
new_node = Node("node-5", "192.168.1.14", 8080, weight=1)
add_result = dht.add_node(new_node)
print(f"Added node-5: {add_result['success']}")
print(f"Redistributed keys: {add_result['redistributed_keys']}")
print(f"Keys moved: {add_result.get('keys', [])}")

# Show stats after adding node
print("\n--- Stats After Adding Node ---")
new_stats = dht.get_cluster_stats()
print(f"Total keys: {new_stats['cluster_summary']['total_keys']}")
print(f"Ring balance score: {new_stats['ring_statistics']['ring_balance_score']:.1f}")

print("New data distribution:")
for node_id, distribution in new_stats['data_distribution'].items():
    print(f"  {node_id}: {distribution['key_count']} keys, {distribution['total_size_bytes']} bytes")

# Remove a node (demonstrate fault tolerance)
print("\n--- Removing Node (Demonstrating Fault Tolerance) ---")
remove_result = dht.remove_node("node-2")
print(f"Removed node-2: {remove_result['success']}")
print(f"Redistributed keys: {remove_result['redistributed_keys']}")

# Verify data is still accessible
print("\n--- Verifying Data After Node Removal ---")
for key in ["user:1001", "user:1002", "session:abc123"]:
    result = dht.get(key)
    if result['success']:
        print(f"✓ {key} still accessible from {result['retrieved_from_node']}")
    else:
        print(f"✗ {key} lost: {result['error']}")

# Rebalance the ring
print("\n--- Rebalancing Ring ---")
rebalance_result = dht.hash_ring.rebalance_ring(target_deviation=3.0)
print(f"Rebalancing needed: {rebalance_result.get('rebalancing_needed', False)}")
if rebalance_result.get('adjustments_made', 0) > 0:
    print(f"Adjustments made: {rebalance_result['adjustments_made']}")

# Final stats
print("\n--- Final Cluster Stats ---")
final_stats = dht.get_cluster_stats()
print(f"Ring balance score: {final_stats['ring_statistics']['ring_balance_score']:.1f}")
print(f"Performance metrics: {final_stats['performance_metrics']}")

# Demonstrate hash distribution visualization
print("\n--- Hash Distribution Analysis ---")
ring_stats = dht.hash_ring.get_ring_stats()
load_dist = ring_stats['node_details']

print("Load distribution per node:")
for node_id, load_info in load_dist.items():
    print(f"  {node_id}: {load_info['load_percentage']:.2f}% "
          f"({load_info['virtual_nodes']} virtual nodes)")

print(f"Standard deviation: {ring_stats['load_distribution']['std_deviation']:.2f}")
print(f"Min/Max load: {ring_stats['load_distribution']['min_load']:.2f}% / "
      f"{ring_stats['load_distribution']['max_load']:.2f}%")
```

## 🚀 Advanced Consistent Hashing Patterns

```python
class WeightedConsistentHashing:
    """Advanced consistent hashing with node weights and dynamic rebalancing"""
    
    def __init__(self):
        self.hash_ring = ConsistentHashRing()
        self.node_weights: Dict[str, int] = {}
        self.load_monitor = LoadMonitor()
        
    def add_weighted_node(self, node: Node) -> Dict[str, Any]:
        """Add node with custom weight"""
        
        # Store weight
        self.node_weights[node.node_id] = node.weight
        
        # Calculate virtual nodes based on weight and current load distribution
        optimal_virtual_nodes = self._calculate_optimal_virtual_nodes(node)
        
        # Temporarily adjust virtual nodes per node for this addition
        original_virtual_nodes = self.hash_ring.virtual_nodes_per_node
        self.hash_ring.virtual_nodes_per_node = optimal_virtual_nodes
        
        result = self.hash_ring.add_node(node)
        
        # Restore original setting
        self.hash_ring.virtual_nodes_per_node = original_virtual_nodes
        
        return result
    
    def _calculate_optimal_virtual_nodes(self, node: Node) -> int:
        """Calculate optimal number of virtual nodes based on weight and cluster state"""
        
        base_virtual_nodes = 150
        
        # Adjust based on node weight
        weight_factor = node.weight
        
        # Adjust based on current cluster imbalance
        current_stats = self.hash_ring.get_ring_stats()
        
        if 'ring_balance_score' in current_stats:
            balance_score = current_stats['ring_balance_score']
            
            if balance_score < 70:  # Poor balance
                # Increase virtual nodes for better distribution
                balance_factor = 1.5
            elif balance_score > 90:  # Good balance
                # Maintain current virtual node count
                balance_factor = 1.0
            else:
                # Moderate improvement needed
                balance_factor = 1.2
        else:
            balance_factor = 1.0
        
        optimal_count = int(base_virtual_nodes * weight_factor * balance_factor)
        return max(50, min(500, optimal_count))  # Clamp between 50-500

class LoadMonitor:
    """Monitor and track load patterns for optimization"""
    
    def __init__(self):
        self.access_patterns: Dict[str, List[float]] = defaultdict(list)
        self.hot_keys: Set[str] = set()
        self.cold_keys: Set[str] = set()
        self.monitoring_window = 3600  # 1 hour
        
    def record_access(self, key: str, timestamp: float = None):
        """Record key access for pattern analysis"""
        
        if timestamp is None:
            timestamp = time.time()
        
        self.access_patterns[key].append(timestamp)
        
        # Keep only recent accesses
        cutoff_time = timestamp - self.monitoring_window
        self.access_patterns[key] = [t for t in self.access_patterns[key] if t >= cutoff_time]
        
        # Update hot/cold classification
        self._update_key_classification(key, timestamp)
    
    def _update_key_classification(self, key: str, current_time: float):
        """Classify keys as hot or cold based on access patterns"""
        
        accesses = self.access_patterns[key]
        
        if len(accesses) >= 10:  # At least 10 accesses in the window
            # Calculate access frequency
            time_span = current_time - min(accesses)
            frequency = len(accesses) / max(time_span / 3600, 0.1)  # accesses per hour
            
            if frequency >= 50:  # 50+ accesses per hour
                self.hot_keys.add(key)
                self.cold_keys.discard(key)
            elif frequency <= 1:  # 1 or fewer accesses per hour
                self.cold_keys.add(key)
                self.hot_keys.discard(key)
    
    def get_hot_keys(self, limit: int = 100) -> List[Tuple[str, float]]:
        """Get most frequently accessed keys"""
        
        current_time = time.time()
        key_frequencies = []
        
        for key in self.hot_keys:
            accesses = self.access_patterns[key]
            if accesses:
                time_span = current_time - min(accesses)
                frequency = len(accesses) / max(time_span / 3600, 0.1)
                key_frequencies.append((key, frequency))
        
        key_frequencies.sort(key=lambda x: x[1], reverse=True)
        return key_frequencies[:limit]
    
    def suggest_optimizations(self) -> Dict[str, Any]:
        """Suggest optimizations based on access patterns"""
        
        hot_keys = self.get_hot_keys(20)
        
        suggestions = {
            'hot_key_optimizations': [],
            'cold_key_optimizations': [],
            'replication_adjustments': []
        }
        
        # Hot key suggestions
        if hot_keys:
            suggestions['hot_key_optimizations'] = [
                {
                    'type': 'increase_replication',
                    'keys': [key for key, _ in hot_keys[:10]],
                    'reason': 'High access frequency detected'
                },
                {
                    'type': 'enable_caching',
                    'keys': [key for key, _ in hot_keys],
                    'reason': 'Frequently accessed keys benefit from caching'
                }
            ]
        
        # Cold key suggestions
        if len(self.cold_keys) > 100:
            suggestions['cold_key_optimizations'] = [
                {
                    'type': 'reduce_replication',
                    'keys': list(self.cold_keys)[:50],
                    'reason': 'Infrequently accessed keys can use lower replication'
                }
            ]
        
        return suggestions

class GeoDistributedConsistentHashing:
    """Consistent hashing with geographic awareness"""
    
    def __init__(self):
        self.regional_rings: Dict[str, ConsistentHashRing] = {}
        self.global_ring = ConsistentHashRing()
        self.node_regions: Dict[str, str] = {}
        self.cross_region_replication = True
        
    def add_regional_node(self, node: Node, region: str) -> Dict[str, Any]:
        """Add node to specific geographic region"""
        
        # Create regional ring if it doesn't exist
        if region not in self.regional_rings:
            self.regional_rings[region] = ConsistentHashRing()
        
        # Add to regional ring
        regional_result = self.regional_rings[region].add_node(node)
        
        # Add to global ring with region prefix
        global_node = Node(
            node_id=f"{region}:{node.node_id}",
            host=node.host,
            port=node.port,
            weight=node.weight,
            metadata={**node.metadata, 'region': region}
        )
        
        global_result = self.global_ring.add_node(global_node)
        
        # Track node region
        self.node_regions[node.node_id] = region
        
        return {
            'success': regional_result['success'] and global_result['success'],
            'regional_result': regional_result,
            'global_result': global_result,
            'region': region
        }
    
    def get_nodes_with_locality(self, key: str, preferred_region: str = None, 
                               count: int = 3) -> Dict[str, Any]:
        """Get nodes with geographic locality preference"""
        
        result = {
            'primary_nodes': [],
            'fallback_nodes': [],
            'regions_used': []
        }
        
        # Try preferred region first
        if preferred_region and preferred_region in self.regional_rings:
            regional_nodes = self.regional_rings[preferred_region].get_nodes(key, count)
            
            for node_id in regional_nodes:
                result['primary_nodes'].append(f"{preferred_region}:{node_id}")
                if preferred_region not in result['regions_used']:
                    result['regions_used'].append(preferred_region)
        
        # Fill remaining slots with global ring
        remaining_count = count - len(result['primary_nodes'])
        
        if remaining_count > 0:
            global_nodes = self.global_ring.get_nodes(key, count + 2)  # Get extra for filtering
            
            for global_node_id in global_nodes:
                if global_node_id not in result['primary_nodes']:
                    result['fallback_nodes'].append(global_node_id)
                    
                    # Extract region from global node id
                    if ':' in global_node_id:
                        region = global_node_id.split(':', 1)[0]
                        if region not in result['regions_used']:
                            result['regions_used'].append(region)
                    
                    if len(result['fallback_nodes']) >= remaining_count:
                        break
        
        return result
    
    def get_regional_stats(self) -> Dict[str, Any]:
        """Get statistics for each region"""
        
        regional_stats = {}
        
        for region, ring in self.regional_rings.items():
            regional_stats[region] = {
                'nodes': len(ring.nodes),
                'virtual_nodes': len(ring.ring),
                'balance_score': ring.get_ring_stats().get('ring_balance_score', 0),
                'load_distribution': ring.get_load_distribution()
            }
        
        return {
            'regional_statistics': regional_stats,
            'global_statistics': self.global_ring.get_ring_stats(),
            'cross_region_replication': self.cross_region_replication
        }

# Example usage of advanced patterns
print("\n=== Advanced Consistent Hashing Patterns Demo ===")

# Weighted consistent hashing
print("\n--- Weighted Consistent Hashing ---")
weighted_hash = WeightedConsistentHashing()

# Add nodes with different weights
high_capacity_node = Node("high-cap-1", "192.168.1.20", 8080, weight=3)
medium_capacity_node = Node("medium-cap-1", "192.168.1.21", 8080, weight=2)
low_capacity_node = Node("low-cap-1", "192.168.1.22", 8080, weight=1)

weighted_hash.add_weighted_node(high_capacity_node)
weighted_hash.add_weighted_node(medium_capacity_node)
weighted_hash.add_weighted_node(low_capacity_node)

# Check load distribution
weighted_stats = weighted_hash.hash_ring.get_ring_stats()
print("Weighted load distribution:")
for node_id, load_info in weighted_stats['node_details'].items():
    weight = weighted_hash.node_weights.get(node_id, 1)
    print(f"  {node_id} (weight {weight}): {load_info['load_percentage']:.2f}% load")

# Geographic distribution
print("\n--- Geographic Consistent Hashing ---")
geo_hash = GeoDistributedConsistentHashing()

# Add nodes in different regions
us_east_nodes = [
    Node("us-east-1", "10.0.1.10", 8080),
    Node("us-east-2", "10.0.1.11", 8080)
]

us_west_nodes = [
    Node("us-west-1", "10.0.2.10", 8080),
    Node("us-west-2", "10.0.2.11", 8080)
]

europe_nodes = [
    Node("eu-1", "10.0.3.10", 8080),
    Node("eu-2", "10.0.3.11", 8080)
]

for node in us_east_nodes:
    geo_hash.add_regional_node(node, "us-east")

for node in us_west_nodes:
    geo_hash.add_regional_node(node, "us-west")

for node in europe_nodes:
    geo_hash.add_regional_node(node, "europe")

# Test geographic locality
test_keys = ["user:east:1001", "user:west:2002", "user:eu:3003"]

for key in test_keys:
    # Extract preferred region from key
    if ":east:" in key:
        preferred_region = "us-east"
    elif ":west:" in key:
        preferred_region = "us-west"
    elif ":eu:" in key:
        preferred_region = "europe"
    else:
        preferred_region = None
    
    locality_result = geo_hash.get_nodes_with_locality(key, preferred_region, 3)
    print(f"Key {key} (preferred: {preferred_region}):")
    print(f"  Primary nodes: {locality_result['primary_nodes']}")
    print(f"  Fallback nodes: {locality_result['fallback_nodes']}")
    print(f"  Regions used: {locality_result['regions_used']}")

# Regional statistics
print("\n--- Regional Statistics ---")
geo_stats = geo_hash.get_regional_stats()

for region, stats in geo_stats['regional_statistics'].items():
    print(f"{region}: {stats['nodes']} nodes, balance score: {stats['balance_score']:.1f}")

print("\n--- Advanced Patterns Demo Completed ---")
```

## 📚 Conclusion

Consistent hashing is a fundamental technique that enables distributed systems to scale gracefully while maintaining data locality and minimizing redistribution overhead. From simple hash rings to sophisticated geographic distribution with weighted nodes, consistent hashing provides the foundation for building resilient, scalable distributed systems.

**Key Takeaways:**

1. **Minimal Redistribution**: Only adjacent data moves when nodes are added or removed
2. **Load Balancing**: Virtual nodes ensure even distribution across physical nodes
3. **Fault Tolerance**: System continues operating when nodes fail
4. **Geographic Awareness**: Optimize for locality while maintaining global consistency
5. **Dynamic Rebalancing**: Monitor and adjust distribution based on actual load patterns

The future of consistent hashing includes machine learning-powered load prediction, quantum-resistant hash functions, and integration with edge computing architectures. Whether you're building distributed caches, databases, or content delivery networks, understanding consistent hashing is essential for creating systems that scale efficiently.

Remember: consistent hashing is not just about distributing data—it's about creating a foundation that allows distributed systems to grow and adapt while maintaining performance and reliability characteristics that users depend on.
