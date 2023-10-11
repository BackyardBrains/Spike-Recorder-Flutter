/// Data model for dialogs
class SimpleItem {
  int id;
  String title;
  String subTitle;

  /// used only in multi selection
  bool checked;

  SimpleItem({
    required this.id,
    required this.title,
    this.subTitle = "",
    this.checked = false,
  });

  @override
  bool operator ==(Object other) {
    return (identical(this, other) ||
        (other is SimpleItem &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title));
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString([printFull = false]) {
    return printFull
        ? "SimpleItem(id: $id, title: $title, checked: $checked, subTitle: $subTitle)"
        : title;
  }
}
