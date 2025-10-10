// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    let userData: UserData
    @State private var selectedTab = 0
    @State private var navigationRoute: String?
    @State private var shouldNavigateToReport = false
    @State private var submenuToExpand: String?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Home Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                .id("home-tab") // Preserve WebView state
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
              // 2. Obat Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
                .id("obat-tab") // Preserve WebView state
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                    Text("Obat")
                }
                .tag(1)
            
            // 3. Keuangan Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
                .id("keuangan-tab") // Preserve WebView state
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                    Text("Keuangan")
                }
                .tag(2)
            
            // 4. Forecast Tab
            LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
                .id("forecast-tab") // Preserve WebView state
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Forecast")
                }
                .tag(3)// 5. Account Tab - Using native ProfileView with Customer menu
            ProfileView(
                userData: userData,
                navigationRoute: $navigationRoute,
                shouldNavigate: $shouldNavigateToReport,
                submenuToExpand: $submenuToExpand
            )
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
            setupStatsNavigationListener()
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
          // iOS 16+ uses only scrollEdgeAppearance
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
      private func setupStatsNavigationListener() {
        // Listen untuk notification dari stats navigation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NavigateToReport"),
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let route = userInfo["route"] as? String else {
                return
            }
            
            print("📱 MainTabView received navigation request: \(route)")
            
            // Get submenu info if available
            let submenu = userInfo["submenu"] as? String
            if let submenu = submenu, !submenu.isEmpty {
                print("📂 Should expand submenu: \(submenu)")
            }
            
            // Switch ke tab Akun (index 4)
            self.selectedTab = 4
            
            // Set navigation state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Expand submenu jika ada
                if let submenu = submenu, !submenu.isEmpty {
                    self.submenuToExpand = submenu
                }
                
                self.navigationRoute = route
                self.shouldNavigateToReport = true
                
                print("✅ Navigation state set: \(route)")
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
    let icon: String
    let title: String
    let route: String
    
    init(icon: String = "doc.text", title: String, route: String) {
        self.icon = icon
        self.title = title
        self.route = route
    }
}

