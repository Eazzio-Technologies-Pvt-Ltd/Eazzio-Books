import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/permissions/permission_helper.dart';
import 'package:mobile_books/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mobile_books/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile_books/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile_books/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mobile_books/features/customers/presentation/screens/customers_screen.dart';
import 'package:mobile_books/features/customers/presentation/screens/customer_detail_screen.dart';
import 'package:mobile_books/features/customers/presentation/screens/customer_form_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/items_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/item_detail_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/item_form_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/stock_adjustment_form_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/inventory_movements_screen.dart';
import 'package:mobile_books/features/quotes/presentation/screens/quotes_screen.dart';
import 'package:mobile_books/features/quotes/presentation/screens/quote_detail_screen.dart';
import 'package:mobile_books/features/quotes/presentation/screens/quote_form_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/invoices_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/invoice_detail_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/invoice_form_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/invoice_document_preview_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/payments_received_list_screen.dart';
import 'package:mobile_books/features/invoices/presentation/screens/payment_received_form_screen.dart';
import 'package:mobile_books/features/quotes/presentation/screens/quote_document_preview_screen.dart';
import 'package:mobile_books/features/items/presentation/screens/low_stock_alerts_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/item_valuation_report_screen.dart';
import 'package:mobile_books/features/credit_notes/presentation/screens/credit_notes_list_screen.dart';
import 'package:mobile_books/features/credit_notes/presentation/screens/credit_note_detail_screen.dart';
import 'package:mobile_books/features/credit_notes/presentation/screens/credit_note_form_screen.dart';
import 'package:mobile_books/features/delivery_challans/presentation/screens/delivery_challans_list_screen.dart';
import 'package:mobile_books/features/delivery_challans/presentation/screens/delivery_challan_detail_screen.dart';
import 'package:mobile_books/features/delivery_challans/presentation/screens/delivery_challan_form_screen.dart';
import 'package:mobile_books/features/recurring_invoices/presentation/screens/recurring_invoices_list_screen.dart';
import 'package:mobile_books/features/recurring_invoices/presentation/screens/recurring_invoice_form_screen.dart';
import 'package:mobile_books/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/trial_balance_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/pnl_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/balance_sheet_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/cash_flow_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/customer_aging_screen.dart';
import 'package:mobile_books/features/reports/presentation/screens/vendor_aging_screen.dart';
import 'package:mobile_books/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:mobile_books/core/widgets/placeholder_page.dart';
import 'package:mobile_books/features/banking/presentation/screens/reconciliation_selector_screen.dart';
import 'package:mobile_books/features/sales_orders/presentation/screens/sales_orders_list_screen.dart';
import 'package:mobile_books/features/sales_orders/presentation/screens/sales_order_detail_screen.dart';
import 'package:mobile_books/features/sales_orders/presentation/screens/sales_order_form_screen.dart';

// Group D screen imports
import 'package:mobile_books/features/banking/presentation/screens/bank_accounts_screen.dart';
import 'package:mobile_books/features/banking/presentation/screens/bank_account_details_screen.dart';
import 'package:mobile_books/features/banking/presentation/screens/bank_reconciliation_screen.dart';
import 'package:mobile_books/features/accounting/presentation/screens/chart_of_accounts_screen.dart';
import 'package:mobile_books/features/accounting/presentation/screens/account_form_screen.dart';
import 'package:mobile_books/features/accounting/presentation/screens/manual_journals_screen.dart';
import 'package:mobile_books/features/accounting/presentation/screens/manual_journal_details_screen.dart';
import 'package:mobile_books/features/accounting/presentation/screens/manual_journal_form_screen.dart';
import 'package:mobile_books/features/transaction_locks/presentation/screens/transaction_locking_screen.dart';
import 'package:mobile_books/features/bulk_updates/presentation/screens/bulk_updates_screen.dart';
import 'package:mobile_books/features/taxes/presentation/screens/taxes_list_screen.dart';
import 'package:mobile_books/features/taxes/presentation/screens/tax_form_screen.dart';
import 'package:mobile_books/features/documents/presentation/screens/documents_list_screen.dart';
import 'package:mobile_books/features/documents/presentation/screens/document_upload_screen.dart';
import 'package:mobile_books/features/settings/presentation/screens/organization_settings_screen.dart';
import 'package:mobile_books/features/salespersons/presentation/screens/salespersons_list_screen.dart';
import 'package:mobile_books/features/salespersons/presentation/screens/salesperson_form_screen.dart';

