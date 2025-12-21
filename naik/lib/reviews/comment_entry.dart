class Comment {
    String commentId;
    int commentRating;
    String commentContent;
    String commentAuthorId;
    String commentAuthorUsername;
    String commentAuthorRole;
    DateTime commentCreatedAt;
    List<Reply>? replies;

    Comment({
        required this.commentId,
        required this.commentRating,
        required this.commentContent,
        required this.commentAuthorId,
        required this.commentAuthorUsername,
        required this.commentAuthorRole,
        required this.commentCreatedAt,
        this.replies,
    });

    factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        commentId: json["comment_id"],
        commentRating: json["comment_rating"],
        commentContent: json["comment_content"],
        commentAuthorId: json["comment_author_id"],
        commentAuthorUsername: json["comment_author_username"],
        commentCreatedAt: DateTime.parse(json["comment_created_at"]),
        commentAuthorRole: json["comment_author_role"] ?? 'user',
        replies: json["replies"] == null ? null : List<Reply>.from(json["replies"].map((x) => Reply.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "comment_id": commentId,
        "comment_rating": commentRating,
        "comment_content": commentContent,
        "comment_author_id": commentAuthorId,
        "comment_author_username": commentAuthorUsername,
        "comment_author_role": commentAuthorRole,
        "comment_created_at": commentCreatedAt.toIso8601String(),
        "replies": List<dynamic>.from(replies!.map((x) => x.toJson())),
    };
}

class Reply {
    String replyId;
    String replyContent;
    String replyAuthorId;
    String replyAuthorUsername;
    String replyAuthorRole;
    DateTime replyCreatedAt;

    Reply({
        required this.replyId,
        required this.replyContent,
        required this.replyAuthorId,
        required this.replyAuthorUsername,
        required this.replyAuthorRole,
        required this.replyCreatedAt,
    });

    factory Reply.fromJson(Map<String, dynamic> json) => Reply(
        replyId: json["reply_id"],
        replyContent: json["reply_content"],
        replyAuthorId: json["reply_author_id"],
        replyAuthorUsername: json["reply_author_username"],
        replyAuthorRole: json["reply_author_role"] ?? 'user',
        replyCreatedAt: DateTime.parse(json["reply_created_at"]),
    );

    Map<String, dynamic> toJson() => {
        "reply_id": replyId,
        "reply_content": replyContent,
        "reply_author_id": replyAuthorId,
        "reply_author_username": replyAuthorUsername,
        "reply_author_role": replyAuthorRole,
        "reply_created_at": replyCreatedAt.toIso8601String(),
    };
}