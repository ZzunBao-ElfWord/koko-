/// Attachment model matching Revolt/Stoat autumn API
class Attachment {
  final String id;
  final String filename;
  final String? contentType;
  final int? size;
  final String? tag;

  Attachment({
    required this.id,
    required this.filename,
    this.contentType,
    this.size,
    this.tag,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['_id'] ?? json['id'] ?? '',
        filename: json['filename'] ?? 'file',
        contentType: json['content_type'] ?? json['contentType'],
        size: json['size'],
        tag: json['tag'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'content_type': contentType,
        'size': size,
        'tag': tag,
      };

  bool get isImage => contentType?.startsWith('image/') ?? false;

  bool get isVideo {
    if (contentType == null) return false;
    return contentType!.startsWith('video/');
  }

  String get displaySize {
    if (size == null) return '';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
