# Array Data Structure - Comprehensive Cheatsheet

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

### What is an Array?

An array is a fundamental linear data structure that stores elements of the same type in contiguous memory locations. Think of an array as a row of mailboxes in an apartment building - each mailbox has a specific address (index), can hold one item (element), and you can access any mailbox directly if you know its address.

**Key Characteristics:**
- **Contiguous Memory**: Elements are stored in adjacent memory locations
- **Fixed Size**: In most languages, arrays have a predetermined size (though dynamic arrays exist)
- **Random Access**: Any element can be accessed in O(1) time using its index
- **Homogeneous**: All elements must be of the same data type
- **Zero-Based Indexing**: Most languages use 0-based indexing (first element at index 0)

### Real-World Analogies

1. **Library Bookshelf**: Books arranged in order where you can go directly to shelf position 5 to find the 5th book
2. **Parking Lot**: Numbered parking spaces where each car (element) occupies exactly one space (index)
3. **Theatre Seating**: Row of seats with specific seat numbers for direct access
4. **Egg Carton**: Fixed slots where each position can hold exactly one egg

### Memory Layout Visualization

```
Array: [10, 25, 30, 45, 50]
Index:  0   1   2   3   4

Memory Layout:
┌────┬────┬────┬────┬────┐
│ 10 │ 25 │ 30 │ 45 │ 50 │
└────┴────┴────┴────┴────┘
Addr: 100 104 108 112 116  (assuming 4 bytes per int)
```

### Mathematical Foundation

Arrays are built on the mathematical concept of **sequences** and **mappings**. An array can be viewed as a function f: Index → Value, where:
- Domain: Set of valid indices {0, 1, 2, ..., n-1}
- Codomain: Set of possible values of the element type
- The function maps each index to exactly one value

**Address Calculation Formula:**
```
address(arr[i]) = base_address + (i × element_size)
```

This mathematical relationship enables O(1) random access - the fundamental advantage of arrays over linked structures.

### Historical Context

Arrays are one of the oldest data structures in computer science, dating back to the 1940s with early computers like EDVAC. The concept was formalized by John von Neumann in his stored-program computer architecture. Arrays became fundamental because they directly map to how computer memory works - as a linear sequence of addressable locations.

**Evolution Timeline:**
- **1940s**: Basic array concept in assembly languages
- **1950s**: FORTRAN introduces multi-dimensional arrays
- **1960s**: ALGOL formalizes array syntax and semantics
- **1970s**: C introduces pointer arithmetic closely tied to arrays
- **1990s**: Dynamic arrays (vectors) in C++, Java, Python
- **2000s**: Modern languages with built-in array methods and functional programming support

---

## Key Properties & Rules

### Fundamental Properties

#### 1. **Index Bounds**
- Valid indices: 0 to (length - 1)
- Accessing out-of-bounds indices leads to undefined behavior or runtime errors
- Negative indices are invalid in most languages (except Python-style negative indexing)

#### 2. **Memory Contiguity**
- Elements stored in consecutive memory locations
- Enables cache-friendly access patterns
- Supports pointer arithmetic for traversal

#### 3. **Type Homogeneity**
- All elements must be of the same type
- Ensures consistent memory layout and operations
- Type safety enforced at compile time

#### 4. **Fixed vs Dynamic Sizing**

**Static Arrays:**
```cpp
int arr[10];  // Fixed size of 10 integers
```

**Dynamic Arrays:**
```cpp
vector<int> arr;  // Can grow/shrink during runtime
```

### Mathematical Properties

#### Array Invariants
1. **Length Invariant**: `0 ≤ valid_index < array.length`
2. **Type Invariant**: All elements conform to declared type
3. **Memory Invariant**: Elements occupy contiguous memory

#### Algebraic Properties
- **Associativity**: Array concatenation is associative: `(A + B) + C = A + (B + C)`
- **Identity Element**: Empty array [] is the identity for concatenation
- **Commutativity**: Array concatenation is NOT commutative: `A + B ≠ B + A`

### Performance Characteristics

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Access by index | O(1) | O(1) |
| Search (unsorted) | O(n) | O(1) |
| Search (sorted) | O(log n) | O(1) |
| Insertion at end | O(1) amortized | O(1) |
| Insertion at beginning | O(n) | O(1) |
| Deletion at end | O(1) | O(1) |
| Deletion at beginning | O(n) | O(1) |

