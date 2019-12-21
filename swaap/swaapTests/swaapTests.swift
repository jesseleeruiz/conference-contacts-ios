//
//  swaapTests.swift
//  swaapTests
//
//  Created by Marlon Raskin on 11/11/19.
//  Copyright © 2019 swaap. All rights reserved.
//
//swiftlint:disable force_try

import XCTest
@testable import swaap
import Auth0
import NetworkHandler
import CoreLocation

class SwaapTests: XCTestCase {

	func getCreds() -> Credentials {
		Credentials(accessToken: testAccessToken,
					tokenType: testTokenType,
					idToken: testIDToken,
					refreshToken: nil,
					expiresIn: Date(timeIntervalSinceNow: 60 * 60 * 24),
					scope: "openid profile email")
	}

	func currentLocation() -> CLLocation {
		let locationHandler = LocationHandler()
		locationHandler.requestAuth()
		locationHandler.singleLocationRequest()
		let waitForLocation = expectation(description: "wait for location")

		DispatchQueue.global().async {
			while locationHandler.lastLocation == nil {
				sleep(1)
				print(locationHandler.lastLocation)
			}
			print(locationHandler.lastLocation)
			waitForLocation.fulfill()
		}

		wait(for: [waitForLocation], timeout: 10)

		guard let location = locationHandler.lastLocation else { fatalError("Couldn't get location") }
		return location
	}

	func getAuthManager() -> AuthManager {
		AuthManager(testCredentials: getCreds())
	}

	func getProfileController() -> ProfileController {
		ProfileController(authManager: getAuthManager())
	}

	func getContactController() -> ContactsController {
		ContactsController(profileController: getProfileController())
	}

//	override func setUp() {
//		// Put setup code here. This method is called before the invocation of each test method in the class.
//	}
//
//	override func tearDown() {
//		// Put teardown code here. This method is called after the invocation of each test method in the class.
//	}

	// FIXME: setup mocking
	/// current uses live server data - requires the the constants file be updated before running
	func testRetrieveArbitraryUser() {
		let contactController = getContactController()

		let waitForNetwork = expectation(description: "test")
		contactController.fetchUser(with: heUserID) { result in
			do {
				let user = try result.get()
				XCTAssertEqual(heUserID, user.id)
			} catch {
				XCTFail("Error testing single user fetch: \(error)")
			}
			waitForNetwork.fulfill()
		}
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Timed out waiting for an expectation: \(error)")
			}
		}
	}

	// FIXME: setup mocking
	func testFetchQRCode() {
		let contactController = getContactController()

		let waitForNetwork = expectation(description: "test")
		contactController.fetchQRCode(with: heQRCodeID) { result in
			do {
				let qrCode = try result.get()
				XCTAssertEqual(heQRCodeID, qrCode.id)
				XCTAssertEqual("Default", qrCode.label)
			} catch {
				XCTFail("Error testing qrcode fetch: \(error)")
			}
			waitForNetwork.fulfill()
		}
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Timed out waiting for an expectation: \(error)")
			}
		}
	}

	func testRequestConnection() {
		let contactController = getContactController()

		let mockingData = NetworkMockingSession { inputData -> (Data?, Int, Error?) in
			let failReturn: (Data?, Int, Error?) = (nil, 500, NetworkError.unspecifiedError(reason: "bad input"))
			guard let inputData = inputData else { return failReturn }
			let json = (try? JSONSerialization.jsonObject(with: inputData)) as? [String: Any] ?? [:]
			guard (json["query"] as? String) == SwaapGQLQueries.connectionCreateMutation else { return failReturn }
			guard let variables = json["variables"] as? [String: Any] else { return failReturn }
			guard (variables["id"] as? String) == heUserID else { return failReturn }
			guard let coords = variables["coords"] as? [String: NSNumber] else { return failReturn }
			guard coords["latitude"] == 40 else { return failReturn }
			guard coords["longitude"] == -107.0001 else { return failReturn }

			return (createConnectionResponse, 200, nil)
		}


		let waitForNetwork = expectation(description: "test")
		contactController.requestConnection(toUserID: heUserID, currentLocation: currentLocation(), session: mockingData) { result in
			do {
				let response = try result.get()
				XCTAssertEqual(201, response.code)
			} catch {
				XCTFail("Error testing qrcode fetch: \(error)")
			}
			waitForNetwork.fulfill()
		}
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Timed out waiting for an expectation: \(error)")
			}
		}
	}

	// FIXME: setup mocking
	func testFetchAllConnections() {
		let contactController = getContactController()

		let waitForNetwork = expectation(description: "test")
		contactController.fetchAllContacts { result in
			do {
				let response = try result.get()
				print(response)
				// FIXME: setup mocking
				// this is where confirming good data would go (set up mocking!)
			} catch {
				XCTFail("Error testing all connection fetch: \(error)")
			}
			waitForNetwork.fulfill()
		}
		waitForExpectations(timeout: 10) { error in
			if let error = error {
				XCTFail("Timed out waiting for an expectation: \(error)")
			}
		}
	}
}
