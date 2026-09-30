#!/usr/bin/env bash
set -euo pipefail

workspace_dir="/home/e_rakesh176_gmail_com/medgemma-work"
bundle_prefix="gs://vueniverse-508413-medgemma-training/resurrection/20260918-lora-v7-final"

cd "$workspace_dir"

for bundle_dir in configs datasets docs models reports runs tooling deployment; do
  gcloud storage rsync --recursive "$bundle_dir" "$bundle_prefix/workspace/$bundle_dir"
done

gcloud storage rsync --recursive resurrection-manifest "$bundle_prefix/manifest"
gcloud storage cp ./*.py ./*.sh "$bundle_prefix/workspace/source-scripts/"
gcloud storage ls --recursive "$bundle_prefix" > resurrection-manifest/UPLOADED-OBJECTS.txt
gcloud storage cp resurrection-manifest/UPLOADED-OBJECTS.txt "$bundle_prefix/manifest/UPLOADED-OBJECTS.txt"

printf '%s\n' 'RESURRECTION_UPLOAD_EXIT=0' | tee resurrection-manifest/upload-status.log
gcloud storage cp resurrection-manifest/upload-status.log "$bundle_prefix/manifest/upload-status.log"
