import 'package:flutter/widgets.dart';

/// Internal capsule. Text.rich provides natural and dry alphabetic baselines.
class MfmMention extends StatelessWidget {
  const MfmMention({
    super.key,
    required this.name,
    required this.host,
    required this.style,
    required this.color,
    this.avatar,
    this.onTap,
  });

  final String name;
  final String host;
  final TextStyle style;
  final Color color;
  final ImageProvider<Object>? avatar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final em = style.fontSize ?? 14;
    final placeholder = ColoredBox(
      color: color.withValues(alpha: color.a * .2),
    );
    return Semantics(
      container: true,
      label: '$name$host',
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: color.a * .1),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                child: Text.rich(
                  TextSpan(
                    style: mentionRoleStyle(style, color),
                    children: [
                      WidgetSpan(
                        // WidgetSpan defaults to bottom alignment.
                        child: Padding(
                          padding: EdgeInsets.only(right: em * .2),
                          child: SizedBox.square(
                            dimension: em * 1.5,
                            child: ClipOval(
                              child: avatar == null
                                  ? placeholder
                                  : Image(
                                      image: avatar!,
                                      fit: BoxFit.cover,
                                      frameBuilder:
                                          (
                                            context,
                                            child,
                                            frame,
                                            synchronous,
                                          ) => frame == null
                                          ? placeholder
                                          : child,
                                      errorBuilder: (context, error, stack) =>
                                          placeholder,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: name),
                      if (host.isNotEmpty)
                        TextSpan(
                          text: host,
                          style: mentionRoleStyle(
                            style,
                            color.withValues(alpha: color.a * .5),
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textWidthBasis: TextWidthBasis.longestLine,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A foreground shader/paint must not override explicit mention role colors.
TextStyle mentionRoleStyle(TextStyle style, Color color) =>
    style.foreground == null
    ? style.copyWith(color: color)
    : style.copyWith(foreground: Paint()..color = color);
