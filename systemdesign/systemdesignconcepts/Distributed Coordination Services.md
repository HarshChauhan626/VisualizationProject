# Distributed Coordination Services: The Nervous System of Distributed Systems

## 🎯 What are Distributed Coordination Services?

Distributed coordination services are like the air traffic control system for distributed systems. Just as air traffic controllers ensure planes don't collide, coordinate takeoffs and landings, and manage flight paths across multiple airports, coordination services help distributed system components work together safely by managing locks, configuration, leader election, and service discovery without conflicts.

## 🏗️ Core Concepts

### The Air Traffic Control Analogy
- **Coordination Service**: Central air traffic control tower
- **Distributed Nodes**: Individual airports and aircraft
- **Consensus**: All controllers agreeing on flight plans
- **Leader Election**: Designating the primary controller for a region
- **Configuration Management**: Updating flight routes and procedures
- **Service Discovery**: Helping planes find the right runway

### Why Coordination Services Matter
1. **Prevent Race Conditions**: Ensure only one node performs critical operations
2. **Maintain Consistency**: Keep distributed state synchronized
3. **Enable Leader Election**: Choose primary nodes for coordination
4. **Manage Configuration**: Distribute settings across the cluster
5. **Provide Service Discovery**: Help services find and communicate with each other

## 🗳️ ZooKeeper-Style Coordination Service