// Group B screen imports
import 'package:mobile_books/features/vendors/presentation/screens/vendors_list_screen.dart';
import 'package:mobile_books/features/vendors/presentation/screens/vendor_form_screen.dart';
import 'package:mobile_books/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile_books/features/purchase_orders/presentation/screens/purchase_orders_list_screen.dart';
import 'package:mobile_books/features/purchase_orders/presentation/screens/purchase_order_form_screen.dart';
import 'package:mobile_books/features/purchase_orders/presentation/screens/purchase_order_detail_screen.dart';
import 'package:mobile_books/features/bills/presentation/screens/bills_list_screen.dart';
import 'package:mobile_books/features/bills/presentation/screens/bill_form_screen.dart';
import 'package:mobile_books/features/bills/presentation/screens/bill_detail_screen.dart';
import 'package:mobile_books/features/payments_made/presentation/screens/payments_made_list_screen.dart';
import 'package:mobile_books/features/payments_made/presentation/screens/payment_made_form_screen.dart';
import 'package:mobile_books/features/expenses/presentation/screens/expenses_list_screen.dart';
import 'package:mobile_books/features/expenses/presentation/screens/expense_form_screen.dart';
import 'package:mobile_books/features/expenses/presentation/screens/expense_detail_screen.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/screens/recurring_expenses_list_screen.dart';
import 'package:mobile_books/features/recurring_expenses/presentation/screens/recurring_expense_form_screen.dart';
import 'package:mobile_books/features/vendor_credits/presentation/screens/vendor_credits_list_screen.dart';
import 'package:mobile_books/features/vendor_credits/presentation/screens/vendor_credit_form_screen.dart';
import 'package:mobile_books/features/vendor_credits/presentation/screens/vendor_credit_detail_screen.dart';
import 'package:mobile_books/features/projects/presentation/screens/projects_list_screen.dart';
import 'package:mobile_books/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:mobile_books/features/projects/presentation/screens/project_form_screen.dart';
import 'package:mobile_books/features/timesheets/presentation/screens/timesheets_list_screen.dart';
import 'package:mobile_books/features/timesheets/presentation/screens/timesheet_form_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';
      final isForgotting = location == '/forgot-password';
      final isResetting = location.startsWith('/reset-password');

      final isPublicRoute = isLoggingIn || isRegistering || isForgotting || isResetting;

      // While checking session initialization, allow boot route
      if (authState is AuthInitial) {
        return null;
      }

      // If user is not logged in and attempts secure access, force login redirect
      if (authState is AuthUnauthenticated) {
        return isPublicRoute ? null : '/login';
      }

      // If user is authenticated, redirect away from public auth forms to Dashboard
      if (authState is AuthAuthenticated) {
        if (isPublicRoute) {
          return '/dashboard';
        }
        // Verify route permission
        final role = authState.user.role;
        if (!PermissionHelper.hasRoutePermission(role, location)) {
          return '/dashboard';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/items',
        builder: (context, state) => const ItemsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ItemFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ItemDetailScreen(itemId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ItemFormScreen(itemId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        redirect: (context, state) {
          if (state.matchedLocation == '/inventory') {
            return '/inventory/movements';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'stock',
            builder: (context, state) => const StockAdjustmentFormScreen(),
          ),
          GoRoute(
            path: 'movements',
            builder: (context, state) => const InventoryMovementsScreen(),
          ),
          GoRoute(
            path: 'low-stock',
            builder: (context, state) => const LowStockAlertsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) => const CustomersScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CustomerFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomerDetailScreen(customerId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CustomerFormScreen(customerId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/quotes',
        builder: (context, state) => const QuotesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const QuoteFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return QuoteDetailScreen(quoteId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return QuoteFormScreen(quoteId: id);
            },
          ),
          GoRoute(
            path: ':id/document',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return QuoteDocumentPreviewScreen(quoteId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/sales-orders',
        builder: (context, state) => const SalesOrdersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final convertFromQuoteIdStr = state.uri.queryParameters['convertFromQuoteId'];
              final convertFromQuoteId = convertFromQuoteIdStr != null ? int.tryParse(convertFromQuoteIdStr) : null;
              return SalesOrderFormScreen(convertFromQuoteId: convertFromQuoteId);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return SalesOrderDetailScreen(salesOrderId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return SalesOrderFormScreen(salesOrderId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/invoices',
        builder: (context, state) => const InvoicesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final quoteIdStr = state.uri.queryParameters['convertFromQuoteId'];
              final quoteId = quoteIdStr != null ? int.tryParse(quoteIdStr) : null;
              return InvoiceFormScreen(convertFromQuoteId: quoteId);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return InvoiceDetailScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return InvoiceFormScreen(invoiceId: id);
            },
          ),
          GoRoute(
            path: ':id/record-payment',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final balanceDueStr = state.uri.queryParameters['balanceDue'] ?? '0.0';
              final balanceDue = double.tryParse(balanceDueStr) ?? 0.0;
              return PaymentReceivedFormScreen(invoiceId: id, balanceDue: balanceDue);
            },
          ),
          GoRoute(
            path: ':id/document',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return InvoiceDocumentPreviewScreen(invoiceId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: '/reports',
        redirect: (context, state) {
          if (state.matchedLocation == '/reports') {
            return '/reports/profit-loss';
          }
          return null;
        },
        routes: [
          GoRoute(
            path: 'trial-balance',
            builder: (context, state) => const TrialBalanceScreen(),
          ),
          GoRoute(
            path: 'profit-loss',
            builder: (context, state) => const PnlScreen(),
          ),
          GoRoute(
            path: 'balance-sheet',
            builder: (context, state) => const BalanceSheetScreen(),
          ),
          GoRoute(
            path: 'cash-flow',
            builder: (context, state) => const CashFlowScreen(),
          ),
          GoRoute(
            path: 'customer-aging',
            builder: (context, state) => const CustomerAgingScreen(),
          ),
          GoRoute(
            path: 'vendor-aging',
            builder: (context, state) => const VendorAgingScreen(),
          ),
          GoRoute(
            path: 'item-valuation',
            builder: (context, state) => const ItemValuationReportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/payments-received',
        builder: (context, state) => const PaymentsReceivedListScreen(),
      ),
      GoRoute(
        path: '/credit-notes',
        builder: (context, state) => const CreditNotesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreditNoteFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CreditNoteDetailScreen(creditNoteId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return CreditNoteFormScreen(creditNoteId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/delivery-challans',
        builder: (context, state) => const DeliveryChallansListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) {
              final fromSalesOrder = state.uri.queryParameters['fromSalesOrder'];
              final salesOrderId = fromSalesOrder != null ? int.tryParse(fromSalesOrder) : null;
              return DeliveryChallanFormScreen(convertFromSalesOrderId: salesOrderId);
            },
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return DeliveryChallanDetailScreen(challanId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return DeliveryChallanFormScreen(challanId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/recurring-invoices',
        builder: (context, state) => const RecurringInvoicesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const RecurringInvoiceFormScreen(),
          ),
        ],
      ),
      // Vendors
      GoRoute(
        path: '/vendors',
        builder: (context, state) => const VendorsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const VendorFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VendorDetailScreen(vendorId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VendorFormScreen(vendorId: id);
            },
          ),
        ],
      ),
      // Purchase Orders
      GoRoute(
        path: '/purchase-orders',
        builder: (context, state) => const PurchaseOrdersListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const PurchaseOrderFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PurchaseOrderDetailScreen(purchaseOrderId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PurchaseOrderFormScreen(purchaseOrderId: id);
            },
          ),
        ],
      ),
      // Bills
      GoRoute(
        path: '/bills',
        builder: (context, state) => const BillsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const BillFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BillDetailScreen(billId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BillFormScreen(billId: id);
            },
          ),
          GoRoute(
            path: ':id/record-payment',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final balanceDueStr = state.uri.queryParameters['balanceDue'] ?? '0.0';
              final balanceDue = double.tryParse(balanceDueStr) ?? 0.0;
              return PaymentMadeFormScreen(billId: id, balanceDue: balanceDue);
            },
          ),
        ],
      ),
      // Expenses
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ExpenseFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ExpenseDetailScreen(expenseId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ExpenseFormScreen(expenseId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/recurring-expenses',
        builder: (context, state) => const RecurringExpensesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const RecurringExpenseFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return RecurringExpenseFormScreen(expenseId: id);
            },
          ),
        ],
      ),
      // Payments Made
      GoRoute(
        path: '/payments-made',
        builder: (context, state) => const PaymentsMadeListScreen(),
      ),
      // Vendor Credits
      GoRoute(
        path: '/vendor-credits',
        builder: (context, state) => const VendorCreditsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const VendorCreditFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VendorCreditDetailScreen(vendorCreditId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VendorCreditFormScreen(vendorCreditId: id);
            },
          ),
        ],
      ),
      // Projects
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ProjectFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ProjectDetailScreen(projectId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ProjectFormScreen(projectId: id);
            },
          ),
        ],
      ),
      // Timesheets
      GoRoute(
        path: '/timesheets',
        builder: (context, state) => const TimesheetsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TimesheetFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return TimesheetFormScreen(timesheetId: id);
            },
          ),
        ],
      ),
      // Banking Routes
      GoRoute(
        path: '/banking',
        builder: (context, state) => const BankAccountsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BankAccountDetailsScreen(accountId: id);
            },
          ),
          GoRoute(
            path: ':id/reconcile',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BankReconciliationScreen(bankAccountId: id);
            },
          ),
        ],
      ),
      // Accounting & Chart of Accounts
      GoRoute(
        path: '/accounting/coa',
        builder: (context, state) => const ChartOfAccountsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const AccountFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return AccountFormScreen(accountId: id);
            },
          ),
        ],
      ),
      // Manual Journals
      GoRoute(
        path: '/accounting/journals',
        builder: (context, state) => const ManualJournalsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ManualJournalFormScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ManualJournalDetailsScreen(journalId: id);
            },
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ManualJournalFormScreen(journalId: id);
            },
          ),
        ],
      ),
      // Transaction Locking
      GoRoute(
        path: '/transaction-locking',
        builder: (context, state) => const TransactionLockingScreen(),
      ),
      // Bulk Updates
      GoRoute(
        path: '/bulk-updates',
        builder: (context, state) => const BulkUpdatesScreen(),
      ),
      // Taxes
      GoRoute(
        path: '/taxes',
        builder: (context, state) => const TaxesListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const TaxFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return TaxFormScreen(taxId: id);
            },
          ),
        ],
      ),
      // Direct Reconciliation Screen Select
      GoRoute(
        path: '/reconciliation',
        builder: (context, state) => const ReconciliationSelectorScreen(),
      ),
      // Placeholder routes
      GoRoute(
        path: '/bank-rules',
        builder: (context, state) => const PlaceholderPage(
          title: 'Bank Rules',
          message: 'Automated bank rules configuration is coming soon to mobile!',
          currentRoute: '/banking',
        ),
      ),
      GoRoute(
        path: '/currency-adjustments',
        builder: (context, state) => const PlaceholderPage(
          title: 'Currency Adjustments',
          message: 'Foreign currency adjustments and revaluation are coming soon to mobile!',
          currentRoute: '/accounting/journals',
        ),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsListScreen(),
        routes: [
          GoRoute(
            path: 'upload',
            builder: (context, state) => const DocumentUploadScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings/organization',
        builder: (context, state) => const OrganizationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/users',
        builder: (context, state) => const PlaceholderPage(
          title: 'Users & Roles',
          message: 'Manage users and roles configuration is coming soon to mobile!',
          currentRoute: '/dashboard',
        ),
      ),
      GoRoute(
        path: '/salespersons',
        builder: (context, state) => const SalespersonsListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const SalespersonFormScreen(),
          ),
        ],
      ),
    ],
  );
});

class PlaceholderScreen extends ConsumerWidget {
  final String title;
  final String currentRoute;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> navButtons = [];

    navButtons.add(
      ElevatedButton(
        onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
        child: const Text('Logout'),
      ),
    );

    if (currentRoute == '/dashboard') {
      navButtons.addAll([
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.push('/customers'),
          child: const Text('Customers'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push('/items'),
          child: const Text('Items'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push('/quotes'),
          child: const Text('Quotes'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push('/invoices'),
          child: const Text('Invoices'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => context.push('/tasks'),
          child: const Text('Tasks'),
        ),
      ]);
    } else {
      navButtons.addAll([
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Back'),
        ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$title Screen',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
              ...navButtons,
            ],
          ),
        ),
      ),
    );
  }
}
