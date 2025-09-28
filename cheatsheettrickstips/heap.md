# Heap Data Structure - Comprehensive Cheatsheet

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

### What is a Heap?

A heap is a complete binary tree that satisfies the heap property. Think of it as a priority queue where the most important element is always at the root. It's like a company hierarchy where the CEO (highest priority) is at the top.

**Key Characteristics:**
- **Complete Binary Tree**: All levels filled except possibly the last
- **Heap Property**: Parent is always greater (max-heap) or smaller (min-heap) than children
- **Array Representation**: Efficiently stored in arrays
- **Priority Queue**: Primary use case for efficient priority operations

### Types of Heaps

#### 1. **Max Heap**
- Parent ≥ children
- Root contains maximum element
- Used for finding maximum efficiently

#### 2. **Min Heap**
- Parent ≤ children  
- Root contains minimum element
- Used for finding minimum efficiently

### Array Representation
```python
# For node at index i:
parent_index = (i - 1) // 2
left_child_index = 2 * i + 1
right_child_index = 2 * i + 2

# Example heap: [10, 8, 9, 4, 7, 5, 3, 2, 1, 6]
#       10
#      /  \
#     8    9
#    / \  / \
#   4  7 5   3
#  / \ /
# 2  1 6
```

---

## Key Properties & Rules

### Fundamental Properties

#### 1. **Heap Property**
```python
# Max Heap Property
def is_max_heap(arr):
    n = len(arr)
    for i in range((n - 2) // 2 + 1):
        left = 2 * i + 1
        right = 2 * i + 2
        
        if left < n and arr[i] < arr[left]:
            return False
        if right < n and arr[i] < arr[right]:
            return False
    return True

# Min Heap Property  
def is_min_heap(arr):
    n = len(arr)
    for i in range((n - 2) // 2 + 1):
        left = 2 * i + 1
        right = 2 * i + 2
        
        if left < n and arr[i] > arr[left]:
            return False
        if right < n and arr[i] > arr[right]:
            return False
    return True
```

#### 2. **Complete Binary Tree**
- All levels filled except possibly the last
- Last level filled left to right
- Height = O(log n)

### Core Operations

#### 1. **Heapify (Bubble Down)**
```python
def heapify_down(heap, index, heap_size, is_max_heap=True):
    largest = index
    left = 2 * index + 1
    right = 2 * index + 2
    
    # Find largest among root, left child and right child
    if is_max_heap:
        if left < heap_size and heap[left] > heap[largest]:
            largest = left
        if right < heap_size and heap[right] > heap[largest]:
            largest = right
    else:  # min heap
        if left < heap_size and heap[left] < heap[largest]:
            largest = left
        if right < heap_size and heap[right] < heap[largest]:
            largest = right
    
    # If largest is not root
    if largest != index:
        heap[index], heap[largest] = heap[largest], heap[index]
        heapify_down(heap, largest, heap_size, is_max_heap)
```

#### 2. **Heapify Up (Bubble Up)**
```python
def heapify_up(heap, index, is_max_heap=True):
    parent = (index - 1) // 2
    
    if index > 0:
        if is_max_heap and heap[index] > heap[parent]:
            heap[index], heap[parent] = heap[parent], heap[index]
            heapify_up(heap, parent, is_max_heap)
        elif not is_max_heap and heap[index] < heap[parent]:
            heap[index], heap[parent] = heap[parent], heap[index]
            heapify_up(heap, parent, is_max_heap)
```

#### 3. **Build Heap**
```python
def build_heap(arr, is_max_heap=True):
    n = len(arr)
    # Start from last non-leaf node and heapify down
    for i in range((n - 2) // 2, -1, -1):
        heapify_down(arr, i, n, is_max_heap)
    return arr
```

---

## Patterns & Use Cases

### Core Heap Patterns

