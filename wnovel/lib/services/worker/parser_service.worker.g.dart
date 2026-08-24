// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'parser_service.dart';

// **************************************************************************
// Generator: WorkerGenerator 9.3.1 (Squadron 7.4.3)
// **************************************************************************

// dart format width=80
/// Command ids used in operations map
const int _$decodeProjectZipId = 1;
const int _$encodeProjectZipId = 2;
const int _$parseEpubId = 3;

/// WorkerService operations for ParserService
extension on ParserService {
  OperationsMap _$getOperations() => OperationsMap({
    _$decodeProjectZipId: ($req) async {
      final Map<String, dynamic>? $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await decodeProjectZip($dsr.$1($req.args[0]));
      } finally {}
      return $res;
    },
    _$encodeProjectZipId: ($req) async {
      final List<int>? $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await encodeProjectZip($dsr.$4($req.args[0]));
      } finally {}
      return $res;
    },
    _$parseEpubId: ($req) async {
      final Map<String, dynamic> $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await parseEpub($dsr.$1($req.args[0]), $dsr.$2($req.args[1]));
      } finally {}
      return $res;
    },
  });
}

/// Invoker for ParserService, implements the public interface to invoke the
/// remote service.
base mixin _$ParserService$Invoker on Invoker implements ParserService {
  @override
  Future<Map<String, dynamic>?> decodeProjectZip(List<int> bytes) async {
    final dynamic $res = await send(_$decodeProjectZipId, args: [bytes]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<List<int>?> encodeProjectZip(Map<String, dynamic> projectJson) async {
    final dynamic $res = await send(_$encodeProjectZipId, args: [projectJson]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$6($res);
    } finally {}
  }

  @override
  Future<Map<String, dynamic>> parseEpub(List<int> bytes, String title) async {
    final dynamic $res = await send(_$parseEpubId, args: [bytes, title]);
    try {
      final $dsr = _$Deser(contextAware: false);
      return $dsr.$4($res);
    } finally {}
  }
}

/// Facade for ParserService, implements other details of the service unrelated to
/// invoking the remote service.
base mixin _$ParserService$Facade implements ParserService {
  @override
  List<Map<String, dynamic>> _flattenChapters(
    EpubChapter epubChapter, {
    int refIndex = 0,
  }) => throw UnimplementedError();
}

/// WorkerClient for ParserService
final class $ParserService$Client extends WorkerClient
    with _$ParserService$Invoker, _$ParserService$Facade
    implements ParserService {
  $ParserService$Client(PlatformChannel channelInfo)
    : super(Channel.deserialize(channelInfo)!);
}

/// Local worker extension for ParserService
extension $ParserServiceLocalWorkerExt on ParserService {
  // Get a fresh local worker instance.
  LocalWorker<ParserService> getLocalWorker([
    ExceptionManager? exceptionManager,
  ]) => LocalWorker.create(this, _$getOperations(), exceptionManager);
}

/// WorkerService class for ParserService
base class _$ParserService$WorkerService extends ParserService
    implements WorkerService {
  _$ParserService$WorkerService() : super();

  @override
  OperationsMap get operations => _$getOperations();
}

/// Service initializer for ParserService
WorkerService $ParserServiceInitializer(WorkerRequest $req) =>
    _$ParserService$WorkerService();

/// Worker for ParserService
base class ParserServiceWorker extends Worker
    with _$ParserService$Invoker, _$ParserService$Facade
    implements ParserService {
  ParserServiceWorker({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $ParserServiceActivator(Squadron.platformType),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorker.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $ParserServiceActivator(SquadronPlatformType.vm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorker.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $ParserServiceActivator(SquadronPlatformType.js),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorker.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $ParserServiceActivator(SquadronPlatformType.wasm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  @override
  List? getStartArgs() => null;
}

/// Worker pool for ParserService
base class ParserServiceWorkerPool extends WorkerPool<ParserServiceWorker>
    with _$ParserService$Facade
    implements ParserService {
  ParserServiceWorkerPool({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => ParserServiceWorker(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorkerPool.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => ParserServiceWorker.vm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorkerPool.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => ParserServiceWorker.js(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  ParserServiceWorkerPool.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => ParserServiceWorker.wasm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  @override
  Future<Map<String, dynamic>?> decodeProjectZip(List<int> bytes) =>
      execute((w) => w.decodeProjectZip(bytes));

  @override
  Future<List<int>?> encodeProjectZip(Map<String, dynamic> projectJson) =>
      execute((w) => w.encodeProjectZip(projectJson));

  @override
  Future<Map<String, dynamic>> parseEpub(List<int> bytes, String title) =>
      execute((w) => w.parseEpub(bytes, title));
}

final class _$Deser extends MarshalingContext {
  _$Deser({super.contextAware});
  late final $0 = value<int>();
  late final $1 = list<int>($0);
  late final $2 = value<String>();
  late final $3 = value<Object>();
  late final $4 = nmap<String, Object>(kcast: $2, vcast: $3);
  late final $5 = Converter.allowNull($4);
  late final $6 = Converter.allowNull($1);
}
