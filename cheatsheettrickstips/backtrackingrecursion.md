# Backtracking Recursion - Comprehensive Cheatsheet

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

### What is Backtracking?

Backtracking is a general algorithmic approach that incrementally builds candidates to the solutions of a computational problem and abandons candidates ("backtracks") as soon as it determines they cannot possibly be extended to a valid solution. Think of backtracking as exploring a maze - you try a path, and if it leads to a dead end, you backtrack to the last decision point and try a different direction.

**Key Characteristics:**
- **Incremental Construction**: Builds solutions step by step
- **Constraint Checking**: Validates constraints at each step
- **Backtracking**: Undoes choices when they lead to invalid states
- **Exhaustive Search**: Systematically explores all possibilities
- **Pruning**: Eliminates branches that cannot lead to valid solutions

### Real-World Analogies

1. **Maze Navigation**: Try a path, backtrack when hitting a dead end
2. **Chess Game**: Consider a move, analyze consequences, undo if poor
3. **Sudoku Solving**: Fill a cell, check validity, erase if conflicts arise
4. **Trial and Error Learning**: Try an approach, learn from mistakes, try differently

### Recursive Foundation

Backtracking is fundamentally built on recursion, where:
- **Base Case**: Solution is complete or impossible
- **Recursive Case**: Make a choice and recurse
- **Backtrack**: Undo the choice before trying the next option

### Mathematical Foundation

Backtracking can be viewed as a depth-first search on an implicit state space tree where:
- **Nodes**: Represent partial solutions
- **Edges**: Represent choices or decisions
- **Leaves**: Represent complete solutions or dead ends
- **Pruning**: Eliminates subtrees that cannot contain valid solutions

**State Space Representation:**
```
        Root (empty solution)
       /    |    |    \
    Choice1 Choice2 ... ChoiceN
    /  |  \  /  |  \     / | \
   ...     ...        ...
```

### Historical Context

Backtracking has deep roots in mathematics and computer science:

**Timeline:**
- **1950s**: Early formalization in constraint satisfaction
- **1960s**: Systematic study by Golomb and Baumert
- **1970s**: Application to combinatorial optimization
- **1980s**: Integration with artificial intelligence
- **1990s**: Constraint programming and CSP solvers
- **2000s**: Modern applications in SAT solvers and model checking

**Notable Contributions:**
- **D.H. Lehmer (1950s)**: Early applications to number theory
- **Solomon Golomb (1965)**: Formal analysis of backtracking
- **Robert Floyd (1967)**: Algorithm design principles
- **Donald Knuth (2000s)**: Dancing Links and exact cover problems

### Core Philosophy

Backtracking embodies the principle of **"intelligent brute force"** - it exhaustively searches the solution space but uses constraints and pruning to avoid exploring impossible paths. This makes it much more efficient than naive enumeration while still guaranteeing completeness.

---

## Key Properties & Rules

### Fundamental Properties

#### 1. **Systematic Exploration**
- Explores solution space in a depth-first manner
- Guarantees finding all solutions (if they exist)
- Maintains order in solution enumeration

#### 2. **Constraint Propagation**
- Checks constraints incrementally during construction
- Prunes invalid branches early to save computation
- Maintains problem invariants throughout the search

#### 3. **State Reversibility**
- All changes made during recursion must be undoable
- State is restored to previous condition after backtracking
- Enables exploration of alternative paths

#### 4. **Decision Tree Structure**
- Each recursive call represents a decision point
- Branches represent different choices available
- Leaves represent complete solutions or failures

### Essential Rules for Implementation

#### Rule 1: **Clear Base Cases**
```python
def backtrack(current_state):
    # Base case: solution is complete
    if is_complete(current_state):
        if is_valid(current_state):
            record_solution(current_state)
        return
    
    # Base case: impossible to continue
    if is_impossible(current_state):
        return
    
    # Recursive case continues below...
```

