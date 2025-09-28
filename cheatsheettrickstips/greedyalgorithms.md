# Greedy Algorithms - Comprehensive Cheatsheet

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

### What are Greedy Algorithms?

A greedy algorithm makes the locally optimal choice at each stage, hoping to find a global optimum. Unlike dynamic programming, greedy algorithms never reconsider their choices. Think of making change with coins - always pick the largest denomination possible.

**Key Characteristics:**
- **Local Optimization**: Best immediate choice
- **Irrevocable Decisions**: No backtracking
- **Efficient**: Usually O(n log n) or better
- **Simple**: Straightforward implementation
- **Not Always Optimal**: May miss global optimum

### Real-World Examples
1. **Making Change**: Use largest coins first
2. **Traffic Routes**: Take fastest immediate path
3. **Packing**: Put most valuable items first
4. **Eating**: Consume favorites first

### When Greedy Works
**Required Properties:**
1. **Greedy Choice Property**: Local optimum leads to global optimum
2. **Optimal Substructure**: Optimal solutions contain optimal subproblems

**Works Well For:**
- Activity selection
- Fractional knapsack
- Minimum spanning tree
- Shortest path (Dijkstra)

**Fails For:**
- 0/1 Knapsack
- Longest path
- Traveling salesman

---

## Key Properties & Rules

### Fundamental Properties

#### 1. **Greedy Choice Property**
Making locally optimal choice leads to globally optimal solution.

**Proof Technique - Exchange Argument:**
1. Assume optimal solution differs from greedy
2. Show we can exchange choices without worsening solution
3. Conclude greedy is optimal

#### 2. **Optimal Substructure**
After greedy choice, remaining problem has same structure.

### Algorithm Framework
```python
def greedy_algorithm(candidates):
    solution = []
    candidates = sort_by_criterion(candidates)
    
    for candidate in candidates:
        if is_feasible(solution, candidate):
            solution.append(candidate)
    
    return solution
```

---

## Patterns & Use Cases

### Core Patterns

#### 1. **Activity Selection Pattern**
**When:** Scheduling non-overlapping activities
**Greedy Choice:** Earliest finish time

```python
def activity_selection(activities):
    activities.sort(key=lambda x: x.finish_time)
    
    selected = [activities[0]]
    last_finish = activities[0].finish_time
    
    for activity in activities[1:]:
        if activity.start_time >= last_finish:
            selected.append(activity)
            last_finish = activity.finish_time
    
    return selected
```

#### 2. **Minimum Spanning Tree Pattern**
**When:** Connecting components with minimum cost

**Kruskal's Algorithm:**
```python
def kruskal_mst(edges, num_vertices):
    edges.sort(key=lambda x: x.weight)
    parent = list(range(num_vertices))
    
    def find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]
    
    def union(x, y):
        parent[find(x)] = find(y)
    
    mst = []
    for u, v, weight in edges:
        if find(u) != find(v):
            union(u, v)
            mst.append((u, v, weight))
    
    return mst
```

#### 3. **Fractional Knapsack Pattern**
**When:** Maximizing value with divisible items
**Greedy Choice:** Highest value-to-weight ratio

```python
def fractional_knapsack(items, capacity):
    items.sort(key=lambda x: x.value / x.weight, reverse=True)
    
    total_value = 0
    for item in items:
        if capacity >= item.weight:
            total_value += item.value
            capacity -= item.weight
        else:
            total_value += item.value * (capacity / item.weight)
            break
    
    return total_value
```

#### 4. **Shortest Path Pattern**
**When:** Single-source shortest paths (non-negative weights)

**Dijkstra's Algorithm:**
```python
def dijkstra(graph, source):
    distances = {v: float('inf') for v in graph}
    distances[source] = 0
    
    unvisited = set(graph.vertices)
    
    while unvisited:
        current = min(unvisited, key=lambda v: distances[v])
        unvisited.remove(current)
        
        for neighbor, weight in graph.neighbors(current):
            distance = distances[current] + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
    
    return distances
```

