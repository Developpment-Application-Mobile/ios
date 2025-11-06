import SwiftUI

struct WelcomeScreen: View {
    var onGetStartedClick: () -> Void = {}
    var onChildLoginClick: () -> Void = {}
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.686, green: 0.494, blue: 0.906).opacity(0.6),
                    Color(red: 0.153, green: 0.125, blue: 0.322)
                ]),
                center: .init(x: 0.3, y: 0.3),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Decorative elements
            DecorativeElements()
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Title
                Text("Welcome\nto EduKid Academy!")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .frame(maxWidth: 323, alignment: .leading)
                
                Spacer().frame(height: 15)
                
                // Subtitle
                Text("Play, Learn, and Explore with Exciting Quizzes!")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: 269, alignment: .leading)
                
                Spacer().frame(height: 34)
                
                // Get Started Button
                Button(action: onGetStartedClick) {
                    Text("GET STARTED")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                
                Spacer().frame(height: 20)
                
                // Child Login Button
                Button(action: onChildLoginClick) {
                    Text("LOG IN AS CHILD")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.18, green: 0.18, blue: 0.18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(30)
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Decorative Elements
struct DecorativeElements: View {
    var body: some View {
        ZStack {
            // Book and Globe - Center
            Image("book_and_globe")
                .resizable()
                .scaledToFit()
                .frame(width: 426, height: 426)
                .offset(x: 0, y: -200)
            
            // Education Book - Top Left
            Image("education_book")
                .resizable()
                .scaledToFit()
                .frame(width: 224, height: 224)
                .offset(x: -160, y: -350)
            
            // Book Stacks - Bottom Right (with blur)
            Image("book_stacks")
                .resizable()
                .scaledToFit()
                .frame(width: 116, height: 116)
                .blur(radius: 2)
                .offset(x: 120, y: 250)
            
            // Coins 1 - Top Right
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 123, height: 123)
                .offset(x: 140, y: -350)
            
            // Coins 2 - Top Center (flipped horizontally)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 53, height: 53)
                .scaleEffect(x: -1, y: 1)
                .offset(x: 20, y: -280)
            
            // Coins 3 - Middle Right (rotated)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(28.68))
                .offset(x: 150, y: 10)
            
            // Coins 4 - Bottom Left (rotated)
            Image("coins")
                .resizable()
                .scaledToFit()
                .frame(width: 42, height: 42)
                .rotationEffect(.degrees(38.66))
                .offset(x: -140, y: 250)
        }
    }
}

// MARK: - Preview
struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
