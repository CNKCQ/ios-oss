import KsApi
import Prelude
import ReactiveSwift
import Result

public protocol BackerDashboardViewModelInputs {
  /// Call when backed projects button is tapped.
  func backedProjectsButtonTapped()

  /// Call when messages button is tapped.
  func messagesButtonTapped()

  /// Call when a project cell is tapped.
  func projectTapped(_ project: Project)

  /// Call when saved projects button is tapped.
  func savedProjectsButtonTapped()

  /// Call when settings button is tapped.
  func settingsButtonTapped()

  /// Call when the project navigator has transitioned to a new project with its index.
  func transitionedToProject(at row: Int, outOf totalRows: Int)

  /// Call when the view loads.
  func viewDidLoad()

  /// Call when the view will appear.
  func viewWillAppear(_ animated: Bool)
}

public protocol BackerDashboardViewModelOutputs {
  /// Emits a URL for the avatar image view.
  var avatarURL: Signal<URL?, NoError> { get }

  /// Emits a string for the backer location label.
  var backerLocationText: Signal<String, NoError> { get }

  /// Emits a string for the backer name label.
  var backerNameText: Signal<String, NoError> { get }

  /// Emits a boolean whether backed projects container should be hidden or not.
  var backedProjectsAreHidden: Signal<Bool, NoError> { get }

  /// Emits when to present Messages.
  var goToMessages: Signal<(), NoError> { get }

  /// Emits the project and ref tag when should go to project page.
  var goToProject: Signal<(Project, [Project], RefTag), NoError > { get }

  /// Emits when to navigate to Settings.
  var goToSettings: Signal<(), NoError> { get }

  /// Emits an index to pin the indicator view to a particular button view and whether to animate it.
  var pinSelectedIndicatorToPage: Signal<(Int, Bool), NoError> { get }

  /// Emits a boolean whether saved projects container should be hidden or not.
  var savedProjectsAreHidden: Signal<Bool, NoError> { get }

  /// Emits when should scroll to the project item or row position.
  var scrollToProject: Signal<Int, NoError> { get }
}

public protocol BackerDashboardViewModelType {
  var inputs: BackerDashboardViewModelInputs { get }
  var outputs: BackerDashboardViewModelOutputs { get }
}

public final class BackerDashboardViewModel: BackerDashboardViewModelType, BackerDashboardViewModelInputs,
  BackerDashboardViewModelOutputs {

  public init() {
    let user = self.viewWillAppearProperty.signal
      .switchMap { _ in
        AppEnvironment.current.apiService.fetchUserSelf()
          .prefix(SignalProducer([AppEnvironment.current.currentUser].compact()))
          .demoteErrors()
    }

    self.avatarURL = user.map { URL(string: $0.avatar.large ?? $0.avatar.medium) }

    self.backerLocationText = user.map { $0.location?.displayableName ?? "" }

    self.backerNameText = user.map { $0.name }

//    self.backedProjectsCountLabel = user
//      .map { user in
//        Strings.Backed_projects_projects_count(
//          project_count: Format.wholeNumber(user.stats.backedProjectsCount ?? 0)
//        )
//    }
//    self.createdProjectsCountLabel = user
//      .map { user in
//        Strings.Created_projects_projects_count(
//          projects_count: Format.wholeNumber(user.stats.createdProjectsCount ?? 0)
//        )
//    }

    self.backedProjectsAreHidden = Signal.merge(
      self.backedProjectsButtonProperty.signal.mapConst(false),
      self.savedProjectsButtonProperty.signal.mapConst(true)
    )

    self.savedProjectsAreHidden = Signal.merge(
      self.viewDidLoadProperty.signal.mapConst(true),
      self.backedProjectsButtonProperty.signal.mapConst(true),
      self.savedProjectsButtonProperty.signal.mapConst(false)
    )

    self.goToProject = .empty

    self.goToMessages = self.messagesButtonTappedProperty.signal

    self.goToSettings = self.settingsButtonTappedProperty.signal

    self.pinSelectedIndicatorToPage = .empty

    self.scrollToProject = self.transitionedToProjectRowAndTotalProperty.signal.skipNil().map(first)
  }

  private let backedProjectsButtonProperty = MutableProperty()
  public func backedProjectsButtonTapped() {
    self.backedProjectsButtonProperty.value = ()
  }

  private let messagesButtonTappedProperty = MutableProperty()
  public func messagesButtonTapped() {
    self.messagesButtonTappedProperty.value = ()
  }

  private let projectTappedProperty = MutableProperty<Project?>(nil)
  public func projectTapped(_ project: Project) {
    self.projectTappedProperty.value = project
  }

  private let savedProjectsButtonProperty = MutableProperty()
  public func savedProjectsButtonTapped() {
    self.savedProjectsButtonProperty.value = ()
  }

  private let settingsButtonTappedProperty = MutableProperty()
  public func settingsButtonTapped() {
    self.settingsButtonTappedProperty.value = ()
  }

  private let transitionedToProjectRowAndTotalProperty = MutableProperty<(row: Int, total: Int)?>(nil)
  public func transitionedToProject(at row: Int, outOf totalRows: Int) {
    self.transitionedToProjectRowAndTotalProperty.value = (row, totalRows)
  }

  private let viewDidLoadProperty = MutableProperty()
  public func viewDidLoad() {
    self.viewDidLoadProperty.value = ()
  }

  private let viewWillAppearProperty = MutableProperty(false)
  public func viewWillAppear(_ animated: Bool) {
    self.viewWillAppearProperty.value = animated
  }

  public let avatarURL: Signal<URL?, NoError>
  public let backerLocationText: Signal<String, NoError>
  public let backerNameText: Signal<String, NoError>
  public let backedProjectsAreHidden: Signal<Bool, NoError>
  public let goToMessages: Signal<(), NoError>
  public let goToProject: Signal<(Project, [Project], RefTag), NoError>
  public let goToSettings: Signal<(), NoError>
  public let pinSelectedIndicatorToPage: Signal<(Int, Bool), NoError>
  public let savedProjectsAreHidden: Signal<Bool, NoError>
  public let scrollToProject: Signal<Int, NoError>

  public var inputs: BackerDashboardViewModelInputs { return self }
  public var outputs: BackerDashboardViewModelOutputs { return self }
}
