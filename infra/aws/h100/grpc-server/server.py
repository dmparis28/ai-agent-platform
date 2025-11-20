#!/usr/bin/env python3
import grpc
from concurrent import futures
import json
import time
from neo4j import GraphDatabase
import redis
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
import boto3
import os

import intelligence_pb2
import intelligence_pb2_grpc


class SharedIntelligenceService(intelligence_pb2_grpc.SharedIntelligenceServicer):
    def __init__(self):
        self.neo4j_driver = GraphDatabase.driver(
            "bolt://localhost:7687",
            auth=("neo4j", os.getenv("NEO4J_PASSWORD"))
        )
        self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        
        # Load sentence transformer for embeddings
        self.model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Initialize FAISS index
        self.dimension = 384
        self.index = faiss.IndexFlatL2(self.dimension)
        
        # Load existing index if available
        if os.path.exists('/opt/h100/faiss/knowledge.index'):
            self.index = faiss.read_index('/opt/h100/faiss/knowledge.index')
        
        self.task_metadata = {}
    
    def QueryContext(self, request, context):
        """Query knowledge graph for relevant context"""
        task_description = request.task_description
        agent_type = request.agent_type
        
        # Check Redis cache first
        cache_key = f"context:{agent_type}:{hash(task_description)}"
        cached = self.redis_client.get(cache_key)
        if cached:
            return intelligence_pb2.ContextResponse(
                relevant_patterns=json.loads(cached)
            )
        
        # Generate embedding
        query_embedding = self.model.encode([task_description])[0]
        
        # Search FAISS for similar tasks
        k = 5
        distances, indices = self.index.search(
            np.array([query_embedding]).astype('float32'), 
            k
        )
        
        # Query Neo4j for detailed context
        patterns = []
        with self.neo4j_driver.session() as session:
            # Find similar past tasks
            result = session.run("""
                MATCH (t:Task {agent_type: $agent_type})
                WHERE t.success = true
                WITH t
                ORDER BY t.timestamp DESC
                LIMIT 5
                MATCH (t)-[:USED_PATTERN]->(p:Pattern)
                RETURN p.description as pattern, p.success_rate as rate
            """, agent_type=agent_type)
            
            for record in result:
                patterns.append({
                    "pattern": record["pattern"],
                    "success_rate": record["rate"]
                })
        
        # Cache result
        self.redis_client.setex(cache_key, 3600, json.dumps(patterns))
        
        return intelligence_pb2.ContextResponse(
            relevant_patterns=json.dumps(patterns)
        )
    
    def StoreResult(self, request, context):
        """Store task result in knowledge graph"""
        task_id = request.task_id
        agent_type = request.agent_type
        success = request.success
        result_data = request.result_data
        
        # Store in Neo4j
        with self.neo4j_driver.session() as session:
            session.run("""
                CREATE (t:Task {
                    task_id: $task_id,
                    agent_type: $agent_type,
                    success: $success,
                    timestamp: timestamp()
                })
            """, task_id=task_id, agent_type=agent_type, success=success)
            
            # Extract and store patterns
            if success:
                patterns = self._extract_patterns(result_data)
                for pattern in patterns:
                    session.run("""
                        MATCH (t:Task {task_id: $task_id})
                        MERGE (p:Pattern {description: $pattern})
                        ON CREATE SET p.success_rate = 1.0, p.usage_count = 1
                        ON MATCH SET 
                            p.usage_count = p.usage_count + 1,
                            p.success_rate = (p.success_rate * p.usage_count + 1.0) / (p.usage_count + 1)
                        CREATE (t)-[:USED_PATTERN]->(p)
                    """, task_id=task_id, pattern=pattern)
        
        # Update FAISS index
        embedding = self.model.encode([result_data])[0]
        self.index.add(np.array([embedding]).astype('float32'))
        self.task_metadata[self.index.ntotal - 1] = task_id
        
        # Save index periodically
        if self.index.ntotal % 10 == 0:
            faiss.write_index(self.index, '/opt/h100/faiss/knowledge.index')
        
        return intelligence_pb2.StoreResponse(success=True)
    
    def CrossAgentLearn(self, request, context):
        """Enable cross-agent learning"""
        source_agent = request.source_agent
        target_agent = request.target_agent
        
        with self.neo4j_driver.session() as session:
            result = session.run("""
                MATCH (source:Task {agent_type: $source_agent})-[:USED_PATTERN]->(p:Pattern)
                WHERE source.success = true
                WITH p, count(source) as usage
                ORDER BY p.success_rate DESC, usage DESC
                LIMIT 10
                RETURN p.description as pattern, p.success_rate as rate
            """, source_agent=source_agent)
            
            patterns = [{"pattern": r["pattern"], "rate": r["rate"]} for r in result]
        
        return intelligence_pb2.CrossAgentResponse(
            shared_patterns=json.dumps(patterns)
        )
    
    def _extract_patterns(self, result_data):
        """Extract patterns from result data"""
        patterns = []
        
        try:
            data = json.loads(result_data)
            if "code" in data:
                # Extract code patterns
                code = data["code"]
                if "import" in code:
                    patterns.append("uses_imports")
                if "async" in code:
                    patterns.append("uses_async")
                if "try:" in code:
                    patterns.append("has_error_handling")
        except:
            pass
        
        return patterns


def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    intelligence_pb2_grpc.add_SharedIntelligenceServicer_to_server(
        SharedIntelligenceService(), server
    )
    server.add_insecure_port('[::]:50051')
    server.start()
    print("H100 gRPC Server started on port 50051")
    server.wait_for_termination()


if __name__ == '__main__':
    serve()
