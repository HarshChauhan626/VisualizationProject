# Computational Geometry - Comprehensive Cheatsheet

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

### What is Computational Geometry?

Computational Geometry is the study of algorithms for solving geometric problems. It bridges mathematics and computer science, dealing with points, lines, polygons, and higher-dimensional objects.

**Core Objects:**
- **Points**: Basic geometric primitives (x, y coordinates)
- **Lines**: Infinite straight paths
- **Line Segments**: Finite portions of lines
- **Polygons**: Closed shapes with straight sides
- **Circles**: Round shapes defined by center and radius

### Coordinate Systems

#### Cartesian Coordinates
- **2D**: (x, y) representing horizontal and vertical positions
- **3D**: (x, y, z) adding depth dimension

#### Polar Coordinates
- **(r, θ)**: Distance from origin and angle
- **Conversion**: x = r cos(θ), y = r sin(θ)

### Fundamental Concepts

#### Distance
**Euclidean Distance** between points (x₁, y₁) and (x₂, y₂):
```
d = √[(x₂ - x₁)² + (y₂ - y₁)²]
```

**Manhattan Distance**:
```
d = |x₂ - x₁| + |y₂ - y₁|
```

#### Orientation
Determines whether three points make a clockwise or counterclockwise turn:
```
orientation = (y₂ - y₁) * (x₃ - x₂) - (y₃ - y₂) * (x₂ - x₁)
- orientation > 0: Counterclockwise
- orientation < 0: Clockwise  
- orientation = 0: Collinear
```

---

## Key Properties & Rules

### Basic Point Operations

```python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
    
    def distance_to(self, other):
        return ((self.x - other.x)**2 + (self.y - other.y)**2)**0.5
    
    def manhattan_distance(self, other):
        return abs(self.x - other.x) + abs(self.y - other.y)
    
    def __eq__(self, other):
        return self.x == other.x and self.y == other.y
    
    def __repr__(self):
        return f"Point({self.x}, {self.y})"
```

### Line Operations

#### Line Representation
1. **Two Points**: Line through points A and B
2. **Slope-Intercept**: y = mx + b
3. **General Form**: ax + by + c = 0

```python
class Line:
    def __init__(self, p1, p2):
        self.p1 = p1
        self.p2 = p2
    
    def slope(self):
        if self.p2.x == self.p1.x:
            return float('inf')  # Vertical line
        return (self.p2.y - self.p1.y) / (self.p2.x - self.p1.x)
    
    def y_intercept(self):
        if self.p2.x == self.p1.x:
            return None  # Vertical line
        m = self.slope()
        return self.p1.y - m * self.p1.x
```

### Orientation and Cross Product

```python
def orientation(p, q, r):
    """Find orientation of ordered triplet (p, q, r)
    Returns:
    0 --> p, q and r are collinear
    1 --> Clockwise
    2 --> Counterclockwise
    """
    val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    if val == 0:
        return 0
    return 1 if val > 0 else 2

def cross_product(o, a, b):
    """Cross product of vectors OA and OB"""
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
```

---

## Patterns & Use Cases

### Core Geometric Patterns

#### 1. **Point-in-Polygon**
Determine if a point lies inside a polygon.

**Ray Casting Algorithm:**
```python
def point_in_polygon(point, polygon):
    x, y = point.x, point.y
    n = len(polygon)
    inside = False
    
    p1x, p1y = polygon[0].x, polygon[0].y
    for i in range(1, n + 1):
        p2x, p2y = polygon[i % n].x, polygon[i % n].y
        if y > min(p1y, p2y):
            if y <= max(p1y, p2y):
                if x <= max(p1x, p2x):
                    if p1y != p2y:
                        xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x, p1y = p2x, p2y
    
    return inside
```

#### 2. **Line Intersection**
Find intersection point of two line segments.

