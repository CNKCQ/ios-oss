import KsApi
import Library
import Prelude
import UIKit

internal final class BackerDashboardViewController: UIViewController {

  @IBOutlet private weak var avatarImageView: CircleAvatarImageView!
  @IBOutlet private weak var backedContainerView: UIView!
  @IBOutlet private weak var backedMenuButton: UIButton!
  @IBOutlet private weak var backerNameLabel: UILabel!
  @IBOutlet private weak var backerLocationLabel: UILabel!
  @IBOutlet private weak var dividerView: UIView!
  @IBOutlet private weak var embeddedViewsTopLayoutConstraint: NSLayoutConstraint!
  @IBOutlet private weak var headerTopContainerView: UIView!
  @IBOutlet private weak var headerStackView: UIStackView!
  @IBOutlet private weak var headerView: UIView!
  @IBOutlet private weak var headerViewTopConstraint: NSLayoutConstraint!
  @IBOutlet private weak var menuButtonsStackView: UIStackView!
  @IBOutlet private weak var messagesButtonItem: UIBarButtonItem!
  @IBOutlet private weak var savedContainerView: UIView!
  @IBOutlet private weak var savedMenuButton: UIButton!
  @IBOutlet private weak var selectedButtonIndicatorView: UIView!
  @IBOutlet private weak var selectedButtonIndicatorLeadingConstraint: NSLayoutConstraint!
  @IBOutlet private weak var selectedButtonIndicatorWidthConstraint: NSLayoutConstraint!
  @IBOutlet private weak var settingsButtonItem: UIBarButtonItem!
  @IBOutlet weak var sortBar: ProfileSortBarView!

  private weak var backedProjectsViewController: ProfileBackedProjectsViewController!
  private weak var savedProjectsViewController: ProfileSavedProjectsViewController!

  fileprivate let viewModel: BackerDashboardViewModelType = BackerDashboardViewModel()

  private var isCollapsed: Bool = false

  internal static func instantiate() -> BackerDashboardViewController {
    return Storyboard.BackerDashboard.instantiate(BackerDashboardViewController.self)
  }

