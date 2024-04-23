//
//  MetalContext.swift
//  quantum-speedup
//
//  Created by Rustam Khakhuk on 12.11.2022.
//

import Foundation
import Metal
import MetalKit

public class MetalContext {
    private let device: MTLDevice
    private let queue: MTLCommandQueue

    private let libriary: MTLLibrary
    private let vectorMultMatrixPipeline: MTLComputePipelineState
    private let matrixMultMatrixPipeline: MTLComputePipelineState
    private let matrixPlusMatrixPipeline: MTLComputePipelineState
    private let matrixTensorMatrixPipeline: MTLComputePipelineState
    private let matrixRotatePipeline: MTLComputePipelineState
    private let functionMatrixPipeline: MTLComputePipelineState

    static let shared = MetalContext()

    public init() {
        device = MTLCreateSystemDefaultDevice()!
        queue = device.makeCommandQueue()!

        libriary = device.makeDefaultLibrary()!

        vectorMultMatrixPipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "vectorMultMatrix")!)
        matrixMultMatrixPipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "matrixMultMatrix")!)
        matrixPlusMatrixPipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "matrixPlusMatrix")!)
        matrixTensorMatrixPipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "matrixTensorMatrix")!)
        matrixRotatePipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "rotateMatrix")!)
        functionMatrixPipeline = try! device.makeComputePipelineState(function: libriary.makeFunction(name: "functionMatrix")!)
    }

    public func vectorMultMatrix(vector: Vector, matrix: Matrix) -> Vector {
        let result = Vector(values: .init(repeating: 0, count: vector.values.count))
        var size = Float(result.values.count)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(vectorMultMatrixPipeline)

        let vectorBuffer = device.makeBuffer(bytes: vector.values, length: MemoryLayout<Complex>.stride * vector.values.count)!
        let matrixBuffer = device.makeBuffer(bytes: matrix.values, length: MemoryLayout<Complex>.stride * matrix.values.count)!
        let outputVectorBuffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<Float>.stride)!

        encoder.setBuffer(vectorBuffer, offset: 0, index: 0)
        encoder.setBuffer(matrixBuffer, offset: 0, index: 1)
        encoder.setBuffer(outputVectorBuffer, offset: 0, index: 2)
        encoder.setBuffer(sizeBuffer, offset: 0, index: 3)

        let threadGroupSize = MTLSize(width: vectorMultMatrixPipeline.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.size) / Double(vectorMultMatrixPipeline.maxTotalThreadsPerThreadgroup))), height: 1, depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = outputVectorBuffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        outputVectorBuffer.setPurgeableState(.empty)

        return result
    }

    public func matrixMultMatrix(matrixLeft: Matrix, matrixRight: Matrix) -> Matrix {
        let result = Matrix(values: .init(repeating: 0, count: matrixLeft.values.count))
        var size = Float(result.size)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(matrixMultMatrixPipeline)

        let firstMatrixBuffer = device.makeBuffer(bytes: matrixLeft.values, length: MemoryLayout<Complex>.stride * matrixLeft.values.count)!
        let secondMatrixBuffer = device.makeBuffer(bytes: matrixRight.values, length: MemoryLayout<Complex>.stride * matrixRight.values.count)!
        let outputVectorBuffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<Float>.stride)!

        encoder.setBuffer(firstMatrixBuffer, offset: 0, index: 0)
        encoder.setBuffer(secondMatrixBuffer, offset: 0, index: 1)
        encoder.setBuffer(outputVectorBuffer, offset: 0, index: 2)
        encoder.setBuffer(sizeBuffer, offset: 0, index: 3)

        let threadGroupSize = MTLSize(width: matrixMultMatrixPipeline.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.values.count) / Double(matrixMultMatrixPipeline.maxTotalThreadsPerThreadgroup))), height: 1, depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = outputVectorBuffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        outputVectorBuffer.setPurgeableState(.empty)

        return result
    }

    public func matrixPlusMatrix(matrixLeft: Matrix, matrixRight: Matrix) -> Matrix {
        let result = Matrix(values: .init(repeating: 0, count: matrixLeft.values.count))
        var size = Float(result.size)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(matrixPlusMatrixPipeline)

        let firstMatrixBuffer = device.makeBuffer(bytes: matrixLeft.values, length: MemoryLayout<Complex>.stride * matrixLeft.values.count)!
        let secondMatrixBuffer = device.makeBuffer(bytes: matrixRight.values, length: MemoryLayout<Complex>.stride * matrixRight.values.count)!
        let outputVectorBuffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<Float>.stride)!

        encoder.setBuffer(firstMatrixBuffer, offset: 0, index: 0)
        encoder.setBuffer(secondMatrixBuffer, offset: 0, index: 1)
        encoder.setBuffer(outputVectorBuffer, offset: 0, index: 2)
        encoder.setBuffer(sizeBuffer, offset: 0, index: 3)

        let threadGroupSize = MTLSize(width: matrixPlusMatrixPipeline.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.values.count) / Double(matrixPlusMatrixPipeline.maxTotalThreadsPerThreadgroup))), height: 1, depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = outputVectorBuffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        outputVectorBuffer.setPurgeableState(.empty)

        return result
    }

    public func MatrixTensorMatrix(m1: Matrix, m2: Matrix) -> Matrix {
        let result = Matrix(values: .init(repeating: 0, count: Int(powf(Float(m1.size * m2.size), 2))))
        var firstSize = Float(m1.size)
        var secondSize = Float(m2.size)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(matrixTensorMatrixPipeline)

        let m1Buffer = device.makeBuffer(bytes: m1.values, length: MemoryLayout<Complex>.stride * m1.values.count)!
        let m2Buffer = device.makeBuffer(bytes: m2.values, length: MemoryLayout<Complex>.stride * m2.values.count)!
        let outputMatrixBuffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let firstSizeBuffer = device.makeBuffer(bytes: &firstSize, length: MemoryLayout<Float>.stride)!
        let secondSizeBuffer = device.makeBuffer(bytes: &secondSize, length: MemoryLayout<Float>.stride)!

        encoder.setBuffer(m1Buffer, offset: 0, index: 0)
        encoder.setBuffer(m2Buffer, offset: 0, index: 1)
        encoder.setBuffer(outputMatrixBuffer, offset: 0, index: 2)
        encoder.setBuffer(firstSizeBuffer, offset: 0, index: 3)
        encoder.setBuffer(secondSizeBuffer, offset: 0, index: 4)

        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.size) / 32.0)), height: Int(ceil(Double(result.size) / 32.0)), depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = outputMatrixBuffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        outputMatrixBuffer.setPurgeableState(.empty)

        return result
    }

    public func rotateMatrix(matrix: Matrix) -> Matrix {
        let result = Matrix(values: .init(repeating: 0, count: matrix.values.count))
        var size = Float(matrix.size)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(matrixRotatePipeline)

        let m1Buffer = device.makeBuffer(bytes: matrix.values, length: MemoryLayout<Complex>.stride * matrix.values.count)!
        let m2Buffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<Float>.stride)

        encoder.setBuffer(m1Buffer, offset: 0, index: 0)
        encoder.setBuffer(m2Buffer, offset: 0, index: 1)
        encoder.setBuffer(sizeBuffer, offset: 0, index: 2)

        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.size) / 32.0)), height: Int(ceil(Double(result.size) / 32.0)), depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = m2Buffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        m2Buffer.setPurgeableState(.empty)

        return result
    }

    public func functionMatrix(x: Int, m: Int, outputSize: Int, size: Int) -> Matrix {
        let result = Matrix(values: .init(repeating: 0, count: size * size))
        var size = Float(size)
        var x = Float(x)
        var m = Float(m)
        var outputSize = Float(outputSize)

        let buffer = queue.makeCommandBuffer()!
        let encoder = buffer.makeComputeCommandEncoder()!

        encoder.setComputePipelineState(functionMatrixPipeline)

        let mBuffer = device.makeBuffer(bytes: result.values, length: MemoryLayout<Complex>.stride * result.values.count, options: .storageModeShared)!
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<Float>.stride)

        encoder.setBuffer(mBuffer, offset: 0, index: 0)
        encoder.setBuffer(sizeBuffer, offset: 0, index: 1)
        encoder.setBuffer(device.makeBuffer(bytes: &x, length: MemoryLayout<Float>.stride), offset: 0, index: 2)
        encoder.setBuffer(device.makeBuffer(bytes: &m, length: MemoryLayout<Float>.stride), offset: 0, index: 3)
        encoder.setBuffer(device.makeBuffer(bytes: &outputSize, length: MemoryLayout<Float>.stride), offset: 0, index: 4)

        let threadGroupSize = MTLSize(width: 32, height: 32, depth: 1)
        let threadGroupCount = MTLSize(width: Int(ceil(Double(result.size) / 32.0)), height: Int(ceil(Double(result.size) / 32.0)), depth: 1)

        encoder.dispatchThreadgroups(threadGroupCount, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        buffer.commit()
        buffer.waitUntilCompleted()

        let resultContent = mBuffer.contents()
        result.values = resultContent.toArray(capacity: result.values.count)

        mBuffer.setPurgeableState(.empty)

        return result
    }
}

extension UnsafeMutableRawPointer {
    func toArray<T>(capacity count: Int) -> [T] {
        let pointer = bindMemory(to: T.self, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
}
