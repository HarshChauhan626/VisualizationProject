# Full-Text Search: Finding Needles in Digital Haystacks

## 🎯 What is Full-Text Search?

Full-text search is like having a super-intelligent librarian who has read every book in a massive library and can instantly find any book, chapter, or even specific sentences based on your description. Unlike a simple catalog search that only looks at titles and authors, full-text search examines the entire content of documents and can find relevant information even when you don't know the exact words or phrases.

## 🏗️ Core Concepts

### The Super Librarian Analogy
- **Document Collection**: The entire library of books and materials
- **Index**: The librarian's mental map of every word and concept
- **Query Processing**: Understanding what you're really looking for
- **Ranking**: Determining which results are most relevant to your needs
- **Real-time Updates**: Keeping track of new books and changes

### Why Full-Text Search Matters
1. **Information Discovery**: Find relevant content without knowing exact terms
2. **User Experience**: Enable intuitive, Google-like search experiences
3. **Content Navigation**: Help users explore large document collections
4. **Business Intelligence**: Extract insights from unstructured data
5. **Personalization**: Tailor results based on user preferences and context

## 🔍 Search Engine Architecture

```python
import re
import math
import time
import threading
from typing import Dict, List, Set, Tuple, Optional, Any
from collections import defaultdict, Counter
from dataclasses import dataclass
from enum import Enum
import heapq
import json

class DocumentType(Enum):
    TEXT = "text"
    HTML = "html"
    PDF = "pdf"
    JSON = "json"

@dataclass
class Document:
    doc_id: str
    title: str
    content: str
    doc_type: DocumentType
    metadata: Dict[str, Any]
    created_at: float
    updated_at: float
    
class TextProcessor:
    def __init__(self):
        self.stop_words = {
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
            'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
            'should', 'may', 'might', 'must', 'can', 'this', 'that', 'these',
            'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him',
            'her', 'us', 'them', 'my', 'your', 'his', 'its', 'our', 'their'
        }
        
        # Simple stemming rules (in production, use proper stemmer like Porter)
        self.stemming_rules = {
            'running': 'run', 'runs': 'run', 'ran': 'run',
            'better': 'good', 'best': 'good',
            'bigger': 'big', 'biggest': 'big',
            'quickly': 'quick', 'slower': 'slow'
        }
    
    def tokenize(self, text: str) -> List[str]:
        """Split text into tokens"""
        # Convert to lowercase and split on non-alphanumeric characters
        tokens = re.findall(r'\b[a-zA-Z0-9]+\b', text.lower())
        return tokens
    
    def remove_stop_words(self, tokens: List[str]) -> List[str]:
        """Remove common stop words"""
        return [token for token in tokens if token not in self.stop_words]
    
    def stem_words(self, tokens: List[str]) -> List[str]:
        """Apply basic stemming"""
        return [self.stemming_rules.get(token, token) for token in tokens]
    
    def process_text(self, text: str) -> List[str]:
        """Complete text processing pipeline"""
        tokens = self.tokenize(text)
        tokens = self.remove_stop_words(tokens)
        tokens = self.stem_words(tokens)
        return tokens
    
    def extract_phrases(self, tokens: List[str], max_phrase_length: int = 3) -> List[str]:
        """Extract n-gram phrases from tokens"""
        phrases = []
        
        for length in range(2, max_phrase_length + 1):
            for i in range(len(tokens) - length + 1):
                phrase = ' '.join(tokens[i:i + length])
                phrases.append(phrase)
        
        return phrases

class InvertedIndex:
    def __init__(self):
        self.index: Dict[str, Dict[str, float]] = defaultdict(dict)  # term -> {doc_id: tf_idf}
        self.document_frequencies: Dict[str, int] = defaultdict(int)  # term -> document count
        self.document_lengths: Dict[str, int] = {}  # doc_id -> document length
        self.total_documents = 0
        
    def add_document(self, doc_id: str, tokens: List[str]):
        """Add document to inverted index"""
        
        # Calculate term frequencies
        term_counts = Counter(tokens)
        doc_length = len(tokens)
        
        self.document_lengths[doc_id] = doc_length
        self.total_documents += 1
        
        # Update inverted index
        for term, count in term_counts.items():
            tf = count / doc_length  # Term frequency
            
            # Update document frequency
            if doc_id not in self.index[term]:
                self.document_frequencies[term] += 1
            
            self.index[term][doc_id] = tf
        
        # Recalculate TF-IDF scores for affected terms
        self._update_tfidf_scores(set(term_counts.keys()))
    
    def remove_document(self, doc_id: str):
        """Remove document from inverted index"""
        
        if doc_id not in self.document_lengths:
            return
        
        affected_terms = set()
        
        # Remove from inverted index
        for term in list(self.index.keys()):
            if doc_id in self.index[term]:
                del self.index[term][doc_id]
                self.document_frequencies[term] -= 1
                affected_terms.add(term)
                
                # Clean up empty term entries
                if not self.index[term]:
                    del self.index[term]
                    del self.document_frequencies[term]
        
        del self.document_lengths[doc_id]
        self.total_documents -= 1
        
        # Recalculate TF-IDF scores
        self._update_tfidf_scores(affected_terms)
    
    def _update_tfidf_scores(self, terms: Set[str]):
        """Update TF-IDF scores for given terms"""
        
        for term in terms:
            if term not in self.index:
                continue
                
            df = self.document_frequencies[term]
            idf = math.log(self.total_documents / df) if df > 0 else 0
            
            # Update TF-IDF for all documents containing this term
            for doc_id, tf in self.index[term].items():
                self.index[term][doc_id] = tf * idf
    
    def search(self, query_terms: List[str], max_results: int = 10) -> List[Tuple[str, float]]:
        """Search for documents matching query terms"""
        
        if not query_terms:
            return []
        
        # Calculate document scores
        doc_scores = defaultdict(float)
        
        for term in query_terms:
            if term in self.index:
                for doc_id, tfidf_score in self.index[term].items():
                    doc_scores[doc_id] += tfidf_score
        
        # Sort by relevance score
        sorted_results = sorted(doc_scores.items(), key=lambda x: x[1], reverse=True)
        
        return sorted_results[:max_results]
    
    def get_index_stats(self) -> Dict[str, Any]:
        """Get statistics about the inverted index"""
        
        total_terms = len(self.index)
        total_postings = sum(len(postings) for postings in self.index.values())
        
        return {
            'total_terms': total_terms,
            'total_documents': self.total_documents,
            'total_postings': total_postings,
            'average_document_length': sum(self.document_lengths.values()) / len(self.document_lengths) if self.document_lengths else 0,
            'index_size_estimate_mb': (total_postings * 64) / (1024 * 1024)  # Rough estimate
        }

class SearchEngine:
    def __init__(self):
        self.documents: Dict[str, Document] = {}
        self.inverted_index = InvertedIndex()
        self.text_processor = TextProcessor()
        self.query_log: List[Dict[str, Any]] = []
        self.indexing_queue = []
        self.indexing_thread = None
        self.running = False
        
    def start_indexing_service(self):
        """Start background indexing service"""
        if self.running:
            return
            
        self.running = True
        self.indexing_thread = threading.Thread(target=self._indexing_worker)
        self.indexing_thread.daemon = True
        self.indexing_thread.start()
        
        print("Search engine indexing service started")
    
    def stop_indexing_service(self):
        """Stop background indexing service"""
        self.running = False
        if self.indexing_thread:
            self.indexing_thread.join()
        print("Search engine indexing service stopped")
    
    def add_document(self, document: Document):
        """Add document to search engine"""
        
        # Store document
        self.documents[document.doc_id] = document
        
        # Queue for indexing
        self.indexing_queue.append(('add', document))
        
        print(f"Document {document.doc_id} queued for indexing")
    
    def update_document(self, document: Document):
        """Update existing document"""
        
        if document.doc_id in self.documents:
            # Remove old version from index
            self.indexing_queue.append(('remove', document.doc_id))
        
        # Store updated document
        self.documents[document.doc_id] = document
        
        # Queue for re-indexing
        self.indexing_queue.append(('add', document))
        
        print(f"Document {document.doc_id} queued for re-indexing")
    
    def remove_document(self, doc_id: str):
        """Remove document from search engine"""
        
        if doc_id in self.documents:
            del self.documents[doc_id]
            self.indexing_queue.append(('remove', doc_id))
            print(f"Document {doc_id} queued for removal")
    
    def _indexing_worker(self):
        """Background worker for indexing operations"""
        
        while self.running:
            try:
                if self.indexing_queue:
                    operation, data = self.indexing_queue.pop(0)
                    
                    if operation == 'add':
                        document = data
                        self._index_document(document)
                    elif operation == 'remove':
                        doc_id = data
                        self.inverted_index.remove_document(doc_id)
                
                time.sleep(0.1)  # Brief pause to prevent busy waiting
                
            except Exception as e:
                print(f"Indexing error: {e}")
    
    def _index_document(self, document: Document):
        """Index a single document"""
        
        # Extract text content
        full_text = f"{document.title} {document.content}"
        
        # Process text
        tokens = self.text_processor.process_text(full_text)
        
        # Add to inverted index
        self.inverted_index.add_document(document.doc_id, tokens)
        
        print(f"Indexed document {document.doc_id} ({len(tokens)} tokens)")
    
    def search(self, query: str, max_results: int = 10, 
               filters: Dict[str, Any] = None) -> Dict[str, Any]:
        """Search for documents matching query"""
        
        search_start_time = time.time()
        
        # Process query
        query_terms = self.text_processor.process_text(query)
        
        if not query_terms:
            return {
                'query': query,
                'results': [],
                'total_results': 0,
                'search_time_ms': 0
            }
        
        # Search inverted index
        raw_results = self.inverted_index.search(query_terms, max_results * 2)  # Get more for filtering
        
        # Apply filters and build result objects
        filtered_results = []
        
        for doc_id, relevance_score in raw_results:
            if doc_id not in self.documents:
                continue
                
            document = self.documents[doc_id]
            
            # Apply filters
            if filters and not self._apply_filters(document, filters):
                continue
            
            # Generate snippet
            snippet = self._generate_snippet(document, query_terms)
            
            result = {
                'doc_id': doc_id,
                'title': document.title,
                'snippet': snippet,
                'relevance_score': relevance_score,
                'doc_type': document.doc_type.value,
                'created_at': document.created_at,
                'metadata': document.metadata
            }
            
            filtered_results.append(result)
            
            if len(filtered_results) >= max_results:
                break
        
        search_time = (time.time() - search_start_time) * 1000
        
        # Log query
        self._log_query(query, len(filtered_results), search_time)
        
        return {
            'query': query,
            'processed_query': ' '.join(query_terms),
            'results': filtered_results,
            'total_results': len(filtered_results),
            'search_time_ms': search_time
        }
    
    def _apply_filters(self, document: Document, filters: Dict[str, Any]) -> bool:
        """Apply search filters to document"""
        
        # Document type filter
        if 'doc_type' in filters:
            if document.doc_type.value != filters['doc_type']:
                return False
        
        # Date range filter
        if 'created_after' in filters:
            if document.created_at < filters['created_after']:
                return False
        
        if 'created_before' in filters:
            if document.created_at > filters['created_before']:
                return False
        
        # Metadata filters
        if 'metadata' in filters:
            for key, value in filters['metadata'].items():
                if key not in document.metadata or document.metadata[key] != value:
                    return False
        
        return True
    
    def _generate_snippet(self, document: Document, query_terms: List[str]) -> str:
        """Generate search result snippet with highlighted terms"""
        
        content = document.content
        snippet_length = 200
        
        # Find best snippet location (containing most query terms)
        words = content.split()
        best_start = 0
        best_score = 0
        
        for i in range(len(words) - 20):
            snippet_words = words[i:i + 20]
            snippet_text = ' '.join(snippet_words).lower()
            
            score = sum(1 for term in query_terms if term in snippet_text)
            
            if score > best_score:
                best_score = score
                best_start = i
        
        # Extract snippet
        snippet_words = words[best_start:best_start + 30]
        snippet = ' '.join(snippet_words)
        
        # Truncate if too long
        if len(snippet) > snippet_length:
            snippet = snippet[:snippet_length] + "..."
        
        # Simple highlighting (in production, use proper HTML highlighting)
        for term in query_terms:
            pattern = re.compile(re.escape(term), re.IGNORECASE)
            snippet = pattern.sub(f"**{term}**", snippet)
        
        return snippet
    
    def _log_query(self, query: str, result_count: int, search_time: float):
        """Log search query for analytics"""
        
        log_entry = {
            'query': query,
            'result_count': result_count,
            'search_time_ms': search_time,
            'timestamp': time.time()
        }
        
        self.query_log.append(log_entry)
        
        # Keep only recent queries
        if len(self.query_log) > 10000:
            self.query_log = self.query_log[-10000:]
    
    def get_search_analytics(self) -> Dict[str, Any]:
        """Get search analytics and statistics"""
        
        if not self.query_log:
            return {'message': 'No search queries logged'}
        
        # Calculate statistics
        total_queries = len(self.query_log)
        avg_search_time = sum(log['search_time_ms'] for log in self.query_log) / total_queries
        avg_results = sum(log['result_count'] for log in self.query_log) / total_queries
        
        # Most common queries
        query_counts = Counter(log['query'].lower() for log in self.query_log)
        top_queries = query_counts.most_common(10)
        
        # Zero result queries
        zero_result_queries = [log['query'] for log in self.query_log if log['result_count'] == 0]
        
        return {
            'total_queries': total_queries,
            'average_search_time_ms': avg_search_time,
            'average_results_per_query': avg_results,
            'top_queries': top_queries,
            'zero_result_queries': len(zero_result_queries),
            'zero_result_examples': zero_result_queries[:5],
            'index_stats': self.inverted_index.get_index_stats()
        }
    
    def suggest_query_completions(self, partial_query: str, max_suggestions: int = 5) -> List[str]:
        """Suggest query completions based on search history"""
        
        partial_lower = partial_query.lower()
        suggestions = []
        
        # Find queries that start with the partial query
        for log in self.query_log:
            query = log['query'].lower()
            if query.startswith(partial_lower) and query != partial_lower:
                if query not in suggestions:
                    suggestions.append(query)
                    
                if len(suggestions) >= max_suggestions:
                    break
        
        return suggestions

# Example usage: Building a document search engine
search_engine = SearchEngine()
search_engine.start_indexing_service()

# Add sample documents
documents = [
    Document(
        doc_id="doc1",
        title="Introduction to Machine Learning",
        content="Machine learning is a subset of artificial intelligence that enables computers to learn and improve from experience without being explicitly programmed. It focuses on developing algorithms that can analyze data and make predictions or decisions.",
        doc_type=DocumentType.TEXT,
        metadata={"category": "technology", "author": "John Doe"},
        created_at=time.time(),
        updated_at=time.time()
    ),
    Document(
        doc_id="doc2", 
        title="The Future of Artificial Intelligence",
        content="Artificial intelligence is transforming industries and changing how we work and live. From autonomous vehicles to medical diagnosis, AI applications are becoming more sophisticated and widespread. The future holds even more exciting possibilities.",
        doc_type=DocumentType.TEXT,
        metadata={"category": "technology", "author": "Jane Smith"},
        created_at=time.time(),
        updated_at=time.time()
    ),
    Document(
        doc_id="doc3",
        title="Cooking with Python",
        content="Python is not just for programming! This cookbook shows how to use Python programming concepts in cooking. Learn about loops while making pasta, understand variables through ingredient measurements, and discover functions in recipe organization.",
        doc_type=DocumentType.TEXT,
        metadata={"category": "cooking", "author": "Chef Code"},
        created_at=time.time(),
        updated_at=time.time()
    ),
    Document(
        doc_id="doc4",
        title="Data Science Fundamentals",
        content="Data science combines statistics, programming, and domain expertise to extract insights from data. Python and R are popular programming languages for data analysis, visualization, and machine learning applications.",
        doc_type=DocumentType.TEXT,
        metadata={"category": "technology", "author": "Data Expert"},
        created_at=time.time(),
        updated_at=time.time()
    )
]

# Add documents to search engine
for doc in documents:
    search_engine.add_document(doc)

# Wait for indexing to complete
time.sleep(2)

# Perform searches
print("=== Search Engine Demo ===")

# Search for machine learning
results1 = search_engine.search("machine learning algorithms")
print(f"\nSearch: 'machine learning algorithms' ({results1['total_results']} results)")
for result in results1['results']:
    print(f"  {result['title']} (score: {result['relevance_score']:.3f})")
    print(f"    {result['snippet']}")

# Search for Python programming
results2 = search_engine.search("Python programming")
print(f"\nSearch: 'Python programming' ({results2['total_results']} results)")
for result in results2['results']:
    print(f"  {result['title']} (score: {result['relevance_score']:.3f})")
    print(f"    {result['snippet']}")

# Search with filters
results3 = search_engine.search(
    "technology", 
    filters={"metadata": {"category": "technology"}}
)
print(f"\nFiltered search: 'technology' in category 'technology' ({results3['total_results']} results)")
for result in results3['results']:
    print(f"  {result['title']} - {result['metadata']['category']}")

# Get analytics
analytics = search_engine.get_search_analytics()
print(f"\n=== Search Analytics ===")
print(f"Total queries: {analytics['total_queries']}")
print(f"Average search time: {analytics['average_search_time_ms']:.2f}ms")
print(f"Index stats: {analytics['index_stats']['total_terms']} terms, {analytics['index_stats']['total_documents']} documents")
```