  internal override func viewDidLoad() {
    super.viewDidLoad()

    self.backedProjectsViewController = self.childViewControllers
      .flatMap { $0 as? ProfileBackedProjectsViewController }.first

    self.backedProjectsViewController.delegate = self

    self.savedProjectsViewController = self.childViewControllers
      .flatMap { $0 as? ProfileSavedProjectsViewController }.first

    self.savedProjectsViewController.delegate = self

    self.backedMenuButton.addTarget(self, action: #selector(backedButtonTapped), for: .touchUpInside)

    self.savedMenuButton.addTarget(self, action: #selector(savedButtonTapped), for: .touchUpInside)

    _ = self.messagesButtonItem
      |> UIBarButtonItem.lens.targetAction .~ (self, #selector(messagesButtonTapped))

    _ = self.settingsButtonItem
      |> UIBarButtonItem.lens.targetAction .~ (self, #selector(settingsButtonTapped))

    self.viewModel.inputs.viewDidLoad()
  }

  internal override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.viewModel.inputs.viewWillAppear(animated)
  }

  internal override func bindViewModel() {
    super.bindViewModel()

    self.backedContainerView.rac.hidden = self.viewModel.outputs.backedProjectsAreHidden
    self.savedContainerView.rac.hidden = self.viewModel.outputs.savedProjectsAreHidden
    self.backerNameLabel.rac.text = self.viewModel.outputs.backerNameText
    self.backerLocationLabel.rac.text = self.viewModel.outputs.backerLocationText
    self.sortBar.rac.hidden = self.viewModel.outputs.sortBarIsHidden

    self.viewModel.outputs.avatarURL
      .observeForUI()
      .on(event: { [weak self] _ in
        self?.avatarImageView.af_cancelImageRequest()
        self?.avatarImageView.image = nil
      })
      .skipNil()
      .observeValues { [weak self] url in
        self?.avatarImageView.ksr_setImageWithURL(url)
    }

    self.viewModel.outputs.backedButtonTitleText
      .observeForControllerAction()
      .observeValues { [weak self] string in
        guard let _self = self else { return }
        _self.setAttributedTitles(for: _self.backedMenuButton, with: string)
    }

    self.viewModel.outputs.embeddedViewTopConstraintConstant
      .observeForUI()
      .observeValues { [weak self] in
        self?.embeddedViewsTopLayoutConstraint.constant = $0
    }

    self.viewModel.outputs.savedButtonTitleText
      .observeForControllerAction()
      .observeValues { [weak self] string in
        guard let _self = self else { return }
        _self.setAttributedTitles(for: _self.savedMenuButton, with: string)
    }

    self.viewModel.outputs.goToMessages
      .observeForControllerAction()
      .observeValues { [weak self] _ in
        guard let _self = self else { return }
        let vc = MessageThreadsViewController.configuredWith(project: nil)
        _self.navigationController?.pushViewController(vc, animated: true)
    }

    self.viewModel.outputs.goToProject
      .observeForControllerAction()
      .observeValues { [weak self] project, projects, refTag in
        self?.present(project: project, projects: projects, refTag: refTag)
    }

    self.viewModel.outputs.goToSettings
      .observeForControllerAction()
      .observeValues { [weak self] _ in
        self?.goToSettings()
    }

    self.viewModel.outputs.pinSelectedIndicatorToPage
      .observeForUI()
      .observeValues { [weak self] index, animated in
        self?.pinSelectedIndicator(to: index, animated: animated)
    }

    self.viewModel.outputs.setSelectedButton
      .observeForUI()
      .observeValues { [weak self] in
        self?.selectButton(atIndex: $0)
    }

//    self.viewModel.outputs.scrollToProject
//      .observeForUI()
//      .observeValues { [weak self] itemIndex in
//        guard let _self = self else { return }
//    }
  }

  internal override func bindStyles() {
    super.bindStyles()

    _ = self |> baseControllerStyle()

    _ = self.navigationController?.navigationBar
      ?|> baseNavigationBarStyle

    _ = self.navigationItem
      |> UINavigationItem.lens.title %~ { _ in Strings.tabbar_profile() }

    _ = self.messagesButtonItem
      |> UIBarButtonItem.lens.image .~ image(named: "inbox-icon")
      |> UIBarButtonItem.lens.accessibilityLabel %~ { _ in Strings.profile_buttons_messages() }

    _ = self.settingsButtonItem
      |> UIBarButtonItem.lens.image .~ image(named: "settings-icon")
      |> UIBarButtonItem.lens.accessibilityLabel %~ { _ in Strings.profile_settings_navbar_title() }

    _ = self.dividerView
      |> UIView.lens.backgroundColor .~ .ksr_grey_500
    //todo: make a Styles.grid(2) top constraint from the headerview for the containers that is
    // active when sort bar is showing and not active when they are hidden
    _ = self.headerStackView
      |> UIView.lens.layoutMargins %~~ { _, view in
        view.traitCollection.isRegularRegular
          ? .init(topBottom: Styles.grid(2), leftRight: Styles.grid(20))
          : .init(top: Styles.grid(5), left: Styles.grid(2), bottom: 0, right: Styles.grid(2))
    }

    _ = self.backerNameLabel
      |> UILabel.lens.textColor .~ .black
      |> UILabel.lens.font .~ .ksr_headline(size: 18)

    _ = self.backerLocationLabel
      |> UILabel.lens.textColor .~ .ksr_text_navy_600
      |> UILabel.lens.font .~ .ksr_subhead(size: 14)
  }

  private func goToSettings() {
    let vc = SettingsViewController.instantiate()

    if UIDevice.current.userInterfaceIdiom == .pad {
      let nav = UINavigationController(rootViewController: vc)
      nav.modalPresentationStyle = .formSheet
      self.present(nav, animated: true, completion: nil)
    } else {
      self.navigationController?.pushViewController(vc, animated: true)
    }
  }

  private func present(project: Project, projects: [Project], refTag: RefTag) {
    let vc = ProjectNavigatorViewController.configuredWith(project: project,
                                                           refTag: refTag,
                                                           initialPlaylist: projects,
                                                           navigatorDelegate: self)
    self.present(vc, animated: true, completion: nil)
  }

  private func updateProjectPlaylist(_ playlist: [Project]) {
    guard let navigator = self.presentedViewController as? ProjectNavigatorViewController else { return }
    navigator.updatePlaylist(playlist)
  }

  private func setAttributedTitles(for button: UIButton, with string: String) {
    let normalTitleString = NSAttributedString(string: string, attributes: [
      NSFontAttributeName: self.traitCollection.isRegularRegular
        ? UIFont.ksr_subhead(size: 16.0)
        : UIFont.ksr_subhead(size: 13.0),
      NSForegroundColorAttributeName: UIColor.ksr_text_navy_700
    ])

    let selectedTitleString = NSAttributedString(string: string, attributes: [
      NSFontAttributeName: self.traitCollection.isRegularRegular
        ? UIFont.ksr_subhead(size: 16.0).bolded
        : UIFont.ksr_subhead(size: 13.0).bolded,
      NSForegroundColorAttributeName: UIColor.black
    ])

    _ = button
      |> UIButton.lens.attributedTitle(forState: .normal) %~ { _ in normalTitleString }
      |> UIButton.lens.attributedTitle(forState: .selected) %~ { _ in selectedTitleString }
      |> (UIButton.lens.titleLabel • UILabel.lens.lineBreakMode) .~ .byWordWrapping
  }

  private func selectButton(atIndex index: Int) {
    for (idx, button) in self.menuButtonsStackView.arrangedSubviews.enumerated() {
      _ = (button as? UIButton)
        ?|> UIButton.lens.selected .~ (idx == index)
    }
  }

  private func pinSelectedIndicator(to index: Int, animated: Bool) {
    guard let button = self.menuButtonsStackView.arrangedSubviews[index] as? UIButton else { return }

    let leadingConstant = button.frame.origin.x + Styles.grid(1)
    let widthConstant = button.titleLabel?.frame.size.width ?? button.frame.size.width

    UIView.animate(withDuration: animated ? 0.2 : 0.0, delay: 0.0, options: .curveEaseOut, animations: {
      self.selectedButtonIndicatorLeadingConstraint.constant = leadingConstant
      self.selectedButtonIndicatorWidthConstraint.constant = widthConstant

      self.headerView.setNeedsLayout()
      self.headerView.layoutIfNeeded()
    }, completion: nil)
  }

  fileprivate func expandOrCollapseHeaderOnRelease(scrollView: UIScrollView) {
    // put this value in view model. it changes when sort bar is hidden.
    let minHeaderHeight = self.headerView.frame.size.height - self.headerTopContainerView.frame.size.height
      + Styles.grid(6)
    let shouldCollapse = self.headerViewTopConstraint.constant <= floor(-minHeaderHeight / 2.0)

    if shouldCollapse {
      UIView.animate(
        withDuration: 0.3,
        delay: 0.0,
        options: .curveEaseOut,
        animations: {
          self.headerViewTopConstraint.constant = -minHeaderHeight
          self.view.layoutIfNeeded()
        },
        completion: { _ in
          self.isCollapsed = true
        }
      )
    } else {
      UIView.animate(
        withDuration: 0.3,
        delay: 0.0,
        options: .curveEaseOut,
        animations: {
          self.headerViewTopConstraint.constant = 0
          self.view.layoutIfNeeded()
      },
        completion: { _ in
          self.isCollapsed = false
        }
      )
    }
  }

  fileprivate func moveHeader(with scrollView: UIScrollView) {
    let minHeaderHeight = self.headerView.frame.size.height - self.headerTopContainerView.frame.size.height
      + Styles.grid(6)

    if scrollView.contentOffset.y > 0 {
      if !self.isCollapsed {
        self.headerViewTopConstraint.constant = -scrollView.contentOffset.y
      }
    } else if scrollView.contentOffset.y < 0 {
      if isCollapsed {
        let newConstant = self.headerViewTopConstraint.constant - scrollView.contentOffset.y
        if newConstant <= 0 { // need a constraint here, but maybe this isn't the best place
          self.headerViewTopConstraint.constant = newConstant
        }
      }
    }

    if self.headerViewTopConstraint.constant <= -minHeaderHeight {
      self.headerViewTopConstraint.constant = -minHeaderHeight
    }

    // todo: the scrollview itself shouldn't be able to tuck under when header is not yet collapsed
    // todo: still some jankiness on scroll, probably b/c isCollapsed is not correct until releasing

//    print("offset = \(scrollView.contentOffset.y)")
//    print("constant = \(self.headerViewTopConstraint.constant), -minHeight = \(-minHeaderHeight)")
//    print("isCollapsed = \(self.isCollapsed)")
  }

  @objc private func messagesButtonTapped() {
    self.viewModel.inputs.messagesButtonTapped()
  }

  @objc private func settingsButtonTapped() {
    self.viewModel.inputs.settingsButtonTapped()
  }

  @objc private func backedButtonTapped() {
    self.viewModel.inputs.backedProjectsButtonTapped()
  }

  @objc private func savedButtonTapped() {
    self.viewModel.inputs.savedProjectsButtonTapped()
  }
}

extension BackerDashboardViewController: ProfileBackedProjectsViewControllerDelegate {
  func profileBackedProjectsDidScroll(_ scrollView: UIScrollView) {
    self.moveHeader(with: scrollView)
  }

  func profileBackedProjectsDidEndDecelerating(_ scrollView: UIScrollView) {
    self.expandOrCollapseHeaderOnRelease(scrollView: scrollView)
  }

  func profileBackedProjectsDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.expandOrCollapseHeaderOnRelease(scrollView: scrollView)
    }
  }
}

extension BackerDashboardViewController: ProfileSavedProjectsViewControllerDelegate {
  func profileSavedProjectsDidScroll(_ scrollView: UIScrollView) {
    self.moveHeader(with: scrollView)
  }

  func profileSavedProjectsDidEndDecelerating(_ scrollView: UIScrollView) {
    self.expandOrCollapseHeaderOnRelease(scrollView: scrollView)
  }

  func profileSavedProjectsDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      self.expandOrCollapseHeaderOnRelease(scrollView: scrollView)
    }
  }
}

extension BackerDashboardViewController: ProjectNavigatorDelegate {
  func transitionedToProject(at index: Int) {
    //self.viewModel.inputs.transitionedToProject(at: index, outOf: self.dataSource.numberOfItems())
  }
}

