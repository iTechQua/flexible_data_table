import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart' as excel;

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
  final Color headerColor;
  final double rowHeight;
  final double headerHeight;
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
    this.headerColor = const Color(0xFF6D28D9),
    this.rowHeight = 50,
    this.headerHeight = 50,
    this.pageSize = 10,
    this.actionColumnFlex,
    this.headerTextColor,
    this.rowTextColor,
    this.borderColor,
    this.checkboxColor,
    this.onPageChanged,
    this.totalItems = 0,
    this.isServerSide = false,
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

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();

  Color get _headerText => widget.headerTextColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white);

  Color get _rowText => widget.rowTextColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87);

  Color get _border => widget.borderColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade200);

  Color get _checkboxColor => widget.checkboxColor ??
      (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.white);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredData = List.from(widget.data);
    _pageSize = widget.pageSize;
    _setupScrollControllers();
    _updateEffectiveTotalItems();
  }

  void _updateEffectiveTotalItems() {
    _effectiveTotalItems = widget.isServerSide
        ? widget.totalItems
        : _filteredData.length;
  }

  @override
  void didUpdateWidget(FlexibleDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  }

  // Update _buildTableBody to use pagination based on isServerSide
  Widget _buildTableBody(Map<String, dynamic> headerMap, double tableWidth) {
    if (_filteredData.isEmpty) {
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
                children: [
                  TableRow(
                    children: List.generate(
                      headerMap.length + (widget.showCheckboxColumn ? 2 : 1),
                          (_) => Container(height: 100),
                    ),
                  ),
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

    final startIndex = widget.isServerSide ? 0 : _currentPage * _pageSize;
    final endIndex = widget.isServerSide
        ? _filteredData.length
        : math.min(startIndex + _pageSize, _filteredData.length);

    final pageData = widget.isServerSide
        ? _filteredData
        : _filteredData.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(
              horizontalInside: BorderSide(color: _border),
              verticalInside: BorderSide(color: _border),
            ),
            columnWidths: _buildColumnWidths(headerMap),
            children: pageData.map((item) => _buildTableRow(item, headerMap)).toList(),
          ),
        ),
      ),
    );
  }

  // Update pagination calculations
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

  // Update _filterData to handle server-side vs local filtering
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
        // Calculate last page when clearing search
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

  // Update _changePage to handle server-side vs local pagination
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

        // Handle numeric sorting
        if (aValue is num && bValue is num) {
          final comparison = aValue.compareTo(bValue);
          return ascending ? comparison : -comparison;
        }

        // Handle date sorting
        final aDate = DateTime.tryParse(aValue.toString());
        final bDate = DateTime.tryParse(bValue.toString());
        if (aDate != null && bDate != null) {
          final comparison = aDate.compareTo(bDate);
          return ascending ? comparison : -comparison;
        }

        // Default string sorting
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
      elevation: 0,
      color: isDarkMode ? Colors.grey[850] : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
    final Map<String, dynamic> headerMap = widget.data.isNotEmpty
        ? Map<String, dynamic>.from(widget.toTableDataMap(widget.data.first))
        : {};

    final double totalWidth = _calculateTotalWidth(headerMap);
    final double tableWidth = math.max(totalWidth, widget.minWidth ?? 0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(4),
        color: isDarkMode ? Colors.grey[900] : Colors.white,
      ),
      child: Column(
        children: [
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
                    decoration: BoxDecoration(
                      color: widget.headerColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
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

  TableRow _buildTableRow(T item, Map<String, dynamic> headerMap) {
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
            minHeight: widget.rowHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      );
    }

    cells.add(
      Container(
        constraints: BoxConstraints(
          minHeight: widget.rowHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: widget.actionBuilder(item),
      ),
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      children: cells,
    );
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
            value: widget.selectedItems?.length == widget.data.length,
            onChanged: (value) {
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
      cells.add(Container(
        height: widget.headerHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              key,
              style: GoogleFonts.poppins(
                color: _headerText,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isSort)
              InkWell(
                onTap: () => _handleSort(key, !_sortAscending),
                child: Icon(
                  _sortColumn == key
                      ? _sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward
                      : Icons.sort,
                  color: _headerText,
                  size: 16,
                ),
              ),
          ],
        ),
      ));
    }

    cells.add(Container(
      height: widget.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Text(
          widget.actionColumnName ?? 'Actions',
          style: GoogleFonts.poppins(
            color: _headerText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ));

    return cells;
  }

// Update _buildColumnWidths method
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

    // Add action column width
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
        // For flex columns, provide a minimum width
        totalWidth += 100;
      } else {
        totalWidth += 150;
      }
    }

    totalWidth += 100; // Actions column
    return totalWidth;
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _buildPageSizeDropdown(),
        const SizedBox(width: 16),
        _buildExportButton(),
        const Spacer(),
        _buildSearchField(),
      ],
    );
  }

  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: widget.headerColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Export',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'excel',
          child: Text('Export to Excel', style: GoogleFonts.poppins()),
          onTap: _exportToExcel,
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Text('Export to PDF', style: GoogleFonts.poppins()),
          onTap: _exportToPdf,
        ),
      ],
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
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<int>(
            value: _pageSize,
            items: [5, 10, 25, 50, 100].map((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value', style: GoogleFonts.poppins()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _pageSize = value;
                  _currentPage = 0;
                });
                widget.onPageChanged?.call(1, value);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final workbook = excel.Excel.createExcel();
      final sheet = workbook.sheets[workbook.getDefaultSheet() ?? 'Sheet1'];
      if (sheet == null) throw Exception('Failed to create sheet');

      // Set column widths
      for (var i = 0; i < widget.toTableDataMap(_filteredData.first).length + 1; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      // Add headers with merged cells for better visibility
      final headerMap = widget.toTableDataMap(_filteredData.first);
      var columnIndex = 0;

      // Add S.No header
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

      // Add other headers
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

      // Add data with alternating row colors
      for (var i = 0; i < _filteredData.length; i++) {
        columnIndex = 0;
        final rowColor = i % 2 == 0 ? '#F3F4F6' : '#FFFFFF';

        // Add S.No
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

        // Add row data
        final rowData = widget.toTableDataMap(_filteredData[i]);
        for (final value in rowData.values) {
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

      // Auto-fit columns
      sheet.setDefaultColumnWidth(15.0);

      final excelData = workbook.encode();
      if (excelData == null) throw Exception('Failed to save Excel file');

      await _saveFile(excelData, '${widget.fileName}.xlsx');
    } catch (e) {
      _showErrorDialog('Export Error', e.toString());
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final pdf = pw.Document();
      final headerMap = widget.toTableDataMap(_filteredData.first);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.TableHelper.fromTextArray(
              headers: ['S.No', ...headerMap.keys.toList()],
              data: _filteredData.asMap().entries.map((entry) {
                final map = widget.toTableDataMap(entry.value);
                return [
                  (entry.key + 1).toString(),
                  ...map.values.map((e) => e?.toString() ?? '').toList()
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
    } catch (e) {
      _showErrorDialog('PDF Export Error', e.toString());
    }
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
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);

        if (mounted) {
          _showSuccessDialog('File saved successfully!', {
            'Location': file.path,
            'Size': '${(bytes.length / 1024).toStringAsFixed(2)} KB',
            'Type': fileName.split('.').last.toUpperCase(),
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error Saving File', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.black87,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: widget.headerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, Map<String, String> details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}:',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: GoogleFonts.poppins(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: widget.headerColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

  /// set parent widget in center
  Widget center({double? heightFactor, double? widthFactor}) {
    return Center(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: this,
    );
  }

  /// Circular Progressbar
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

/// returns Radius
BorderRadius radius([double? radius]) {
  return BorderRadius.all(radiusCircular(radius ?? 8));
}

/// returns Radius
Radius radiusCircular([double? radius]) {
  return Radius.circular(radius ?? 8);
}

extension WidgetExtension on Widget? {

  /// set parent widget in center
  Widget center({double? heightFactor, double? widthFactor}) {
    return Center(
      heightFactor: heightFactor,
      widthFactor: widthFactor,
      child: this,
    );
  }

  /// set visibility
  Widget visible(bool visible, {Widget? defaultWidget}) {
    return visible ? this! : (defaultWidget ?? SizedBox());
  }
}

extension BooleanExtensions on bool? {
  /// Validate given bool is not null and returns given value if null.
  bool validate({bool value = false}) => this ?? value;
}
