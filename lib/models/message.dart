import 'package:hive/hive.dart';

class Message extends HiveObject {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    content: json['content'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
  );
}

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++)
        i: reader.read(),
    };
    return Message(
      id: fields[0] as String,
      content: fields[1] as String,
      isUser: fields[2] as bool,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer.writeByte(4);
    writer.write(obj.id);
    writer.write(obj.content);
    writer.write(obj.isUser);
    writer.write(obj.timestamp);
  }
}
