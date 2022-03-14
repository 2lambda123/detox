//
//  InvokeHandler.swift (DetoxInvokeHandler)
//  Created by Asaf Korem (Wix.com) on 2022.
//

import Foundation

/// Handles JSON messages by parsing them and routing them into the relevant delegate
/// (`actionDelegate` or `expectationDelegate`) to handle the requested action or expectation on the
/// specified element (in which located by the provided `elementMatcher`).
public class InvokeHandler {
  /// Used to find elements by matching to a given pattern (the message predicate).
  private let elementMatcher: ElementMatcherProtocol

  /// Used to delegate actions on elements.
  private let actionDelegate: ActionDelegateProtocol

  /// Used to delegate expectations on elements.
  private let expectationDelegate: ExpectationDelegateProtocol

  /// Initializes the handler with given `elementMatcher`, `actionDelegate` and
  /// `expectationDelegate`.
  init(
    elementMatcher: ElementMatcherProtocol,
    actionDelegate: ActionDelegateProtocol,
    expectationDelegate: ExpectationDelegateProtocol
  ) {
    self.elementMatcher = elementMatcher
    self.actionDelegate = actionDelegate
    self.expectationDelegate = expectationDelegate
  }

  /// Handles the given `message` by parsing and calling the relevant delegate.
  /// - Returns: `nil` if nothing was requested by the message. Otherwise returns a value wrapped
  /// with `AnyCodable` object.
  public func handle(_ message: [String: AnyHashable]) throws -> AnyCodable? {
    let parsedMessage = try Message(from: message)
    return try handle(parsedMessage: parsedMessage)
  }

  private func handle(parsedMessage: Message) throws -> AnyCodable? {
    let elements = try findElements(by: parsedMessage.predicate)
    let element = try element(from: elements, at: parsedMessage.atIndex)

    switch parsedMessage.type {
      case .action:
        guard let action = parsedMessage.action else {
          throw Error.invalidActionType
        }

        guard action != .getAttributes else {
          return try getAttributes(from: elements)
        }

        try handleAction(
          on: element,
          type: action,
          params: parsedMessage.params,
          whileMessage: parsedMessage.whileMessage
        )

      case .expectation:
        try handleExpectation(
          on: element, type: parsedMessage.expectation!,
          params: parsedMessage.params,
          modifiers: parsedMessage.modifiers,
          timemout: parsedMessage.timeout
        )
    }

    return nil
  }

  // MARK: - Find element

  private func findElements(by predicate: MessagePredicate) throws -> [AnyHashable] {
    let pattern = try ElementPattern(from: predicate)
    return try elementMatcher.match(to: pattern)
  }

  private func element(from elements: [AnyHashable], at index: Int?) throws -> AnyHashable {
    let index = index ?? 0
    guard index >= 0, elements.count > index else {
      throw Error.noElementAtIndex
    }

    return elements[index]
  }

  // MARK: - Get attributes

  private func getAttributes(from elements: [AnyHashable]) throws -> AnyCodable {
    return try actionDelegate.getAttributes(from: elements)
  }

  // MARK: - Handle actions

  private func handleAction(
    on element: AnyHashable, type: ActionType, params: [AnyCodable]?, whileMessage: WhileMessage?
  ) throws {
    guard let whileMessage = whileMessage else {
      try handleAction(on: element, type: type, params: params)
      return
    }

    while (true) {
      do {
        try handleWhileMessage(whileMessage)
      } catch {
        try handleAction(on: element, type: type, params: params)

        // Continue to next iteration if expectation is not fulfilled.
        continue
      }

      break
    }
  }

  private func handleAction(
    on element: AnyHashable, type: ActionType, params: [AnyCodable]?
  ) throws {
    try actionDelegate.act(
      action: action(type: type, params: params),
      on: element
    )
  }

  private func action(type: ActionType, params: [AnyCodable]?) throws -> Action {
    switch type {
      case .tap:
        return try tapAction(params: params)

      case .multiTap:
        return try multiTapAction(params: params)

      case .longPress:
        return try longPressAction(params: params)

      case .swipe:
        return try swipeAction(params: params)

      case .takeScreenshot:
        return try screenshotAction(params: params)

      case .tapBackspaceKey:
        return .tapKey(.backspaceKey)

      case .tapReturnKey:
        return .tapKey(.returnKey)

      case .typeText:
        return try typeTextAction(params: params)

      case .replaceText:
        return try replaceTextAction(params: params)

      case .clearText:
        return .changeText(.clear)

      case .scrollTo:
        return try scrollToAction(params: params)

      case .scroll:
        return try scrollAction(params: params)

      case .setColumnToValue:
        return try setColumnToValueAction(params: params)

      case .setDatePickerDate:
        return try setDatePickerAction(params: params)

      case .pinch:
        return try pinchAction(params: params)

      case .adjustSliderToPosition:
        return try adjustSliderAction(params: params)

      case .getAttributes:
        throw Error.invalidActionHandlingRequest
    }
  }

  private func handleWhileMessage(_ whileMessage: WhileMessage) throws {
    let elements = try findElements(by: whileMessage.predicate)
    let element = try element(from: elements, at: whileMessage.atIndex)

    try handleExpectation(
      on: element, type: whileMessage.expectation,
      params: whileMessage.params,
      modifiers: whileMessage.modifiers,
      timemout: nil
    )
  }

  private func tapAction(params: [AnyCodable]?) throws -> Action {
    guard let params = params else {
      return .tap()
    }

    let axisParam = (params.first?.value)! as! [String: Int]
    let x = axisParam["x"]!
    let y = axisParam["y"]!

    return .tapOnAxis(x: x, y: y)
  }

