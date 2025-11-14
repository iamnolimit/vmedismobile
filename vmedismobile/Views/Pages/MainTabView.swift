// File: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var previousTab: Int? = nil // Track previous tab for back navigation
    @State private var navigationRoute: String?
    @State private var shouldNavigateToReport = false
    @State private var submenuToExpand: String?
    @State private var accessibleTabs: [String] = []
    @State private var isCheckingAccess = true
    
    // Computed property to get current userData (always non-nil since we only show MainTabView when logged in)
    private var userData: UserData {
        return appState.userData!
    }
    
    var body: some View {
        if isCheckingAccess {
            // Loading state saat check access
            VStack {
                ProgressView()
                Text("Memeriksa akses...")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                checkTabAccess()
            }        } else {
            TabView(selection: $selectedTab) {
                // 1. Home Tab - conditional
                if accessibleTabs.contains("home") {
                    LoadingBypassWebView(userData: userData, destinationUrl: "mobile")
                        .id("home-tab-\(userData.id ?? "0")")
                        .tabItem {
                            Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                            Text("Home")
                        }
                        .tag(0)
                }
                  // 2. Obat Tab - conditional
                if accessibleTabs.contains("products") {
                    LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=products")
                        .id("obat-tab-\(userData.id ?? "0")")
                        .tabItem {
                            Image(systemName: selectedTab == 1 ? "pills.fill" : "pills")
                            Text("Obat")
                        }
                        .tag(1)
                }
                  // 3. Keuangan Tab - conditional
                if accessibleTabs.contains("orders") {
                    LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=orders")
                        .id("keuangan-tab-\(userData.id ?? "0")")
                        .tabItem {
                            Image(systemName: selectedTab == 2 ? "banknote.fill" : "banknote")
                            Text("Keuangan")
                        }
                        .tag(2)
                }
                  // 4. Forecast Tab - conditional
                if accessibleTabs.contains("forecast") {
                    LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=forecast")
                        .id("forecast-tab-\(userData.id ?? "0")")
                        .tabItem {
                            Image(systemName: selectedTab == 3 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                            Text("Forecast")
                        }                        
                        .tag(3)
                }
                
                // 5. Account Tab - always accessible
                ProfileView(
                    userData: userData,
                    navigationRoute: $navigationRoute,
                    shouldNavigate: $shouldNavigateToReport,
                    submenuToExpand: $submenuToExpand,
                    previousTab: $previousTab,
                    selectedTab: $selectedTab
                )
                .id("profile-tab-\(userData.id ?? "0")") // Force re-render when userData changes (critical for account switching!)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    Text("Akun")
                }
                .tag(4)
            }
            .id("tabview-\(userData.id ?? "0")") // Force TabView re-render on userData change
            .accentColor(.blue)
            .preferredColorScheme(.light)
            .onAppear {
                setupTabBarAppearance()
                setupStatsNavigationListener()
                // Check tab access on appear
                checkTabAccess()
            }            .onChange(of: userData.id) { newId in
                // Reload tab access when userData changes (account switch)
                print("🔄 UserData.id changed to: \(newId ?? "N/A")")
                
                // Use DispatchQueue to ensure userData is fully updated before checking access
                DispatchQueue.main.async {
                    print("   Verifying userData after async: ID=\(userData.id ?? "N/A"), Level=\(userData.lvl ?? 0)")
                    checkTabAccess()
                }
            }
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
        ]        // iOS 16+ uses only scrollEdgeAppearance
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
            
            // Save current tab before switching (for back navigation)
            if self.selectedTab != 4 {
                self.previousTab = self.selectedTab
                print("💾 Saved previous tab: \(self.selectedTab)")
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
    
    // MARK: - Tab Access Control
      /// Check akses user ke setiap tab
    private func checkTabAccess() {
        print("🔐 Checking tab access for user (ID: \(userData.id ?? "N/A"))...")
        
        let userLevel = userData.lvl ?? 999
        
        // Superadmin (lvl=1) - full access ke semua tab
        if userLevel == 1 {
            print("👑 Superadmin detected - granting full tab access")
            accessibleTabs = ["home", "products", "orders", "forecast", "account"]
            isCheckingAccess = false
            return
        }
        
        // Load menu access LANGSUNG dari userData (bukan dari UserDefaults!)
        guard let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty else {
            print("⚠️ No menu access in userData - granting only account tab")
            // Default: hanya tab Akun yang accessible
            accessibleTabs = ["account"]
            isCheckingAccess = false
            return
        }
        
        print("📋 Checking tab access from userData.aksesMenu (\(aksesMenu.count) items)")
        
        // Regular user - check akses per tab berdasarkan aksesMenu dari userData
        let allTabs = ["home", "products", "orders", "forecast", "account"]
        accessibleTabs = allTabs.filter { tabName in
            // Tab Akun selalu accessible
            if tabName == "account" {
                return true
            }
            
            // Check apakah tab accessible
            if let mnUrl = MenuURLMapping.getURL(for: tabName) {
                return aksesMenu.contains(mnUrl)
            }
            return false
        }
        
        print("✅ Accessible tabs for user: \(accessibleTabs)")
        print("   - Home: \(accessibleTabs.contains("home") ? "✓" : "✗")")
        print("   - Obat: \(accessibleTabs.contains("products") ? "✓" : "✗")")
        print("   - Keuangan: \(accessibleTabs.contains("orders") ? "✓" : "✗")")
        print("   - Forecast: \(accessibleTabs.contains("forecast") ? "✓" : "✗")")
        print("   - Akun: ✓ (always)")
        
        isCheckingAccess = false
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
    @Binding var previousTab: Int?
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState
    @State private var expandedMenuIds: Set<UUID> = []
    @State private var navigateToRoute: String?
    
    // MARK: - Menu Access Properties
    @State private var userMenuAccess: [MenuAccess] = []
    @State private var filteredMenuItems: [MenuItem] = []
    @State private var isLoadingMenu: Bool = true
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
        ]),
        
        MenuItem(icon: "chart.bar.doc.horizontal", title: "Laporan Keuangan", subMenus: [
            SubMenuItem(icon: "doc.text", title: "Laporan Neraca Umum", route: "lapneracaumum"),
            SubMenuItem(icon: "chart.line.uptrend.xyaxis", title: "Laporan Laba Rugi", route: "laplabarugi")
        ]),
        
        MenuItem(icon: "gearshape.2", title: "Sistem", subMenus: [
            SubMenuItem(icon: "person.2.circle", title: "Manajemen User", route: "lapmanajemenuser"),
            SubMenuItem(icon: "building.columns", title: "Pengaturan Bank", route: "lappengaturanbank")
        ])
    ];var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 20) {                        // Profile Header
                        VStack(spacing: 16) {
                            // Profile Image - Load dari userData
                            AsyncImage(url: getUserPhotoURL()) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    // Error loading - show placeholder
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                case .empty:
                                    // Loading state
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            ProgressView()
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        )
                                }
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
                            }                        }
                        .padding()
                        
                        // Account Management Section
                        AccountManagementSection()
                            .padding(.horizontal)
                        
                        // Menu Options with Accordion
                        VStack(spacing: 0) {
                            // Loading state
                            if isLoadingMenu {
                                HStack {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                    Text("Memuat menu...")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else if filteredMenuItems.isEmpty {
                                // Empty state - no accessible menu
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(.orange)
                                    Text("Tidak ada menu yang dapat diakses")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Text("Hubungi administrator untuk bantuan")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                // Display accessible menus
                                ForEach(filteredMenuItems) { menu in
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
                                    
                                    if menu.id != filteredMenuItems.last?.id {
                                        Divider()
                                    }
                                }
                            }
                              Divider()
                              // Logout Options
                            ProfileOptionRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Logout Akun Ini",
                                action: {
                                    appState.logout()
                                }
                            )
                            
                            // Show "Logout Semua" only if multiple sessions exist
                            if SessionManager.shared.sessions.count > 1 {
                                Divider()
                                
                                ProfileOptionRow(
                                    icon: "rectangle.portrait.and.arrow.right.fill",
                                    title: "Logout Semua Akun",
                                    titleColor: .red,
                                    action: {
                                        appState.logoutAllAccounts()
                                    }
                                )
                            }
                            
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.05))
                
                // Fixed Footer - tidak ikut scroll
                VStack(spacing: 0) {
                    Divider()
                    
                    Text(AppVersion.poweredByText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                }
                
                // Programmatic NavigationLink - hidden but functional
                NavigationLink(
                    destination: ReportPageView(
                        userData: userData, 
                        route: navigateToRoute ?? ""
                    )
                    .onAppear {
                        if let route = navigateToRoute {
                            print("📄 ReportPageView appeared for route: \(route)")
                        }
                    }
                    .onDisappear {
                        if let route = navigateToRoute {
                            print("👋 ReportPageView disappeared for route: \(route)")
                        }
                    },                    isActive: Binding(
                        get: { 
                            navigateToRoute != nil
                        },
                        set: { isActive in
                            if !isActive {
                                // User tapped back - reset navigation states and restore previous tab
                                print("🔙 User tapped back - resetting navigation states")
                                DispatchQueue.main.async {
                                    self.navigateToRoute = nil
                                    self.shouldNavigate = false
                                    self.navigationRoute = nil
                                    
                                    // Restore previous tab if coming from stats navigation
                                    if let prevTab = self.previousTab {
                                        print("↩️ Restoring previous tab: \(prevTab)")
                                        self.selectedTab = prevTab
                                        self.previousTab = nil // Clear after restore
                                    }
                                }
                            }
                        }
                    ),
                    label: { EmptyView() }
                )
                .frame(width: 0, height: 0)
                .opacity(0)            }
            .navigationTitle("Akun")
            .navigationBarTitleDisplayMode(.inline)
        }        .navigationViewStyle(StackNavigationViewStyle()) // Force single column on iPad
        .preferredColorScheme(.light) // Force light mode
        .onAppear {
            // Load menu access saat view muncul
            loadUserMenuAccess()
        }
        .onChange(of: userData.id) { _ in
            // Reload menu access when userData changes (account switch)
            print("🔄 UserData changed - reloading menu access")
            loadUserMenuAccess()
        }
        .onChange(of: submenuToExpand) { newSubmenu in
            if let submenu = newSubmenu {
                print("📂 Expanding submenu: \(submenu)")
                
                // Find menu dengan title yang match dari filteredMenuItems
                if let menuToExpand = filteredMenuItems.first(where: { $0.title == submenu }) {
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
        }.onChange(of: shouldNavigate) { newValue in
            if newValue, let route = navigationRoute {
                print("🎯 ProfileView triggering navigation to: \(route)")
                print("   Setting navigateToRoute to: \(route)")
                
                // Set state to trigger NavigationLink
                navigateToRoute = route
                
                print("✅ navigateToRoute is now: \(String(describing: self.navigateToRoute))")
                
                // ✅ Don't auto-reset! Let NavigationLink's set closure handle it when user taps back
                // This prevents the page from closing immediately
            }
        }
    }    // MARK: - Helper Functions
    /// Filter menu items berdasarkan hak akses user
    private func filterMenuItemsByAccess(_ menuItems: [MenuItem]) -> [MenuItem] {
        var filtered: [MenuItem] = []
        
        // Extract accessible URLs from userMenuAccess
        let accessibleUrls = Set(userMenuAccess.map { $0.mn_url })
        print("🔍 Filtering with \(accessibleUrls.count) accessible URLs from userMenuAccess")
        
        for menu in menuItems {
            // Menu tanpa submenu
            if let route = menu.route, menu.subMenus == nil {
                if hasLocalAccess(to: route, accessibleUrls: accessibleUrls) {
                    filtered.append(menu)
                }
            }
            // Menu dengan submenu
            else if let subMenus = menu.subMenus {
                // Filter submenu berdasarkan akses
                let filteredSubs = subMenus.filter { hasLocalAccess(to: $0.route, accessibleUrls: accessibleUrls) }
                
                // Hanya tampilkan parent jika ada submenu yang accessible
                if !filteredSubs.isEmpty {
                    // Create new MenuItem with filtered submenus
                    let filteredMenu = MenuItem(
                        icon: menu.icon,
                        title: menu.title,
                        route: menu.route,
                        subMenus: filteredSubs
                    )
                    filtered.append(filteredMenu)
                }
            }
        }
        
        print("📊 Filtered menu: \(filtered.count) items from \(menuItems.count) total")
        return filtered
    }
    
    /// Check access LOKAL dari userMenuAccess (tidak dari UserDefaults)
    private func hasLocalAccess(to route: String, accessibleUrls: Set<String>) -> Bool {
        // Map route ke mn_url
        guard let mnUrl = MenuURLMapping.getURL(for: route) else {
            return false
        }
        
        // Check apakah mn_url ada di accessible URLs
        return accessibleUrls.contains(mnUrl)
    }/// Load dan filter menu berdasarkan hak akses user
    private func loadUserMenuAccess() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔐 LOADING MENU ACCESS FOR USER")
        print("   Username: \(userData.username ?? "unknown")")
        print("   User ID: \(userData.id ?? "N/A")")
        print("   Level: \(userData.lvl ?? 999)")
        print("   Domain: \(userData.domain ?? "N/A")")
        print("   AksesMenu count: \(userData.aksesMenu?.count ?? 0)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        isLoadingMenu = true
        
        // Check user level - lvl=1 adalah superadmin dengan full akses
        let userLevel = userData.lvl ?? 999
        
        if userLevel == 1 {
            // Superadmin - berikan full akses ke semua menu
            print("👑 Superadmin detected (lvl=\(userLevel)) - granting full access to ALL \(menuItems.count) menu items")
            filteredMenuItems = menuItems
            userMenuAccess = [] // Superadmin tidak perlu menu access list
            isLoadingMenu = false
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
            return
        }
        
        // Load menu access LANGSUNG dari userData (TIDAK melalui UserDefaults!)
        if let aksesMenu = userData.aksesMenu, !aksesMenu.isEmpty {
            // Convert aksesMenu dari userData ke MenuAccess objects
            let menuAccessItems = aksesMenu.map { mnUrl in
                MenuAccess(mn_url: mnUrl, mn_kode: "", mn_nama: "")
            }
            
            // LANGSUNG gunakan data dari userData, TIDAK save ke UserDefaults
            userMenuAccess = menuAccessItems
            
            print("📋 User (lvl=\(userLevel)) has access to \(aksesMenu.count) menu URLs from userData.aksesMenu:")
            for (index, url) in aksesMenu.enumerated() {
                print("   \(index + 1). \(url)")
            }
            
            // Filter menu berdasarkan hak akses
            print("🔍 Filtering menu based on access...")
            filteredMenuItems = filterMenuItemsByAccess(menuItems)
            
            // Log hasil filtering
            print("✅ Filtered to \(filteredMenuItems.count) accessible menu items:")
            for menu in filteredMenuItems {
                if let subMenus = menu.subMenus {
                    print("   📂 \(menu.title) - \(subMenus.count) submenus")
                } else {                    print("   📄 \(menu.title) - route: \(menu.route ?? "none")")
                }
            }
        } else {
            // Tidak ada menu access di userData
            print("⚠️ No menu access data in userData - user has NO access to any menu")
            filteredMenuItems = []
            userMenuAccess = []
        }
        
        isLoadingMenu = false
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
    }
    
    /// Construct URL foto profil user berdasarkan data yang tersedia
    /// Logika sama seperti mobile lama (React Native)
    private func getUserPhotoURL() -> URL? {
        // Base URL untuk gambar
        let baseImageURL = "https://apt.vmedis.com/foto/"
        
        // Priority 1: Gunakan logo user jika ada (untuk user personal)
        if let userLogo = userData.logo, !userLogo.isEmpty {
            let photoURL = baseImageURL + userLogo
            return URL(string: photoURL)
        }
        
        // Priority 2: Gunakan logo klinik atau apotek berdasarkan app_jenis
        // app_jenis: 1 = Klinik, 2 = Apotek
        let appJenis = userData.app_jenis ?? 1
        
        if appJenis == 2 {
            // Apotek - gunakan apt_logo jika ada
            if let aptLogo = userData.kl_logo, !aptLogo.isEmpty {
                let photoURL = baseImageURL + aptLogo
                return URL(string: photoURL)
            }
        } else {
            // Klinik - gunakan kl_logo jika ada
            if let klLogo = userData.kl_logo, !klLogo.isEmpty {
                let photoURL = baseImageURL + klLogo
                return URL(string: photoURL)
            }
        }
        
        // Default: return nil untuk trigger placeholder
        return nil
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
    var titleColor: Color = .black
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(titleColor == .red ? .red : .blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(titleColor)
                
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
    @State private var refreshTrigger = 0
    
    var body: some View {
        LoadingBypassWebView(userData: userData, destinationUrl: "mobile?tab=\(route)")
            .id("report-\(route)-\(refreshTrigger)") // Cache by route, allow manual refresh
            .navigationTitle(getTitle(for: route))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Manual refresh - increment trigger
                        refreshTrigger += 1
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .preferredColorScheme(.light) // Force light mode
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

// MARK: - Account Management Section
struct AccountManagementSection: View {    @StateObject private var sessionManager = SessionManager.shared
    @EnvironmentObject var appState: AppState
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: AccountSession?
    @State private var showingAccountDropdown = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Dropdown Button - SAMA dengan MenuRowContent padding
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showingAccountDropdown.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Avatar - sama seperti icon menu (30pt frame)
                    if let activeSession = sessionManager.activeSession {
                        AsyncImage(url: getPhotoURL(for: activeSession)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.blue)
                                    )
                            case .empty:
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    )
                            @unknown default:
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.blue)
                                    )
                            }
                        }
                        .frame(width: 30, height: 30) // Sama dengan icon menu
                        .clipShape(Circle())
                        
                        // Info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activeSession.displayName)
                                .font(.body) // Sama dengan menu title
                                .foregroundColor(.black)
                            
                            Text(activeSession.domainInfo)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("Tidak ada akun tersimpan")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Chevron - sama dengan menu
                    Image(systemName: showingAccountDropdown ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14)) // Sama dengan menu chevron
                        .foregroundColor(.gray)
                }
                .padding() // SAMA dengan MenuRowContent - 16pt default padding
                .background(Color.white)
                .contentShape(Rectangle())
            }
              // Dropdown List - SAMA dengan submenu styling
            if showingAccountDropdown {
                VStack(spacing: 0) {
                    // All Sessions (including active) - SAMA dengan submenu items
                    ForEach(sessionManager.sessions) { session in
                        Button(action: {
                            if !session.isActive {
                                withAnimation {
                                    showingAccountDropdown = false
                                }
                                appState.switchAccount(to: session)
                            }
                        }) {
                            HStack(spacing: 12) {
                                // Indentation 20pt - SAMA dengan submenu
                                Spacer()
                                    .frame(width: 20)
                                
                                // Avatar - sama dengan submenu icon (24pt frame)
                                AsyncImage(url: getPhotoURL(for: session)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                            )
                                    case .empty:
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            )
                                    @unknown default:
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gray)
                                            )
                                    }
                                }
                                .frame(width: 24, height: 24) // Sama dengan submenu icon
                                .clipShape(Circle())
                                
                                // Info
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.displayName)
                                        .font(.subheadline) // Sama dengan submenu title
                                        .foregroundColor(.black)
                                    
                                    Text(session.domainInfo)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.leading, 8) // Sama dengan submenu
                                
                                Spacer()
                                
                                // Active Label or Delete Button
                                if session.isActive {
                                    Text("Aktif")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green)
                                        .cornerRadius(4)
                                } else {
                                    Button(action: {
                                        sessionToDelete = session
                                        showingDeleteAlert = true
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 12))
                                            .foregroundColor(.red)
                                            .padding(6)
                                    }
                                }
                            }
                            .padding(.vertical, 12) // SAMA dengan submenu vertical padding
                            .padding(.horizontal, 16) // SAMA dengan submenu horizontal padding
                            .background(session.isActive ? Color.gray.opacity(0.05) : Color.white) // Sama dengan submenu background
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(session.isActive)
                        
                        if session.id != sessionManager.sessions.last?.id {
                            Divider()
                                .padding(.leading, 60) // SAMA dengan submenu divider
                        }
                    }
                      // Add Account Button - SAMA dengan submenu item
                    Divider()
                    
                    Button(action: {
                        showingAccountDropdown = false
                        // LANGSUNG ke login tanpa konfirmasi sheet
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Logout tapi session tetap tersimpan
                            appState.isLoggedIn = false
                            // Jangan set appState.userData = nil agar tidak crash
                        }
                    }) {
                        HStack(spacing: 12) {
                            // Indentation 20pt
                            Spacer()
                                .frame(width: 20)
                            
                            // Icon - 24pt frame sama dengan submenu
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(sessionManager.canAddMoreSessions() ? .blue : .gray)
                                .frame(width: 24)
                            
                            Text("Tambah Akun Baru")
                                .font(.subheadline) // Sama dengan submenu
                                .foregroundColor(sessionManager.canAddMoreSessions() ? .black : .gray)
                                .padding(.leading, 8)
                            
                            Spacer()
                            
                            if !sessionManager.canAddMoreSessions() {
                                Text("\(sessionManager.sessions.count)/5")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 12) // SAMA dengan submenu
                        .padding(.horizontal, 16) // SAMA dengan submenu
                        .background(Color.gray.opacity(0.03))
                        .contentShape(Rectangle())
                    }
                    .disabled(!sessionManager.canAddMoreSessions())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Hapus Akun"),
                message: Text("Apakah Anda yakin ingin menghapus akun \(sessionToDelete?.displayName ?? "")?"),
                primaryButton: .destructive(Text("Hapus")) {
                    if let session = sessionToDelete {
                        sessionManager.removeSession(session)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func getPhotoURL(for session: AccountSession) -> URL? {
        let baseImageURL = "https://apt.vmedis.com/foto/"
        
        if let userLogo = session.userData.logo, !userLogo.isEmpty {
            return URL(string: baseImageURL + userLogo)
        }
        
        let appJenis = session.userData.app_jenis ?? 1
        if appJenis == 2 {
            if let aptLogo = session.userData.kl_logo, !aptLogo.isEmpty {
                return URL(string: baseImageURL + aptLogo)
            }
        } else {
            if let klLogo = session.userData.kl_logo, !klLogo.isEmpty {
                return URL(string: baseImageURL + klLogo)
            }
        }
          return nil
    }
}
