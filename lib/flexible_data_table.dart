import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' as excel;

// Enum for different table types
enum FlexibleDataTableType {
  standard,     // Default clean style (no borders)
  bordered,     // Full borders around all cells
  striped,      // Alternating row colors
  card,         // Each row as a card
  compact,      // Reduced padding and spacing
  modern,       // Premium look with gradients and shadows
  minimal       // Ultra-minimal with only bottom lines
}

class FlexibleDataTable<T> extends StatefulWidget {
  final List<T> data;
  final String fileName;
  final Map<String, dynamic> Function(T) toTableDataMap;
  final Map<String, Widget Function(dynamic value, T rowData)>? cellBuilders;
  final Map<String, double>? columnSizes;
  final Map<String, int>? columnFlex;
  final Widget Function(T) actionBuilder;
  final bool isSort;
  final bool showCheckboxColumn;
  final bool isLoading;
  final List<T>? selectedItems;
  final Widget? heading;
  final Widget? loader;
  final Function(bool?, T)? onSelectItem;
  final Map<String, Widget Function(String columnName)>? customHeaderBuilders;
  final double? minWidth;
  final Color primaryColor;
  final Color headerColor;
  final Color? cardColor;
  final double rowHeight;
  final double headerHeight;
  final double headerFontSize;
  final String? actionColumnName;
  final double? actionColumnWidth;
  final int? actionColumnFlex;
  final Color? headerTextColor;
  final Color? rowTextColor;
  final Color? borderColor;
  final Color? checkboxColor;
  final int pageSize;
  final Function(int page, int pageSize)? onPageChanged;
  final int totalItems;
  final bool isServerSide;
  final Map<String, dynamic>? headers;

  // New table type functionality
  final FlexibleDataTableType tableType;
  final Color? stripedRowColor;
  final double? cardElevation;
  final double? cardMargin;
  final BorderRadius? cardBorderRadius;
  final Color? cardShadowColor;
  final bool showTableTypeSelector;

  const FlexibleDataTable({
    super.key,
    required this.data,
    required this.fileName,
    required this.toTableDataMap,
    required this.actionBuilder,
    this.cellBuilders,
    this.columnSizes,
    this.columnFlex,
    this.isSort = true,
    this.showCheckboxColumn = false,
    this.isLoading = false,
    this.actionColumnName,
    this.actionColumnWidth = 200,
    this.selectedItems,
    this.onSelectItem,
    this.customHeaderBuilders,
    this.minWidth,
    this.heading,
    this.loader,
    this.primaryColor = const Color(0xFF6D28D9),
    this.headerColor = const Color(0xFFF6F8FF),
    this.cardColor,
    this.rowHeight = 50,
    this.headerHeight = 50,
    this.headerFontSize = 12,
    this.pageSize = 10,
    this.actionColumnFlex,
    this.headerTextColor,
    this.rowTextColor,
    this.borderColor,
    this.checkboxColor,
    this.onPageChanged,
    this.totalItems = 0,
    this.isServerSide = false,
    this.headers,

    // New table type parameters
    this.tableType = FlexibleDataTableType.standard,
    this.stripedRowColor,
    this.cardElevation,
    this.cardMargin,
    this.cardBorderRadius,
    this.cardShadowColor,
    this.showTableTypeSelector = false,
  });

  @override
  FlexibleDataTableState<T> createState() => FlexibleDataTableState<T>();
}

class FlexibleDataTableState<T> extends State<FlexibleDataTable<T>> {
  late List<T> _filteredData;
  late TextEditingController _searchController;
  String? _sortColumn;
  bool _sortAscending = true;
  int _currentPage = 0;
  int _pageSize = 10;
  String _searchQuery = '';
  late int _effectiveTotalItems;
  late FlexibleDataTableType _currentTableType;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();

  Map<String, dynamic>? _defaultHeaderMap;

