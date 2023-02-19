//
//  SelectContextViewController.swift
//  ADEduKit
//
//  Created by Schwarze on 02.01.22.
//

import UIKit

@objc
public protocol SelectContextViewControllerDelegate : NSObjectProtocol {
    func selectContextViewControllerDidSelect(node: ModelNode, container: Container)
    func selectContextViewControllerWillClose()
}

@objc @objcMembers
public class SelectContextViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    public weak var selectContextViewControllerDelegate : SelectContextViewControllerDelegate?

    var container: Container?
    var rootNode: ModelNode?
    var deepList: [ModelNode] = []
    static let cellId = "cell"

    @IBOutlet weak var tableView: UITableView!

    public static func createInstance() -> SelectContextViewController {
        let b = Bundle(for: Self.self)
        let vc = SelectContextViewController(nibName: "SelectContextViewController", bundle: b)
        return vc
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let nib = UINib(nibName: "ContextTableViewCell", bundle: Bundle(for: Self.self))
        tableView.register(nib, forCellReuseIdentifier: Self.cellId)
        tableView.delegate = self
        tableView.dataSource = self
    }

    public func update(rootNode: ModelNode?, container: Container?) {
        self.container = container
        self.rootNode = rootNode
        self.deepList = rootNode?.deepList() ?? []
        if tableView != nil {
            tableView.reloadData()
        }
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return deepList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let _cell = tableView.dequeueReusableCell(withIdentifier: Self.cellId) ?? UITableViewCell()
        if let cell = _cell as? ContextTableViewCell {
            let node = deepList[indexPath.row]
            cell.updateFor(node: node)
        }
        return _cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let container = container else {
            Log.log("\(#function): Error: container is nil")
            return
        }
        let node = deepList[indexPath.row]
        selectContextViewControllerDelegate?.selectContextViewControllerDidSelect(node: node, container: container)
    }

    @IBAction func didTapClose(_ sender: Any) {
        selectContextViewControllerDelegate?.selectContextViewControllerWillClose()
        dismiss(animated: true, completion: nil)
    }
}
