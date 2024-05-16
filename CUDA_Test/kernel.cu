#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>     /* srand, rand */
#include <chrono>
#include <iostream>

__global__ void vectorAdd(int* a, int* b, int* c) 
{
    int i = threadIdx.x;
    c[i] = a[i] + b[i] * (b[i] % 5);
    
    return;
}

template<typename Func>
void benchmark(Func func) {
    auto start = std::chrono::high_resolution_clock::now();
    
    func();
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    std::cout << "Time taken by function: " << duration.count() << " microseconds" << std::endl;
}

int main()
{
    const int items = 50000;
    int a[items];
    int b[items];

    for (int i = 0; i < items; i++) {
        a[i] = rand() % 1000000;
        b[i] = rand() % 1000000;
    }

    int c[sizeof(a) / sizeof(int)] = { 0 };
    int d[sizeof(a) / sizeof(int)] = { 0 };

    //create pointers into the gpu
    int* cudaA = 0;
    int* cudaB = 0;
    int* cudaC = 0;

    //allocate memory in the gpu
    cudaMalloc(&cudaA, sizeof(a));
    cudaMalloc(&cudaB, sizeof(b));
    cudaMalloc(&cudaC, sizeof(c));

    //copy the vecors into the gpu
    cudaMemcpy(cudaA, a, sizeof(a), cudaMemcpyHostToDevice);
    cudaMemcpy(cudaB, b, sizeof(b), cudaMemcpyHostToDevice);


    benchmark([&]() {
        for (int i = 0; i < items; i++) {
            d[i] = a[i] + b[i] * (b[i] % 5);
        }
    });
    benchmark([&]() {
        vectorAdd <<<1, 1024 >> > (cudaA, cudaB, cudaC);
    });
        cudaMemcpy(c, cudaC, sizeof(c), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();

    return 0;
}
