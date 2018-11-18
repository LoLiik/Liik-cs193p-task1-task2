//
//  CalculatorBrain.swift
//  MySmashTag
//
//  Created by Евгений on 10.03.2018.
//  Copyright © 2018 Евгений. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    @IBOutlet weak var displayM: UILabel!
    @IBOutlet weak var tochka: UIButton!{
        didSet {
            tochka.setTitle(decimalSeparator, for: UIControlState())
        }
    }
    
    let decimalSeparator = formatter.decimalSeparator ?? "."
    
    var userInTheMiddleOfTyping = false
    
    @IBAction func touchDigit(_ sender: UIButton) {
        let digit = sender.currentTitle!
        if userInTheMiddleOfTyping {
            let textCurrentlyInDisplay = display.text!
            if (digit != decimalSeparator) || !(textCurrentlyInDisplay.contains(decimalSeparator)) {
                display.text = textCurrentlyInDisplay + digit
            }
        } else {
            display.text = digit
            userInTheMiddleOfTyping = true
        }
    }
    
    var displayValue: Double? {
        get {
            if let text = display.text, let value = formatter.number(from: text) as? Double{
                return value
            }
            return nil
        }
        set {
            if let error = brain.evaluate(using: namedVariableOperands).error{
                display.text = error
                history.text = brain.description! + (brain.resultIsPending ? " …" : " =")
            } else if let value = newValue {
                display.text = formatter.string(from: NSNumber(value:value))
                history.text = brain.description! + (brain.resultIsPending ? " …" : " =")
            } else {
                display.text = " "
                history.text = brain.description
            }
        }
    }
    
    private var brain = CalculatorBrain ()
    
    @IBAction func performOPeration(_ sender: UIButton) {
        if userInTheMiddleOfTyping {
            if let value = displayValue{
                brain.setOperand(value)
            }
            userInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        displayValue = brain.result
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        brain.clear()
        displayValue = nil
        userInTheMiddleOfTyping = false
        history.text = " "
    }
    
    @IBAction func backspace(_ sender: UIButton) {
        if userInTheMiddleOfTyping{
            guard !display.text!.isEmpty else {
                userInTheMiddleOfTyping = false
                return
            }
            display.text = String(display.text!.dropLast())
            if display.text!.isEmpty{
                displayValue = nil
                userInTheMiddleOfTyping = false}
        } else{
            guard !brain.chainIsEmpty else {
                displayValue = nil
                return
            }
            brain.undo()
            switch brain.chainLast{
                case .number(let value):
                    displayValue = value
                    history.text = brain.description!
                    brain.undo()
                    userInTheMiddleOfTyping = true
                default:
                    displayValue = brain.result
            }
        }
    }
    
    @IBAction func M(_ sender: UIButton) {
        self.brain.setOperand(variable: "M")
        history.text = brain.description!
        if let mValue = namedVariableOperands["M"]{
            displayM.text! = String(describing: mValue)
        } else{
            displayM.text! = "0"
        }
    }
    
    @IBAction func arrowM(_ sender: UIButton) {
        namedVariableOperands["M"] = displayValue!
        displayM.text! = display.text!
        displayValue = brain.result
    }
}