### Memory Access Patterns

#### Cache Efficiency
Arrays provide excellent **spatial locality** - accessing elements sequentially maximizes cache hits:

```cpp
// Cache-friendly: Sequential access
for (i = 0; i < n; i++) {
    sum += arr[i];  // High cache hit rate
}

// Cache-unfriendly: Random access
for (i = 0; i < n; i++) {
    sum += arr[random_index];  // Poor cache performance
```

#### Memory Alignment
Modern processors access memory in chunks (cache lines, typically 64 bytes). Arrays benefit from:
- **Alignment**: Starting address aligned to cache line boundaries
- **Prefetching**: Processor automatically loads nearby elements
- **Vectorization**: SIMD instructions can process multiple array elements simultaneously

---

## Patterns & Use Cases

### Core Array Patterns

#### 1. **Two Pointers Technique**

**When to Use:**
- Sorted arrays with pair/triplet sum problems
- Palindrome checking
- Array partitioning problems
- Removing duplicates in-place

**Pattern Recognition:**
- Problem involves examining pairs of elements
- Array is sorted or can be sorted
- Need to find elements that satisfy some condition
- Space optimization required (in-place operations)

**Variants:**
- **Opposite Direction**: Start from both ends, move toward center
- **Same Direction**: Both pointers move in same direction at different speeds
- **Fast-Slow**: One pointer moves faster than the other

```python
# Opposite Direction Example: Two Sum in Sorted Array
def two_sum_sorted(arr, target):
    left, right = 0, len(arr) - 1
    
    while left < right:
        current_sum = arr[left] + arr[right]
        if current_sum == target:
            return [left, right]
        elif current_sum < target:
            left += 1
        else:
            right -= 1
    
    return [-1, -1]
```

#### 2. **Sliding Window Pattern**

**When to Use:**
- Subarray/substring problems
- Finding maximum/minimum in subarrays
- Problems involving contiguous elements
- Optimization problems with constraints

**Window Types:**
- **Fixed Size**: Window size remains constant
- **Variable Size**: Window expands and contracts based on conditions

```python
# Fixed Window: Maximum sum of k consecutive elements
def max_sum_k_elements(arr, k):
    n = len(arr)
    if n < k:
        return -1
    
    # Calculate sum of first window
    window_sum = sum(arr[:k])
    max_sum = window_sum
    
    # Slide the window
    for i in range(k, n):
        window_sum = window_sum - arr[i-k] + arr[i]
        max_sum = max(max_sum, window_sum)
    
    return max_sum
```

#### 3. **Prefix Sum Pattern**

**When to Use:**
- Range sum queries
- Subarray sum problems
- Equilibrium point problems
- 2D matrix sum queries

```python
# Prefix Sum for Range Queries
def build_prefix_sum(arr):
    prefix = [0] * (len(arr) + 1)
    for i in range(len(arr)):
        prefix[i + 1] = prefix[i] + arr[i]
    return prefix

def range_sum(prefix, left, right):
    return prefix[right + 1] - prefix[left]
```

### Industry Applications

#### 1. **Database Systems**
- **Columnar Storage**: Arrays store column data for efficient analytical queries
- **Index Structures**: B-tree nodes use arrays for key storage
- **Buffer Pools**: Array-based buffer management for page caching

#### 2. **Graphics and Game Development**
- **Vertex Arrays**: 3D coordinates stored in arrays for rendering
- **Texture Data**: 2D/3D arrays represent image pixels
- **Animation Frames**: Sequential array of game states

#### 3. **Scientific Computing**
- **Matrix Operations**: 2D arrays for linear algebra computations
- **Signal Processing**: Time-series data in arrays for FFT operations
- **Simulation Data**: Particle positions, velocities in physics simulations

#### 4. **Financial Systems**
- **Time Series**: Stock prices, trading volumes over time
- **Risk Calculations**: Portfolio positions in arrays for risk metrics
- **High-Frequency Trading**: Market data arrays for millisecond decisions

#### 5. **Machine Learning**
- **Feature Vectors**: Training data represented as arrays
- **Neural Networks**: Weight matrices as multi-dimensional arrays
- **Image Processing**: Pixel data in 2D/3D arrays

### Problem Categories by Pattern

