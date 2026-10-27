import Foundation
import Observation
import SensorCore
import UIKit

/// A device of the app in the device list, with its binding to a phone.
struct DeviceRow: Identifiable, Hashable {
    enum Binding: Hashable {
        /// No phone is bound to the device.
        case free
        case thisPhone
        case otherPhone
        /// The binding could not be read.
        case unknown
    }

    let device: Device
    let binding: Binding

    var id: String { device.id }
}

/// The steps of sign-in and device selection (see `docs/spec/sign-in.md`, Overview).
/// E-mail address and password are the root of the flow; the steps follow on the navigation stack.
enum SignInStep: Hashable {
    case tenant
    case code
    case project
    case device
}

/// Leads the user through sign-in, tenant, code, project, and device.
@Observable
final class SignInModel {
    private let app: AppModel

    var addressText: String
    var email = ""
    /// Kept in memory only until the session exists, never stored.
    var password = ""
    var code = ""
    var newDeviceName = UIDevice.current.name

    var path: [SignInStep] = []
    private(set) var roles: [Role] = []
    private(set) var role: Role?
    private(set) var codeEmail = ""
    private var twoFactorToken = ""
    private(set) var projects: [Project] = []
    private(set) var projectId: String?
    private(set) var devices: [DeviceRow] = []

    private(set) var isWorking = false
    var error: SignInError?
    /// Set when the device is picked and the flow is finished.
    private(set) var isFinished = false

    init(app: AppModel) {
        self.app = app
        addressText = app.address.text
    }

    var canSignIn: Bool {
        ServerAddress(parsing: addressText) != nil && !email.isEmpty && !password.isEmpty && !isWorking
    }

    /// Starts the flow. With a running session it goes straight to the project, and reads the role of the session
    /// for the name of its tenant.
    func start() async {
        guard let client = app.client, await client.isSignedIn else { return }
        await run {
            try await self.loadProjects(client)
            // Only after the projects: `cancel()` ends a session that has a role but no projects yet.
            let authorityId = await client.claims?.authorityDataId
            self.role = try? await client.roles().first { $0.id == authorityId }
        }
    }

    // MARK: Steps

    func signIn() async {
        guard let address = ServerAddress(parsing: addressText) else { return }
        let client = app.startSession(at: address)
        await run {
            let all = try await client.roles(username: self.email, password: self.password)
            let roles = all.filter(\.isUsable)
            self.roles = roles.sorted { $0.tenantName.localizedStandardCompare($1.tenantName) == .orderedAscending }
            switch roles.count {
            case 0: throw SignInError.noTenant(authorities: all.compactMap(\.authority))
            case 1: try await self.signIn(with: roles[0], client)
            default: self.path = [.tenant]
            }
        }
    }

    func choose(_ role: Role) async {
        guard let client = app.client else { return }
        await run { try await self.signIn(with: role, client) }
    }

    func submitCode() async {
        guard let client = app.client else { return }
        await run {
            try await client.verify(twoFactorToken: self.twoFactorToken, code: self.code.trimmingCharacters(in: .whitespaces))
            try await self.signedIn(client)
        }
    }

    /// The server sends a new code when the app signs in with the role again.
    func requestNewCode() async {
        guard let client = app.client, let role else { return }
        code = ""
        await run { try await self.signIn(with: role, client) }
    }

    func chooseProject(_ id: String) async {
        guard let client = app.client else { return }
        await run {
            if await client.claims?.projectId != id {
                try await client.selectProject(id: id)
            }
            self.projectId = id
            try await self.loadDevices(client)
            self.path.append(.device)
        }
    }

    func refreshDevices() async {
        guard let client = app.client else { return }
        await run { try await self.loadDevices(client) }
    }

    /// Picks a device. A device bound to another phone is taken over only with `takeOver`.
    func choose(_ row: DeviceRow, takeOver: Bool = false) async {
        guard let client = app.client else { return }
        if row.binding == .otherPhone && !takeOver { return }
        await run {
            if row.binding != .thisPhone {
                try await self.bind(row.device.id, client)
            }
            try await self.finish(with: row.device, client)
        }
    }

    func createDevice() async {
        guard let client = app.client else { return }
        let name = newDeviceName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        await run {
            let device = try await client.createDevice(name: name)
            try await self.bind(device.id, client)
            try await self.finish(with: device, client)
        }
    }

    func cancel() {
        if !isFinished && role != nil && projects.isEmpty {
            app.abandonSession()
        }
        password = ""
    }

    // MARK: Internals

    private func signIn(with role: Role, _ client: OptiCloudClient) async throws {
        self.role = role
        switch try await client.login(username: email, password: password, authorityId: role.authorityId.id) {
        case .signedIn:
            try await signedIn(client)
        case .codeRequired(let token, let email):
            twoFactorToken = token
            codeEmail = email
            if path.last != .code { path.append(.code) }
        }
    }

    private func signedIn(_ client: OptiCloudClient) async throws {
        password = ""
        code = ""
        try await loadProjects(client)
    }

    private func loadProjects(_ client: OptiCloudClient) async throws {
        projects = try await client.projects()
        let all = projects.flatMap(\.flattened)
        projectId = await client.claims?.projectId ?? all.first?.id
        if all.count <= 1, let projectId {
            if await client.claims?.projectId != projectId {
                try await client.selectProject(id: projectId)
            }
            try await loadDevices(client)
            path.append(.device)
        } else {
            path.append(.project)
        }
    }

