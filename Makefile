# Makefile for FIO Test Suite Container

# Container configuration
IMAGE_NAME ?= fio-test-suite
IMAGE_TAG ?= latest
CONTAINER_NAME ?= fio-test
CONTAINER_RUNTIME ?= podman

# Ceph configuration directory (override with your actual path)
CEPH_DIR ?= /etc/ceph

# Test results directory on host
RESULTS_DIR ?= $(PWD)/fio-results

# Ceph monitor configuration (override when running)
CEPH_MON_IP ?= localhost
CEPH_MON_PORT ?= 6789

# FIO test configuration
FSIZE ?= 100G
FNAME ?= /mnt/fio-testfile
TEST_DIR ?= /root/test
FIO_IOENGINE ?= sync
FIO_IODEPTH ?= 64
FIO_NUMJOBS ?= 1
FIO_RUNTIME ?= 300

.PHONY: help build run start stop restart logs shell clean exec mount-ceph run-tests status remove prune

# Default target
help:
	@echo "FIO Test Suite - Container Management"
	@echo ""
	@echo "Build targets:"
	@echo "  make build              Build the container image"
	@echo ""
	@echo "Container lifecycle:"
	@echo "  make run                Build and run container with volume mounts"
	@echo "  make start              Start existing container"
	@echo "  make stop               Stop running container"
	@echo "  make restart            Restart container"
	@echo "  make remove             Remove container"
	@echo ""
	@echo "Container interaction:"
	@echo "  make shell              Open bash shell in container"
	@echo "  make exec CMD='...'     Execute command in container"
	@echo "  make logs               View container logs"
	@echo "  make status             Show container status"
	@echo ""
	@echo "Testing:"
	@echo "  make mount-ceph         Mount Ceph filesystem in container"
	@echo "  make run-tests          Run FIO tests (requires Ceph mounted)"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean              Stop and remove container"
	@echo "  make prune              Remove container and image"
	@echo ""
	@echo "Configuration (set as environment variables or in command):"
	@echo "  IMAGE_NAME=$(IMAGE_NAME)"
	@echo "  IMAGE_TAG=$(IMAGE_TAG)"
	@echo "  CONTAINER_NAME=$(CONTAINER_NAME)"
	@echo "  CEPH_DIR=$(CEPH_DIR)"
	@echo "  RESULTS_DIR=$(RESULTS_DIR)"
	@echo "  CEPH_MON_IP=$(CEPH_MON_IP)"
	@echo "  CEPH_MON_PORT=$(CEPH_MON_PORT)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run CEPH_DIR=/custom/ceph RESULTS_DIR=/var/fio-results"
	@echo "  make mount-ceph CEPH_MON_IP=10.0.0.5"
	@echo "  make run-tests FSIZE=200G FIO_NUMJOBS=4"

# Build the container image
build:
	@echo "Building container image: $(IMAGE_NAME):$(IMAGE_TAG)"
	$(CONTAINER_RUNTIME) build -t $(IMAGE_NAME):$(IMAGE_TAG) -f Containerfile .
	@echo "Build complete!"

# Create results directory if it doesn't exist
$(RESULTS_DIR):
	@echo "Creating results directory: $(RESULTS_DIR)"
	@mkdir -p $(RESULTS_DIR)

