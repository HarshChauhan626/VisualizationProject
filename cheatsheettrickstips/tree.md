# Tree Data Structures - Comprehensive Cheatsheet

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

### What is a Tree?

A tree is a hierarchical data structure consisting of nodes connected by edges, with exactly one path between any two nodes. Think of a family tree, organizational chart, or file system - all represent hierarchical relationships.

**Mathematical Definition**: A tree is a connected acyclic graph with n vertices and n-1 edges.

### Tree Terminology

#### Basic Terms
- **Root**: Top node (has no parent)
- **Leaf**: Node with no children
- **Parent**: Node with children
- **Child**: Node with a parent
- **Sibling**: Nodes with same parent
- **Ancestor**: Nodes on path from root to current node
- **Descendant**: Nodes in subtree of current node

#### Measurements
- **Height**: Longest path from node to leaf
- **Depth**: Distance from root to node
- **Level**: Depth + 1
- **Degree**: Number of children

### Tree Types

#### Binary Tree
- Each node has at most 2 children (left and right)
- Most common tree type in algorithms

#### Binary Search Tree (BST)
- Binary tree with ordering property:
  - Left subtree values < node value
  - Right subtree values > node value

#### Complete Binary Tree
- All levels filled except possibly the last
- Last level filled from left to right

#### Perfect Binary Tree
- All internal nodes have 2 children
- All leaves at same level

#### Balanced Tree
- Height difference between subtrees ≤ 1
- Examples: AVL, Red-Black trees

---

## Key Properties & Rules

### Binary Tree Properties

#### Node Count Relationships
- **Maximum nodes at level i**: 2^i
- **Maximum nodes in tree of height h**: 2^(h+1) - 1
- **Minimum height for n nodes**: ⌊log₂(n)⌋
- **Maximum height for n nodes**: n - 1

#### BST Properties
- **Inorder traversal**: Produces sorted sequence
- **Search/Insert/Delete**: O(h) where h is height
- **Best case height**: O(log n)
- **Worst case height**: O(n)

### Tree Representations

#### Node-based Representation
```python
class TreeNode:
    def __init__(self, val=0, left=None, right=None):
        self.val = val
        self.left = left
        self.right = right
```

#### Array Representation (Complete Trees)
```python
# For node at index i:
# Left child: 2*i + 1
# Right child: 2*i + 2
# Parent: (i-1) // 2
tree = [1, 2, 3, 4, 5, 6, 7]  # Level-order representation
```

---

## Patterns & Use Cases

### Core Tree Patterns

#### 1. Tree Traversal
**Depth-First Traversals**:
- **Preorder**: Root → Left → Right
- **Inorder**: Left → Root → Right  
- **Postorder**: Left → Right → Root

**Breadth-First Traversal**:
- **Level-order**: Visit nodes level by level

#### 2. Tree Construction
- Build tree from traversals
- Convert between tree representations
- Reconstruct from serialized data

#### 3. Tree Validation
- Check if valid BST
- Verify tree properties
- Balance validation

#### 4. Path Problems
- Root-to-leaf paths
- Path with target sum
- Maximum path sum

#### 5. Tree Modification
- Insertion and deletion
- Tree rotations
- Pruning and grafting

### Advanced Tree Structures

#### Segment Tree
**Use Cases**: Range queries and updates
**Time**: O(log n) query/update
**Space**: O(n)

#### Fenwick Tree (Binary Indexed Tree)
**Use Cases**: Prefix sum queries
**Time**: O(log n) query/update
**Space**: O(n)

#### Trie (Prefix Tree)
**Use Cases**: String storage and search
**Time**: O(m) where m is string length
**Space**: O(ALPHABET_SIZE * N * M)

---

## Step-by-Step Approaches

### Tree Problem-Solving Framework

1. **Identify Problem Type**:
   - Traversal problem?
   - Search problem?
   - Modification problem?
   - Path/sum problem?

2. **Choose Approach**:
   - Recursive (most common)
   - Iterative with stack/queue
   - Level-order with queue

3. **Define Base Cases**:
   - Empty tree (None)
   - Single node
   - Leaf node

4. **Handle Edge Cases**:
   - Null inputs
   - Single node trees
   - Unbalanced trees

### Generic Tree Template
```python
def solve_tree_problem(root):
    # Base case
    if not root:
        return base_case_value
    
    # Single node case (optional)
    if not root.left and not root.right:
        return leaf_case_value
    
    # Recursive case
    left_result = solve_tree_problem(root.left)
    right_result = solve_tree_problem(root.right)
    
    # Combine results
    return combine_results(root.val, left_result, right_result)
```

---

## Common Algorithms

### 1. Tree Traversals

