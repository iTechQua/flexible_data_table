<div align="center">
<a href="https://pub.dev/packages/flexible_data_table/"><img src="https://img.shields.io/pub/v/flexible_data_table.svg" /></a>
<a href="https://opensource.org/licenses/MIT" target="_blank"><img src="https://img.shields.io/badge/License-MIT-yellow.svg"/></a>
<a href="https://opensource.org/licenses/Apache-2.0" target="_blank"><img src="https://badges.frapsoft.com/os/v1/open-source.svg?v=102"/></a>
<a href="https://github.com/iTechQua/flexible_data_table/issues" target="_blank"><img alt="GitHub: bhoominn" src="https://img.shields.io/github/issues-raw/iTechQua/flexible_data_table?style=flat" /></a>
<img src="https://img.shields.io/github/last-commit/iTechQua/flexible_data_table" />

<a href="https://discord.com/channels/854023838136533063/854023838576672839" target="_blank"><img src="https://img.shields.io/discord/854023838136533063" /></a>
<a href="https://github.com/iTechQua"><img alt="GitHub: bhoominn" src="https://img.shields.io/github/followers/iTechQua?label=Follow&style=social" /></a>
<a href="https://github.com/iTechQua/flexible_data_table"><img src="https://img.shields.io/github/stars/iTechQua/flexible_data_table?style=social" /></a>

<a href="https://saythanks.io/to/iTechQua" target="_blank"><img src="https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg"/></a>
<a href="https://github.com/sponsors/iTechQua"><img src="https://img.shields.io/github/sponsors/iTechQua" /></a>

<a href="https://www.buymeacoffee.com/iTechQua"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=bhoominn&button_colour=5F7FFF&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00"></a>

</div>

## Show some love and like to support the project

### Say Thanks Here
<a href="https://saythanks.io/to/iTechQua" target="_blank"><img src="https://img.shields.io/badge/Say%20Thanks-!-1EAEDB.svg"/></a>

### Follow Me on Twitter
<a href="https://x.com/iTechQua" target="_blank"><img src="https://img.shields.io/twitter/follow/iTechQua?color=1DA1F2&label=Followers&logo=twitter" /></a>

## Platform Support

| Android | iOS | MacOS  | Web | Linux | Windows |
| :-----: | :-: | :---:  | :-: | :---: | :-----: |
|   ✔️    | ✔️  |  ✔️   | ✔️  |  ✔️   |   ✔️   |

# Flexible Data Table

The **Flexible Data Table** is a powerful, enterprise-grade Flutter package for displaying and managing large datasets with advanced features like customizable headers, enhanced search, multiple table styles, and persistent user preferences. Perfect for building professional data management interfaces in Flutter applications.

This package supports both client-side and server-side data processing, making it ideal for applications ranging from simple data displays to complex enterprise dashboards.

## ✨ Features

### 🎨 **Table Styling & Types**
- **7 Built-in Table Types**: Standard, Bordered, Striped, Card, Compact, Modern, Minimal
- **Dynamic Theme Support**: Automatic light/dark mode adaptation
- **Custom Colors**: Configurable primary, header, row, and border colors
- **Responsive Design**: Automatic layout adaptation for mobile, tablet, and desktop

### 🔍 **Advanced Search & Filtering**
- **Enhanced Search**: Search through both visible and hidden columns
- **Additional Searchable Fields**: Include metadata, IDs, notes, and other hidden data in search
- **Smart Search Hints**: Contextual search hints based on available fields
- **Real-time Filtering**: Instant search results as you type

### 🛠️ **Customizable Headers**
- **Column Visibility Control**: Show/hide columns with persistent preferences
- **Drag & Drop Reordering**: Rearrange columns (coming soon)
- **Header Customization Dialog**: User-friendly column selection interface
- **Automatic Persistence**: User preferences saved using SharedPreferences

### 📊 **Data Management**
- **Server-Side Pagination**: Efficient handling of large datasets
- **Client-Side Filtering**: Fast local data filtering and sorting
- **Custom Cell Builders**: Rich cell content with widgets, icons, and styling
- **Row Actions**: Customizable action buttons for each row
- **Row Click Events**: Handle row selection and navigation

### 📱 **Export & Sharing**
- **Excel Export**: Generate and download Excel files
- **PDF Export**: Create formatted PDF documents
- **Custom File Names**: Configurable export file naming
- **Cross-Platform Sharing**: Native sharing on mobile platforms

