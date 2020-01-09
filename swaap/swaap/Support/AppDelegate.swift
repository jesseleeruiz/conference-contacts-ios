//
//  AppDelegate.swift
//  swaap
//
//  Created by Marlon Raskin on 11/11/19.
//  Copyright © 2019 swaap. All rights reserved.
//

import UIKit
import Auth0
import TouchVisualizer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		#if DEBUG
		var config = Configuration()
		config.color = UIColor.lightGray.withAlphaComponent(0.25)
		Visualizer.start(config)
		#endif
		return true
	}

	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
		return Auth0.resumeAuth(url, options: options)
	}
}