```python
def lines_intersect(p1, q1, p2, q2):
    """Check if line segments p1q1 and p2q2 intersect"""
    o1 = orientation(p1, q1, p2)
    o2 = orientation(p1, q1, q2)
    o3 = orientation(p2, q2, p1)
    o4 = orientation(p2, q2, q1)
    
    # General case
    if o1 != o2 and o3 != o4:
        return True
    
    # Special cases (collinear points)
    if (o1 == 0 and on_segment(p1, p2, q1) or
        o2 == 0 and on_segment(p1, q2, q1) or
        o3 == 0 and on_segment(p2, p1, q2) or
        o4 == 0 and on_segment(p2, q1, q2)):
        return True
    
    return False

def on_segment(p, q, r):
    """Check if point q lies on segment pr"""
    return (q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and
            q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y))
```

#### 3. **Closest Pair**
Find the closest pair of points in a set.

```python
def closest_pair_brute_force(points):
    """O(n²) brute force approach"""
    min_dist = float('inf')
    n = len(points)
    closest_points = None
    
    for i in range(n):
        for j in range(i + 1, n):
            dist = points[i].distance_to(points[j])
            if dist < min_dist:
                min_dist = dist
                closest_points = (points[i], points[j])
    
    return closest_points, min_dist
```

### Advanced Patterns

#### 4. **Convex Hull**
Find the smallest convex polygon containing all points.

**Graham Scan Algorithm:**
```python
def convex_hull_graham(points):
    def polar_angle(p0, p1):
        if p1.x == p0.x and p1.y == p0.y:
            return -math.pi
        return math.atan2(p1.y - p0.y, p1.x - p0.x)
    
    # Find bottom-most point (or leftmost in case of tie)
    start = min(points, key=lambda p: (p.y, p.x))
    
    # Sort points by polar angle with respect to start point
    sorted_points = sorted(points, key=lambda p: (polar_angle(start, p), start.distance_to(p)))
    
    if len(sorted_points) < 3:
        return sorted_points
    
    # Create convex hull
    hull = [sorted_points[0], sorted_points[1]]
    
    for i in range(2, len(sorted_points)):
        # Remove points that make clockwise turn
        while (len(hull) > 1 and 
               cross_product(hull[-2], hull[-1], sorted_points[i]) <= 0):
            hull.pop()
        hull.append(sorted_points[i])
    
    return hull
```

---

## Step-by-Step Approaches

### Geometric Problem-Solving Framework

1. **Understand the Problem**:
   - What geometric objects are involved?
   - What relationships need to be determined?
   - What are the constraints?

2. **Choose Coordinate System**:
   - Cartesian for most problems
   - Polar for circular/angular problems

3. **Identify Key Operations**:
   - Distance calculations
   - Orientation tests
   - Intersection tests
   - Area calculations

4. **Handle Precision**:
   - Use appropriate epsilon for floating-point comparisons
   - Consider integer coordinates when possible

### Common Geometric Algorithms

#### Sweep Line Algorithm
Process geometric objects by sweeping a line across the plane.

```python
def sweep_line_intersections(segments):
    """Find all intersection points using sweep line"""
    events = []
    
    # Create events for segment endpoints
    for i, (start, end) in enumerate(segments):
        events.append((start.x, 'start', i, start, end))
        events.append((end.x, 'end', i, start, end))
    
    events.sort()
    active_segments = set()
    intersections = []
    
    for x, event_type, seg_id, start, end in events:
        if event_type == 'start':
            # Check intersections with all active segments
            for active_id in active_segments:
                active_start, active_end = segments[active_id]
                if lines_intersect(start, end, active_start, active_end):
                    # Calculate intersection point
                    intersection = calculate_intersection(start, end, active_start, active_end)
                    intersections.append(intersection)
            active_segments.add(seg_id)
        else:
            active_segments.remove(seg_id)
    
    return intersections
```

---

## Common Algorithms

### 1. Area Calculations

