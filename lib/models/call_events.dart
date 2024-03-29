import '../src/signed_call_logger.dart';

///Holds all the possible statuses of a VoIP call
enum CallEvent {
  // Indicates that the call is successfully placed
  callIsPlaced,

  // Indicates that the call is cancelled from the initiator's end
  cancelled,

  // Indicates that the call is declined from the receiver's end
  declined,

  // Indicates that the call is missed at the receiver's end
  missed,

  // Indicates that the call is picked up by the receiver
  answered,

  // Indicates that the connection to the receiver is established and the audio transfer begins at this state
  callInProgress,

  // Indicates that the call has been ended.
  ended,

  // Indicates that the receiver is already busy on another call
  receiverBusyOnAnotherCall,

  // Indicates that the call is declined due to the receiver being logged out with the specific CUID
  declinedDueToLoggedOutCuid,

  // [Specific to Android-Platform]
  // Indicates that the call is declined due to the notifications are disabled at the receiver's end.
  declinedDueToNotificationsDisabled,

  // Indicates that the microphone permission is not granted for the call.
  declinedDueToMicrophonePermissionsNotGranted;

  ///parses the state of the call in a [CallEvent]
  static CallEvent fromString(String state) {
    switch (state) {
      case "CallIsPlaced":
        return CallEvent.callIsPlaced;
      case "Cancelled":
        return CallEvent.cancelled;
      case "Declined":
        return CallEvent.declined;
      case "Missed":
        return CallEvent.missed;
      case "Answered":
        return CallEvent.answered;
      case "CallInProgress":
        return CallEvent.callInProgress;
      case "Ended":
        return CallEvent.ended;
      case "ReceiverBusyOnAnotherCall":
        return CallEvent.receiverBusyOnAnotherCall;
      case "DeclinedDueToLoggedOutCuid":
        return CallEvent.declinedDueToLoggedOutCuid;
      case "DeclinedDueToNotificationsDisabled":
        return CallEvent.declinedDueToNotificationsDisabled;
      case "DeclinedDueToMicrophonePermissionsNotGranted":
        return CallEvent.declinedDueToMicrophonePermissionsNotGranted;
      default:
        SignedCallLogger.d('$state is not a valid CallState.');
        throw ArgumentError('$state is not a valid CallState.');
    }
  }
}
