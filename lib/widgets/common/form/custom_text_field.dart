import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final bool? filled;
  final Color? fillColor;
  final Color? cursorColor;
  final TextStyle? style;
  final String? initialValue;
  final bool showCounter;
  final bool expands;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool enableInteractiveSelection;
  final bool enableSuggestions;
  final bool autocorrect;
  final String? obscuringCharacter;
  final Brightness? keyboardAppearance;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  final TextDirection? textDirection;
  final String? errorText;
  final String? helperText;
  final String? counterText;
  final Widget? counter;
  final Widget? helper;
  final Widget? error;
  final double? cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final bool? showCursor;
  final bool autovalidateMode;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;
  final Iterable<String>? autofillHints;
  final MouseCursor? mouseCursor;
  final Widget? Function(
    BuildContext, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  })?
  buildCounter;
  final EdgeInsets scrollPadding;
  final bool? enabledBorderUnderline;
  final bool? focusedBorderUnderline;
  final bool? disabledBorderUnderline;
  final bool? errorBorderUnderline;
  final bool? focusedErrorBorderUnderline;
  final bool? isCollapsed;
  final bool? isDense;
  final bool? filledWithColor;
  final Color? focusColor;
  final Color? hoverColor;
  final InputDecoration? decoration;
  final String? Function(String?)? onSaved;
  final String? obscuringCharacterForPassword;
  final bool enableCopyPaste;
  final bool showClearButton;
  final VoidCallback? onClear;
  final String? semanticCounterText;
  final bool? expandsToBottom;
  final bool? showDropdownIcon;
  final List<BoxShadow>? boxShadow;
  final BoxConstraints? constraints;
  final bool? alignLabelWithHint;
  final String? prefixText;
  final String? suffixText;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;
  final Widget? prefix;
  final double? prefixIconConstraintsMinWidth;
  final double? prefixIconConstraintsMinHeight;
  final double? suffixIconConstraintsMinWidth;
  final double? suffixIconConstraintsMinHeight;
  final EdgeInsetsGeometry? prefixIconPadding;
  final EdgeInsetsGeometry? suffixIconPadding;
  final bool? isCollapsible;
  final bool? isExpanded;
  final bool? isFilled;
  final bool? isHovering;
  final bool? isFocused;
  final bool? hasError;
  final bool? isActive;
  final bool? isPristine;
  final bool? isTouched;
  final bool? isDirty;
  final bool? isValid;
  final bool? isInvalid;
  final bool? isSubmitting;
  final bool? isSubmitted;
  final bool? isSubmittable;
  final bool? isInitialValue;
  final bool? isDisabled;
  final bool? isReadOnly;
  final bool? isRequired;
  final bool? isOptional;
  final bool? isPassword;
  final bool? isMultiline;
  final bool? isSearch;
  final bool? isIconOnly;
  final bool? isCircle;
  final bool? isSquare;
  final bool? isRounded;
  final bool? isOutlined;
  final bool? isFloating;
  final bool? isUnderlined;
  final bool? isFilledWithBorder;
  final bool? isFilledWithoutBorder;
  final bool? isOutlinedWithBorder;
  final bool? isOutlinedWithoutBorder;
  final bool? isUnderlinedWithBorder;
  final bool? isUnderlinedWithoutBorder;
  final bool? isFloatingWithBorder;
  final bool? isFloatingWithoutBorder;
  final bool? isFloatingLabel;
  final bool? isCollapsibleLabel;
  final bool? isAlwaysCollapsed;
  final bool? isAlwaysExpanded;
  final bool? isHovered;
  final bool? isSelected;
  final bool? isActiveItem;
  final bool? isHighlighted;
  final bool? isPressed;
  final bool? isScrolledUnder;
  final bool? isScrolledOver;
  final bool? isScrolledToTop;
  final bool? isScrolledToBottom;
  final bool? isScrolledToLeft;
  final bool? isScrolledToRight;
  final bool? isScrolledToStart;
  final bool? isScrolledToEnd;
  final bool? isScrolledHorizontally;
  final bool? isScrolledVertically;
  final bool? isScrolling;
  final bool? isAtScrollStart;
  final bool? isAtScrollEnd;
  final bool? isAtScrollStartOrEnd;
  final bool? isAtScrollStartAndEnd;
  final bool? isAtScrollStartOrEndOrMiddle;
  final bool? isAtScrollMiddle;
  final bool? isAtScrollStartOrMiddle;
  final bool? isAtScrollEndOrMiddle;
  final bool? isAtScrollStartOrEndOrMiddleOrTop;
  final bool? isAtScrollStartOrEndOrMiddleOrBottom;
  final bool? isAtScrollStartOrEndOrMiddleOrLeft;
  final bool? isAtScrollStartOrEndOrMiddleOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrBottom;
  final bool? isAtScrollStartOrEndOrMiddleOrLeftOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrLeft;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrBottomOrLeft;
  final bool? isAtScrollStartOrEndOrMiddleOrBottomOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrBottomOrLeft;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrBottomOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrLeftOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrBottomOrLeftOrRight;
  final bool? isAtScrollStartOrEndOrMiddleOrTopOrBottomOrLeftOrRight;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.filled,
    this.fillColor,
    this.cursorColor,
    this.style,
    this.initialValue,
    this.showCounter = false,
    this.expands = false,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.enableInteractiveSelection = true,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.obscuringCharacter = '•',
    this.keyboardAppearance,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.textDirection,
    this.errorText,
    this.helperText,
    this.counterText,
    this.counter,
    this.helper,
    this.error,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.showCursor,
    this.autovalidateMode = false,
    this.scrollPhysics,
    this.scrollController,
    this.autofillHints,
    this.mouseCursor,
    this.buildCounter,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enabledBorderUnderline,
    this.focusedBorderUnderline,
    this.disabledBorderUnderline,
    this.errorBorderUnderline,
    this.focusedErrorBorderUnderline,
    this.isCollapsed = false,
    this.isDense,
    this.filledWithColor = false,
    this.focusColor,
    this.hoverColor,
    this.decoration,
    this.onSaved,
    this.obscuringCharacterForPassword = '•',
    this.enableCopyPaste = true,
    this.showClearButton = false,
    this.onClear,
    this.semanticCounterText,
    this.expandsToBottom = false,
    this.showDropdownIcon = false,
    this.boxShadow,
    this.constraints,
    this.alignLabelWithHint,
    this.prefixText,
    this.suffixText,
    this.prefixStyle,
    this.suffixStyle,
    this.prefix,
    this.prefixIconConstraintsMinWidth = 40.0,
    this.prefixIconConstraintsMinHeight = 40.0,
    this.suffixIconConstraintsMinWidth = 40.0,
    this.suffixIconConstraintsMinHeight = 40.0,
    this.prefixIconPadding = EdgeInsets.zero,
    this.suffixIconPadding = EdgeInsets.zero,
    this.isCollapsible = false,
    this.isExpanded = false,
    this.isFilled,
    this.isHovering = false,
    this.isFocused = false,
    this.hasError = false,
    this.isActive = false,
    this.isPristine = true,
    this.isTouched = false,
    this.isDirty = false,
    this.isValid = false,
    this.isInvalid = false,
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.isSubmittable = false,
    this.isInitialValue = false,
    this.isDisabled = false,
    this.isReadOnly = false,
    this.isRequired = false,
    this.isOptional = true,
    this.isPassword = false,
    this.isMultiline = false,
    this.isSearch = false,
    this.isIconOnly = false,
    this.isCircle = false,
    this.isSquare = false,
    this.isRounded = true,
    this.isOutlined = false,
    this.isFloating = false,
    this.isUnderlined = false,
    this.isFilledWithBorder = false,
    this.isFilledWithoutBorder = false,
    this.isOutlinedWithBorder = false,
    this.isOutlinedWithoutBorder = false,
    this.isUnderlinedWithBorder = false,
    this.isUnderlinedWithoutBorder = false,
    this.isFloatingWithBorder = false,
    this.isFloatingWithoutBorder = false,
    this.isFloatingLabel = false,
    this.isCollapsibleLabel = false,
    this.isAlwaysCollapsed = false,
    this.isAlwaysExpanded = false,
    this.isHovered = false,
    this.isSelected = false,
    this.isActiveItem = false,
    this.isHighlighted = false,
    this.isPressed = false,
    this.isScrolledUnder = false,
    this.isScrolledOver = false,
    this.isScrolledToTop = false,
    this.isScrolledToBottom = false,
    this.isScrolledToLeft = false,
    this.isScrolledToRight = false,
    this.isScrolledToStart = false,
    this.isScrolledToEnd = false,
    this.isScrolledHorizontally = false,
    this.isScrolledVertically = false,
    this.isScrolling = false,
    this.isAtScrollStart = false,
    this.isAtScrollEnd = false,
    this.isAtScrollStartOrEnd = false,
    this.isAtScrollStartAndEnd = false,
    this.isAtScrollStartOrEndOrMiddle = false,
    this.isAtScrollMiddle = false,
    this.isAtScrollStartOrMiddle = false,
    this.isAtScrollEndOrMiddle = false,
    this.isAtScrollStartOrEndOrMiddleOrTop = false,
    this.isAtScrollStartOrEndOrMiddleOrBottom = false,
    this.isAtScrollStartOrEndOrMiddleOrLeft = false,
    this.isAtScrollStartOrEndOrMiddleOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrBottom = false,
    this.isAtScrollStartOrEndOrMiddleOrLeftOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrLeft = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrBottomOrLeft = false,
    this.isAtScrollStartOrEndOrMiddleOrBottomOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrBottomOrLeft = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrBottomOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrLeftOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrBottomOrLeftOrRight = false,
    this.isAtScrollStartOrEndOrMiddleOrTopOrBottomOrLeftOrRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
    );

    final decoration = InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      counterText: showCounter ? null : '',
      border: border ?? defaultBorder,
      enabledBorder: enabledBorder ?? defaultBorder,
      focusedBorder:
          focusedBorder ??
          defaultBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
      errorBorder:
          errorBorder ??
          defaultBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.error),
          ),
      focusedErrorBorder:
          focusedErrorBorder ??
          defaultBorder.copyWith(
            borderSide: BorderSide(color: colorScheme.error, width: 2),
          ),
      filled: filled ?? true,
      fillColor: fillColor ?? colorScheme.surface,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: BoxConstraints(
        minWidth: prefixIconConstraintsMinWidth!,
        minHeight: prefixIconConstraintsMinHeight!,
      ),
      suffixIconConstraints: BoxConstraints(
        minWidth: suffixIconConstraintsMinWidth!,
        minHeight: suffixIconConstraintsMinHeight!,
      ),
      isDense: isDense,
      alignLabelWithHint: alignLabelWithHint,
      prefixText: prefixText,
      suffixText: suffixText,
      prefixStyle: prefixStyle,
      suffixStyle: suffixStyle,
      prefix: prefix,
      helperText: helperText,
      helperStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
      ),
      errorText: errorText,
      errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      errorMaxLines: 2,
      counter: counter,
      helper: helper,
      error: error,
    );

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style:
          style ?? textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      textDirection: textDirection,
      readOnly: readOnly,
      contextMenuBuilder: enableCopyPaste
          ? (context, editableTextState) => AdaptiveTextSelectionToolbar(
              anchors: editableTextState.contextMenuAnchors,
              children: [
                if (editableTextState.currentTextEditingValue.selection.isValid)
                  ...[
                    TextSelectionToolbarTextButton(
                      padding: EdgeInsets.zero,
                      child: Text('Copy'),
                      onPressed: () => editableTextState.copySelection(SelectionChangedCause.toolbar),
                    ),
                    TextSelectionToolbarTextButton(
                      padding: EdgeInsets.zero,
                      child: Text('Cut'),
                      onPressed: () => editableTextState.cutSelection(SelectionChangedCause.toolbar),
                    ),
                  ],
                TextSelectionToolbarTextButton(
                  padding: EdgeInsets.zero,
                  child: Text('Paste'),
                  onPressed: () => editableTextState.pasteText(SelectionChangedCause.toolbar),
                ),
                TextSelectionToolbarTextButton(
                  padding: EdgeInsets.zero,
                  child: Text('Select All'),
                  onPressed: () => editableTextState.selectAll(SelectionChangedCause.toolbar),
                ),
              ],
            )
          : (context, editableTextState) => const SizedBox.shrink(),
      showCursor: showCursor,
      autofocus: autofocus,
      obscuringCharacter: obscuringCharacter!,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      cursorWidth: cursorWidth!,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor ?? colorScheme.primary,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      autovalidateMode: autovalidateMode
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      autofillHints: autofillHints,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      buildCounter: buildCounter,
      decoration: decoration,
      focusNode: focusNode,
      initialValue: initialValue,
      expands: expands,
      mouseCursor: mouseCursor,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
    );
  }
}
