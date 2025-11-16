import 'package:flutter/material.dart';

class ParentElementsFooter extends StatelessWidget {
  final bool showParentElementsOnly;
  final ValueChanged<bool?> onShowParentElementsOnlyChanged;

  const ParentElementsFooter({
    super.key,
    required this.showParentElementsOnly,
    required this.onShowParentElementsOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48.0, // You can adjust the height as needed
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              onShowParentElementsOnlyChanged(!showParentElementsOnly);
            },
            child: Row(
              children: [
                Checkbox(
                  value: showParentElementsOnly,
                  onChanged: onShowParentElementsOnlyChanged,
                ),
                const Text('Show Parent Elements Only'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
