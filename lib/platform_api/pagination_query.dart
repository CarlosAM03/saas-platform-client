enum SortOrder { asc, desc }

enum SortField {
  name,
  email,
  status,
  createdAt,
  updatedAt,
  startedAt,
  completedAt,
  id
}

class PaginationQuery {
  const PaginationQuery(
      {this.page, this.limit, this.search, this.sortBy, this.sortOrder});
  final int? page;
  final int? limit;
  final String? search;
  final SortField? sortBy;
  final SortOrder? sortOrder;

  Map<String, dynamic> toQuery(
      {Set<SortField>? allowedSorts, bool allowSearch = true}) {
    if (page != null && page! < 1) throw ArgumentError.value(page, 'page');
    if (limit != null && (limit! < 1 || limit! > 100)) {
      throw ArgumentError.value(limit, 'limit');
    }
    if (!allowSearch && search != null) {
      throw ArgumentError('This resource does not support search');
    }
    if (sortBy != null &&
        allowedSorts != null &&
        !allowedSorts.contains(sortBy)) {
      throw ArgumentError.value(sortBy, 'sortBy');
    }
    return {
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null) 'search': search,
      if (sortBy != null) 'sortBy': sortBy!.name,
      if (sortOrder != null) 'sortOrder': sortOrder!.name,
    };
  }
}
