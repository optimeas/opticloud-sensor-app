import SensorCore
import SwiftUI

/// Sign-in and device selection, from the server address to the device.
struct SignInView: View {
    @State private var model: SignInModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focus: Field?

    private enum Field {
        case address, email, password
    }

    init(app: AppModel) {
        _model = State(initialValue: SignInModel(app: app))
    }

    var body: some View {
        NavigationStack(path: $model.path) {
            Form {
                Section {
                    TextField("Server", text: $model.addressText)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .address)
                        .submitLabel(.next)
                        .onSubmit { focus = .email }
                } header: {
                    Text("optiCLOUD")
                } footer: {
                    Text("The address of the optiCLOUD web application.")
                }

                Section {
                    TextField("E-mail address", text: $model.email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                    SecureField("Password", text: $model.password)
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { Task { await model.signIn() } }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Sign in with your personal optiCLOUD account. The password is not stored.")
                }

                Section {
                    Button {
                        focus = nil
                        Task { await model.signIn() }
                    } label: {
                        HStack {
                            Text("Sign In")
                            Spacer()
                            if model.isWorking && model.path.isEmpty { ProgressView() }
                        }
                    }
                    .disabled(!model.canSignIn)
                }
            }
            .navigationTitle("Sign In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        model.cancel()
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: SignInStep.self) { step in
                switch step {
                case .tenant: TenantListView(model: model)
                case .code: CodeEntryView(model: model)
                case .project: ProjectListView(model: model)
                case .device: DeviceListView(model: model)
                }
            }
        }
        .alert(item: $model.error) { error in
            Alert(
                title: Text(error.message),
                message: error.detail.map(Text.init),
                dismissButton: .default(Text("OK"))
            )
        }
        .task { await model.start() }
        .onChange(of: model.isFinished) { _, finished in
            if finished { dismiss() }
        }
        .interactiveDismissDisabled(model.isWorking)
    }
}

/// Step 3: the tenant, one per role of the user.
struct TenantListView: View {
    let model: SignInModel

    var body: some View {
        List(model.roles) { role in
            Button {
                Task { await model.choose(role) }
            } label: {
                HStack {
                    Text(role.tenant.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    if model.isWorking && model.role == role { ProgressView() }
                }
            }
            .disabled(model.isWorking)
        }
        .navigationTitle("Tenant")
    }
}

/// Step 4: the code sent by e-mail, if the tenant requires it.
struct CodeEntryView: View {
    @Bindable var model: SignInModel
    @FocusState private var focused: Bool

    var body: some View {
        Form {
            Section {
                TextField("Code", text: $model.code)
                    .textContentType(.oneTimeCode)
                    .keyboardType(.numberPad)
                    .focused($focused)
            } footer: {
                if model.codeEmail.isEmpty {
                    Text("Enter the code that was sent to you by e-mail.")
                } else {
                    Text("Enter the code that was sent to \(model.codeEmail).")
                }
            }
            Section {
                Button {
                    Task { await model.submitCode() }
                } label: {
                    HStack {
                        Text("Confirm")
                        Spacer()
                        if model.isWorking { ProgressView() }
                    }
                }
                .disabled(model.code.isEmpty || model.isWorking)
                Button("Send New Code") {
                    Task { await model.requestNewCode() }
                }
                .disabled(model.isWorking)
            }
        }
        .navigationTitle("Code")
        .onAppear { focused = true }
    }
}

/// Step 5: the project, with the default project of the role preselected.
struct ProjectListView: View {
    let model: SignInModel

    var body: some View {
        List(model.projects, children: \.childProjects) { project in
            Button {
                Task { await model.chooseProject(project.id) }
            } label: {
                HStack {
                    Text(project.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    if project.id == model.projectId {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                            .accessibilityLabel("Current project")
                    }
                }
            }
            .disabled(model.isWorking)
        }
        .overlay {
            if model.isWorking { ProgressView() }
        }
        .navigationTitle("Project")
    }
}
