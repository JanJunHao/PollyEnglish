import SwiftUI

struct GreetingHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(greeting)
                .font(AppFonts.display(28, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
            Text("今天学一点英语？")
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.lg)
        .padding(.top, AppSpacing.xl)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:  return "早上好 👋"
        case 11..<14: return "中午好 👋"
        case 14..<18: return "下午好 👋"
        default:      return "晚上好 👋"
        }
    }
}

#Preview {
    GreetingHeader()
        .preferredColorScheme(.dark)
        .background(AppColors.bgPrimary)
}
