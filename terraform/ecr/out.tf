output "api_repository_url" {
  value = aws_ecr_repository.repositories["api"].repository_url
}