#### Rule 2: **Systematic Choice Enumeration**
```python
def backtrack(current_state):
    # ... base cases ...
    
    for choice in get_valid_choices(current_state):
        # Make the choice
        make_choice(current_state, choice)
        
        # Recurse with the new state
        backtrack(current_state)
        
        # Undo the choice (backtrack)
        undo_choice(current_state, choice)
```

#### Rule 3: **Early Pruning**
```python
def backtrack(current_state):
    # Prune if current state violates constraints
    if violates_constraints(current_state):
        return
    
    # Prune if impossible to reach solution
    if cannot_reach_solution(current_state):
        return
    
    # Continue with normal backtracking...
```

#### Rule 4: **State Management**
```python
# Approach 1: Modify and restore state
def backtrack(state):
    if base_case(state):
        return
    
    for choice in choices:
        state.add(choice)      # Modify state
        backtrack(state)       # Recurse
        state.remove(choice)   # Restore state

# Approach 2: Pass new state (immutable approach)
def backtrack(state):
    if base_case(state):
        return
    
    for choice in choices:
        new_state = state.copy()
        new_state.add(choice)
        backtrack(new_state)   # State naturally restored
```

### Mathematical Properties

#### **Completeness**
Backtracking is complete - it will find a solution if one exists:
- **Theorem**: If the search space is finite and there exists a solution, backtracking will find it
- **Proof**: By exhaustive depth-first exploration of all possible paths

#### **Optimality**
Backtracking finds optimal solutions when combined with appropriate strategies:
- **Branch and Bound**: Prune suboptimal branches
- **Best-First**: Explore most promising branches first
- **A* Integration**: Use heuristics to guide search

#### **Space Complexity Bounds**
- **Worst Case**: O(maximum_depth) for recursion stack
- **Average Case**: Depends on pruning effectiveness
- **Best Case**: O(1) if solution found immediately

#### **Time Complexity Bounds**
- **Upper Bound**: O(b^d) where b = branching factor, d = depth
- **Practical Bound**: Much better with effective pruning
- **Exponential Nature**: Inherently exponential for NP-complete problems

### Constraint Satisfaction Framework

Backtracking naturally handles constraint satisfaction problems (CSPs):

**CSP Components:**
- **Variables**: What we're trying to assign values to
- **Domain**: Possible values for each variable
- **Constraints**: Rules that valid assignments must satisfy

**Constraint Types:**
- **Unary Constraints**: Involve single variables
- **Binary Constraints**: Involve pairs of variables
- **Global Constraints**: Involve multiple variables

```python
class CSP:
    def __init__(self, variables, domains, constraints):
        self.variables = variables
        self.domains = domains
        self.constraints = constraints
    
    def is_consistent(self, assignment, var, value):
        """Check if assigning value to var is consistent with current assignment"""
        test_assignment = assignment.copy()
        test_assignment[var] = value
        
        for constraint in self.constraints:
            if not constraint.satisfied(test_assignment):
                return False
        return True
```

### Pruning Strategies

#### **Forward Checking**
- Check constraints as soon as values are assigned
- Eliminate values from future variables that would conflict

#### **Arc Consistency**
- Ensure every value in domain has at least one compatible value in related domains
- Reduces domain sizes before backtracking

#### **Constraint Propagation**
- Use constraint relationships to infer additional restrictions
- Can dramatically reduce search space

```python
def forward_checking_backtrack(assignment, csp):
    if len(assignment) == len(csp.variables):
        return assignment
    
    var = select_unassigned_variable(assignment, csp)
    
    for value in order_domain_values(var, assignment, csp):
        if csp.is_consistent(assignment, var, value):
            assignment[var] = value
            
            # Forward checking: remove inconsistent values
            removals = inference(csp, var, value, assignment)
            
            if removals is not None:
                result = forward_checking_backtrack(assignment, csp)
                if result is not None:
                    return result
            
            # Restore removed values
            restore(csp, removals)
            del assignment[var]
    
    return None
```

