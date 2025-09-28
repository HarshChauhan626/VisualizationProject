# Queue & Stack - Comprehensive Cheatsheet

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

### Stack (LIFO - Last In, First Out)

A stack is like a stack of plates - you can only add or remove plates from the top. The last plate you put on is the first one you take off.

**Key Operations:**
- **Push**: Add element to top
- **Pop**: Remove element from top
- **Peek/Top**: View top element without removing
- **isEmpty**: Check if stack is empty

**Real-world Examples:**
- Call stack in programming
- Undo operations in editors
- Browser back button
- Expression evaluation

### Queue (FIFO - First In, First Out)

A queue is like a line at a store - first person in line is the first person served.

**Key Operations:**
- **Enqueue**: Add element to rear
- **Dequeue**: Remove element from front
- **Front**: View front element
- **Rear**: View rear element
- **isEmpty**: Check if queue is empty

**Real-world Examples:**
- Print job queues
- CPU task scheduling
- BFS in graphs
- Handling requests in web servers

### Deque (Double-ended Queue)

A deque allows insertion and deletion at both ends.

**Operations:**
- **addFront/addRear**: Add to front/rear
- **removeFront/removeRear**: Remove from front/rear
- **peekFront/peekRear**: View front/rear elements

---

## Key Properties & Rules

### Stack Properties

#### LIFO Principle
- Last element pushed is first to be popped
- Access only to top element
- No random access to middle elements

#### Stack Implementation

**Array-based Stack:**
```python
class ArrayStack:
    def __init__(self):
        self.items = []
    
    def push(self, item):
        self.items.append(item)
    
    def pop(self):
        if self.is_empty():
            raise IndexError("Stack is empty")
        return self.items.pop()
    
    def peek(self):
        if self.is_empty():
            raise IndexError("Stack is empty")
        return self.items[-1]
    
    def is_empty(self):
        return len(self.items) == 0
    
    def size(self):
        return len(self.items)
```

**Linked List Stack:**
```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next

class LinkedStack:
    def __init__(self):
        self.head = None
        self.count = 0
    
    def push(self, item):
        new_node = ListNode(item)
        new_node.next = self.head
        self.head = new_node
        self.count += 1
    
    def pop(self):
        if self.is_empty():
            raise IndexError("Stack is empty")
        val = self.head.val
        self.head = self.head.next
        self.count -= 1
        return val
    
    def peek(self):
        if self.is_empty():
            return None
        return self.head.val
    
    def is_empty(self):
        return self.head is None
```

### Queue Properties

#### FIFO Principle
- First element enqueued is first to be dequeued
- Access to both front and rear
- Elements maintain insertion order

#### Queue Implementation

**Array-based Queue (Circular):**
```python
class CircularQueue:
    def __init__(self, capacity):
        self.capacity = capacity
        self.queue = [None] * capacity
        self.front = 0
        self.rear = -1
        self.size = 0
    
    def enqueue(self, item):
        if self.is_full():
            raise OverflowError("Queue is full")
        self.rear = (self.rear + 1) % self.capacity
        self.queue[self.rear] = item
        self.size += 1
    
    def dequeue(self):
        if self.is_empty():
            raise IndexError("Queue is empty")
        item = self.queue[self.front]
        self.queue[self.front] = None
        self.front = (self.front + 1) % self.capacity
        self.size -= 1
        return item
    
    def is_empty(self):
        return self.size == 0
    
    def is_full(self):
        return self.size == self.capacity
```

**Linked List Queue:**
```python
class LinkedQueue:
    def __init__(self):
        self.front = None
        self.rear = None
        self.size = 0
    
    def enqueue(self, item):
        new_node = ListNode(item)
        if self.is_empty():
            self.front = self.rear = new_node
        else:
            self.rear.next = new_node
            self.rear = new_node
        self.size += 1
    
    def dequeue(self):
        if self.is_empty():
            raise IndexError("Queue is empty")
        item = self.front.val
        self.front = self.front.next
        if self.front is None:
            self.rear = None
        self.size -= 1
        return item
```

---

## Patterns & Use Cases

### Stack Patterns

#### 1. **Monotonic Stack**
Maintains elements in monotonic (increasing/decreasing) order.

**Use Cases:**
- Next Greater Element
- Largest Rectangle in Histogram
- Daily Temperatures

```python
def next_greater_elements(nums):
    result = [-1] * len(nums)
    stack = []  # Stack stores indices
    
    for i in range(len(nums)):
        # Pop elements smaller than current
        while stack and nums[stack[-1]] < nums[i]:
            index = stack.pop()
            result[index] = nums[i]
        stack.append(i)
    
    return result
```

#### 2. **Expression Evaluation**
Evaluate mathematical expressions and check balanced parentheses.