### 🎯 **Developer Experience**
- **Type Safety**: Full generic type support for your data models
- **Easy Integration**: Simple setup with minimal boilerplate
- **Extensive Customization**: Fine-tune every aspect of the table
- **Performance Optimized**: Efficient rendering and memory usage

## Installation

Add this package to `pubspec.yaml`:

```yaml
dependencies:
  flexible_data_table: ^1.1.1
```

Or install via command line:

```console
$ flutter pub add flexible_data_table
```

Import the package:

```dart
import 'package:flexible_data_table/flexible_data_table.dart';
```

## Quick Start

### Basic Usage

```dart
FlexibleDataTable<User>(
  data: users,
  fileName: 'users_table',
  toTableDataMap: (user) => {
    'id': user.id,
    'name': user.name,
    'email': user.email,
    'status': user.isActive ? 'Active' : 'Inactive',
  },
  actionBuilder: (user) => Row(
    children: [
      IconButton(
        icon: Icon(Icons.edit),
        onPressed: () => editUser(user),
      ),
      IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => deleteUser(user),
      ),
    ],
  ),
)
```

### Advanced Usage with All Features

```dart
FlexibleDataTable<Employee>(
  // Basic Configuration
  data: employees,
  fileName: 'employee_management',
  toTableDataMap: (employee) => {
    // Visible columns
    'name': employee.fullName,
    'email': employee.email,
    'department': employee.department,
    'salary': '\$${employee.salary.toStringAsFixed(0)}',
    'status': employee.status,
    
    // Hidden but searchable fields
    'employee_id': employee.id,
    'phone': employee.phoneNumber,
    'address': employee.address,
    'notes': employee.internalNotes,
    'skills': employee.skills.join(', '),
  },
  
  // 🎨 Table Styling
  tableType: FlexibleDataTableType.modern,
  showTableTypeSelector: true,
  primaryColor: Colors.deepPurple,
  
  // 🔍 Enhanced Search Configuration
  additionalSearchableFields: [
    'employee_id', 'phone', 'address', 'notes', 'skills'
  ],
  searchHint: 'Search employees, IDs, skills, notes...',
  
  // 🛠️ Customizable Headers with Persistence
  availableHeaders: {
    'name': 'Full Name',
    'email': 'Email Address',
    'department': 'Department',
    'salary': 'Annual Salary',
    'status': 'Employment Status',
    'employee_id': 'Employee ID',
    'phone': 'Phone Number',
    'skills': 'Skills & Certifications',
  },
  initialVisibleHeaders: ['name', 'email', 'department', 'status'],
  showHeaderSelector: true,
  headerSelectorTooltip: 'Customize table columns',
  
  // 📊 Cell Customization
  cellBuilders: {
    'name': (value, employee) => Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(employee.avatarUrl),
        ),
        SizedBox(width: 8),
        Text(
          value.toString(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
    'salary': (value, employee) => Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: Colors.green[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    'status': (value, employee) => Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: employee.isActive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  },
  
  // 🎯 Actions & Interactions
  actionBuilder: (employee) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.visibility, color: Colors.blue),
        onPressed: () => viewEmployee(employee),
        tooltip: 'View Details',
      ),
      IconButton(
        icon: Icon(Icons.edit, color: Colors.orange),
        onPressed: () => editEmployee(employee),
        tooltip: 'Edit Employee',
      ),
      if (employee.canDelete)
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () => deleteEmployee(employee),
          tooltip: 'Delete Employee',
        ),
    ],
  ),
  
  // 📱 Row Interactions
  enableRowClick: true,
  onRowTap: (employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDetailPage(employee: employee),
      ),
    );
  },
  
  // 📊 Pagination & Performance
  pageSize: 25,
  isServerSide: true,
  onPageChanged: (page, pageSize) {
    // Fetch data from server
    fetchEmployees(page: page, limit: pageSize);
  },
  
  // 🎨 Layout & Sizing
  columnSizes: {
    'name': 180,
    'email': 200,
    'department': 150,
    'salary': 120,
    'status': 100,
  },
  rowHeight: 64,
  headerHeight: 48,
  minWidth: 1200,
  actionColumnWidth: 150,
  
  // 📋 Additional Configuration
  isSort: true,
  showCheckboxColumn: false,
  onHeaderVisibilityChanged: (visibleHeaders) {
    print('User customized columns: $visibleHeaders');
  },
)
```

