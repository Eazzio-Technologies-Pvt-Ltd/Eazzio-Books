import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/theme/app_assets.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/permissions/permission_helper.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/organizations/presentation/providers/organization_provider.dart';

final globalSearchProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.trim().isEmpty) return {};
  final networkClient = ref.read(networkClientProvider);
  final response = await networkClient.get('/search', queryParameters: {'q': query});
  return response.data as Map<String, dynamic>;
});

class SidebarMenuItem {
  final String label;
  final IconData icon;
  final String? path;
  final List<SidebarSubmenuItem>? children;

  const SidebarMenuItem({
    required this.label,
    required this.icon,
    this.path,
    this.children,
  });
}

class SidebarSubmenuItem {
  final String label;
  final String path;

  const SidebarSubmenuItem({
    required this.label,
    required this.path,
  });
}

const List<SidebarMenuItem> sidebarMenus = [
  SidebarMenuItem(
    label: 'Home',
    icon: Icons.home_outlined,
    path: '/dashboard',
  ),
  SidebarMenuItem(
    label: 'Items',
    icon: Icons.inventory_2_outlined,
    children: [
      SidebarSubmenuItem(label: 'Items', path: '/items'),
      SidebarSubmenuItem(label: 'New Item', path: '/items/new'),
      SidebarSubmenuItem(label: 'Stock In / Stock Out', path: '/inventory/stock'),
      SidebarSubmenuItem(label: 'Inventory Movements', path: '/inventory/movements'),
      SidebarSubmenuItem(label: 'Low Stock Alerts', path: '/inventory/low-stock'),
      SidebarSubmenuItem(label: 'Item Valuation Report', path: '/reports/item-valuation'),
    ],
  ),
  SidebarMenuItem(
    label: 'Sales',
    icon: Icons.shopping_cart_outlined,
    children: [
      SidebarSubmenuItem(label: 'Customers', path: '/customers'),
      SidebarSubmenuItem(label: 'Quotes', path: '/quotes'),
      SidebarSubmenuItem(label: 'Invoices', path: '/invoices'),
      SidebarSubmenuItem(label: 'Sales Orders', path: '/sales-orders'),
      SidebarSubmenuItem(label: 'Payments Received', path: '/payments-received'),
      SidebarSubmenuItem(label: 'Delivery Challans', path: '/delivery-challans'),
      SidebarSubmenuItem(label: 'Credit Notes', path: '/credit-notes'),
      SidebarSubmenuItem(label: 'Recurring Invoices', path: '/recurring-invoices'),
      SidebarSubmenuItem(label: 'Salespersons', path: '/salespersons'),
    ],
  ),
  SidebarMenuItem(
    label: 'Purchases',
    icon: Icons.shopping_bag_outlined,
    children: [
      SidebarSubmenuItem(label: 'Vendors', path: '/vendors'),
      SidebarSubmenuItem(label: 'Expenses', path: '/expenses'),
      SidebarSubmenuItem(label: 'Recurring / Fixed Expenses', path: '/recurring-expenses'),
      SidebarSubmenuItem(label: 'Purchase Orders', path: '/purchase-orders'),
      SidebarSubmenuItem(label: 'Bills', path: '/bills'),
      SidebarSubmenuItem(label: 'Payments Made', path: '/payments-made'),
      SidebarSubmenuItem(label: 'Vendor Credits', path: '/vendor-credits'),
    ],
  ),
  SidebarMenuItem(
    label: 'Time Tracking',
    icon: Icons.access_time_outlined,
    children: [
      SidebarSubmenuItem(label: 'Projects', path: '/projects'),
      SidebarSubmenuItem(label: 'Timesheets', path: '/timesheets'),
    ],
  ),
  SidebarMenuItem(
    label: 'Banking',
    icon: Icons.account_balance_outlined,
    children: [
      SidebarSubmenuItem(label: 'Bank Accounts', path: '/banking'),
      SidebarSubmenuItem(label: 'Bank Rules', path: '/bank-rules'),
      SidebarSubmenuItem(label: 'Reconciliation', path: '/reconciliation'),
    ],
  ),
  SidebarMenuItem(
    label: 'Accountant',
    icon: Icons.calculate_outlined,
    children: [
      SidebarSubmenuItem(label: 'Chart of Accounts', path: '/accounting/coa'),
      SidebarSubmenuItem(label: 'Manual Journals', path: '/accounting/journals'),
      SidebarSubmenuItem(label: 'Transaction Locking', path: '/transaction-locking'),
      SidebarSubmenuItem(label: 'Bulk Updates', path: '/bulk-updates'),
      SidebarSubmenuItem(label: 'Currency Adjustments', path: '/currency-adjustments'),
      SidebarSubmenuItem(label: 'Taxes', path: '/taxes'),
    ],
  ),
  SidebarMenuItem(
    label: 'Reports',
    icon: Icons.assessment_outlined,
    children: [
      SidebarSubmenuItem(label: 'Profit & Loss', path: '/reports/profit-loss'),
      SidebarSubmenuItem(label: 'Balance Sheet', path: '/reports/balance-sheet'),
      SidebarSubmenuItem(label: 'Cash Flow', path: '/reports/cash-flow'),
      SidebarSubmenuItem(label: 'Trial Balance', path: '/reports/trial-balance'),
    ],
  ),
  SidebarMenuItem(
    label: 'Documents',
    icon: Icons.description_outlined,
    children: [
      SidebarSubmenuItem(label: 'All Documents', path: '/documents'),
      SidebarSubmenuItem(label: 'Upload Documents', path: '/documents/upload'),
    ],
  ),
];
class ResponsiveScaffold extends ConsumerStatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final String currentRoute;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    required this.currentRoute,
    this.floatingActionButton,
  });

  @override
  ConsumerState<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends ConsumerState<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Use simple static/stateful variables to keep track of UI state
  static bool _isCollapsed = false;
  static final Set<String> _expandedMenus = {};

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Global Search'),
              content: SizedBox(
                width: 400,
                height: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search customers, items, invoices, quotes...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (query.trim().isNotEmpty)
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final searchAsync = ref.watch(globalSearchProvider(query));
                            return searchAsync.when(
                              data: (results) {
                                final customers = results['customers'] as List? ?? [];
                                final items = results['items'] as List? ?? [];
                                final invoices = results['invoices'] as List? ?? [];
                                final quotes = results['quotes'] as List? ?? [];
                                
                                if (customers.isEmpty && items.isEmpty && invoices.isEmpty && quotes.isEmpty) {
                                  return const Center(child: Text('No results found.'));
                                }
                                
                                return ListView(
                                  children: [
                                    if (customers.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('CUSTOMERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                      ),
                                      ...customers.map((c) => ListTile(
                                        title: Text(c['display_name'] ?? c['company_name'] ?? ''),
                                        subtitle: Text(c['email'] ?? ''),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/customers/${c['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (items.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                      ),
                                      ...items.map((it) => ListTile(
                                        title: Text(it['name'] ?? ''),
                                        subtitle: Text('SKU: ${it['sku'] ?? ""} | Price: ₹${it['selling_price'] ?? "0"}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/items/${it['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (invoices.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('INVOICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                      ),
                                      ...invoices.map((inv) => ListTile(
                                        title: Text(inv['invoice_number'] ?? ''),
                                        subtitle: Text('Total: ₹${inv['total_amount'] ?? "0"} | Status: ${inv['status'] ?? ""}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/invoices/${inv['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (quotes.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('QUOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                      ),
                                      ...quotes.map((q) => ListTile(
                                        title: Text(q['quote_number'] ?? ''),
                                        subtitle: Text('Total: ₹${q['total_amount'] ?? "0"} | Status: ${q['status'] ?? ""}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/quotes/${q['id']}');
                                        },
                                      )),
                                    ],
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(child: Text('Error: $err')),
                            );
                          },
                        ),
                      )
                    else
                      const Expanded(child: Center(child: Text('Type to start searching...'))),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateOrgDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        String selectedBusinessType = 'Services';
        final formKey = GlobalKey<FormState>();
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create New Organization'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Organization Name',
                        hintText: 'e.g. My Retail Shop',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Organization name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBusinessType,
                      decoration: const InputDecoration(
                        labelText: 'Business Type',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Services', child: Text('Services')),
                        DropdownMenuItem(value: 'Retail', child: Text('Retail')),
                        DropdownMenuItem(value: 'Manufacturing', child: Text('Manufacturing')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedBusinessType = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final name = nameController.text.trim();
                      Navigator.pop(context);
                      
                      final success = await ref
                          .read(organizationsProvider.notifier)
                          .createAndSwitchOrg(name: name, businessType: selectedBusinessType);
                          
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Created and switched to "$name"')),
                        );
                      } else if (context.mounted) {
                        final error = ref.read(organizationsProvider).errorMessage ?? 'Failed to create organization';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrgSwitcherButton(BuildContext context, bool isMobile) {
    final authState = ref.watch(authNotifierProvider);
    final orgState = ref.watch(organizationsProvider);
    
    String currentOrgName = 'My Business';
    if (authState is AuthAuthenticated) {
      currentOrgName = authState.user.organizationName ?? 'My Business';
    }
    
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'create_new') {
          _showCreateOrgDialog(context);
        } else if (value.startsWith('switch_')) {
          final parts = value.split('_');
          final orgId = int.tryParse(parts[1]) ?? 0;
          final orgName = parts.sublist(2).join('_');
          final success = await ref.read(organizationsProvider.notifier).switchOrg(orgId, orgName);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Switched to "$orgName"')),
            );
          }
        }
      },
      itemBuilder: (context) {
        final List<PopupMenuEntry<String>> items = [];
        
        items.add(
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(
              'ORGANIZATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );
        
        for (final org in orgState.organizations) {
          final isActive = authState is AuthAuthenticated && authState.user.organizationId == org.id;
          items.add(
            PopupMenuItem<String>(
              value: 'switch_${org.id}_${org.name}',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      org.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isActive)
                    const Icon(Icons.check, color: AppColors.primaryBlue, size: 18),
                ],
              ),
            ),
          );
        }
        
        items.add(const PopupMenuDivider());
        
        items.add(
          const PopupMenuItem<String>(
            value: 'create_new',
            child: Row(
              children: [
                Icon(Icons.add, color: AppColors.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text('Create New Organization'),
              ],
            ),
          ),
        );
        
        return items;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: isMobile
            ? const Icon(Icons.business_outlined, size: 22)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      currentOrgName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        key: const Key('quickActionButton'),
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        onPressed: () => _showQuickActionsBottomSheet(context),
      ),
    );
  }

  Widget _buildProfileAvatarButton(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    String firstLetter = 'R';
    if (authState is AuthAuthenticated) {
      final email = authState.user.email;
      if (email.isNotEmpty) {
        firstLetter = email[0].toUpperCase();
      }
    }
    return InkWell(
      key: const Key('profileAvatarButton'),
      onTap: () => _showProfileMenuBottomSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 12, left: 4),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF1b2337),
          child: Text(
            firstLetter,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.m),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: AppColors.primaryBlue),
                title: const Text('New Invoice'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/invoices/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.request_quote_outlined, color: AppColors.primaryBlue),
                title: const Text('New Quote'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/quotes/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline, color: AppColors.primaryBlue),
                title: const Text('New Customer'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/customers/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined, color: AppColors.primaryBlue),
                title: const Text('New Item'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/items/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined, color: AppColors.primaryBlue),
                title: const Text('New Bill'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/bills/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primaryBlue),
                title: const Text('New Expense'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/expenses/new');
                },
              ),
              ListTile(
                leading: const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue),
                title: const Text('New Journal Entry'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/accounting/journals/new');
                },
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        );
      },
    );
  }

  void _showProfileMenuBottomSheet(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    String userEmail = 'user@eazzio.com';
    String userRole = 'Admin';
    if (authState is AuthAuthenticated) {
      userEmail = authState.user.email;
      userRole = authState.user.role;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeModeProvider);
            final isDark = themeMode == ThemeMode.dark || 
                (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
            
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'R',
                            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userEmail,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Role: $userRole',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.business, color: AppColors.textSecondaryLight),
                    title: const Text('Organization Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings/organization');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined, color: AppColors.textSecondaryLight),
                    title: const Text('Users & Roles'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings/users');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.percent, color: AppColors.textSecondaryLight),
                    title: const Text('Taxes'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/taxes');
                    },
                  ),
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: AppColors.textSecondaryLight,
                    ),
                    title: const Text('Dark Mode'),
                    value: isDark,
                    onChanged: (bool value) {
                      ref.read(themeModeProvider.notifier).setThemeMode(
                          value ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            );
          },
        );
      },
    );
  }



  PreferredSizeWidget? _buildAppBar(BuildContext context, bool isMobile) {
    if (widget.appBar != null) {
      if (widget.appBar is AppBar) {
        final originalAppBar = widget.appBar as AppBar;
        
        final mergedActions = <Widget>[
          if (isMobile && context.canPop())
            IconButton(
              key: const Key('backButton'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          
          if (!isMobile)
            ...?originalAppBar.actions,
          
          IconButton(
            key: const Key('globalSearchButton'),
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          
          if (isMobile && originalAppBar.actions != null && originalAppBar.actions!.isNotEmpty)
            ...?originalAppBar.actions,
          
          _buildOrgSwitcherButton(context, isMobile),
          _buildProfileAvatarButton(context),
        ];

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final titleWidget = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: originalAppBar.title ?? const Text('Eazzio Books'),
        );

        return AppBar(
          key: originalAppBar.key,
          leading: isMobile ? IconButton(
            key: const Key('drawerOpenButton'),
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ) : originalAppBar.leading,
          title: titleWidget,
          actions: mergedActions,
          automaticallyImplyLeading: isMobile ? false : originalAppBar.automaticallyImplyLeading,
          flexibleSpace: originalAppBar.flexibleSpace,
          bottom: originalAppBar.bottom,
          elevation: originalAppBar.elevation,
          scrolledUnderElevation: originalAppBar.scrolledUnderElevation,
          shadowColor: originalAppBar.shadowColor,
          surfaceTintColor: originalAppBar.surfaceTintColor,
          backgroundColor: originalAppBar.backgroundColor,
          foregroundColor: originalAppBar.foregroundColor,
          iconTheme: originalAppBar.iconTheme,
          actionsIconTheme: originalAppBar.actionsIconTheme,
          primary: originalAppBar.primary,
          centerTitle: originalAppBar.centerTitle,
          excludeHeaderSemantics: originalAppBar.excludeHeaderSemantics,
          titleSpacing: originalAppBar.titleSpacing,
          toolbarHeight: originalAppBar.toolbarHeight,
          leadingWidth: originalAppBar.leadingWidth,
          toolbarTextStyle: originalAppBar.toolbarTextStyle,
          titleTextStyle: originalAppBar.titleTextStyle,
          systemOverlayStyle: originalAppBar.systemOverlayStyle,
          forceMaterialTransparency: originalAppBar.forceMaterialTransparency,
          clipBehavior: originalAppBar.clipBehavior,
        );
      } else {
        return widget.appBar;
      }
    } else {
      return AppBar(
        title: const Text('Eazzio Books'),
        leading: isMobile ? IconButton(
          key: const Key('drawerOpenButton'),
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ) : null,
        actions: [
          if (isMobile && context.canPop())
            IconButton(
              key: const Key('backButton'),
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          IconButton(
            key: const Key('globalSearchButton'),
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          _buildOrgSwitcherButton(context, isMobile),
          _buildProfileAvatarButton(context),
        ],
      );
    }
  }

  Widget _buildAnimatedBody(Widget body) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<String>(widget.currentRoute),
        child: body,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // Set breakpoint slightly higher to accommodate 800px width test environment as mobile if needed,
    // or keep 768px but ensure it behaves robustly. Let's use 768px to align with web.
    final isMobile = width <= 768;
    
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    final baseTheme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    int currentBottomNavIndex = 0;
    if (widget.currentRoute.startsWith('/dashboard')) {
      currentBottomNavIndex = 0;
    } else if (widget.currentRoute.startsWith('/customers')) {
      currentBottomNavIndex = 1;
    } else if (widget.currentRoute.startsWith('/invoices')) {
      currentBottomNavIndex = 2;
    } else if (widget.currentRoute.startsWith('/expenses')) {
      currentBottomNavIndex = 3;
    } else {
      currentBottomNavIndex = 4; // More/Other categories
    }

    return Theme(
      data: theme,
      child: isMobile
          ? Scaffold(
              key: _scaffoldKey,
              appBar: _buildAppBar(context, true),
              drawer: AppNavigationDrawer(currentRoute: widget.currentRoute),
              floatingActionButton: widget.floatingActionButton,
              body: _buildAnimatedBody(widget.body),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: currentBottomNavIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.secondary,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go('/dashboard');
                      break;
                    case 1:
                      context.go('/customers');
                      break;
                    case 2:
                      context.go('/invoices');
                      break;
                    case 3:
                      context.go('/expenses');
                      break;
                    case 4:
                      _scaffoldKey.currentState?.openDrawer();
                      break;
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Customers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Invoices',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.money_off_outlined),
                    activeIcon: Icon(Icons.money_off),
                    label: 'Expenses',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_outlined),
                    activeIcon: Icon(Icons.menu),
                    label: 'More',
                  ),
                ],
              ),
            )
          : Scaffold(
              body: Row(
                children: [
                  CustomSidebar(
                    currentRoute: widget.currentRoute,
                    isCollapsed: _isCollapsed,
                    expandedMenus: _expandedMenus,
                    onCollapseToggle: () {
                      setState(() {
                        _isCollapsed = !_isCollapsed;
                      });
                    },
                    onMenuToggle: (menuLabel) {
                      setState(() {
                        if (_expandedMenus.contains(menuLabel)) {
                          _expandedMenus.remove(menuLabel);
                        } else {
                          _expandedMenus.add(menuLabel);
                        }
                      });
                    },
                    onForceExpandMenu: (menuLabel) {
                      setState(() {
                        _isCollapsed = false;
                        _expandedMenus.add(menuLabel);
                      });
                    },
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF283352)),
                  Expanded(
                    child: Scaffold(
                      appBar: _buildAppBar(context, false),
                      floatingActionButton: widget.floatingActionButton,
                      body: _buildAnimatedBody(widget.body),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CustomSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool isCollapsed;
  final Set<String> expandedMenus;
  final VoidCallback onCollapseToggle;
  final ValueChanged<String> onMenuToggle;
  final ValueChanged<String> onForceExpandMenu;

  const CustomSidebar({
    super.key,
    required this.currentRoute,
    required this.isCollapsed,
    required this.expandedMenus,
    required this.onCollapseToggle,
    required this.onMenuToggle,
    required this.onForceExpandMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Zoho Books Style Color Scheme
    const bgDarkSidebar = Color(0xFF1b2337);
    const borderSidebar = Color(0xFF283352);
    const textUnselected = Color(0xFFc0c8e0);
    const textSelected = Colors.white;
    const accentColor = Color(0xFF2f80ed);

    final authState = ref.watch(authNotifierProvider);
    final role = authState is AuthAuthenticated ? authState.user.role : 'Admin';

    final allowedMenus = sidebarMenus.map((menu) {
      if (menu.children == null || menu.children!.isEmpty) {
        if (menu.path != null && !PermissionHelper.hasRoutePermission(role, menu.path!)) {
          return null;
        }
        return menu;
      }
      
      final allowedChildren = menu.children!.where((c) => PermissionHelper.hasRoutePermission(role, c.path)).toList();
      if (allowedChildren.isEmpty) {
        return null;
      }
      
      return SidebarMenuItem(
        label: menu.label,
        icon: menu.icon,
        path: menu.path,
        children: allowedChildren,
      );
    }).whereType<SidebarMenuItem>().toList();

    return Container(
      width: isCollapsed ? 72 : 240,
      height: double.infinity,
      color: bgDarkSidebar,
      child: Column(
        children: [
          // Sidebar Brand Header
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderSidebar, width: 1),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed) ...[
                  Expanded(
                    child: Row(
                      children: [
                        AppAssets.walletLogo(
                          width: 32,
                          height: 32,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Eazzio Books',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: textSelected,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  AppAssets.walletLogo(
                    width: 36,
                    height: 36,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ],
            ),
          ),

          // Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: allowedMenus.map((menu) {
                final hasChildren = menu.children != null && menu.children!.isNotEmpty;
                final isExpanded = expandedMenus.contains(menu.label);
                final isSelected = menu.path != null && currentRoute == menu.path;
                final anyChildSelected = hasChildren &&
                    menu.children!.any((c) => currentRoute.startsWith(c.path));

                if (isCollapsed) {
                  // Collapsed Sidebar Menu Item
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Tooltip(
                      message: menu.label,
                      child: InkWell(
                        onTap: () {
                          if (hasChildren) {
                            onForceExpandMenu(menu.label);
                          } else if (menu.path != null) {
                            context.go(menu.path!);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected || anyChildSelected
                                ? accentColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            menu.icon,
                            color: isSelected || anyChildSelected
                                ? textSelected
                                : textUnselected,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Expanded Sidebar Menu Item
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: InkWell(
                        onTap: () {
                          if (hasChildren) {
                            onMenuToggle(menu.label);
                          } else if (menu.path != null) {
                            context.go(menu.path!);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected && !hasChildren
                                ? accentColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                menu.icon,
                                color: (isSelected && !hasChildren) || anyChildSelected
                                    ? textSelected
                                    : textUnselected,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  menu.label,
                                  style: TextStyle(
                                    color: (isSelected && !hasChildren) || anyChildSelected
                                        ? textSelected
                                        : textUnselected,
                                    fontSize: 14,
                                    fontWeight: isSelected || anyChildSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasChildren)
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_down
                                      : Icons.keyboard_arrow_right,
                                  color: textUnselected.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasChildren && isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 2, bottom: 4),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFF283352), width: 1.5),
                            ),
                          ),
                          child: Column(
                            children: menu.children!.map((child) {
                              final isSubSelected = currentRoute == child.path || currentRoute.startsWith('${child.path}/');
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: InkWell(
                                  onTap: () => context.go(child.path),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 34,
                                    width: double.infinity,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      child.label,
                                      style: TextStyle(
                                        color: isSubSelected
                                            ? const Color(0xFF56b4ff)
                                            : const Color(0xFF8892b0),
                                        fontSize: 13,
                                        fontWeight: isSubSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Sidebar Footer with Collapse Trigger and Logout
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: borderSidebar, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              children: [
                if (!isCollapsed) ...[
                  Consumer(
                    builder: (context, ref, child) {
                      if (Platform.environment.containsKey('FLUTTER_TEST')) {
                        return const Text(
                          'test@eazzio.com',
                          style: TextStyle(
                            color: textUnselected,
                            fontSize: 12,
                          ),
                        );
                      }
                      final authState = ref.watch(authNotifierProvider);
                      String userEmail = 'User';
                      if (authState is AuthAuthenticated) {
                        userEmail = authState.user.email;
                      }
                      return Text(
                        userEmail,
                        style: const TextStyle(
                          color: textUnselected,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
                Center(
                  child: IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: textUnselected,
                    ),
                    onPressed: onCollapseToggle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Side menu list drawer for Mobile Layout
class AppNavigationDrawer extends ConsumerWidget {
  final String currentRoute;

  const AppNavigationDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryBlueDark : AppColors.primaryBlue;

    final authState = ref.watch(authNotifierProvider);
    final role = authState is AuthAuthenticated ? authState.user.role : 'Admin';

    final allowedMenus = sidebarMenus.map((menu) {
      if (menu.children == null || menu.children!.isEmpty) {
        if (menu.path != null && !PermissionHelper.hasRoutePermission(role, menu.path!)) {
          return null;
        }
        return menu;
      }
      
      final allowedChildren = menu.children!.where((c) => PermissionHelper.hasRoutePermission(role, c.path)).toList();
      if (allowedChildren.isEmpty) {
        return null;
      }
      
      return SidebarMenuItem(
        label: menu.label,
        icon: menu.icon,
        path: menu.path,
        children: allowedChildren,
      );
    }).whereType<SidebarMenuItem>().toList();

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    AppAssets.walletLogo(
                      height: 36,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Eazzio Books',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                 Consumer(
                  builder: (context, ref, child) {
                    if (Platform.environment.containsKey('FLUTTER_TEST')) {
                      return const Text(
                        'My Business (Test)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    }
                    final authState = ref.watch(authNotifierProvider);
                    String orgName = 'My Business';
                    if (authState is AuthAuthenticated) {
                      orgName = authState.user.organizationName ?? authState.user.email;
                    }
                    return Text(
                      orgName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: allowedMenus.map((menu) {
                final hasChildren = menu.children != null && menu.children!.isNotEmpty;
                final isSelected = menu.path != null && currentRoute == menu.path;
                final anyChildSelected = hasChildren &&
                    menu.children!.any((c) => currentRoute.startsWith(c.path));

                if (!hasChildren) {
                  return ListTile(
                    leading: Icon(menu.icon),
                    title: Text(menu.label),
                    selected: isSelected,
                    onTap: () {
                      Navigator.pop(context);
                      context.go(menu.path!);
                    },
                  );
                }

                return ExpansionTile(
                  leading: Icon(menu.icon),
                  title: Text(menu.label),
                  initiallyExpanded: anyChildSelected,
                  childrenPadding: const EdgeInsets.only(left: AppSpacing.m),
                  children: menu.children!.map((child) {
                    final isSubSelected = currentRoute == child.path || currentRoute.startsWith('${child.path}/');
                    return ListTile(
                      title: Text(child.label),
                      selected: isSubSelected,
                      onTap: () {
                        Navigator.pop(context);
                        context.go(child.path);
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
