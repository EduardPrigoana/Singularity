import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:singularity/CustomWidgets/snackbar.dart';
import 'package:singularity/localization/app_localizations.dart';

void copyToClipboard({
  required BuildContext context,
  required String text,
  String? displayText,
}) {
  Clipboard.setData(
    ClipboardData(text: text),
  );
  ShowSnackBar().showSnackBar(
    context,
    displayText ?? AppLocalizations.of(context)!.copied,
  );
}
