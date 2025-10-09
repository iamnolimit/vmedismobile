// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Home Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // 2. Obat Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                    Text("Obat")
                }
                .tag(1)
            
            // 3. Keuangan Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                    Text("Keuangan")
                }
                .tag(2)
            
            // 4. Forecast Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Forecast")
                }
                .tag(3)
            
            // 5. Account Tab - Using native ProfileView with Customer menu
            ProfileView(userData: userData)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    Text("Akun")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .preferredColorScheme(.light)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.white
        
        // Selected item
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        
        // Unselected item
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}
}

// MARK: - Menu Data Models
struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let route: String?
    let subMenus: [SubMenuItem]?
    
    init(icon: String, title: String, route: String? = nil, subMenus: [SubMenuItem]? = nil) {
        self.icon = icon
        self.title = title
        self.route = route
        self.subMenus = subMenus
    }
}

struct SubMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let route: String
}

// MARK: - Profile View
struct ProfileView: View {
    let userData: UserData
    @EnvironmentObject var appState: AppState
    @State private var expandedMenuIds: Set<UUID> = []
    
    // Menu structure based on provided data
    let menuItems: [MenuItem] = [
        MenuItem(icon: "person.3", title: "Customer", route: "customers"),
        
        MenuItem(icon: "person.text.rectangle", title: "Pendaftaran Klinik", subMenus: [
            SubMenuItem(title: "Laporan Registrasi Pasien", route: "lapregistrasipasien"),
            SubMenuItem(title: "Laporan Kunjungan Pasien", route: "lapkunjunganpasien")
        ]),
        
        MenuItem(icon: "stethoscope", title: "Pelayanan Klinik", subMenus: [
            SubMenuItem(title: "Laporan Janji Dengan Dokter", route: "lapjanjidengandokter")
        ]),
        
        MenuItem(icon: "creditcard", title: "Billing Kasir", subMenus: [
            SubMenuItem(title: "Laporan Piutang Klinik", route: "lappiutangklinik"),
            SubMenuItem(title: "Laporan Pembayaran Kasir", route: "lappembayarankasir"),
            SubMenuItem(title: "Laporan Penjualan Obat Klinik", route: "lappenjualanobatklinik"),
            SubMenuItem(title: "Laporan Tagihan Jaminan", route: "laptagihanjaminan"),
            SubMenuItem(title: "Laporan Pendapatan Petugas Medis", route: "lappendapatanpetugasmedis")
        ]),
        
        MenuItem(icon: "pills", title: "Laporan Apotek", subMenus: [
            SubMenuItem(title: "Laporan Pembelian", route: "lappembelianobat"),
            SubMenuItem(title: "Laporan Hutang Obat", route: "laphutangobat"),
            SubMenuItem(title: "Laporan Penjualan Obat", route: "lappenjualanobat"),
            SubMenuItem(title: "Laporan Piutang Obat", route: "lappiutangobat"),
            SubMenuItem(title: "Laporan Obat Stok Habis", route: "lapobatstokhabis"),
            SubMenuItem(title: "Laporan Obat Expired", route: "lapobatexpired"),
            SubMenuItem(title: "Laporan Obat Terlaris", route: "lapobatterlaris"),
            SubMenuItem(title: "Laporan Stok Opname", route: "lapstokopname"),
            SubMenuItem(title: "Laporan Stok Obat", route: "lapstokobat"),
            SubMenuItem(title: "Laporan Pergantian Shift", route: "lappergantianshift")
        ])
    ];
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Profile Image
                        AsyncImage(url: URL(string: "https://via.placeholder.com/100")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(spacing: 4) {
                            Text(userData.nama_lengkap ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(userData.username ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let klinikName = userData.kl_nama {
                                Text(klinikName)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                    
                    // Menu Options with Accordion
                    VStack(spacing: 0) {
                        ForEach(menuItems) { menu in
                            AccordionMenuRow(
                                menu: menu,
                                isExpanded: expandedMenuIds.contains(menu.id),
                                userData: userData,
                                onToggle: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedMenuIds.contains(menu.id) {
                                            expandedMenuIds.remove(menu.id)
                                        } else {
                                            expandedMenuIds.insert(menu.id)
                                        }
                                    }
                                }
                            )
                            
                            if menu.id != menuItems.last?.id {
                                Divider()
                            }
                        }
                        
                        Divider()
                        
                        // Logout Option
                        ProfileOptionRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Logout",
                            action: {
                                appState.logout()
                            }
                        )
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color.gray.opacity(0.05))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Force single column on iPad
        .preferredColorScheme(.light) // Force light mode
    }
}

// MARK: - Accordion Menu Row
struct AccordionMenuRow: View {
    let menu: MenuItem
    let isExpanded: Bool
    let userData: UserData
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Master Menu Button
            if menu.subMenus != nil {
                // Menu with submenu - use button to toggle
                Button(action: onToggle) {
                    MenuRowContent(menu: menu, isExpanded: isExpanded)
                }
            } else if let route = menu.route {
                // Menu without submenu - use NavigationLink
                NavigationLink(destination: ReportPageView(userData: userData, route: route)) {
                    MenuRowContent(menu: menu, isExpanded: false)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Sub Menus (Collapsible)
            if let subMenus = menu.subMenus, isExpanded {
                VStack(spacing: 0) {
                    ForEach(subMenus) { subMenu in
                        NavigationLink(destination: ReportPageView(userData: userData, route: subMenu.route)) {
                            HStack {
                                // Indentation for sub menu
                                Spacer()
                                    .frame(width: 30)
                                
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                
                                Text(subMenu.title)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.05))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if subMenu.id != subMenus.last?.id {
                            Divider()
                                .padding(.leading, 46)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Menu Row Content (Reusable)
struct MenuRowContent: View {
    let menu: MenuItem
    let isExpanded: Bool
    
    var body: some View {
        HStack {
            Image(systemName: menu.icon)
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(menu.title)
                .font(.body)
                .foregroundColor(.black)
            
            Spacer()
            
            if menu.subMenus != nil {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
}

// MARK: - Profile Option Row
struct ProfileOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}

// MARK: - Report Page View (Full Page Navigation)
struct ReportPageView: View {
    let userData: UserData
    let route: String
    @State private var refreshId = UUID()
    
    var body: some View {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=\(route)")
            .id(refreshId) // Force refresh with unique ID
            .navigationTitle(getTitle(for: route))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Force refresh WebView
                        refreshId = UUID()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .preferredColorScheme(.light) // Force light mode
            .onAppear {
                // Force fresh load when page appears
                refreshId = UUID()
            }
    }
    
    func getTitle(for route: String) -> String {
        switch route {
        case "customers": return "Customer"
        case "lapregistrasipasien": return "Registrasi Pasien"
        case "lapkunjunganpasien": return "Kunjungan Pasien"
        case "lapjanjidengandokter": return "Janji Dengan Dokter"
        case "lappiutangklinik": return "Piutang Klinik"
        case "lappembayarankasir": return "Pembayaran Kasir"
        case "lappenjualanobatklinik": return "Penjualan Obat Klinik"
        case "laptagihanjaminan": return "Tagihan Jaminan"
        case "lappendapatanpetugasmedis": return "Pendapatan Petugas Medis"
        case "lappembelianobat": return "Pembelian Obat"
        case "laphutangobat": return "Hutang Obat"
        case "lappenjualanobat": return "Penjualan Obat"
        case "lappiutangobat": return "Piutang Obat"
        case "lapobatstokhabis": return "Obat Stok Habis"
        case "lapobatexpired": return "Obat Expired"
        case "lapobatterlaris": return "Obat Terlaris"
        case "lapstokopname": return "Stok Opname"
        case "lapstokobat": return "Stok Obat"
        case "lappergantianshift": return "Pergantian Shift"
        default: return "Laporan"
        }
    }
}
