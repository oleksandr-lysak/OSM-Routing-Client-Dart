import 'package:flutter/foundation.dart';

import '../../routing_client_dart.dart';
import '../models/osrm/osrm_mixin.dart';
import '../utilities/computes_utilities.dart';

class OSRMRoutingService extends RoutingService with OSRMHelper {
  OSRMRoutingService({
    String? serverURL,
    super.header,
  }) : super(serverURL: serverURL ?? oSRMServer);
  OSRMRoutingService.dioClient({
    required super.client,
  }) : super.dioClient();

  void setOSRMURLServer({String server = oSRMServer}) {
    dio.options.baseUrl = server;
  }

  Future<OSRMRoad> getOSRMRoad(OSRMRequest request) async {
    final urlOption = request.encodeHeader();
    final response = await dio.get(dio.options.baseUrl + urlOption);
    final Map<String, dynamic> responseJson = Map.from(response.data);
    if (response.statusCode != null && response.statusCode! > 299 ||
        response.statusCode! < 200) {
      return OSRMRoad.withError();
    }
    final instructionsHelper =
        await loadInstructionHelperJson(language: request.languages);
    final computeData =
        (json: responseJson, request: request, helper: instructionsHelper);
    return compute(
      (message) async {
        final route = await switch (message.request.profile) {
          Profile.route => parseRoad(
              ParserRoadComputeArg(
                json: message.json,
                langCode: message.request.languages.code,
                alternative: request.hasAlternative ?? false,
              ),
            ),
          Profile.trip => parseTrip(
              ParserTripComputeArg(
                tripJson: message.json,
                langCode: message.request.languages.code,
              ),
            ),
          // TODO: Handle this case.
          Object() => throw UnimplementedError(),
          // TODO: Handle this case.
          null => throw UnimplementedError(),
        };
        final instructions = OSRMHelper.buildInstructions(
          road: route,
          instructionsHelper: message.helper,
        );
        return route.copyWith(
          instructions: instructions,
        );
      },
      computeData,
    );
  }
}