---

## Patterns & Use Cases

### Core Backtracking Patterns

#### 1. **Subset Generation Pattern**

**When to Use:**
- Generate all possible subsets or combinations
- Problems involving selection of items
- Optimization problems with discrete choices

**Pattern Structure:**
```python
def generate_subsets(arr, current_subset=[], start_index=0):
    # Base case: processed all elements
    if start_index == len(arr):
        process_subset(current_subset.copy())
        return
    
    # Choice 1: Include current element
    current_subset.append(arr[start_index])
    generate_subsets(arr, current_subset, start_index + 1)
    current_subset.pop()  # Backtrack
    
    # Choice 2: Exclude current element
    generate_subsets(arr, current_subset, start_index + 1)
```

**Applications:**
- Subset sum problems
- Knapsack variations
- Feature selection in machine learning
- Portfolio optimization

#### 2. **Permutation Generation Pattern**

**When to Use:**
- Generate all arrangements of elements
- Sequence-dependent problems
- Ordering and scheduling problems

**Pattern Structure:**
```python
def generate_permutations(arr, current_perm=[], used=None):
    if used is None:
        used = [False] * len(arr)
    
    # Base case: permutation is complete
    if len(current_perm) == len(arr):
        process_permutation(current_perm.copy())
        return
    
    # Try each unused element
    for i in range(len(arr)):
        if not used[i]:
            # Make choice
            current_perm.append(arr[i])
            used[i] = True
            
            # Recurse
            generate_permutations(arr, current_perm, used)
            
            # Backtrack
            current_perm.pop()
            used[i] = False
```

**Applications:**
- Traveling salesman problem
- Task scheduling
- String anagram generation
- Sequence optimization

#### 3. **Grid/Board Exploration Pattern**

**When to Use:**
- Problems on 2D grids or boards
- Path finding with constraints
- Placement problems

**Pattern Structure:**
```python
def explore_grid(grid, row, col, visited=None):
    if visited is None:
        visited = set()
    
    # Base cases
    if not is_valid_position(row, col, grid):
        return False
    
    if (row, col) in visited:
        return False
    
    if is_target_reached(row, col, grid):
        return True
    
    # Mark as visited
    visited.add((row, col))
    
    # Explore all directions
    directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]
    for dr, dc in directions:
        new_row, new_col = row + dr, col + dc
        if explore_grid(grid, new_row, new_col, visited):
            return True
    
    # Backtrack
    visited.remove((row, col))
    return False
```

**Applications:**
- N-Queens problem
- Sudoku solving
- Maze solving
- Word search in grids

#### 4. **Tree Construction Pattern**

**When to Use:**
- Building tree structures with constraints
- Generating valid parse trees
- Expression evaluation

**Pattern Structure:**
```python
def build_tree(nodes, current_tree, constraints):
    # Base case: tree is complete
    if is_complete_tree(current_tree):
        if satisfies_all_constraints(current_tree, constraints):
            process_tree(current_tree.copy())
        return
    
    # Try adding each available node
    for node in get_available_nodes(nodes, current_tree):
        if can_add_node(current_tree, node, constraints):
            # Add node
            current_tree.add_node(node)
            
            # Recurse
            build_tree(nodes, current_tree, constraints)
            
            # Backtrack
            current_tree.remove_node(node)
```

**Applications:**
- Binary tree construction
- Decision tree building
- Parse tree generation
- Game tree exploration

#### 5. **Partition Pattern**

**When to Use:**
- Dividing sets into groups with constraints
- Load balancing problems
- Resource allocation

