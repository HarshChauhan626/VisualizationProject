# Distributed File Systems: Storing Data Across the Globe

## 🎯 What are Distributed File Systems?

A distributed file system is like having a massive library with books spread across multiple buildings worldwide, but with a single catalog system that makes it appear as if all books are in one location. Just as you can request any book and the librarian will retrieve it from the appropriate building without you knowing where it's physically stored, a distributed file system stores data across multiple machines while providing a unified interface for accessing that data.

## 🏗️ Core Concepts

### The Global Library Analogy
- **Distributed Storage**: Books stored in multiple library branches
- **Unified Catalog**: Single system to find and access any book
- **Replication**: Multiple copies of popular books in different locations
- **Load Distribution**: Spreading requests across different branches
- **Fault Tolerance**: If one branch burns down, books are still available elsewhere

### Why Distributed File Systems Matter
1. **Scalability**: Handle petabytes of data across thousands of machines
2. **Reliability**: Data survives individual machine failures through replication
3. **Performance**: Parallel access to data from multiple locations
4. **Geographic Distribution**: Store data close to users worldwide
5. **Cost Efficiency**: Use commodity hardware instead of expensive specialized storage

## 🗄️ Core Architecture Patterns

```python
import hashlib
import time
import random
import threading
from typing import Dict, List, Any, Optional, Tuple
from enum import Enum
from dataclasses import dataclass
from collections import defaultdict

class NodeStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    FAILED = "failed"
    RECOVERING = "recovering"

@dataclass
class DataBlock:
    block_id: str
    data: bytes
    checksum: str
    size: int
    created_at: float
    replicas: List[str]  # List of node IDs storing this block

@dataclass
class FileMetadata:
    file_path: str
    file_size: int
    block_count: int
    block_ids: List[str]
    replication_factor: int
    created_at: float
    modified_at: float
    permissions: Dict[str, Any]

class StorageNode:
    def __init__(self, node_id: str, capacity_gb: int):
        self.node_id = node_id
        self.capacity_bytes = capacity_gb * 1024 * 1024 * 1024
        self.used_bytes = 0
        self.blocks: Dict[str, DataBlock] = {}
        self.status = NodeStatus.HEALTHY
        self.last_heartbeat = time.time()
        self.read_requests = 0
        self.write_requests = 0
        self.error_count = 0
        
    def store_block(self, block: DataBlock) -> bool:
        """Store a data block on this node"""
        
        if self.used_bytes + block.size > self.capacity_bytes:
            return False  # Not enough space
        
        if self.status != NodeStatus.HEALTHY:
            return False  # Node not healthy
        
        # Verify checksum
        calculated_checksum = hashlib.md5(block.data).hexdigest()
        if calculated_checksum != block.checksum:
            self.error_count += 1
            return False  # Checksum mismatch
        
        self.blocks[block.block_id] = block
        self.used_bytes += block.size
        self.write_requests += 1
        
        return True
    
    def retrieve_block(self, block_id: str) -> Optional[DataBlock]:
        """Retrieve a data block from this node"""
        
        if self.status == NodeStatus.FAILED:
            return None
        
        if block_id not in self.blocks:
            return None
        
        self.read_requests += 1
        
        # Simulate occasional read errors
        if random.random() < 0.001:  # 0.1% error rate
            self.error_count += 1
            return None
        
        return self.blocks[block_id]
    
    def delete_block(self, block_id: str) -> bool:
        """Delete a data block from this node"""
        
        if block_id not in self.blocks:
            return False
        
        block = self.blocks[block_id]
        self.used_bytes -= block.size
        del self.blocks[block_id]
        
        return True
    
    def get_utilization(self) -> float:
        """Get storage utilization percentage"""
        return (self.used_bytes / self.capacity_bytes) * 100
    
    def get_stats(self) -> Dict[str, Any]:
        """Get node statistics"""
        return {
            'node_id': self.node_id,
            'status': self.status.value,
            'capacity_gb': self.capacity_bytes / (1024**3),
            'used_gb': self.used_bytes / (1024**3),
            'utilization_percent': self.get_utilization(),
            'block_count': len(self.blocks),
            'read_requests': self.read_requests,
            'write_requests': self.write_requests,
            'error_count': self.error_count,
            'last_heartbeat': self.last_heartbeat
        }

class DistributedFileSystem:
    def __init__(self, default_replication_factor: int = 3, block_size_mb: int = 64):
        self.nodes: Dict[str, StorageNode] = {}
        self.file_metadata: Dict[str, FileMetadata] = {}
        self.default_replication_factor = default_replication_factor
        self.block_size_bytes = block_size_mb * 1024 * 1024
        self.block_allocation_strategy = 'round_robin'
        self.rebalance_threshold = 0.1  # 10% imbalance triggers rebalancing
        
        # Monitoring and statistics
        self.total_files = 0
        self.total_blocks = 0
        self.total_storage_used = 0
        
    def add_storage_node(self, node_id: str, capacity_gb: int):
        """Add a storage node to the cluster"""
        node = StorageNode(node_id, capacity_gb)
        self.nodes[node_id] = node
        print(f"Added storage node {node_id} with {capacity_gb}GB capacity")
    
    def write_file(self, file_path: str, data: bytes, replication_factor: int = None) -> bool:
        """Write a file to the distributed file system"""
        
        if replication_factor is None:
            replication_factor = self.default_replication_factor
        
        # Check if we have enough healthy nodes for replication
        healthy_nodes = [n for n in self.nodes.values() if n.status == NodeStatus.HEALTHY]
        if len(healthy_nodes) < replication_factor:
            print(f"Error: Not enough healthy nodes for replication factor {replication_factor}")
            return False
        
        # Split file into blocks
        blocks = self._split_into_blocks(data)
        block_ids = []
        
        print(f"Writing file {file_path} ({len(data)} bytes) as {len(blocks)} blocks")
        
        # Store each block with replication
        for i, block_data in enumerate(blocks):
            block_id = f"{file_path}_block_{i}_{int(time.time())}"
            checksum = hashlib.md5(block_data).hexdigest()
            
            block = DataBlock(
                block_id=block_id,
                data=block_data,
                checksum=checksum,
                size=len(block_data),
                created_at=time.time(),
                replicas=[]
            )
            
            # Select nodes for replication
            selected_nodes = self._select_nodes_for_block(replication_factor)
            
            # Store block on selected nodes
            successful_replicas = []
            for node in selected_nodes:
                if node.store_block(block):
                    successful_replicas.append(node.node_id)
            
            if len(successful_replicas) < replication_factor:
                print(f"Warning: Block {block_id} only replicated to {len(successful_replicas)} nodes")
            
            block.replicas = successful_replicas
            block_ids.append(block_id)
        
        # Create file metadata
        metadata = FileMetadata(
            file_path=file_path,
            file_size=len(data),
            block_count=len(blocks),
            block_ids=block_ids,
            replication_factor=replication_factor,
            created_at=time.time(),
            modified_at=time.time(),
            permissions={'owner': 'user', 'mode': '644'}
        )
        
        self.file_metadata[file_path] = metadata
        self.total_files += 1
        self.total_blocks += len(blocks)
        self.total_storage_used += len(data)
        
        print(f"File {file_path} written successfully")
        return True
    
    def read_file(self, file_path: str) -> Optional[bytes]:
        """Read a file from the distributed file system"""
        
        if file_path not in self.file_metadata:
            print(f"File {file_path} not found")
            return None
        
        metadata = self.file_metadata[file_path]
        file_data = bytearray()
        
        print(f"Reading file {file_path} ({metadata.block_count} blocks)")
        
        # Read each block
        for block_id in metadata.block_ids:
            block_data = self._read_block_with_fallback(block_id)
            
            if block_data is None:
                print(f"Error: Could not read block {block_id}")
                return None
            
            file_data.extend(block_data)
        
        print(f"File {file_path} read successfully ({len(file_data)} bytes)")
        return bytes(file_data)
    
    def delete_file(self, file_path: str) -> bool:
        """Delete a file from the distributed file system"""
        
        if file_path not in self.file_metadata:
            print(f"File {file_path} not found")
            return False
        
        metadata = self.file_metadata[file_path]
        
        # Delete all blocks
        for block_id in metadata.block_ids:
            self._delete_block_from_all_replicas(block_id)
        
        # Remove metadata
        del self.file_metadata[file_path]
        self.total_files -= 1
        self.total_blocks -= metadata.block_count
        self.total_storage_used -= metadata.file_size
        
        print(f"File {file_path} deleted successfully")
        return True
    
    def _split_into_blocks(self, data: bytes) -> List[bytes]:
        """Split data into fixed-size blocks"""
        blocks = []
        
        for i in range(0, len(data), self.block_size_bytes):
            block_data = data[i:i + self.block_size_bytes]
            blocks.append(block_data)
        
        return blocks
    
    def _select_nodes_for_block(self, replication_factor: int) -> List[StorageNode]:
        """Select nodes for storing a block"""
        
        healthy_nodes = [n for n in self.nodes.values() if n.status == NodeStatus.HEALTHY]
        
        if self.block_allocation_strategy == 'round_robin':
            # Simple round-robin selection
            selected = []
            for i in range(replication_factor):
                if healthy_nodes:
                    node = healthy_nodes[i % len(healthy_nodes)]
                    if node not in selected:
                        selected.append(node)
            return selected
        
        elif self.block_allocation_strategy == 'least_used':
            # Select nodes with lowest utilization
            sorted_nodes = sorted(healthy_nodes, key=lambda n: n.get_utilization())
            return sorted_nodes[:replication_factor]
        
        else:
            # Random selection
            return random.sample(healthy_nodes, min(replication_factor, len(healthy_nodes)))
    
    def _read_block_with_fallback(self, block_id: str) -> Optional[bytes]:
        """Read block with fallback to replicas if primary fails"""
        
        # Find nodes that have this block
        replica_nodes = []
        for node in self.nodes.values():
            if block_id in node.blocks:
                replica_nodes.append(node)
        
        if not replica_nodes:
            print(f"Error: No replicas found for block {block_id}")
            return None
        
        # Try to read from each replica until successful
        for node in replica_nodes:
            block = node.retrieve_block(block_id)
            if block is not None:
                return block.data
        
        print(f"Error: All replicas failed for block {block_id}")
        return None
    
    def _delete_block_from_all_replicas(self, block_id: str):
        """Delete block from all replica nodes"""
        
        for node in self.nodes.values():
            if block_id in node.blocks:
                node.delete_block(block_id)
    
    def get_cluster_stats(self) -> Dict[str, Any]:
        """Get cluster-wide statistics"""
        
        healthy_nodes = len([n for n in self.nodes.values() if n.status == NodeStatus.HEALTHY])
        total_capacity = sum(n.capacity_bytes for n in self.nodes.values())
        total_used = sum(n.used_bytes for n in self.nodes.values())
        
        return {
            'total_nodes': len(self.nodes),
            'healthy_nodes': healthy_nodes,
            'total_files': self.total_files,
            'total_blocks': self.total_blocks,
            'total_capacity_gb': total_capacity / (1024**3),
            'total_used_gb': total_used / (1024**3),
            'cluster_utilization_percent': (total_used / total_capacity) * 100 if total_capacity > 0 else 0,
            'average_replication_factor': self.default_replication_factor,
            'block_size_mb': self.block_size_bytes / (1024**2)
        }
    
    def rebalance_cluster(self):
        """Rebalance data across nodes to maintain even distribution"""
        
        print("Starting cluster rebalancing...")
        
        # Calculate target utilization
        total_used = sum(n.used_bytes for n in self.nodes.values())
        total_capacity = sum(n.capacity_bytes for n in self.nodes.values())
        target_utilization = total_used / total_capacity if total_capacity > 0 else 0
        
        # Identify over-utilized and under-utilized nodes
        over_utilized = []
        under_utilized = []
        
        for node in self.nodes.values():
            if node.status != NodeStatus.HEALTHY:
                continue
                
            node_utilization = node.used_bytes / node.capacity_bytes
            
            if node_utilization > target_utilization + self.rebalance_threshold:
                over_utilized.append((node, node_utilization - target_utilization))
            elif node_utilization < target_utilization - self.rebalance_threshold:
                under_utilized.append((node, target_utilization - node_utilization))
        
        # Move blocks from over-utilized to under-utilized nodes
        moves_made = 0
        
        for over_node, excess in over_utilized:
            for under_node, deficit in under_utilized:
                if excess <= 0 or deficit <= 0:
                    continue
                
                # Find blocks to move
                blocks_to_move = []
                bytes_to_move = 0
                
                for block_id, block in over_node.blocks.items():
                    if bytes_to_move >= min(excess * over_node.capacity_bytes, 
                                          deficit * under_node.capacity_bytes):
                        break
                    
                    # Check if this block can be moved (has other replicas)
                    replica_count = sum(1 for n in self.nodes.values() 
                                      if n != over_node and block_id in n.blocks)
                    
                    if replica_count > 0:  # Safe to move
                        blocks_to_move.append(block)
                        bytes_to_move += block.size
                
                # Move the blocks
                for block in blocks_to_move:
                    if under_node.store_block(block):
                        over_node.delete_block(block.block_id)
                        moves_made += 1
                        
                        # Update replica list
                        block.replicas = [node_id for node_id in block.replicas 
                                        if node_id != over_node.node_id]
                        block.replicas.append(under_node.node_id)
        
        print(f"Rebalancing complete. Moved {moves_made} blocks.")

# Example usage: HDFS-like distributed file system
class HDFSLikeSystem(DistributedFileSystem):
    """HDFS-inspired distributed file system implementation"""
    
    def __init__(self):
        super().__init__(default_replication_factor=3, block_size_mb=128)
        self.namenode = NameNode()
        self.datanodes: Dict[str, DataNode] = {}
        
    def add_datanode(self, node_id: str, capacity_gb: int):
        """Add a DataNode to the cluster"""
        datanode = DataNode(node_id, capacity_gb)
        self.datanodes[node_id] = datanode
        self.add_storage_node(node_id, capacity_gb)
        
        # Register with NameNode
        self.namenode.register_datanode(datanode)
    
    def write_file_hdfs(self, file_path: str, data: bytes) -> bool:
        """Write file using HDFS-like protocol"""
        
        # Client contacts NameNode for write permission and block allocation
        write_plan = self.namenode.plan_write(file_path, len(data), self.default_replication_factor)
        
        if not write_plan['success']:
            print(f"Write failed: {write_plan['error']}")
            return False
        
        # Split data into blocks and write to allocated DataNodes
        blocks = self._split_into_blocks(data)
        block_info = []
        
        for i, (block_data, allocation) in enumerate(zip(blocks, write_plan['block_allocations'])):
            block_id = f"{file_path}_block_{i}_{int(time.time())}"
            
            # Write to primary DataNode, which will replicate to others
            primary_node = allocation['primary']
            replica_nodes = allocation['replicas']
            
            success = self._write_block_with_pipeline(
                block_id, block_data, primary_node, replica_nodes
            )
            
            if success:
                block_info.append({
                    'block_id': block_id,
                    'size': len(block_data),
                    'replicas': [primary_node] + replica_nodes
                })
            else:
                print(f"Failed to write block {block_id}")
                return False
        
        # Report successful write to NameNode
        self.namenode.commit_write(file_path, block_info)
        
        return True
    
    def _write_block_with_pipeline(self, block_id: str, data: bytes, 
                                  primary_node: str, replica_nodes: List[str]) -> bool:
        """Write block using replication pipeline"""
        
        # Create block
        checksum = hashlib.md5(data).hexdigest()
        block = DataBlock(
            block_id=block_id,
            data=data,
            checksum=checksum,
            size=len(data),
            created_at=time.time(),
            replicas=[]
        )
        
        # Write to primary node
        primary = self.datanodes[primary_node]
        if not primary.store_block(block):
            return False
        
        # Pipeline replication to replica nodes
        for replica_node_id in replica_nodes:
            replica_node = self.datanodes[replica_node_id]
            if not replica_node.store_block(block):
                print(f"Warning: Failed to replicate to {replica_node_id}")
        
        return True

class NameNode:
    """HDFS NameNode equivalent - manages metadata and coordinates operations"""
    
    def __init__(self):
        self.file_system_tree = {}
        self.block_locations = {}  # block_id -> list of node_ids
        self.datanode_info = {}
        self.edit_log = []
        
    def register_datanode(self, datanode):
        """Register a DataNode with the NameNode"""
        self.datanode_info[datanode.node_id] = {
            'capacity': datanode.capacity_bytes,
            'used': datanode.used_bytes,
            'last_heartbeat': time.time(),
            'status': datanode.status
        }
        
    def plan_write(self, file_path: str, file_size: int, replication_factor: int) -> Dict[str, Any]:
        """Plan write operation and allocate blocks"""
        
        # Check if file already exists
        if file_path in self.file_system_tree:
            return {'success': False, 'error': 'File already exists'}
        
        # Calculate number of blocks needed
        block_size = 128 * 1024 * 1024  # 128MB
        num_blocks = (file_size + block_size - 1) // block_size
        
        # Select DataNodes for each block
        block_allocations = []
        
        for _ in range(num_blocks):
            # Select nodes with enough space and good health
            available_nodes = [
                node_id for node_id, info in self.datanode_info.items()
                if info['status'] == NodeStatus.HEALTHY and 
                   info['used'] < info['capacity'] * 0.9  # Not too full
            ]
            
            if len(available_nodes) < replication_factor:
                return {'success': False, 'error': 'Not enough healthy DataNodes'}
            
            # Select primary and replica nodes
            selected_nodes = random.sample(available_nodes, replication_factor)
            
            block_allocations.append({
                'primary': selected_nodes[0],
                'replicas': selected_nodes[1:]
            })
        
        return {
            'success': True,
            'block_allocations': block_allocations,
            'num_blocks': num_blocks
        }
    
    def commit_write(self, file_path: str, block_info: List[Dict[str, Any]]):
        """Commit successful write to metadata"""
        
        # Add to file system tree
        self.file_system_tree[file_path] = {
            'blocks': block_info,
            'size': sum(block['size'] for block in block_info),
            'created_at': time.time(),
            'replication_factor': len(block_info[0]['replicas']) if block_info else 0
        }
        
        # Update block location mapping
        for block in block_info:
            self.block_locations[block['block_id']] = block['replicas']
        
        # Log the operation
        self.edit_log.append({
            'operation': 'create',
            'file_path': file_path,
            'timestamp': time.time(),
            'block_count': len(block_info)
        })

class DataNode(StorageNode):
    """HDFS DataNode equivalent - stores actual data blocks"""
    
    def __init__(self, node_id: str, capacity_gb: int):
        super().__init__(node_id, capacity_gb)
        self.block_reports = []
        
    def generate_block_report(self) -> Dict[str, Any]:
        """Generate block report for NameNode"""
        
        report = {
            'node_id': self.node_id,
            'timestamp': time.time(),
            'blocks': list(self.blocks.keys()),
            'total_blocks': len(self.blocks),
            'used_bytes': self.used_bytes,
            'capacity_bytes': self.capacity_bytes
        }
        
        self.block_reports.append(report)
        return report

# Usage example
print("=== Distributed File System Demo ===")

# Create HDFS-like system
dfs = HDFSLikeSystem()

# Add DataNodes
dfs.add_datanode("datanode-1", 100)  # 100GB
dfs.add_datanode("datanode-2", 100)  # 100GB
dfs.add_datanode("datanode-3", 100)  # 100GB
dfs.add_datanode("datanode-4", 100)  # 100GB

# Write some files
test_data_1 = b"This is a test file for the distributed file system. " * 1000
test_data_2 = b"Another test file with different content. " * 2000

success1 = dfs.write_file("/user/data/file1.txt", test_data_1)
success2 = dfs.write_file("/user/data/file2.txt", test_data_2)

print(f"File 1 write: {'Success' if success1 else 'Failed'}")
print(f"File 2 write: {'Success' if success2 else 'Failed'}")

# Read files back
read_data_1 = dfs.read_file("/user/data/file1.txt")
read_data_2 = dfs.read_file("/user/data/file2.txt")

print(f"File 1 read: {'Success' if read_data_1 == test_data_1 else 'Failed'}")
print(f"File 2 read: {'Success' if read_data_2 == test_data_2 else 'Failed'}")

# Check cluster statistics
stats = dfs.get_cluster_stats()
print(f"\nCluster Statistics:")
print(f"Total nodes: {stats['total_nodes']}")
print(f"Total files: {stats['total_files']}")
print(f"Total blocks: {stats['total_blocks']}")
print(f"Cluster utilization: {stats['cluster_utilization_percent']:.2f}%")

# Simulate node failure and test fault tolerance
print(f"\n=== Simulating Node Failure ===")
failed_node = dfs.nodes["datanode-1"]
failed_node.status = NodeStatus.FAILED

# Try to read files after node failure
read_after_failure_1 = dfs.read_file("/user/data/file1.txt")
read_after_failure_2 = dfs.read_file("/user/data/file2.txt")

print(f"File 1 read after failure: {'Success' if read_after_failure_1 == test_data_1 else 'Failed'}")
print(f"File 2 read after failure: {'Success' if read_after_failure_2 == test_data_2 else 'Failed'}")

# Perform cluster rebalancing
dfs.rebalance_cluster()

final_stats = dfs.get_cluster_stats()
print(f"\nFinal cluster utilization: {final_stats['cluster_utilization_percent']:.2f}%")
```

