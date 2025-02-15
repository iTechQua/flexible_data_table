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

# Server Side Data Table

The **Flexible Data Table** is a powerful and flexible tool for displaying large datasets in a web application. It supports dynamic table creation with features like filtering, sorting, pagination, and search functionality. The table is customizable, allowing you to define columns, actions, and layouts, all while providing a responsive design to ensure smooth integration into any web application.

This package also supports server-side datatables, which can significantly enhance performance when dealing with large datasets by offloading data processing to the server.


## Features

- **Dynamic Table Creation**: Create tables dynamically on the web.
- **Custom Column Configurations**: Customize column names, sizes, and data mapping.
- **Search Functionality**: Allows users to search and filter the data.
- **Server-Side Datatable**: Efficiently handles large datasets by processing them server-side.
- **Sorting & Pagination**: Easily sort data and paginate through large sets of records.
- **Responsive Design**: Ensures smooth integration across different screen sizes.
- **Custom Actions**: Add custom actions for each row, such as editing or deleting data.
- **Flexible Data Mapping**: Allows transforming data into different formats using custom mappings.

## Installation

Add this package to `pubspec.yaml` as follows:

```console
$ flutter pub add flexible_data_table
```

Import package

```dart
import 'package:flexible_data_table/flexible_data_table.dart';
```


```yaml
dependencies:
  flexible_data_table: ^1.0.0
```


## Example Usage
Here’s an example of how to use the Flexible Data Table in your Flutter project:
![Example](https://raw.githubusercontent.com/iTechQua/flexible_data_table/main/example/assets/server_side_datatable.png)
```dart
SizedBox(
  height: 550,
  child: ServerSideDataTable<UserModel>(
    heading: _heading(isDark, primaryColor),
    isServerSide: false,
    data: users,
    fileName: 'User List',
    toTableDataMap: (UserModel user) => user.toTableDataMap(),
    cellBuilders: {
      'Status': (value, UserModel user) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: user.isActive ? Colors.green : Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              user.isActive ? Icons.check_circle : Icons.cancel_outlined,
              size: 16,
              color: user.isActive ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              value.toString(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: user.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      'Created At': (value, UserModel user) => Text(
        DateFormat('dd MMM yyyy, hh:mm a').format(user.registrationDate),
        style: GoogleFonts.poppins(fontSize: 13),
      ),
    },
    columnSizes: {
      'ID': 60,
      'Name': 150.0,
      'Mobile Number': 150.0,
      'Email': 200.0,
      'Status': 120.0,
      'Created At': 180.0,
    },
    // Optional: Use columnFlex instead of columnSizes for flexible widths
    // columnFlex: {
    //   'ID': 1,
    //   'Name': 2,
    //   'Mobile Number': 2,
    //   'Email': 3,
    //   'Status': 1,
    //   'Created At': 2,
    // },
    actionBuilder: (UserModel user) => SizedBox(
      width: 120,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.edit,
            color: Colors.deepPurple,
            tooltip: 'Edit User',
            onPressed: () => onEdit(user),
          ),
          _buildActionButton(
            icon: user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
            color: user.isActive ? Colors.red : Colors.green,
            tooltip: user.isActive ? 'Deactivate User' : 'Activate User',
            onPressed: () => user.id != getIntAsync(apiUserId) ? onToggleStatus(user) : null,
          ),
        ],
      ),
    ),
    customHeaderBuilders: {
      'Status': (columnName) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.toggle_on_outlined,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              columnName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    },
    minWidth: 1170,
    headerColor: const Color(0xFF6D28D9),
    rowHeight: 30,
    headerHeight: 40,
    actionColumnWidth: 100,
    actionColumnName: 'Actions',
    loader: CustomAppStackLoader(visible: true),
  ),
)
```
### Widgets Used in Example

`_heading`

```dart
Widget _heading(bool isDark, Color primaryColor) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Text(
          'All Users',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AppButton(
            color: primaryColor,
            onTap: onAddUser,
            child: Text(
              'Add New user',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );
}

```

`_buildActionButton`

```dart
Widget _buildActionButton({
  required IconData icon,
  required Color color,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return IconButton(
    icon: Icon(icon, size: 20, color: color),
    tooltip: tooltip,
    onPressed: onPressed,
    constraints: const BoxConstraints(
      minWidth: 40,
      minHeight: 40,
    ),
    padding: EdgeInsets.zero,
  );
}

```

## Contributing
If you would like to contribute to this project, feel free to fork it and submit pull requests. Any contributions, issues, or feedback are welcome!