**Pattern Structure:**
```python
def partition_set(elements, groups, current_partition, target_criteria):
    # Base case: all elements assigned
    if not elements:
        if meets_criteria(current_partition, target_criteria):
            process_partition(current_partition.copy())
        return
    
    element = elements[0]
    remaining = elements[1:]
    
    # Try adding element to each existing group
    for i, group in enumerate(current_partition):
        if can_add_to_group(element, group, target_criteria):
            group.append(element)
            partition_set(remaining, groups, current_partition, target_criteria)
            group.pop()  # Backtrack
    
    # Try creating new group (if allowed)
    if len(current_partition) < groups:
        current_partition.append([element])
        partition_set(remaining, groups, current_partition, target_criteria)
        current_partition.pop()  # Backtrack
```

**Applications:**
- Bin packing
- Team formation
- Graph coloring
- Resource scheduling

### Advanced Patterns

#### 6. **Branch and Bound Integration**

**When to Use:**
- Optimization problems where you need the best solution
- Problems with measurable solution quality
- Large search spaces requiring pruning

**Pattern Structure:**
```python
def branch_and_bound_backtrack(state, current_cost, best_solution, best_cost):
    # Pruning: if current cost already exceeds best, abandon
    if current_cost >= best_cost[0]:
        return
    
    # Base case: solution complete
    if is_complete(state):
        if current_cost < best_cost[0]:
            best_cost[0] = current_cost
            best_solution[:] = state.copy()
        return
    
    # Branch on choices, ordered by estimated promise
    for choice in get_ordered_choices(state):
        estimated_cost = estimate_total_cost(state, choice)
        
        # Bound: skip if estimated cost exceeds current best
        if estimated_cost >= best_cost[0]:
            continue
        
        # Make choice and recurse
        new_state = make_choice(state, choice)
        new_cost = current_cost + get_choice_cost(choice)
        
        branch_and_bound_backtrack(new_state, new_cost, best_solution, best_cost)
```

#### 7. **Memoization Integration**

**When to Use:**
- Overlapping subproblems in the search space
- Expensive state validation
- Repeated computation of same states

**Pattern Structure:**
```python
def memoized_backtrack(state, memo=None):
    if memo is None:
        memo = {}
    
    # Check memo for previously computed result
    state_key = get_state_key(state)
    if state_key in memo:
        return memo[state_key]
    
    # Base cases
    if is_complete(state):
        result = evaluate_solution(state)
        memo[state_key] = result
        return result
    
    best_result = None
    for choice in get_choices(state):
        new_state = make_choice(state, choice)
        result = memoized_backtrack(new_state, memo)
        
        if is_better(result, best_result):
            best_result = result
    
    memo[state_key] = best_result
    return best_result
```

### Pattern Selection Guidelines

#### **Choose Subset Generation When:**
- Problem asks for all possible selections
- Working with power sets
- Optimization over binary choices

#### **Choose Permutation Generation When:**
- Order matters in the solution
- Working with arrangements
- Sequence-dependent constraints

#### **Choose Grid Exploration When:**
- Working on 2D/3D spaces
- Path-finding problems
- Spatial constraint satisfaction

#### **Choose Tree Construction When:**
- Building hierarchical structures
- Expression parsing
- Recursive data structure creation

#### **Choose Partition Pattern When:**
- Grouping elements with constraints
- Load distribution problems
- Classification tasks

---

## Step-by-Step Approaches

### General Backtracking Framework

#### Step 1: **Problem Analysis and Modeling**

**1.1 Identify the Search Space**
- What are the decision variables?
- What values can each variable take?
- What is the size of the complete solution?

**1.2 Define Constraints**
- What rules must valid solutions satisfy?
- Can constraints be checked incrementally?
- Are there implicit constraints from the problem domain?

**1.3 Determine Solution Criteria**
- What constitutes a complete solution?
- Are you looking for all solutions or just one?
- Is there an optimization objective?

#### Step 2: **Design the State Representation**

