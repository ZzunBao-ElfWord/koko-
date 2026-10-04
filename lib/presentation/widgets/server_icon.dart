import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/server.dart';

class ServerIcon extends StatelessWidget {
  final Server server;
  final bool isSelected;
  final VoidCallback onTap;

  const ServerIcon({
    super.key,
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : _getServerColor(server.name),
          borderRadius: isSelected
              ? const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                )
              : BorderRadius.circular(24),
        ),
        child: server.iconUrl != null
            ? ClipRRect(
                borderRadius: isSelected
                    ? const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      )
                    : BorderRadius.circular(24),
                child: CachedNetworkImage(
                  imageUrl: server.iconUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorWidget: (context, url, error) => _buildFallback(),
                ),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Color _getServerColor(String name) {
    final colors = [
      Colors.red[700],
      Colors.green[700],
      Colors.blue[700],
      Colors.orange[700],
      Colors.purple[700],
      Colors.teal[700],
      Colors.pink[700],
      Colors.indigo[700],
    ];
    return colors[name.hashCode.abs() % colors.length] ?? Colors.grey[700]!;
  }
}
