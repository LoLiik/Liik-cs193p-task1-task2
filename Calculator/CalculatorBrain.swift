//
//  CalculatorBrain.swift
//  MySmashTag
//
//  Created by Евгений on 10.03.2018.
//  Copyright © 2018 Евгений. All rights reserved.
//

import Foundation

struct CalculatorBrain {
    public var description: String? { // текущее описание операций (deprecated)
        get { return evaluate(using: namedVariableOperands).description }
    }
    
    public var result: Double? { // текущее числовое значение результата
        get { return evaluate(using: namedVariableOperands).result }
    }
    
    public var resultIsPending: Bool { // текущая готовность результата
        get { return evaluate(using: namedVariableOperands).isPending }
    }

    public mutating func setOperand (_ operand: Double){  // функция добавления числового операнда
        evaluationChain.append(.number(operand))
    }
    
    public mutating func setOperand(variable named: String){ // функция добавления именнованного операнда вычислительную цеполчку
        evaluationChain.append(.variable(named))
    }
    
    public mutating func performOperation(_ symbol: String) { // функция добавления операции
        evaluationChain.append(.operation(symbol))
    }
    
    public mutating func undo() { // функция отмены последнего действия
        if evaluationChain.count > 0 { evaluationChain.removeLast() }
    }
    
    public mutating func clear() { // функция очищения введённых ранее данных
        evaluationChain.removeAll()
        namedVariableOperands.removeAll()
    }
    
    public var chainLast:evaluationElement{
        get{return evaluationChain.last!}
    }
    
    public var chainIsEmpty:Bool{
        get{return evaluationChain.isEmpty}
    }
    
    private enum Operation { // возможные типы операций
        case nullaryOperation(() -> Double,String) // использутеся для формирования случайного значения
        case constant (Double)
        case unaryOperation ((Double) -> Double,((String) -> String)?, ((Double)->String?)?)
        case binaryOperation ((Double, Double) -> Double, ((String, String) -> String)?, ((Double,Double)->String?)?)
        case equals // операция равенства "="
    }
    
    private var operations : Dictionary <String,Operation> = [
        "Ran": Operation.nullaryOperation({ Double(arc4random())/Double(UInt32.max)},"rand()"),
        "π": Operation.constant(Double.pi),
        "e": Operation.constant(M_E),
        "±": Operation.unaryOperation({ -$0 },nil,nil),           // { "±(" + $0 + ")"}
        "√": Operation.unaryOperation(sqrt,nil, { $0 < 0 ? "Ошибка: корень от отрицательного числа" : nil}),              // { "√(" + $0 + ")"}
        "cos": Operation.unaryOperation(cos,nil,nil),             // { "cos(" + $0 + ")"}
        "sin": Operation.unaryOperation(sin,nil,nil),             // { "sin(" + $0 + ")"}
        "tan": Operation.unaryOperation(tan,nil, { $0 == 0 ? "Ошибка: tan от нуля" : nil}),             // { "tan(" + $0 + ")"}
        "sin⁻¹" : Operation.unaryOperation(asin,nil,{ $0 < -1 || $0 > 1 ? "sin⁻¹ от [-1:1]" : nil}),         // { "sin⁻¹(" + $0 + ")"}
        "cos⁻¹" : Operation.unaryOperation(acos,nil,{ $0 < -1 || $0 > 1 ? "cos⁻¹ от [-1:1]" : nil}),         // { "cos⁻¹(" + $0 + ")"}
        "tan⁻¹" : Operation.unaryOperation(atan, nil, nil),        // { "tan⁻¹(" + $0 + ")"}
        "ln" : Operation.unaryOperation(log,nil, nil),             //  { "ln(" + $0 + ")"}
        "x⁻¹" : Operation.unaryOperation({1.0/$0}, {"(" + $0 + ")⁻¹"},{ $0 == 0 ? "Ошибка: деление на ноль" : nil}),
        "х²" : Operation.unaryOperation({$0 * $0}, { "(" + $0 + ")²"},nil),
        "×": Operation.binaryOperation(*,nil,nil),                // { $0 + " × " + $1 }
        "÷": Operation.binaryOperation(/,nil,{ $1 == 0 ? "Ошибка: деление на ноль" : nil}),                // { $0 + " ÷ " + $1 } // { $1 == 0 ? "Деление на ноль" : nil}
        "+": Operation.binaryOperation(+,nil,nil),                // { $0 + " + " + $1 }
        "−": Operation.binaryOperation(-,nil,nil),                // { $0 + " - " + $1 }
        "xʸ" : Operation.binaryOperation(pow,{ $0 + " ^ " + $1 },{ $1 == 0 ? "Ошибка: деление на ноль" : nil}),
        "=": Operation.equals
    ]
    
    public enum evaluationElement { // возможные типы вычислительных элементов: числовой операнд, переменная (именнованный операнд), операция
        case number(Double)
        case variable(String)
        case operation(String)
    }
    
    private var evaluationChain:[evaluationElement] = [] // массив вычислительных элементов в последовательном порядке (порядке ввода пользователем) = "история операций" = "вычислительная цепочка"
    
    private struct PendingBinaryOperation {  // бинарная операция: функция, первый числовой операнд, функция описания, описательный операнд
        let function: (Double,Double) -> Double
        let firstOperand: Double
        var descriptionFunction: (String, String) -> String
        var descriptionOperand: String
        var errorFunction: ((Double, Double) -> String?)?
        func perform (with secondOperand: Double) -> Double { // выполнение операции
            return function (firstOperand, secondOperand)
        }
        func performDescription (with secondOperand: String) -> String { // форматирование описания
            return descriptionFunction ( descriptionOperand, secondOperand)
        }
    }
    
