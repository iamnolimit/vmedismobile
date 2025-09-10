// File: App/ContentView.swift - Proper Carousel Rotation
import SwiftUI

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var showLoginPage = false
    @State private var leftOffset: CGFloat = 0
    @State private var centerOffset: CGFloat = 0
    @State private var rightOffset: CGFloat = 0
    @State private var isAnimating = false
    
    private let sliderItems = [
        SliderItem(
            title: "P&F",
            iconName: "doc.text",
            iconColor: .orange,
            backgroundColor: Color.orange.opacity(0.1)
        ),
        SliderItem(
            title: "Apotek / Klinik",
            iconName: "house.fill",
            iconColor: .blue,
            backgroundColor: Color.blue.opacity(0.1)
        ),
        SliderItem(
            title: "Praktik Mandiri",
            iconName: "person.3.fill",
            iconColor: .green,
            backgroundColor: Color.green.opacity(0.1)
        )
    ]
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(spacing: 30) {
                headerView
                
                Spacer()
                
                carouselRotationView
                
                Spacer()
                
                contentAreaView
                
                Spacer()
            }
        }
        .sheet(isPresented: $showLoginPage) {
            LoginPageView(selectedItem: sliderItems[currentIndex])
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
            VStack(spacing: 20) {
                // Logo dari Bundle Resource
                if let logoImage = UIImage(named: "logo") {
                    Image(uiImage: logoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                } else {
                    // Fallback design jika logo tidak ditemukan
                    VStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.blue.opacity(0.5))
                                .font(.title2)
                            Image(systemName: "arrow.up")
                                .foregroundColor(Color.blue.opacity(0.3))
                                .font(.title2)
                        }
                        
                        ZStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                                .font(.caption)
                                .offset(y: -2)
                        }
                    }
                }
                
            }
            .padding(.top, 20)
        }
    
    // MARK: - Carousel Rotation View
    private var carouselRotationView: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let leftPosition: CGFloat = screenWidth * 0.05   // 5% from left (more left)
            let centerPosition: CGFloat = screenWidth * 0.5  // Exactly center
            let rightPosition: CGFloat = screenWidth * 0.95  // 95% from left (more right)
            
            ZStack {
                // Left Item
                SliderItemView(
                    item: sliderItems[leftIndex],
                    isCenter: false
                )
                .position(x: leftPosition + leftOffset, y: 100)
                .onTapGesture {
                    if !isAnimating {
                        rotateRight() // Tap left item moves it to center
                    }
                }
                
                // Center Item
                SliderItemView(
                    item: sliderItems[currentIndex],
                    isCenter: true
                )
                .position(x: centerPosition + centerOffset, y: 100)
                .onTapGesture {
                    showLoginPage = true
                }
                
                // Right Item
                SliderItemView(
                    item: sliderItems[rightIndex],
                    isCenter: false
                )
                .position(x: rightPosition + rightOffset, y: 100)
                .onTapGesture {
                    if !isAnimating {
                        rotateLeft() // Tap right item moves it to center
                    }
                }
            }
            .clipped()
            .gesture(
                DragGesture()
                    .onEnded { dragValue in
                        if !isAnimating {
                            let threshold: CGFloat = 50
                            
                            if dragValue.translation.width > threshold {
                                // Swipe right - rotate right (left becomes center)
                                rotateRight()
                            } else if dragValue.translation.width < -threshold {
                                // Swipe left - rotate left (right becomes center)
                                rotateLeft()
                            }
                        }
                    }
            )
        }
        .frame(height: 200)
    }
    
    // MARK: - Content Area View
    private var contentAreaView: some View {
        VStack(spacing: 20) {
            Text("Pilih aplikasi Anda lalu")
                .font(.title3)
                .foregroundColor(.black)
            
            Text("Klik tombol LOGIN di bawah ini")
                .font(.title3)
                .foregroundColor(.black)
            
            Button(action: {
                showLoginPage = true
            }) {
                HStack {
                    Text("LOGIN")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(sliderItems[currentIndex].iconColor)
                .cornerRadius(8)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Computed Properties
    private var leftIndex: Int {
        return currentIndex > 0 ? currentIndex - 1 : sliderItems.count - 1
    }
    
    private var rightIndex: Int {
        return (currentIndex + 1) % sliderItems.count
    }
    
    // MARK: - Animation Methods
    private func rotateLeft() {
        // Right item becomes center, center becomes left, left becomes right
        isAnimating = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Move items to their new positions
            leftOffset = 200  // Current left moves far right (will become new right)
            centerOffset = -150  // Current center moves left
            rightOffset = -200  // Current right moves to center
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Update the index (right item is now center)
            currentIndex = rightIndex
            
            // Reset offsets
            leftOffset = 0
            centerOffset = 0
            rightOffset = 0
            isAnimating = false
        }
    }
    
    private func rotateRight() {
        // Left item becomes center, center becomes right, right becomes left
        isAnimating = true
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Move items to their new positions
            leftOffset = 150   // Current left moves to center
            centerOffset = 200 // Current center moves right
            rightOffset = -200 // Current right moves far left (will become new left)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Update the index (left item is now center)
            currentIndex = leftIndex
            
            // Reset offsets
            leftOffset = 0
            centerOffset = 0
            rightOffset = 0
            isAnimating = false
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
