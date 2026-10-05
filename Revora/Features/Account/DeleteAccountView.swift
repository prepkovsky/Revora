import SwiftUI

struct DeleteAccountView: View {
    private enum Field {
        case password
    }

    @Environment(AuthService.self) private var authService
    @Environment(RecipeRepository.self) private var recipeRepository
    @Environment(RecipePhotoStore.self) private var photoStore

    @State private var password = ""
    @State private var isConfirming = false
    @State private var isDeleting = false
    @State private var passwordError: String?
    @State private var deleteError: String?
    @FocusState private var focusedField: Field?

    private var recipeCount: Int {
        recipeRepository.recipes.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Deleting your account permanently removes:")
                        .foregroundStyle(.secondaryText)

                    VStack(alignment: .leading, spacing: 12) {
                        Label(authService.currentUser?.email ?? "Your account", systemImage: "person.crop.circle")
                        Label {
                            if recipeCount > 0 {
                                Text("^[\(recipeCount) recipe](inflect: true), with their photos")
                            } else {
                                Text("All of your recipes and photos")
                            }
                        } icon: {
                            Image(systemName: "book")
                        }
                    }

                    Text("This can't be undone.")
                        .font(.headline)
                }

                FormField(
                    label: "Password",
                    hint: "Enter your password to confirm it's you.",
                    error: passwordError,
                    focus: $focusedField,
                    field: .password
                ) {
                    PasswordField(title: "Password", text: $password)
                        .textContentType(.password)
                        .submitLabel(.done)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if let deleteError {
                        ErrorMessage(message: deleteError)
                    }

                    Button(role: .destructive) {
                        focusedField = nil
                        isConfirming = true
                    } label: {
                        ProgressButtonLabel(title: "Delete Account", isInProgress: isDeleting)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .fontWeight(.semibold)
                    .tint(.red)
                    .disabled(password.isEmpty)
                    .confirmationDialog("Delete Your Account?", isPresented: $isConfirming, titleVisibility: .visible) {
                        Button("Delete Account", role: .destructive, action: delete)
                    } message: {
                        Text("Your account and all of your recipes will be deleted. This can't be undone.")
                    }
                }
            }
            .padding()
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(.appBackground)
        .onTapGesture { focusedField = nil }
        .navigationTitle("Delete Account")
        .navigationBarBackButtonHidden(isDeleting)
        .onChange(of: password) {
            passwordError = nil
            deleteError = nil
        }
    }

    /// The password is checked before anything is deleted, so a typo can't leave the account
    /// half deleted. The account itself goes last, because the security rules only let a
    /// signed-in user delete their recipes. If a step fails, trying again picks up from there.
    private func delete() {
        guard !isDeleting else { return }
        isDeleting = true
        passwordError = nil
        deleteError = nil
        Task {
            defer { isDeleting = false }
            do throws(AuthError) {
                try await authService.reauthenticate(password: password)
            } catch .wrongPassword {
                passwordError = AuthError.wrongPassword.message
                return
            } catch {
                deleteError = error.message
                return
            }

            do throws(RecipeError) {
                try await recipeRepository.deleteAllRecipes(photoStore: photoStore)
            } catch {
                deleteError = error.message
                return
            }

            do throws(AuthError) {
                try await authService.deleteAccount()
                AccessibilityNotification.Announcement("Your account has been deleted.").post()
            } catch {
                deleteError = error.message
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeleteAccountView()
    }
    .environment(AuthService())
    .environment(RecipeRepository())
    .environment(RecipePhotoStore())
}
