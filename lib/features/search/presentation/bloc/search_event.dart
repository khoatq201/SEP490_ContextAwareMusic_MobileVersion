import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the Search screen mounts to load categories.
class LoadCategoriesEvent extends SearchEvent {
  const LoadCategoriesEvent();
}

/// Fired on every keystroke / query change.
class QueryChangedEvent extends SearchEvent {
  final String query;
  const QueryChangedEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Fired when the user clears the search field.
class ClearSearchEvent extends SearchEvent {
  const ClearSearchEvent();
}