#### 5. **Huffman Coding Pattern**
**When:** Optimal prefix-free encoding

```python
import heapq

def huffman_coding(frequencies):
    heap = [[freq, char] for char, freq in frequencies.items()]
    heapq.heapify(heap)
    
    while len(heap) > 1:
        lo = heapq.heappop(heap)
        hi = heapq.heappop(heap)
        
        merged = [lo[0] + hi[0], lo[1:], hi[1:]]
        heapq.heappush(heap, merged)
    
    return heap[0]
```

---

## Step-by-Step Approaches

### General Framework

#### Step 1: **Identify Greedy Choice**
- Earliest deadline first
- Highest value density
- Minimum cost first
- Shortest processing time

#### Step 2: **Prove Correctness**
Use exchange argument:
1. Assume optimal differs from greedy
2. Show exchange doesn't worsen solution
3. Conclude greedy is optimal

#### Step 3: **Implement Algorithm**
```python
def greedy_template(input_data):
    # Sort by greedy criterion
    candidates = sorted(input_data, key=greedy_criterion)
    
    solution = []
    for candidate in candidates:
        if is_feasible(solution, candidate):
            solution.append(candidate)
    
    return solution
```

---

## Common Algorithms

### 1. **Activity Selection**
**Problem:** Maximum non-overlapping activities

```python
def max_activities(intervals):
    intervals.sort(key=lambda x: x[1])  # Sort by end time
    
    count = 1
    last_end = intervals[0][1]
    
    for start, end in intervals[1:]:
        if start >= last_end:
            count += 1
            last_end = end
    
    return count
```

### 2. **Gas Station**
**Problem:** Can complete circular route?

```python
def can_complete_circuit(gas, cost):
    total_tank = 0
    current_tank = 0
    start_station = 0
    
    for i in range(len(gas)):
        total_tank += gas[i] - cost[i]
        current_tank += gas[i] - cost[i]
        
        if current_tank < 0:
            start_station = i + 1
            current_tank = 0
    
    return start_station if total_tank >= 0 else -1
```

### 3. **Jump Game**
**Problem:** Can reach end of array?

```python
def can_jump(nums):
    max_reach = 0
    
    for i in range(len(nums)):
        if i > max_reach:
            return False
        max_reach = max(max_reach, i + nums[i])
        if max_reach >= len(nums) - 1:
            return True
    
    return True
```

### 4. **Meeting Rooms II**
**Problem:** Minimum meeting rooms needed

```python
def min_meeting_rooms(intervals):
    events = []
    for start, end in intervals:
        events.append((start, 1))    # Meeting starts
        events.append((end, -1))     # Meeting ends
    
    events.sort()
    
    concurrent = 0
    max_rooms = 0
    
    for time, event in events:
        concurrent += event
        max_rooms = max(max_rooms, concurrent)
    
    return max_rooms
```

### 5. **Task Scheduler**
**Problem:** Minimum time to complete tasks with cooldown

```python
def least_interval(tasks, n):
    from collections import Counter
    import heapq
    
    counts = Counter(tasks)
    max_heap = [-count for count in counts.values()]
    heapq.heapify(max_heap)
    
    time = 0
    
    while max_heap:
        temp = []
        for _ in range(n + 1):
            if max_heap:
                count = heapq.heappop(max_heap)
                if count < -1:
                    temp.append(count + 1)
            time += 1
            
            if not max_heap and not temp:
                break
        
        for count in temp:
            heapq.heappush(max_heap, count)
    
    return time
```

---

## Complexity Analysis

### Time Complexity Patterns

**Sorting-Based:** O(n log n)
- Activity selection
- Fractional knapsack
- Job scheduling

**Heap-Based:** O(n log n) to O(E log V)
- Dijkstra's algorithm
- Prim's MST
- Huffman coding

**Linear:** O(n)
- Gas station
- Jump game
- Some interval problems

### Space Complexity
- **Input Storage:** O(n)
- **Auxiliary Structures:** O(n) for heaps, O(V) for graphs
- **Solution Storage:** Problem-dependent

---

## Example Problems