  private func multiTapAction(params: [AnyCodable]?) throws -> Action {
    return .tap(times: UInt(params!.first!.value as! Int))
  }

  private func longPressAction(params: [AnyCodable]?) throws -> Action {
    guard let params = params else {
      return .longPress
    }

    return .longPressAndDrag(
      duration: (params[0].value as? NSNumber)?.doubleValue,
      normalizedPositionX: (params[1].value as? NSNumber)?.doubleValue,
      normalizedPositionY: (params[2].value as? NSNumber)?.doubleValue,
      targetElement: params[3].value as! AnyHashable,
      normalizedTargetPositionX: (params[4].value as? NSNumber)?.doubleValue,
      normalizedTargetPositionY: (params[5].value as? NSNumber)?.doubleValue,
      speed: (params[6].value as? NSNumber)?.doubleValue,
      holdDuration: (params[7].value as? NSNumber)?.doubleValue
    )
  }

  private func swipeAction(params: [AnyCodable]?) throws -> Action {
    let direction: Action.SwipeDirection = .init(rawValue: (params?[0].value as! String))!

    let speedString = params?[1].value as? String
    let speed: Action.ActionSpeed? = speedString != nil ? .init(rawValue: speedString!)! : nil

    return .swipe(
      direction: direction,
      speed: speed,
      normalizedOffset: (params?[2].value as? NSNumber)?.doubleValue,
      normalizedStartingPointX: (params?[3].value as? NSNumber)?.doubleValue,
      normalizedStartingPointY: (params?[4].value as? NSNumber)?.doubleValue
    )
  }

  private func screenshotAction(params: [AnyCodable]?) throws -> Action {
    return .screenshot(imageName: params?[0].value as? String)
  }

  private func typeTextAction(params: [AnyCodable]?) throws -> Action {
    return .changeText(.type(params!.first!.value as! String))
  }

  private func replaceTextAction(params: [AnyCodable]?) throws -> Action {
    return .changeText(.replace(params!.first!.value as! String))
  }

  private func scrollToAction(params: [AnyCodable]?) throws -> Action {
    return .scroll(.to(.init(rawValue: params!.first!.value as! String)!))
  }

  private func scrollAction(params: [AnyCodable]?) throws -> Action {
    return .scroll(.withParams(
      offset: (params?[0].value as? NSNumber)!.doubleValue,
      direction: .init(rawValue: params![1].value as! String)!,
      startNormalizedPositionX: (params![2].value as? NSNumber)?.doubleValue,
      startNormalizedPositionY: (params![3].value as? NSNumber)?.doubleValue)
    )
  }

  private func setColumnToValueAction(params: [AnyCodable]?) throws -> Action {
    return .setColumnToValue(
      index: UInt(params?[0].value as! Int),
      value: params?[1].value as! String
    )
  }

  private func setDatePickerAction(params: [AnyCodable]?) throws -> Action {
    let dateString = params?[0].value as! String
    let formatString = params?[1].value as! String

    let date = date(from: dateString, using: formatString)!

    return .setDatePicker(date: date)
  }

  private func date(from dateString: String, using formatString: String) -> Date? {
    if formatString == "ISO8601" {
      return ISO8601DateFormatter().date(from: dateString)
    }

    let dateFormatter = dateFormatter(from: formatString)
    return dateFormatter.date(from: dateString)
  }

  private func dateFormatter(from format: String) -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = format

    return dateFormatter
  }

  private func pinchAction(params: [AnyCodable]?) throws -> Action {
    return .pinch(
      scale: (params![0].value as! NSNumber).doubleValue,
      speed: .init(rawValue: params![1].value as! String)!,
      angle: (params![2].value as! NSNumber).doubleValue
    )
  }

  private func adjustSliderAction(params: [AnyCodable]?) throws -> Action {
    return .adjustSlider(normalizedPosition: (params!.first?.value as! NSNumber).doubleValue)
  }

  // MARK: - Handle expectations

  private func handleExpectation(
    on element: AnyHashable,
    type: ExpectationType,
    params: [AnyCodable]?,
    modifiers: [MessagePredicateModifiers]?,
    timemout: Double?
  ) throws {
    let isTruthy: Bool = modifiers?.contains(.not) != true

    try expectationDelegate.expect(
      expectation(type: type, params: params),
      isTruthy: isTruthy,
      on: element,
      timeout: timemout
    )
  }

  private func expectation(type: ExpectationType, params: [AnyCodable]?) throws -> Expectation {
    switch type {
      case .toBeVisible:
        return try visibilityExpectation(params: params)

      case .toBeFocused:
        return .toBeFocused

      case .toHaveText:
        return try textExpectation(params: params)

      case .toHaveId:
        return try idExpectation(params: params)

      case .toHaveSliderPosition:
        return try sliderPositionExpectation(params: params)

      case .toExist:
        return .toExist
    }
  }

  private func visibilityExpectation(params: [AnyCodable]?) throws -> Expectation {
    let threshold = (params?.first?.value as? NSNumber)?.doubleValue
    return .toBeVisible(threshold: threshold ?? 75)
  }

  private func textExpectation(params: [AnyCodable]?) throws -> Expectation {
    let text = (params?.first?.value)! as! String
    return .toHaveText(text)
  }

  private func idExpectation(params: [AnyCodable]?) throws -> Expectation {
    let id = (params?.first?.value)! as! String
    return .toHaveId(id)
  }

  private func sliderPositionExpectation(params: [AnyCodable]?) throws -> Expectation {
    let normalizedPosition = ((params?.first?.value)! as! NSNumber).doubleValue
    let tolerance = params?.count == 2 ? (params?[1].value as? NSNumber)?.doubleValue : nil
    return .toHaveSliderInPosition(normalizedPosition: normalizedPosition, tolerance: tolerance)
  }
}