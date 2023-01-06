//
//  matrix-actions.metal
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

#include <metal_stdlib>
using namespace metal;

struct Complex {
public:
    float2 value;

    float module() {
        return sqrt(pow(value.x, 2) + pow(value.y, 2));
    }
    
    Complex(float re, float im) {
        value = float2(re, im);
    }

    Complex(float2 value) {
        this->value = value;
    }

    Complex operator+(Complex other) {
        return Complex(this->value + other.value);
    }

    Complex operator-(Complex other) {
        return Complex(this->value - other.value);
    }

    Complex operator*(Complex other) {
        return Complex(this->value.x * other.value.x - this->value.y * other.value.y, this->value.x * other.value.y + this->value.y * other.value.x);
    }
};

kernel void vectorMultMatrix(constant Complex *inputVector [[buffer(0)]],
                             constant Complex *matrix [[buffer(1)]],
                             device Complex *outputVector [[buffer(2)]],
                             constant float &size [[buffer(3)]],
                             ushort gid [[thread_position_in_grid]]
                             ) {
    outputVector[gid] = Complex(0, 0);

    for(int index = 0; index < size; index++) {
        outputVector[gid] = Complex(outputVector[gid].value) +
                            (Complex(inputVector[index].value) * Complex(matrix[gid * (int)size + index].value));
    }
}

kernel void matrixTensorMatrix(constant Complex *firstMatrix [[buffer(0)]],
                               constant Complex *secondMatrix [[buffer(1)]],
                               device Complex *outputMatrix [[buffer(2)]],
                               constant float &firstSize [[buffer(3)]],
                               constant float &secondSize [[buffer(4)]],
                               ushort2 gid [[thread_position_in_grid]]
                             ) {
    int resultSize = (int)(firstSize * secondSize);
    int index = gid.y * resultSize + gid.x;
    int2 pos = int2(index % resultSize, index / resultSize);

    ushort2 firstIndex = ushort2(pos.x / (int)secondSize, pos.y / (int)secondSize);
    ushort2 secondIndex = ushort2(pos.x % (int)secondSize, pos.y % (int)secondSize);

    outputMatrix[pos.y * resultSize + pos.x] =
    Complex(firstMatrix[firstIndex.y * (int)firstSize + firstIndex.x].value) *
    Complex(secondMatrix[secondIndex.y * (int)secondSize + secondIndex.x].value);
}

kernel void rotateMatrix(constant Complex *inputMatrix [[buffer(0)]],
                         device Complex *outputMatrix [[buffer(1)]],
                         constant float &size [[buffer(2)]],
                         ushort2 gid [[thread_position_in_grid]]
                         ) {
    int intsize = (int)size;
    int index = gid.y * intsize + gid.x;
    int2 pos = int2(index % intsize, index / intsize);

    outputMatrix[pos.y * intsize + pos.x] = inputMatrix[pos.x * intsize + pos.y];
}

int powMod(int x, int r, int m) {
    int result = 1;
    if (r == 0) return 1;

    for(int i = 0; i < r; i++) {
        result *= x;
        result %= m;
    }

    return result;
}

kernel void functionMatrix(device Complex *outputMatrix [[buffer(0)]],
                           constant float &size [[buffer(1)]],
                           constant float &x [[buffer(2)]],
                           constant float &m [[buffer(3)]],
                           constant float &outputSize [[buffer(4)]],
                           ushort2 gid [[thread_position_in_grid]]
                           ) {
    int intsize = (int)size;
    int outputInt = (int)outputSize;
    int index = gid.y * intsize + gid.x;
    int2 pos = int2(index % intsize, index / intsize);
    int value = powMod((int)x, pos.y >> outputInt, (int)m);

    int finalValue = ((pos.y >> outputInt) << outputInt) + value;

    outputMatrix[pos.y * intsize + pos.x] = Complex(finalValue == pos.x ? 1 : 0, 0);
}
