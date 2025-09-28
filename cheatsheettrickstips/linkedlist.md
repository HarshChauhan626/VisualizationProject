# Linked List - Comprehensive Cheatsheet

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

### What is a Linked List?

A linked list is a linear data structure where elements are stored in nodes, each containing data and a reference to the next node. Unlike arrays, linked lists don't require contiguous memory and can grow dynamically.

**Key Characteristics:**
- **Dynamic Size**: Grows/shrinks at runtime
- **Sequential Access**: Must traverse from head
- **Pointer-based**: Nodes connected via pointers
- **Memory Efficient**: No wasted space

### Basic Node Structure
```python
class ListNode:
    def __init__(self, val=0, next=None):
        self.val = val
        self.next = next
```

---

## Key Properties & Rules

### Fundamental Operations

#### 1. **Traversal**
```python
def traverse(head):
    current = head
    while current:
        print(current.val)
        current = current.next
```

#### 2. **Insertion**
```python
def insert_at_beginning(head, val):
    new_node = ListNode(val)
    new_node.next = head
    return new_node

def insert_at_end(head, val):
    new_node = ListNode(val)
    if not head:
        return new_node
    
    current = head
    while current.next:
        current = current.next
    current.next = new_node
    return head
```

#### 3. **Deletion**
```python
def delete_node(head, val):
    if not head:
        return head
    
    if head.val == val:
        return head.next
    
    current = head
    while current.next and current.next.val != val:
        current = current.next
    
    if current.next:
        current.next = current.next.next
    
    return head
```

---

## Patterns & Use Cases

### Core Patterns

#### 1. **Two Pointer Technique**
```python
def find_middle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
    return slow

def has_cycle(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow == fast:
            return True
    return False
```

#### 2. **Reversal Pattern**
```python
def reverse_list(head):
    prev = None
    current = head
    
    while current:
        next_node = current.next
        current.next = prev
        prev = current
        current = next_node
    
    return prev
```

#### 3. **Merge Pattern**
```python
def merge_two_sorted(l1, l2):
    dummy = ListNode(0)
    current = dummy
    
    while l1 and l2:
        if l1.val <= l2.val:
            current.next = l1
            l1 = l1.next
        else:
            current.next = l2
            l2 = l2.next
        current = current.next
    
    current.next = l1 or l2
    return dummy.next
```

---

## Common Algorithms

### 1. **Cycle Detection**
```python
def detect_cycle(head):
    if not head or not head.next:
        return None
    
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        if slow == fast:
            break
    else:
        return None
    
    slow = head
    while slow != fast:
        slow = slow.next
        fast = fast.next
    
    return slow
```

### 2. **Remove Nth from End**
```python
def remove_nth_from_end(head, n):
    dummy = ListNode(0)
    dummy.next = head
    
    first = second = dummy
    for _ in range(n + 1):
        first = first.next
    
    while first:
        first = first.next
        second = second.next
    
    second.next = second.next.next
    return dummy.next
```

### 3. **Palindrome Check**
```python
def is_palindrome(head):
    if not head or not head.next:
        return True
    
    # Find middle and reverse second half
    slow = fast = head
    while fast.next and fast.next.next:
        slow = slow.next
        fast = fast.next.next
    
    # Reverse second half
    second_half = reverse_list(slow.next)
    slow.next = None
    
    # Compare
    first_half = head
    while second_half:
        if first_half.val != second_half.val:
            return False
        first_half = first_half.next
        second_half = second_half.next
    
    return True
```

---

## Example Problems

### Problem 1: **Add Two Numbers**
```python
def add_two_numbers(l1, l2):
    dummy = ListNode(0)
    current = dummy
    carry = 0
    
    while l1 or l2 or carry:
        val1 = l1.val if l1 else 0
        val2 = l2.val if l2 else 0
        
        total = val1 + val2 + carry
        carry = total // 10
        current.next = ListNode(total % 10)
        
        current = current.next
        l1 = l1.next if l1 else None
        l2 = l2.next if l2 else None
    
    return dummy.next
```

### Problem 2: **Intersection of Two Lists**
```python
def get_intersection_node(headA, headB):
    if not headA or not headB:
        return None
    
    pA, pB = headA, headB
    
    while pA != pB:
        pA = pA.next if pA else headB
        pB = pB.next if pB else headA
    
    return pA
```

---

## Problem Categories

### 1. **Pointer Manipulation**
- Reverse linked list
- Remove nodes
- Insert nodes
- Merge lists

### 2. **Cycle Problems**
- Detect cycle
- Find cycle start
- Remove cycle

### 3. **Two List Problems**
- Merge sorted lists
- Find intersection
- Add numbers

### 4. **Mathematical Operations**
- Add/subtract numbers
- Convert to/from other formats

---

## Pro Tips & Interview Tricks

### Essential Techniques

#### 1. **Dummy Node Pattern**
```python
def solution(head):
    dummy = ListNode(0)
    dummy.next = head
    # Work with dummy.next
    return dummy.next
```

#### 2. **Two Pointer Template**
```python
def two_pointer_solution(head):
    slow = fast = head
    while fast and fast.next:
        slow = slow.next
        fast = fast.next.next
        # Process...
```

#### 3. **Edge Case Handling**
```python
def robust_solution(head):
    if not head:
        return None
    if not head.next:
        return head
    # Continue with main logic
```

### Common Patterns Recognition

1. **Cycle Detection**: Use Floyd's algorithm (tortoise and hare)
2. **Finding Middle**: Slow/fast pointers
3. **Nth from End**: Two pointers with gap
4. **Reversal**: Three pointer technique
5. **Merging**: Dummy node with comparison

### Interview Success Tips

1. **Draw it out**: Visualize pointer movements
2. **Handle edge cases**: Empty list, single node
3. **Use dummy nodes**: Simplifies insertion/deletion
4. **Check for cycles**: Before infinite loops
5. **Practice pointer arithmetic**: Know next, prev operations
6. **Memory management**: Be aware of dangling pointers

Linked lists are fundamental to many advanced data structures. Master the core patterns and pointer manipulation techniques for interview success!