#### Recursive Traversals
```python
def preorder(root, result=[]):
    if root:
        result.append(root.val)  # Visit root
        preorder(root.left, result)   # Left subtree
        preorder(root.right, result)  # Right subtree
    return result

def inorder(root, result=[]):
    if root:
        inorder(root.left, result)    # Left subtree
        result.append(root.val)  # Visit root
        inorder(root.right, result)   # Right subtree
    return result

def postorder(root, result=[]):
    if root:
        postorder(root.left, result)  # Left subtree
        postorder(root.right, result) # Right subtree
        result.append(root.val)  # Visit root
    return result
```

#### Iterative Traversals
```python
def preorder_iterative(root):
    if not root:
        return []
    
    result = []
    stack = [root]
    
    while stack:
        node = stack.pop()
        result.append(node.val)
        
        # Push right first, then left (stack is LIFO)
        if node.right:
            stack.append(node.right)
        if node.left:
            stack.append(node.left)
    
    return result

def inorder_iterative(root):
    result = []
    stack = []
    current = root
    
    while stack or current:
        # Go to leftmost node
        while current:
            stack.append(current)
            current = current.left
        
        # Current is None, pop from stack
        current = stack.pop()
        result.append(current.val)
        
        # Move to right subtree
        current = current.right
    
    return result

def level_order(root):
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

### 2. Binary Search Tree Operations

#### Search
```python
def search_bst(root, val):
    if not root or root.val == val:
        return root
    
    if val < root.val:
        return search_bst(root.left, val)
    else:
        return search_bst(root.right, val)

def search_bst_iterative(root, val):
    while root and root.val != val:
        if val < root.val:
            root = root.left
        else:
            root = root.right
    return root
```

#### Insert
```python
def insert_bst(root, val):
    if not root:
        return TreeNode(val)
    
    if val < root.val:
        root.left = insert_bst(root.left, val)
    else:
        root.right = insert_bst(root.right, val)
    
    return root
```

#### Delete
```python
def delete_bst(root, val):
    if not root:
        return root
    
    if val < root.val:
        root.left = delete_bst(root.left, val)
    elif val > root.val:
        root.right = delete_bst(root.right, val)
    else:
        # Node to delete found
        if not root.left:
            return root.right
        elif not root.right:
            return root.left
        
        # Node has two children
        # Find inorder successor (smallest in right subtree)
        min_node = find_min(root.right)
        root.val = min_node.val
        root.right = delete_bst(root.right, min_node.val)
    
    return root

def find_min(root):
    while root.left:
        root = root.left
    return root
```

### 3. Tree Properties

#### Height and Depth
```python
def max_depth(root):
    if not root:
        return 0
    return 1 + max(max_depth(root.left), max_depth(root.right))

def min_depth(root):
    if not root:
        return 0
    
    if not root.left and not root.right:
        return 1
    
    if not root.left:
        return 1 + min_depth(root.right)
    if not root.right:
        return 1 + min_depth(root.left)
    
    return 1 + min(min_depth(root.left), min_depth(root.right))
```

#### Balance Check
```python
def is_balanced(root):
    def check_balance(node):
        if not node:
            return 0, True
        
        left_height, left_balanced = check_balance(node.left)
        if not left_balanced:
            return 0, False
        
        right_height, right_balanced = check_balance(node.right)
        if not right_balanced:
            return 0, False
        
        balanced = abs(left_height - right_height) <= 1
        height = 1 + max(left_height, right_height)
        
        return height, balanced
    
    _, balanced = check_balance(root)
    return balanced
```

### 4. Path Problems

#### Path Sum
```python
def has_path_sum(root, target_sum):
    if not root:
        return False
    
    if not root.left and not root.right:
        return root.val == target_sum
    
    remaining = target_sum - root.val
    return (has_path_sum(root.left, remaining) or 
            has_path_sum(root.right, remaining))

def path_sum_all_paths(root, target_sum):
    def dfs(node, current_path, remaining):
        if not node:
            return
        
        current_path.append(node.val)
        
        if not node.left and not node.right and remaining == node.val:
            result.append(current_path[:])
        else:
            dfs(node.left, current_path, remaining - node.val)
            dfs(node.right, current_path, remaining - node.val)
        
        current_path.pop()  # Backtrack
    
    result = []
    dfs(root, [], target_sum)
    return result
```

#### Maximum Path Sum
```python
def max_path_sum(root):
    def max_gain(node):
        nonlocal max_sum
        if not node:
            return 0
        
        # Maximum gain from left and right subtrees
        left_gain = max(max_gain(node.left), 0)
        right_gain = max(max_gain(node.right), 0)
        
        # Price of new path through current node
        price_new_path = node.val + left_gain + right_gain
        max_sum = max(max_sum, price_new_path)
        
        # Return max gain if we continue path through this node
        return node.val + max(left_gain, right_gain)
    
    max_sum = float('-inf')
    max_gain(root)
    return max_sum
