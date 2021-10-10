//
//  Expectation.swift
//  DetoxTestRunner
//
//  Created by Alon Haiut on 10/10/2021.
//  Copyright © 2021 Wix. All rights reserved.
//

import Foundation
import XCTest

class Expectation : CustomStringConvertible {
	struct Keys {
		static let kind = "expectation"
		static let params = "params"
		static let predicate = "predicate"
		static let modifiers = "modifiers"
	}
	
	struct Kind {
		static let toBeVisible = "toBeVisible"
		static let toExist = "toExist"
		static let toHaveText = "toHaveText"
		static let toHaveLabel = "toHaveLabel"
		static let toHaveId = "toHaveId"
		static let toHaveValue = "toHaveValue"
		static let toHavePlaceholderValue = "toHavePlaceholderValue"
	}
	
	let element : Element
	let kind : String
	let modifiers : Set<String>
	
	required init(kind: String, modifiers: Set<String>, element: Element) {
		self.element = element
		self.kind = kind
		self.modifiers = modifiers
	}
	
	static let mapping : [String: Expectation.Type] = [
		Kind.toBeVisible: ToBeVisibleExpectation.self,
		Kind.toExist: ToExistExpectation.self,
		
		Kind.toHaveText: ValueExpectation.self,
		Kind.toHaveLabel: ValueExpectation.self,
		Kind.toHaveId: ValueExpectation.self,
		Kind.toHaveValue: ValueExpectation.self,
		Kind.toHavePlaceholderValue: ValueExpectation.self
	]
	
	static let keyMapping : [String: String] = [
		Kind.toHaveText: "label",
		Kind.toHaveLabel: "label",
		Kind.toHaveId: "identifier",
		Kind.toHaveValue: "value",
		Kind.toHavePlaceholderValue: "placeholderValue"
	]
	
	class func with(dictionaryRepresentation: [String: Any]) -> Expectation {
		let kind = dictionaryRepresentation[Keys.kind] as! String //crash on failure
		let params = dictionaryRepresentation[Keys.params] as! [CustomStringConvertible]?
		let modifiers : Set<String>
		if let modifiersInput = dictionaryRepresentation[Keys.modifiers] as? [String] {
			modifiers = Set<String>(modifiersInput)
		} else {
			modifiers = []
		}
		
		let element = Element.with(dictionaryRepresentation: dictionaryRepresentation)
		let expectationClass = mapping[kind]!
		if expectationClass == ValueExpectation.self {
			return ValueExpectation(kind: kind, modifiers: modifiers, element: element, key: keyMapping[kind]!, value: params!.first!)
		} else {
			return expectationClass.init(kind: kind, modifiers: modifiers, element: element)
		}
	}
	
	fileprivate func evaluate(with element: XCUIElement) -> Bool {
		fatalError("Unimplemented perform(on:) called for \(type(of: self))")
	}
	
	func evaluate(with application: XCUIApplication) -> Bool {
		let element = self.element.matchingElement(forQuery: application.descendants(matching: .any))
		
		return evaluate(with: element)
	}
	
	var description: String {
		get {
			return String(format: "%@%@ WITH %@", modifiers.contains(Modifier.not) ? "NOT " : "", self.kind.uppercased(), element.description)
		}
	}
}

class ToBeVisibleExpectation : Expectation {
	override func evaluate(with element: XCUIElement) -> Bool {
		return element.dtx_isVisible
	}
}

class ToExistExpectation : Expectation {
	override func evaluate(with element: XCUIElement) -> Bool {
		return element.exists
	}
}

class ValueExpectation : Expectation {
	let key : String
	let value : CustomStringConvertible
	
	required init(kind: String, modifiers: Set<String>, element: Element, key: String, value: CustomStringConvertible) {
		self.key = key
		self.value = value
		
		super.init(kind: kind, modifiers: modifiers, element: element)
	}
	
	required init(kind: String, modifiers: Set<String>, element: Element) {
		fatalError("Call the other initializer")
	}
	
	override func evaluate(with element: XCUIElement) -> Bool {
		return NSComparisonPredicate(leftExpression: NSExpression(forKeyPath: key), rightExpression: NSExpression(forConstantValue: value), modifier: .direct, type: modifiers.contains(Modifier.not) ? .notEqualTo : .equalTo, options: []).evaluate(with: element)
	}
	
	override var description: String {
		get {
			return String(format: "%@%@(%@) WITH %@", modifiers.contains(Modifier.not) ? "NOT " : "", self.kind.uppercased(), value.description, element.description)
		}
	}
}