// MARK: - Profile View
struct ProfileView: View {
    let userData: UserData
    @Binding var navigationRoute: String?
    @Binding var shouldNavigate: Bool
    @Binding var submenuToExpand: String?
    @EnvironmentObject var appState: AppState
    @State private var expandedMenuIds: Set<UUID> = []
    @State private var navigateToRoute: String?
      // Menu structure based on provided data
    let menuItems: [MenuItem] = [
        MenuItem(icon: "person.3", title: "Customer", route: "customers"),
        
        MenuItem(icon: "person.text.rectangle", title: "Pendaftaran Klinik", subMenus: [
            SubMenuItem(icon: "person.badge.plus", title: "Laporan Registrasi Pasien", route: "lapregistrasipasien"),
            SubMenuItem(icon: "person.2", title: "Laporan Kunjungan Pasien", route: "lapkunjunganpasien")
        ]),
        
        MenuItem(icon: "stethoscope", title: "Pelayanan Klinik", subMenus: [
            SubMenuItem(icon: "calendar.badge.clock", title: "Laporan Janji Dengan Dokter", route: "lapjanjidengandokter")
        ]),
        
        MenuItem(icon: "creditcard", title: "Billing Kasir", subMenus: [
            SubMenuItem(icon: "dollarsign.circle", title: "Laporan Piutang Klinik", route: "lappiutangklinik"),
            SubMenuItem(icon: "banknote", title: "Laporan Pembayaran Kasir", route: "lappembayarankasir"),
            SubMenuItem(icon: "cart", title: "Laporan Penjualan Obat Klinik", route: "lappenjualanobatklinik"),
            SubMenuItem(icon: "doc.text.magnifyingglass", title: "Laporan Tagihan Jaminan", route: "laptagihanjaminan"),
            SubMenuItem(icon: "stethoscope", title: "Laporan Pendapatan Petugas Medis", route: "lappendapatanpetugasmedis")
        ]),
        
        MenuItem(icon: "pills", title: "Laporan Apotek", subMenus: [
            SubMenuItem(icon: "cart.fill", title: "Laporan Pembelian", route: "lappembelianobat"),
            SubMenuItem(icon: "creditcard.circle", title: "Laporan Hutang Obat", route: "laphutangobat"),
            SubMenuItem(icon: "bag", title: "Laporan Penjualan Obat", route: "lappenjualanobat"),
            SubMenuItem(icon: "dollarsign.arrow.circlepath", title: "Laporan Piutang Obat", route: "lappiutangobat"),
            SubMenuItem(icon: "exclamationmark.triangle", title: "Laporan Obat Stok Habis", route: "lapobatstokhabis"),
            SubMenuItem(icon: "calendar.badge.exclamationmark", title: "Laporan Obat Expired", route: "lapobatexpired"),
            SubMenuItem(icon: "star.fill", title: "Laporan Obat Terlaris", route: "lapobatterlaris"),
            SubMenuItem(icon: "shippingbox", title: "Laporan Stok Opname", route: "lapstokopname"),
            SubMenuItem(icon: "square.stack.3d.up", title: "Laporan Stok Obat", route: "lapstokobat"),
            SubMenuItem(icon: "arrow.left.arrow.right", title: "Laporan Pergantian Shift", route: "lappergantianshift")
        ])
    ];
      var body: some View {
        NavigationView {
            ZStack {
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
                            
                            // DEBUG: Test navigation button
                            #if DEBUG
                            Divider()
                            Button(action: {
                                print("🧪 TEST: Manual trigger navigation")
                                navigateToRoute = "lappenjualanobat"
                                print("🧪 TEST: navigateToRoute set to: \(String(describing: navigateToRoute))")
                            }) {
                                HStack {
                                    Image(systemName: "hammer.fill")
                                        .foregroundColor(.orange)
                                    Text("DEBUG: Test Navigation")
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                .padding()
                            }
                            #endif
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
                .navigationTitle("Akun")
                .navigationBarTitleDisplayMode(.inline)
                
                // Programmatic NavigationLink - in background
                NavigationLink(
                    destination: Group {
                        if let route = navigateToRoute {
                            ReportPageView(userData: userData, route: route)
                                .onAppear {
                                    print("📄 ReportPageView appeared for route: \(route)")
                                }
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { 
                            print("🔗 NavigationLink isActive getter: \(navigateToRoute != nil)")
                            return navigateToRoute != nil 
                        },
                        set: { isActive in
                            print("🔗 NavigationLink isActive setter: \(isActive)")
                            if !isActive {
                                print("🔙 NavigationLink deactivated")
                            }
                        }
                    ),
                    label: { EmptyView() }
                )
                .frame(width: 0, height: 0)
                .opacity(0)
            }
        }.navigationViewStyle(StackNavigationViewStyle()) // Force single column on iPad
        .preferredColorScheme(.light) // Force light mode
        .onChange(of: submenuToExpand) { newSubmenu in
            if let submenu = newSubmenu {
                print("📂 Expanding submenu: \(submenu)")
                
                // Find menu dengan title yang match
                if let menuToExpand = menuItems.first(where: { $0.title == submenu }) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expandedMenuIds.insert(menuToExpand.id)
                    }
                    print("✅ Submenu expanded: \(submenu)")
                }
                
                // Reset submenu state
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    submenuToExpand = nil
                }
            }
        }        .onChange(of: shouldNavigate) { newValue in
            if newValue, let route = navigationRoute {
                print("🎯 ProfileView triggering navigation to: \(route)")
                print("   Current navigateToRoute: \(String(describing: navigateToRoute))")
                print("   Setting navigateToRoute to: \(route)")
                
                // Set state to trigger NavigationLink
                navigateToRoute = route
                
                // Add small delay to ensure state is set
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("✅ navigateToRoute is now: \(String(describing: self.navigateToRoute))")
                }
                
                // Reset navigation state after navigation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🔄 Resetting navigation states")
                    shouldNavigate = false
                    navigationRoute = nil
                    
                    // Reset local state after navigation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        navigateToRoute = nil
                    }
                }
            }
        }
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
                                    .frame(width: 20)
                                
                                // Icon untuk sub menu (bukan dots)
                                Image(systemName: subMenu.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
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
                                .padding(.leading, 60)
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
