import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Internal search editor. Its draft belongs to this widget identity, not MFM.
class MfmSearch extends StatefulWidget {
  const MfmSearch({
    super.key,
    required this.query,
    required this.label,
    required this.style,
    required this.foreground,
    required this.divider,
    required this.accent,
    required this.brightness,
    this.onSearch,
  });

  final String query;
  final String label;
  final TextStyle style;
  final Color foreground;
  final Color divider;
  final Color accent;
  final Brightness brightness;
  final ValueChanged<String>? onSearch;

  @override
  State<MfmSearch> createState() => _MfmSearchState();
}

class _MfmSearchState extends State<MfmSearch> {
  late final TextEditingController _controller;
  late final FocusNode _fieldFocusNode;
  bool _buttonFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
    _fieldFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(MfmSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocusNode.dispose();
    super.dispose();
  }

  void _submit() => widget.onSearch?.call(_controller.text);

  Widget _contextMenu(BuildContext _, EditableTextState state) {
    // The builder receives the root overlay context, not the editor context.
    final fieldContext = state.context;
    final popup = Directionality(
      textDirection: Directionality.of(fieldContext),
      child: CupertinoAdaptiveTextSelectionToolbar.buttonItems(
        anchors: state.contextMenuAnchors,
        buttonItems: state.contextMenuButtonItems,
      ),
    );
    // Root overlays capture themes, not the field's localizations. Wrap the
    // returned popup, keeping the editor's ancestry stable on locale changes.
    if (Localizations.of<CupertinoLocalizations>(
          fieldContext,
          CupertinoLocalizations,
        ) !=
        null) {
      return Localizations.override(context: fieldContext, child: popup);
    }
    return Localizations(
      locale: const Locale('en'),
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      child: popup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onSearch != null;
    final hasOverlay = Overlay.maybeOf(context) != null;
    final borderSide = BorderSide(color: widget.divider);
    // Do not flatten a foreground paint or let Cupertino inject its font.
    final style = widget.style.copyWith(
      inherit: false,
      color: widget.style.color == null && widget.style.foreground == null
          ? widget.foreground
          : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : math.max<double>(320, constraints.minWidth);
        return SizedBox(
          width: width,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Semantics(
                      container: true,
                      child: CupertinoTextField(
                        controller: _controller,
                        focusNode: _fieldFocusNode,
                        style: style,
                        placeholder: widget.query,
                        placeholderStyle: style.copyWith(
                          foreground: Paint()
                            ..color = widget.foreground.withValues(alpha: .5),
                        ),
                        padding: const EdgeInsets.all(10),
                        textAlignVertical: TextAlignVertical.center,
                        textInputAction: TextInputAction.search,
                        keyboardAppearance: widget.brightness,
                        cursorColor: widget.accent,
                        enableInteractiveSelection: hasOverlay,
                        contextMenuBuilder: hasOverlay ? _contextMenu : null,
                        magnifierConfiguration:
                            TextMagnifierConfiguration.disabled,
                        onSubmitted: (_) => _submit(),
                        decoration: BoxDecoration(
                          border: Border.fromBorderSide(borderSide),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: width * .6),
                    child: Semantics(
                      container: true,
                      button: true,
                      enabled: enabled,
                      label: widget.label,
                      onTap: enabled ? _submit : null,
                      child: ExcludeFocus(
                        excluding: !enabled,
                        child: FocusableActionDetector(
                          enabled: enabled,
                          onShowFocusHighlight: (focused) {
                            setState(() => _buttonFocused = focused);
                          },
                          shortcuts: const {
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.space):
                                ActivateIntent(),
                          },
                          actions: {
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                if (enabled) _submit();
                                return null;
                              },
                            ),
                          },
                          child: GestureDetector(
                            // Even disabled buttons consume taps inside a link.
                            behavior: HitTestBehavior.opaque,
                            excludeFromSemantics: true,
                            onTap: _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: borderSide,
                                  right: borderSide,
                                  bottom: borderSide,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              foregroundDecoration: _buttonFocused && enabled
                                  ? BoxDecoration(
                                      border: Border.all(
                                        color: widget.accent,
                                        width: 2,
                                      ),
                                    )
                                  : null,
                              child: Center(
                                widthFactor: 1,
                                child: ExcludeSemantics(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    children: [
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: math.max(
                                            0,
                                            width * .6 - 34,
                                          ),
                                        ),
                                        child: Icon(
                                          const IconData(
                                            0xe567,
                                            fontFamily: 'MaterialIcons',
                                          ),
                                          size: style.fontSize ?? 14,
                                          color:
                                              style.color ??
                                              style.foreground?.color ??
                                              widget.foreground,
                                        ),
                                      ),
                                      Text(
                                        widget.label,
                                        style: widget.style,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
