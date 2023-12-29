#!/bin/bash

## This bash script is to check for older images in AWS ECR repositories and delete the images as per latest retain count 
## This script can be executed on any environment/region.

total_repo=$(aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | grep repository | wc -l)

echo Total number of repositories is $total_repo

#### The total number of images to be retained as latest
retain_count=20 

echo Ignoring latest $retain_count images from each repo one by one, and listing the rest of images 

for repoName in $(aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | grep repository); do
	echo Found repository $repoName
	
	total_count=$(aws ecr describe-images --repository-name $repoName | grep imageDigest | awk -F ' ' '{print $2}' | tr -d '",' | wc -l)
	
	if [[ $total_count -gt $retain_count ]]; then
	  delete_count=$(($total_count-$retain_count))
	  echo Total images $total_count
	  echo Images to be deleted $delete_count
	  image_details=$(aws ecr describe-images --repository-name $repoName --query 'sort_by(imageDetails, &imagePushedAt)' | grep imageDigest | awk -F ' ' '{print $2}' | head -n $delete_count | tr -d '",')
	  for img in $image_details; do
	    aws ecr batch-delete-image --repository-name $repoName --image-ids imageDigest=$img | jq '.imageDetails[].imagePushedAt,.imageDetails[].imageDigest'
      done
	else 
	  
	  echo For this repo, Total images is $total_count only, no action required.
	fi
done