#### Triangle Area
```python
def triangle_area(p1, p2, p3):
    """Calculate area using cross product"""
    return abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) / 2

def triangle_area_shoelace(p1, p2, p3):
    """Calculate area using shoelace formula"""
    return abs(p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)) / 2
```

#### Polygon Area
```python
def polygon_area(vertices):
    """Calculate polygon area using shoelace formula"""
    n = len(vertices)
    area = 0
    
    for i in range(n):
        j = (i + 1) % n
        area += vertices[i].x * vertices[j].y
        area -= vertices[j].x * vertices[i].y
    
    return abs(area) / 2
```

### 2. Geometric Transformations

#### Rotation
```python
def rotate_point(point, angle, center=None):
    """Rotate point around center by given angle (in radians)"""
    if center is None:
        center = Point(0, 0)
    
    # Translate to origin
    x = point.x - center.x
    y = point.y - center.y
    
    # Rotate
    cos_a = math.cos(angle)
    sin_a = math.sin(angle)
    
    new_x = x * cos_a - y * sin_a
    new_y = x * sin_a + y * cos_a
    
    # Translate back
    return Point(new_x + center.x, new_y + center.y)
```

#### Scaling and Translation
```python
def scale_point(point, scale_x, scale_y, center=None):
    """Scale point around center"""
    if center is None:
        center = Point(0, 0)
    
    x = (point.x - center.x) * scale_x + center.x
    y = (point.y - center.y) * scale_y + center.y
    
    return Point(x, y)

def translate_point(point, dx, dy):
    """Translate point by given offsets"""
    return Point(point.x + dx, point.y + dy)
```

### 3. Circle Operations

```python
class Circle:
    def __init__(self, center, radius):
        self.center = center
        self.radius = radius
    
    def contains_point(self, point):
        """Check if point is inside circle"""
        return self.center.distance_to(point) <= self.radius
    
    def intersects_circle(self, other):
        """Check if this circle intersects with another"""
        distance = self.center.distance_to(other.center)
        return distance <= (self.radius + other.radius)
    
    def area(self):
        return math.pi * self.radius ** 2
    
    def circumference(self):
        return 2 * math.pi * self.radius
```

### 4. Line-Circle Intersection

```python
def line_circle_intersection(line_start, line_end, circle):
    """Find intersection points of line segment with circle"""
    # Vector from line start to circle center
    d = Point(line_end.x - line_start.x, line_end.y - line_start.y)
    f = Point(line_start.x - circle.center.x, line_start.y - circle.center.y)
    
    # Quadratic equation coefficients
    a = d.x * d.x + d.y * d.y
    b = 2 * (f.x * d.x + f.y * d.y)
    c = f.x * f.x + f.y * f.y - circle.radius * circle.radius
    
    discriminant = b * b - 4 * a * c
    
    if discriminant < 0:
        return []  # No intersection
    
    discriminant = math.sqrt(discriminant)
    t1 = (-b - discriminant) / (2 * a)
    t2 = (-b + discriminant) / (2 * a)
    
    intersections = []
    
    # Check if intersection points are within line segment
    for t in [t1, t2]:
        if 0 <= t <= 1:
            x = line_start.x + t * d.x
            y = line_start.y + t * d.y
            intersections.append(Point(x, y))
    
    return intersections
```

---

## Edge Cases

### Critical Edge Cases

1. **Degenerate Cases**:
   - Zero-length line segments
   - Polygons with fewer than 3 vertices
   - Circles with zero radius

2. **Collinear Points**:
   - Three or more points on the same line
   - Affects orientation and convex hull algorithms

3. **Floating-Point Precision**:
   - Use epsilon for comparisons
   - Consider coordinate scaling

4. **Boundary Cases**:
   - Points exactly on polygon edges
   - Tangent lines to circles

### Precision Handling

```python
EPS = 1e-9

def float_equal(a, b):
    return abs(a - b) < EPS

def point_equal(p1, p2):
    return float_equal(p1.x, p2.x) and float_equal(p1.y, p2.y)
```

---

## Complexity Analysis