## 🚀 Advanced Search Features

### Elasticsearch-like Distributed Search
```python
class DistributedSearchEngine:
    def __init__(self, num_shards: int = 3):
        self.num_shards = num_shards
        self.shards: List[SearchEngine] = []
        self.shard_assignments: Dict[str, int] = {}
        
        # Create shards
        for i in range(num_shards):
            shard = SearchEngine()
            shard.start_indexing_service()
            self.shards.append(shard)
    
    def _get_shard_for_document(self, doc_id: str) -> int:
        """Determine which shard should store a document"""
        return hash(doc_id) % self.num_shards
    
    def add_document(self, document: Document):
        """Add document to appropriate shard"""
        shard_id = self._get_shard_for_document(document.doc_id)
        self.shards[shard_id].add_document(document)
        self.shard_assignments[document.doc_id] = shard_id
    
    def search(self, query: str, max_results: int = 10) -> Dict[str, Any]:
        """Search across all shards and merge results"""
        
        search_start_time = time.time()
        
        # Search all shards in parallel (simulated)
        shard_results = []
        
        for shard in self.shards:
            shard_result = shard.search(query, max_results)
            shard_results.append(shard_result['results'])
        
        # Merge and rank results from all shards
        all_results = []
        for results in shard_results:
            all_results.extend(results)
        
        # Sort by relevance score
        all_results.sort(key=lambda x: x['relevance_score'], reverse=True)
        
        # Take top results
        final_results = all_results[:max_results]
        
        search_time = (time.time() - search_start_time) * 1000
        
        return {
            'query': query,
            'results': final_results,
            'total_results': len(final_results),
            'search_time_ms': search_time,
            'shards_searched': len(self.shards)
        }
    
    def get_cluster_stats(self) -> Dict[str, Any]:
        """Get statistics for entire cluster"""
        
        total_documents = 0
        total_terms = 0
        total_queries = 0
        
        shard_stats = []
        
        for i, shard in enumerate(self.shards):
            analytics = shard.get_search_analytics()
            index_stats = analytics.get('index_stats', {})
            
            shard_info = {
                'shard_id': i,
                'documents': index_stats.get('total_documents', 0),
                'terms': index_stats.get('total_terms', 0),
                'queries': analytics.get('total_queries', 0)
            }
            
            shard_stats.append(shard_info)
            
            total_documents += shard_info['documents']
            total_terms += shard_info['terms']
            total_queries += shard_info['queries']
        
        return {
            'total_shards': len(self.shards),
            'total_documents': total_documents,
            'total_terms': total_terms,
            'total_queries': total_queries,
            'shard_stats': shard_stats
        }

class FacetedSearch:
    """Add faceted search capabilities"""
    
    def __init__(self, search_engine: SearchEngine):
        self.search_engine = search_engine
        self.facet_fields = ['doc_type', 'category', 'author', 'created_year']
    
    def search_with_facets(self, query: str, max_results: int = 10) -> Dict[str, Any]:
        """Search with faceted navigation"""
        
        # Perform regular search
        search_results = self.search_engine.search(query, max_results * 2)  # Get more for faceting
        
        # Calculate facets
        facets = self._calculate_facets(search_results['results'])
        
        # Limit results
        search_results['results'] = search_results['results'][:max_results]
        search_results['facets'] = facets
        
        return search_results
    
    def _calculate_facets(self, results: List[Dict[str, Any]]) -> Dict[str, Dict[str, int]]:
        """Calculate facet counts from search results"""
        
        facets = {}
        
        for field in self.facet_fields:
            facets[field] = defaultdict(int)
        
        for result in results:
            # Document type facet
            facets['doc_type'][result['doc_type']] += 1
            
            # Metadata-based facets
            metadata = result.get('metadata', {})
            
            if 'category' in metadata:
                facets['category'][metadata['category']] += 1
            
            if 'author' in metadata:
                facets['author'][metadata['author']] += 1
            
            # Created year facet
            created_year = time.strftime('%Y', time.localtime(result['created_at']))
            facets['created_year'][created_year] += 1
        
        # Convert to regular dicts and sort by count
        for field in facets:
            facets[field] = dict(sorted(facets[field].items(), 
                                      key=lambda x: x[1], reverse=True))
        
        return facets

class AutoComplete:
    """Provide search autocompletion"""
    
    def __init__(self):
        self.trie = TrieNode()
        self.popular_queries = Counter()
        
    def add_query(self, query: str, frequency: int = 1):
        """Add query to autocompletion index"""
        
        # Add to trie
        self._insert_into_trie(query.lower())
        
        # Update popularity
        self.popular_queries[query.lower()] += frequency
    
    def _insert_into_trie(self, query: str):
        """Insert query into trie structure"""
        
        current = self.trie
        
        for char in query:
            if char not in current.children:
                current.children[char] = TrieNode()
            current = current.children[char]
            current.queries.add(query)
        
        current.is_end_of_query = True
    
    def get_suggestions(self, prefix: str, max_suggestions: int = 5) -> List[Tuple[str, int]]:
        """Get autocompletion suggestions for prefix"""
        
        prefix_lower = prefix.lower()
        
        # Find prefix node in trie
        current = self.trie
        
        for char in prefix_lower:
            if char not in current.children:
                return []  # No suggestions found
            current = current.children[char]
        
        # Collect all queries from this node
        suggestions = []
        
        for query in current.queries:
            frequency = self.popular_queries[query]
            suggestions.append((query, frequency))
        
        # Sort by popularity and return top suggestions
        suggestions.sort(key=lambda x: x[1], reverse=True)
        
        return suggestions[:max_suggestions]

class TrieNode:
    def __init__(self):
        self.children = {}
        self.queries = set()
        self.is_end_of_query = False

# Example: Advanced search features
print("\n=== Advanced Search Features Demo ===")

# Create distributed search engine
distributed_search = DistributedSearchEngine(num_shards=2)

# Add documents to distributed engine
for doc in documents:
    distributed_search.add_document(doc)

time.sleep(1)  # Wait for indexing

# Search across shards
distributed_results = distributed_search.search("artificial intelligence")
print(f"Distributed search results: {distributed_results['total_results']} from {distributed_results['shards_searched']} shards")

# Faceted search
faceted_search = FacetedSearch(search_engine)
faceted_results = faceted_search.search_with_facets("programming")

print(f"\nFaceted search results:")
print(f"Results: {len(faceted_results['results'])}")
print("Facets:")
for facet_name, facet_values in faceted_results['facets'].items():
    if facet_values:
        print(f"  {facet_name}: {dict(list(facet_values.items())[:3])}")

# Autocompletion
autocomplete = AutoComplete()

# Add some popular queries
popular_queries = [
    ("machine learning", 100),
    ("machine learning algorithms", 50),
    ("machine learning tutorial", 30),
    ("artificial intelligence", 80),
    ("artificial intelligence future", 40),
    ("python programming", 60),
    ("python tutorial", 35)
]

for query, frequency in popular_queries:
    autocomplete.add_query(query, frequency)

# Test autocompletion
suggestions = autocomplete.get_suggestions("machine", 3)
print(f"\nAutocompletion for 'machine': {suggestions}")

suggestions = autocomplete.get_suggestions("python", 3)
print(f"Autocompletion for 'python': {suggestions}")
```