**2.1 Choose Data Structures**
```python
# Example: N-Queens problem
class NQueensState:
    def __init__(self, n):
        self.n = n
        self.queens = []  # List of (row, col) positions
        self.cols_used = set()  # Track used columns
        self.diag1_used = set()  # Track used diagonal (row - col)
        self.diag2_used = set()  # Track used diagonal (row + col)
    
    def can_place_queen(self, row, col):
        return (col not in self.cols_used and
                (row - col) not in self.diag1_used and
                (row + col) not in self.diag2_used)
    
    def place_queen(self, row, col):
        self.queens.append((row, col))
        self.cols_used.add(col)
        self.diag1_used.add(row - col)
        self.diag2_used.add(row + col)
    
    def remove_queen(self):
        if self.queens:
            row, col = self.queens.pop()
            self.cols_used.remove(col)
            self.diag1_used.remove(row - col)
            self.diag2_used.remove(row + col)
```

**2.2 Ensure Efficient Operations**
- State copying should be efficient (or avoided)
- Constraint checking should be O(1) when possible
- Undo operations must completely restore previous state

#### Step 3: **Implement Base Cases**

**3.1 Success Condition**
```python
def is_solution_complete(state):
    """Check if we have a complete, valid solution"""
    return (len(state.queens) == state.n and 
            all_constraints_satisfied(state))

def is_solution_impossible(state):
    """Check if current state cannot lead to any solution"""
    return (constraint_violation_detected(state) or
            insufficient_choices_remaining(state))
```

**3.2 Early Termination Conditions**
```python
def should_prune_branch(state):
    """Determine if current branch should be abandoned"""
    # Check if current state violates any constraints
    if violates_hard_constraints(state):
        return True
    
    # Check if remaining space cannot accommodate solution
    if cannot_complete_solution(state):
        return True
    
    # For optimization: check if current path cannot beat best known
    if has_optimization_objective(state):
        return current_bound(state) >= best_known_value
    
    return False
```

#### Step 4: **Design Choice Generation**

**4.1 Systematic Choice Enumeration**
```python
def get_next_choices(state):
    """Generate all valid next choices from current state"""
    choices = []
    
    # Determine next decision point
    next_position = get_next_decision_point(state)
    
    # Generate all possible values for this decision
    for value in get_domain_values(next_position, state):
        if is_locally_consistent(state, next_position, value):
            choices.append((next_position, value))
    
    return choices

def order_choices_by_heuristic(choices, state):
    """Order choices to improve search efficiency"""
    # Most constrained variable first
    # Least constraining value first
    # Other domain-specific heuristics
    return sorted(choices, key=lambda c: choice_promise(c, state))
```

**4.2 Choice Validation**
```python
def is_valid_choice(state, choice):
    """Validate that a choice doesn't immediately violate constraints"""
    # Check local constraints
    if violates_local_constraints(state, choice):
        return False
    
    # Check global constraints that can be verified early
    if violates_early_global_constraints(state, choice):
        return False
    
    return True
```

#### Step 5: **Implement State Transitions**

**5.1 Making Choices**
```python
def make_choice(state, choice):
    """Apply choice to state - must be reversible"""
    position, value = choice
    
    # Record change for potential undo
    old_value = state.get_value(position)
    state.change_log.append((position, old_value))
    
    # Apply the choice
    state.set_value(position, value)
    
    # Update auxiliary data structures
    state.update_constraints(position, value)
    
    return state

def undo_choice(state):
    """Reverse the most recent choice"""
    if state.change_log:
        position, old_value = state.change_log.pop()
        state.set_value(position, old_value)
        state.restore_constraints(position, old_value)
```

**5.2 Template Implementation**
```python
def backtrack(state):
    """Generic backtracking template"""
    # Base cases
    if is_solution_complete(state):
        process_solution(state)
        return True  # or False for find-all problems
    
    if should_prune_branch(state):
        return False
    
    # Try each possible choice
    for choice in get_next_choices(state):
        if is_valid_choice(state, choice):
            # Make choice
            make_choice(state, choice)
            
            # Recurse
            if backtrack(state):
                return True  # Found solution (for find-first)
            
            # Backtrack
            undo_choice(state)
    
    return False  # No solution found in this branch
```

