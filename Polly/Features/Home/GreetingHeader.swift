import SwiftUI

struct GreetingHeader: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(greeting)
                .font(AppFonts.display(28, weight: .semibold))
                .foregroundColor(theme.text)
            Text("Ready to learn some English today?")
                .font(AppFonts.body(14))
                .foregroundColor(theme.textTer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xl)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning 👋"
        case 12..<18: return "Good afternoon 👋"
        default:      return "Good evening 👋"
        }
    }
}

#Preview {
    GreetingHeader()
        .preferredColorScheme(.dark)
        .background(AppColors.bgPrimary)
}
