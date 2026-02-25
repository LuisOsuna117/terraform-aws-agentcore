#!/usr/bin/env bash
# ==============================================================================
# build-image.sh — part of terraform-aws-agentcore
# https://github.com/LuisOsuna117/terraform-aws-agentcore
#
# Starts an AWS CodeBuild build, monitors its progress, and verifies the
# resulting image exists in ECR. Called automatically by the null_resource
# trigger in codebuild.tf — not intended to be run manually.
#
# Usage:
#   build-image.sh <project-name> <region> <ecr-repo-name> <image-tag> <ecr-repo-url>
#
# Environment variables (optional):
#   BUILD_TIMEOUT_MINUTES   Max minutes to wait for the build (default: 60)
#   NO_COLOR                Set to any value to disable coloured output
#
# Requirements: bash >= 4, AWS CLI v2
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Argument validation
# ------------------------------------------------------------------------------

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <project-name> <region> <ecr-repo-name> <image-tag> <ecr-repo-url>" >&2
  exit 1
fi

PROJECT_NAME="$1"
REGION="$2"
REPO_NAME="$3"
IMAGE_TAG="$4"
REPO_URL="$5"

# Timeout: respect BUILD_TIMEOUT_MINUTES env var, otherwise default to 60.
TIMEOUT_MINUTES="${BUILD_TIMEOUT_MINUTES:-60}"
POLL_INTERVAL=10  # seconds between status polls
MAX_ATTEMPTS=$(( TIMEOUT_MINUTES * 60 / POLL_INTERVAL ))

# ------------------------------------------------------------------------------
# Colour helpers — disabled automatically when NO_COLOR is set or stdout is not
# a TTY (e.g. CI log files), so output stays readable everywhere.
# ------------------------------------------------------------------------------

if [[ -z "${NO_COLOR:-}" && -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

print_header() {
  echo ""
  echo -e "${BLUE}================================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}================================================${NC}"
}
print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[⚠]${NC} $1"; }
print_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }

# ------------------------------------------------------------------------------
# Start build
# ------------------------------------------------------------------------------

print_header "terraform-aws-agentcore — Build Agent Image"

print_info "Project  : ${PROJECT_NAME}"
print_info "Region   : ${REGION}"
print_info "Image    : ${REPO_URL}:${IMAGE_TAG}"
print_info "Timeout  : ${TIMEOUT_MINUTES} minutes"
echo ""

print_info "Starting CodeBuild project..."

if ! BUILD_ID=$(aws codebuild start-build \
      --project-name "${PROJECT_NAME}" \
      --region "${REGION}" \
      --query 'build.id' \
      --output text 2>&1); then
  print_error "Failed to start CodeBuild:"
  echo "${BUILD_ID}" >&2
  exit 1
fi

CONSOLE_URL="https://${REGION}.console.aws.amazon.com/codesuite/codebuild/projects/${PROJECT_NAME}/build/${BUILD_ID}/log?region=${REGION}"

print_success "Build started: ${BUILD_ID}"
print_info "Logs: ${CONSOLE_URL}"
echo ""

# ------------------------------------------------------------------------------
# Monitor build progress
# ------------------------------------------------------------------------------

print_header "Waiting for Build to Complete"

ATTEMPT=0

while [[ ${ATTEMPT} -lt ${MAX_ATTEMPTS} ]]; do
  ATTEMPT=$(( ATTEMPT + 1 ))

  STATUS=$(aws codebuild batch-get-builds \
    --ids "${BUILD_ID}" \
    --region "${REGION}" \
    --query 'builds[0].buildStatus' \
    --output text 2>/dev/null)

  case "${STATUS}" in
    SUCCEEDED)
      print_success "Build succeeded."
      break
      ;;
    FAILED|FAULT|TIMED_OUT|STOPPED)
      echo ""
      print_error "Build ended with status '${STATUS}'."
      print_info  "Review the full build log:"
      print_info  "  ${CONSOLE_URL}"
      exit 1
      ;;
    IN_PROGRESS)
      # Log progress every minute
      if [[ $(( ATTEMPT % ( 60 / POLL_INTERVAL ) )) -eq 0 ]]; then
        ELAPSED=$(( ATTEMPT * POLL_INTERVAL / 60 ))
        print_info "Still in progress... (${ELAPSED}/${TIMEOUT_MINUTES} min elapsed)"
      fi
      sleep "${POLL_INTERVAL}"
      ;;
    *)
      print_error "Unexpected build status '${STATUS}'. Aborting."
      exit 1
      ;;
  esac
done

if [[ ${ATTEMPT} -ge ${MAX_ATTEMPTS} ]]; then
  print_error "Timed out after ${TIMEOUT_MINUTES} minutes waiting for build to complete."
  print_info  "The build may still be running. Check:"
  print_info  "  ${CONSOLE_URL}"
  exit 1
fi

echo ""

# ------------------------------------------------------------------------------
# Verify image in ECR
# ------------------------------------------------------------------------------

print_header "Verifying Image in ECR"

print_info "Checking for ${REPO_NAME}:${IMAGE_TAG}..."
sleep 5  # brief wait for ECR to register the push

MAX_VERIFY=12   # 1 minute (12 * 5 s)
VERIFY=0

while [[ ${VERIFY} -lt ${MAX_VERIFY} ]]; do
  VERIFY=$(( VERIFY + 1 ))

  if aws ecr describe-images \
       --repository-name "${REPO_NAME}" \
       --image-ids imageTag="${IMAGE_TAG}" \
       --region "${REGION}" > /dev/null 2>&1; then

    IMAGE_SIZE=$(aws ecr describe-images \
      --repository-name "${REPO_NAME}" \
      --image-ids imageTag="${IMAGE_TAG}" \
      --region "${REGION}" \
      --query 'imageDetails[0].imageSizeInBytes' \
      --output text 2>/dev/null || echo "")

    echo ""
    print_success "Image verified in ECR."
    print_info    "URI  : ${REPO_URL}:${IMAGE_TAG}"
    if [[ -n "${IMAGE_SIZE}" && "${IMAGE_SIZE}" != "None" ]]; then
      print_info  "Size : $(( IMAGE_SIZE / 1024 / 1024 )) MB"
    fi
    echo ""
    print_success "Done — agent image is ready."
    exit 0
  fi

  if [[ $(( VERIFY % 3 )) -eq 0 ]]; then
    print_info "Waiting for ECR propagation... (${VERIFY}/${MAX_VERIFY})"
  fi
  sleep 5
done

# ------------------------------------------------------------------------------
# ECR verification failed
# ------------------------------------------------------------------------------

echo ""
print_error "Image '${REPO_NAME}:${IMAGE_TAG}' was not found in ECR after the build completed."
print_warning "The build may have succeeded but the Docker push step failed."
echo ""
print_info "Troubleshooting:"
print_info "  1. Review the CodeBuild log:"
print_info "       ${CONSOLE_URL}"
print_info "  2. Confirm the image manually:"
print_info "       aws ecr describe-images --repository-name ${REPO_NAME} --region ${REGION}"
print_info "  3. Verify the CodeBuild IAM role has ecr:PutImage on the repository."

exit 1