#### **Searching Patterns**
1. **Linear Search**: Unsorted arrays, finding specific elements
2. **Binary Search**: Sorted arrays, logarithmic time searching
3. **Ternary Search**: Finding maximum/minimum in unimodal arrays
4. **Exponential Search**: Unbounded arrays, finding range then binary search

#### **Sorting Patterns**
1. **Comparison-Based**: Merge sort, quick sort, heap sort
2. **Non-Comparison**: Counting sort, radix sort, bucket sort
3. **Partial Sorting**: Finding kth smallest/largest element
4. **Stability Requirements**: Maintaining relative order of equal elements

#### **Subarray Patterns**
1. **Maximum Subarray**: Kadane's algorithm variants
2. **Subarray with Given Sum**: Hash maps, prefix sums
3. **Longest Subarray**: With specific properties or constraints
4. **Number of Subarrays**: Counting subarrays meeting criteria

---

## Step-by-Step Approaches

### Generic Problem-Solving Framework

#### Step 1: **Problem Analysis**

**Questions to Ask:**
1. Is the array sorted or unsorted?
2. Are there duplicate elements?
3. What is the expected input size?
4. Are there memory constraints?
5. Do we need to modify the array in-place?
6. What is the expected output format?

**Classification Checklist:**
```
□ Search Problem: Finding specific elements/indices
□ Optimization Problem: Maximum/minimum values or subarrays
□ Counting Problem: Number of elements/subarrays meeting criteria
□ Transformation Problem: Modifying array to meet requirements
□ Validation Problem: Checking if array satisfies conditions
```

#### Step 2: **Pattern Recognition**

**Decision Tree:**
```
Is array sorted?
├─ Yes:
│  ├─ Binary Search variants
│  ├─ Two Pointers (opposite direction)
│  └─ Merge operations
└─ No:
   ├─ Can we sort? → Sorting + above patterns
   ├─ Subarray problem? → Sliding Window
   ├─ Need all elements? → Linear scan
   └─ Range queries? → Prefix sums
```

#### Step 3: **Algorithm Selection**

**Time Complexity Goals:**
- **O(1)**: Direct access, simple calculations
- **O(log n)**: Binary search on sorted data
- **O(n)**: Single pass solutions, optimal linear algorithms
- **O(n log n)**: Sorting-based solutions
- **O(n²)**: Nested loops, brute force approaches

#### Step 4: **Implementation Template**

```python
def solve_array_problem(arr, *args):
    # 1. Handle edge cases
    if not arr or len(arr) == 0:
        return default_value
    
    # 2. Initialize variables
    n = len(arr)
    result = initialize_result()
    
    # 3. Preprocessing (if needed)
    # Sort, build prefix sums, etc.
    
    # 4. Main algorithm
    # Apply chosen pattern/algorithm
    
    # 5. Post-processing
    # Format result, handle special cases
    
    return result
```

### Specific Approach Templates

#### Binary Search Template

```python
def binary_search_template(arr, target):
    left, right = 0, len(arr) - 1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return -1  # Not found
```

**Variants:**
- **Find First Occurrence**: Modify condition to continue searching left
- **Find Last Occurrence**: Modify condition to continue searching right
- **Find Insert Position**: Return `left` when not found
- **Search in Rotated Array**: Add pivot detection logic

#### Two Pointers Template

```python
def two_pointers_template(arr):
    left, right = 0, len(arr) - 1
    result = []
    
    while left < right:
        # Calculate current state
        current = calculate_state(arr[left], arr[right])
        
        if meets_condition(current):
            result.append([left, right])
            left += 1
            right -= 1
        elif should_move_left(current):
            left += 1
        else:
            right -= 1
    
    return result
```

#### Sliding Window Template

```python
def sliding_window_template(arr, constraint):
    left = 0
    result = []
    window_state = initialize_window_state()
    
    for right in range(len(arr)):
        # Expand window
        update_window_state(window_state, arr[right])
        
        # Contract window if needed
        while not window_valid(window_state, constraint):
            remove_from_window(window_state, arr[left])
            left += 1
        
        # Update result with current window
        if window_meets_criteria(window_state):
            result.append(get_window_result(left, right))
    
    return result
```

---

## Common Algorithms

### 1. Binary Search and Variants

#### Standard Binary Search
**Time Complexity:** O(log n)  
**Space Complexity:** O(1)