## 📊 Search Quality and Performance Optimization

```python
class SearchQualityAnalyzer:
    """Analyze and improve search quality"""
    
    def __init__(self, search_engine: SearchEngine):
        self.search_engine = search_engine
        self.click_data = []  # query, doc_id, position, timestamp
        self.relevance_judgments = {}  # (query, doc_id) -> relevance_score
        
    def record_click(self, query: str, doc_id: str, position: int):
        """Record user click for learning"""
        
        click_record = {
            'query': query.lower(),
            'doc_id': doc_id,
            'position': position,
            'timestamp': time.time()
        }
        
        self.click_data.append(click_record)
    
    def calculate_click_through_rates(self) -> Dict[str, float]:
        """Calculate CTR by position"""
        
        position_clicks = defaultdict(int)
        position_impressions = defaultdict(int)
        
        for click in self.click_data:
            position = click['position']
            position_clicks[position] += 1
        
        # Estimate impressions (simplified)
        for click in self.click_data:
            for pos in range(1, click['position'] + 1):
                position_impressions[pos] += 1
        
        ctrs = {}
        for position in position_impressions:
            if position_impressions[position] > 0:
                ctrs[position] = position_clicks[position] / position_impressions[position]
        
        return ctrs
    
    def analyze_query_performance(self, min_queries: int = 5) -> Dict[str, Any]:
        """Analyze performance of different queries"""
        
        query_stats = defaultdict(lambda: {
            'total_searches': 0,
            'total_clicks': 0,
            'avg_click_position': 0,
            'zero_result_searches': 0
        })
        
        # Analyze search logs
        for log in self.search_engine.query_log:
            query = log['query'].lower()
            query_stats[query]['total_searches'] += 1
            
            if log['result_count'] == 0:
                query_stats[query]['zero_result_searches'] += 1
        
        # Analyze click data
        click_positions = defaultdict(list)
        
        for click in self.click_data:
            query = click['query']
            query_stats[query]['total_clicks'] += 1
            click_positions[query].append(click['position'])
        
        # Calculate average click positions
        for query, positions in click_positions.items():
            if positions:
                query_stats[query]['avg_click_position'] = sum(positions) / len(positions)
        
        # Filter queries with sufficient data
        significant_queries = {
            query: stats for query, stats in query_stats.items()
            if stats['total_searches'] >= min_queries
        }
        
        return significant_queries
    
    def identify_poor_performing_queries(self) -> List[Dict[str, Any]]:
        """Identify queries that need improvement"""
        
        query_performance = self.analyze_query_performance()
        poor_queries = []
        
        for query, stats in query_performance.items():
            issues = []
            
            # High zero-result rate
            zero_result_rate = stats['zero_result_searches'] / stats['total_searches']
            if zero_result_rate > 0.3:  # 30% zero results
                issues.append(f"High zero-result rate: {zero_result_rate:.2%}")
            
            # Low click-through rate
            if stats['total_searches'] > 0:
                ctr = stats['total_clicks'] / stats['total_searches']
                if ctr < 0.1:  # Less than 10% CTR
                    issues.append(f"Low click-through rate: {ctr:.2%}")
            
            # High average click position
            if stats['avg_click_position'] > 5:
                issues.append(f"Users clicking far down: position {stats['avg_click_position']:.1f}")
            
            if issues:
                poor_queries.append({
                    'query': query,
                    'issues': issues,
                    'stats': stats
                })
        
        return poor_queries
    
    def suggest_improvements(self) -> List[Dict[str, Any]]:
        """Suggest search improvements"""
        
        suggestions = []
        
        # Analyze poor performing queries
        poor_queries = self.identify_poor_performing_queries()
        
        for poor_query in poor_queries:
            query = poor_query['query']
            improvements = []
            
            # Check if it's a spelling issue
            if self._might_be_misspelled(query):
                improvements.append("Add spell correction")
            
            # Check if it needs synonyms
            if "zero-result" in poor_query['issues'][0]:
                improvements.append("Add synonym expansion")
            
            # Check if it needs better ranking
            if "clicking far down" in str(poor_query['issues']):
                improvements.append("Improve ranking algorithm")
            
            suggestions.append({
                'query': query,
                'problems': poor_query['issues'],
                'suggested_improvements': improvements
            })
        
        return suggestions
    
    def _might_be_misspelled(self, query: str) -> bool:
        """Simple heuristic to detect potential misspellings"""
        
        # Check against common terms in index
        query_terms = self.search_engine.text_processor.process_text(query)
        index_terms = set(self.search_engine.inverted_index.index.keys())
        
        # If many query terms are not in index, might be misspelled
        missing_terms = [term for term in query_terms if term not in index_terms]
        
        return len(missing_terms) / len(query_terms) > 0.5 if query_terms else False

class SearchPerformanceOptimizer:
    """Optimize search performance"""
    
    def __init__(self, search_engine: SearchEngine):
        self.search_engine = search_engine
        self.query_cache = {}
        self.cache_hits = 0
        self.cache_misses = 0
        
    def cached_search(self, query: str, max_results: int = 10) -> Dict[str, Any]:
        """Search with result caching"""
        
        cache_key = f"{query}:{max_results}"
        
        if cache_key in self.query_cache:
            self.cache_hits += 1
            cached_result = self.query_cache[cache_key]
            cached_result['from_cache'] = True
            return cached_result
        
        # Perform search
        result = self.search_engine.search(query, max_results)
        
        # Cache result
        self.query_cache[cache_key] = result.copy()
        self.cache_misses += 1
        
        # Limit cache size
        if len(self.query_cache) > 1000:
            # Remove oldest entries (simple FIFO)
            oldest_key = next(iter(self.query_cache))
            del self.query_cache[oldest_key]
        
        result['from_cache'] = False
        return result
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache performance statistics"""
        
        total_requests = self.cache_hits + self.cache_misses
        hit_rate = self.cache_hits / total_requests if total_requests > 0 else 0
        
        return {
            'cache_hits': self.cache_hits,
            'cache_misses': self.cache_misses,
            'hit_rate': hit_rate,
            'cached_queries': len(self.query_cache)
        }
    
    def optimize_index(self) -> Dict[str, Any]:
        """Optimize search index for better performance"""
        
        optimizations = []
        
        # Analyze index statistics
        index_stats = self.search_engine.inverted_index.get_index_stats()
        
        # Check for terms that appear in too many documents (low selectivity)
        low_selectivity_terms = []
        
        for term, postings in self.search_engine.inverted_index.index.items():
            document_frequency = len(postings)
            selectivity = document_frequency / index_stats['total_documents']
            
            if selectivity > 0.8:  # Term appears in >80% of documents
                low_selectivity_terms.append((term, selectivity))
        
        if low_selectivity_terms:
            optimizations.append({
                'type': 'low_selectivity_terms',
                'description': f'Found {len(low_selectivity_terms)} terms with low selectivity',
                'recommendation': 'Consider adding these terms to stop words list',
                'examples': low_selectivity_terms[:5]
            })
        
        # Check for very rare terms (might be typos)
        rare_terms = []
        
        for term, postings in self.search_engine.inverted_index.index.items():
            if len(postings) == 1:  # Appears in only one document
                rare_terms.append(term)
        
        if len(rare_terms) > index_stats['total_terms'] * 0.3:  # >30% rare terms
            optimizations.append({
                'type': 'many_rare_terms',
                'description': f'Found {len(rare_terms)} terms appearing in only one document',
                'recommendation': 'Consider spell checking or better text preprocessing',
                'count': len(rare_terms)
            })
        
        return {
            'optimizations_found': len(optimizations),
            'recommendations': optimizations,
            'current_index_stats': index_stats
        }

# Example: Search quality analysis
print("\n=== Search Quality Analysis Demo ===")

# Create analyzers
quality_analyzer = SearchQualityAnalyzer(search_engine)
performance_optimizer = SearchPerformanceOptimizer(search_engine)

# Simulate user interactions
user_interactions = [
    ("machine learning", "doc1", 1),
    ("machine learning", "doc4", 2),
    ("artificial intelligence", "doc2", 1),
    ("python programming", "doc3", 1),
    ("python programming", "doc4", 3),
    ("cooking recipes", "doc3", 5),  # Poor relevance
]

for query, doc_id, position in user_interactions:
    quality_analyzer.record_click(query, doc_id, position)

# Analyze performance
poor_queries = quality_analyzer.identify_poor_performing_queries()
print(f"Poor performing queries: {len(poor_queries)}")

for pq in poor_queries:
    print(f"  {pq['query']}: {pq['issues']}")

# Get improvement suggestions
suggestions = quality_analyzer.suggest_improvements()
print(f"\nImprovement suggestions: {len(suggestions)}")

for suggestion in suggestions:
    print(f"  {suggestion['query']}: {suggestion['suggested_improvements']}")

# Test cached search
cached_result1 = performance_optimizer.cached_search("machine learning")
cached_result2 = performance_optimizer.cached_search("machine learning")  # Should be cached

cache_stats = performance_optimizer.get_cache_stats()
print(f"\nCache performance: {cache_stats['hit_rate']:.2%} hit rate")

# Index optimization analysis
optimization_report = performance_optimizer.optimize_index()
print(f"\nIndex optimization: {optimization_report['optimizations_found']} recommendations")

for opt in optimization_report['recommendations']:
    print(f"  {opt['type']}: {opt['description']}")

search_engine.stop_indexing_service()
```

## 📚 Conclusion

Full-text search is a complex but essential component of modern applications, enabling users to find relevant information quickly and intuitively. From basic inverted indexes to sophisticated distributed search engines with machine learning-powered ranking, search systems continue to evolve to meet growing demands for speed, relevance, and scale.

**Key Takeaways:**

1. **Build Quality Indexes**: Proper text processing and indexing are fundamental to good search
2. **Measure and Optimize**: Use analytics to understand user behavior and improve search quality
3. **Design for Scale**: Consider distributed architectures for large document collections
4. **Focus on Relevance**: Ranking algorithms and user feedback are crucial for good results
5. **Plan for Real-time**: Balance index freshness with search performance

The future of full-text search includes AI-powered semantic understanding, real-time personalization, and multi-modal search across text, images, and audio. Whether you're building an e-commerce site, document management system, or knowledge base, understanding search concepts is essential for creating applications that help users find what they need.

Remember: great search is not just about finding documents—it's about understanding user intent and delivering the most relevant, useful results in the context of their needs and preferences.