## Table Types

The package includes 7 built-in table styles:

| Type | Description | Best For |
|------|-------------|----------|
| **Standard** | Clean, minimalist design | General purpose tables |
| **Bordered** | Full borders around all cells | Data-heavy interfaces |
| **Striped** | Alternating row colors | Long lists, improved readability |
| **Card** | Each row as an individual card | Mobile-first designs, detailed data |
| **Compact** | Reduced padding and spacing | Dense data displays |
| **Modern** | Gradient headers, shadows, premium look | Dashboards, executive reports |
| **Minimal** | Ultra-clean with subtle dividers | Elegant, simple interfaces |

```dart
// Switch between table types
FlexibleDataTable<Product>(
  tableType: FlexibleDataTableType.modern, // or any other type
  showTableTypeSelector: true, // Let users switch types
  // ... other configuration
)
```

## Advanced Search Features

### Search Through Hidden Fields

```dart
FlexibleDataTable<Order>(
  toTableDataMap: (order) => {
    // Visible columns
    'order_number': order.number,
    'customer_name': order.customerName,
    'total': order.total,
    'status': order.status,
    
    // Hidden but searchable fields
    'order_id': order.id,
    'customer_email': order.customerEmail,
    'internal_notes': order.notes,
    'tracking_number': order.trackingNumber,
    'payment_reference': order.paymentRef,
  },
  
  // Configure additional search fields
  additionalSearchableFields: [
    'order_id',
    'customer_email', 
    'internal_notes',
    'tracking_number',
    'payment_reference',
  ],
  
  // Custom search hint
  searchHint: 'Search orders, customers, tracking numbers...',
  
  // ... rest of configuration
)
```

Now users can search by order ID, customer email, internal notes, or tracking numbers even though these fields aren't visible as columns!

### Predefined Table Configurations

Use built-in configurations for common use cases:

```dart
// Employee management table
...TableConfigurations.employeeTableConfig(
  isDark: Theme.of(context).brightness == Brightness.dark,
  additionalSearchableFields: ['employee_id', 'skills', 'notes'],
  searchHint: 'Search employees, IDs, skills...',
)

// Financial/invoice table  
...TableConfigurations.financialTableConfig(
  isDark: isDarkMode,
  additionalSearchableFields: ['invoice_id', 'tax_id', 'reference'],
  searchHint: 'Search invoices, tax IDs, references...',
)

// Product inventory table
...TableConfigurations.productTableConfig(
  isDark: isDarkMode,
  additionalSearchableFields: ['sku', 'barcode', 'tags'],
  searchHint: 'Search products, SKUs, barcodes...',
)
```

## Header Customization

### Enable Column Customization

```dart
FlexibleDataTable<User>(
  // Define all possible headers
  availableHeaders: {
    'id': 'User ID',
    'name': 'Full Name',
    'email': 'Email Address',
    'phone': 'Phone Number',
    'department': 'Department',
    'role': 'User Role',
    'last_login': 'Last Login',
    'created_at': 'Registration Date',
  },
  
  // Set initial visible columns
  initialVisibleHeaders: ['name', 'email', 'department', 'role'],
  
  // Enable header customization UI
  showHeaderSelector: true,
  headerSelectorTooltip: 'Customize table columns',
  
  // Get notified when user changes columns
  onHeaderVisibilityChanged: (visibleHeaders) {
    print('Visible columns: $visibleHeaders');
    // Optional: Save to user preferences, analytics, etc.
  },
  
  // ... rest of configuration
)
```

### Programmatic Header Control

```dart
final GlobalKey<FlexibleDataTableState<User>> tableKey = 
    GlobalKey<FlexibleDataTableState<User>>();

// Reset to defaults
await tableKey.currentState?.resetToDefaults();

// Show all columns
await tableKey.currentState?.showAllColumns();

// Set specific columns
await tableKey.currentState?.setVisibleHeaders(['name', 'email', 'status']);

// Get current state
int visibleCount = tableKey.currentState?.visibleHeaderCount ?? 0;
List<String> currentHeaders = tableKey.currentState?.currentVisibleHeaders ?? [];
```

## Cell Builders

Create rich, interactive cells with custom widgets:

