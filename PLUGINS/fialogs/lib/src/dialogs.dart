import 'package:fialogs/fialogs.dart';
import 'package:fialogs/src/dialogs/alert_dialog.dart';
import 'package:fialogs/src/dialogs/custom_dialog.dart';
import 'package:fialogs/src/dialogs/multi_selection_dialog.dart';
import 'package:fialogs/src/dialogs/options_dialog.dart';
import 'package:fialogs/src/dialogs/progress_dialog.dart';
import 'package:fialogs/src/dialogs/radio_list_dialog.dart';
import 'package:fialogs/src/dialogs/single_input_dialog.dart';
import 'package:fialogs/src/dialogs/single_selection_dialog.dart';
import 'package:fialogs/src/functions.dart';
import 'package:fialogs/src/props/dialog_text_field.dart';
import 'package:fialogs/src/props/progress_dialog_type.dart';
import 'package:fialogs/src/res/colors.dart';
import 'package:fialogs/src/res/styles.dart';
import 'package:fialogs/src/widgets.dart';
import 'package:flutter/material.dart';

/// customDialog function with [title] and [content] widgets
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
customDialog(
  BuildContext context, {
  required Widget content,
  Widget? title,
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool hideTitleDivider = false,
  bool closeOnBackPress = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: CustomDialog(
        titleWidget: title,
        contentWidget: content,
        icon: titleIcon,
        negativeButtonText: negativeButtonText,
        negativeButtonAction: negativeButtonAction,
        positiveButtonText: positiveButtonText,
        positiveButtonAction: positiveButtonAction,
        neutralButtonText: neutralButtonText,
        neutralButtonAction: neutralButtonAction,
        hideNeutralButton: hideNeutralButton,
        hideTitleDivider: hideTitleDivider,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// progressDialog function with [title] widgets
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
progressDialog(
  BuildContext context, {
  required ProgressDialogType progressDialogType,
  bool displayValue = false,
  bool autoCloseOnCompletion = true,
  Widget? titleWidget,
  Widget? contentWidget,
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = true,
  bool hideTitleDivider = true,
  bool closeOnBackPress = false,
  Color? backgroundColor,
  Animation<Color>? valueColor,
  double? circularStrokeWidth,
  double? linearMinHeight,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: ProgressDialog(
        progressDialogType: progressDialogType,
        displayValue: displayValue,
        autoCloseOnCompletion: autoCloseOnCompletion,
        titleWidget: titleWidget,
        contentWidget: contentWidget,
        icon: titleIcon,
        negativeButtonText: negativeButtonText,
        negativeButtonAction: negativeButtonAction,
        positiveButtonText: positiveButtonText,
        positiveButtonAction: positiveButtonAction,
        neutralButtonText: neutralButtonText,
        neutralButtonAction: neutralButtonAction,
        hideNeutralButton: hideNeutralButton,
        hideTitleDivider: hideTitleDivider,
        backgroundColor: backgroundColor,
        valueColor: valueColor,
        circularStrokeWidth: circularStrokeWidth,
        linearMinHeight: linearMinHeight,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// customAlertDialog function with [title] and [content] widgets
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
customAlertDialog(
  BuildContext context,
  Widget title,
  Widget content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SimpleAlertDialog(
        title,
        content,
        icon: titleIcon,
        negativeButtonText: negativeButtonText,
        negativeButtonAction: negativeButtonAction,
        positiveButtonText: positiveButtonText,
        positiveButtonAction: positiveButtonAction,
        neutralButtonText: neutralButtonText,
        neutralButtonAction: neutralButtonAction,
        hideNeutralButton: hideNeutralButton,
        confirmationDialog: confirmationDialog,
        confirmationMessage: confirmationMessage,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// alert dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
alertDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon,
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// confirmation dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
confirmationDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = true,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon ?? confirmIcon(),
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// success dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
successDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon ?? successIcon(),
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// error dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
errorDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon ?? errorIcon(),
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// warning dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
warningDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon ?? warningIcon(),
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// info dialog function with [title] and [content] string
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
/// [confirmationDialog] to make the confirmation dialog default is false
/// [confirmationMessage] confirmation message default is 'Please check this box for Confirmation!'
infoDialog(
  BuildContext context,
  String title,
  String content, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
  bool confirmationDialog = false,
  String? confirmationMessage,
}) {
  return customAlertDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    Text(content,
        textAlign: TextAlign.justify, style: dialogContentStyle(context)),
    titleIcon: titleIcon ?? infoIcon(),
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
    confirmationDialog: confirmationDialog,
    confirmationMessage: confirmationMessage,
  );
}

/// customSingleInputDialog function with [title] and [content] widgets
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is false
customSingleInputDialog(
  BuildContext context,
  Widget title,
  DialogTextField dialogTextField, {
  Widget? icon,
  String? positiveButtonText,
  Function(String)? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SingleInputDialog(
        icon,
        title,
        dialogTextField,
        negativeButtonText: negativeButtonText,
        negativeButtonAction: negativeButtonAction,
        positiveButtonText: positiveButtonText,
        positiveButtonAction: positiveButtonAction,
        neutralButtonText: neutralButtonText,
        neutralButtonAction: neutralButtonAction,
        hideNeutralButton: hideNeutralButton,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// singleInputDialog function with [title] String and [dialogTextField] InputFieldProps
///
/// [positiveButtonText] for positive button text
/// [negativeButtonText] for negative button text
/// [neutralButtonText] for negative button text
/// [hideNeutralButton] to hide the Neutral Button default is false
/// [closeOnBackPress] to close dialog on back button default is true
singleInputDialog(
  BuildContext context,
  String title,
  DialogTextField dialogTextField, {
  Widget? titleIcon,
  String? positiveButtonText,
  Function(String)? positiveButtonAction,
  String? negativeButtonText,
  Function? negativeButtonAction,
  String? neutralButtonText,
  Function? neutralButtonAction,
  bool hideNeutralButton = false,
  bool closeOnBackPress = true,
}) {
  return customSingleInputDialog(
    context,
    Text(title, style: dialogTitleStyle(context)),
    dialogTextField,
    icon: titleIcon,
    negativeButtonText: negativeButtonText,
    negativeButtonAction: negativeButtonAction,
    positiveButtonText: positiveButtonText,
    positiveButtonAction: positiveButtonAction,
    neutralButtonText: neutralButtonText,
    neutralButtonAction: neutralButtonAction,
    hideNeutralButton: hideNeutralButton,
    closeOnBackPress: closeOnBackPress,
  );
}

/// optionsDialog function with [title] Widget
customOptionsDialog(
  BuildContext context, {
  required List<SimpleItem> simpleItems,
  required Widget Function(BuildContext, int, SimpleItem) itemBuilder,
  Widget? titleWidget,
  Widget? titleIcon,
  bool hideTitleDivider = false,
  bool closeOnBackPress = false,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: OptionDialog(
        titleWidget: titleWidget,
        icon: titleIcon,
        items: simpleItems,
        itemBuilder: itemBuilder,
        hideTitleDivider: hideTitleDivider,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// optionsDialog function with [title] Widget
optionsDialog(
  BuildContext context, {
  required List<SimpleItem> simpleItems,
  required Widget Function(BuildContext, int, SimpleItem) itemBuilder,
  String? title,
  Widget? titleIcon,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
}) {
  return customOptionsDialog(
    context,
    titleWidget: title != null
        ? Text(
            title,
            style: dialogTitleStyle(context),
          )
        : null,
    titleIcon: titleIcon,
    simpleItems: simpleItems,
    itemBuilder: itemBuilder,
    hideTitleDivider: hideTitleDivider,
    closeOnBackPress: closeOnBackPress,
  );
}

/// customSingleSelectionDialog with [title] Widget
customSingleSelectionDialogWithBuilder(
  BuildContext context, {
  required Widget titleWidget,
  required List<SimpleItem> items,
  required Widget Function(BuildContext, int, SimpleItem, String) itemBuilder,
  required Function(SimpleItem) onItemClick,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SingleSelectionDialog(
        titleWidget: titleWidget,
        items: items,
        itemBuilder: itemBuilder,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// singleSelectionDialog with [title] String
singleSelectionDialogWithBuilder(
  BuildContext context, {
  required String title,
  required List<SimpleItem> items,
  required Widget Function(BuildContext, int, SimpleItem, String) itemBuilder,
  required Function(SimpleItem) onItemClick,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SingleSelectionDialog(
        titleWidget: Text(
          title,
          style: dialogTitleStyle(context),
        ),
        items: items,
        itemBuilder: itemBuilder,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// singleSelectionDialog with [title] Widget
customSingleSelectionDialog(
  BuildContext context, {
  required Widget title,
  required List<SimpleItem> items,
  required Function(SimpleItem) onItemClick,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SingleSelectionDialog(
        titleWidget: title,
        items: items,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// singleSelectionDialog with [title] String
singleSelectionDialog(
  BuildContext context, {
  required String title,
  required List<SimpleItem> items,
  required Function(SimpleItem) onItemClick,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: SingleSelectionDialog(
        titleWidget: Text(
          title,
          style: dialogTitleStyle(context),
        ),
        items: items,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// multiSelectionDialog with [title] Widget
customMultiSelectionDialog(
  BuildContext context, {
  required Widget title,
  required Set<SimpleItem> items,
  required Set<SimpleItem> selectedItems,
  required Function(Set<SimpleItem>) onSubmit,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
  String? submitButtonText,
  String? selectAllText,
  String? unSelectAllText,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: MultiSelectionDialog(
        titleWidget: title,
        items: items,
        selectedItems: selectedItems,
        onSubmit: onSubmit,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
        submitButtonText: submitButtonText,
        selectAllText: selectAllText,
        unSelectAllText: unSelectAllText,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// multiSelectionDialog with [title] String
multiSelectionDialog(
  BuildContext context, {
  required String title,
  required Set<SimpleItem> items,
  required Set<SimpleItem> selectedItems,
  required Function(Set<SimpleItem>) onSubmit,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
  String? submitButtonText,
  String? selectAllText,
  String? unSelectAllText,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: MultiSelectionDialog(
        titleWidget: Text(
          title,
          style: dialogTitleStyle(context),
        ),
        items: items,
        selectedItems: selectedItems,
        onSubmit: onSubmit,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
        submitButtonText: submitButtonText,
        selectAllText: selectAllText,
        unSelectAllText: unSelectAllText,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// radioSelectionDialog with [title] Widget
customRadioSelectionDialog(
  BuildContext context, {
  required Widget title,
  required Set<SimpleItem> items,
  required Function(SimpleItem) onItemClick,
  required SimpleItem selectedItem,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = true,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: RadioListDialog(
        titleWidget: title,
        items: items,
        selectedItem: selectedItem,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}

/// radioSelectionDialog with [title] String
radioSelectionDialog(
  BuildContext context, {
  required String title,
  required Set<SimpleItem> items,
  required Function(SimpleItem) onItemClick,
  required SimpleItem selectedItem,
  bool hideTitleDivider = false,
  bool closeOnBackPress = true,
  bool itemDivider = false,
  bool hideSubTitle = true,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: closeOnBackPress,
    barrierLabel: "",
    barrierColor: getBarrierColor(),
    transitionDuration: getDialogPopUpAnimationDuration(),
    transitionBuilder: (c2, a1, a2, widget) {
      return getDialogAnimation(a1, a2, widget);
    },
    pageBuilder: (c1, a1, a2) => WillPopScope(
      child: RadioListDialog(
        titleWidget: Text(
          title,
          style: dialogTitleStyle(context),
        ),
        items: items,
        selectedItem: selectedItem,
        onItemClick: onItemClick,
        hideTitleDivider: hideTitleDivider,
        itemDivider: itemDivider,
        hideSubTitle: hideSubTitle,
      ),
      onWillPop: () async => closeOnBackPress,
    ),
  );
}