  Color get _headerText => widget.headerTextColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);

  Color get _rowText => widget.rowTextColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);

  Color get _border => widget.borderColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade200);

  Color get _checkboxColor => widget.checkboxColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.white);

  Color get _stripedColor => widget.stripedRowColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade50);

  Future<bool> checkPermissions() async {
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.mediaLibrary,
      Permission.accessMediaLocation,
      Permission.photos,
      Permission.camera,
    ].request();

    if ((statuses[Permission.manageExternalStorage]!.isPermanentlyDenied ||
        statuses[Permission.storage]!.isPermanentlyDenied ||
        statuses[Permission.mediaLibrary]!.isPermanentlyDenied ||
        statuses[Permission.accessMediaLocation]!.isPermanentlyDenied ||
        statuses[Permission.photos]!.isPermanentlyDenied ||
        statuses[Permission.camera]!.isPermanentlyDenied) &&
        Platform.isAndroid) {
      openAppSettings();
    }
    return statuses.values.every((status) => status.isGranted);
  }

  void _updateDefaultHeaderMap() {
    if (widget.headers != null && widget.headers!.isNotEmpty) {
      _defaultHeaderMap = Map<String, dynamic>.from(widget.headers!);
      return;
    }

    if (_defaultHeaderMap == null || _defaultHeaderMap!.isEmpty) {
      if (widget.data.isNotEmpty) {
        _defaultHeaderMap = Map<String, dynamic>.from(widget.toTableDataMap(widget.data.first));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredData = List.from(widget.data);
    _pageSize = widget.pageSize;
    _currentTableType = widget.tableType;
    _setupScrollControllers();
    _updateEffectiveTotalItems();
    _updateDefaultHeaderMap();
  }

  void _updateEffectiveTotalItems() {
    _effectiveTotalItems = widget.isServerSide
        ? widget.totalItems
        : _filteredData.length;
  }

  @override
  void didUpdateWidget(FlexibleDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateDefaultHeaderMap();

    if (oldWidget.data != widget.data) {
      setState(() {
        if (_searchQuery.isNotEmpty) {
          _filteredData = widget.data.where((item) {
            final map = widget.toTableDataMap(item);
            return map.values.any(
                  (value) => value?.toString().toLowerCase().contains(_searchQuery) ?? false,
            );
          }).toList();
        } else {
          _filteredData = List.from(widget.data);
        }
        _updateEffectiveTotalItems();
      });
    }

    if (oldWidget.tableType != widget.tableType) {
      setState(() {
        _currentTableType = widget.tableType;
      });
    }
  }

  // Get table-specific styling based on table type
  TableBorder? _getTableBorder() {
    switch (_currentTableType) {
      case FlexibleDataTableType.bordered:
        return TableBorder.all(color: _border, width: 1);
      case FlexibleDataTableType.card:
      case FlexibleDataTableType.standard:
        return null; // No borders for these types
      case FlexibleDataTableType.minimal:
        return null; // Minimal uses only row bottom borders
      case FlexibleDataTableType.modern:
        return TableBorder(
          horizontalInside: BorderSide(color: _border.withValues(alpha: 0.1), width: 1),
        );
      case FlexibleDataTableType.striped:
      case FlexibleDataTableType.compact:
        return TableBorder(
          horizontalInside: BorderSide(color: _border.withValues(alpha: 0.5)),
        );
      default:
        return null;
    }
  }

  EdgeInsets _getCellPadding() {
    switch (_currentTableType) {
      case FlexibleDataTableType.compact:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case FlexibleDataTableType.card:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double _getRowHeight() {
    switch (_currentTableType) {
      case FlexibleDataTableType.compact:
        return widget.rowHeight * 0.8;
      case FlexibleDataTableType.card:
        return widget.rowHeight * 1.2;
      default:
        return widget.rowHeight;
    }
  }

  Color? _getRowColor(int index, bool isDarkMode) {
    switch (_currentTableType) {
      case FlexibleDataTableType.striped:
        return index % 2 == 0
            ? (isDarkMode ? Colors.grey[850] : Colors.white)
            : _stripedColor;
      case FlexibleDataTableType.card:
        return null; // Cards handle their own color
      case FlexibleDataTableType.minimal:
        return Colors.transparent; // Minimal uses transparent rows
      case FlexibleDataTableType.standard:
        return isDarkMode ? Colors.grey[900] : Colors.white;
      case FlexibleDataTableType.modern:
      // Modern: Subtle gradient-like alternating colors
        return index % 2 == 0
            ? (isDarkMode ? Colors.grey[850]!.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.9))
            : (isDarkMode ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.grey.shade50.withValues(alpha: 0.8));
      case FlexibleDataTableType.compact:
        return isDarkMode ? Colors.grey[850] : Colors.white;
      case FlexibleDataTableType.bordered:
        return isDarkMode ? Colors.grey[850] : Colors.white;
      default:
        return isDarkMode ? Colors.grey[850] : Colors.white;
    }
  }

  Widget _buildTableBody(Map<String, dynamic> headerMap, double tableWidth) {
    if (_filteredData.isEmpty) {
      return _buildEmptyState(headerMap, tableWidth);
    }

    final startIndex = widget.isServerSide ? 0 : _currentPage * _pageSize;
    final endIndex = widget.isServerSide
        ? _filteredData.length
        : math.min(startIndex + _pageSize, _filteredData.length);

    final pageData = widget.isServerSide
        ? _filteredData
        : _filteredData.sublist(startIndex, endIndex);

    if (_currentTableType == FlexibleDataTableType.card) {
      return _buildCardTableBody(pageData, headerMap);
    }

    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: _getTableBorder(),
            columnWidths: _buildColumnWidths(headerMap),
            children: pageData.asMap().entries.map((entry) =>
                _buildTableRow(entry.value, headerMap, entry.key)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Map<String, dynamic> headerMap, double tableWidth) {
    final List<Widget> emptyCells = [];

    if (widget.showCheckboxColumn) {
      emptyCells.add(Container(height: 100));
    }

    for (int i = 0; i < headerMap.length; i++) {
      emptyCells.add(Container(height: 100));
    }

    emptyCells.add(Container(height: 100));

    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: _buildColumnWidths(headerMap),
              border: _getTableBorder(),
              children: [
                TableRow(children: emptyCells),
              ],
            ),
          ),
        ),
        Center(
          child: Text(
            _searchQuery.isEmpty ? 'No data available' : 'No matching records found',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _rowText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTableBody(List<T> pageData, Map<String, dynamic> headerMap) {
    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: Column(
        children: pageData.asMap().entries.map((entry) =>
            _buildCardRow(entry.value, headerMap, entry.key)).toList(),
      ),
    );
  }

  Widget _buildCardRow(T item, Map<String, dynamic> headerMap, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final map = widget.toTableDataMap(item);

    return Container(
      margin: EdgeInsets.all(widget.cardMargin ?? 8),
      child: Card(
        elevation: widget.cardElevation ?? 3,
        shadowColor: widget.cardShadowColor ?? Colors.grey.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: widget.cardBorderRadius ?? BorderRadius.circular(12),
        ),
        color: widget.cardColor ?? (isDarkMode ? Colors.grey[850] : Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card header with index
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Checkbox row if enabled
              if (widget.showCheckboxColumn) ...[
                Row(
                  children: [
                    Checkbox(
                      value: widget.selectedItems?.contains(item) ?? false,
                      onChanged: (value) => widget.onSelectItem?.call(value, item),
                    ),
                    Text(
                      'Select Item',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _rowText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Data rows
              ...headerMap.keys.map((key) {
                final value = map[key];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '$key:',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _rowText.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: widget.cellBuilders?.containsKey(key) ?? false
                            ? widget.cellBuilders![key]!(value, item)
                            : Text(
                          value?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: _rowText,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Actions row
              ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: _border.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  widget.actionBuilder(item),
                ],
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = (_effectiveTotalItems / _pageSize).ceil();
    final startEntry = _currentPage * _pageSize + 1;
    final endEntry = math.min((_currentPage + 1) * _pageSize, _effectiveTotalItems);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startEntry to $endEntry of $_effectiveTotalItems entries',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 0 ? () => _changePage(0) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0 ? () => _changePage(_currentPage - 1) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Page ${_currentPage + 1} of $totalPages',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1 ? () => _changePage(_currentPage + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages - 1 ? () => _changePage(totalPages - 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _filterData(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredData = widget.data.where((item) {
        final map = widget.toTableDataMap(item);
        return map.values.any(
              (value) => value?.toString().toLowerCase().contains(_searchQuery) ?? false,
        );
      }).toList();

      if (_searchQuery.isNotEmpty) {
        _currentPage = 0;
      } else {
        int totalPages = (widget.isServerSide ? widget.totalItems : widget.data.length) ~/ _pageSize;
        if ((widget.isServerSide ? widget.totalItems : widget.data.length) % _pageSize != 0) {
          totalPages += 1;
        }
        _currentPage = totalPages - 1;
      }

      _updateEffectiveTotalItems();

      if (widget.isServerSide) {
        widget.onPageChanged?.call(_currentPage + 1, _pageSize);
      }
    });
  }

  void _changePage(int page) {
    setState(() => _currentPage = page);

    if (widget.isServerSide) {
      widget.onPageChanged?.call(page + 1, _pageSize);
    }
  }

  void _handleSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;

      _filteredData.sort((a, b) {
        final aValue = widget.toTableDataMap(a)[column];
        final bValue = widget.toTableDataMap(b)[column];

        if (aValue == null || bValue == null) return 0;

        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return ascending ? comparison : -comparison;
        }

        final aDate = DateTime.tryParse(aValue.toString());
        final bDate = DateTime.tryParse(bValue.toString());
        if (aDate != null && bDate != null) {
          final comparison = aDate.compareTo(bDate);
          return ascending ? comparison : -comparison;
        }

        final comparison = aValue.toString().compareTo(bValue.toString());
        return ascending ? comparison : -comparison;
      });
    });
  }

  void _setupScrollControllers() {
    _horizontalScrollController.addListener(() {
      if (_headerScrollController.position.pixels != _horizontalScrollController.position.pixels) {
        _headerScrollController.jumpTo(_horizontalScrollController.position.pixels);
      }
    });

    _headerScrollController.addListener(() {
      if (_horizontalScrollController.position.pixels != _headerScrollController.position.pixels) {
        _horizontalScrollController.jumpTo(_headerScrollController.position.pixels);
      }
    });
  }

  String? _getValidationError() {
    if (!widget.isServerSide) return null;

    if (widget.onPageChanged == null) {
      return 'onPageChanged callback is required when isServerSide is true';
    }
    return null;
  }

  Widget _buildErrorDisplay(String message) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Configuration Error',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validationError = _getValidationError();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: _currentTableType == FlexibleDataTableType.modern ? 4 : 0,
      shadowColor: _currentTableType == FlexibleDataTableType.modern ? widget.cardShadowColor : null,
      color: widget.cardColor ?? (isDarkMode ? Colors.grey[850] : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_currentTableType == FlexibleDataTableType.modern ? 16.0 : 16.0),
        side: BorderSide(
            color: _currentTableType == FlexibleDataTableType.standard
                ? Colors.transparent
                : (isDarkMode ? Colors.grey[700]! : Colors.grey.shade200)
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(_currentTableType == FlexibleDataTableType.compact ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.heading != null) ...[widget.heading!, SizedBox(height: 16)],
            if (validationError != null)
              Expanded(child: Center(child: _buildErrorDisplay(validationError)))
            else ...[
              _buildTopBar(),
              const SizedBox(height: 16),
              Expanded(child: AppStackLoader(visible: widget.isLoading, loader: widget.loader, child: _buildTable())),
              if (_filteredData.isNotEmpty) _buildPagination(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Map<String, dynamic> headerMap;

    if (widget.headers != null && widget.headers!.isNotEmpty) {
      headerMap = Map<String, dynamic>.from(widget.headers!);
    }
    else if (widget.data.isNotEmpty) {
      headerMap = Map<String, dynamic>.from(widget.toTableDataMap(widget.data.first));
    }
    else if (_defaultHeaderMap != null && _defaultHeaderMap!.isNotEmpty) {
      headerMap = _defaultHeaderMap!;
    }
    else if (widget.customHeaderBuilders != null && widget.customHeaderBuilders!.isNotEmpty) {
      headerMap = Map<String, dynamic>.fromIterable(
          widget.customHeaderBuilders!.keys,
          value: (_) => null
      );
    }
    else {
      headerMap = {'ID': null, 'Name': null, 'Description': null};
    }

    final double totalColumnWidth = _calculateTotalWidth(headerMap);

    return LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final double requestedMinWidth = widget.minWidth ?? 0;

          final double tableWidth = math.max(
              totalColumnWidth,
              math.max(availableWidth, requestedMinWidth)
          );

          // For card layout, don't show traditional table headers
          if (_currentTableType == FlexibleDataTableType.card) {
            return Container(
              decoration: _getContainerDecoration(isDarkMode),
              child: _buildTableBody(headerMap, tableWidth),
            );
          }

          return Container(
            decoration: _getContainerDecoration(isDarkMode),
            child: Column(
              children: [
                // Headers
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _headerScrollController,
                  child: SizedBox(
                    width: tableWidth,
                    height: widget.headerHeight,
                    child: Table(
                      columnWidths: _buildColumnWidths(headerMap),
                      children: [
                        TableRow(
                          decoration: _getHeaderDecoration(),
                          children: _buildHeaderCells(headerMap).map((cell) =>
                              SizedBox(height: widget.headerHeight, child: cell)
                          ).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildTableBody(headerMap, tableWidth),
                ),
              ],
            ),
          );
        }
    );
  }

  BoxDecoration _getContainerDecoration(bool isDarkMode) {
    switch (_currentTableType) {
      case FlexibleDataTableType.standard:
      // Standard type - no borders, clean look
        return BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
      case FlexibleDataTableType.bordered:
        return BoxDecoration(
          border: Border.all(color: _border, width: 1),
          borderRadius: BorderRadius.circular(4),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
      case FlexibleDataTableType.modern:
      // Modern: Premium look with gradients, shadows, and rounded corners
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode ? Colors.grey[850]! : Colors.white,
              isDarkMode ? Colors.grey[900]! : Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        );
      case FlexibleDataTableType.minimal:
      // Minimal: Ultra-clean with transparent background
        return BoxDecoration(
          color: Colors.transparent,
        );
      case FlexibleDataTableType.striped:
        return BoxDecoration(
          border: Border.all(color: _border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
      case FlexibleDataTableType.compact:
        return BoxDecoration(
          border: Border.all(color: _border.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(2),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
      case FlexibleDataTableType.card:
        return BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
      default:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        );
    }
  }

  BoxDecoration _getHeaderDecoration() {
    switch (_currentTableType) {
      case FlexibleDataTableType.standard:
        return BoxDecoration(
          color: widget.headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        );
      case FlexibleDataTableType.modern:
      // Modern: Premium header with gradient and shadow
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.primaryColor.withValues(alpha: 0.9),
              widget.primaryColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        );
      case FlexibleDataTableType.minimal:
      // Minimal: No background, just transparent
        return BoxDecoration(
          color: Colors.transparent,
        );
      case FlexibleDataTableType.striped:
        return BoxDecoration(
          color: widget.headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        );
      case FlexibleDataTableType.compact:
        return BoxDecoration(
          color: widget.headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
        );
      case FlexibleDataTableType.bordered:
        return BoxDecoration(
          color: widget.headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        );
      default:
        return BoxDecoration(
          color: widget.headerColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        );
    }
  }

  TableRow _buildTableRow(T item, Map<String, dynamic> headerMap, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cells = <Widget>[];

    if (widget.showCheckboxColumn) {
      cells.add(
        SizedBox(
          width: 50,
          child: Checkbox(
            value: widget.selectedItems?.contains(item) ?? false,
            onChanged: (value) => widget.onSelectItem?.call(value, item),
          ),
        ),
      );
    }

    final map = widget.toTableDataMap(item);
    for (final key in headerMap.keys) {
      final value = map[key];
      cells.add(
        Container(
          constraints: BoxConstraints(
            minHeight: _getRowHeight(),
          ),
          padding: _getCellPadding(),
          child: widget.cellBuilders?.containsKey(key) ?? false
              ? widget.cellBuilders![key]!(value, item)
              : Text(
            value?.toString() ?? '',
            style: GoogleFonts.poppins(
              fontSize: _currentTableType == FlexibleDataTableType.compact ? 12 : 13,
              color: _rowText,
            ),
          ),
        ),
      );
    }

    cells.add(
      Container(
        constraints: BoxConstraints(
          minHeight: _getRowHeight(),
        ),
        padding: _getCellPadding(),
        child: widget.actionBuilder(item),
      ),
    );

    return TableRow(
      decoration: BoxDecoration(
        color: _getRowColor(index, isDarkMode),
        border: _getRowBorder(),
      ),
      children: cells,
    );
  }

  Border? _getRowBorder() {
    switch (_currentTableType) {
      case FlexibleDataTableType.standard:
      case FlexibleDataTableType.card:
        return null; // No borders for these types
      case FlexibleDataTableType.minimal:
      // Minimal: Only subtle bottom lines
        return Border(
          bottom: BorderSide(
            color: _border.withValues(alpha: 0.1),
            width: 1,
          ),
        );
      case FlexibleDataTableType.modern:
      // Modern: Very subtle borders with glow effect
        return Border(
          bottom: BorderSide(
            color: widget.primaryColor.withValues(alpha: 0.1),
            width: 2,
          ),
        );
      case FlexibleDataTableType.striped:
      case FlexibleDataTableType.compact:
        return Border(
          bottom: BorderSide(
            color: _border.withValues(alpha: 0.3),
            width: 0.5,
          ),
        );
      case FlexibleDataTableType.bordered:
        return null; // Handled by table border
      default:
        return null;
    }
  }

  List<Widget> _buildHeaderCells(Map<String, dynamic> headerMap) {
    final cells = <Widget>[];

    if (widget.showCheckboxColumn) {
      cells.add(Container(
        height: widget.headerHeight,
        alignment: Alignment.center,
        child: Theme(
          data: ThemeData(
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.all(_checkboxColor),
            ),
          ),
          child: Checkbox(
            value: widget.selectedItems?.length == widget.data.length && widget.data.isNotEmpty,
            onChanged: widget.data.isEmpty ? null : (value) {
              if (value == true) {
                for (var item in widget.data) {
                  widget.onSelectItem?.call(true, item);
                }
              } else {
                for (var item in widget.data) {
                  widget.onSelectItem?.call(false, item);
                }
              }
            },
          ),
        ),
      ));
    }

    for (final key in headerMap.keys) {
      if (widget.customHeaderBuilders?.containsKey(key) ?? false) {
        cells.add(Container(
          height: widget.headerHeight,
          padding: EdgeInsets.symmetric(horizontal: _currentTableType == FlexibleDataTableType.compact ? 8 : 16),
          child: widget.customHeaderBuilders![key]!(key),
        ));
      } else {
        // Determine header text color based on table type
        Color headerTextColor = _currentTableType == FlexibleDataTableType.modern
            ? Colors.white  // White text for modern gradient header
            : (_currentTableType == FlexibleDataTableType.minimal
            ? _headerText.withValues(alpha: 0.8)  // Subtle text for minimal
            : _headerText);

        cells.add(Container(
          height: widget.headerHeight,
          padding: EdgeInsets.symmetric(horizontal: _currentTableType == FlexibleDataTableType.compact ? 8 : 16),
          child: Row(
            children: [
              Text(
                key,
                style: GoogleFonts.poppins(
                    color: headerTextColor,
                    fontWeight: _currentTableType == FlexibleDataTableType.modern
                        ? FontWeight.w600
                        : (_currentTableType == FlexibleDataTableType.minimal
                        ? FontWeight.w400
                        : FontWeight.w500),
                    fontSize: _currentTableType == FlexibleDataTableType.compact
                        ? widget.headerFontSize - 1
                        : widget.headerFontSize
                ),
              ),
              if (widget.isSort && widget.data.isNotEmpty)
                InkWell(
                  onTap: () => _handleSort(key, !_sortAscending),
                  child: Icon(
                    _sortColumn == key
                        ? _sortAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward
                        : Icons.sort,
                    color: headerTextColor,
                    size: _currentTableType == FlexibleDataTableType.compact
                        ? widget.headerFontSize - 1
                        : widget.headerFontSize,
                  ),
                ),
            ],
          ),
        ));
      }
    }

    // Action column header
    Color actionHeaderTextColor = _currentTableType == FlexibleDataTableType.modern
        ? Colors.white
        : (_currentTableType == FlexibleDataTableType.minimal
        ? _headerText.withValues(alpha: 0.8)
        : _headerText);

    cells.add(Container(
      height: widget.headerHeight,
      padding: EdgeInsets.symmetric(horizontal: _currentTableType == FlexibleDataTableType.compact ? 8 : 14),
      child: Center(
        child: Text(
          widget.actionColumnName ?? 'Actions',
          style: GoogleFonts.poppins(
              color: actionHeaderTextColor,
              fontWeight: _currentTableType == FlexibleDataTableType.modern
                  ? FontWeight.w600
                  : (_currentTableType == FlexibleDataTableType.minimal
                  ? FontWeight.w400
                  : FontWeight.w500),
              fontSize: _currentTableType == FlexibleDataTableType.compact
                  ? widget.headerFontSize - 1
                  : widget.headerFontSize
          ),
        ),
      ),
    ));

    return cells;
  }

  Map<int, TableColumnWidth> _buildColumnWidths(Map<String, dynamic> headerMap) {
    final widths = <int, TableColumnWidth>{};
    var index = 0;

    if (widget.showCheckboxColumn) {
      widths[index++] = const FixedColumnWidth(50);
    }

    for (final key in headerMap.keys) {
      if (widget.columnFlex?.containsKey(key) ?? false) {
        widths[index] = FlexColumnWidth(widget.columnFlex![key]!.toDouble());
      } else if (widget.columnSizes?.containsKey(key) ?? false) {
        widths[index] = FixedColumnWidth(widget.columnSizes![key]!);
      } else {
        widths[index] = const FlexColumnWidth();
      }
      index++;
    }

    if (widget.actionColumnFlex != null) {
      widths[index] = FlexColumnWidth(widget.actionColumnFlex!.toDouble());
    } else {
      widths[index] = FixedColumnWidth(widget.actionColumnWidth ?? 100);
    }

    return widths;
  }

  double _calculateTotalWidth(Map<String, dynamic> headerMap) {
    double totalWidth = 0;

    if (widget.showCheckboxColumn) {
      totalWidth += 50;
    }

    for (final key in headerMap.keys) {
      if (widget.columnSizes?.containsKey(key) ?? false) {
        totalWidth += widget.columnSizes![key]!;
      } else if (widget.columnFlex?.containsKey(key) ?? false) {
        totalWidth += 100;
      } else {
        totalWidth += 150;
      }
    }

    totalWidth += (widget.actionColumnWidth ?? 100);

    return totalWidth;
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildPageSizeDropdown(),
        const SizedBox(width: 16),
        _buildExportButton(),
        if (widget.showTableTypeSelector) ...[
          const SizedBox(width: 16),
          _buildTableTypeSelector(),
        ],
        const Spacer(),
        _buildSearchField(),
      ],
    );
  }

  Widget _buildTableTypeSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 40,
              color: widget.primaryColor,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 2),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<FlexibleDataTableType>(
                  value: _currentTableType,
                  isDense: true,
                  icon: Icon(
                    Icons.table_chart,
                    color: widget.primaryColor,
                    size: 16,
                  ),
                  items: FlexibleDataTableType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getTableTypeDisplayName(type),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (FlexibleDataTableType? value) {
                    if (value != null) {
                      setState(() {
                        _currentTableType = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTableTypeDisplayName(FlexibleDataTableType type) {
    switch (type) {
      case FlexibleDataTableType.standard:
        return 'Standard';
      case FlexibleDataTableType.bordered:
        return 'Bordered';
      case FlexibleDataTableType.striped:
        return 'Striped';
      case FlexibleDataTableType.card:
        return 'Card';
      case FlexibleDataTableType.compact:
        return 'Compact';
      case FlexibleDataTableType.modern:
        return 'Modern';
      case FlexibleDataTableType.minimal:
        return 'Minimal';
    }
  }

  Widget _buildExportButton() {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        offset: const Offset(-4, 38),
        icon: null,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.white,
        tooltip: 'Export options',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.9),
                widget.primaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 4),
              Text(
                'Export',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            height: 36,
            value: 'excel',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: _exportToExcel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.table_chart_rounded,
                    color: Colors.green.shade700,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Excel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            height: 36,
            value: 'pdf',
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            onTap: _exportToPdf,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.red.shade700,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PDF',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 250,
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: _filterData,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildPageSizeDropdown() {
    const int allItemsValue = -1;
    final List<dynamic> pageSizes = [5, 10, 25, 50, 100, allItemsValue];

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final borderColor = isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300;
    final textColor = isDarkMode ? Colors.white : Colors.grey.shade800;
    final labelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    const double dropdownWidth = 80;

    return Container(
      height: 40,
      width: dropdownWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Material(
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 40,
                color: widget.primaryColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 2),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      isExpanded: true,
                      value: _pageSize == widget.totalItems ? allItemsValue : _pageSize,
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: widget.primaryColor,
                        size: 20,
                      ),
                      iconSize: 20,
                      underline: Container(),
                      selectedItemBuilder: (context) {
                        return pageSizes.map<Widget>((dynamic value) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value == allItemsValue ? "All" : "$value",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList();
                      },
                      elevation: 4,
                      dropdownColor: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 13,
                      ),
                      alignment: AlignmentDirectional.centerStart,
                      menuMaxHeight: 305,
                      items: pageSizes.map((dynamic value) {
                        bool isSelected = _pageSize == value;
                        return DropdownMenuItem<dynamic>(
                          value: value,
                          child: IntrinsicHeight(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              constraints: const BoxConstraints(
                                minHeight: 30,
                                maxHeight: 30,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? widget.primaryColor : Colors.transparent,
                                      border: isSelected
                                          ? null
                                          : Border.all(color: labelColor, width: 1),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      value == allItemsValue ? "All" : "$value",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        color: isSelected ? widget.primaryColor : textColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _pageSize = (value == allItemsValue) ? widget.totalItems : value;
                            _currentPage = 0;
                          });
                          widget.onPageChanged?.call(1, _pageSize);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    await _showProgressDialogWithTimeout('Generating Excel file...', () async {
      final workbook = excel.Excel.createExcel();
      final sheet = workbook.sheets[workbook.getDefaultSheet() ?? 'Sheet1'];
      if (sheet == null) throw Exception('Failed to create sheet');

      for (var i = 0; i < widget.toTableDataMap(_filteredData.first).length + 1; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      final headerMap = _getHeaderMap();
      var columnIndex = 0;

      sheet.merge(excel.CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: 0),
          excel.CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: 0));

      final sNoCell = sheet.cell(excel.CellIndex.indexByColumnRow(
        columnIndex: columnIndex,
        rowIndex: 0,
      ));
      sNoCell.value = excel.TextCellValue('S.No');
      sNoCell.cellStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: excel.ExcelColor.fromHexString('#6D28D9'),
        fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: excel.HorizontalAlign.Center,
        verticalAlign: excel.VerticalAlign.Center,
      );
      columnIndex++;

      for (final key in headerMap.keys) {
        sheet.merge(excel.CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: 0),
            excel.CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: 0));

        final cell = sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: 0,
        ));

        cell.value = excel.TextCellValue(key);
        cell.cellStyle = excel.CellStyle(
          bold: true,
          backgroundColorHex: excel.ExcelColor.fromHexString('#6D28D9'),
          fontColorHex: excel.ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: excel.HorizontalAlign.Center,
          verticalAlign: excel.VerticalAlign.Center,
        );
        columnIndex++;
      }

      for (var i = 0; i < _filteredData.length; i++) {
        columnIndex = 0;
        final rowColor = i % 2 == 0 ? '#F3F4F6' : '#FFFFFF';

        final sNoDataCell = sheet.cell(excel.CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: i + 1,
        ));
        sNoDataCell.value = excel.TextCellValue((i + 1).toString());
        sNoDataCell.cellStyle = excel.CellStyle(
          backgroundColorHex: excel.ExcelColor.fromHexString(rowColor),
          horizontalAlign: excel.HorizontalAlign.Center,
        );
        columnIndex++;

        final rowData = widget.toTableDataMap(_filteredData[i]);
        for (final key in headerMap.keys) {
          final value = rowData[key];
          final cellValue = value?.toString() ?? '';
          final cell = sheet.cell(excel.CellIndex.indexByColumnRow(
            columnIndex: columnIndex,
            rowIndex: i + 1,
          ));

          if (cellValue.isNotEmpty && num.tryParse(cellValue) != null) {
            cell.value = excel.IntCellValue(int.parse(cellValue));
            cell.cellStyle = excel.CellStyle(
              backgroundColorHex: excel.ExcelColor.fromHexString(rowColor),
              horizontalAlign: excel.HorizontalAlign.Right,
            );
          } else {
            cell.value = excel.TextCellValue(cellValue);
            cell.cellStyle = excel.CellStyle(
              backgroundColorHex: excel.ExcelColor.fromHexString(rowColor),
              horizontalAlign: excel.HorizontalAlign.Left,
            );
          }
          columnIndex++;
        }
      }

      sheet.setDefaultColumnWidth(15.0);

      final excelData = workbook.encode();
      if (excelData == null) throw Exception('Failed to save Excel file');

      await _saveFile(excelData, '${widget.fileName}.xlsx');
    });
  }

  Map<String, dynamic> _getHeaderMap() {
    if (widget.headers != null && widget.headers!.isNotEmpty) {
      return Map<String, dynamic>.from(widget.headers!);
    }
    else if (widget.data.isNotEmpty) {
      return Map<String, dynamic>.from(widget.toTableDataMap(widget.data.first));
    }
    else if (_defaultHeaderMap != null && _defaultHeaderMap!.isNotEmpty) {
      return _defaultHeaderMap!;
    }
    else if (widget.customHeaderBuilders != null && widget.customHeaderBuilders!.isNotEmpty) {
      return Map<String, dynamic>.fromIterable(
          widget.customHeaderBuilders!.keys,
          value: (_) => null
      );
    }
    else {
      return {'ID': null, 'Name': null, 'Description': null};
    }
  }

  Future<void> _exportToPdf() async {
    await _showProgressDialogWithTimeout('Generating PDF file...', () async {
      final pdf = pw.Document();
      final headerMap = _getHeaderMap();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['S.No', ...headerMap.keys],
              data: _filteredData.asMap().entries.map((entry) {
                final map = widget.toTableDataMap(entry.value);
                return [
                  (entry.key + 1).toString(),
                  ...headerMap.keys.map((key) => map[key]?.toString() ?? '')
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromHex('6D28D9'),
              ),
              headerHeight: 25,
              cellHeight: 20,
              cellAlignments: {
                0: pw.Alignment.center,
              },
            ),
          ],
        ),
      );

      final bytes = await pdf.save();

      await _saveFile(bytes, '${widget.fileName}.pdf');
    });
  }

  Future<void> _showProgressDialogWithTimeout(String message, Future<void> Function() operation) async {
    bool needToDismiss = true;
    bool operationComplete = false;

    if (mounted) {
      _showProgressDialog(message);
    }

    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (needToDismiss && mounted && !operationComplete) {
        print("Operation timeout - forcing dialog dismissal");
        _dismissDialog();
        needToDismiss = false;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export operation continues in the background...'),
              backgroundColor: widget.primaryColor,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });

    try {
      await operation();
      operationComplete = true;

      timeoutTimer.cancel();

      if (needToDismiss && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        _dismissDialog();
        needToDismiss = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File exported successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      operationComplete = true;

      timeoutTimer.cancel();

      if (needToDismiss && mounted) {
        _dismissDialog();
        needToDismiss = false;
      }

      _showErrorDialog('Export Error', e.toString());
    }
  }

  void _dismissDialog() {
    if (!mounted) return;

    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        print("Dismissing dialog with rootNavigator");
        Navigator.of(context, rootNavigator: true).pop();
        return;
      }
    } catch (e) {
      print("Standard Navigator dismissal failed: $e");
    }

    try {
      if (Navigator.of(context).canPop()) {
        print("Dismissing dialog with basic Navigator");
        Navigator.of(context).pop();
        return;
      }
    } catch (e) {
      print("Basic Navigator dismissal failed: $e");
    }

    try {
      if (Navigator.canPop(context)) {
        print("Dismissing dialog with direct pop");
        Navigator.pop(context);
        return;
      }
    } catch (e) {
      print("Direct pop dismissal failed: $e");
    }

    print("Warning: Could not dismiss dialog through normal means");
  }

  bool _isDialogShowing = false;

  void _showProgressDialog(String message) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final GlobalKey<State> dialogKey = GlobalKey<State>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            key: dialogKey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 8,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please wait while we prepare your file...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }

  void _showSuccessDialog(String title, Map<String, String> details) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 8,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: details.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key}:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 8,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade900
            : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_rounded,
                  color: Colors.red.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFile(List<int> bytes, String fileName) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File downloaded: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        try {
          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/$fileName';
          final file = File(filePath);

          await file.writeAsBytes(bytes);

          if (mounted) {
            await Share.shareXFiles(
              [XFile(filePath)],
              subject: 'Exported ${fileName.split('.').last} file',
              text: 'Here is your exported data',
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('File shared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } catch (e) {
          await _saveToDownloads(bytes, fileName);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error Saving File', 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _saveToDownloads(List<int> bytes, String fileName) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            throw Exception('Storage permission not granted');
          }
        }

        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      if (mounted) {
        _showSuccessDialog('File saved successfully!', {
          'Location': filePath,
          'Size': '${(bytes.length / 1024).toStringAsFixed(2)} KB',
          'Type': fileName.split('.').last.toUpperCase(),
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error Saving to Downloads', e.toString());
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }
}

class AppStackLoader extends StatelessWidget {
  final bool visible;
  final Widget child;
  final Widget? loader;

  const AppStackLoader({super.key, required this.visible, required this.child, this.loader});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        (loader ?? hProgress()).center().visible(visible.validate()),
      ],
    );
  }

  Widget center({double? heightFactor, double? widthFactor}) {
    return Center(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: this,
    );
  }

  Widget hProgress({
    Color color = Colors.blue,
  }) {
    return Container(
      alignment: Alignment.center,
      child: Card(
        semanticContainer: true,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        elevation: 4,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(borderRadius: radius(50)),
        child: Container(
          width: 45,
          height: 45,
          padding: const EdgeInsets.all(8.0),
          child: Theme(
            data: ThemeData(
                colorScheme:
                ColorScheme.fromSwatch().copyWith(secondary: color)),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }
}

BorderRadius radius([double? radius]) {
  return BorderRadius.all(radiusCircular(radius ?? 8));
}

Radius radiusCircular([double? radius]) {
  return Radius.circular(radius ?? 8);
}

extension WidgetExtension on Widget? {
  Widget center({double? heightFactor, double? widthFactor}) {
    return Center(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: this,
    );
  }

  Widget visible(bool visible, {Widget? defaultWidget}) {
    return visible ? this! : (defaultWidget ?? SizedBox());
  }
}

extension BooleanExtensions on bool? {
  bool validate({bool value = false}) => this ?? value;
}