```dart
cellBuilders: {
  // Status badge
  'status': (value, item) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: _getStatusColor(value),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      value.toString(),
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
  ),
  
  // Progress indicator
  'completion': (value, item) => Column(
    children: [
      Text('${value}%'),
      LinearProgressIndicator(
        value: value / 100,
        backgroundColor: Colors.grey[300],
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
      ),
    ],
  ),
  
  // Currency with icon
  'amount': (value, item) => Row(
    children: [
      Icon(Icons.attach_money, size: 16, color: Colors.green),
      Text(
        value.toString(),
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
      ),
    ],
  ),
  
  // Clickable link
  'website': (value, item) => InkWell(
    onTap: () => launch(value.toString()),
    child: Text(
      value.toString(),
      style: TextStyle(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
}
```

## Export Features

### Excel Export

```dart
FlexibleDataTable<Product>(
  // ... configuration
  
  // The table automatically includes export functionality
  // Users can export via the built-in export button
  
  fileName: 'product_inventory', // Base name for exports
)

// Exports will be named: "product_inventory.xlsx" or "product_inventory.pdf"
```

### Custom Export Handling

```dart
// Access table state for programmatic export
final GlobalKey<FlexibleDataTableState<Product>> tableKey = 
    GlobalKey<FlexibleDataTableState<Product>>();

// Trigger exports programmatically
await tableKey.currentState?.exportToExcel();
await tableKey.currentState?.exportToPdf();
```

## Server-Side Integration

### Basic Server-Side Setup

```dart
FlexibleDataTable<Order>(
  // Enable server-side processing
  isServerSide: true,
  
  // Provide total count from server
  totalItems: serverResponse.totalCount,
  
  // Handle page changes
  onPageChanged: (page, pageSize) async {
    // Fetch data from your API
    final response = await apiService.getOrders(
      page: page,
      limit: pageSize,
      search: currentSearchQuery,
      sortBy: currentSortColumn,
      sortDirection: currentSortDirection,
    );
    
    // Update your state with new data
    setState(() {
      orders = response.data;
      totalItems = response.totalCount;
    });
  },
  
  // Current page data
  data: orders,
  pageSize: 25,
  
  // ... rest of configuration
)
```

### Advanced Server Integration

```dart
class OrderTableWidget extends StatefulWidget {
  @override
  _OrderTableWidgetState createState() => _OrderTableWidgetState();
}

class _OrderTableWidgetState extends State<OrderTableWidget> {
  List<Order> orders = [];
  int totalItems = 0;
  bool isLoading = false;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders({
    int page = 1,
    int pageSize = 25,
    String? search,
  }) async {
    setState(() => isLoading = true);
    
    try {
      final response = await OrderService.getOrders(
        page: page,
        limit: pageSize,
        search: search ?? searchQuery,
      );
      
      setState(() {
        orders = response.data;
        totalItems = response.totalCount;
        if (search != null) searchQuery = search;
      });
    } catch (error) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FlexibleDataTable<Order>(
      data: orders,
      isLoading: isLoading,
      isServerSide: true,
      totalItems: totalItems,
      onPageChanged: (page, pageSize) => _loadOrders(page: page, pageSize: pageSize),
      
      // ... rest of table configuration
    );
  }
}
```

## Responsive Design

The table automatically adapts to different screen sizes:

```dart
FlexibleDataTable<Item>(
  // Minimum width before horizontal scrolling
  minWidth: 800,
  
  // Responsive column sizing
  columnSizes: {
    'id': 80,
    'name': 200,
    'description': 300,
    'price': 100,
  },
  
  // Or use flexible columns
  columnFlex: {
    'id': 1,
    'name': 3,
    'description': 4,
    'price': 2,
  },
  
  // Row height adapts to content
  rowHeight: 56,
  
  // ... rest of configuration
)
```

## Performance Tips

### Large Datasets

```dart
FlexibleDataTable<Record>(
  // Use server-side processing for large datasets
  isServerSide: true,
  
  // Optimize page size based on your use case
  pageSize: 50, // Sweet spot for most applications
  
  // Limit initial visible columns
  initialVisibleHeaders: ['essential', 'columns', 'only'],
  
  // Use efficient cell builders
  cellBuilders: {
    'status': (value, item) => _cachedStatusWidget(value),
  },
  
  // ... rest of configuration
)
```

### Memory Optimization

```dart
// For very large client-side datasets
FlexibleDataTable<LargeDataItem>(
  // Keep page size reasonable
  pageSize: 25,
  
  // Use lazy loading where possible
  isServerSide: true,
  
  // Minimize complex cell builders
  cellBuilders: {
    // Simple, efficient builders
    'status': (value, item) => Text(value.toString()),
  },
)
```

