# Dynamic Programming - Comprehensive Cheatsheet

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

### What is Dynamic Programming?

Dynamic Programming (DP) is an algorithmic paradigm that solves complex problems by breaking them down into simpler subproblems and storing their solutions to avoid redundant computation. Think of DP as "smart recursion with memory" - instead of recalculating the same subproblems repeatedly, we remember their solutions.

**Core Philosophy**: "Those who cannot remember the past are condemned to repeat it." DP embodies this by remembering solutions to subproblems.

### The Two Pillars of DP

#### 1. Optimal Substructure
An optimal solution to a problem contains optimal solutions to its subproblems.

#### 2. Overlapping Subproblems
The same subproblems appear multiple times in the recursive decomposition.

### DP vs Other Paradigms

| Paradigm | When to Use | Example |
|----------|-------------|----------|
| Greedy | Local optimal → Global optimal | Huffman Coding |
| Divide & Conquer | Non-overlapping subproblems | Merge Sort |
| Dynamic Programming | Overlapping subproblems | Fibonacci |

---

## Key Properties & Rules

### State Definition
The foundation of any DP solution is a clear state definition:
- **Complete**: Captures all information needed
- **Minimal**: No redundant information
- **Unique**: Each subproblem has unique state
- **Bounded**: Finite number of states

### Approaches

#### Top-Down (Memoization)
```python
def fibonacci_memo(n, memo={}):
    if n in memo:
        return memo[n]
    if n <= 1:
        return n
    memo[n] = fibonacci_memo(n-1, memo) + fibonacci_memo(n-2, memo)
    return memo[n]
```

#### Bottom-Up (Tabulation)
```python
def fibonacci_tab(n):
    if n <= 1:
        return n
    dp = [0] * (n + 1)
    dp[0], dp[1] = 0, 1
    for i in range(2, n + 1):
        dp[i] = dp[i-1] + dp[i-2]
    return dp[n]
```

---

## Patterns & Use Cases

### 1. Linear DP
**Pattern**: `dp[i]` depends on previous positions
**Examples**: Climbing Stairs, House Robber, Maximum Subarray

### 2. Grid DP
**Pattern**: `dp[i][j]` depends on adjacent cells
**Examples**: Unique Paths, Minimum Path Sum, Edit Distance

### 3. Knapsack DP
**Pattern**: Resource allocation with constraints
**Examples**: 0/1 Knapsack, Subset Sum, Coin Change

### 4. String DP
**Pattern**: String manipulation and matching
**Examples**: LCS, Edit Distance, Palindrome Problems

### 5. Interval DP
**Pattern**: Optimal solution for ranges [i,j]
**Examples**: Matrix Chain Multiplication, Palindrome Partitioning

---

## Step-by-Step Approaches

### Universal DP Framework

1. **Identify DP Problem**:
   - Optimization (max/min)?
   - Counting (number of ways)?
   - Decision (possible/impossible)?

2. **Define State**:
   - What variables change?
   - What does dp[state] represent?

3. **Find Base Cases**:
   - Smallest subproblems
   - Boundary conditions

4. **Derive Recurrence**:
   - How to combine subproblems?
   - What choices exist at each state?

5. **Implement**:
   - Choose top-down or bottom-up
   - Consider space optimization

---

## Common Algorithms

### 1. Climbing Stairs
```python
def climb_stairs(n):
    if n <= 2:
        return n
    prev2, prev1 = 1, 2
    for i in range(3, n + 1):
        current = prev1 + prev2
        prev2, prev1 = prev1, current
    return prev1
```

### 2. House Robber
```python
def rob(nums):
    if not nums:
        return 0
    if len(nums) == 1:
        return nums[0]
    
    prev2, prev1 = nums[0], max(nums[0], nums[1])
    
    for i in range(2, len(nums)):
        current = max(prev1, prev2 + nums[i])
        prev2, prev1 = prev1, current
    
    return prev1
```

### 3. Coin Change
```python
def coin_change(coins, amount):
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    
    for coin in coins:
        for i in range(coin, amount + 1):
            dp[i] = min(dp[i], dp[i - coin] + 1)
    
    return dp[amount] if dp[amount] != float('inf') else -1
```

### 4. Longest Common Subsequence
```python
def lcs(text1, text2):
    m, n = len(text1), len(text2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if text1[i-1] == text2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    return dp[m][n]
```

### 5. Edit Distance
```python
def edit_distance(word1, word2):
    m, n = len(word1), len(word2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    # Base cases
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if word1[i-1] == word2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(
                    dp[i-1][j],    # Delete
                    dp[i][j-1],    # Insert
                    dp[i-1][j-1]   # Replace
                )
    
    return dp[m][n]
```

### 6. Knapsack 0/1
```python
def knapsack(weights, values, capacity):
    n = len(weights)
    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
    
    for i in range(1, n + 1):
        for w in range(capacity + 1):
            # Don't take item
            dp[i][w] = dp[i-1][w]
            
            # Take item if possible
            if weights[i-1] <= w:
                dp[i][w] = max(dp[i][w], 
                              dp[i-1][w-weights[i-1]] + values[i-1])
    
    return dp[n][capacity]
```