## 📊 Advanced Distributed File System Features

```python
class ConsistentHashingDFS(DistributedFileSystem):
    """Distributed file system using consistent hashing for data placement"""
    
    def __init__(self):
        super().__init__()
        self.hash_ring = ConsistentHashRing()
        self.virtual_nodes_per_physical = 150  # Virtual nodes for better distribution
        
    def add_storage_node(self, node_id: str, capacity_gb: int):
        """Add node to both storage and hash ring"""
        super().add_storage_node(node_id, capacity_gb)
        
        # Add virtual nodes to hash ring
        for i in range(self.virtual_nodes_per_physical):
            virtual_node_id = f"{node_id}:{i}"
            hash_value = self._hash_function(virtual_node_id)
            self.hash_ring.add_node(hash_value, node_id)
        
        print(f"Added {node_id} to hash ring with {self.virtual_nodes_per_physical} virtual nodes")
    
    def remove_storage_node(self, node_id: str):
        """Remove node from storage and hash ring"""
        if node_id in self.nodes:
            del self.nodes[node_id]
            
            # Remove virtual nodes from hash ring
            self.hash_ring.remove_physical_node(node_id)
            
            print(f"Removed {node_id} from cluster")
    
    def _select_nodes_for_block(self, replication_factor: int) -> List[StorageNode]:
        """Select nodes using consistent hashing"""
        
        # Generate random key for this block
        block_key = str(random.random())
        hash_value = self._hash_function(block_key)
        
        # Get nodes from hash ring
        selected_node_ids = self.hash_ring.get_nodes(hash_value, replication_factor)
        
        # Return actual node objects
        selected_nodes = []
        for node_id in selected_node_ids:
            if node_id in self.nodes and self.nodes[node_id].status == NodeStatus.HEALTHY:
                selected_nodes.append(self.nodes[node_id])
        
        return selected_nodes
    
    def _hash_function(self, key: str) -> int:
        """Hash function for consistent hashing"""
        return int(hashlib.md5(key.encode()).hexdigest(), 16)

class ConsistentHashRing:
    """Consistent hash ring implementation"""
    
    def __init__(self):
        self.ring = {}  # hash_value -> physical_node_id
        self.sorted_hashes = []
        
    def add_node(self, hash_value: int, physical_node_id: str):
        """Add virtual node to ring"""
        self.ring[hash_value] = physical_node_id
        self.sorted_hashes = sorted(self.ring.keys())
    
    def remove_physical_node(self, physical_node_id: str):
        """Remove all virtual nodes for a physical node"""
        hashes_to_remove = [h for h, node in self.ring.items() if node == physical_node_id]
        
        for hash_value in hashes_to_remove:
            del self.ring[hash_value]
        
        self.sorted_hashes = sorted(self.ring.keys())
    
    def get_nodes(self, hash_value: int, count: int) -> List[str]:
        """Get next N nodes clockwise from hash value"""
        if not self.sorted_hashes:
            return []
        
        # Find position in ring
        idx = self._find_position(hash_value)
        
        # Collect unique physical nodes
        selected_nodes = []
        seen_nodes = set()
        
        for i in range(len(self.sorted_hashes)):
            ring_idx = (idx + i) % len(self.sorted_hashes)
            physical_node = self.ring[self.sorted_hashes[ring_idx]]
            
            if physical_node not in seen_nodes:
                selected_nodes.append(physical_node)
                seen_nodes.add(physical_node)
                
                if len(selected_nodes) >= count:
                    break
        
        return selected_nodes
    
    def _find_position(self, hash_value: int) -> int:
        """Find position in sorted hash list"""
        for i, ring_hash in enumerate(self.sorted_hashes):
            if hash_value <= ring_hash:
                return i
        return 0  # Wrap around to beginning

class ReplicationManager:
    """Manages data replication and consistency"""
    
    def __init__(self, dfs: DistributedFileSystem):
        self.dfs = dfs
        self.replication_queue = []
        self.consistency_level = 'eventual'  # 'strong', 'eventual', 'weak'
        
    def check_replication_health(self) -> Dict[str, Any]:
        """Check health of data replication across cluster"""
        
        under_replicated_blocks = []
        over_replicated_blocks = []
        corrupt_blocks = []
        
        # Check each file's blocks
        for file_path, metadata in self.dfs.file_metadata.items():
            for block_id in metadata.block_ids:
                replica_count = 0
                replica_nodes = []
                
                # Count replicas across all nodes
                for node in self.dfs.nodes.values():
                    if block_id in node.blocks:
                        replica_count += 1
                        replica_nodes.append(node.node_id)
                        
                        # Check block integrity
                        block = node.blocks[block_id]
                        calculated_checksum = hashlib.md5(block.data).hexdigest()
                        
                        if calculated_checksum != block.checksum:
                            corrupt_blocks.append({
                                'block_id': block_id,
                                'node_id': node.node_id,
                                'file_path': file_path
                            })
                
                # Check replication level
                target_replicas = metadata.replication_factor
                
                if replica_count < target_replicas:
                    under_replicated_blocks.append({
                        'block_id': block_id,
                        'current_replicas': replica_count,
                        'target_replicas': target_replicas,
                        'file_path': file_path,
                        'replica_nodes': replica_nodes
                    })
                elif replica_count > target_replicas:
                    over_replicated_blocks.append({
                        'block_id': block_id,
                        'current_replicas': replica_count,
                        'target_replicas': target_replicas,
                        'file_path': file_path
                    })
        
        return {
            'under_replicated_blocks': under_replicated_blocks,
            'over_replicated_blocks': over_replicated_blocks,
            'corrupt_blocks': corrupt_blocks,
            'replication_health_score': self._calculate_replication_health_score(
                under_replicated_blocks, corrupt_blocks
            )
        }
    
    def repair_under_replicated_blocks(self, max_repairs: int = 10):
        """Repair under-replicated blocks"""
        
        health_report = self.check_replication_health()
        under_replicated = health_report['under_replicated_blocks']
        
        repairs_made = 0
        
        for block_info in under_replicated[:max_repairs]:
            block_id = block_info['block_id']
            current_replicas = block_info['current_replicas']
            target_replicas = block_info['target_replicas']
            needed_replicas = target_replicas - current_replicas
            
            # Find source node with the block
            source_node = None
            source_block = None
            
            for node in self.dfs.nodes.values():
                if block_id in node.blocks and node.status == NodeStatus.HEALTHY:
                    source_node = node
                    source_block = node.blocks[block_id]
                    break
            
            if not source_node:
                print(f"Error: No healthy source found for block {block_id}")
                continue
            
            # Select target nodes for additional replicas
            available_nodes = [
                n for n in self.dfs.nodes.values()
                if n.status == NodeStatus.HEALTHY and
                   block_id not in n.blocks and
                   n.used_bytes + source_block.size <= n.capacity_bytes
            ]
            
            target_nodes = available_nodes[:needed_replicas]
            
            # Create additional replicas
            for target_node in target_nodes:
                if target_node.store_block(source_block):
                    source_block.replicas.append(target_node.node_id)
                    repairs_made += 1
                    print(f"Replicated block {block_id} to node {target_node.node_id}")
        
        print(f"Completed {repairs_made} block repairs")
        return repairs_made
    
    def _calculate_replication_health_score(self, under_replicated: List, corrupt: List) -> float:
        """Calculate overall replication health score (0-100)"""
        
        total_blocks = self.dfs.total_blocks
        
        if total_blocks == 0:
            return 100.0
        
        # Penalties for problems
        under_replicated_penalty = len(under_replicated) / total_blocks * 50
        corruption_penalty = len(corrupt) / total_blocks * 100
        
        health_score = 100 - under_replicated_penalty - corruption_penalty
        
        return max(0, min(100, health_score))

# Usage example with advanced features
print("\n=== Advanced DFS Features Demo ===")

# Create consistent hashing DFS
advanced_dfs = ConsistentHashingDFS()

# Add nodes
for i in range(6):
    advanced_dfs.add_storage_node(f"node-{i}", 50)  # 50GB each

# Create replication manager
replication_mgr = ReplicationManager(advanced_dfs)

# Write test files
large_data = b"X" * (10 * 1024 * 1024)  # 10MB file
advanced_dfs.write_file("/test/large_file.dat", large_data)

# Check replication health
health_report = replication_mgr.check_replication_health()
print(f"Replication health score: {health_report['replication_health_score']:.1f}")
print(f"Under-replicated blocks: {len(health_report['under_replicated_blocks'])}")
print(f"Corrupt blocks: {len(health_report['corrupt_blocks'])}")

# Simulate node failures
print("\nSimulating multiple node failures...")
advanced_dfs.nodes["node-1"].status = NodeStatus.FAILED
advanced_dfs.nodes["node-2"].status = NodeStatus.FAILED

# Check health after failures
health_after_failure = replication_mgr.check_replication_health()
print(f"Health after failures: {health_after_failure['replication_health_score']:.1f}")

# Repair under-replicated blocks
repairs_made = replication_mgr.repair_under_replicated_blocks()
print(f"Repairs completed: {repairs_made}")

# Final health check
final_health = replication_mgr.check_replication_health()
print(f"Final health score: {final_health['replication_health_score']:.1f}")
```

## 📚 Conclusion

Distributed file systems are the backbone of modern data infrastructure, enabling organizations to store and process massive amounts of data reliably and efficiently. From simple replication strategies to sophisticated consistent hashing and automatic repair mechanisms, these systems provide the foundation for big data analytics, content delivery, and global-scale applications.

**Key Takeaways:**

1. **Design for Failure**: Assume individual components will fail and build redundancy accordingly
2. **Balance Consistency and Performance**: Choose appropriate consistency models for your use case
3. **Monitor and Repair**: Implement continuous monitoring and automatic repair mechanisms
4. **Scale Incrementally**: Design systems that can grow by adding more commodity hardware
5. **Optimize for Access Patterns**: Consider how data will be read and written when designing storage layout

The future of distributed file systems includes integration with cloud-native architectures, AI-powered data placement optimization, and quantum-resistant security measures. Whether you're building a content delivery network, a data lake, or a global backup system, understanding distributed file system concepts is essential for creating scalable, reliable data storage solutions.

Remember: distributed file systems are not just about storing data—they're about creating a reliable, scalable foundation that enables applications to focus on business logic rather than data management complexity.