```python
def is_valid_parentheses(s):
    stack = []
    mapping = {')': '(', '}': '{', ']': '['}
    
    for char in s:
        if char in mapping:
            if not stack or stack.pop() != mapping[char]:
                return False
        else:
            stack.append(char)
    
    return not stack
```

#### 3. **Function Call Stack**
Track function calls and recursion.

### Queue Patterns

#### 1. **BFS Traversal**
Level-order traversal in trees and graphs.

```python
from collections import deque

def bfs_tree(root):
    if not root:
        return []
    
    result = []
    queue = deque([root])
    
    while queue:
        node = queue.popleft()
        result.append(node.val)
        
        if node.left:
            queue.append(node.left)
        if node.right:
            queue.append(node.right)
    
    return result
```

#### 2. **Sliding Window Maximum**
Use deque to maintain maximum in sliding window.

```python
def sliding_window_maximum(nums, k):
    if not nums or k <= 0:
        return []
    
    dq = deque()  # Store indices
    result = []
    
    for i in range(len(nums)):
        # Remove indices outside window
        while dq and dq[0] <= i - k:
            dq.popleft()
        
        # Remove smaller elements
        while dq and nums[dq[-1]] < nums[i]:
            dq.pop()
        
        dq.append(i)
        
        # Add to result when window is full
        if i >= k - 1:
            result.append(nums[dq[0]])
    
    return result
```

---

## Step-by-Step Approaches

### Stack Problem Framework

1. **Identify Stack Usage**:
   - Need to reverse order?
   - Track nested structures?
   - Maintain last-seen elements?

2. **Choose Stack Type**:
   - Simple stack for basic operations
   - Monotonic stack for next/previous greater/smaller
   - Stack with additional data for complex operations

3. **Implementation Pattern**:
   ```python
   stack = []
   for element in input:
       # Process current element
       while stack and condition(stack[-1], element):
           # Process stack top
           stack.pop()
       stack.append(element)
   ```

### Queue Problem Framework

1. **Identify Queue Usage**:
   - Process in FIFO order?
   - Level-by-level processing?
   - Sliding window problems?

2. **Choose Queue Type**:
   - Simple queue for BFS
   - Deque for sliding window
   - Priority queue for ordered processing

3. **Implementation Pattern**:
   ```python
   queue = deque()
   queue.append(initial_elements)
   
   while queue:
       current = queue.popleft()
       # Process current element
       # Add new elements to queue
   ```

---

## Common Algorithms

### 1. Monotonic Stack Problems

#### Daily Temperatures
```python
def daily_temperatures(temperatures):
    result = [0] * len(temperatures)
    stack = []  # Stack of indices
    
    for i, temp in enumerate(temperatures):
        while stack and temperatures[stack[-1]] < temp:
            prev_index = stack.pop()
            result[prev_index] = i - prev_index
        stack.append(i)
    
    return result
```

#### Largest Rectangle in Histogram
```python
def largest_rectangle_area(heights):
    stack = []
    max_area = 0
    
    for i, height in enumerate(heights):
        while stack and heights[stack[-1]] > height:
            h = heights[stack.pop()]
            w = i if not stack else i - stack[-1] - 1
            max_area = max(max_area, h * w)
        stack.append(i)
    
    # Process remaining bars
    while stack:
        h = heights[stack.pop()]
        w = len(heights) if not stack else len(heights) - stack[-1] - 1
        max_area = max(max_area, h * w)
    
    return max_area
```

### 2. Queue-based BFS

#### Level Order Traversal
```python
def level_order_traversal(root):
    if not root:
        return []
    
    result = []
    queue = deque([root])
    
    while queue:
        level_size = len(queue)
        level_nodes = []
        
        for _ in range(level_size):
            node = queue.popleft()
            level_nodes.append(node.val)
            
            if node.left:
                queue.append(node.left)
            if node.right:
                queue.append(node.right)
        
        result.append(level_nodes)
    
    return result
```

#### Word Ladder (Shortest Path)
```python
def ladder_length(begin_word, end_word, word_list):
    if end_word not in word_list:
        return 0
    
    word_set = set(word_list)
    queue = deque([(begin_word, 1)])
    visited = {begin_word}
    
    while queue:
        word, length = queue.popleft()
        
        if word == end_word:
            return length
        
        # Try all possible one-letter changes
        for i in range(len(word)):
            for c in 'abcdefghijklmnopqrstuvwxyz':
                next_word = word[:i] + c + word[i+1:]
                
                if next_word in word_set and next_word not in visited:
                    visited.add(next_word)
                    queue.append((next_word, length + 1))
    
    return 0
```

### 3. Stack for Expression Evaluation