```python
def binary_search(arr, target):
    """Find target in sorted array, return index or -1"""
    left, right = 0, len(arr) - 1
    
    while left <= right:
        mid = left + (right - left) // 2  # Prevents overflow
        
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return -1
```

#### Binary Search: Find First/Last Occurrence

```python
def find_first_occurrence(arr, target):
    """Find leftmost occurrence of target"""
    left, right = 0, len(arr) - 1
    result = -1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if arr[mid] == target:
            result = mid
            right = mid - 1  # Continue searching left
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return result

def find_last_occurrence(arr, target):
    """Find rightmost occurrence of target"""
    left, right = 0, len(arr) - 1
    result = -1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if arr[mid] == target:
            result = mid
            left = mid + 1  # Continue searching right
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    
    return result
```

#### Binary Search in Rotated Array

```python
def search_rotated_array(arr, target):
    """Search in rotated sorted array"""
    left, right = 0, len(arr) - 1
    
    while left <= right:
        mid = left + (right - left) // 2
        
        if arr[mid] == target:
            return mid
        
        # Left half is sorted
        if arr[left] <= arr[mid]:
            if arr[left] <= target < arr[mid]:
                right = mid - 1
            else:
                left = mid + 1
        # Right half is sorted
        else:
            if arr[mid] < target <= arr[right]:
                left = mid + 1
            else:
                right = mid - 1
    
    return -1
```

### 2. Kadane's Algorithm (Maximum Subarray)
**Time Complexity:** O(n)  
**Space Complexity:** O(1)

```python
def max_subarray_sum(arr):
    """Find maximum sum of contiguous subarray"""
    if not arr:
        return 0
    
    max_so_far = arr[0]
    max_ending_here = arr[0]
    
    for i in range(1, len(arr)):
        # Either extend existing subarray or start new one
        max_ending_here = max(arr[i], max_ending_here + arr[i])
        max_so_far = max(max_so_far, max_ending_here)
    
    return max_so_far

def max_subarray_with_indices(arr):
    """Return max sum and the subarray indices"""
    if not arr:
        return 0, -1, -1
    
    max_so_far = arr[0]
    max_ending_here = arr[0]
    start = 0
    end = 0
    temp_start = 0
    
    for i in range(1, len(arr)):
        if max_ending_here < 0:
            max_ending_here = arr[i]
            temp_start = i
        else:
            max_ending_here += arr[i]
        
        if max_ending_here > max_so_far:
            max_so_far = max_ending_here
            start = temp_start
            end = i
    
    return max_so_far, start, end
```

### 3. Dutch National Flag (Three-Way Partitioning)
**Time Complexity:** O(n)  
**Space Complexity:** O(1)

```python
def dutch_flag_partition(arr, pivot):
    """Partition array into three parts: <pivot, =pivot, >pivot"""
    low = 0
    mid = 0
    high = len(arr) - 1
    
    while mid <= high:
        if arr[mid] < pivot:
            arr[low], arr[mid] = arr[mid], arr[low]
            low += 1
            mid += 1
        elif arr[mid] == pivot:
            mid += 1
        else:  # arr[mid] > pivot
            arr[mid], arr[high] = arr[high], arr[mid]
            high -= 1
            # Don't increment mid as we need to check swapped element
    
    return arr

def sort_colors(arr):
    """Sort array of 0s, 1s, and 2s (colors)"""
    red = 0    # boundary for 0s
    white = 0  # current position
    blue = len(arr) - 1  # boundary for 2s
    
    while white <= blue:
        if arr[white] == 0:
            arr[red], arr[white] = arr[white], arr[red]
            red += 1
            white += 1
        elif arr[white] == 1:
            white += 1
        else:  # arr[white] == 2
            arr[white], arr[blue] = arr[blue], arr[white]
            blue -= 1
    
    return arr
```

### 4. Moore's Voting Algorithm
**Time Complexity:** O(n)  
**Space Complexity:** O(1)

```python
def majority_element(arr):
    """Find majority element (appears > n/2 times)"""
    candidate = None
    count = 0
    
    # Phase 1: Find candidate
    for num in arr:
        if count == 0:
            candidate = num
            count = 1
        elif num == candidate:
            count += 1
        else:
            count -= 1
    
    # Phase 2: Verify candidate (optional if majority guaranteed)
    count = 0
    for num in arr:
        if num == candidate:
            count += 1
    
    return candidate if count > len(arr) // 2 else None

def majority_elements_k(arr, k):
    """Find all elements appearing > n/k times"""
    # Implementation for finding multiple majority elements
    pass
```

