import 'package:flutter/material.dart';

class ChannelSelectorWidget extends StatelessWidget {
  final String selectedChannel;
  final ValueChanged<String> onChannelChanged;
  final Color? themeColor;

  const ChannelSelectorWidget({
    Key? key,
    required this.selectedChannel,
    required this.onChannelChanged,
    this.themeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = themeColor ?? Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChannelButton(
          context,
          'sms',
          'SMS',
          Icons.sms,
          primaryColor,
        ),
        const SizedBox(width: 16),
        _buildChannelButton(
          context,
          'whatsapp',
          'WhatsApp',
          Icons.chat,
          primaryColor,
        ),
      ],
    );
  }

  Widget _buildChannelButton(
    BuildContext context,
    String channel,
    String label,
    IconData icon,
    Color primaryColor,
  ) {
    final isSelected = selectedChannel == channel;
    return GestureDetector(
      onTap: () => onChannelChanged(channel),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: primaryColor, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}