```python
import time
import threading
import socket
import json
from typing import Dict, List, Optional, Set, Callable, Any
from enum import Enum
from dataclasses import dataclass
from collections import defaultdict
import hashlib
import random

class NodeState(Enum):
    FOLLOWER = "follower"
    CANDIDATE = "candidate"
    LEADER = "leader"

class ZNodeType(Enum):
    PERSISTENT = "persistent"
    EPHEMERAL = "ephemeral"
    SEQUENTIAL = "sequential"
    EPHEMERAL_SEQUENTIAL = "ephemeral_sequential"

@dataclass
class ZNode:
    path: str
    data: bytes
    version: int
    created_time: float
    modified_time: float
    node_type: ZNodeType
    children: Set[str]
    watchers: Set[str]  # Client IDs watching this node
    session_id: Optional[str] = None  # For ephemeral nodes

class CoordinationService:
    def __init__(self, node_id: str, cluster_nodes: List[str]):
        self.node_id = node_id
        self.cluster_nodes = cluster_nodes
        self.state = NodeState.FOLLOWER
        self.current_term = 0
        self.voted_for = None
        self.log = []
        
        # ZooKeeper-like data structure
        self.znodes: Dict[str, ZNode] = {}
        self.sessions: Dict[str, Dict[str, Any]] = {}
        self.watchers: Dict[str, Set[str]] = defaultdict(set)  # path -> client_ids
        
        # Leadership and consensus
        self.leader_id = None
        self.votes_received = set()
        self.last_heartbeat = 0
        
        # Initialize root node
        self._create_root_node()
        
        # Start background services
        self.running = True
        self.election_thread = threading.Thread(target=self._election_loop)
        self.heartbeat_thread = threading.Thread(target=self._heartbeat_loop)
        self.election_thread.daemon = True
        self.heartbeat_thread.daemon = True
        
    def start(self):
        """Start the coordination service"""
        self.election_thread.start()
        self.heartbeat_thread.start()
        print(f"Coordination service {self.node_id} started")
    
    def stop(self):
        """Stop the coordination service"""
        self.running = False
        print(f"Coordination service {self.node_id} stopped")
    
    def _create_root_node(self):
        """Create root ZNode"""
        root = ZNode(
            path="/",
            data=b"",
            version=0,
            created_time=time.time(),
            modified_time=time.time(),
            node_type=ZNodeType.PERSISTENT,
            children=set(),
            watchers=set()
        )
        self.znodes["/"] = root
    
    def create_session(self, client_id: str, timeout: int = 30) -> str:
        """Create client session"""
        session_id = f"{client_id}_{int(time.time())}_{random.randint(1000, 9999)}"
        
        self.sessions[session_id] = {
            'client_id': client_id,
            'created_at': time.time(),
            'last_seen': time.time(),
            'timeout': timeout,
            'ephemeral_nodes': set()
        }
        
        print(f"Created session {session_id} for client {client_id}")
        return session_id
    
    def create_znode(self, path: str, data: bytes = b"", 
                    node_type: ZNodeType = ZNodeType.PERSISTENT,
                    session_id: str = None) -> bool:
        """Create a ZNode"""
        
        if path in self.znodes:
            return False  # Node already exists
        
        # Validate parent exists
        parent_path = self._get_parent_path(path)
        if parent_path != path and parent_path not in self.znodes:
            return False  # Parent doesn't exist
        
        # Handle sequential nodes
        if node_type in [ZNodeType.SEQUENTIAL, ZNodeType.EPHEMERAL_SEQUENTIAL]:
            path = self._generate_sequential_path(path)
        
        # Create the node
        znode = ZNode(
            path=path,
            data=data,
            version=0,
            created_time=time.time(),
            modified_time=time.time(),
            node_type=node_type,
            children=set(),
            watchers=set(),
            session_id=session_id if node_type in [ZNodeType.EPHEMERAL, ZNodeType.EPHEMERAL_SEQUENTIAL] else None
        )
        
        self.znodes[path] = znode
        
        # Add to parent's children
        if parent_path != path:
            self.znodes[parent_path].children.add(path)
        
        # Track ephemeral nodes
        if session_id and node_type in [ZNodeType.EPHEMERAL, ZNodeType.EPHEMERAL_SEQUENTIAL]:
            if session_id in self.sessions:
                self.sessions[session_id]['ephemeral_nodes'].add(path)
        
        # Notify watchers
        self._notify_watchers(parent_path, 'child_created', path)
        
        print(f"Created ZNode: {path}")
        return True
    
    def get_znode(self, path: str) -> Optional[ZNode]:
        """Get ZNode data"""
        return self.znodes.get(path)
    
    def set_data(self, path: str, data: bytes, version: int = -1) -> bool:
        """Set ZNode data"""
        
        if path not in self.znodes:
            return False
        
        znode = self.znodes[path]
        
        # Check version if specified
        if version != -1 and znode.version != version:
            return False  # Version mismatch
        
        # Update data
        znode.data = data
        znode.version += 1
        znode.modified_time = time.time()
        
        # Notify watchers
        self._notify_watchers(path, 'data_changed', None)
        
        return True
    
    def delete_znode(self, path: str, version: int = -1) -> bool:
        """Delete ZNode"""
        
        if path not in self.znodes:
            return False
        
        znode = self.znodes[path]
        
        # Check version if specified
        if version != -1 and znode.version != version:
            return False
        
        # Cannot delete if has children
        if znode.children:
            return False
        
        # Remove from parent
        parent_path = self._get_parent_path(path)
        if parent_path != path and parent_path in self.znodes:
            self.znodes[parent_path].children.discard(path)
        
        # Remove from session tracking
        if znode.session_id and znode.session_id in self.sessions:
            self.sessions[znode.session_id]['ephemeral_nodes'].discard(path)
        
        # Notify watchers
        self._notify_watchers(parent_path, 'child_deleted', path)
        
        # Delete the node
        del self.znodes[path]
        
        print(f"Deleted ZNode: {path}")
        return True
    
    def get_children(self, path: str, watch: bool = False, client_id: str = None) -> List[str]:
        """Get children of a ZNode"""
        
        if path not in self.znodes:
            return []
        
        # Add watcher if requested
        if watch and client_id:
            self.watchers[path].add(client_id)
        
        children = list(self.znodes[path].children)
        children.sort()  # Return sorted list
        
        return children
    
    def exists(self, path: str, watch: bool = False, client_id: str = None) -> bool:
        """Check if ZNode exists"""
        
        exists = path in self.znodes
        
        # Add watcher if requested and node doesn't exist
        if watch and client_id and not exists:
            self.watchers[path].add(client_id)
        
        return exists
    
    def _get_parent_path(self, path: str) -> str:
        """Get parent path of a ZNode"""
        if path == "/":
            return "/"
        
        parent = "/".join(path.split("/")[:-1])
        return "/" if parent == "" else parent
    
    def _generate_sequential_path(self, base_path: str) -> str:
        """Generate sequential path"""
        parent_path = self._get_parent_path(base_path)
        base_name = base_path.split("/")[-1]
        
        # Find highest sequence number
        max_seq = -1
        if parent_path in self.znodes:
            for child_path in self.znodes[parent_path].children:
                child_name = child_path.split("/")[-1]
                if child_name.startswith(base_name):
                    try:
                        seq_part = child_name[len(base_name):]
                        seq_num = int(seq_part)
                        max_seq = max(max_seq, seq_num)
                    except ValueError:
                        pass
        
        # Generate new sequential path
        new_seq = max_seq + 1
        sequential_name = f"{base_name}{new_seq:010d}"  # 10-digit sequence
        
        if parent_path == "/":
            return f"/{sequential_name}"
        else:
            return f"{parent_path}/{sequential_name}"
    
    def _notify_watchers(self, path: str, event_type: str, child_path: str):
        """Notify watchers of changes"""
        
        if path in self.watchers:
            for client_id in self.watchers[path].copy():
                print(f"Notifying {client_id} of {event_type} on {path}")
                # In real implementation, send notification to client
            
            # Remove one-time watchers
            self.watchers[path].clear()
    
    def _election_loop(self):
        """Leader election loop"""
        
        while self.running:
            try:
                if self.state == NodeState.FOLLOWER:
                    # Check if we should start election
                    if time.time() - self.last_heartbeat > 5:  # No heartbeat for 5 seconds
                        self._start_election()
                
                elif self.state == NodeState.CANDIDATE:
                    # Continue election process
                    self._continue_election()
                
                elif self.state == NodeState.LEADER:
                    # Send heartbeats
                    self._send_heartbeats()
                
                time.sleep(1)
                
            except Exception as e:
                print(f"Election loop error: {e}")
    
    def _heartbeat_loop(self):
        """Session management and cleanup loop"""
        
        while self.running:
            try:
                current_time = time.time()
                
                # Clean up expired sessions
                expired_sessions = []
                
                for session_id, session_info in self.sessions.items():
                    if current_time - session_info['last_seen'] > session_info['timeout']:
                        expired_sessions.append(session_id)
                
                # Remove expired sessions and their ephemeral nodes
                for session_id in expired_sessions:
                    self._cleanup_session(session_id)
                
                time.sleep(5)  # Check every 5 seconds
                
            except Exception as e:
                print(f"Heartbeat loop error: {e}")
    
    def _start_election(self):
        """Start leader election"""
        
        self.state = NodeState.CANDIDATE
        self.current_term += 1
        self.voted_for = self.node_id
        self.votes_received = {self.node_id}
        
        print(f"Node {self.node_id} starting election for term {self.current_term}")
        
        # Request votes from other nodes (simulated)
        self._request_votes()
    
    def _continue_election(self):
        """Continue election process"""
        
        # Check if we have majority
        majority = len(self.cluster_nodes) // 2 + 1
        
        if len(self.votes_received) >= majority:
            self._become_leader()
        else:
            # Simulate receiving votes
            if random.random() < 0.3:  # 30% chance of receiving vote
                voter = random.choice([n for n in self.cluster_nodes if n not in self.votes_received])
                self.votes_received.add(voter)
                print(f"Received vote from {voter}")
    
    def _become_leader(self):
        """Become the leader"""
        
        self.state = NodeState.LEADER
        self.leader_id = self.node_id
        
        print(f"Node {self.node_id} became leader for term {self.current_term}")
        
        # Send initial heartbeat
        self._send_heartbeats()
    
    def _send_heartbeats(self):
        """Send heartbeats to followers"""
        
        # Simulate sending heartbeats
        print(f"Leader {self.node_id} sending heartbeats")
        
        # Update our own heartbeat
        self.last_heartbeat = time.time()
    
    def _request_votes(self):
        """Request votes from other nodes (simulated)"""
        
        for node in self.cluster_nodes:
            if node != self.node_id:
                # Simulate vote request
                print(f"Requesting vote from {node}")
    
    def _cleanup_session(self, session_id: str):
        """Clean up expired session"""
        
        if session_id not in self.sessions:
            return
        
        session_info = self.sessions[session_id]
        
        # Delete ephemeral nodes
        for node_path in session_info['ephemeral_nodes'].copy():
            if node_path in self.znodes:
                self.delete_znode(node_path)
        
        # Remove session
        del self.sessions[session_id]
        
        print(f"Cleaned up expired session {session_id}")
    
    def get_cluster_status(self) -> Dict[str, Any]:
        """Get cluster status"""
        
        return {
            'node_id': self.node_id,
            'state': self.state.value,
            'current_term': self.current_term,
            'leader_id': self.leader_id,
            'total_znodes': len(self.znodes),
            'active_sessions': len(self.sessions),
            'cluster_nodes': self.cluster_nodes
        }

# Distributed Lock Implementation using Coordination Service
class DistributedLock:
    def __init__(self, coordination_service: CoordinationService, lock_path: str, session_id: str):
        self.coordination_service = coordination_service
        self.lock_path = lock_path
        self.session_id = session_id
        self.my_lock_node = None
        self.acquired = False
    
    def acquire(self, timeout: float = 10.0) -> bool:
        """Acquire distributed lock"""
        
        start_time = time.time()
        
        # Create ephemeral sequential node
        lock_node_path = f"{self.lock_path}/lock-"
        
        success = self.coordination_service.create_znode(
            lock_node_path,
            data=self.session_id.encode(),
            node_type=ZNodeType.EPHEMERAL_SEQUENTIAL,
            session_id=self.session_id
        )
        
        if not success:
            return False
        
        # Find our actual node path (with sequence number)
        children = self.coordination_service.get_children(self.lock_path)
        my_node_name = None
        
        for child in children:
            child_path = f"{self.lock_path}/{child}"
            node = self.coordination_service.get_znode(child_path)
            if node and node.session_id == self.session_id:
                if child.startswith("lock-") and node.data == self.session_id.encode():
                    my_node_name = child
                    self.my_lock_node = child_path
                    break
        
        if not my_node_name:
            return False
        
        # Check if we have the lock
        while time.time() - start_time < timeout:
            children = self.coordination_service.get_children(self.lock_path)
            lock_children = [c for c in children if c.startswith("lock-")]
            lock_children.sort()
            
            if lock_children and lock_children[0] == my_node_name:
                # We have the lock!
                self.acquired = True
                print(f"Acquired lock {self.lock_path} with node {my_node_name}")
                return True
            
            # Wait for predecessor to be deleted
            my_index = lock_children.index(my_node_name)
            if my_index > 0:
                predecessor = lock_children[my_index - 1]
                predecessor_path = f"{self.lock_path}/{predecessor}"
                
                # Watch predecessor
                while self.coordination_service.exists(predecessor_path):
                    time.sleep(0.1)
                    if time.time() - start_time >= timeout:
                        break
            
            time.sleep(0.1)
        
        # Timeout - clean up our node
        if self.my_lock_node:
            self.coordination_service.delete_znode(self.my_lock_node)
        
        return False
    
    def release(self):
        """Release distributed lock"""
        
        if self.acquired and self.my_lock_node:
            success = self.coordination_service.delete_znode(self.my_lock_node)
            if success:
                self.acquired = False
                print(f"Released lock {self.lock_path}")
                return True
        
        return False
    
    def __enter__(self):
        """Context manager entry"""
        if not self.acquire():
            raise Exception(f"Failed to acquire lock {self.lock_path}")
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.release()

# Leader Election Implementation
class LeaderElection:
    def __init__(self, coordination_service: CoordinationService, election_path: str, 
                 node_id: str, session_id: str):
        self.coordination_service = coordination_service
        self.election_path = election_path
        self.node_id = node_id
        self.session_id = session_id
        self.my_election_node = None
        self.is_leader = False
        self.leader_callbacks: List[Callable] = []
        self.follower_callbacks: List[Callable] = []
    
    def join_election(self) -> bool:
        """Join leader election"""
        
        # Create election path if it doesn't exist
        if not self.coordination_service.exists(self.election_path):
            self.coordination_service.create_znode(self.election_path, node_type=ZNodeType.PERSISTENT)
        
        # Create ephemeral sequential node
        election_node_path = f"{self.election_path}/election-"
        
        success = self.coordination_service.create_znode(
            election_node_path,
            data=self.node_id.encode(),
            node_type=ZNodeType.EPHEMERAL_SEQUENTIAL,
            session_id=self.session_id
        )
        
        if not success:
            return False
        
        # Find our actual node path
        children = self.coordination_service.get_children(self.election_path)
        
        for child in children:
            child_path = f"{self.election_path}/{child}"
            node = self.coordination_service.get_znode(child_path)
            if node and node.session_id == self.session_id:
                if child.startswith("election-") and node.data == self.node_id.encode():
                    self.my_election_node = child_path
                    break
        
        if self.my_election_node:
            self._check_leadership()
            return True
        
        return False
    
    def _check_leadership(self):
        """Check if we are the leader"""
        
        children = self.coordination_service.get_children(self.election_path)
        election_children = [c for c in children if c.startswith("election-")]
        election_children.sort()
        
        if not election_children:
            return
        
        my_node_name = self.my_election_node.split("/")[-1]
        
        if election_children[0] == my_node_name:
            if not self.is_leader:
                self.is_leader = True
                print(f"Node {self.node_id} became leader")
                
                # Notify leader callbacks
                for callback in self.leader_callbacks:
                    try:
                        callback()
                    except Exception as e:
                        print(f"Leader callback error: {e}")
        else:
            if self.is_leader:
                self.is_leader = False
                print(f"Node {self.node_id} is no longer leader")
                
                # Notify follower callbacks
                for callback in self.follower_callbacks:
                    try:
                        callback()
                    except Exception as e:
                        print(f"Follower callback error: {e}")
    
    def add_leader_callback(self, callback: Callable):
        """Add callback for when becoming leader"""
        self.leader_callbacks.append(callback)
    
    def add_follower_callback(self, callback: Callable):
        """Add callback for when becoming follower"""
        self.follower_callbacks.append(callback)
    
    def leave_election(self):
        """Leave leader election"""
        
        if self.my_election_node:
            self.coordination_service.delete_znode(self.my_election_node)
            self.my_election_node = None
            self.is_leader = False

# Configuration Management
class ConfigurationManager:
    def __init__(self, coordination_service: CoordinationService, config_path: str):
        self.coordination_service = coordination_service
        self.config_path = config_path
        self.config_cache = {}
        self.config_watchers = {}
        
        # Create config path if it doesn't exist
        if not self.coordination_service.exists(self.config_path):
            self.coordination_service.create_znode(self.config_path, node_type=ZNodeType.PERSISTENT)
    
    def set_config(self, key: str, value: Any) -> bool:
        """Set configuration value"""
        
        config_node_path = f"{self.config_path}/{key}"
        config_data = json.dumps(value).encode()
        
        if self.coordination_service.exists(config_node_path):
            return self.coordination_service.set_data(config_node_path, config_data)
        else:
            return self.coordination_service.create_znode(
                config_node_path,
                data=config_data,
                node_type=ZNodeType.PERSISTENT
            )
    
    def get_config(self, key: str, default: Any = None, watch: bool = False) -> Any:
        """Get configuration value"""
        
        config_node_path = f"{self.config_path}/{key}"
        
        if watch:
            # Set up watcher (simplified)
            self.config_watchers[key] = True
        
        node = self.coordination_service.get_znode(config_node_path)
        
        if node:
            try:
                return json.loads(node.data.decode())
            except json.JSONDecodeError:
                return default
        
        return default
    
    def get_all_config(self) -> Dict[str, Any]:
        """Get all configuration values"""
        
        config = {}
        children = self.coordination_service.get_children(self.config_path)
        
        for child in children:
            child_path = f"{self.config_path}/{child}"
            node = self.coordination_service.get_znode(child_path)
            
            if node:
                try:
                    config[child] = json.loads(node.data.decode())
                except json.JSONDecodeError:
                    config[child] = None
        
        return config
    
    def delete_config(self, key: str) -> bool:
        """Delete configuration value"""
        
        config_node_path = f"{self.config_path}/{key}"
        return self.coordination_service.delete_znode(config_node_path)

# Example usage and testing
print("=== Distributed Coordination Service Demo ===")

# Create coordination service cluster
cluster_nodes = ["node1", "node2", "node3"]
coord_service = CoordinationService("node1", cluster_nodes)
coord_service.start()

# Create client session
session_id = coord_service.create_session("client1")

# Test basic ZNode operations
print("\n--- Basic ZNode Operations ---")
coord_service.create_znode("/apps", node_type=ZNodeType.PERSISTENT)
coord_service.create_znode("/apps/myapp", data=b"app config", node_type=ZNodeType.PERSISTENT)
coord_service.create_znode("/locks", node_type=ZNodeType.PERSISTENT)

# Test distributed lock
print("\n--- Distributed Lock Test ---")
lock = DistributedLock(coord_service, "/locks/resource1", session_id)

try:
    with lock:
        print("Critical section - performing exclusive operation")
        time.sleep(1)
        print("Exclusive operation completed")
except Exception as e:
    print(f"Lock acquisition failed: {e}")

# Test leader election
print("\n--- Leader Election Test ---")
election = LeaderElection(coord_service, "/election/service1", "node1", session_id)

def on_become_leader():
    print("Callback: I am now the leader!")

def on_become_follower():
    print("Callback: I am now a follower!")

election.add_leader_callback(on_become_leader)
election.add_follower_callback(on_become_follower)

election.join_election()

# Test configuration management
print("\n--- Configuration Management Test ---")
config_manager = ConfigurationManager(coord_service, "/config/myapp")

# Set configuration
config_manager.set_config("database_url", "postgresql://localhost:5432/mydb")
config_manager.set_config("cache_ttl", 300)
config_manager.set_config("feature_flags", {"new_ui": True, "beta_features": False})

# Get configuration
db_url = config_manager.get_config("database_url")
cache_ttl = config_manager.get_config("cache_ttl", 60)
feature_flags = config_manager.get_config("feature_flags", {})

print(f"Database URL: {db_url}")
print(f"Cache TTL: {cache_ttl}")
print(f"Feature flags: {feature_flags}")

# Get all configuration
all_config = config_manager.get_all_config()
print(f"All configuration: {all_config}")

# Check cluster status
status = coord_service.get_cluster_status()
print(f"\n--- Cluster Status ---")
print(f"Node: {status['node_id']}")
print(f"State: {status['state']}")
print(f"Leader: {status['leader_id']}")
print(f"Total ZNodes: {status['total_znodes']}")
print(f"Active sessions: {status['active_sessions']}")

# Wait a bit then clean up
time.sleep(2)
coord_service.stop()
```