# Run container with all necessary mounts
run: build $(RESULTS_DIR)
	@echo "Starting container: $(CONTAINER_NAME)"
	@if [ ! -d "$(CEPH_DIR)" ]; then \
		echo "Warning: Ceph directory not found at $(CEPH_DIR)"; \
		echo "Set CEPH_DIR=/path/to/ceph/dir if different"; \
	fi
	@if [ ! -f "$(CEPH_DIR)/ceph.conf" ]; then \
		echo "Warning: ceph.conf not found in $(CEPH_DIR)"; \
	fi
	@if [ ! -f "$(CEPH_DIR)/ceph.client.admin.keyring" ]; then \
		echo "Warning: ceph.client.admin.keyring not found in $(CEPH_DIR)"; \
	fi
	$(CONTAINER_RUNTIME) run -d \
		--name $(CONTAINER_NAME) \
		--privileged \
		--net host \
		-v $(CEPH_DIR):/etc/ceph:ro \
		-v $(RESULTS_DIR):/root/test \
		$(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Container started successfully!"
	@echo "Use 'make shell' to access the container"
	@echo "Use 'make logs' to view container output"

# Start existing container
start:
	@echo "Starting container: $(CONTAINER_NAME)"
	$(CONTAINER_RUNTIME) start $(CONTAINER_NAME)

# Stop running container
stop:
	@echo "Stopping container: $(CONTAINER_NAME)"
	$(CONTAINER_RUNTIME) stop $(CONTAINER_NAME)

# Restart container
restart: stop start

# View container logs
logs:
	$(CONTAINER_RUNTIME) logs -f $(CONTAINER_NAME)

# Open shell in container
shell:
	@echo "Opening shell in container: $(CONTAINER_NAME)"
	@echo "Type 'exit' to return to host"
	$(CONTAINER_RUNTIME) exec -it $(CONTAINER_NAME) /bin/bash

# Execute arbitrary command in container
exec:
	@if [ -z "$(CMD)" ]; then \
		echo "Error: CMD not specified"; \
		echo "Usage: make exec CMD='your command here'"; \
		exit 1; \
	fi
	$(CONTAINER_RUNTIME) exec -it $(CONTAINER_NAME) $(CMD)

# Show container status
status:
	@echo "Container status:"
	@$(CONTAINER_RUNTIME) ps -a --filter name=$(CONTAINER_NAME)
	@echo ""
	@echo "Image info:"
	@$(CONTAINER_RUNTIME) images $(IMAGE_NAME)

# Mount Ceph filesystem in container
mount-ceph:
	@echo "Mounting Ceph filesystem..."
	@echo "Monitor: $(CEPH_MON_IP):$(CEPH_MON_PORT)"
	$(CONTAINER_RUNTIME) exec $(CONTAINER_NAME) bash -c "\
		mount -t ceph $(CEPH_MON_IP):$(CEPH_MON_PORT):/ /mnt \
		-o name=admin,secretfile=/etc/ceph/admin.key && \
		echo 'Ceph mounted successfully at /mnt' && \
		df -h /mnt"

# Run FIO tests in container
run-tests:
	@echo "Running FIO tests with configuration:"
	@echo "  FSIZE=$(FSIZE)"
	@echo "  FNAME=$(FNAME)"
	@echo "  TEST_DIR=$(TEST_DIR)"
	@echo "  FIO_IOENGINE=$(FIO_IOENGINE)"
	@echo "  FIO_IODEPTH=$(FIO_IODEPTH)"
	@echo "  FIO_NUMJOBS=$(FIO_NUMJOBS)"
	@echo "  FIO_RUNTIME=$(FIO_RUNTIME)"
	@echo ""
	$(CONTAINER_RUNTIME) exec -it $(CONTAINER_NAME) bash -c "\
		export FSIZE=$(FSIZE) && \
		export FNAME=$(FNAME) && \
		export TEST_DIR=$(TEST_DIR) && \
		export FIO_IOENGINE=$(FIO_IOENGINE) && \
		export FIO_IODEPTH=$(FIO_IODEPTH) && \
		export FIO_NUMJOBS=$(FIO_NUMJOBS) && \
		export FIO_RUNTIME=$(FIO_RUNTIME) && \
		cd /fio && \
		./run-fio.sh"

# Stop and remove container
clean: stop
	@echo "Removing container: $(CONTAINER_NAME)"
	$(CONTAINER_RUNTIME) rm $(CONTAINER_NAME)
	@echo "Container removed"

# Remove container and image
prune: clean
	@echo "Removing image: $(IMAGE_NAME):$(IMAGE_TAG)"
	$(CONTAINER_RUNTIME) rmi $(IMAGE_NAME):$(IMAGE_TAG)
	@echo "Image removed"

# Remove container (alias for clean)
remove: clean