    public func evaluate(using variables: Dictionary<String,Double>? = nil) -> (result: Double?, isPending: Bool, description: String, error: String?){
        var localCache: (accumulator: Double?, descriptionAccumulator: String?, error: String? )
        var localPendingBinaryOperation:PendingBinaryOperation?
        var localDescription: String {
            get {
                if localPendingBinaryOperation == nil {
                    return localCache.descriptionAccumulator ?? " "
                } else {
                    return  localPendingBinaryOperation!.descriptionFunction(localPendingBinaryOperation!.descriptionOperand, localCache.descriptionAccumulator ?? " ")
                }
            } // get
        } // var
        
        var localResult: Double? {
            get { return localCache.accumulator }
        }
        
        var localResultIsPending: Bool {
            get { return localPendingBinaryOperation != nil }
        }
        
        var localError: String?{
            get { return localCache.error}
        }
        
        func  evaluatePendingBinaryOperation() {
            if let currentPendingBinaryOperation = localPendingBinaryOperation, localCache.accumulator != nil {
                if let error = currentPendingBinaryOperation.errorFunction?((currentPendingBinaryOperation.firstOperand), localCache.accumulator!){
                    localCache.error = error
                } else {
                    localCache.error = nil
                }
                print("error in .binaryOperation: \((localPendingBinaryOperation?.firstOperand)!), , \(localCache.accumulator!)")
                localCache.accumulator = currentPendingBinaryOperation.perform(with: localCache.accumulator!)
                localCache.descriptionAccumulator = currentPendingBinaryOperation.performDescription(with: localCache.descriptionAccumulator!)
                localPendingBinaryOperation = nil
            }
        }
        
        func evaluateOperation(_ symbol: String) {
            print("Evaluating operand: \(symbol)")
            if let operation = operations[symbol]{
                switch operation {
                case .nullaryOperation(let function, let descriptionValue):
                    localCache = (function(), descriptionValue, nil)
                    
                case .constant(let value):
                    localCache = (value,symbol,nil)
                    
                case .unaryOperation (let function, var descriptionFunction, let errorFunction):
                    if let error = errorFunction?(localCache.accumulator!){
                        localCache.error = error
                    } else {
                        localCache.error = nil
                    }
                    if localCache.accumulator != nil, localCache.error == nil{
                        localCache.accumulator = function (localCache.accumulator!)
                        if  descriptionFunction == nil{
                            descriptionFunction = {symbol + "(" + $0 + ")"}
                        }
                        localCache.descriptionAccumulator = descriptionFunction!(localCache.descriptionAccumulator!)
                        
                    }
                case .binaryOperation (let function, var descriptionFunction, let errorFunction):
                    if let _ = localPendingBinaryOperation{
                        evaluatePendingBinaryOperation()
                    }
                    if localCache.accumulator != nil {
                        if  descriptionFunction == nil{
                            descriptionFunction = {$0 + " " + symbol + " " + $1}
                        }
                        
                        localPendingBinaryOperation = PendingBinaryOperation (function: function,
                                                                         firstOperand: localCache.accumulator!,
                                                                         descriptionFunction: descriptionFunction!,
                                                                         descriptionOperand: localCache.descriptionAccumulator!,
                                                                         errorFunction: errorFunction)
                        localCache = (nil, nil, nil)
                    }
                case .equals:
                    evaluatePendingBinaryOperation()
                }// switch operation
            }// if let operation = operations[symbol]
        }// func evaluateOperation(
        
        print("\n evaluationChain: \(evaluationChain), \(namedVariableOperands)")
        for operand in evaluationChain{ // последовательное выполнение вычислитной цепочки операндов (истории операций) хранящихся в evaluationChain
            print("Local result:\(String(describing: localResult)), localResultIsPending:\(localResultIsPending), localDescription:\(localDescription), localError:\(String(describing: localError))")
            guard localError == nil else {break}
            switch operand{
            case .number(let number):
                localCache.accumulator = number
                if let value = localCache.accumulator {
                    localCache.descriptionAccumulator = formatter.string(from: NSNumber(value:value)) ?? ""
                }
            case .variable(let variable):
                if variables == nil{ //если словарь переменных пуст
                    localCache.accumulator = 0
                }
                else{
                    print("IN VARIABLE CASE: \(variable)")
                    if let variableValue = variables?[variable]{
                        localCache.accumulator = variableValue
                    } else { //если переменной нет в словаре
                        localCache.accumulator = 0
                    }
                }
                localCache.descriptionAccumulator = variable
            case .operation(let operation):
                evaluateOperation(operation)
            } // switch operand
        } // for operand in evaluationChain
        print("FINALLY Local result:\(String(describing: localResult)), localResultIsPending:\(localResultIsPending), localDescription:\(localDescription), localError:\(String(describing: localError))")
        return (localResult, localResultIsPending, localDescription, localError)
    }
}

public var namedVariableOperands:[String:Double] = [:] // словарь с именованными операндами и их значениями: "x":5.4, "m":3.78,.. для использования в вычислении

let formatter:NumberFormatter = { // форматтер числа в дисплее: 6 десятичных разрядов,
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.notANumberSymbol = "Error"
        formatter.groupingSeparator = " "
        formatter.locale = Locale.current
        return formatter
} () // необходимо именно вызвать () для инициализации данной константы-форматтера
