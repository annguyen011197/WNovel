// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// Generator: WorkerGenerator 9.3.1 (Squadron 7.4.3)
// **************************************************************************

import 'package:squadron/squadron.dart';

import 'parser_service.dart';

void _start$ParserService(WorkerRequest command) {
  /// VM entry point for ParserService
  run($ParserServiceInitializer, command);
}

EntryPoint $getParserServiceActivator(SquadronPlatformType platform) {
  if (platform.isVm) {
    return _start$ParserService;
  } else {
    throw UnsupportedError('${platform.label} not supported.');
  }
}
