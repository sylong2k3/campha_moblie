import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/domain/session_controller.dart';
import '../../shared/presentation/app_feedback.dart';
import '../../shared/presentation/app_search_field.dart';
import '../data/map_repository.dart';
import '../domain/layer_model.dart';

class MapSearchScreen extends ConsumerStatefulWidget {
  const MapSearchScreen({super.key});

  @override
  ConsumerState<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends ConsumerState<MapSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  CancelToken? _cancelToken;
  List<MapSearchResult> _results = const [];
  bool _loading = false;
  Object? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    ref.listenManual<SessionState>(sessionControllerProvider, (previous, next) {
      if (previous?.user?.id == next.user?.id &&
          previous?.status == next.status) {
        return;
      }
      _debounce?.cancel();
      _cancelSearch('identity changed');
      _controller.clear();
      if (!mounted) return;
      setState(() {
        _query = '';
        _results = const [];
        _loading = false;
        _error = null;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancelSearch('search disposed');
    _controller.dispose();
    super.dispose();
  }

  void _cancelSearch(String reason) {
    final token = _cancelToken;
    _cancelToken = null;
    if (token != null && !token.isCancelled) token.cancel(reason);
  }

  void _changed(String value) {
    final trimmed = value.trim();
    final wasTooShort = _query.length < 2;
    _query = trimmed;
    _debounce?.cancel();
    if (_query.length < 2) {
      _cancelSearch('query too short');
      if (!wasTooShort || _results.isNotEmpty || _loading || _error != null) {
        setState(() {
          _results = const [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final query = _query;
    if (!mounted || query.length < 2 || query.length > 100) return;
    _cancelSearch('superseded');
    final token = CancelToken();
    _cancelToken = token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(mapRepositoryProvider)
          .searchFeatures(query: query, cancelToken: token);
      if (!mounted ||
          token.isCancelled ||
          !identical(_cancelToken, token) ||
          query != _query) {
        return;
      }
      setState(() {
        _results = results;
        _loading = false;
      });
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) return;
      if (mounted && !token.isCancelled && identical(_cancelToken, token)) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && !token.isCancelled && identical(_cancelToken, token)) {
        setState(() {
          _error = error;
          _loading = false;
        });
      }
    } finally {
      if (identical(_cancelToken, token)) _cancelToken = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<MapSearchResult>>{};
    for (final item in _results) {
      groups.putIfAbsent(item.layerName, () => []).add(item);
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.mapSearchTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: AppSearchField(
                key: const ValueKey('map-search-input'),
                controller: _controller,
                hintText: context.l10n.mapSearchHint,
                clearTooltip: context.l10n.cmsClearSearch,
                autofocus: true,
                loading: _loading,
                onChanged: _changed,
                onSubmitted: (_) {
                  _debounce?.cancel();
                  _search();
                },
              ),
            ),
            Expanded(
              child: _error != null
                  ? AppStateMessage(
                      icon: Icons.cloud_off_outlined,
                      tone: AppFeedbackTone.error,
                      title: _error!.localizedErrorMessage(context.l10n),
                      actionLabel: context.l10n.commonRetry,
                      onAction: _search,
                      liveRegion: true,
                    )
                  : _query.length < 2
                  ? AppStateMessage(
                      icon: Icons.travel_explore,
                      title: context.l10n.mapSearchPrompt,
                    )
                  : !_loading && _results.isEmpty
                  ? AppStateMessage(
                      icon: Icons.search_off,
                      title: context.l10n.mapSearchEmpty,
                      liveRegion: true,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 26),
                      children: [
                        for (final group in groups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                            child: Text(
                              group.key,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                for (final item in group.value)
                                  ListTile(
                                    key: ValueKey(
                                      'map-result-${item.layerId}-${item.featureId}',
                                    ),
                                    leading: const Icon(
                                      Icons.location_on_outlined,
                                    ),
                                    title: Text(item.label),
                                    subtitle: Text(item.layerCode),
                                    trailing: const Icon(Icons.north_east),
                                    onTap: () => context.pop(item),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
