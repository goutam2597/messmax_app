import 'package:equatable/equatable.dart';
import '../../data/models/blog_response_model.dart';

sealed class BlogState extends Equatable {
  const BlogState();

  @override
  List<Object?> get props => [];
}

final class BlogInitial extends BlogState {
  const BlogInitial();
}

final class BlogLoading extends BlogState {
  const BlogLoading();
}

final class BlogLoaded extends BlogState {
  final BlogResponseModel response;
  final String? searchQuery;
  final String selectedCategory;

  const BlogLoaded({
    required this.response,
    this.searchQuery,
    this.selectedCategory = 'All',
  });

  @override
  List<Object?> get props => [response, searchQuery, selectedCategory];
}

final class BlogError extends BlogState {
  final String message;
  final String code;

  const BlogError(this.message, {this.code = 'ERR-NET-0000'});

  @override
  List<Object?> get props => [message, code];
}