    private func loadDevices(_ client: OptiCloudClient) async throws {
        guard let projectId = await client.claims?.projectId else {
            throw OptiCloudError.unexpectedAnswer
        }
        let devices = try await client.devices(projectId: projectId).filter(\.isSensorAppDevice)
        let installationId = app.installationId
        self.devices = await withTaskGroup(of: DeviceRow.self) { group in
            for device in devices {
                group.addTask {
                    guard let attributes = try? await client.sharedAttributes(deviceId: device.id) else {
                        return DeviceRow(device: device, binding: .unknown)
                    }
                    switch attributes.first(where: { $0.key == "sensorAppInstallation" })?.value {
                    case nil: return DeviceRow(device: device, binding: .free)
                    case .string(installationId): return DeviceRow(device: device, binding: .thisPhone)
                    default: return DeviceRow(device: device, binding: .otherPhone)
                    }
                }
            }
            var rows: [DeviceRow] = []
            for await row in group { rows.append(row) }
            return rows
        }
        .sorted { $0.device.name.localizedStandardCompare($1.device.name) == .orderedAscending }
    }

    private func bind(_ deviceId: String, _ client: OptiCloudClient) async throws {
        do {
            try await client.setSharedAttributes(deviceId: deviceId, ["sensorAppInstallation": .string(app.installationId)])
        } catch let error as OptiCloudError where error.errorCode == OptiCloudError.Code.permissionMissing {
            throw SignInError.step(.bind, error)
        }
    }

    private func finish(with device: Device, _ client: OptiCloudClient) async throws {
        let credentials: DeviceCredentials
        do {
            credentials = try await client.credentials(deviceId: device.id)
        } catch let error as OptiCloudError where error.errorCode == OptiCloudError.Code.permissionMissing {
            throw SignInError.step(.readToken, error)
        }
        guard credentials.credentialsType == DeviceCredentials.accessTokenType, let token = credentials.credentialsId else {
            throw SignInError.notAccessToken
        }
        guard credentials.enabled != false else { throw SignInError.deviceBlocked }

        let projectName = projects.flatMap(\.flattened).first { $0.id == projectId }?.name ?? ""
        app.select(
            SelectedDevice(id: device.id, name: device.name, tenantName: role?.tenantName ?? app.device?.tenantName ?? "", projectName: projectName),
            token: token
        )
        isFinished = true
    }

    /// Runs a step, shows progress, and turns errors into a message.
    private func run(_ step: @escaping () async throws -> Void) async {
        isWorking = true
        error = nil
        defer { isWorking = false }
        do {
            try await step()
        } catch let error as SignInError {
            self.error = error
        } catch let error as OptiCloudError {
            self.error = .server(error)
        } catch {
            self.error = .network(error.localizedDescription)
        }
    }
}

/// Errors of sign-in and device selection, with the text the app shows (see `docs/spec/sign-in.md`, Errors).
enum SignInError: Error, Identifiable {
    enum Step {
        case bind
        case readToken
    }

    case server(OptiCloudError)
    case network(String)
    case noTenant(authorities: [String])
    case notAccessToken
    case deviceBlocked
    case step(Step, OptiCloudError)

    var id: String { message }

    var message: String {
        switch self {
        case .server(let error):
            switch error.errorCode {
            case OptiCloudError.Code.signInFailed:
                return String(localized: "E-mail address or password is wrong.")
            case OptiCloudError.Code.tokenExpired:
                return String(localized: "The session has expired. Please sign in again.")
            case OptiCloudError.Code.accountExpired:
                return String(localized: "The account or the tenant has expired.")
            case OptiCloudError.Code.licenseLimit:
                return String(localized: "The license of the tenant allows no further device.")
            case OptiCloudError.Code.permissionMissing:
                return String(localized: "You do not have the permission for this step.")
            case OptiCloudError.Code.invalidRequest:
                return String(localized: "The server did not accept the input. A device with this name may already exist.")
            case OptiCloudError.Code.tooManyAttempts:
                return String(localized: "Too many attempts. Please sign in again later.")
            default:
                return String(localized: "The server reported an error.")
            }
        case .network(let description):
            return String(localized: "The server cannot be reached. \(description)")
        case .noTenant:
            return String(localized: "Your account has no active access to a tenant.")
        case .notAccessToken:
            return String(localized: "This device uses another kind of credentials and cannot be used by the app.")
        case .deviceBlocked:
            return String(localized: "This device is blocked in optiCLOUD.")
        case .step(.bind, _):
            return String(localized: "You do not have the permission to bind the device to this phone.")
        case .step(.readToken, _):
            return String(localized: "You do not have the permission to read the access token of the device.")
        }
    }

    /// The message of the server, shown as a detail for support.
    var detail: String? {
        switch self {
        case .server(let error), .step(_, let error):
            if case .api(let status, let body) = error {
                return [body.message, body.errorCode.map { "Code \($0)" }, "HTTP \(status)"]
                    .compactMap { $0 }.joined(separator: " · ")
            }
            if case .signInRejected(let status, let message) = error {
                return [message, "HTTP \(status)"].compactMap { $0 }.joined(separator: " · ")
            }
            if case .http(let status) = error { return "HTTP \(status)" }
            return nil
        case .noTenant(let authorities) where !authorities.isEmpty:
            return String(localized: "Roles: \(authorities.joined(separator: ", "))")
        default:
            return nil
        }
    }
}