---

## Common Algorithms

### 1. **N-Queens Problem**

```python
def solve_n_queens(n):
    def is_safe(board, row, col):
        # Check column
        for i in range(row):
            if board[i] == col:
                return False
        
        # Check diagonals
        for i in range(row):
            if abs(board[i] - col) == abs(i - row):
                return False
        
        return True
    
    def backtrack(board, row):
        if row == n:
            solutions.append(board[:])
            return
        
        for col in range(n):
            if is_safe(board, row, col):
                board[row] = col
                backtrack(board, row + 1)
                # board[row] is automatically overwritten
    
    solutions = []
    board = [-1] * n
    backtrack(board, 0)
    return solutions
```

### 2. **Sudoku Solver**

```python
def solve_sudoku(board):
    def is_valid(board, row, col, num):
        # Check row
        for j in range(9):
            if board[row][j] == num:
                return False
        
        # Check column
        for i in range(9):
            if board[i][col] == num:
                return False
        
        # Check 3x3 box
        start_row, start_col = 3 * (row // 3), 3 * (col // 3)
        for i in range(start_row, start_row + 3):
            for j in range(start_col, start_col + 3):
                if board[i][j] == num:
                    return False
        
        return True
    
    def backtrack():
        for i in range(9):
            for j in range(9):
                if board[i][j] == 0:
                    for num in range(1, 10):
                        if is_valid(board, i, j, num):
                            board[i][j] = num
                            if backtrack():
                                return True
                            board[i][j] = 0
                    return False
        return True
    
    return backtrack()
```

### 3. **Generate Parentheses**

```python
def generate_parentheses(n):
    def backtrack(current, open_count, close_count):
        if len(current) == 2 * n:
            result.append(current)
            return
        
        if open_count < n:
            backtrack(current + '(', open_count + 1, close_count)
        
        if close_count < open_count:
            backtrack(current + ')', open_count, close_count + 1)
    
    result = []
    backtrack('', 0, 0)
    return result
```

### 4. **Word Search**

```python
def word_search(board, word):
    def backtrack(row, col, index):
        if index == len(word):
            return True
        
        if (row < 0 or row >= len(board) or 
            col < 0 or col >= len(board[0]) or 
            board[row][col] != word[index]):
            return False
        
        # Mark as visited
        temp = board[row][col]
        board[row][col] = '#'
        
        # Explore neighbors
        found = (backtrack(row + 1, col, index + 1) or
                backtrack(row - 1, col, index + 1) or
                backtrack(row, col + 1, index + 1) or
                backtrack(row, col - 1, index + 1))
        
        # Restore
        board[row][col] = temp
        return found
    
    for i in range(len(board)):
        for j in range(len(board[0])):
            if backtrack(i, j, 0):
                return True
    return False
```

---

## Complexity Analysis

### Time Complexity

**General Formula**: O(b^d)
- b = branching factor (choices per level)
- d = maximum depth

**Specific Problems**:
- N-Queens: O(N!)
- Sudoku: O(9^(empty_cells))
- Subset generation: O(2^n)
- Permutations: O(n!)

### Space Complexity

**Recursion Stack**: O(d) where d is maximum depth
**Additional Storage**: Depends on state representation

**Optimization Techniques**:
- Constraint propagation
- Heuristic ordering
- Memoization for overlapping subproblems

---

## Example Problems

### Problem 1: **Combination Sum**

```python
def combination_sum(candidates, target):
    def backtrack(start, current_combination, remaining):
        if remaining == 0:
            result.append(current_combination[:])
            return
        
        for i in range(start, len(candidates)):
            if candidates[i] <= remaining:
                current_combination.append(candidates[i])
                backtrack(i, current_combination, remaining - candidates[i])
                current_combination.pop()
    
    result = []
    candidates.sort()
    backtrack(0, [], target)
    return result
```

