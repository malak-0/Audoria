class FileOptionsModel {
  final String title;
  final String iconPath;
  final bool isReversed;
  final String? routeName;
  const FileOptionsModel({
    this.isReversed = false,
    required this.title,
    required this.iconPath,
    this.routeName,
  });
}
