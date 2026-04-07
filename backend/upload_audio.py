import boto3

# Create S3 client
s3 = boto3.client('s3')

# Bucket name
bucket_name = "urban-noise-audio-storage"

# File to upload
file_name = "test-noise.mp3"

# Upload file
s3.upload_file(file_name, bucket_name, file_name)

print("File uploaded successfully!")