---

## Edge Cases

### Critical Edge Cases
1. **Empty Input**: Arrays, strings with length 0
2. **Single Element**: Base case handling
3. **All Same Elements**: Optimization opportunities
4. **Negative Values**: Affects optimization direction
5. **Large Numbers**: Integer overflow concerns

### Common Pitfalls
1. **Incorrect State Definition**: Missing crucial information
2. **Wrong Base Cases**: Leads to incorrect results
3. **Off-by-One Errors**: Index boundaries
4. **Space Optimization Errors**: Overwriting needed values

---

## Complexity Analysis

### Time Complexity Patterns
- **Linear DP**: O(n) - single state variable
- **2D DP**: O(n*m) - two state variables
- **3D DP**: O(n*m*k) - three state variables
- **Interval DP**: O(n³) - trying all splits

### Space Complexity
- **Memoization**: O(recursion depth + state space)
- **Tabulation**: O(state space)
- **Optimized**: Often O(1) or O(min dimension)

### Space Optimization Techniques

#### Rolling Array
```python
# Before: O(n) space
dp = [0] * n
# After: O(1) space
prev = 0
for i in range(1, n):
    curr = prev + nums[i]
    prev = curr
```

#### 2D to 1D Compression
```python
# Before: O(m*n) space
dp = [[0] * n for _ in range(m)]
# After: O(n) space
dp = [0] * n
for i in range(m):
    for j in range(n):
        dp[j] = new_value
```

---

## Problem Categories

### 1. **Linear DP Problems**
- Climbing Stairs
- House Robber
- Maximum Subarray (Kadane's)
- Jump Game
- Decode Ways

### 2. **Grid DP Problems**
- Unique Paths
- Minimum Path Sum
- Dungeon Game
- Cherry Pickup

### 3. **String DP Problems**
- Edit Distance
- Longest Common Subsequence
- Palindromic Substrings
- Word Break
- Regular Expression Matching

### 4. **Knapsack Problems**
- 0/1 Knapsack
- Unbounded Knapsack
- Subset Sum
- Partition Equal Subset Sum
- Coin Change

### 5. **Tree DP Problems**
- Binary Tree Maximum Path Sum
- House Robber III
- Diameter of Binary Tree

---

## Pro Tips & Interview Tricks

### Problem Recognition Patterns
```
"Maximum/Minimum" + Choices → DP
"Number of ways" → DP
"Can we achieve" → DP
Overlapping subproblems → DP
```

### Implementation Strategies

1. **Start with Recursion**: Write naive recursive solution first
2. **Add Memoization**: Cache results to avoid recomputation
3. **Convert to Tabulation**: If needed for space optimization
4. **Optimize Space**: Use rolling arrays when possible

### Common Mistakes to Avoid

1. **Forgetting Base Cases**: Always handle boundary conditions
2. **Wrong State Transitions**: Carefully derive recurrence relations
3. **Index Errors**: Be careful with 0-based vs 1-based indexing
4. **Premature Optimization**: Get correctness first, then optimize

### Interview-Specific Tips

1. **Identify the Pattern**: Explain which DP pattern you're using
2. **State Definition**: Clearly define what dp[i] represents
3. **Walk Through Example**: Trace through small example
4. **Discuss Optimizations**: Mention space optimization possibilities
5. **Handle Edge Cases**: Consider empty inputs, single elements

### Code Templates

#### Top-Down Template
```python
def solve_dp_memo(params):
    memo = {}
    
    def dp(state):
        if state in memo:
            return memo[state]
        if base_case(state):
            return base_value
        
        result = optimal_choice([dp(next_state) for next_state in transitions])
        memo[state] = result
        return result
    
    return dp(initial_state)
```

#### Bottom-Up Template
```python
def solve_dp_tab(params):
    dp = initialize_table()
    set_base_cases(dp)
    
    for state in all_states():
        dp[state] = optimal_choice([dp[prev_state] for prev_state in previous_states])
    
    return dp[final_state]
```

### Optimization Checklist

1. **Space Optimization**: Can we use O(1) or O(k) space?
2. **Early Termination**: Can we stop computation early?
3. **Preprocessing**: Can we precompute some values?
4. **State Reduction**: Can we reduce the state space?

---

## Conclusion

Dynamic Programming is a powerful technique that transforms exponential-time brute force solutions into polynomial-time algorithms. The key to mastering DP is:

1. **Pattern Recognition**: Identify when DP applies
2. **State Design**: Define states that capture essential information
3. **Recurrence Relations**: Derive correct transitions between states
4. **Implementation**: Choose appropriate approach (top-down vs bottom-up)
5. **Optimization**: Apply space and time optimizations

**Success Formula**: Practice + Pattern Recognition + Careful Implementation = DP Mastery

Master these patterns and you'll be able to solve 80% of DP problems in technical interviews!