## Edge Cases

### Critical Edge Cases
1. **Empty Arrays**: Always check if array exists and has elements
2. **Single Element**: Many algorithms have special cases for size 1
3. **Duplicate Values**: Consider how duplicates affect your algorithm
4. **Integer Overflow**: Use safe arithmetic operations
5. **Index Bounds**: Prevent out-of-bounds access

## Complexity Analysis

### Time Complexity Patterns
- **O(1)**: Direct array access
- **O(log n)**: Binary search on sorted arrays
- **O(n)**: Single pass algorithms (optimal for many problems)
- **O(n log n)**: Sorting-based solutions
- **O(n²)**: Nested loops, brute force approaches

### Space Complexity
- **O(1)**: In-place algorithms
- **O(n)**: Additional arrays or recursion depth

## Problem Categories

### 1. **Two Pointers**
- Two Sum, Three Sum
- Container with Most Water
- Remove Duplicates
- Dutch National Flag

### 2. **Sliding Window**
- Maximum Sum Subarray
- Longest Substring Problems
- Minimum Window Substring

### 3. **Binary Search**
- Search in Sorted/Rotated Arrays
- Find Peak Element
- First/Last Occurrence

### 4. **Prefix Sum**
- Range Sum Queries
- Subarray Sum Equals K
- Equilibrium Point

## Pro Tips & Interview Tricks

### 1. **Pattern Recognition**
```
Sorted Array + Search → Binary Search
Pairs in Sorted Array → Two Pointers
Subarray Problems → Sliding Window
Range Queries → Prefix Sum
In-place Modification → Dutch Flag Pattern
```

### 2. **Optimization Strategies**
- **Sort First**: Often enables O(n log n) solutions instead of O(n²)
- **Hash Maps**: Trade space for time in search problems
- **Two Pointers**: Reduce O(n²) to O(n) for pair problems
- **In-place**: Use input array as workspace when possible

### 3. **Common Mistakes to Avoid**
- Off-by-one errors in binary search
- Not handling empty arrays
- Integer overflow in sum calculations
- Modifying array while iterating

### 4. **Interview-Specific Tips**
- Always clarify input constraints
- Start with brute force, then optimize
- Test with edge cases
- Explain time/space complexity
- Consider follow-up questions

### 5. **Code Templates**

#### Binary Search Template:
```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = left + (right - left) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1
```

#### Two Pointers Template:
```python
def two_pointers(arr):
    left, right = 0, len(arr) - 1
    while left < right:
        if condition_met(arr[left], arr[right]):
            # Process and move both pointers
            left += 1
            right -= 1
        elif should_move_left():
            left += 1
        else:
            right -= 1
```

#### Sliding Window Template:
```python
def sliding_window(arr, k):
    window_sum = sum(arr[:k])
    max_sum = window_sum
    
    for i in range(k, len(arr)):
        window_sum = window_sum - arr[i-k] + arr[i]
        max_sum = max(max_sum, window_sum)
    
    return max_sum
```

### 6. **Memory Optimization Tricks**
- Reuse input array when modification is allowed
- Use bit manipulation for boolean arrays
- Implement cyclic arrays for space efficiency
- Consider streaming algorithms for large datasets

### 7. **Performance Optimization**
- Prefer iterative over recursive solutions
- Use appropriate data structures (arrays vs lists)
- Consider cache locality in nested loops
- Minimize memory allocations in tight loops

---

## Conclusion

Arrays form the foundation of most algorithmic problems. Mastering array patterns like two pointers, sliding window, binary search, and prefix sums will help you solve 70% of array-related interview questions efficiently. Remember to always consider edge cases, analyze complexity, and choose the most appropriate pattern for each problem.

**Key Takeaways:**
1. Arrays provide O(1) access but O(n) insertion/deletion
2. Sorting often enables more efficient algorithms
3. Two pointers and sliding window are essential optimization techniques
4. Binary search works on any monotonic function, not just sorted arrays
5. Space-time tradeoffs are crucial in array problems

This comprehensive guide covers the essential array concepts, patterns, and problems you'll encounter in technical interviews and competitive programming. Practice implementing these patterns until they become second nature!