# Graph Algorithms - Comprehensive Cheatsheet

## Table of Contents
1. [Definition & Intuition](#definition--intuition)
2. [Key Properties & Rules](#key-properties--rules)
3. [Patterns & Use Cases](#patterns--use-cases)
4. [Step-by-Step Approaches](#step-by-step-approaches)
5. [Common Algorithms](#common-algorithms)
6. [Edge Cases](#edge-cases)
7. [Complexity Analysis](#complexity-analysis)
8. [Example Problems](#example-problems)
9. [Problem Categories](#problem-categories)
10. [Pro Tips & Interview Tricks](#pro-tips--interview-tricks)

---

## Definition & Intuition

### What is a Graph?

A graph is a fundamental data structure consisting of vertices (nodes) connected by edges. Think of a graph as a network of relationships - social networks, road systems, computer networks, or any system where entities are connected.

**Mathematical Definition**: G = (V, E) where:
- V = Set of vertices (nodes)
- E = Set of edges (connections)

### Graph Types

#### Directed vs Undirected
- **Directed**: Edges have direction (one-way streets)
- **Undirected**: Edges are bidirectional (two-way streets)

#### Weighted vs Unweighted
- **Weighted**: Edges have associated costs/weights
- **Unweighted**: All edges have equal weight (usually 1)

#### Special Graph Types
- **Tree**: Connected acyclic graph (n-1 edges for n vertices)
- **DAG**: Directed Acyclic Graph
- **Complete**: Every vertex connected to every other vertex
- **Bipartite**: Vertices can be divided into two disjoint sets

### Graph Representations

#### 1. Adjacency Matrix
```python
# n x n matrix where matrix[i][j] = 1 if edge exists
graph = [[0, 1, 1, 0],
         [1, 0, 1, 1],
         [1, 1, 0, 1],
         [0, 1, 1, 0]]
```
**Pros**: O(1) edge lookup, simple implementation
**Cons**: O(V²) space, inefficient for sparse graphs

#### 2. Adjacency List
```python
# Dictionary/Array of lists
graph = {
    0: [1, 2],
    1: [0, 2, 3],
    2: [0, 1, 3],
    3: [1, 2]
}
```
**Pros**: O(V + E) space, efficient for sparse graphs
**Cons**: O(V) edge lookup in worst case

#### 3. Edge List
```python
# List of tuples representing edges
edges = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3)]
```
**Pros**: Simple, good for algorithms like Kruskal's
**Cons**: Inefficient for most graph operations

---

## Key Properties & Rules

### Graph Properties

#### Connectivity
- **Connected**: Path exists between every pair of vertices
- **Strongly Connected**: (Directed) Path exists in both directions
- **Weakly Connected**: (Directed) Connected when treating as undirected

#### Cycles
- **Acyclic**: No cycles exist
- **Tree**: Connected and acyclic
- **Forest**: Collection of trees

#### Degree
- **Degree**: Number of edges incident to a vertex
- **In-degree**: Number of incoming edges (directed)
- **Out-degree**: Number of outgoing edges (directed)

### Fundamental Theorems

#### Handshaking Lemma
Sum of all vertex degrees = 2 × number of edges

#### Tree Properties
- n vertices, n-1 edges
- Exactly one path between any two vertices
- Adding any edge creates exactly one cycle
- Removing any edge disconnects the graph

---

## Patterns & Use Cases

### Core Graph Algorithms

#### 1. Graph Traversal
**DFS (Depth-First Search)**
- **Use Cases**: Cycle detection, topological sort, connected components
- **Implementation**: Stack (iterative) or recursion
- **Time**: O(V + E), **Space**: O(V)

**BFS (Breadth-First Search)**
- **Use Cases**: Shortest path (unweighted), level-order traversal
- **Implementation**: Queue
- **Time**: O(V + E), **Space**: O(V)

#### 2. Shortest Path Algorithms
**Dijkstra's Algorithm**
- **Use Cases**: Single-source shortest path (non-negative weights)
- **Time**: O((V + E) log V), **Space**: O(V)

**Bellman-Ford Algorithm**
- **Use Cases**: Single-source shortest path (with negative weights)
- **Time**: O(VE), **Space**: O(V)

**Floyd-Warshall Algorithm**
- **Use Cases**: All-pairs shortest path
- **Time**: O(V³), **Space**: O(V²)

#### 3. Minimum Spanning Tree
**Kruskal's Algorithm**
- **Use Cases**: MST using edge sorting
- **Time**: O(E log E), **Space**: O(V)

**Prim's Algorithm**
- **Use Cases**: MST using vertex growing
- **Time**: O((V + E) log V), **Space**: O(V)

---

## Step-by-Step Approaches

### Graph Problem-Solving Framework

1. **Understand the Problem**:
   - What type of graph (directed/undirected, weighted/unweighted)?
   - What are we trying to find (path, cycle, connectivity)?

2. **Choose Representation**:
   - Adjacency list for sparse graphs
   - Adjacency matrix for dense graphs

3. **Select Algorithm**:
   - Traversal problems → DFS/BFS
   - Shortest path → Dijkstra/Bellman-Ford
   - Connectivity → Union-Find

4. **Handle Edge Cases**:
   - Empty graph
   - Single vertex
   - Disconnected components

---

## Common Algorithms

### 1. Depth-First Search (DFS)
```python
def dfs_recursive(graph, start, visited=None):
    if visited is None:
        visited = set()
    
    visited.add(start)
    print(start)  # Process vertex
    
    for neighbor in graph[start]:
        if neighbor not in visited:
            dfs_recursive(graph, neighbor, visited)
    
    return visited

def dfs_iterative(graph, start):
    visited = set()
    stack = [start]
    
    while stack:
        vertex = stack.pop()
        if vertex not in visited:
            visited.add(vertex)
            print(vertex)  # Process vertex
            
            # Add neighbors to stack
            for neighbor in graph[vertex]:
                if neighbor not in visited:
                    stack.append(neighbor)
    
    return visited
```

### 2. Breadth-First Search (BFS)
```python
from collections import deque

def bfs(graph, start):
    visited = set()
    queue = deque([start])
    visited.add(start)
    
    while queue:
        vertex = queue.popleft()
        print(vertex)  # Process vertex
        
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    
    return visited

def bfs_shortest_path(graph, start, end):
    if start == end:
        return [start]
    
    visited = set([start])
    queue = deque([(start, [start])])
    
    while queue:
        vertex, path = queue.popleft()
        
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                if neighbor == end:
                    return path + [neighbor]
                
                visited.add(neighbor)
                queue.append((neighbor, path + [neighbor]))
    
    return None  # No path found
```

### 3. Dijkstra's Algorithm
```python
import heapq

def dijkstra(graph, start):
    # Initialize distances
    distances = {vertex: float('infinity') for vertex in graph}
    distances[start] = 0
    
    # Priority queue: (distance, vertex)
    pq = [(0, start)]
    visited = set()
    
    while pq:
        current_distance, current_vertex = heapq.heappop(pq)
        
        if current_vertex in visited:
            continue
        
        visited.add(current_vertex)
        
        # Update neighbors
        for neighbor, weight in graph[current_vertex]:
            distance = current_distance + weight
            
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(pq, (distance, neighbor))
    
    return distances

def dijkstra_with_path(graph, start, end):
    distances = {vertex: float('infinity') for vertex in graph}
    previous = {vertex: None for vertex in graph}
    distances[start] = 0
    
    pq = [(0, start)]
    visited = set()
    
    while pq:
        current_distance, current_vertex = heapq.heappop(pq)
        
        if current_vertex in visited:
            continue
        
        if current_vertex == end:
            # Reconstruct path
            path = []
            while current_vertex is not None:
                path.append(current_vertex)
                current_vertex = previous[current_vertex]
            return path[::-1], distances[end]
        
        visited.add(current_vertex)
        
        for neighbor, weight in graph[current_vertex]:
            distance = current_distance + weight
            
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                previous[neighbor] = current_vertex
                heapq.heappush(pq, (distance, neighbor))
    
    return None, float('infinity')  # No path found
```

### 4. Topological Sort
```python
def topological_sort_dfs(graph):
    visited = set()
    rec_stack = set()
    result = []
    
    def dfs(vertex):
        if vertex in rec_stack:
            return False  # Cycle detected
        if vertex in visited:
            return True
        
        visited.add(vertex)
        rec_stack.add(vertex)
        
        for neighbor in graph[vertex]:
            if not dfs(neighbor):
                return False
        
        rec_stack.remove(vertex)
        result.append(vertex)
        return True
    
    # Try DFS from all vertices
    for vertex in graph:
        if vertex not in visited:
            if not dfs(vertex):
                return None  # Graph has cycle
    
    return result[::-1]  # Reverse to get topological order

def topological_sort_kahn(graph):
    # Calculate in-degrees
    in_degree = {vertex: 0 for vertex in graph}
    for vertex in graph:
        for neighbor in graph[vertex]:
            in_degree[neighbor] += 1
    
    # Start with vertices having no incoming edges
    queue = deque([v for v in in_degree if in_degree[v] == 0])
    result = []
    
    while queue:
        vertex = queue.popleft()
        result.append(vertex)
        
        # Remove this vertex and update in-degrees
        for neighbor in graph[vertex]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
    
    # Check if all vertices are included (no cycle)
    if len(result) != len(graph):
        return None  # Graph has cycle
    
    return result
```

### 5. Union-Find (Disjoint Set Union)
```python
class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
        self.components = n
    
    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])  # Path compression
        return self.parent[x]
    
    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        
        if px == py:
            return False  # Already in same component
        
        # Union by rank
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        
        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1
        
        self.components -= 1
        return True
    
    def connected(self, x, y):
        return self.find(x) == self.find(y)
```

### 6. Cycle Detection
```python
def has_cycle_undirected(graph):
    """Detect cycle in undirected graph using DFS"""
    visited = set()
    
    def dfs(vertex, parent):
        visited.add(vertex)
        
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                if dfs(neighbor, vertex):
                    return True
            elif neighbor != parent:
                return True  # Back edge found
        
        return False
    
    for vertex in graph:
        if vertex not in visited:
            if dfs(vertex, -1):
                return True
    
    return False

def has_cycle_directed(graph):
    """Detect cycle in directed graph using DFS"""
    WHITE, GRAY, BLACK = 0, 1, 2
    color = {vertex: WHITE for vertex in graph}
    
    def dfs(vertex):
        if color[vertex] == GRAY:
            return True  # Back edge (cycle)
        if color[vertex] == BLACK:
            return False  # Already processed
        
        color[vertex] = GRAY
        
        for neighbor in graph[vertex]:
            if dfs(neighbor):
                return True
        
        color[vertex] = BLACK
        return False
    
    for vertex in graph:
        if color[vertex] == WHITE:
            if dfs(vertex):
                return True
    
    return False
```

---

## Edge Cases

### Critical Edge Cases
1. **Empty Graph**: No vertices or edges
2. **Single Vertex**: Graph with one vertex, no edges
3. **Disconnected Graph**: Multiple components
4. **Self-loops**: Vertex connected to itself
5. **Multiple Edges**: Multiple edges between same vertices
6. **Negative Weights**: Affects shortest path algorithms

### Algorithm-Specific Edge Cases
- **DFS/BFS**: Handle disconnected components
- **Dijkstra**: Cannot handle negative weights
- **Bellman-Ford**: Detects negative cycles
- **Topological Sort**: Only works on DAGs

---

## Complexity Analysis

### Time Complexity Summary

| Algorithm | Time Complexity | Space Complexity |
|-----------|-----------------|------------------|
| DFS/BFS | O(V + E) | O(V) |
| Dijkstra | O((V + E) log V) | O(V) |
| Bellman-Ford | O(VE) | O(V) |
| Floyd-Warshall | O(V³) | O(V²) |
| Kruskal's MST | O(E log E) | O(V) |
| Prim's MST | O((V + E) log V) | O(V) |
| Union-Find | O(α(n)) amortized | O(n) |

### Space Complexity Considerations
- **Adjacency Matrix**: O(V²)
- **Adjacency List**: O(V + E)
- **Recursion Depth**: O(V) in worst case

---

## Problem Categories

### 1. **Graph Traversal**
- Number of Islands
- Clone Graph
- Word Ladder
- Surrounded Regions

### 2. **Shortest Path**
- Shortest Path in Binary Matrix
- Network Delay Time
- Cheapest Flights Within K Stops

### 3. **Topological Sort**
- Course Schedule
- Alien Dictionary
- Minimum Height Trees

### 4. **Union-Find**
- Number of Connected Components
- Redundant Connection
- Accounts Merge

### 5. **Cycle Detection**
- Detect Cycle in Directed Graph
- Find Eventual Safe States

---

## Pro Tips & Interview Tricks

### Problem Recognition Patterns
```
Connectivity Questions → DFS/BFS or Union-Find
Shortest Path → BFS (unweighted) or Dijkstra (weighted)
Cycle Detection → DFS with colors or Union-Find
Topological Order → DFS or Kahn's algorithm
Minimum Spanning Tree → Kruskal's or Prim's
```

### Implementation Tips

1. **Choose Right Representation**:
   - Sparse graphs: Adjacency list
   - Dense graphs: Adjacency matrix
   - Edge-centric algorithms: Edge list

2. **Handle Disconnected Components**:
   ```python
   visited = set()
   for vertex in graph:
       if vertex not in visited:
           dfs(vertex, visited)
   ```

3. **Avoid Infinite Loops**:
   - Always mark vertices as visited
   - Use proper cycle detection

### Common Mistakes

1. **Not handling disconnected graphs**
2. **Forgetting to mark vertices as visited**
3. **Using wrong algorithm for weighted graphs**
4. **Not considering negative weights**
5. **Mixing up directed vs undirected logic**

### Interview-Specific Strategies

1. **Clarify Graph Properties**:
   - Directed or undirected?
   - Weighted or unweighted?
   - Can have cycles?

2. **Discuss Trade-offs**:
   - Time vs space complexity
   - Different representations
   - Algorithm choices

3. **Test Edge Cases**:
   - Empty graph
   - Single vertex
   - Disconnected components

### Code Templates

#### DFS Template
```python
def dfs(graph, start, visited=None):
    if visited is None:
        visited = set()
    
    visited.add(start)
    # Process vertex
    
    for neighbor in graph[start]:
        if neighbor not in visited:
            dfs(graph, neighbor, visited)
```

#### BFS Template
```python
def bfs(graph, start):
    visited = set([start])
    queue = deque([start])
    
    while queue:
        vertex = queue.popleft()
        # Process vertex
        
        for neighbor in graph[vertex]:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
```

---

## Conclusion

Graphs are fundamental to many real-world problems - from social networks to GPS navigation. Master these key concepts:

1. **Graph Representations**: Choose the right one for your problem
2. **Traversal Algorithms**: DFS and BFS are your building blocks
3. **Shortest Path**: Dijkstra for weighted, BFS for unweighted
4. **Connectivity**: Union-Find for dynamic connectivity queries
5. **Topological Sort**: Essential for dependency resolution

**Success Formula**: Understand the problem type + Choose appropriate algorithm + Handle edge cases = Graph mastery

Practice these patterns and you'll solve most graph problems efficiently!