#### Basic Calculator
```python
def calculate(s):
    stack = []
    num = 0
    sign = '+'
    
    for i, char in enumerate(s):
        if char.isdigit():
            num = num * 10 + int(char)
        
        if char in '+-*/' or i == len(s) - 1:
            if sign == '+':
                stack.append(num)
            elif sign == '-':
                stack.append(-num)
            elif sign == '*':
                stack.append(stack.pop() * num)
            elif sign == '/':
                # Handle negative division
                last = stack.pop()
                stack.append(int(last / num))
            
            num = 0
            sign = char
    
    return sum(stack)
```

#### Reverse Polish Notation
```python
def eval_rpn(tokens):
    stack = []
    
    for token in tokens:
        if token in '+-*/':
            b = stack.pop()
            a = stack.pop()
            
            if token == '+':
                stack.append(a + b)
            elif token == '-':
                stack.append(a - b)
            elif token == '*':
                stack.append(a * b)
            elif token == '/':
                # Integer division towards zero
                stack.append(int(a / b))
        else:
            stack.append(int(token))
    
    return stack[0]
```

---

## Edge Cases

### Stack Edge Cases
1. **Empty Stack**: Pop/peek on empty stack
2. **Single Element**: Stack with one element
3. **Stack Overflow**: Exceeding capacity (array-based)
4. **Null Elements**: Handling null values

### Queue Edge Cases
1. **Empty Queue**: Dequeue from empty queue
2. **Single Element**: Queue with one element
3. **Queue Full**: Exceeding capacity (circular queue)
4. **Circular Wrap**: Index wrapping in circular queue

### Common Pitfalls
```python
# Wrong: Not checking if stack is empty
if stack[-1] > current:  # Can cause IndexError

# Correct: Always check emptiness
if stack and stack[-1] > current:
```

---

## Complexity Analysis

### Stack Operations

| Operation | Array-based | Linked List |
|-----------|-------------|-------------|
| Push | O(1) amortized | O(1) |
| Pop | O(1) | O(1) |
| Peek | O(1) | O(1) |
| Search | O(n) | O(n) |
| Space | O(n) | O(n) |

### Queue Operations

| Operation | Circular Array | Linked List |
|-----------|----------------|-------------|
| Enqueue | O(1) | O(1) |
| Dequeue | O(1) | O(1) |
| Front | O(1) | O(1) |
| Search | O(n) | O(n) |
| Space | O(n) | O(n) |

---

## Problem Categories

### Stack Problems
1. **Parentheses**: Valid Parentheses, Remove Invalid Parentheses
2. **Monotonic Stack**: Next Greater Element, Daily Temperatures
3. **Expression**: Basic Calculator, Evaluate RPN
4. **String Processing**: Remove Duplicate Letters, Decode String

### Queue Problems
1. **BFS**: Binary Tree Level Order, Word Ladder
2. **Sliding Window**: Sliding Window Maximum
3. **Simulation**: Design Hit Counter, Moving Average
4. **Graph**: Shortest Path, Islands

---

## Pro Tips & Interview Tricks

### Problem Recognition
```
Nested Structures → Stack
Level-by-level Processing → Queue
Next/Previous Greater → Monotonic Stack
Expression Evaluation → Stack
Shortest Path (unweighted) → BFS with Queue
```

### Implementation Tips

1. **Use Collections.deque**: More efficient than list for queue operations
2. **Check Empty**: Always verify before pop/peek operations
3. **Monotonic Stack Pattern**: Common in "next greater/smaller" problems
4. **BFS Template**: Level-by-level processing pattern

### Common Mistakes

1. **Using List as Queue**: `list.pop(0)` is O(n)
2. **Not Handling Empty**: Forgetting to check empty conditions
3. **Index Errors**: Accessing elements without bounds checking
4. **Memory Leaks**: Not properly clearing references

### Code Templates

#### Monotonic Stack Template
```python
def monotonic_stack_pattern(arr):
    stack = []
    result = []
    
    for i, val in enumerate(arr):
        while stack and condition(stack[-1], val):
            # Process the popped element
            popped = stack.pop()
            # Do something with popped element
        
        stack.append(val)  # or append index i
        result.append(some_computation)
    
    return result
```

#### BFS Template
```python
def bfs_template(start):
    queue = deque([start])
    visited = set([start])
    result = []
    
    while queue:
        current = queue.popleft()
        result.append(current)
        
        for neighbor in get_neighbors(current):
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)
    
    return result
```

---

## Conclusion

Stacks and queues are fundamental data structures that power many algorithms:

**Stacks excel at**:
- Reversing order (LIFO nature)
- Tracking nested structures
- Expression evaluation
- Maintaining "most recent" information

**Queues excel at**:
- First-come-first-served processing
- Level-by-level traversal
- Breadth-first search
- Sliding window problems with deque

**Success Formula**: Recognize the pattern + Choose right structure + Handle edge cases = Stack/Queue mastery

Master these patterns and you'll efficiently solve problems involving ordered processing and hierarchical structures!