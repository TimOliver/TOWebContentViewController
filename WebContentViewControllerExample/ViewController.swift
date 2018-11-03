//
//  ViewController.swift
//  WebContentViewControllerExample
//
//  Created by Tim Oliver on 3/11/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

import UIKit

class ViewController: UIViewController, WebContentViewControllerDelegate {

    @IBAction func didTapLocalButton(sender: AnyObject) {
        // Get resources folder URL
        let resourcesURL = Bundle.main.resourceURL!
        let baseURL = resourcesURL.appendingPathComponent("HTML")
        let fileURL = baseURL.appendingPathComponent("about.html")

        let webContentController = WebContentViewController(fileURL: fileURL, baseURL: baseURL)
        webContentController.templateTags = ["AppName": "iComics"]
        webContentController.setsTitleFromContent = true
        webContentController.delegate = self;

        let navigationController = UINavigationController(rootViewController: webContentController)
        navigationController.navigationBar.barStyle = .black
        navigationController.modalPresentationStyle = .formSheet
        navigationController.view.tintColor = UIColor(red: 91.0/255.0, green: 158.0/255.0, blue: 1.0, alpha: 1.0)
        present(navigationController, animated: true, completion: nil)

        webContentController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(didTapDone(sender:)))
    }

    @IBAction func didTapWebButton(sender: AnyObject) {

    }

    @objc func didTapDone(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
}

