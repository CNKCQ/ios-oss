import KsApi
import Library
import Prelude
import UIKit

internal protocol BackerDashboardProjectsViewControllerDelegate: class {
  /// Called when a project cell is tapped.
  func profileProjectsGoToProject(_ project: Project, projects: [Project], reftag: RefTag)
}

internal final class BackerDashboardProjectsViewController: UITableViewController {

  private let viewModel: BackerDashboardProjectsViewModelType = BackerDashboardProjectsViewModel()
  private let dataSource = BackerDashboardProjectsDataSource()

  internal weak var delegate: BackerDashboardProjectsViewControllerDelegate?

  internal func configureWith(delegate: BackerDashboardProjectsViewControllerDelegate,
                              projectsType: ProfileProjectsType,
                              sort: DiscoveryParams.Sort) {

    self.viewModel.inputs.configureWith(type: projectsType)
  }

  internal override func viewDidLoad() {
    super.viewDidLoad()

    self.tableView.dataSource = dataSource

    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    self.refreshControl = refreshControl

    self.tableView.register(nib: .BackerDashboardEmptyStateCell)
    self.tableView.register(nib: .BackerDashboardProjectCell)

    self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: Styles.grid(2)))

    self.viewModel.inputs.viewDidLoad()
  }

  internal override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.viewModel.inputs.viewWillAppear(animated)
  }

  internal override func bindViewModel() {
    super.bindViewModel()

    self.refreshControl?.rac.refreshing = self.viewModel.outputs.isRefreshing

    self.viewModel.outputs.emptyStateIsVisible
      .observeForUI()
      .observeValues { [weak self] isVisible, type in
        self?.dataSource.emptyState(visible: isVisible, type: type)
        self?.tableView.reloadData()
    }

    self.viewModel.outputs.projects
      .observeForUI()
      .observeValues { [weak self] in
        self?.dataSource.load(projects: $0)
        self?.tableView.reloadData()
    }

    self.viewModel.outputs.notifyDelegateGoToProject
      .observeForControllerAction()
      .observeValues { [weak self] project, projects, reftag in
        self?.delegate?.profileProjectsGoToProject(project, projects: projects, reftag: reftag)
    }
  }

  internal override func bindStyles() {
    super.bindStyles()

    _ = self
      |> baseTableControllerStyle()

    _ = self.navigationController?.navigationBar
      ?|> baseNavigationBarStyle
  }

  internal override func tableView(_ tableView: UITableView,
                                   willDisplay cell: UITableViewCell,
                                   forRowAt indexPath: IndexPath) {

    self.viewModel.inputs.willDisplayRow(self.dataSource.itemIndexAt(indexPath),
                                         outOf: self.dataSource.numberOfItems())
  }

  internal override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let project = self.dataSource[indexPath] as? Project else {
      return
    }

    self.viewModel.inputs.projectTapped(project)
  }

  @objc internal func refresh() {
    self.viewModel.inputs.refresh()
  }
}
