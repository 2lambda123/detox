//
//  ActionDelegate.swift (DetoxTester)
//  Created by Asaf Korem (Wix.com) on 2022.
//

import DetoxInvokeHandler
import Foundation
import XCTest

class ActionDelegate: ActionDelegateProtocol {
  let app: XCUIApplication

  let whiteBoxMessageHandler: WhiteBoxMessageHandler

  init(_ app: XCUIApplication, whiteBoxMessageHandler: @escaping WhiteBoxMessageHandler) {
    self.app = app
    self.whiteBoxMessageHandler = whiteBoxMessageHandler
  }

  /// Make an action by Detox Tester.
  func act(action: Action, on element: AnyHashable) throws {
    try act(action: action, on: element, testCase: DetoxTester.shared.testCase!)
  }

  /// Used for unit testing.
  func act(
    action: Action,
    on element: AnyHashable,
    testCase: XCTestCase
  ) throws {
    guard let element = element as? XCUIElement else {
      throw ActionDelegateError.notXCUIElement
    }

    uiLog(
      "wait until ready to handle action: `\(action.name)`, on element: " +
      "`\(element.debugDescription)`"
    )

    whiteBoxMessageHandler(.waitUntilReady)?.assertResponse(equalsTo: .completed)

    uiLog("handling action: `\(action.name)`, on element: `\(element.debugDescription)`")

    switch action {
      case .tap(let times):
        element.tap(withNumberOfTaps: Int(times))

      case .tapOnAxis(let x, let y):
        element.tap(on: CGPoint(x: x,y: y))

      case let .longPress(duration):
        if let duration = duration {
          element.longPress(duration)
        } else {
          element.longPress()
        }

      case .longPressAndDrag(
        let duration,
        let normalizedPositionX,
        let normalizedPositionY,
        let targetElement,
        let normalizedTargetPositionX,
        let normalizedTargetPositionY,
        let speed,
        let holdDuration
      ):
        guard let targetElement = targetElement as? XCUIElement else {
          throw ActionDelegate.ActionDelegateError.notXCUIElement
        }

        if let response = whiteBoxMessageHandler(
          .longPressAndDrag(
            duration: duration,
            normalizedPositionX: normalizedPositionX,
            normalizedPositionY: normalizedPositionY,
            targetElement: targetElement,
            normalizedTargetPositionX: normalizedTargetPositionX,
            normalizedTargetPositionY: normalizedTargetPositionY,
            speed: speed,
            holdDuration: holdDuration,
            onElement: element
          )) {
          response.assertResponse(equalsTo: .completed)

          // TODO: remove log
          uiLog("long press and drag was executed by the app", type: .debug)
        } else {
          // Element holding after dragging is not working on XCUITest.
          // See: https://github.com/asafkorem/XCUITestHoldBugReproduction for details regarding
          // this bug.
          uiLog(
            "long press and drag was executed by XCUITest. Note that the preferred " +
            "implementation for this action is invoked only for white-box-handled applications",
            type: .debug
          )

          try element.longPress(
            duration: duration,
            normalizedOffsetX: normalizedPositionX,
            normalizedOffsetY: normalizedPositionY,
            dragTo: targetElement,
            normalizedTargetOffsetX: normalizedTargetPositionX,
            normalizedTargetOffsetY: normalizedTargetPositionY,
            speed: speed,
            holdDuration: holdDuration,
            testCase: testCase
          )
        }

      case .swipe(
        let direction,
        let speed,
        let normalizedOffset,
        let normalizedStartingPointX,
        let normalizedStartingPointY
      ):
        element.swipe(
          direction: direction,
          speed: speed,
          normalizedOffset: normalizedOffset,
          normalizedStartingPointX: normalizedStartingPointX,
          normalizedStartingPointY: normalizedStartingPointY,
          app: app
        )

      case .tapKey(let type):
        try element.tapKey(type)

      case .changeText(let change):
        element.changeText(change)

      case .scroll(let type):
        element.scroll(type, app: app)

      case .setColumnToValue(index: let index, value: let value):
        element.setColumnToValue(value, atIndex: index)

      case .setDatePicker(date: let date):
        if let response = whiteBoxMessageHandler(.setDatePicker(toDate: date, onElement: element)) {
          response.assertResponse(equalsTo: .completed)
        }

      case .pinch(scale: let scale, speed: let speed, angle: let angle):
        element.pinch(withScale: scale, speed: speed, angle: angle)

      case .adjustSlider(normalizedPosition: let normalizedPosition):
        element.adjustSlider(to: normalizedPosition)

      case .screenshot, .getAttributes:
        // TODO: remove log
        uiLog("this action should not be called under `act`: \(action.name)", type: .error)

        fatalError("this action should not be called under `act()`")
    }
  }

  // TODO: extract to another file.
  func getAttributes(from elements: [AnyHashable]) throws -> AnyCodable {
    // TODO: mix XCUITest attributes with the application's attributes.

    let mappedElements = elements.compactMap { $0 as? XCUIElement }
    guard mappedElements.count == elements.count
    else {
      throw ActionDelegateError.notXCUIElement
    }

    let attributes = mappedElements.map {
      $0.getAttributes()
    }

    if attributes.count > 1 {
      return AnyCodable(["elements": attributes])
    } else {
      guard let attributes = attributes.first else {
        uiLog("could not find any attributes (no matching elements)", type: .error)
        fatalError("could not find any attributes (no matching elements)")
      }

      return attributes
    }
  }

  func takeScreenshot(
    _ imageName: String?,
    date: Date = Date.now
  ) throws -> AnyCodable {
    return try AnyCodable(app.takeScreenshot(imageName, date: date))
  }
}

extension ActionDelegate {
  enum ActionDelegateError: Error {
    case notXCUIElement
  }
}