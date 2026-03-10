#!/bin/bash

# LOADING MODULES
module purge
module load slurm
module load nccl2-cuda11.8-gcc11/2.16.5
module load openmpi/gcc/64/4.1.5

BENCHMARKS=(
    "all_reduce_perf"
    "all_gather_perf"
    "broadcast_perf"
    "reduce_scatter_perf"
    "alltoall_perf"
    "reduce_perf"
    "sendrecv_perf"
)

export NCCL_DEBUG=TRACE
export NCCL_IB_DISABLE=0
export CUDA_VISIBLE_DEVICES=1,2

# HOSTS
HOSTS="n013:2"
TOTAL_GPUS=2

MPI_PATH=$(dirname $(dirname $(which mpirun)))

for TEST in "${BENCHMARKS[@]}"; do
    if [ -f "./build/$TEST" ]; then
        echo "============================================================"
        echo " RUNNING: $TEST"
        echo "============================================================"
        
        mpiexec --allow-run-as-root \
        --prefix "$MPI_PATH" \
        -H "$HOSTS" -np $TOTAL_GPUS \
        --mca btl tcp,self \
	--mca btl_tcp_if_include ibp209s0f0 \
        -x LD_LIBRARY_PATH \
	-x PATH \
        -x NCCL_DEBUG=TRACE \
	-x NCCL_DEBUG_SUBSYS=INIT,GRAPH,NET \
        -x NCCL_IB_DISABLE=0 \
	-x NCCL_IB_HCA=mlx5_2 \
	-x NCCL_NET_GDR_LEVEL=SYS \
	-x NCCL_SOCKET_IFNAME=ibp209s0f0 \
	-x CUDA_VISIBLE_DEVICES=1,2 \
        ./build/$TEST -b 8 -e 12G -f 2 -g 1 \
        2>&1 | tee "result__${TEST}.txt"
        
        echo "Done. Results saved to result_Medium_${TEST}_2GPUs.txt"
    else
        echo "SKIPPING: ./build/$TEST not found."
    fi
done