### Problem 2: **Palindrome Partitioning**

```python
def partition_palindromes(s):
    def is_palindrome(string):
        return string == string[::-1]
    
    def backtrack(start, current_partition):
        if start == len(s):
            result.append(current_partition[:])
            return
        
        for end in range(start + 1, len(s) + 1):
            substring = s[start:end]
            if is_palindrome(substring):
                current_partition.append(substring)
                backtrack(end, current_partition)
                current_partition.pop()
    
    result = []
    backtrack(0, [])
    return result
```

---

## Problem Categories

### 1. **Constraint Satisfaction**
- N-Queens, Sudoku
- Graph coloring
- Course scheduling

### 2. **Combinatorial Generation**
- Subsets, permutations, combinations
- Parentheses generation
- Phone number combinations

### 3. **Path Finding**
- Word search
- Maze solving
- Knight's tour

### 4. **Optimization**
- Traveling salesman
- Knapsack variants
- Job scheduling

---

## Pro Tips & Interview Tricks

### Essential Tips

#### 1. **Template Recognition**
```python
# Standard backtracking template
def backtrack(state):
    if is_complete(state):
        process_solution(state)
        return
    
    for choice in get_choices(state):
        if is_valid(choice):
            make_choice(state, choice)
            backtrack(state)
            undo_choice(state, choice)
```

#### 2. **State Management Strategies**

**Approach 1: Modify and Restore**
```python
# Efficient but requires careful undo
state.add(item)
backtrack(state)
state.remove(item)
```

**Approach 2: Copy State**
```python
# Safer but potentially expensive
new_state = state.copy()
new_state.add(item)
backtrack(new_state)
```

#### 3. **Optimization Techniques**

**Early Pruning**:
```python
if current_cost > best_known:
    return  # Prune this branch
```

**Constraint Ordering**:
```python
# Choose most constrained variable first
variable = min(unassigned, key=lambda v: len(get_domain(v)))
```

**Value Ordering**:
```python
# Try least constraining values first
values = sorted(domain, key=lambda v: count_conflicts(v))
```

#### 4. **Common Patterns**

**Generate All Solutions**:
```python
def find_all_solutions(state, solutions):
    if is_complete(state):
        solutions.append(state.copy())
        return
    # Continue backtracking...
```

**Find First Solution**:
```python
def find_first_solution(state):
    if is_complete(state):
        return True
    
    for choice in get_choices(state):
        make_choice(state, choice)
        if find_first_solution(state):
            return True
        undo_choice(state, choice)
    
    return False
```

**Count Solutions**:
```python
def count_solutions(state):
    if is_complete(state):
        return 1
    
    count = 0
    for choice in get_choices(state):
        make_choice(state, choice)
        count += count_solutions(state)
        undo_choice(state, choice)
    
    return count
```

### Interview Success Strategies

1. **Start with brute force**: Get the basic backtracking working first
2. **Identify constraints**: Clearly state what makes a solution valid
3. **Optimize incrementally**: Add pruning and heuristics step by step
4. **Handle edge cases**: Empty input, impossible solutions, single element
5. **Analyze complexity**: Be prepared to discuss time and space complexity
6. **Test thoroughly**: Walk through examples and edge cases

### Common Mistakes to Avoid

1. **Forgetting to backtrack**: Always undo changes before trying next option
2. **Incorrect base cases**: Ensure all termination conditions are covered
3. **State pollution**: Make sure state is properly restored after recursion
4. **Inefficient constraint checking**: Check constraints as early as possible
5. **Missing pruning opportunities**: Identify when branches can be eliminated

This comprehensive guide provides the foundation for mastering backtracking and recursion in algorithmic problem-solving. The key is understanding the systematic exploration pattern and applying appropriate optimizations for specific problem domains.