### Algorithm Complexities

| Algorithm | Time Complexity | Space Complexity |
|-----------|-----------------|------------------|
| Point in Polygon | O(n) | O(1) |
| Line Intersection | O(1) | O(1) |
| Closest Pair (Brute Force) | O(n²) | O(1) |
| Closest Pair (Divide & Conquer) | O(n log n) | O(n) |
| Convex Hull (Graham Scan) | O(n log n) | O(n) |
| Convex Hull (Jarvis March) | O(nh) | O(1) |

*n = number of points, h = number of hull points*

---

## Problem Categories

### 1. **Basic Geometry**
- Distance between points
- Area of polygons
- Point in polygon
- Line intersections

### 2. **Convex Hull**
- Graham Scan
- Jarvis March (Gift Wrapping)
- QuickHull

### 3. **Closest/Farthest Points**
- Closest pair of points
- Farthest pair of points
- All nearest neighbors

### 4. **Visibility and Illumination**
- Art gallery problems
- Visibility polygons
- Shadow computation

---

## Pro Tips & Interview Tricks

### Problem Recognition
```
Point Relationships → Distance/Orientation calculations
Shape Properties → Area/Perimeter algorithms
Optimization → Closest/Farthest pair problems
Containment → Point-in-polygon tests
Intersection → Line/Circle intersection algorithms
```

### Implementation Tips

1. **Use Cross Product**: For orientation and area calculations
2. **Handle Precision**: Use epsilon for floating-point comparisons
3. **Consider Edge Cases**: Degenerate and boundary cases
4. **Coordinate Scaling**: Scale coordinates to avoid precision issues

### Common Mistakes

1. **Precision Errors**: Not handling floating-point precision
2. **Degenerate Cases**: Not checking for zero-length segments
3. **Coordinate Systems**: Mixing different coordinate systems
4. **Boundary Conditions**: Not handling points exactly on boundaries

### Optimization Strategies

1. **Spatial Data Structures**: Use quad-trees, k-d trees for range queries
2. **Sweep Line**: For intersection and closest pair problems
3. **Divide and Conquer**: For closest pair and convex hull
4. **Incremental Construction**: For convex hull and Delaunay triangulation

### Code Templates

#### Basic Geometric Primitives
```python
def ccw(A, B, C):
    """Check if three points are in counterclockwise order"""
    return (C.y - A.y) * (B.x - A.x) > (B.y - A.y) * (C.x - A.x)

def intersect(A, B, C, D):
    """Check if line segments AB and CD intersect"""
    return ccw(A, C, D) != ccw(B, C, D) and ccw(A, B, C) != ccw(A, B, D)

def point_to_line_distance(point, line_start, line_end):
    """Distance from point to line segment"""
    A = point.x - line_start.x
    B = point.y - line_start.y
    C = line_end.x - line_start.x
    D = line_end.y - line_start.y
    
    dot = A * C + B * D
    len_sq = C * C + D * D
    
    if len_sq == 0:
        return point.distance_to(line_start)
    
    param = dot / len_sq
    
    if param < 0:
        return point.distance_to(line_start)
    elif param > 1:
        return point.distance_to(line_end)
    else:
        closest = Point(line_start.x + param * C, line_start.y + param * D)
        return point.distance_to(closest)
```

---

## Conclusion

Computational Geometry combines mathematical concepts with algorithmic thinking to solve spatial problems. Key mastery areas:

1. **Basic Primitives**: Points, lines, polygons, and their relationships
2. **Orientation Tests**: Cross products and collinearity checks
3. **Intersection Algorithms**: Line-line, line-circle intersections
4. **Containment Tests**: Point-in-polygon, circle containment
5. **Optimization Problems**: Closest pairs, convex hulls

**Success Formula**: Mathematical foundation + Careful implementation + Precision handling = Geometry mastery

Computational geometry problems appear in graphics, robotics, GIS, and computer vision. Master these fundamentals for success in spatial algorithm challenges!