```

### 5. Lowest Common Ancestor (LCA)

#### LCA in BST
```python
def lca_bst(root, p, q):
    if not root:
        return None
    
    if p.val < root.val and q.val < root.val:
        return lca_bst(root.left, p, q)
    elif p.val > root.val and q.val > root.val:
        return lca_bst(root.right, p, q)
    else:
        return root
```

#### LCA in Binary Tree
```python
def lca_binary_tree(root, p, q):
    if not root or root == p or root == q:
        return root
    
    left = lca_binary_tree(root.left, p, q)
    right = lca_binary_tree(root.right, p, q)
    
    if left and right:
        return root
    
    return left or right
```

---

## Edge Cases

### Critical Edge Cases
1. **Empty Tree**: Root is None
2. **Single Node**: Tree with only root
3. **Linear Tree**: Essentially a linked list
4. **Complete vs Incomplete**: Affects array representation
5. **Duplicate Values**: Affects BST operations

### BST-Specific Edge Cases
1. **Invalid BST**: Violates ordering property
2. **Deletion Edge Cases**: Node with 0, 1, or 2 children
3. **Insertion in Empty Tree**: Creating root

---

## Complexity Analysis

### Time Complexity Summary

| Operation | BST (Average) | BST (Worst) | Balanced Tree |
|-----------|---------------|-------------|---------------|
| Search | O(log n) | O(n) | O(log n) |
| Insert | O(log n) | O(n) | O(log n) |
| Delete | O(log n) | O(n) | O(log n) |
| Traversal | O(n) | O(n) | O(n) |

### Space Complexity
- **Recursive algorithms**: O(h) where h is height
- **Iterative with stack**: O(h)
- **Level-order traversal**: O(w) where w is maximum width
- **Tree storage**: O(n)

---

## Problem Categories

### 1. **Tree Traversal**
- Binary Tree Inorder Traversal
- Binary Tree Level Order Traversal
- Binary Tree Zigzag Level Order

### 2. **Tree Construction**
- Construct Binary Tree from Preorder and Inorder
- Convert Sorted Array to BST
- Serialize and Deserialize Binary Tree

### 3. **Tree Validation**
- Validate Binary Search Tree
- Same Tree
- Symmetric Tree

### 4. **Path Problems**
- Path Sum
- Binary Tree Maximum Path Sum
- Sum Root to Leaf Numbers

### 5. **BST Operations**
- Search in BST
- Insert into BST
- Delete Node in BST

---

## Pro Tips & Interview Tricks

### Problem Recognition
```
Hierarchical Data → Tree Structure
Ordered Data → BST
Level-by-level Processing → BFS
Path-related Problems → DFS
Range Queries → Segment Tree
```

### Implementation Strategies

1. **Recursive Approach** (Most Common):
   - Natural for tree problems
   - Base case: null node
   - Recursive case: process subtrees

2. **Iterative Approach**:
   - Use stack for DFS
   - Use queue for BFS
   - Better space complexity sometimes

### Common Patterns

#### Tree DP Pattern
```python
def tree_dp(root):
    if not root:
        return base_case
    
    left_result = tree_dp(root.left)
    right_result = tree_dp(root.right)
    
    # Use left_result and right_result to compute current result
    current_result = combine(root.val, left_result, right_result)
    
    # Update global state if needed
    update_global_state(current_result)
    
    return current_result
```

#### Tree Validation Pattern
```python
def validate_tree(root, min_val=float('-inf'), max_val=float('inf')):
    if not root:
        return True
    
    if root.val <= min_val or root.val >= max_val:
        return False
    
    return (validate_tree(root.left, min_val, root.val) and
            validate_tree(root.right, root.val, max_val))
```

### Debugging Tips

1. **Visualize the Tree**: Draw small examples
2. **Check Base Cases**: Handle null nodes properly
3. **Trace Recursion**: Follow the recursive calls
4. **Test Edge Cases**: Empty tree, single node, linear tree

### Interview-Specific Advice

1. **Clarify Tree Type**: Binary tree? BST? Balanced?
2. **Ask About Duplicates**: How to handle duplicate values?
3. **Discuss Approach**: Recursive vs iterative
4. **Consider Space Optimization**: Can we reduce space complexity?
5. **Handle Edge Cases**: Always check for null inputs

---

## Conclusion

Trees are fundamental hierarchical data structures with wide applications in computer science. Key mastery points:

1. **Tree Traversals**: Master all four traversal methods
2. **BST Operations**: Understand search, insert, delete
3. **Recursive Thinking**: Most tree problems are naturally recursive
4. **Edge Cases**: Always handle null nodes and empty trees
5. **Complexity Analysis**: Understand height vs node count relationship

**Success Formula**: Recursive thinking + Base case handling + Edge case consideration = Tree mastery

Practice these patterns and you'll solve most tree problems with confidence!