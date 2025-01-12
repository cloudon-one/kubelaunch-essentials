output "metadata_db_endpoint" {
  description = "Endpoint for Airflow metadata database"
  value       = aws_db_instance.airflow_metadata.endpoint
}

output "redis_endpoint" {
  description = "Endpoint for Airflow Redis instance"
  value       = aws_elasticache_cluster.airflow_celery.cache_nodes[0].address
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Airflow storage"
  value       = aws_s3_bucket.airflow.id
}