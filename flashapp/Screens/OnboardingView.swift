import SwiftUI

private enum OnboardingStep {
    case name, email, code
}

struct OnboardingView: View {
    @EnvironmentObject private var session: SessionStore

    @State private var step: OnboardingStep = .name
    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var email     = ""
    @State private var otp       = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    @FocusState private var firstNameFocused: Bool
    @FocusState private var lastNameFocused:  Bool
    @FocusState private var emailFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            stepContent
                .padding(.horizontal, 28)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)

            Spacer(minLength: 0)

            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .background(FlashPalette.canvasLight.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    // MARK: Step content

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:  nameStep
        case .email: emailStep
        case .code:  codeStep
        }
    }

    // MARK: Name

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.largeTitle.weight(.bold))
                Text("Flash is for real people. Use your real name.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("First name", text: $firstName)
                    .textContentType(.givenName)
                    .padding(.horizontal, 14).padding(.vertical, 14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($firstNameFocused)
                    .submitLabel(.next)
                    .onSubmit { lastNameFocused = true }

                TextField("Last name", text: $lastName)
                    .textContentType(.familyName)
                    .padding(.horizontal, 14).padding(.vertical, 14)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($lastNameFocused)
                    .submitLabel(.done)
                    .onSubmit { if canProceed { advance() } }
            }
        }
        .onAppear { firstNameFocused = true }
    }

    // MARK: Email

    private var emailStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your email")
                    .font(.largeTitle.weight(.bold))
                Text("We'll send you a one-time code to verify it's you.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            TextField("you@example.com", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14).padding(.vertical, 14)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .focused($emailFocused)

            errorLabel
        }
        .onAppear { emailFocused = true }
    }

    // MARK: OTP

    private var codeStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter the code")
                    .font(.largeTitle.weight(.bold))
                Text("Sent to \(email)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            OTPBoxField(code: $otp)

            errorLabel

            Button("Resend code") {
                Task { try? await SupabaseService.shared.sendOTP(email: email) }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .disabled(isLoading)
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        Button(action: advance) {
            ZStack {
                if isLoading {
                    ProgressView().tint(Color(UIColor.systemBackground))
                } else {
                    Text(primaryLabel)
                        .font(.body.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canProceed ? Color.primary : Color.primary.opacity(0.3))
            #if canImport(UIKit)
            .foregroundStyle(Color(UIColor.systemBackground))
            #else
            .foregroundStyle(.white)
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canProceed || isLoading)
    }

    @ViewBuilder
    private var errorLabel: some View {
        if let error = errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    // MARK: Helpers

    private var primaryLabel: String {
        switch step {
        case .name:  return "Continue"
        case .email: return "Send code"
        case .code:  return "Verify"
        }
    }

    private var canProceed: Bool {
        switch step {
        case .name:  return !firstName.trimmingCharacters(in: .whitespaces).isEmpty
        case .email: return email.contains("@") && email.contains(".")
        case .code:  return otp.count == 6
        }
    }

    private func advance() {
        Task {
            switch step {
            case .name:
                withAnimation { step = .email }
            case .email:
                await sendCode()
            case .code:
                await verifyCode()
            }
        }
    }

    private func sendCode() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.sendOTP(email: email)
            withAnimation { step = .code }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func verifyCode() async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseService.shared.verifyOTP(email: email, token: otp)
            try? await SupabaseService.shared.upsertProfile(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName:  lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            session.completeOnboarding(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName:  lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - OTP box input

private struct OTPBoxField: View {
    @Binding var code: String
    private let length = 6
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: code) { _, new in
                    code = String(new.filter(\.isNumber).prefix(length))
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { i in
                    digitBox(index: i)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { isFocused = true }
    }

    private func digitBox(index: Int) -> some View {
        let char: String = index < code.count
            ? String(code[code.index(code.startIndex, offsetBy: index)])
            : ""
        let isNext = index == code.count

        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isNext && isFocused ? Color.primary.opacity(0.4) : Color.clear,
                            lineWidth: 2
                        )
                )
            Text(char).font(.title2.weight(.semibold))
        }
        .frame(width: 44, height: 52)
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(SessionStore())
    }
}
#endif