#### 1. **Top K Elements Pattern**
```python
import heapq

def find_k_largest(nums, k):
    # Use min heap of size k
    heap = []
    
    for num in nums:
        if len(heap) < k:
            heapq.heappush(heap, num)
        elif num > heap[0]:
            heapq.heapreplace(heap, num)
    
    return heap

def find_k_smallest(nums, k):
    # Use max heap (negate values for Python's min heap)
    heap = []
    
    for num in nums:
        if len(heap) < k:
            heapq.heappush(heap, -num)
        elif num < -heap[0]:
            heapq.heapreplace(heap, -num)
    
    return [-x for x in heap]
```

#### 2. **Merge K Sorted Lists Pattern**
```python
def merge_k_sorted_lists(lists):
    heap = []
    result = []
    
    # Initialize heap with first element from each list
    for i, lst in enumerate(lists):
        if lst:
            heapq.heappush(heap, (lst[0], i, 0))
    
    while heap:
        val, list_idx, elem_idx = heapq.heappop(heap)
        result.append(val)
        
        # Add next element from same list
        if elem_idx + 1 < len(lists[list_idx]):
            next_val = lists[list_idx][elem_idx + 1]
            heapq.heappush(heap, (next_val, list_idx, elem_idx + 1))
    
    return result
```

#### 3. **Running Median Pattern**
```python
class MedianFinder:
    def __init__(self):
        self.max_heap = []  # For smaller half (negated values)
        self.min_heap = []  # For larger half
    
    def add_number(self, num):
        # Add to max_heap first
        heapq.heappush(self.max_heap, -num)
        
        # Balance heaps
        if (self.max_heap and self.min_heap and 
            -self.max_heap[0] > self.min_heap[0]):
            val = -heapq.heappop(self.max_heap)
            heapq.heappush(self.min_heap, val)
        
        # Maintain size property
        if len(self.max_heap) > len(self.min_heap) + 1:
            val = -heapq.heappop(self.max_heap)
            heapq.heappush(self.min_heap, val)
        elif len(self.min_heap) > len(self.max_heap) + 1:
            val = heapq.heappop(self.min_heap)
            heapq.heappush(self.max_heap, -val)
    
    def find_median(self):
        if len(self.max_heap) == len(self.min_heap):
            return (-self.max_heap[0] + self.min_heap[0]) / 2
        elif len(self.max_heap) > len(self.min_heap):
            return -self.max_heap[0]
        else:
            return self.min_heap[0]
```

#### 4. **Interval Scheduling Pattern**
```python
def merge_intervals(intervals):
    if not intervals:
        return []
    
    # Sort by start time
    intervals.sort(key=lambda x: x[0])
    merged = [intervals[0]]
    
    for current in intervals[1:]:
        last = merged[-1]
        if current[0] <= last[1]:  # Overlapping
            last[1] = max(last[1], current[1])
        else:
            merged.append(current)
    
    return merged

def min_meeting_rooms(intervals):
    if not intervals:
        return 0
    
    # Use heap to track end times
    heap = []
    intervals.sort(key=lambda x: x[0])
    
    for start, end in intervals:
        if heap and start >= heap[0]:
            heapq.heapreplace(heap, end)
        else:
            heapq.heappush(heap, end)
    
    return len(heap)
```

---

## Common Algorithms

### 1. **Heap Sort**
```python
def heap_sort(arr):
    n = len(arr)
    
    # Build max heap
    build_heap(arr, is_max_heap=True)
    
    # Extract elements one by one
    for i in range(n - 1, 0, -1):
        arr[0], arr[i] = arr[i], arr[0]
        heapify_down(arr, 0, i, is_max_heap=True)
    
    return arr
```