### Problem 1: **Container With Most Water**
```python
def max_area(height):
    left, right = 0, len(height) - 1
    max_water = 0
    
    while left < right:
        width = right - left
        max_water = max(max_water, min(height[left], height[right]) * width)
        
        if height[left] < height[right]:
            left += 1
        else:
            right -= 1
    
    return max_water
```

### Problem 2: **Minimum Number of Arrows**
```python
def find_min_arrows(points):
    if not points:
        return 0
    
    points.sort(key=lambda x: x[1])  # Sort by end position
    
    arrows = 1
    end = points[0][1]
    
    for start, finish in points[1:]:
        if start > end:
            arrows += 1
            end = finish
    
    return arrows
```

### Problem 3: **Partition Labels**
```python
def partition_labels(s):
    last_occurrence = {char: i for i, char in enumerate(s)}
    
    partitions = []
    start = 0
    end = 0
    
    for i, char in enumerate(s):
        end = max(end, last_occurrence[char])
        
        if i == end:
            partitions.append(i - start + 1)
            start = i + 1
    
    return partitions
```

---

## Problem Categories

### 1. **Scheduling Problems**
- Activity selection
- Job scheduling with deadlines
- Meeting room allocation
- Interval scheduling

### 2. **Graph Problems**
- Minimum spanning tree
- Shortest path algorithms
- Graph traversal optimization

### 3. **Array/String Problems**
- Jump games
- Container problems
- Partitioning problems

### 4. **Resource Allocation**
- Knapsack variants
- Load balancing
- Task assignment

---

## Edge Cases

### Common Edge Cases
1. **Empty Input:** Handle empty arrays/lists
2. **Single Element:** Ensure algorithm works with one item
3. **All Equal:** When elements have same priority
4. **Impossible Solutions:** When no valid solution exists
5. **Tie Breaking:** Multiple choices with same value

### Robust Implementation
```python
def robust_greedy(items):
    if not items:
        return []
    
    if len(items) == 1:
        return items if is_valid(items[0]) else []
    
    # Handle ties with secondary criterion
    items.sort(key=lambda x: (primary_key(x), secondary_key(x)))
    
    return greedy_selection(items)
```

---

## Pro Tips & Interview Tricks

### Recognition Patterns

#### When to Use Greedy:
1. **Keywords:** "minimum", "maximum", "optimal"
2. **Local Decisions:** Choice can be made with current info
3. **No Backtracking:** Don't need to reconsider choices
4. **Sorting Helps:** Problem becomes clearer after sorting

### Common Greedy Choices
- **Earliest deadline first:** Scheduling problems
- **Shortest job first:** Minimizing wait time
- **Highest value density:** Packing problems
- **Minimum cost first:** Network problems

### Proof Strategies

#### Exchange Argument Template:
```
1. Assume optimal solution O differs from greedy G
2. Find first difference between O and G
3. Show exchanging O's choice with G's doesn't worsen solution
4. Conclude greedy is optimal
```

### Implementation Template
```python
def greedy_solve(problem_input):
    # Step 1: Sort by greedy criterion
    candidates = sorted(problem_input, key=greedy_criterion)
    
    # Step 2: Initialize solution
    solution = []
    
    # Step 3: Greedy selection
    for candidate in candidates:
        if is_feasible(solution, candidate):
            solution.append(candidate)
    
    return solution
```

### Common Mistakes
1. **Wrong criterion:** Incorrect greedy choice
2. **Missing constraints:** Not enforcing requirements
3. **No proof:** Assuming greedy works without verification
4. **Complexity errors:** Forgetting sorting costs

### Interview Success Tips
1. **Start simple:** Basic greedy approach first
2. **Identify pattern:** Recognize problem type
3. **Justify choice:** Explain greedy criterion
4. **Prove correctness:** Use exchange arguments
5. **Analyze complexity:** Include all operation costs
6. **Handle edge cases:** Test boundary conditions

Greedy algorithms are powerful for optimization problems with the right structure. Master the patterns, understand the proofs, and practice recognizing when greedy approaches apply!