## 📊 Advanced Coordination Patterns

```python
class ServiceRegistry:
    """Service discovery and registry using coordination service"""
    
    def __init__(self, coordination_service: CoordinationService, registry_path: str = "/services"):
        self.coordination_service = coordination_service
        self.registry_path = registry_path
        self.registered_services = {}
        
        # Create registry path
        if not self.coordination_service.exists(self.registry_path):
            self.coordination_service.create_znode(self.registry_path, node_type=ZNodeType.PERSISTENT)
    
    def register_service(self, service_name: str, host: str, port: int, 
                        metadata: Dict[str, Any] = None, session_id: str = None) -> bool:
        """Register a service instance"""
        
        service_path = f"{self.registry_path}/{service_name}"
        
        # Create service path if it doesn't exist
        if not self.coordination_service.exists(service_path):
            self.coordination_service.create_znode(service_path, node_type=ZNodeType.PERSISTENT)
        
        # Create service instance node (ephemeral sequential)
        instance_data = {
            'host': host,
            'port': port,
            'registered_at': time.time(),
            'metadata': metadata or {}
        }
        
        instance_path = f"{service_path}/instance-"
        
        success = self.coordination_service.create_znode(
            instance_path,
            data=json.dumps(instance_data).encode(),
            node_type=ZNodeType.EPHEMERAL_SEQUENTIAL,
            session_id=session_id
        )
        
        if success:
            print(f"Registered service {service_name} at {host}:{port}")
            self.registered_services[f"{service_name}:{host}:{port}"] = instance_path
        
        return success
    
    def discover_services(self, service_name: str) -> List[Dict[str, Any]]:
        """Discover all instances of a service"""
        
        service_path = f"{self.registry_path}/{service_name}"
        
        if not self.coordination_service.exists(service_path):
            return []
        
        instances = []
        children = self.coordination_service.get_children(service_path)
        
        for child in children:
            if child.startswith("instance-"):
                child_path = f"{service_path}/{child}"
                node = self.coordination_service.get_znode(child_path)
                
                if node:
                    try:
                        instance_data = json.loads(node.data.decode())
                        instances.append(instance_data)
                    except json.JSONDecodeError:
                        continue
        
        return instances
    
    def get_service_instance(self, service_name: str, strategy: str = "round_robin") -> Optional[Dict[str, Any]]:
        """Get a single service instance using load balancing strategy"""
        
        instances = self.discover_services(service_name)
        
        if not instances:
            return None
        
        if strategy == "round_robin":
            # Simple round-robin (in production, maintain state)
            return instances[int(time.time()) % len(instances)]
        elif strategy == "random":
            return random.choice(instances)
        elif strategy == "least_connections":
            # Simplified - would need connection tracking
            return min(instances, key=lambda x: x.get('connections', 0))
        else:
            return instances[0]
    
    def unregister_service(self, service_name: str, host: str, port: int) -> bool:
        """Unregister a service instance"""
        
        service_key = f"{service_name}:{host}:{port}"
        
        if service_key in self.registered_services:
            instance_path = self.registered_services[service_key]
            success = self.coordination_service.delete_znode(instance_path)
            
            if success:
                del self.registered_services[service_key]
                print(f"Unregistered service {service_name} at {host}:{port}")
            
            return success
        
        return False
    
    def watch_service(self, service_name: str, callback: Callable[[List[Dict[str, Any]]], None]):
        """Watch for changes in service instances"""
        
        service_path = f"{self.registry_path}/{service_name}"
        
        # In a real implementation, this would set up proper watchers
        # For now, we'll simulate periodic checking
        def watch_loop():
            last_instances = []
            
            while True:
                current_instances = self.discover_services(service_name)
                
                if current_instances != last_instances:
                    try:
                        callback(current_instances)
                    except Exception as e:
                        print(f"Service watch callback error: {e}")
                    
                    last_instances = current_instances
                
                time.sleep(5)  # Check every 5 seconds
        
        watch_thread = threading.Thread(target=watch_loop)
        watch_thread.daemon = True
        watch_thread.start()

class DistributedBarrier:
    """Distributed barrier for synchronizing multiple processes"""
    
    def __init__(self, coordination_service: CoordinationService, barrier_path: str, 
                 num_participants: int, session_id: str):
        self.coordination_service = coordination_service
        self.barrier_path = barrier_path
        self.num_participants = num_participants
        self.session_id = session_id
        self.my_barrier_node = None
        
        # Create barrier path
        if not self.coordination_service.exists(self.barrier_path):
            self.coordination_service.create_znode(self.barrier_path, node_type=ZNodeType.PERSISTENT)
    
    def enter_barrier(self, participant_id: str, timeout: float = 30.0) -> bool:
        """Enter the barrier and wait for all participants"""
        
        start_time = time.time()
        
        # Create participant node
        participant_path = f"{self.barrier_path}/participant-"
        
        success = self.coordination_service.create_znode(
            participant_path,
            data=participant_id.encode(),
            node_type=ZNodeType.EPHEMERAL_SEQUENTIAL,
            session_id=self.session_id
        )
        
        if not success:
            return False
        
        # Find our node
        children = self.coordination_service.get_children(self.barrier_path)
        
        for child in children:
            child_path = f"{self.barrier_path}/{child}"
            node = self.coordination_service.get_znode(child_path)
            if node and node.session_id == self.session_id and node.data == participant_id.encode():
                self.my_barrier_node = child_path
                break
        
        print(f"Participant {participant_id} entered barrier")
        
        # Wait for all participants
        while time.time() - start_time < timeout:
            children = self.coordination_service.get_children(self.barrier_path)
            participant_children = [c for c in children if c.startswith("participant-")]
            
            if len(participant_children) >= self.num_participants:
                print(f"Barrier released - all {self.num_participants} participants ready")
                return True
            
            print(f"Waiting for participants: {len(participant_children)}/{self.num_participants}")
            time.sleep(1)
        
        # Timeout - clean up our node
        if self.my_barrier_node:
            self.coordination_service.delete_znode(self.my_barrier_node)
        
        print(f"Barrier timeout for participant {participant_id}")
        return False
    
    def leave_barrier(self):
        """Leave the barrier"""
        
        if self.my_barrier_node:
            self.coordination_service.delete_znode(self.my_barrier_node)
            self.my_barrier_node = None

class DistributedQueue:
    """Distributed queue implementation using coordination service"""
    
    def __init__(self, coordination_service: CoordinationService, queue_path: str):
        self.coordination_service = coordination_service
        self.queue_path = queue_path
        
        # Create queue path
        if not self.coordination_service.exists(self.queue_path):
            self.coordination_service.create_znode(self.queue_path, node_type=ZNodeType.PERSISTENT)
    
    def enqueue(self, data: bytes) -> bool:
        """Add item to queue"""
        
        item_path = f"{self.queue_path}/item-"
        
        return self.coordination_service.create_znode(
            item_path,
            data=data,
            node_type=ZNodeType.PERSISTENT_SEQUENTIAL
        )
    
    def dequeue(self, timeout: float = 10.0) -> Optional[bytes]:
        """Remove and return item from queue"""
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            children = self.coordination_service.get_children(self.queue_path)
            item_children = [c for c in children if c.startswith("item-")]
            
            if not item_children:
                time.sleep(0.1)
                continue
            
            # Get oldest item (lowest sequence number)
            item_children.sort()
            oldest_item = item_children[0]
            oldest_path = f"{self.queue_path}/{oldest_item}"
            
            # Get item data
            node = self.coordination_service.get_znode(oldest_path)
            if not node:
                continue
            
            item_data = node.data
            
            # Delete item
            if self.coordination_service.delete_znode(oldest_path):
                return item_data
        
        return None
    
    def size(self) -> int:
        """Get queue size"""
        
        children = self.coordination_service.get_children(self.queue_path)
        item_children = [c for c in children if c.startswith("item-")]
        
        return len(item_children)
    
    def peek(self) -> Optional[bytes]:
        """Peek at next item without removing it"""
        
        children = self.coordination_service.get_children(self.queue_path)
        item_children = [c for c in children if c.startswith("item-")]
        
        if not item_children:
            return None
        
        # Get oldest item
        item_children.sort()
        oldest_item = item_children[0]
        oldest_path = f"{self.queue_path}/{oldest_item}"
        
        node = self.coordination_service.get_znode(oldest_path)
        return node.data if node else None

# Example usage of advanced patterns
print("\n=== Advanced Coordination Patterns Demo ===")

# Service Registry
service_registry = ServiceRegistry(coord_service)

# Register services
session_id2 = coord_service.create_session("service_provider")
service_registry.register_service("web-api", "192.168.1.10", 8080, 
                                 {"version": "1.0", "region": "us-east"}, session_id2)
service_registry.register_service("web-api", "192.168.1.11", 8080, 
                                 {"version": "1.0", "region": "us-east"}, session_id2)
service_registry.register_service("database", "192.168.1.20", 5432, 
                                 {"type": "postgresql", "primary": True}, session_id2)

# Discover services
web_api_instances = service_registry.discover_services("web-api")
print(f"Discovered {len(web_api_instances)} web-api instances")

# Get specific instance
instance = service_registry.get_service_instance("web-api", "round_robin")
if instance:
    print(f"Selected instance: {instance['host']}:{instance['port']}")

# Distributed Barrier
print("\n--- Distributed Barrier Test ---")
barrier = DistributedBarrier(coord_service, "/barriers/sync_point", 3, session_id)

def simulate_participant(participant_id: str):
    """Simulate a participant joining the barrier"""
    participant_session = coord_service.create_session(f"participant_{participant_id}")
    participant_barrier = DistributedBarrier(coord_service, "/barriers/sync_point", 3, participant_session)
    
    print(f"Participant {participant_id} starting work...")
    time.sleep(random.uniform(1, 3))  # Simulate work
    
    success = participant_barrier.enter_barrier(participant_id, timeout=10)
    if success:
        print(f"Participant {participant_id} passed barrier - continuing work")
    else:
        print(f"Participant {participant_id} timed out at barrier")

# Start participant threads
participants = []
for i in range(3):
    p = threading.Thread(target=simulate_participant, args=[f"worker_{i}"])
    p.daemon = True
    p.start()
    participants.append(p)

# Wait for participants
for p in participants:
    p.join()

# Distributed Queue
print("\n--- Distributed Queue Test ---")
queue = DistributedQueue(coord_service, "/queues/task_queue")

# Enqueue items
for i in range(5):
    queue.enqueue(f"task_{i}".encode())

print(f"Queue size: {queue.size()}")

# Peek at next item
next_item = queue.peek()
print(f"Next item: {next_item.decode() if next_item else 'None'}")

# Dequeue items
while queue.size() > 0:
    item = queue.dequeue()
    if item:
        print(f"Dequeued: {item.decode()}")

print(f"Final queue size: {queue.size()}")

time.sleep(1)
print("\n--- Demo completed ---")
```

## 📚 Conclusion

Distributed coordination services are the foundation that enables complex distributed systems to work together harmoniously. From simple distributed locks to sophisticated leader election and service discovery, these services provide the essential primitives that make distributed computing possible.

**Key Takeaways:**

1. **Consensus is Critical**: Reliable coordination requires strong consistency guarantees
2. **Handle Network Partitions**: Design for scenarios where nodes cannot communicate
3. **Session Management**: Properly handle client sessions and ephemeral resources
4. **Performance vs Consistency**: Balance strong consistency with system performance
5. **Operational Simplicity**: Keep coordination logic as simple and reliable as possible

The future of distributed coordination includes integration with service meshes, cloud-native orchestration platforms, and edge computing environments. Whether you're building microservices, distributed databases, or large-scale data processing systems, understanding coordination patterns is essential for creating reliable, scalable distributed applications.

Remember: coordination services are often the most critical component in a distributed system—they must be rock-solid reliable because everything else depends on them working correctly.