### 2. **Priority Queue Implementation**
```python
class PriorityQueue:
    def __init__(self, is_max_heap=False):
        self.heap = []
        self.is_max = is_max_heap
    
    def push(self, item, priority):
        if self.is_max:
            heapq.heappush(self.heap, (-priority, item))
        else:
            heapq.heappush(self.heap, (priority, item))
    
    def pop(self):
        if self.is_max:
            priority, item = heapq.heappop(self.heap)
            return item, -priority
        else:
            priority, item = heapq.heappop(self.heap)
            return item, priority
    
    def peek(self):
        if self.heap:
            if self.is_max:
                return self.heap[0][1], -self.heap[0][0]
            else:
                return self.heap[0][1], self.heap[0][0]
        return None
    
    def is_empty(self):
        return len(self.heap) == 0
```

### 3. **K-Way Merge**
```python
def k_way_merge(arrays):
    heap = []
    result = []
    
    # Initialize heap
    for i, array in enumerate(arrays):
        if array:
            heapq.heappush(heap, (array[0], i, 0))
    
    while heap:
        val, array_idx, elem_idx = heapq.heappop(heap)
        result.append(val)
        
        if elem_idx + 1 < len(arrays[array_idx]):
            next_val = arrays[array_idx][elem_idx + 1]
            heapq.heappush(heap, (next_val, array_idx, elem_idx + 1))
    
    return result
```

---

## Example Problems

### Problem 1: **Kth Largest Element in Array**
```python
def find_kth_largest(nums, k):
    # Method 1: Using min heap
    heap = []
    for num in nums:
        if len(heap) < k:
            heapq.heappush(heap, num)
        elif num > heap[0]:
            heapq.heapreplace(heap, num)
    return heap[0]

def find_kth_largest_quickselect(nums, k):
    # Method 2: Using quickselect
    def partition(left, right, pivot_idx):
        pivot = nums[pivot_idx]
        nums[pivot_idx], nums[right] = nums[right], nums[pivot_idx]
        
        store_idx = left
        for i in range(left, right):
            if nums[i] > pivot:
                nums[store_idx], nums[i] = nums[i], nums[store_idx]
                store_idx += 1
        
        nums[right], nums[store_idx] = nums[store_idx], nums[right]
        return store_idx
    
    def select(left, right, k_smallest):
        if left == right:
            return nums[left]
        
        pivot_idx = left + (right - left) // 2
        pivot_idx = partition(left, right, pivot_idx)
        
        if k_smallest == pivot_idx:
            return nums[k_smallest]
        elif k_smallest < pivot_idx:
            return select(left, pivot_idx - 1, k_smallest)
        else:
            return select(pivot_idx + 1, right, k_smallest)
    
    return select(0, len(nums) - 1, k - 1)
```

### Problem 2: **Task Scheduler**
```python
def least_interval(tasks, n):
    from collections import Counter
    
    # Count frequency of each task
    task_counts = Counter(tasks)
    max_heap = [-count for count in task_counts.values()]
    heapq.heapify(max_heap)
    
    time = 0
    
    while max_heap:
        temp = []
        
        # Process tasks for one cycle
        for _ in range(n + 1):
            if max_heap:
                count = heapq.heappop(max_heap)
                if count < -1:
                    temp.append(count + 1)
            time += 1
            
            if not max_heap and not temp:
                break
        
        # Put back remaining tasks
        for count in temp:
            heapq.heappush(max_heap, count)
    
    return time
```

### Problem 3: **Sliding Window Maximum**
```python
def max_sliding_window(nums, k):
    from collections import deque
    
    result = []
    dq = deque()  # Store indices
    
    for i in range(len(nums)):
        # Remove indices outside window
        while dq and dq[0] <= i - k:
            dq.popleft()
        
        # Remove smaller elements
        while dq and nums[dq[-1]] <= nums[i]:
            dq.pop()
        
        dq.append(i)
        
        # Add to result if window is complete
        if i >= k - 1:
            result.append(nums[dq[0]])
    
    return result
```

---

## Problem Categories

### 1. **Priority Queue Problems**
- Task scheduling
- Event simulation
- Resource allocation

### 2. **Top K Problems**
- K largest/smallest elements
- K