## API Reference

### FlexibleDataTable Properties

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `data` | `List<T>` | List of data items to display | Required |
| `toTableDataMap` | `Map<String, dynamic> Function(T)` | Convert data item to table row | Required |
| `actionBuilder` | `Widget Function(T)` | Build action widgets for each row | Required |
| `fileName` | `String` | Base name for exports and preferences | Required |
| `tableType` | `FlexibleDataTableType` | Visual style of the table | `standard` |
| `availableHeaders` | `Map<String, String>?` | All possible columns and display names | `null` |
| `initialVisibleHeaders` | `List<String>?` | Initially visible columns | `null` |
| `additionalSearchableFields` | `List<String>?` | Hidden fields to include in search | `null` |
| `showHeaderSelector` | `bool` | Show column customization UI | `false` |
| `showTableTypeSelector` | `bool` | Show table type selector | `false` |
| `enableRowClick` | `bool` | Enable row click events | `true` |
| `isServerSide` | `bool` | Enable server-side processing | `false` |
| `pageSize` | `int` | Number of rows per page | `10` |
| `isSort` | `bool` | Enable column sorting | `true` |

### Table Types

- `FlexibleDataTableType.standard` - Clean, minimalist design
- `FlexibleDataTableType.bordered` - Full borders around cells
- `FlexibleDataTableType.striped` - Alternating row colors
- `FlexibleDataTableType.card` - Card-style rows
- `FlexibleDataTableType.compact` - Dense layout
- `FlexibleDataTableType.modern` - Premium look with gradients
- `FlexibleDataTableType.minimal` - Ultra-clean design

### CommonFlexibleDataTable

A convenience wrapper with common configurations:

```dart
CommonFlexibleDataTable<User>(
  heading: Text('User Management'),
  data: users,
  toTableDataMap: (user) => user.toMap(),
  actionBuilder: (user) => UserActions(user),
  
  // All FlexibleDataTable properties available
  additionalSearchableFields: ['user_id', 'notes'],
  showHeaderSelector: true,
  
  // Pre-configured common settings
  pageSize: 25,
  rowHeight: 60,
  headerHeight: 50,
  // ... other defaults
)
```

## Migration Guide

### From v1.1.0 to v1.1.1

The new version adds several new features while maintaining backward compatibility:

```dart
// ✅ Existing code continues to work
FlexibleDataTable<User>(
  data: users,
  toTableDataMap: (user) => user.toMap(),
  actionBuilder: (user) => UserActions(user),
)

// ✅ Add new features incrementally
FlexibleDataTable<User>(
  data: users,
  toTableDataMap: (user) => user.toMap(),
  actionBuilder: (user) => UserActions(user),
  
  // NEW: Enhanced search
  additionalSearchableFields: ['user_id', 'notes'],
  searchHint: 'Search users, IDs, notes...',
  
  // NEW: Column customization
  showHeaderSelector: true,
  availableHeaders: {
    'name': 'Full Name',
    'email': 'Email',
    // ... more headers
  },
)
```

## Contributing

We welcome contributions! Here's how you can help:

1. **Report Issues**: Found a bug? [Open an issue](https://github.com/iTechQua/flexible_data_table/issues)
2. **Feature Requests**: Have an idea? We'd love to hear it!
3. **Pull Requests**: Ready to contribute code? Please read our contributing guidelines
4. **Documentation**: Help improve our docs and examples

### Development Setup

```bash
# Clone the repository
git clone https://github.com/iTechQua/flexible_data_table.git

# Install dependencies
flutter pub get

# Run example app
cd example
flutter run
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 **Email**: support@itechqua.com
- 💬 **Discord**: [Join our community](https://discord.com/channels/854023838136533063/854023838576672839)
- 🐛 **Issues**: [GitHub Issues](https://github.com/iTechQua/flexible_data_table/issues)
- 📖 **Documentation**: [Full Documentation](https://pub.dev/packages/flexible_data_table)

---

<div align="center">

**Made with ❤️ by [iTechQua](https://github.com/iTechQua)**

[⭐ Star this repo](https://github.com/iTechQua/flexible_data_table) • [🍕 Buy me a coffee](https://www.buymeacoffee.com/iTechQua) • [🐦 Follow on Twitter](https://x.com/iTechQua)

</div>