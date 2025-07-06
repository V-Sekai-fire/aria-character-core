#!/bin/bash
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Setup script for CUDA 12.8 support with TorchX on RTX 4090

echo "Setting up CUDA 12.8 for RTX 4090..."

# Set LibTorch target for CUDA 12.8
export LIBTORCH_TARGET=cu128

# Set CUDA paths
export PATH="/usr/local/cuda-12.8/bin:$PATH"
export CUDACXX="/usr/local/cuda-12.8/bin/nvcc"
export LD_LIBRARY_PATH="/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH"

echo "Environment variables set:"
echo "LIBTORCH_TARGET=$LIBTORCH_TARGET"
echo "CUDACXX=$CUDACXX"
echo "PATH includes: /usr/local/cuda-12.8/bin"

# Clean previous failed attempts
echo "Cleaning previous compilation attempts..."
mix deps.clean torchx --build
mix clean

# Install dependencies with CUDA support
echo "Installing dependencies with CUDA support..."
mix deps.get

# Compile with CUDA support
echo "Compiling with CUDA support..."
mix compile

echo "Setup complete! TorchX should now use CUDA 12.8 for GPU acceleration."
echo "Your RTX 4090 should now be available for tensor operations."
